#!/usr/bin/env bash
# vault-plugin.sh — register a framework plugin, and inspect what is registered.
#
# Contract: vault/architecture/plugin-extension-contract.md.
#
# Usage:  bin/vault-plugin.sh install <repo> [--yes] [--dir <path>]
#                                                  clone a plugin repo and register it
#         bin/vault-plugin.sh add <plugin-dir>     register a directory already on disk
#         bin/vault-plugin.sh remove <name>        drop it
#         bin/vault-plugin.sh list                 one row per registered plugin
#         bin/vault-plugin.sh doctor               check every registered path still resolves
#         bin/vault-plugin.sh -h
#
# <repo> is `owner/repo`, a git URL, a local path, or a bare name listed in this framework's own
# .claude-plugin/marketplace.json. A bare name is resolved ONLY from that file: guessing an owner for
# an unknown name is how a typo installs someone else's code.
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

# ---------------------------------------------------------------------------- install

PLUGIN_DIR_DEFAULT="${VAULT_PLUGIN_DIR:-${HOME}/workspace}"

# resolve_spec <spec> — print the git URL to clone, or the literal path when one exists.
resolve_spec() {
    local spec=$1

    # An existing directory wins: nothing is fetched and nothing is guessed.
    if [ -d "$spec" ]; then printf 'path\t%s\n' "$spec"; return 0; fi

    case "$spec" in
        http://*|https://*|git@*|ssh://*) printf 'url\t%s\n' "$spec"; return 0 ;;
        */*) printf 'url\thttps://github.com/%s.git\n' "${spec%.git}"; return 0 ;;
    esac

    # A bare name is resolved only from this framework's own marketplace. Deriving an owner from a
    # name nobody listed is how a typo clones somebody else's repository.
    local mp="${VAULT_ROOT}/.claude-plugin/marketplace.json" url
    url=$(python3 - "$mp" "$spec" <<'EOF' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
for p in d.get("plugins", []):
    if p.get("name") == sys.argv[2]:
        src = p.get("source")
        if isinstance(src, dict) and src.get("url"):
            print(src["url"]); sys.exit(0)
sys.exit(1)
EOF
    ) || return 1
    [ -n "$url" ] || return 1
    printf 'url\t%s\n' "$url"
}

cmd_install() {
    local spec="" dest_dir="$PLUGIN_DIR_DEFAULT" assume_yes=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --yes|-y) assume_yes=1; shift ;;
            --dir)    dest_dir=${2:-}; shift 2 ;;
            -*)       usage >&2; exit 2 ;;
            *)        [ -z "$spec" ] || { usage >&2; exit 2; }; spec=$1; shift ;;
        esac
    done
    [ -n "$spec" ] || { usage; exit 2; }

    local kind target resolved
    resolved=$(resolve_spec "$spec") \
        || refuse "cannot resolve '${spec}'. Give owner/repo, a git URL, a path, or a name listed in .claude-plugin/marketplace.json"
    IFS=$'\t' read -r kind target <<<"$resolved"

    local dir
    if [ "$kind" = path ]; then
        dir=$target
    else
        local name; name=$(basename "${target%.git}")
        dir="${dest_dir}/${name}"
        if [ -d "$dir" ]; then
            # Never pull. A silent fast-forward would change what executes without the operator
            # deciding again, which is the whole point of registering by hand.
            printf 'already cloned: %s (not updated)\n' "$dir"
        else
            command -v git >/dev/null 2>&1 || refuse "git is not installed"
            printf 'cloning %s -> %s\n' "$target" "$dir"
            mkdir -p "$dest_dir" || refuse "cannot create ${dest_dir}"
            git clone --quiet -- "$target" "$dir" || refuse "clone failed: ${target}"
        fi
    fi

    [ -r "${dir}/extend/plugin.tsv" ] || refuse "${dir} has no extend/plugin.tsv — it is not a framework plugin"

    # Show what is about to be trusted, then ask. The non-interactive branch is the conservative one:
    # a piped run registers nothing unless --yes says so.
    local rows name points
    rows=$(_vault_plugin_read_tsv "${dir}/extend/plugin.tsv" "$VAULT_PLUGIN_MANIFEST_HEADER") \
        || refuse "${dir}/extend/plugin.tsv does not start with the header: name<TAB>points"
    IFS=$'\t' read -r name points <<<"$rows"

    printf '\n  plugin  %s\n  path    %s\n  points  %s\n\n' "$name" "$dir" "$points"
    printf 'Registering runs this repo'"'"'s scripts during every vault-init from now on,\n'
    printf 'and trusts every future commit of it — not only the one on disk today.\n\n'

    if [ "$assume_yes" -ne 1 ]; then
        if [ -t 0 ]; then
            local reply=""
            printf 'Register %s? [y/N] ' "$name"
            read -r reply </dev/tty || reply=""
            case "$reply" in
                y|Y|yes|YES) ;;
                *) printf 'not registered. The clone is left at %s\n' "$dir"; exit 1 ;;
            esac
        else
            printf 'not registered: no terminal to confirm at. Re-run with --yes.\n' >&2
            exit 1
        fi
    fi

    cmd_add "$dir"
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
        install) cmd_install "$@" ;;
        add)    cmd_add "${1:-}" ;;
        remove) cmd_remove "${1:-}" ;;
        list)   cmd_list ;;
        doctor) cmd_doctor ;;
        *)      usage; exit 2 ;;
    esac
}

main "$@"
