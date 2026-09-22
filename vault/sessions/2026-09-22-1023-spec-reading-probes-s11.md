---
type: session
project: vault
date: 2026-09-22
topic: spec-reading-probes-s11
files_touched: [bin/plan-probes.sh, checks/plan-probe-SC-2.sh, checks/plan-probe-SC-3.sh, checks/plan-probe-SC-7.sh, checks/spec-probes-SC-1.sh, checks/spec-probes-SC-2.sh, checks/spec-probes-SC-3.sh, checks/spec-probes-SC-4.sh, checks/spec-probes-SC-5.sh, checks/spec-probes-SC-6.sh, checks/spec-probes-SC-7.sh, checks/spec-probes-SC-8.sh, commands/_shared/plan-probes.md, commands/_shared/probe-kit.md, commands/v-team/steps/03-propose-loop.md, lib/probe-md-table.awk, lib/probe-md-table.sh, probes/registry.tsv, probes/similar-symbols.sh, probes/sql-schema.sh, tests/fixtures/probe/spec-data-model-bad.arch.md, tests/fixtures/probe/spec-data-model-clean.arch.md, tests/fixtures/probe/spec-no-data-model.arch.md, tests/unit/plan-probes.bats, tests/unit/probe.bats, vault/plans/2026-09-21-0900-architecture-first-planning.md, vault/plans/2026-09-22-1023-spec-reading-probes.md, vault/plans/2026-09-22-1023-spec-reading-probes.arch.md, vault/plans/2026-09-22-1023-spec-reading-probes.trail.md]
decisions: []
tags: [session, probes, spec-reading-probes]
---

# spec-reading-probes-s11

## Goal
Land S11 of the architecture-first-planning master plan: spec-reading SQL probes `spec-tables` and
`spec-naming`, and the `data-model` and `naming` triage auditors, for the plan-time probe stage.

## Did
- Ran the `/v-team` PROPOSE panel (architect, consumer, correctness, quality) over two rounds against
  the draft plan and arch spec. Found and fixed five confirmed blockers across both rounds: a dedup
  gate that dropped drift on a same-named table, an undeterminable auditor envelope, real-SQL findings
  leaking through a spec-less run, `pp_verify` silently dropping extra rows-files, and a grader that
  didn't measure the file its criterion named.
- Implemented all 15 plan work items: `spec_mode`-gated `spec-tables`/`spec-naming` checks in
  `probes/sql-schema.sh`; a shared markdown-table parser (`lib/probe-md-table.sh`) factored out of
  `probes/similar-symbols.sh`; the `data-model`/`naming` auditor rows in
  `commands/_shared/plan-probes.md`; the budget/verify extensions in `bin/plan-probes.sh`.
- Ran a diff-review panel (same four personas) against the real implementation, two rounds. Round 1
  found and fixed two more real bugs via live execution against constructed fixtures: a within-spec
  duplicate column that couldn't be detected (the spec extractor gave every column its own line
  instead of the table's), and a spec table exactly re-declaring a same-named real table producing a
  false "duplicates itself" warning. Round 2 converged clean.
- Closed S11's row in the master plan (all twelve sessions now done), committed and pushed —
  `7ca0aab`.

## Learned
- A fork spawning its own nested critic subagents via the Agent tool can stall silently for an hour
  with zero visible progress: `ListAgents` shows no busy/idle state for those, only `roster`.
  Messaging a specific teammate by name gets an "already running" confirmation that proves liveness —
  spawning critics directly from the top-level session, not through a nested fork, avoided the problem
  entirely on retry.
- `bin/probe-panel.sh`'s `own` posture, with `PROBE_PANEL_REPO_CODE` unset, refuses tools declared
  `executes-repo-code: yes` (`claude-validate`, `lizard`) and prints `registry-edited` whenever the
  reviewed diff itself touches `probes/registry.tsv` — expected behaviour for a session reviewing its
  own framework's changes, not a defect.
- `dup-column-set`/`column-drift`'s file citation depends on fact-stream insertion order, not an
  explicit rule — appending spec facts after real facts is what makes a spec-vs-real comparison cite
  the spec's file, and that ordering needed to be a stated plan decision, not an implementation detail
  left implicit.
- When a shared awk program grows a "plain mode" vs. a "spec-aware mode," every keyed accumulator
  (`have`, `cols`, `ncol`, `nty`) needs the same widening under the same flag — two review rounds each
  found a case where only some of them had been updated.

## Behaviors & rules
- `spec-tables` on a spec with no `## Data model` table, against a repo whose real SQL alone already
  trips `sql-dup-columns` → prints nothing; a finding requires at least one spec-derived contributing
  fact.
- A spec table sharing a real table's name, with one genuinely drifted column → `column-drift` fires,
  citing the spec's file, its message disclosing `(real)`/`(spec)` per entry; edge: the same pair with
  no drift → no `dup-column-set` row (same-name, cross-origin table pairs are never compared for
  duplication — they describe one table, not two).
- A spec table declaring the same column twice → `dup-column-in-table` fires (every column of one spec
  table shares that table's declaration line, mirroring a real `CREATE TABLE`).
- `bin/plan-probes.sh verify <out> <rows-file>...` with a triggered auditor whose rows-file was omitted
  → prints a `note:` naming the missing auditor, instead of silently producing nothing for it.

## Next
- `checks/plan-probe-SC-2.sh`/`-3.sh`/`-7.sh` picked up drive-by fixes (a pipefail/SIGPIPE risk, an
  assertion the new multi-auditor note logic invalidated, a table-format regex) while being adapted for
  the Auditors table restructuring — worth a glance if anything else depends on their exact prior
  behaviour.
- `output-styles/director.md` and `scripts/completion-hook.sh` remain modified and unstaged in the
  working tree — pre-existing, unrelated to S11, left alone deliberately.
- Master plan `vault/plans/2026-09-21-0900-architecture-first-planning.md` is fully closed: all twelve
  sessions (S1–S12) done.

## Refs
- [[../plans/2026-09-22-1023-spec-reading-probes]] — the plan
- [[../plans/2026-09-21-0900-architecture-first-planning]] — master plan, S11 row, now fully closed
- [[../sessions/2026-09-21-1800-plan-time-probes-s5]] — S5, which shipped the `reuse` auditor and
  deferred this work
- [[../indications/plans-are-build-orders]]
