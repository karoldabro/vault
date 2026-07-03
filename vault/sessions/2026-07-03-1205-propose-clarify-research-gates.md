---
type: session
project: vault
date: 2026-07-03
topic: propose-clarify-research-gates
files_touched:
  - commands/v-work/steps/03-propose.md
  - commands/v-work/steps/01-analyze.md
  - commands/v-team/steps/03-propose-loop.md
  - commands/v-team.md
  - commands/v-work.md
  - tool-playbook.md
  - tests/unit/research-clarify.bats
decisions: []
tags: [session, v-work, v-team, propose, research, clarify]
---

# propose-clarify-research-gates

## Goal
Add two front gates to PROPOSE — clarify-before-planning and mandatory online research — to both
`/v-work` and `/v-team`, cutting hallucination and premature planning.

## Did
- Added **§3a.0a Understand & clarify** + **§3a.0b External research** at the top of the shared
  [[../../commands/v-work/steps/03-propose]] `§3a`, so both `/v-work` and `/v-team` inherit them via
  the existing reuse (v-team's propose-loop runs `§3a` in its v0 draft).
- Clarify gate: state understanding + assumptions, list open doubts, route each (answer from
  context/research · ask user via `AskUserQuestion` batched · state safe default); forbids guessing
  past real ambiguity; if user unavailable → proceed on defaults + flag at approval gate.
- Research gate: "your prior is weaker than practitioners who solved this"; gated (skips
  refactor/docs/formatting/rename); `WebSearch`/`WebFetch` + `deep-research`/`tool-evaluator`/
  `trend-researcher`; **contradicting consensus must be adopted or refuted in writing**; cite sources.
- Wired both into [[../../commands/v-team/steps/03-propose-loop]] `(a)` — run before the panel spawns;
  an unresearched design / unsound assumption is now a legitimate critic finding.
- Seeded doubts early in [[../../commands/v-work/steps/01-analyze]] `§1.2` (routes to `§3a.0a`).
- Added `tool-playbook.md` **§7 Web research** (framed correctness-saving, not token-saving).
- Both dispatchers advertise the gates; output contracts gained `Assumptions`/`Clarifications`/
  `Research` lines.
- New `tests/unit/research-clarify.bats` — 10 file-contract tests, all green.
- Committed only my 7 files directly to `main` (`253209e`) — parallel session shares the working
  tree, so no branch switch and explicit staging (no `git add -A`).

## Learned
- The installed command copy under `~/.claude/commands/` is a **symlink into the repo** (install.sh
  symlinks command subdirs), so editing repo source is immediately live — no reinstall needed.
- Two pre-existing unit failures unrelated to this work: `test-hooks-tools-rename.bats` #99
  (`vault-guide.md` hooks/tools contract) and `testing-personas.bats` #114 (`README.md` +
  indications reference `_shared/testing`) — collateral from the README-slimming commit `254c025`.
- Putting a change in the shared `§3a` is the DRY seam for both lifecycles; v-team layers only the
  panel on top, so front-gate work lands once.

## Behaviors & rules
- PROPOSE `§3a` opens with `§3a.0a` (clarify) then `§3a.0b` (research), before code location/design.
- Research gate runs for non-trivial design/architecture/algorithm/data-model/library-choice; skips
  pure refactor/docs/formatting/rename → one-line skip note.
- A credible contradicting consensus → must adopt it OR record a written reason; edge: silently
  ignoring it is disallowed and surfaced at the approval gate.
- Clarify gate asks the user only for plan-changing doubts with no safe default; edge: user
  unavailable → proceed on stated defaults and flag every assumption at the approval gate.
- In `/v-team`, both gates run in the v0 draft before critics spawn; edge: an unresearched design or
  unsound assumption is a grounded critic finding.

## Next
- Optional dials if the user wants: force ≥1 clarifying question every run; let research *block*
  v-team convergence (BLOCKER-grade) instead of reconcile-explicitly.
- Fix the two pre-existing failing tests (#99 vault-guide, #114 README) separately.

## Refs
- [[../../commands/v-work/steps/03-propose]]
- [[../../commands/v-team/steps/03-propose-loop]]
- [[tools-suggestions-not-rules]]
- [[confirmed-vs-advisory-findings]]
