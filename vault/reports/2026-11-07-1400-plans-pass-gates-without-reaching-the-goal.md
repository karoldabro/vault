---
type: report
project: vault
slug: plans-pass-gates-without-reaching-the-goal
date: 2026-11-07
status: open
severity: blocking
found_by: operator question after /v-team amended the device-sync-tests master plan
found_in: digitally-core device-sync-tests plan, ~/vault/digitally-core/plans/device-sync-tests/plan.md
files: [commands/v-pm.md, commands/v-pm/steps/03-plan-panel.md, commands/v-team.md, commands/v-team/steps/03-propose-loop.md, templates/master-plan.md, bin/gate.sh, bin/pm-plan.sh]
tags: [report, planning, approval-gate, success-criteria]
---

# plans-pass-gates-without-reaching-the-goal — report

## What is wrong
A `/v-pm` master plan and a `/v-team` amendment of it pass every gate (`pm-plan.sh check`, `gate.sh coverage`, `gate.sh master`, panel review) while the whole plan has about a 30–40% chance of meeting the operator's stated goal.

## Files

| file (exact path) | what is wrong in it |
|-------------------|---------------------|
| `commands/v-pm/steps/03-plan-panel.md` | the panel reviews each session and its contracts; no reviewer asks whether finishing every session meets the operator's goal |
| `commands/v-team.md` Step 4 | the approval block covers the change, not the whole plan's chance of meeting the goal |
| `templates/master-plan.md` | allows a session scope like "wire five cases; append rows for the rest", which leaves most of the work owned by no session |
| `bin/gate.sh` `coverage` | checks that each success criterion has a work item, not that the criteria together are the operator's goal |
| `bin/pm-plan.sh` `check` | normalizes tables; cannot see unowned work or runtime |

## Consequence
The operator approves plans that cannot deliver. In device-sync-tests the goal is a pre-release gate proving tablet data of any quantity, operation and configuration reaches the API. The approved 22-session plan:
- wires about 20 of roughly 600 written cases, because S7–S10 each wire five and "append rows for the rest";
- never estimates suite runtime, while a full device run plausibly takes tens of hours;
- has success criteria that measure activity ("catalogue covers every interaction", "pattern proven on five cases"), none of which is the goal.
The operator found this only by asking for the probability after approval. It has already happened.

## Cause
The gates check that a plan is internally consistent: criteria reach work items, contracts pair with depends, briefs match rows. No gate or reviewer compares the whole plan with the operator's goal, and nothing requires the goal itself to be a runnable criterion.

## How to see it
`~/vault/digitally-core/plans/device-sync-tests/plan.md`: `bin/pm-plan.sh check` prints `pm: ok`, yet the S7–S10 scopes say "appends rows for the remaining cases" and no session owns those rows.

## Repair
`/v-team` on the framework:
1. Require one success criterion that is the operator's goal as a runnable check, written in `/v-pm` intake (`commands/v-pm/steps/01-intake.md`).
2. Add a goal-fit reviewer seat to `03-plan-panel.md` and `03-propose-loop.md`. It walks the whole plan to its last session and reports: the probability the goal is met, the estimated runtime of what is built, and work no session owns.
3. Add those three lines to the approval block in `commands/v-pm.md`, `commands/v-team.md` and `commands/v-work/steps/03-propose.md`. Block approval while unowned work is not "none".
4. Add a `gate.sh` check refusing a session scope containing "append rows", "the rest" or "remaining cases" without a session that owns them.
Expected result: a plan whose steps, finished, meet 100% of the operator's goal, or that says plainly before approval which part it cannot meet.

## Not now because
Found at the end of a digitally-core session; the framework is a separate repo.

## Closes when
A `/v-pm` run on a goal produces an approval block naming the goal criterion, the probability, the runtime and "unowned work: none"; and `gate.sh master` refuses a plan with a session scope that defers work to unnamed rows.
