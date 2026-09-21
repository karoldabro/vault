#!/usr/bin/env bash
# rule-grep.sh — runs one declarative rule file (`probes/rules/<slug>.grep`) and prints finding rows.
# Native probe. The rule file is data: it never runs as code. Format and limits: commands/_shared/probe-kit.md
# section "Rule files".
#
# Usage:  probes/rule-grep.sh --check <slug> --rule <file> [--repo <root>] [--fixture <file> | --count-files]
#
# --rule       a path relative to --repo (else $PROBE_REPO, else the working directory), or an absolute path.
# --fixture    scan that one file, print its base name as the file field, ignore `glob` and the probes/ skip.
# --count-files  print how many files the globs select, then exit 0.
# Env:    PROBE_RULE_TIMEOUT (10 seconds per batch of 500 files), PROBE_FILES (the list the core exports).
#
# Exit: 0 clean · 1 findings · 2 malformed rule or usage error

set -uo pipefail
export LC_ALL=C
PROBE_FRAMEWORK=${PROBE_FRAMEWORK:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
. "$PROBE_FRAMEWORK/lib/probe-emit.sh"
. "$PROBE_FRAMEWORK/lib/probe-scope.sh"
PROBE_GIT_BIN=$(command -v git || true)

rule="" fixture="" countfiles=0 rest=()
while [ $# -gt 0 ]; do
    case $1 in
        --rule|--fixture) [ $# -ge 2 ] || probe_die "$1 needs a value"
            if [ "$1" = --rule ]; then rule=$2; else fixture=$2; fi; shift 2 ;;
        --count-files) countfiles=1; shift ;;
        *) rest+=("$1"); shift ;;
    esac
done
probe_args "${rest[@]+"${rest[@]}"}"
[ -n "$rule" ] || probe_die "--rule is required"
repo=$(cd "$A_REPO" && pwd)

# Locate the rule file: a link, a path leaving the repo and a `..` component are refused.
case $rule in
    /*) [ -f "$rule" ] && [ ! -L "$rule" ] || probe_die "the rule is not a regular file: $rule"; rulefile=$rule ;;
    *)  case /$rule/ in */../*|*/./*) probe_die "the rule path may not hold .. or ." ;; esac
        case $rule in -*) probe_die "the rule path may not start with a dash" ;; esac
        probe_safe_file "$repo" "$rule" || probe_die "the rule is not a regular file inside the repo: $rule"
        rulefile="$repo/$rule" ;;
esac

globs=() pattern="" severity="" message="" np=0 ns=0 nm=0
while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    case $line in ''|'#'*) continue ;; esac
    [[ $line =~ ^([a-z]+):\ ?(.*)$ ]] || probe_die "the rule has a line that is not key: value"
    key=${BASH_REMATCH[1]} val=${BASH_REMATCH[2]}
    case $key in
        glob) globs+=("$val") ;;
        pattern) pattern=$val; np=$((np + 1)) ;;
        severity) severity=$val; ns=$((ns + 1)) ;;
        message) message=$val; nm=$((nm + 1)) ;;
        *) probe_die "the rule has an unknown key: $key" ;;
    esac
done < "$rulefile"
[ "${#globs[@]}" -ge 1 ] || probe_die "the rule needs a glob"
[ "$np" -eq 1 ] && [ -n "$pattern" ] || probe_die "the rule needs exactly one pattern"
[ "$ns" -eq 1 ] && [ "$nm" -eq 1 ] || probe_die "the rule needs one severity and one message"
case $severity in error|warn|info) ;; *) probe_die "severity must be error, warn or info" ;; esac
[[ $message =~ ^[\ -~]{1,200}$ ]] || probe_die "the message must be printable ASCII of 1 to 200 characters"
[ "${#pattern}" -le 300 ] || probe_die "the pattern is longer than 300 characters"
[[ $pattern =~ [[:cntrl:]] ]] && probe_die "the pattern holds a control character"
for g in "${globs[@]}"; do
    [ -n "$g" ] && [[ $g != /* ]] && [[ $g != *..* ]] && ! [[ $g =~ [[:cntrl:]] ]] || probe_die "a glob is empty, absolute, holds .. or a control character"
done
grep -E -e "$pattern" < /dev/null > /dev/null 2>&1; [ $? -le 1 ] || probe_die "the pattern is not a valid extended regular expression"

files=()
if [ -n "$fixture" ]; then
    fixture=$(readlink -f -- "$fixture") && [ -f "$fixture" ] || probe_die "--fixture is not a file"
    files=("$fixture")
else
    TMP=$(mktemp -d "${TMPDIR:-/tmp}/rule-grep.XXXXXX") || probe_die "cannot create a temp directory"
    trap 'rm -rf "$TMP"' EXIT
    list=${PROBE_FILES:-}
    if [ -z "$list" ] || [ ! -r "$list" ]; then list="$TMP/files"; probe_files "$repo" "$list" || exit 2; fi
    while IFS= read -r -d '' f; do
        case $f in probes/*) continue ;; esac
        for g in "${globs[@]}"; do
            # shellcheck disable=SC2254
            case $f in $g) files+=("$f"); break ;; esac
        done
    done < "$list"
fi
if [ "$countfiles" -eq 1 ]; then printf '%d\n' "${#files[@]}"; exit 0; fi

cd "$repo" || exit 2
found=0 i=0 batch=500 to=${PROBE_RULE_TIMEOUT:-10}
while [ "$i" -lt "${#files[@]}" ] && [ "$found" -lt 200 ]; do
    out=$(timeout "$to" grep -E -n -I -H -Z -e "$pattern" -- "${files[@]:i:batch}" 2> /dev/null | LC_ALL=C tr -d '\001\002' | LC_ALL=C tr '\n\000' '\001\002'; exit "${PIPESTATUS[0]}")
    rc=$?
    case $rc in 0|1) ;; 124) probe_die "the rule timed out after $to seconds" ;; *) probe_die "grep failed with exit $rc" ;; esac
    i=$((i + batch))
    [ -n "$out" ] || continue
    while IFS= read -r -d $'\001' rowtxt; do
        name=${rowtxt%%$'\002'*}
        [ -n "$rowtxt" ] || continue
        rest2=${rowtxt#*$'\002'}
        ln=${rest2%%:*}
        [ -z "$fixture" ] || name=$(basename "$name")
        probe_finding "$A_CHECK" "$name" "$ln" "$severity" "$A_CHECK" "$message"; found=$((found + 1))
        [ "$found" -lt 200 ] || break
    done <<< "$out"$'\001'
done
[ "$found" -eq 0 ]; [ $? -eq 0 ] && exit 0 || exit 1
