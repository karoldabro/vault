#!/usr/bin/env bash
# plugin-registry.sh — read the plugin registry and call a plugin's extension points.
#
# Contract: vault/architecture/plugin-extension-contract.md. Two points exist, `init` and
# `dod-keys`. Commands and Claude Code hooks need nothing from here — Claude Code composes those
# across plugins already.
#
# Sourced by bin/vault-plugin.sh, bin/vault-init.sh and bin/gate.sh. Every function returns 0 unless
# its own contract says otherwise, because a host that sources this file is doing work the operator
# needs whether or not an extension succeeded.
#
# Registry: ${VAULT_HOME:-$HOME/vault}/_global/plugins.tsv, mode 0600, written only by
# bin/vault-plugin.sh.

# The points this framework implements. A plugin naming anything else is refused at registration,
# which is the only compatibility question this framework owns: Claude Code's own `dependencies`
# key in a plugin's manifest gates install-time compatibility.
VAULT_PLUGIN_POINTS="init dod-keys"

VAULT_PLUGIN_REGISTRY_HEADER=$'name\tpath\tpoints'
VAULT_PLUGIN_MANIFEST_HEADER=$'name\tpoints'
VAULT_PLUGIN_DODKEYS_HEADER=$'key\twhy'

# vault_plugin_registry_path
# Where the registry lives. VAULT_HOME is honoured so a test can redirect it.
vault_plugin_registry_path() {
    printf '%s/_global/plugins.tsv\n' "${VAULT_HOME:-${HOME}/vault}"
}

# _vault_plugin_warn <message...>
# Every failure here is a warning on stderr, never an exit. The host keeps going.
_vault_plugin_warn() {
    printf 'plugin: %s\n' "$*" >&2
}

# _vault_plugin_read_tsv <file> <expected-header>
# Emit the data rows of a tab-separated file on stdout, one per line.
#
# Refuses (exit 2, nothing emitted) when line 1 is not the expected header. A commented-out header
# would be skipped as a comment, leaving nothing to count field widths against — so the header is
# required to be literal and uncommented. Rows whose field count differs from the header are dropped
# with a warning rather than parsed into the wrong columns.
_vault_plugin_read_tsv() {
    local file=$1 expected=$2
    [ -r "$file" ] || return 2

    local first
    IFS= read -r first < "$file" || return 2
    first=${first%$'\r'}
    if [ "$first" != "$expected" ]; then
        _vault_plugin_warn "$file line 1 is not the expected header"
        return 2
    fi

    local want
    want=$(printf '%s' "$expected" | awk -F'\t' '{print NF}')

    awk -F'\t' -v want="$want" -v file="$file" '
        NR == 1 { next }
        /^[[:space:]]*$/ { next }
        /^#/ { next }
        {
            sub(/\r$/, "")
            if (NF != want) {
                printf("plugin: %s line %d has %d fields, expected %d — row skipped\n",
                       file, NR, NF, want) > "/dev/stderr"
                next
            }
            print
        }
    ' "$file"
}

# vault_plugin_list
# Emit one `name<TAB>path<TAB>points` row per registered plugin.
#
# An absent registry is silence and exit 0: no plugin is registered, which is the normal case.
# Two rows sharing a name is a refusal (exit 1, nothing emitted) — `cmd_config` would otherwise get
# two paths for one name and pick whichever came first.
vault_plugin_list() {
    local reg; reg=$(vault_plugin_registry_path)
    [ -r "$reg" ] || return 0

    local rows
    rows=$(_vault_plugin_read_tsv "$reg" "$VAULT_PLUGIN_REGISTRY_HEADER") || return 0
    [ -n "$rows" ] || return 0

    local dupes
    dupes=$(printf '%s\n' "$rows" | cut -f1 | sort | uniq -d)
    if [ -n "$dupes" ]; then
        _vault_plugin_warn "registry holds more than one row named: $(printf '%s' "$dupes" | tr '\n' ' ')"
        return 1
    fi

    printf '%s\n' "$rows"
}

# vault_plugin_path <name>
# The registered directory for one plugin, or exit 1 with nothing on stdout.
vault_plugin_path() {
    local want=$1 name path points
    while IFS=$'\t' read -r name path points; do
        [ -n "$name" ] || continue
        if [ "$name" = "$want" ]; then
            printf '%s\n' "$path"
            return 0
        fi
    done < <(vault_plugin_list)
    return 1
}

