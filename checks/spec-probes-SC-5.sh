#!/usr/bin/env bash
# SC-5 of vault/plans/2026-09-22-1023-spec-reading-probes.md — bin/plan-probes.sh budget counts
# distinct triggered auditors, not a 0/1 flag.
# Exit 0 met, 1 not met, 2 cannot say yet.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pp="$root/bin/plan-probes.sh"
[ -x "$pp" ] || { echo "bin/plan-probes.sh not written yet — cannot say"; exit 2; }
"$pp" auditors 2>/dev/null | grep -q '^data-model' || { echo "data-model auditor not wired yet — cannot say"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
T=$(printf '\t')
fail() { printf '%s\n' "$*"; exit 1; }

added_of() {
    local block=$1 d="$tmp/o.$RANDOM"
    "$pp" budget --critics 1 --rounds 1 --block "$block" --out "$d" 2>"$tmp/err" \
        | sed -n 's/^projected: added=\([0-9]*\).*/\1/p'
}

# "one" and "two" are the same byte length (a second, unrecognized-id row of equal size pads "one")
# so the budget delta below isolates the auditor-count effect from the block-size effect.
one="reuse-row"; { printf 'similar-symbols%sf%s1%swarn%sr%sm\n' "$T" "$T" "$T" "$T" "$T"; printf 'unknown-idx%sf%s1%swarn%sr%sm\n' "$T" "$T" "$T" "$T" "$T"; } > "$tmp/one"
two="two-rows"; { printf 'similar-symbols%sf%s1%swarn%sr%sm\n' "$T" "$T" "$T" "$T" "$T"; printf 'spec-tables%sf%s1%swarn%sr%sm\n' "$T" "$T" "$T" "$T" "$T"; } > "$tmp/two"
[ "$(wc -c < "$tmp/one")" -eq "$(wc -c < "$tmp/two")" ] || fail "test fixture bug: one and two are not the same byte length"

a1=$(added_of "$tmp/one"); a2=$(added_of "$tmp/two")
[ -n "$a1" ] && [ -n "$a2" ] || fail "budget did not print a projected line"
diff=$((a2 - a1))
[ "$diff" -eq 36000 ] || fail "two distinct auditors should add exactly one more PLAN_PROBE_AUDITOR_TOKENS (36000) over one; got a delta of $diff"
exit 0
