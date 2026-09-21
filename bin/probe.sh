#!/usr/bin/env bash
# probe.sh — run the deterministic probes of a repo and print their findings.
#
# Usage:  bin/probe.sh list   [--repo <root>] [--allow-repo-registry]
#         bin/probe.sh detect [--repo <root>] [--allow-repo-registry] [--no-repo-code]
#         bin/probe.sh run <plan|review> [--repo <root>] [--spec <file>] [--only <id>] [--max-cost S|M|L]
#                          [--no-repo-code] [--allow-repo-registry]
#         bin/probe.sh diff  [--repo <root>] [--base <ref> | --changed-list <file>] [same options as run]
#         bin/probe.sh scale [--repo <root>]
#
# Findings go to stdout as six tab separated fields (probe file line severity rule message). Status lines
# go to stderr: ran, skipped, absent and failed. A probe never installs a tool; an absent tool prints
# the command the operator runs. Contract: commands/_shared/probe-kit.md.
#
# Exit: 0 clean · 1 findings · 2 a probe was absent or failed, or a usage error

set -uo pipefail
export LC_ALL=C
IFS=$' \t\n'
unset BASH_ENV ENV CDPATH GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES \
    GIT_EXEC_PATH GIT_CONFIG_PARAMETERS GIT_COMMON_DIR GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0
