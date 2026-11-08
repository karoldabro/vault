---
type: handoff
project: vault
slug: S2-run-time-checks
date: 2026-11-08
id: S2
session:
plan: /home/kdabrow/workspace/vault/vault/plans/2026-11-08-1337-plan-goal-fit.md
continues:
tags: [handoff]
---

# S2-run-time-checks — handoff

## Left to do

The plan's S2-W1 to S2-W20 rows are the authority; this table names each file once.

| # | action | file (exact path) | done when |
|---|--------|-------------------|-----------|
| 1 | `goal baseline`, `goal close`, `goal last`, `goal failing` | /home/kdabrow/workspace/vault/lib/goal-run.sh | T21–T24 pass; ≤ 220 lines |
| 2 | dispatch the modes; `table_set`, `table_append`, `frontmatter_put` | /home/kdabrow/workspace/vault/bin/gate.sh | T21, T25 pass |
| 3 | `goal script`, `last run`, gap rules, `split: gap round` | /home/kdabrow/workspace/vault/templates/master-plan.md | ≤ 140 lines |
| 4 | `goal script` and `last run` rows | /home/kdabrow/workspace/vault/templates/feature-plan.md | rows present |
| 5 | refuse an empty `goal script` row | /home/kdabrow/workspace/vault/lib/goal-check.sh | `checks/plan-goal-fit-C1.sh` and `checks/plan-goal-fit-C4.sh` exit 0 |
| 6 | `goal script` rows | /home/kdabrow/workspace/vault/tests/fixtures/goal/complete.md, /home/kdabrow/workspace/vault/tests/fixtures/goal/device-sync-tests.md | C1 and C4 exit 0 |
| 7 | `gap round` split reason | /home/kdabrow/workspace/vault/lib/master-check.sh | T25 passes |
| 8 | `gap`; `set` through `table_set`; `order` without `repo` | /home/kdabrow/workspace/vault/bin/pm-plan.sh | T25–T27 pass |
| 9 | the planner names the goal script | /home/kdabrow/workspace/vault/commands/v-pm/steps/03-plan-panel.md | T30 passes |
| 10 | baseline run at pickup | /home/kdabrow/workspace/vault/commands/_shared/feature-pickup.md | T28 passes |
| 11 | `goal close` and `goal last` at close | /home/kdabrow/workspace/vault/commands/v-work/steps/05-commit-capture.md | T29 passes |
| 12 | gap loop | /home/kdabrow/workspace/vault/commands/v-pm/steps/06-reconcile.md | T30 passes |
| 13 | goal state in the digest | /home/kdabrow/workspace/vault/commands/v-pm/steps/07-status.md | T30 passes |
| 14 | T21–T27 | /home/kdabrow/workspace/vault/tests/unit/goal-run.bats | `checks/plan-goal-fit-C5.sh` exits 0 |
| 15 | T28, T29 | /home/kdabrow/workspace/vault/tests/unit/v-work.bats | `checks/plan-goal-fit-C6.sh` exits 0 |
| 16 | T30 | /home/kdabrow/workspace/vault/tests/unit/v-pm.bats | `checks/plan-goal-fit-C6.sh` exits 0 |
| 17 | registry rows | /home/kdabrow/workspace/vault/vault/architecture/session-gates.md, /home/kdabrow/workspace/vault/vault/check-budget.md | `gate.sh budget` exits 0 |
| 18 | `lib/goal-run.sh` rows | /home/kdabrow/workspace/vault/vault/plans/2026-11-08-1337-plan-goal-fit.arch.md | `gate.sh arch` exits 0 |
| 19 | `1.17.0` | /home/kdabrow/workspace/vault/.claude-plugin/plugin.json | `make release-check` passes |

## Do not touch

- `templates/master-plan.md` field rules: S1 fixed them and C-1 hands them to S2. Add the `baseline` and `status` behaviour without renaming a field or column.
- `checks/plan-goal-fit-C5.sh` and `checks/plan-goal-fit-C6.sh`: committed at approval, so the session cannot edit the check that grades it.

## Unverified

- No `/v-pm` run has used the S1 checks on a real plan. The operator's first `/v-pm` run after S2 closes the report.

## Goal

When a plan's last session closes, its goal script runs, and the failing cases become new sessions, one per repo, at most three rounds.

## Task

S2 of `vault/plans/2026-11-08-1337-plan-goal-fit.md`: the run-time checks.

## Requirements

- Contract C-1 of the plan: `## Goal fit` rows, `## Goal cases` columns, `bin/goal-trace.sh`, `cmd_goal`, `master_resolve`.
- Rules of the `## Decisions` rows on the baseline, the status flip, the scope-change recheck and the gap loop in the plan.
- Every new refusal applies only to a plan with `goal_fit: required`.

## Next command

cd /home/kdabrow/workspace/vault && claude --add-dir /home/kdabrow/workspace/vault/vault/plans "/v-team /home/kdabrow/workspace/vault/vault/plans/2026-11-08-1337-plan-goal-fit.md#S2"

## Success criteria

| id | criterion | how it is decided | met |
|----|-----------|-------------------|-----|
| C5 | WHEN `tests/unit/goal-run.bats` runs THE SYSTEM SHALL pass T21–T27 | `checks/plan-goal-fit-C5.sh` exits 0 | |
| C6 | WHEN the close-time contract tests run THE SYSTEM SHALL pass `tests/unit/v-work.bats` and `tests/unit/v-pm.bats` with T28–T30 present | `checks/plan-goal-fit-C6.sh` exits 0 | |
