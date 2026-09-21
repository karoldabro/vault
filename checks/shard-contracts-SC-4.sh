#!/usr/bin/env bash
# SC-4 of vault/plans/2026-09-21-2040-pm-shard-contracts.md — the close duty, the rule budget and the guards.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
f="$root/commands/v-work/steps/05-commit-capture.md"; b="$root/tests/unit/v-pm.bats"
[ -r "$f" ] && [ -r "$b" ] || { echo "the close step or the bats file is missing — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
sec=$(awk '/^## 5.0/{p=1;next} /^## 5.1/{p=0} p' "$f")
grep -q 'session_of' <<<"$sec" && grep -q 'gate.sh master' <<<"$sec" || fail "step 5.0 lacks the master-plan bullet with session_of and gate.sh master"
grep -q 'gate.sh verdict' <<<"$sec" || fail "step 5.0 does not name the verdict result as evidence"
rc=$("$root/bin/rule-count.sh" | sed -n 's/^rule lines *\([0-9]*\).*/\1/p'); [ "$rc" = 181 ] || fail "bin/rule-count.sh reads $rc rule lines, not 181"
for pat in 'depends after status' 'Cross-session contracts' 'seeds \*\*three\*\* sections' 'Contract gap' 'session_of'; do
    grep -qF -- "$pat" "$b" || fail "tests/unit/v-pm.bats does not guard '$pat'"
done
exit 0
