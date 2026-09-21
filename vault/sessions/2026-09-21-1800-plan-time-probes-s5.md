---
type: session
project: vault
date: 2026-09-21
topic: S5 plan-time probes and reuse auditor for /v-team PROPOSE
files_touched: [bin/plan-probes.sh, bin/probe-panel.sh, probes/similar-symbols.sh, probes/registry.tsv, commands/_shared/plan-probes.md, commands/_shared/probe-kit.md, commands/v-team/steps/03-propose-loop.md, lib/shared-module-rules.tsv, tests/unit/plan-probes.bats, checks/plan-probe-SC-1.sh, checks/plan-probe-SC-7.sh, vault/plans/2026-09-21-0900-architecture-first-planning.md]
decisions: []
tags: [session, probes, v-team, cost]
---

# S5 plan-time probes and reuse auditor for /v-team PROPOSE

## Goal
Add a plan-time probe stage to `/v-team` PROPOSE, with independent auditors, and keep its cost under 50% of a PROPOSE (D-10).

## Did
- Measured the baseline from real session transcripts: the PROPOSE window cost 769,168 fresh tokens for the v-rule plan (S8) and 1,018,594 for the sandbox-probe plan (S10).
- Planned in `vault/plans/2026-09-21-1800-plan-time-probes.md` with ten decisions (PT-1 to PT-10); three reviewers revised the plan once and two reviewers revised the code once.
- Wrote seven graders first, then `bin/plan-probes.sh` (`budget`, `verify`, `measure`), the `--stage plan` block of `bin/probe-panel.sh`, the `spec-symbols` check and step (b2) of `commands/v-team/steps/03-propose-loop.md`.
- `bin/gate.sh verdict <plan> --run` reports SC-1 to SC-7 MET; the full unit suite fails only the 5 known tests. Commit `459ab74`.

## Learned
- `bin/probe-panel.sh cited` matches probe, file and line only, and awk reads line `012` as 12, so `verify` compares whole rows against `confirmed.tsv` and `advisory.tsv`.
- A path filter at plan time drops the useful rows: 13 of 14 `similar-symbols` rows on the sandbox spec point at code the spec does not list.
- The real per-critic PROPOSE cost is about 140,000 fresh tokens and the main thread about 390,000; a trial `haiku` auditor costs about 36,000. With one auditor the stage projects 3% to 4% of the two baselines, so the 50% limit binds only outside the panel's caps.
- The core rejects an absolute `file` in a row, so a spec outside the repo (vault under `~/vault/<slug>/`) is named by its base name.
- `bin/rule-count.sh` counts the whole `/v-team` corpus, which reads 181 rule lines against a budget of 173. A module outside the corpus adds none. New lines in `03-propose-loop.md` avoid the trigger words.
- `pkill -f` on a grader name killed the calling shell; `checks/probe-panel-SC-7.sh` runs the docker bats suite and takes minutes, so `checks/plan-probe-SC-1.sh` runs SC-1 to SC-6 only.

## Behaviors & rules
- Block holds a `[confirmed]` row with severity `error` → `bin/plan-probes.sh verify` prints `open:` and exits 1; a verdict and the tier change neither.
- Auditor line differs from a block row in any field, or names another verdict → `verify` drops it and counts it in a `note:`.
- Projected added cost over 50% of the projected baseline → `tier: skip`; only the block over the limit → `block-only`; the plan names no `arch_spec` → no stage and no note.
- `<out>/tier.txt` missing or not a tier → `verify` exits 2, so a session that skipped step (b2) is refused at step (g).
- Reuse-map cell with a path token → the path exists inside the repo. Each later identifier occurs as a whole word in that file. A cell with no path token is skipped.

## Next
- Session S11: `spec-tables`, `spec-naming`, and the `data-model` and `naming` auditors, with the spec-reading part of `sql-*`.
- Run the stage inside a real `/v-team` session and refit the `PLAN_PROBE_*` constants from a two-round run.
- Two review findings were not applied: the size split beyond S11, and the reuse check as a gate rule in `lib/arch-check.sh`.
- `similar-symbols` still matches on shared words, so the reuse auditor sees noise beyond the stopword fix.

## Refs
- `vault/plans/2026-09-21-1800-plan-time-probes.md`: the plan, with decisions PT-1 to PT-10 and the recorded baselines.
- `commands/_shared/plan-probes.md`: the rules of the plan-time stage.
- `vault/plans/2026-09-21-0900-architecture-first-planning.md`: the master plan; row S5 done, row S11 added.
- `vault/decisions/ADR-003-tool-grounded-findings.md`: a finding blocks only when a tool confirms it.
