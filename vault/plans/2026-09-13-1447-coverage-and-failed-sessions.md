---
type: plan
project: vault
slug: coverage-and-failed-sessions
repos: [vault]
status: executed
process_record:
session: 2026-09-13-1447-coverage-and-failed-sessions
tags: [plan, gates, enforcement]
---

# coverage-and-failed-sessions — plan

## Task

Refuse a plan that sets a goal no work item reaches, and end that session as failed instead of
asking the operator to approve it. Keywords: coverage, criterion, work item, gate, failed session.

## Open & deferred

| item | state |
|------|-------|
| The claim ledger — proof, warrant and refutation per plan statement — is designed and not built. Its design and its 15 open blockers are in `vault/plans/2026-09-13-1355-proof-discipline.md` and that plan's `.trail.md` sibling | deferred to a later session |
| `coverage` runs at the approval gate and nowhere else. At close, `verdict` already requires every criterion to be MET, and `/v-do` writes a plan with no `## Work items` table, so a close-phase run would exit 2 on every `/v-do` session | open — deliberate limit |
| `/v-work` and `/v-pm` have approval gates and do not run `coverage`. Only `commands/v-team.md` calls it | open — unextended by design |
| The counted corpus stays at 175 rule lines against a budget of 173, and 150 prohibitions against 25 requirements where the ceiling is 1:1. This change is net zero on all three; it does not close the standing overrun | open — standing overrun |

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Does `coverage` belong in the close phase as well | no | `tests/unit/gate.bats:350`; `commands/v-do.md`; `bin/gate.sh` phase sets | answered | no — it exits 2 on `/v-do`'s stub plan and `verdict` already covers close |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a success criterion is named in no work item's `covers` cell THE SYSTEM SHALL exit 1 and name it, and WHEN the plan's tables cannot be read THE SYSTEM SHALL exit 2 | unit | command | `checks/coverage-SC-1.sh` | exit 0 | MET | `checks/coverage-SC-1.sh` exited 0 ·   OK  coverage is built and listed; 1 uncovered, 0 covered, 2 unparseable |
| SC-2 | WHEN the approval gate runs on a committed plan THE SYSTEM SHALL grade it through the shipped `bin/gate.sh`, and refuse a copy covering nothing with exit 1 | delivery | command | `checks/coverage-SC-2.sh` | exit 0 | MET | `checks/coverage-SC-2.sh` exited 0 ·   OK  the approve phase passes its own plan and refuses an uncovered copy with exit 1 |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | The change does what the task asked | met | `bin/gate.sh coverage` refuses an uncovered criterion and `commands/v-team.md` Step 4 runs it before the decision; the claim ledger was cut and is recorded as deferred |
| B2 | Tests covering the changed behaviour pass | met | `./tests/run.sh tests/unit/gate.bats` — 60 cases, 11 new, no failures. `./tests/run.sh tests/unit` — 682 cases with 4 failures, all pre-existing: the identical set runs on a detached worktree at `0599b18`, numbered 231, 237, 377 and 423 there against 231, 237, 388 and 434 here, the shift being the 11 cases added |
| B3 | Lint and any format check pass on the changed files | met | `./bin/doc-lint.sh --changed` exited 0; `bash -n bin/gate.sh` clean |
| B4 | Every review finding is fixed or recorded | met | the two reviewer findings against this slice — that it documented a subcommand it did not build, and reached no failed-session state — are both fixed; the 15 findings against the claim ledger are recorded in `vault/plans/2026-09-13-1355-proof-discipline.trail.md` |
| B5 | Documentation and vault docs that the change invalidates are updated | met | `vault/architecture/session-gates.md` names the subcommand, `vault/architecture/session-gates-unbuilt.md` no longer carries U-2 and its count reads six, `vault/check-budget.md` carries the new row |
| B6 | Nothing unrelated is in the commit | met | `git diff --stat` lists the six files this plan's work items name; the untracked `.serena/` predates this session and is not staged |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| R-1 | A plan whose criterion no work item covers does not reach the approval gate | ENFORCED | `cmd_coverage` in `bin/gate.sh`, called by the `approve` phase; `tests/unit/gate.bats` proves both exit codes and the wiring |
| R-2 | A plan marked `status: failed` does not pass the approval gate on a re-run | ENFORCED | `cmd_coverage` reads the frontmatter and refuses; `tests/unit/gate.bats` proves the refusal and its planted-violation pair |
| R-3 | A session that cannot reach a criterion writes `status: failed` in the first place | PROSE | `commands/v-team.md` Step 4 instructs it; no hook fires between the gate's exit 1 and the model's next write, so nothing checks that the marker was written |

