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

| # | action | file (exact path) | done when |
|---|--------|-------------------|-----------|
| 1 | Add `goal baseline <plan>` and `goal close <plan> <session>` modes: record the first goal run in the `baseline` row, refuse a first run that exits 0, refuse a `status` flip on a goal case the session does not own, refuse a close that leaves ownership below 100% | /home/kdabrow/workspace/vault/lib/goal-check.sh | T21–T24 pass; the file stays under 260 lines, else the modes move to `lib/goal-run.sh` |
| 2 | Add `gap <plan> <group ids>`: append one Sessions row per failing goal-case group, bump `gap_rounds` in frontmatter, refuse a fourth round | /home/kdabrow/workspace/vault/bin/pm-plan.sh | T25–T27 pass |
| 3 | The session that first builds the goal command runs `gate.sh goal baseline` | /home/kdabrow/workspace/vault/commands/_shared/feature-pickup.md | T28 passes |
| 4 | The close flips the session's own goal cases to `pass`; a close with a deviation or an appended row runs `gate.sh goal` on the master; the last row's close runs the goal command | /home/kdabrow/workspace/vault/commands/v-work/steps/05-commit-capture.md | T29 passes |
| 5 | Gap loop: a failing last run turns each failing case group into a row through `pm-plan.sh gap`, stopping at `gap_rounds: 3` with the failing cases shown to the operator | /home/kdabrow/workspace/vault/commands/v-pm/steps/06-reconcile.md | T30 passes |
| 6 | Show owned N/M, the baseline, the last goal run and `gap_rounds` | /home/kdabrow/workspace/vault/commands/v-pm/steps/07-status.md | T30 passes |
| 7 | Tests T21–T27 | /home/kdabrow/workspace/vault/tests/unit/goal-run.bats | `checks/plan-goal-fit-C5.sh` exits 0 |
| 8 | Tests T28, T29 (new file) | /home/kdabrow/workspace/vault/tests/unit/v-work.bats | `checks/plan-goal-fit-C6.sh` exits 0 with item 9 |
| 9 | Test T30 | /home/kdabrow/workspace/vault/tests/unit/v-pm.bats | as item 8 |
| 10 | Version `1.17.0` | /home/kdabrow/workspace/vault/.claude-plugin/plugin.json | `make release-check` passes |

## Do not touch

- `templates/master-plan.md` field rules: S1 fixed them and C-1 hands them to S2. Add the `baseline` and `status` behaviour without renaming a field or column.
- `checks/plan-goal-fit-C5.sh` and `checks/plan-goal-fit-C6.sh`: committed at approval, so the session cannot edit the check that grades it.

## Unverified

- No `/v-pm` run has used the S1 checks on a real plan. The operator's first `/v-pm` run after S2 closes the report.

## Goal

When a plan's last session closes, its goal command runs, and each failing case becomes a new session, at most three rounds.

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
