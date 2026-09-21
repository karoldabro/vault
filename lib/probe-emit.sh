#!/usr/bin/env bash
# probe-emit.sh — the one place a finding row is built, and the helpers every native probe shares.
# Sourced by bin/probe.sh, lib/probe-parsers.sh and every native probe. Contract:
# commands/_shared/probe-kit.md. Loading it twice is harmless.

[ -n "${PROBE_EMIT_LOADED:-}" ] && return 0
PROBE_EMIT_LOADED=1

probe_die() { printf 'probe: %s\n' "$*" >&2; exit 2; }

# Text with every control byte, tab and newline included, turned into a space.
probe_sanitize() { printf '%s' "$1" | LC_ALL=C tr '\000-\037\177' ' '; }

# probe_finding <probe> <file> <line> <severity> <rule> <message>
# Prints one six-field row. A line that is not a number becomes 0, and a message is cut at 240 bytes.
probe_finding() {
    local probe=$1 file=$2 line=$3 sev=$4 rule=$5 msg=$6
    case $line in ''|*[!0-9]*) line=0 ;; esac
    msg=$(probe_sanitize "$msg")
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$probe" "$(probe_sanitize "$file")" "$line" "$sev" "$(probe_sanitize "$rule")" "${msg:0:240}"
}

# probe_args "$@" — sets A_CHECK, A_REPO, A_SPEC and A_NAMES for a native probe. The repo, the file list
# and the spec come from the environment the core exports, and an option overrides them for a manual run.
probe_args() {
    A_CHECK="" A_REPO=${PROBE_REPO:-$PWD} A_SPEC=${PROBE_SPEC:-} A_NAMES=""
    while [ $# -gt 0 ]; do
        case $1 in
            --check|--repo|--spec|--names)
                [ $# -ge 2 ] || probe_die "$1 needs a value"
                case $1 in
                    --check) A_CHECK=$2 ;;
                    --repo)  A_REPO=$2; [ -d "$A_REPO" ] || probe_die "--repo needs a directory" ;;
                    --spec)  A_SPEC=$2; [ -r "$A_SPEC" ] || probe_die "--spec needs a readable file" ;;
                    --names) A_NAMES=$2 ;;
                esac
                shift 2 ;;
            *) probe_die "unknown option: $1" ;;
        esac
    done
    case $A_CHECK in ''|*[!a-z0-9-]*) probe_die "--check must match [a-z0-9-]+" ;; esac
    return 0
}

# probe_native_init "$@" — the start of every native probe: parses the options, then sets `repo`, a private
# temp directory `TMP` that is removed on exit, and `LIST`, the NUL list of files the core exports.
# A probe that compares files with each other builds the whole-tree list with `probe_files "$repo" "$TMP/full"`.
probe_native_init() {
    probe_args "$@"
    repo=$(cd "$A_REPO" && pwd)
    TMP=$(mktemp -d "${TMPDIR:-/tmp}/probe-native.XXXXXX") || probe_die "cannot create a temp directory"
    trap 'rm -rf "$TMP"' EXIT
    trap 'rm -rf "$TMP"; exit 143' INT TERM HUP
    LIST=${PROBE_FILES:-}
    if [ -z "$LIST" ] || [ ! -r "$LIST" ]; then LIST="$TMP/files"; probe_files "$repo" "$LIST" || exit 2; fi
}

# probe_emit_sorted <check> — reads `file line severity rule message` lines on stdin and prints them as
# finding rows in file and line order. Returns 1 when there is at least one. Call it last in a probe.
probe_emit_sorted() {
    local check=$1
    LC_ALL=C sort -t "$(printf '\t')" -k1,1 -k2,2n | {
        local found=0 file line sev rule msg
        while IFS=$'\t' read -r file line sev rule msg; do
            probe_finding "$check" "$file" "$line" "$sev" "$rule" "$msg"; found=1
        done
        [ "$found" -eq 0 ] || return 1
    }
}
