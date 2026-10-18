#!/usr/bin/env bash
# vault-check.sh — run a repo's quality checks for one stage of EXECUTE and print what they found.
#
# Usage:  bin/vault-check.sh static|tests --repo <root> --base <ref>
#
# static  the static checks on the working tree against <base>; called before a unit is done
# tests   the tests, changed-line coverage and mutation testing on the same change
#
# A plugin the repo opts into (`plugins:` in VAULT.md) that declares the `check` point measures the
# stage. With none, the stage falls back to the repo's own `lint_command` (static) or `test_command`
# (tests) and says so. Contract: vault/architecture/plugin-extension-contract.md, `check` point.
#
# Output: tab-separated lines — finding, failed, coverage, survivor, unmeasured, plus this script's
# own fallback, floor-below and withheld lines — capped at VAULT_CHECK_LINES (200) lines and
# VAULT_CHECK_BYTES (12000) bytes.
#
# Env:    VAULT_CHECK_FILES is exported to the point: a file listing every changed path, NUL-separated,
#         untracked files included.
#         VAULT_CHECK_TIMEOUT seconds before a point or command is stopped (default 1800).
#
# Exit: 0 measured and acceptable · 1 measured and worse · 2 could not measure, or usage

set -uo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=../lib/vault-md.sh
. "${ROOT}/lib/vault-md.sh" || { echo "vault-check: cannot load lib/vault-md.sh" >&2; exit 2; }
# shellcheck source=../lib/plugin-registry.sh
. "${ROOT}/lib/plugin-registry.sh" || { echo "vault-check: cannot load lib/plugin-registry.sh" >&2; exit 2; }

FLOOR=80
usage() { echo "usage: bin/vault-check.sh static|tests --repo <root> --base <ref>" >&2; exit 2; }

stage=${1:-}; shift || true
case "$stage" in static|tests) ;; *) usage ;; esac
repo=""; base=""
while [ $# -gt 0 ]; do
    case "$1" in
        --repo) repo=${2:-}; shift 2 || usage ;;
        --base) base=${2:-}; shift 2 || usage ;;
        *) usage ;;
    esac
done
[ -n "$repo" ] && [ -n "$base" ] || usage
[ -d "$repo" ] || { echo "vault-check: not a directory: $repo" >&2; exit 2; }
repo=$(cd "$repo" && pwd)

tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT

# The changed paths: tracked changes against <base>, then untracked files, each counted as wholly new.
{ git -C "$repo" diff --name-only -z "$base" -- 2>/dev/null
  git -C "$repo" ls-files -z --others --exclude-standard 2>/dev/null; } > "$tmp/files"
export VAULT_CHECK_FILES="$tmp/files"

# emit <file>: print it within the line and byte caps, then state what was withheld.
emit() {
    local f=$1 lines=${VAULT_CHECK_LINES:-200} bytes=${VAULT_CHECK_BYTES:-12000} total shown
    total=$(grep -c '' "$f" || true)
    head -n "$lines" "$f" | head -c "$bytes" > "$tmp/shown"
    shown=$(grep -c '' "$tmp/shown" || true)
    cat "$tmp/shown"
    [ -s "$tmp/shown" ] && [ "$(tail -c1 "$tmp/shown" | od -An -c | tr -d ' ')" != '\n' ] && echo
    [ "$shown" -ge "$total" ] || printf 'withheld\t%d of %d lines\n' "$((total - shown))" "$total"
}

# floor_rule <output file> <exit>: apply the framework floor to `coverage` lines; print the new exit.
floor_rule() {
    local f=$1 rc=$2
    awk -F'\t' -v min="$FLOOR" -v rc="$rc" '
        $1 == "coverage" { seen = 1
            floor = ($3 == "-" || $3 == "") ? min : $3 + 0
            if (floor < min) { printf("floor-below\t%s\t%s\n", $3, min) > "/dev/stderr"; floor = min }
            if ($2 != "none" && $2 + 0 < floor) bad = 1 }
        $1 == "unmeasured" && $2 == "coverage" { seen = 1 }
        END { if (bad && rc < 1) rc = 1
              if (!seen) { print "no coverage line" > "/dev/stderr"; rc = 2 }
              print rc }' "$f"
}

declared=0
vault_plugin_check_declared "$repo"; case $? in
    0) declared=1 ;;
    2) printf 'unmeasured\t%s\t%s/VAULT.md plugins line cannot be read\n' "$stage" "$repo"; exit 2 ;;
esac

if [ "$declared" -eq 1 ]; then
    rc=0
    vault_plugin_run_check "$stage" "$repo" "$base" > "$tmp/out" || rc=$?
    if [ "$stage" = tests ] && [ "$rc" -lt 2 ]; then
        rc=$(floor_rule "$tmp/out" "$rc" 2>"$tmp/notes")
        if grep -q 'no coverage line' "$tmp/notes"; then
            printf 'unmeasured\tcoverage\tthe check point printed no coverage line\n' >> "$tmp/out"
        fi
        grep '^floor-below' "$tmp/notes" >> "$tmp/out" || true
    fi
    emit "$tmp/out"
    exit "$rc"
fi

key=lint_command; [ "$stage" = tests ] && key=test_command
printf 'fallback\tscope repo\tno plugin in %s/VAULT.md declares check; running %s\n' "$repo" "$key"
if [ "$stage" = tests ]; then
    printf 'unmeasured\tcoverage\tno check plugin measures it\n'
    printf 'unmeasured\tmutation\tno check plugin measures it\n'
fi

cmd=$(vault_md_key "$repo" "$key") || { printf 'unmeasured\t%s\t%s is missing from VAULT.md\n' "$stage" "$key"; exit 2; }
cmd=$(printf '%s' "$cmd" | sed -E 's/[[:space:]]+#[[:space:]].*$//')
case "$cmd" in
    absent:*) printf 'unmeasured\t%s\t%s is %s\n' "$stage" "$key" "$cmd"; exit 2 ;;
    '') printf 'unmeasured\t%s\t%s is empty\n' "$stage" "$key"; exit 2 ;;
esac
if printf '%s' "$cmd" | grep -qE '<[^<>]+>|\{\{[^}]*\}\}'; then
    printf 'unmeasured\t%s\t%s is a template, not a runnable command: %s\n' "$stage" "$key" "$cmd"
    exit 2
fi

rc=0
if command -v timeout >/dev/null 2>&1; then
    (cd "$repo" && timeout "${VAULT_CHECK_TIMEOUT:-1800}" bash -c "$cmd") > "$tmp/out" 2>&1 </dev/null || rc=$?
else
    (cd "$repo" && bash -c "$cmd") > "$tmp/out" 2>&1 </dev/null || rc=$?
fi
emit "$tmp/out"
case "$rc" in
    0) exit 0 ;;
    124) printf 'unmeasured\t%s\t%s timed out\n' "$stage" "$key"; exit 2 ;;
    126|127) printf 'unmeasured\t%s\t%s could not run (exit %s)\n' "$stage" "$key" "$rc"; exit 2 ;;
    *) exit 1 ;;
esac
