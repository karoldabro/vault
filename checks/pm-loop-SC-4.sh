#!/usr/bin/env bash
# SC-4 of vault/plans/2026-10-12-0944-v-pm-planning-loop.md — the execution side.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail() { printf '%s\n' "$*"; exit 1; }
pl="$root/commands/v-team/steps/03-propose-loop.md"
[ -r "$pl" ] || { echo "03-propose-loop.md is missing"; exit 2; }
grep -q '(f3)' "$pl" && fail "03-propose-loop.md still has step (f3)"
fp="$root/commands/_shared/feature-pickup.md"
[ -f "$fp" ] || fail "commands/_shared/feature-pickup.md is missing"
[ -e "$root/commands/v-team/steps/00-feature-pickup.md" ] && fail "the old v-team Step 0 file still exists"
grep -q 'pm-plan.sh order' "$fp" || fail "feature-pickup.md does not check readiness with pm-plan.sh order"
grep -q 'pm-plan.sh set' "$fp" || fail "feature-pickup.md does not write doing with pm-plan.sh set"
grep -q 'feature-pickup.md' "$root/commands/v-work.md" || fail "v-work.md does not run feature pickup"
grep -q 'feature-pickup.md' "$root/commands/v-team.md" || fail "v-team.md does not run feature pickup"
grep -q 'session_of' "$root/commands/v-work/steps/03-propose.md" || fail "v-work 03-propose.md does not write session_of"
cc="$root/commands/v-work/steps/05-commit-capture.md"
grep -q '^## 5.1a' "$cc" || fail "05-commit-capture.md has no step 5.1a"
awk '/^## 5.1a/{s=1;next} /^## /{s=0} s' "$cc" | grep -q 'vault-sync.sh pull' || fail "step 5.1a does not pull before writing the row"
hits=$(grep -rln --exclude=pm-loop-SC-4.sh 'generic-plan.md\|planning-session.md\|plan-appetite-not-tasks' \
    "$root/commands" "$root/templates" "$root/docs" "$root/checks" "$root/vault/features" "$root/_moc.md" \
    "$root/vault-guide.md" "$root/README.md" 2>/dev/null \
    | grep -v -e 'commands/_shared/feature-pickup.md$' -e 'commands/v-pm/steps/06-reconcile.md$')
[ -z "$hits" ] || fail "still referenced outside the legacy readers: $(tr '\n' ' ' <<<"$hits")"
[ -e "$root/templates/_features/generic-plan.md" ] && fail "templates/_features/generic-plan.md still exists"
[ -e "$root/templates/_features/planning-session.md" ] && fail "templates/_features/planning-session.md still exists"
[ -f "$root/vault/decisions/ADR-033-v-pm-planning-loop.md" ] || fail "ADR-033 is missing"
[ -f "$root/vault/indications/pm-plans-sessions.md" ] || fail "indication pm-plans-sessions.md is missing"
exit 0
