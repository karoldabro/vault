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

## Next

- Phases 2 to 6 are rows in `vault/plans/2026-09-04-0900-mechanical-session-gates.md`: the seven
  remaining checks, the two definition-of-done profiles, the verifier contract, the wiring into
  `/v-team` `/v-do` `/v-pm` `/v-cr`, the onboarding keys in `bin/vault-init.sh`, the cross-plan
  tracker, the defect ledger, the commit hook, and ADR-026.
- Six of the nine criteria are not yet due. `gate.sh verdict` names which, and refuses the moment a
  covering work item flips to `DONE`.
- ADR-026 is named in the plan's `## Decisions` rows and does not exist yet. The `decisions` check
  that would refuse this is W-13, itself unbuilt.

## Refs

- [[../architecture/session-gates.md]] — the contract every subcommand implements.
- [[../plans/2026-09-04-0900-mechanical-session-gates]] — the multi-session tracker.
- [[../decisions/ADR-023-document-writing-standard]] — the document contract `doc-lint.sh` enforces,
  which this gate sits beside rather than replacing.
- [[../decisions/ADR-025-mechanical-brevity-enforcement]] — the precedent: measure mechanically where
  prose rules did not work.
