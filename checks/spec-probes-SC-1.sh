#!/usr/bin/env bash
# SC-1 of vault/plans/2026-09-22-1023-spec-reading-probes.md — registry rows + probe.sh list.
# Exit 0 met, 1 not met, 2 cannot say yet.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
reg="$root/probes/registry.tsv"
grep -q '^spec-tables' "$reg" 2>/dev/null && grep -q '^spec-naming' "$reg" 2>/dev/null || {
    echo "registry rows not written yet — cannot say"; exit 2
}
fail() { printf '%s\n' "$*"; exit 1; }
out=$("$root/bin/probe.sh" list --repo "$root" 2>&1) || fail "probe.sh list failed: $out"
printf '%s\n' "$out" | grep -Eq $'^spec-tables\tplan\t[A-Z]\t\\S+\tok$' || fail "spec-tables row not ok: $out"
printf '%s\n' "$out" | grep -Eq $'^spec-naming\tplan\t[A-Z]\t\\S+\tok$' || fail "spec-naming row not ok: $out"
printf '%s\n' "$out" | grep -q '^sql-dup-columns' || fail "sql-dup-columns row missing"
printf '%s\n' "$out" | grep -q '^sql-fk-index' || fail "sql-fk-index row missing"
printf '%s\n' "$out" | grep -q '^sql-naming' || fail "sql-naming row missing"
exit 0
