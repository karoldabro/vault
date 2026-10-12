#!/usr/bin/env bash
# SC-3 of vault/plans/2026-10-12-0944-v-pm-planning-loop.md — the /v-pm command text.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pm="$root/commands/v-pm.md"; st="$root/commands/v-pm/steps"
[ -r "$pm" ] || { echo "commands/v-pm.md is missing"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
grep -q 'writes no code' "$pm" || fail "v-pm.md does not state that /v-pm writes no code"
grep -qi 'approval gate' "$pm" || fail "v-pm.md has no approval gate"
i="$st/01-intake.md"
grep -q 'WHEN <trigger> THE SYSTEM SHALL <observable>' "$i" || fail "01-intake.md does not ask for a WHEN/SHALL criterion"
grep -q 'I will not plan until' "$i" || fail "01-intake.md has no refusal text"
grep -q 'small' "$i" && grep -q 'large' "$i" || fail "01-intake.md sets no scale tier"
grep -q '/v-pm' "$root/commands/_shared/elicitation.md" || fail "elicitation.md states no /v-pm exception"
grep -q 'code orientation' "$st/02-load-context.md" || fail "02-load-context.md has no read-only code orientation"
p="$st/03-plan-panel.md"
grep -qi 'parallel' "$p" || fail "03-plan-panel.md is not a parallel panel"
grep -q 'personas/_shared/planning' "$p" || fail "03-plan-panel.md does not seat the planning group"
grep -q '03-propose-loop.md' "$p" || fail "03-plan-panel.md does not reuse the v-team loop"
grep -q 'templates/handoff.md' "$p" || fail "03-plan-panel.md does not write briefs from templates/handoff.md"
grep -q 'pm-plan.sh check' "$p" || fail "03-plan-panel.md does not run pm-plan.sh check"
grep -qi 'sequential' "$p" && fail "03-plan-panel.md still describes a sequential pipeline"
grep -rqi 'appetite' "$pm" "$st" && fail "the /v-pm command still names an appetite"
grep -q 'pm-plan.sh order' "$st/05-capture.md" || fail "05-capture.md does not print the run order"
grep -q "trail sidecar of the caller's plan" "$root/commands/v-team/steps/03-propose-loop.md" || fail "03-propose-loop.md still hard-codes the v-team trail path"
exit 0
