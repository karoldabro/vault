#!/usr/bin/env bash
# SC-6 of vault/plans/2026-09-22-1023-spec-reading-probes.md — bin/plan-probes.sh verify accepts
# zero or more auditor-rows files.
# Exit 0 met, 1 not met, 2 cannot say yet.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pp="$root/bin/plan-probes.sh"
[ -x "$pp" ] || { echo "bin/plan-probes.sh not written yet — cannot say"; exit 2; }
grep -q 'local out=${1:-} rows=${2:-}' "$pp" && { echo "verify still takes exactly one rows file — cannot say"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
T=$(printf '\t')
fail() { printf '%s\n' "$*"; exit 1; }

row1="spec-tables${T}f${T}1${T}warn${T}dup-column-set${T}m"
row2="spec-naming${T}f${T}2${T}warn${T}naming-snake-case${T}m"
row3="similar-symbols${T}f${T}3${T}warn${T}similar-symbol${T}m"

out="$tmp/out"; mkdir -p "$out"
printf 'full\n' > "$out/tier.txt"
printf '%s\n%s\n%s\n' "$row1" "$row2" "$row3" > "$out/advisory.tsv"
: > "$out/confirmed.tsv"

printf 'applies\t%s\n' "$row1" > "$tmp/r1"
printf 'does-not-apply\t%s\n' "$row2" > "$tmp/r2"
printf 'unclear\t%s\nbogus\tnot-a-block-row\n' "$row3" > "$tmp/r3"

o=$("$pp" verify "$out" "$tmp/r1" "$tmp/r2" "$tmp/r3" 2>"$tmp/err"); rc=$?
[ "$rc" -eq 0 ] || fail "verify with three rows files exited $rc: $(cat "$tmp/err")"
printf '%s\n' "$o" | grep -qF "applies	$row1" || fail "row1 not kept: $o"
printf '%s\n' "$o" | grep -qF "does-not-apply	$row2" || fail "row2 not kept: $o"
printf '%s\n' "$o" | grep -qF "unclear	$row3" || fail "row3 not kept: $o"
printf '%s\n' "$o" | grep -q 'not-a-block-row' && fail "an invalid line was kept: $o"
printf '%s\n' "$o" | grep -q '^note: 1 auditor lines were dropped' || fail "the dropped line was not counted: $o"

o0=$("$pp" verify "$out" 2>"$tmp/err0"); rc0=$?
[ "$rc0" -eq 0 ] || fail "verify with zero rows files exited $rc0: $(cat "$tmp/err0")"
printf '%s\n' "$o0" | grep -q '^applies\|^does-not-apply\|^unclear' && fail "verify with no rows files printed an auditor line: $o0"
exit 0
