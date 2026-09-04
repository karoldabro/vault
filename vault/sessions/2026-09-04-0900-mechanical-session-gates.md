---
type: session
project: vault
date: 2026-09-04
topic: mechanical-session-gates
files_touched: [bin/gate.sh, tests/unit/gate.bats, tests/fixtures/gate/observed-criterion.md, templates/plan.md, commands/v-work/steps/03-propose.md, commands/v-work/steps/05-commit-capture.md, vault/architecture/session-gates.md, vault/plans/2026-09-04-0900-mechanical-session-gates.md]
decisions: [ADR-026]
tags: [session, gates, definition-of-done, enforcement]
---

# mechanical-session-gates

## Goal

Turn the operator's defect register into gates that refuse, rather than more prose a session can
ignore. Phase 1 of a six-phase build.

## Did

- Wrote the gate contract to [[../architecture/session-gates.md]] and the multi-session plan to
  [[../plans/2026-09-04-0900-mechanical-session-gates]], with a separate operator brief at
  `vault/plans/2026-09-04-0900-mechanical-session-gates.brief.md`.
- Built `bin/gate.sh` with `criteria`, `verdict`, `verdict --run`, `all --phase`, and `GATE=off`.
- Added `## Open questions`, `## Success criteria`, `## Definition of done` and
  `## Enforcement states` to `templates/plan.md`; turned `## Decisions` into a table with a `record`
  column and added `covers` to the work items.
- Wired the gate into `commands/v-work/steps/03-propose.md` §3a.3a and
  `commands/v-work/steps/05-commit-capture.md` §5.0.
- Wrote 32 cases in `tests/unit/gate.bats` and one committed fixture at
  `tests/fixtures/gate/observed-criterion.md`.
- Ran the gate against its own plan with `--run`, then flipped a verdict to a check that fails and
  confirmed it refuses.
- Committed as `707e27a`.

## Learned

- The gate found a real defect in its own plan on first run. A raw `|` inside a `check` cell splits
  the markdown row and silently shifts every later column, so the `verdict` cell read as empty. The
  parser restores `\|`; it cannot tell an unescaped pipe from a column break.
- The full unit suite is 521 tests with 4 pre-existing failures, not the 6 recorded in earlier
  sessions: `document-standard.bats:308`, `document-standard.bats:350`, `plugin-install.bats:106`,
  `research-clarify.bats:108`.
- A close gate over a multi-session plan is unusable without due-ness. Every criterion would refuse
  at the first checkpoint, and an unusable gate gets switched off. A criterion becomes due only when
  every work item naming it in `covers` is `DONE`.
- SWE-bench decides pass or fail by re-running hidden tests in a container, with no model judging.
  Where a model does judge, a system optimised against its own judge was measured reporting 94%
  success at 20% real accuracy.
- No mainstream tool detects a configuration key that nothing reads. Knip, Vulture and ConfTainter
  find unused code paths, which is a different question.
- `PreToolUse` hooks deny a tool call before the permission check and hold even when permission
  prompting is off. Injected context does not.

## Behaviors & rules

- A plan with no `## Success criteria` table → `gate.sh criteria` exits 1 and work items may not be
  written.
- No criterion has `kind: e2e` and frontmatter declares no `no-runtime:` → refuse; edge: a declared
  `no-runtime: <reason>` passes with a note.
- A criterion's `how` is `observed` and the row names no failing condition, or no `no-command:`
  reason → refuse. A judgement stays legal; closing on "it looked fine" does not.
- A criterion claims `MET` and its evidence names no backticked command and no `path:line` → refuse.
- `verdict --run` executes a `how: command` check and its real exit code differs from `expect` →
  refuse, whatever the plan claims.
- A criterion is due only when every work item naming it in `covers` is `DONE`; edge: a work-items
  table with no `covers` column leaves every criterion due.
- A table the parser cannot read → exit 2, never 0.
- `GATE=off` skips every check; there is no per-check suppression.

## Continuation 2026-09-04-1200

Every work item in the plan is DONE. The build ran phases A to F and the instruction cut was
narrowed by the compliance study running beside it.

**Built:** `scripts/completion-hook.sh` blocks a turn end when a work item is DONE and its criterion
has no verdict. A criterion's check is a committed script in `checks/`, and `bin/gate.sh verdict
--run` executes it and writes the verdict and captured output itself. `criteria` refuses a plan with
no `kind: delivery` row, a check that is not an executable, and a check path another plan claims.
`config` refuses at ANALYZE when `VAULT.md` omits a done command. `readers` refuses a declared
identifier no code reads. `budget` refuses a check wrong more than one time in ten. `recurrence`
refuses a defect repair with no failing-before test. `scripts/staging-hook.sh` denies a directory-
wide `git add`. `bin/rule-count.sh` measures the corpus; `scripts/rule-inject-hook.sh` re-injects
only the rules nothing checks.

**What the study changed.** Rewriting prohibitions as requirements was dropped: locally prohibitions
score 89.5% and requirements 76.9%, the opposite of the paper the plan cited. A blanket deletion of
unenforced rules was dropped: they score 18.1% to 98.8%, so it would have removed rules followed
92.9%, 98.8% and 74.1% of the time. One rule was deleted — the 50-character commit subject at 18.1%.

**Two defects this session caused, both now enforced.** `git add -A bin/` swept a parallel session's
work into two commits; `scripts/staging-hook.sh` now denies it. Two plans could name the same check
script and each grade itself against the other's; `criteria` now refuses it. Both are D-006 and
D-007 in the ledger.

## Next

- **The open question that matters:** `scripts/completion-hook.sh` blocks a turn end, while the two
  rules `scripts/doc-lint-hook.sh` merely reports on score 100% and 94.4%. Reporting may do the same
  work with less friction. `vault/check-budget.md` records each check's fires; a block that was never
  needed would settle it.
- The wiring into `/v-do`, `/v-pm` and `/v-cr` was dropped from the plan and never built. Only
  `/v-work` and `/v-team` call the gate today.
- The two definition-of-done profiles are specified in `vault/architecture/session-gates.md` and are
  not yet in `commands/_shared/definition-of-done.md`.
- `bin/gate.sh` has no `coverage`, `decisions`, `states` or `tracker` subcommand. Those were in the
  43-item plan and did not survive the rewrite.

## Refs

- [[../architecture/session-gates.md]] — the contract every subcommand implements.
- [[../plans/2026-09-04-0900-mechanical-session-gates]] — the multi-session tracker.
- [[../decisions/ADR-023-document-writing-standard]] — the document contract `doc-lint.sh` enforces,
  which this gate sits beside rather than replacing.
- [[../decisions/ADR-025-mechanical-brevity-enforcement]] — the precedent: measure mechanically where
  prose rules did not work.
