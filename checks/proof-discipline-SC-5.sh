#!/usr/bin/env bash
# SC-5 — the falsification ratio is computed by a function, invoked inside a code fence.
#
# enforced-not-just-stated obligation 5: the contract grep names the FENCED CALL, not the bare token,
# and pairs with a definition grep so the step file cannot name a function nobody wrote. A token grep
# passes on a prose mention; an anchored grep requiring arguments fails on a real zero-argument call.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lib="$root/lib/claim-helpers.sh"
step="$root/commands/v-team/steps/03-propose-loop.md"
bats="$root/tests/unit/proof-discipline.bats"
fail=0

[ -f "$lib" ] || { printf '  MISSING  %s does not exist yet\n' "$lib"; exit 1; }

for fn in claim_grade claim_anchor_check claim_falsification_ratio; do
    run_def=$(grep -cE "^${fn}\(\)" "$lib" || true)
    [ "$run_def" -ge 1 ] || { printf '  FAIL  %s defines no %s()\n' "$lib" "$fn"; fail=1; }
done

# Only a call inside a fenced block counts, with or without arguments.
fenced=$(awk '/^[[:space:]]*```/ {f=!f; next} f && /^[[:space:]]*claim_falsification_ratio([[:space:]]|$)/ {n++} END {print n+0}' "$step")
[ "$fenced" -ge 1 ] || { printf '  FAIL  %s has no fenced claim_falsification_ratio call\n' "$step"; fail=1; }

# The guard must be proven able to fail. A named planted case is the receipt.
[ -f "$bats" ] || { printf '  FAIL  %s does not exist\n' "$bats"; exit 1; }
planted=$(grep -cE '^@test .*planted' "$bats" || true)
[ "$planted" -ge 3 ] || { printf '  FAIL  %s has %s planted-violation cases; one per helper is three\n' "$bats" "$planted"; fail=1; }

[ "$fail" -eq 0 ] || exit 1
printf '  OK  three helpers defined, the ratio call is fenced (%s), %s planted cases\n' "$fenced" "$planted"