# Keep only absolute PATH entries, so a repo file named like a tool is never picked up through `.`.
clean=""; IFS=: read -ra parts <<< "$PATH"
for p in "${parts[@]}"; do case $p in /*) clean="${clean:+$clean:}$p" ;; esac; done
PATH=${clean:-/usr/bin:/bin}; unset clean parts p

PROBE_SELF="$(readlink -f "${BASH_SOURCE[0]}")"
PROBE_FRAMEWORK="$(cd "$(dirname "$PROBE_SELF")/.." && pwd)"
for lib in emit scope registry parsers run; do
    # shellcheck source=../lib/probe-emit.sh
    . "$PROBE_FRAMEWORK/lib/probe-$lib.sh" || { echo "probe: cannot load lib/probe-$lib.sh" >&2; exit 2; }
done
PROBE_GIT_BIN=$(command -v git || true)

usage() { sed -n '2,15p' "$PROBE_SELF" | sed 's/^# \{0,1\}//'; }

cmd=${1:-}
case $cmd in
    -h|--help|help|'') usage; [ -n "$cmd" ] && exit 0; exit 2 ;;
    list|detect|run|diff|scale) shift ;;
    *) probe_die "unknown command: $cmd" ;;
esac

stage="" repo="" spec="" only="" maxcost="" base=HEAD nocode=0 allow=0 clist="" base_set=0
if [ "$cmd" = run ]; then
    stage=${1:-}; shift || true
    case $stage in
        plan|review) ;;
        diff) probe_die "run takes plan or review; use: probe.sh diff" ;;
        *) probe_die "run needs a stage: plan or review" ;;
    esac
fi
while [ $# -gt 0 ]; do
    case $1 in
        --repo|--spec|--only|--base|--max-cost|--changed-list)
            [ $# -ge 2 ] || probe_die "$1 needs a value"
            case $1 in --repo) repo=$2 ;; --spec) spec=$2 ;; --only) only=$2 ;; --base) base=$2; base_set=1 ;; --max-cost) maxcost=$2 ;; --changed-list) clist=$2 ;; esac
            shift 2 ;;
        --no-repo-code) nocode=1; shift ;;
        --allow-repo-registry) allow=1; shift ;;
        *) probe_die "unknown option: $1" ;;
    esac
done
case ${PROBE_TOOLS_FROM:-} in ''|image) ;; *) probe_die "PROBE_TOOLS_FROM must be image or unset" ;; esac
if [ -n "$clist" ]; then
    [ "$cmd" = diff ] || probe_die "--changed-list belongs to diff"
    [ "$base_set" = 0 ] || probe_die "--changed-list and --base exclude each other"
    [ -r "$clist" ] && [ -f "$clist" ] || probe_die "--changed-list needs a readable file: $clist"
    clist=$(readlink -f "$clist")
fi
repo=${repo:-$PWD}
[ -d "$repo" ] || probe_die "--repo needs a directory: $repo"
repo=$(cd "$repo" && pwd)
case $only in ''|*[!a-z0-9-]*) [ -z "$only" ] || probe_die "--only must match [a-z0-9-]+" ;; esac
case $maxcost in ''|S|M|L) ;; *) probe_die "--max-cost must be S, M or L" ;; esac
[ -z "$spec" ] || { [ -r "$spec" ] || probe_die "--spec needs a readable file: $spec"; spec=$(readlink -f "$spec"); }

PROBE_TMP=$(mktemp -d "${TMPDIR:-/tmp}/probe.XXXXXX") || probe_die "cannot create a temp directory"
trap 'rm -rf "$PROBE_TMP"' EXIT
trap 'probe_abort; exit 143' INT TERM HUP
export PROBE_REPO="$repo" PROBE_FRAMEWORK PROBE_SPEC="$spec" PROBE_FILES="$PROBE_TMP/files" PROBE_TMP
export PROBE_NO_REPO_CODE=$nocode PROBE_MAXRANK=3
[ -z "$maxcost" ] || PROBE_MAXRANK=$(probe_rank "$maxcost")

rows=$(probe_registry "$repo" "$allow") || exit 2

file_list() {
    if [ "$cmd" = diff ]; then
        if [ -n "$clist" ]; then probe_filter_list "$repo" "$PROBE_FILES.skipped" < "$clist" | LC_ALL=C sort -z > "$PROBE_FILES"
        else probe_changed "$repo" "$base" "$PROBE_FILES" || exit 2; fi
        tr '\0' '\n' < "$PROBE_FILES" > "$PROBE_TMP/changed"
        export PROBE_CHANGED_FILE="$PROBE_TMP/changed"
    else
        probe_files "$repo" "$PROBE_FILES" || exit 2
    fi
    local skipped; skipped=$(cat "$PROBE_FILES.skipped" 2>/dev/null || echo 0)
    [ "${skipped:-0}" -eq 0 ] || probe_status "skipped: files: $skipped with a control byte in the name"
}

# rows are: origin id stack stage detect run parser cost trust install
each_row() { # each_row <function> — calls it with the ten fields of every row that passes --only
    local origin id stack st detect run parser cost trust install
    while IFS=$'\t' read -r origin id stack st detect run parser cost trust install; do
        [ -n "$id" ] || continue
        [ -z "$only" ] || [ "$id" = "$only" ] || continue
        "$1" "$origin" "$id" "$stack" "$st" "$detect" "$run" "$parser" "$cost" "$trust" "$install"
    done <<< "$rows"
}

do_list() {
    [ "$1" = repo ] && [ "$allow" != 1 ] && return 0
    local status=ok
    probe_tool_present "$6" "$([ "$1" = repo ] && echo yes || echo "$9")" "$repo" || { status=$(probe_sanitize "${10}"); status="absent: ${status:0:300}"; }
    printf '%s\t%s\t%s\t%s\t%s\n' "$2" "$4" "$8" "$1" "$status"
}

do_detect() {
    [ "$1" = repo ] && [ "$nocode" = 1 ] && return 0
    probe_detect "$5" "$([ "$1" = repo ] && echo yes || echo "$9")" "$repo" && printf '%s\t%s\n' "$2" "$4"
    return 0
}

matched=0
do_run() {
    case $cmd in
        run)  [ "$4" = "$stage" ] || return 0 ;;
    esac
    matched=$((matched + 1))
    probe_run_row "$@"
}

case $cmd in
    list)   each_row do_list; exit 0 ;;
    detect) each_row do_detect; exit 0 ;;
    scale)  probe_files "$repo" "$PROBE_FILES" || exit 2; probe_scale "$repo" "$PROBE_FILES"; exit 0 ;;
    run|diff)
        file_list
        each_row do_run
        [ -z "$only" ] || [ "$matched" -gt 0 ] || probe_die "no probe named $only runs at this stage"
        [ "$PROBE_BAD" -eq 0 ] || exit 2
        [ "$PROBE_FOUND" -eq 0 ] || exit 1
        exit 0 ;;
esac
