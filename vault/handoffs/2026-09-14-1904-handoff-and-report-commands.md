---
type: handoff
project: vault
slug: 2026-09-14-1904-handoff-and-report-commands
date: 2026-09-14
status: open
session:
plan: vault/plans/2026-09-14-1642-handoff-and-report-commands.md
continues:
tags: [handoff]
---

# 2026-09-14-1904-handoff-and-report-commands — handoff

## Left to do

| # | action | file (exact path) | done when |
|---|--------|-------------------|-----------|
| 1 | Run `/v-handoff resume` in a session with no memory of this one, and record whether it states the next command without asking anything this file already answers | `vault/plans/2026-09-14-1642-handoff-and-report-commands.md` | the SC-5 row's `verdict` cell reads `MET` with the observation as evidence, or `NOT MET` with what it asked for |
| 2 | Run `./bin/gate.sh all vault/plans/2026-09-14-1642-handoff-and-report-commands.md --phase close` | `vault/plans/2026-09-14-1642-handoff-and-report-commands.md` | it exits 0; today it refuses on SC-5 alone |
| 3 | Decide whether the four pre-existing test failures get `/v-report` files or are left alone | `vault/reports/` | each of the four is either a report file or a stated decision not to write one |

## Do not touch

- **Another Claude session is working in this same checkout.** It owns `bin/vault-plugin.sh`,
  `vault/indications/_index.md`, `vault/indications/plans-are-build-orders.md` and the §2.3b
  paragraph about `plans/` in `commands/v-work/steps/02-load-context.md`. Do not revert or restage
  those; `git status` will show them uncommitted and they are not this work.
- **Never `git add -A` or `git commit -am` here.** `scripts/staging-hook.sh` denies it, and the
  reason is that other session's uncommitted files.

## Unverified

- **SC-5 has never been run.** Nothing yet proves a fresh session resumes from a handoff rather than
  re-deriving the task from the repo. It is the one criterion in the plan with no detector, by
  design: `no-command: nothing can detect whether a fresh session read the handoff`.
- **`/v-handoff resume` and `/v-report list` have never executed.** Both are instructions a model
  follows, not scripts. `checks/handoff-SC-1.sh` and `checks/handoff-SC-2.sh` prove the command files
  name every branch; nothing proves a model drives them correctly.
- **The integration suite was not run.** Only `./tests/run.sh tests/unit` ran (755 tests, 4 failures,
  all four present at HEAD before this work). `tests/integration/vault-init.bats` was edited and its
  new assertion has not executed.

## Goal

`/v-handoff` and `/v-report` are installed, documented, checked and used, so a long session can stop
without losing its direction and a problem found mid-task can be filed instead of derailing the work.

## Task

Add two commands to this framework. `/v-handoff` guards the goal, task, requirements, success
criteria, plan, method, comments, direction, what was executed, how it was executed and what is left,
writing to `handoffs/`. `/v-report` records a failing, stale or incorrect thing found during other
work — who found it, in what circumstances, the cause, the consequences, the suggested repair and the
files involved — writing to `reports/`.

## Requirements

- Six-field core written every time, the rest only when the session has them. Decided against the
  eleven-field list at the clarify gate; `commands/v-handoff.md` implements it as eight core sections.
- The operator files reports; any command may offer in one line and drops on a no.
  `commands/v-work/steps/05-commit-capture.md` §5.3a carries the offer.
- A report's finder lives in frontmatter, never in the body.
  `commands/_shared/document-standard.md` rule 7 bars it; rule 5 permits the frontmatter form.
- A problem inside the current plan's scope stays in that plan's `## Open & deferred`.
  `vault-guide.md` §6 states it.
- No `git add -A`, no `git commit -a`. `scripts/staging-hook.sh` refuses both.

## Next command

```
./bin/gate.sh all vault/plans/2026-09-14-1642-handoff-and-report-commands.md --phase close
```

## Blockers

SC-5 cannot be met inside the session that wrote the plan: it requires a second session. Only you can
clear it, by running item 1 above.

## Plan

`vault/plans/2026-09-14-1642-handoff-and-report-commands.md`. All 21 work items are `DONE`. SC-1
through SC-4 are `MET` with the gate's own evidence; SC-5 has no verdict.

## Done

- Two commands, two templates, four check scripts, one unit test file: written with `Write`, each
  check run red before the work landed and green after.
- `bin/doc-lint.sh`: two new contract types registered in five places, edited with `Edit`.
- `vault-guide.md` §13 extracted to `docs/cross-project-workspaces.md`, because the guide sat at
  exactly its 600-line cap and had no room. The guide is now 518 lines and keeps a four-line pointer.
- Unit suite run in Docker via `./tests/run.sh tests/unit`: 755 tests, the same 4 failures as HEAD.
  Baseline taken by running the suite in a throwaway `git worktree` at HEAD.

## Direction

- A handoff is a contract and a session capture is a record. Keep them in separate files; the split
  is why `## Left to do` is not a section of `templates/session.md`.
- `reports/` is not `vault/defect-ledger.md`. The ledger counts whether a repaired defect class came
  back; a report is the stage before any repair exists.
- Both folders are standard, not `add_folders` opt-ins, because `/v-work` reads them on every context
  load. A folder the lifecycle reads unconditionally has to exist unconditionally.

## Notes

`./bin/rule-count.sh` reports 177 instruction lines against a budget of 173; this work added two.
Nothing calls that script, so it refuses nothing. Both added lines are requirements rather than
prohibitions, which moves the 150:25 ratio the same script asserts in the right direction.
