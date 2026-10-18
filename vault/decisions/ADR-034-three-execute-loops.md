---
type: decision
project: vault
id: ADR-034
slug: three-execute-loops
status: accepted
scope: repo
date: 2026-10-18
supersedes_in_part: [ADR-003, ADR-011]
tags: [adr, v-team, v-work, testing, personas, plugins]
---

# ADR-034 — EXECUTE runs three loops with separate owners; quality tools come from a plugin `check` point

## Context
Neither `/v-work` nor `/v-team` ran the repo's static analysis while code was written: `lint_command` ran
first at close, and `/v-team` ran analyzers only inside its review loop, from free-text strings in the
stack packs. No step measured coverage of a change, no file set a coverage floor, and mutation testing
was optional, with a hand-made characterization check accepted as equal. The review panel also asked
critics to re-check size, nesting and dead code, which linters already report. The vault-quality-gates
plugin already measures static analysis on a commit, changed-line coverage and Infection, but no
extension point let the lifecycle call it.

## Decision
1. **A plugin extension point `check`.** `extend/check.sh <static|tests> <repo> <base>` runs only for a
   plugin the repo's `plugins:` line names. Exit 0 measured and acceptable, 1 measured and worse, 2 could
   not measure; above 2 is clamped to 2. `bin/vault-check.sh` is the one caller. With no opted-in `check`
   plugin it runs `lint_command` or `test_command` and says so; a template value such as `phpunit <path>`
   exits 2. Contract: `vault/architecture/plugin-extension-contract.md`.
2. **The floor is max(80, the plugin's floor) of changed lines**, judged only by `bin/vault-check.sh`.
   There is no fixed mutation score: every surviving mutant on the diff is killed or labelled
   `equivalent: <reason>`, following diff-based mutation testing at Google (Petrović et al., arXiv
   2102.11378), which found neither a score nor a list of all survivors actionable.
3. **`/v-team` EXECUTE is three loops.** Implement edits production code and runs the static check before
   a unit is done. The code-review loop judges design only. The testing loop
   (`commands/_shared/testing-loop.md`) writes tests, measures them, and has reviewers who never wrote
   them label survivors. A writer edits test files only; a production bug a test finds goes back to
   implement.
4. **`/v-work` runs no loops.** One static check, one test-writer pass and one `tests` run; what remains
   goes to the operator unlabelled.
5. **The code-review panel critiques what no tool sees.** Each critic gets the static output, and a
   finding that restates it is dropped. Diff review seats architect, `quality` and `correctness` by
   default. **This widens ADR-003's "concrete check":** a design finding is also `confirmed` by an
   existing symbol `path:line`, a package command and its output, a smaller rewrite applied in a scratch
   worktree with the static check and touched tests passing, or a measurement with its command. An
   unrun rewrite stays `advisory`, at most MINOR, so the false-positive floor ADR-003 set holds.
6. **Three new test-design generators** — `api-contract-mapper`, `abuse-case-designer`,
   `performance-budget-designer` — join `personas/_shared/testing/design/`, seated by trigger. **This
   moves ADR-011's confirmation step** from the diff-review loop to the testing loop; generators still
   emit pre-implementation and never vote.

## Consequences
- Until vault-quality-gates ships its `check` point, no repo enforces the floor or runs mutation testing;
  every testing loop prints `coverage unmeasured: <reason>`.
- A full `/v-team` run spawns about 9 to 45 agents, up from 6 to 12. Its token cost has not been
  re-measured.
- Repos without a linter lose nothing: `quality.md` applies its size and structure items only when no
  static check ran.
- `bin/gate.sh` `plugin_keys` keeps its own `plugins:` parser until it switches to
  `vault_plugin_opted_in`.

## Refs
- `vault/plans/2026-10-18-1257-quality-loops.md` — the plan that built this.
- `vault/decisions/ADR-003-tool-grounded-findings.md`, `vault/decisions/ADR-011-generative-test-design-subphase.md` — the clauses widened and moved.
- `vault/decisions/ADR-030-framework-extension-points.md` — the extension-point mechanism `check` joins.