## Verified current state

- `bin/gate.sh` had no `coverage` subcommand before this change · `git show 0599b18:bin/gate.sh` has `criteria)` as the first arm of the subcommand `case` · 2026-09-13.
- `coverage` was specified and unbuilt as row U-2 of `vault/architecture/session-gates-unbuilt.md` · `git show 0599b18:vault/architecture/session-gates-unbuilt.md` line 24 · 2026-09-13.
- `due_criteria` already parsed the `covers` column and treated a missing one as every criterion being due · `bin/gate.sh` · 2026-09-13.
- `/v-do` writes a plan carrying only `## Open questions`, `## Success criteria` and `## Definition of done` · `vault/architecture/session-gates.md` · 2026-09-13.
- The counted corpus is over budget at 175 rule lines against 173 · `bin/rule-count.sh --assert` exits 1 · 2026-09-13.

## Decisions

| decision | reason | record |
|----------|--------|--------|
| D-1 | One `covers` parser, read in opposite directions by its two callers | `due_criteria` must treat an unsayable question as all-due or the close gate becomes unusable; `coverage` must refuse to guess or it reports thoroughness it never had | local |
| D-2 | Exit 1 for an uncovered criterion, exit 2 for an unreadable plan | the caller turns exit 1 into a failed session, so a malformed table must not declare the work impossible | local |
| D-3 | `coverage` runs at the approval gate only | `verdict` already requires every criterion MET at close, and a close-phase run exits 2 on every `/v-do` plan | local |
| D-4 | An unfinished work item still covers its criterion | coverage asks whether work exists, not whether it finished; `verdict` owns the finished question | local |

## Scope & non-goals

Covers the `coverage` subcommand, its reading of `status: failed`, its approval-gate call in
`/v-team`, the two architecture documents, the check-budget row, and eleven test cases.