# vault_plugin_check_points <points-csv>
# Exit 0 when every named point is implemented here. Otherwise exit 1, naming the first unknown
# point and the set this framework does implement — an operator whose plugin was written against a
# newer framework needs to be told that upgrading is the fix.
vault_plugin_check_points() {
    local csv=$1 p known
    [ -n "$csv" ] && [ "$csv" != "-" ] || {
        _vault_plugin_warn "declares no points"
        return 1
    }
    local rest=$csv k
    # Split on commas by hand. Setting IFS=, for the outer loop would still be in force for the
    # inner one, which splits a space-separated list — and every point would then read as unknown.
    while [ -n "$rest" ]; do
        case "$rest" in
            *,*) p=${rest%%,*}; rest=${rest#*,} ;;
            *)   p=$rest; rest="" ;;
        esac
        p=$(printf '%s' "$p" | tr -d '[:space:]')
        [ -n "$p" ] || continue
        known=0
        for k in $VAULT_PLUGIN_POINTS; do
            [ "$p" = "$k" ] && known=1
        done
        if [ "$known" -eq 0 ]; then
            _vault_plugin_warn "point '${p}' is not implemented by this framework; it implements: ${VAULT_PLUGIN_POINTS}"
            return 1
        fi
    done
    return 0
}

# _vault_plugin_declares <points-csv> <point>
_vault_plugin_declares() {
    local csv=$1 want=$2 rest=$1 p
    while [ -n "$rest" ]; do
        case "$rest" in
            *,*) p=${rest%%,*}; rest=${rest#*,} ;;
            *)   p=$rest; rest="" ;;
        esac
        [ "$(printf '%s' "$p" | tr -d '[:space:]')" = "$want" ] && return 0
    done
    return 1
}

# vault_plugin_point_file <plugin-dir> <point>
vault_plugin_point_file() {
    case "$2" in
        init)     printf '%s/extend/init.sh\n' "$1" ;;
        dod-keys) printf '%s/extend/dod-keys.tsv\n' "$1" ;;
        *)        return 1 ;;
    esac
}

# vault_plugin_run_point <point> [args...]
# Run <point> for every registered plugin that declares it.
#
# ALWAYS returns 0. A point that fails must not stop the host: onboarding a repo is work the
# operator needs whether or not an extension succeeded.
#
# The script is executed through its own shebang in a child process — never sourced, and never
# forced through `sh`. Sourcing lets a point redefine the host's functions and end the host outright
# when it calls `exit`. Forcing `sh` runs a bash or python point under dash, and the syntax error
# then reads as a plugin that declined rather than one that crashed.
#
# Stdin is closed so a point cannot consume the host's input.
#
# Exit 1 means the point declined. Any higher exit means it could not run. Collapsing the two would
# report a crashed script as one that chose to do nothing.
vault_plugin_run_point() {
    local point=$1; shift
    local name path points file rc

    while IFS=$'\t' read -r name path points; do
        [ -n "$name" ] || continue
        _vault_plugin_declares "$points" "$point" || continue

        file=$(vault_plugin_point_file "$path" "$point") || continue

        if [ ! -f "$file" ]; then
            _vault_plugin_warn "${name}: ${point} file is gone (${file})"
            continue
        fi
        if [ ! -x "$file" ]; then
            _vault_plugin_warn "${name}: ${point} file is not executable (${file})"
            continue
        fi

        rc=0
        "$file" "$@" </dev/null || rc=$?
        if [ "$rc" -eq 1 ]; then
            _vault_plugin_warn "${name}: ${point} declined"
        elif [ "$rc" -ne 0 ]; then
            _vault_plugin_warn "${name}: ${point} could not run (exit ${rc})"
        fi
    done < <(vault_plugin_list)

    return 0
}

# vault_plugin_dod_keys <name>
# Emit `key<TAB>why` for every key that plugin declares. Silence and exit 0 when the plugin is not
# registered, does not declare the point, or its file cannot be read: an unreadable declaration is a
# note, never a refusal, because refusing would block a repo over a plugin's own defect.
vault_plugin_dod_keys() {
    local want=$1 path file
    path=$(vault_plugin_path "$want") || return 0
    [ -n "$path" ] || return 0

    file=$(vault_plugin_point_file "$path" dod-keys) || return 0
    [ -r "$file" ] || return 0

    _vault_plugin_read_tsv "$file" "$VAULT_PLUGIN_DODKEYS_HEADER" || return 0
}
