#!/usr/bin/env bash
# SC-5 of vault/plans/2026-09-21-1940-cross-session-contracts.md — the wiring text, the registry and the budgets.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
loop="$root/commands/v-team/steps/03-propose-loop.md"; vt="$root/commands/v-team.md"
master="$root/vault/plans/2026-09-21-0900-architecture-first-planning.md"
[ -r "$loop" ] && [ -r "$vt" ] && [ -r "$master" ] || { echo "a file to read is missing — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
sec() { awk -v h="$2" '$0 ~ h {p=1; next} p && /^## \(/ {exit} p' "$1"; }
a=$(awk '/^## \(a\)/{p=1;next} /^## \(b\)/{p=0} p' "$loop")
f3=$(awk '/^## \(f3\)/{p=1;next} /^## \(g\)/{p=0} p' "$loop")
g=$(awk '/^## \(g\)/{p=1;next} /^---$/{p=0} p' "$loop")
step4=$(awk '/^## Step 4/{p=1;next} /^## Step 5/{p=0} p' "$vt")
grep -q 'templates/master-plan.md' <<<"$a"  || fail "step (a) does not name templates/master-plan.md"
grep -q 'session_of' <<<"$a"                || fail "step (a) does not name session_of"
grep -q 'templates/master-plan.md' <<<"$f3" || fail "step (f3) does not name templates/master-plan.md"
grep -q 'gate.sh master' <<<"$f3"           || fail "step (f3) does not run gate.sh master"
grep -q 'gate.sh master' <<<"$g"            || fail "step (g) does not run gate.sh master"
grep -q 'gate.sh master' <<<"$step4"        || fail "Step 4 of commands/v-team.md does not run gate.sh master"
awk -F'|' '/^\| master /{f=1} END{exit !f}' "$root/vault/check-budget.md" || fail "vault/check-budget.md has no master row"
"$root/checks/doc-truth-SC-3.sh" >/dev/null 2>&1 || fail "checks/doc-truth-SC-3.sh fails"
"$root/bin/gate.sh" --help 2>&1 | grep -q 'gate.sh master' || fail "gate.sh --help does not list master"
n=$(wc -l < "$root/bin/gate.sh"); [ "$n" -le 830 ] || fail "bin/gate.sh has $n lines, over 830"
rc=$("$root/bin/rule-count.sh" | sed -n 's/^rule lines *\([0-9]*\).*/\1/p'); [ "$rc" = 181 ] || fail "bin/rule-count.sh reads $rc rule lines, not 181"
grep -E '^\| E-3 ' "$master" | grep -q 'HALF-BUILT' || fail "the E-3 row of the master plan does not name HALF-BUILT"
exit 0