Excluded: the claim ledger; extending `coverage` to `/v-work`, `/v-pm` or `/v-cr`; the close phase;
closing the rule-budget overrun.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `coverage` subcommand | `commands/v-team.md` Step 4, which runs it before the decision is written | `bin/gate.sh` | the `/v-team` dispatcher, which sets `status: failed` on exit 1 and stops as an error on exit 2 | an unreachable criterion reaches the approval gate unnoticed, which is the state before this change |
| `covers_pairs` | `cmd_coverage` and `due_criteria`, which take its "cannot say" answer in opposite directions | `bin/gate.sh` | both callers; `tests/unit/gate.bats` asserts each direction | a single shared default would make one caller unusable and the other dishonest |
| `status: failed` in plan frontmatter | `cmd_coverage`, which refuses any plan carrying it | the `/v-team` dispatcher, on the gate's exit 1 | `cmd_coverage` via `frontmatter_get`, and the operator | a failed plan passes the approval gate by being run a second time; `tests/unit/gate.bats` "coverage refuses a plan already marked status: failed" fails |
| `coverage` row in `vault/check-budget.md` | `bin/gate.sh budget`, which refuses a check firing wrongly more than one time in ten | this change | the operator, who sets `wrong` by hand | the check's false-positive rate goes unmeasured and `GATE=off` becomes the response |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `bin/gate.sh` | modify | Edit | extract `covers_pairs` out of `due_criteria`; it exits 2 when the plan cannot say, and each caller takes that in its own direction | SC-1 | `tests/unit/gate.bats` cases 36-38 | DONE |
| W-2 | `bin/gate.sh` | modify | Edit | add `cmd_coverage`; exit 1 naming each uncovered criterion, exit 2 on a missing table, rows or `covers` column | SC-1 SC-2 | `checks/coverage-SC-1.sh` | DONE |
| W-3 | `bin/gate.sh` | modify | Edit | dispatch `coverage`, add it to the `approve` phase only, and record in the `close` arm why it is absent there | SC-2 | `tests/unit/gate.bats` "the close phase does not run coverage" | DONE |
| W-4 | `commands/v-team.md` | modify | Edit | Step 4 runs the gate before the decision is written, sets `status: failed` on exit 1, stops as an error on exit 2; net zero on the rule count | SC-2 | `bin/rule-count.sh` reports 175 and 150, unchanged | DONE |
| W-5 | `vault/architecture/session-gates.md` | modify | Edit | one subcommand row naming both exit codes and why the close phase omits it; the unbuilt count drops to six | SC-1 | `checks/coverage-SC-1.sh` | DONE |
| W-6 | `vault/architecture/session-gates-unbuilt.md` | modify | Edit | delete the U-2 row and correct the count in the same commit as W-5 | SC-1 | `checks/doc-truth-SC-1.sh` | DONE |
| W-7 | `vault/check-budget.md` | modify | Edit | one row naming `cmd_coverage` and the single condition it refuses on | SC-1 | `bin/gate.sh budget` | DONE |
| W-4b | `bin/gate.sh` | modify | Edit | `cmd_coverage` reads `status` from the frontmatter and refuses a plan already marked `failed`, so the marker has one code reader | SC-1 | `tests/unit/gate.bats` "coverage refuses a plan already marked status: failed" | DONE |
| W-8 | `tests/unit/gate.bats` | modify | Edit | eleven cases: covered, unfinished-still-covers, uncovered-names-it, no column, no table, no criteria, the approve wiring, the failed-marker refusal and its planted pair, the close-phase absence, and the two architecture documents | SC-1 SC-2 | `tests/run.sh tests/unit/gate.bats` | DONE |
| W-9 | `checks/coverage-SC-1.sh` | create | Write | four behavioural assertions plus both document assertions | SC-1 | its own exit code | DONE |
| W-10 | `checks/coverage-SC-2.sh` | create | Write | run the `approve` phase on this plan, then on a copy with every `covers` cell emptied, requiring exit 1 and a named criterion | SC-2 | its own exit code | DONE |

## Rollback

Revert the commit. `coverage` is one additive arm on the subcommand `case` and one call in
`/v-team` Step 4; no other command invokes it. `due_criteria`'s behaviour is unchanged — the
extracted helper returns the same answer and the pre-existing test at `tests/unit/gate.bats`
"a work-items table with no covers column leaves every criterion due" proves it. `GATE=off`
suppresses every check for a whole run.

## Test plan

`tests/unit/gate.bats`, run through `tests/run.sh` inside Docker.

| unit | scenarios |
|------|-----------|
| `cmd_coverage` | every criterion covered exits 0; an unfinished covering item still counts; an uncovered criterion exits 1 and names it while a covered one is not named; no `covers` column exits 2; no `## Work items` table exits 2; no `## Success criteria` table exits 2 |
| phase wiring | `--phase approve` refuses an uncovered plan; `--phase close` does not run coverage, so a plan with no work items still reaches `verdict` |
| `covers_pairs` | the pre-existing all-due test is the opposite-direction half and must keep passing |
| documents | `session-gates.md` names the subcommand; `session-gates-unbuilt.md` no longer carries U-2, asserted with `run grep` and a status check |

## Refs

- `vault/decisions/ADR-026-mechanical-session-gates.md` — established that a check is a committed script and no model decides whether work is done; this adds the tenth such check.
- `vault/architecture/session-gates.md` — the contract this change extends by one row.
- `vault/architecture/session-gates-unbuilt.md` — held this check as row U-2 from 2026-09-04 until now.
- `vault/plans/2026-09-13-1355-proof-discipline.md` — the claim ledger this change was split out of, still unbuilt.
- `vault/plans/2026-09-13-1355-v-method.brief.md` — the methodology-designer design, also unbuilt.
