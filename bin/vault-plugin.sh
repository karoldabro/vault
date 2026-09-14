#!/usr/bin/env bash
# vault-plugin.sh — register a framework plugin, and inspect what is registered.
#
# Contract: vault/architecture/plugin-extension-contract.md.
#
# Usage:  bin/vault-plugin.sh add <plugin-dir>     register a plugin the operator names
#         bin/vault-plugin.sh remove <name>        drop it
#         bin/vault-plugin.sh list                 one row per registered plugin
#         bin/vault-plugin.sh doctor               check every registered path still resolves
#         bin/vault-plugin.sh -h
#
# This is the ONLY writer of the registry. Nothing scans for plugins: a directory the framework
# discovers on its own is a code-execution surface nobody reviewed. Registering a plugin trusts every
# future commit of that repository, not only the one present at registration.
#
# Exit: 0 done · 1 refused · 2 usage

set -uo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -r "${VAULT_ROOT}/lib/plugin-registry.sh" ]; then
    # shellcheck source=lib/plugin-registry.sh
    . "${VAULT_ROOT}/lib/plugin-registry.sh"
else
    printf 'ERROR: %s/lib/plugin-registry.sh is missing\n' "${VAULT_ROOT}" >&2
    exit 2
fi

usage() { sed -n '2,/^set -uo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }
refuse() { printf 'REFUSED: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------- add

# Refuse a path that is, or traverses, a symlink. `add` validates once and the point runs later; a
# symlinked component lets the directory that actually executes be swapped in between without the
# operator deciding again. Comparing the path against its own realpath catches both cases.
assert_no_symlink() {
    local given=$1 real lexical
    real=$(realpath -- "$given" 2>/dev/null) || refuse "cannot resolve ${given}"
    # `realpath -s` normalises the path WITHOUT following symlinks. When the two disagree, some
    # component was a link. Comparing against `cd && pwd -P` cannot work: cd resolves the link too,
    # so both sides would be the real path and every symlink would pass.
    lexical=$(realpath -s -- "$given" 2>/dev/null) || refuse "cannot resolve ${given}"
    if [ "$lexical" != "$real" ]; then
        refuse "${given} resolves through a symlink to ${real} — register the real path"
    fi
    printf '%s\n' "$real"
}

cmd_add() {
    local given=${1:-}
    [ -n "$given" ] || { usage; exit 2; }
    [ -d "$given" ] || refuse "${given} is not a directory"

    local dir; dir=$(assert_no_symlink "$given") || exit 1

    local manifest="${dir}/extend/plugin.tsv"
    [ -r "$manifest" ] || refuse "${dir} has no extend/plugin.tsv — it is not a plugin"

    local rows
    rows=$(_vault_plugin_read_tsv "$manifest" "$VAULT_PLUGIN_MANIFEST_HEADER") \
        || refuse "${manifest} does not start with the header: name<TAB>points"
    [ -n "$rows" ] || refuse "${manifest} declares no plugin"
    [ "$(printf '%s\n' "$rows" | wc -l)" -eq 1 ] || refuse "${manifest} declares more than one plugin"

    local name points
    IFS=$'\t' read -r name points <<<"$rows"
    [ -n "$name" ] || refuse "${manifest} names no plugin"

    vault_plugin_check_points "$points" || refuse "${name} declares a point this framework does not implement"

    # Every declared point must exist and be executable NOW. A point run through its own shebang
    # cannot start if the file is not executable, and finding that out during onboarding is worse
    # than finding it out here.
    local p file rest=$points
    while [ -n "$rest" ]; do
        case "$rest" in
            *,*) p=${rest%%,*}; rest=${rest#*,} ;;
            *)   p=$rest; rest="" ;;
        esac
        p=$(printf '%s' "$p" | tr -d '[:space:]')
        [ -n "$p" ] || continue
        file=$(vault_plugin_point_file "$dir" "$p") || continue
        [ -f "$file" ] || refuse "${name} declares point '${p}' and ${file} does not exist"
        if [ "$p" != "dod-keys" ] && [ ! -x "$file" ]; then
            refuse "${name}: ${file} is not executable"
        fi
    done

    local reg; reg=$(vault_plugin_registry_path)
    mkdir -p "$(dirname "$reg")" || refuse "cannot create $(dirname "$reg")"
    if [ ! -e "$reg" ]; then
        printf '%s\n' "$VAULT_PLUGIN_REGISTRY_HEADER" > "$reg" || refuse "cannot write ${reg}"
    fi
    chmod 0600 "$reg" 2>/dev/null || true

    # Replacing rather than appending: two rows for one name would give cmd_config two paths and
    # make the init point run twice.
    local old
    old=$(vault_plugin_path "$name" 2>/dev/null || true)
    if [ -n "$old" ]; then
        printf 're-registering %s (was %s)\n' "$name" "$old"
        cmd_remove "$name" >/dev/null
    fi

    printf '%s\t%s\t%s\n' "$name" "$dir" "$points" >> "$reg" || refuse "cannot write ${reg}"
    printf 'registered %s -> %s [%s]\n' "$name" "$dir" "$points"
}

# ---------------------------------------------------------------------------- remove

cmd_remove() {
    local want=${1:-}
    [ -n "$want" ] || { usage; exit 2; }
    local reg; reg=$(vault_plugin_registry_path)
    [ -r "$reg" ] || refuse "no registry at ${reg}"

    local tmp; tmp=$(mktemp) || refuse "cannot create a temporary file"
    awk -F'\t' -v want="$want" 'NR == 1 || $1 != want' "$reg" > "$tmp" \
        && mv "$tmp" "$reg" || { rm -f "$tmp"; refuse "cannot rewrite ${reg}"; }
    chmod 0600 "$reg" 2>/dev/null || true
    printf 'removed %s\n' "$want"
}

# ---------------------------------------------------------------------------- list / doctor

cmd_list() {
    local rows; rows=$(vault_plugin_list) || exit 1
    if [ -z "$rows" ]; then
        printf 'no plugins registered (%s)\n' "$(vault_plugin_registry_path)"
        return 0
    fi
    printf '%s\n' "$rows" | while IFS=$'\t' read -r name path points; do
        printf '%-28s %-12s %s\n' "$name" "$points" "$path"
    done
}

# doctor reports; it never repairs. A path that stopped resolving is the operator's decision to make
# again, not this script's to erase.
cmd_doctor() {
    local rows; rows=$(vault_plugin_list) || exit 1
    [ -n "$rows" ] || { printf 'no plugins registered\n'; return 0; }

    local bad=0 name path points p file
    while IFS=$'\t' read -r name path points; do
        if [ ! -d "$path" ]; then
            printf '  GONE      %-24s %s\n' "$name" "$path"; bad=1; continue
        fi
        local rest=$points
        while [ -n "$rest" ]; do
            case "$rest" in
                *,*) p=${rest%%,*}; rest=${rest#*,} ;;
                *)   p=$rest; rest="" ;;
            esac
            p=$(printf '%s' "$p" | tr -d '[:space:]')
            [ -n "$p" ] || continue
            file=$(vault_plugin_point_file "$path" "$p") || continue
            if [ ! -f "$file" ]; then
                printf '  MISSING   %-24s %s\n' "$name" "$file"; bad=1
            elif [ "$p" != "dod-keys" ] && [ ! -x "$file" ]; then
                printf '  NOT EXEC  %-24s %s\n' "$name" "$file"; bad=1
            else
                printf '  ok        %-24s %s\n' "$name" "$file"
            fi
        done
    done <<<"$rows"
    [ "$bad" -eq 0 ] || exit 1
}

# ---------------------------------------------------------------------------- dispatch

main() {
    local sub=${1:-}
    case "$sub" in
        -h|--help|'') usage; exit 0 ;;
    esac
    shift
    case "$sub" in
        add)    cmd_add "${1:-}" ;;
        remove) cmd_remove "${1:-}" ;;
        list)   cmd_list ;;
        doctor) cmd_doctor ;;
        *)      usage; exit 2 ;;
    esac
}

main "$@"
