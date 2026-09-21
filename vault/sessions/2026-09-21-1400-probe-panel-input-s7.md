---
type: session
project: vault
date: 2026-09-21
topic: probe results as a review panel input (S7)
files_touched: [bin/probe-panel.sh, bin/indication-route-audit.sh, commands/_shared/critic-panel.md, commands/_shared/probe-kit.md, commands/v-team/steps/04-execute-loop.md, commands/v-cr/steps/03-review.md, commands/v-work/steps/04-execute.md, templates/indication.md, tests/unit/probe-panel.bats]
decisions: []
tags: [session, probes, review-panel]
---

# probe results as a review panel input (S7)

## Goal
Feed `bin/probe.sh diff` rows to the critics of `/v-team`, `/v-cr` and `/v-work` review, and add the `probe:` key to indications (session S7 of `vault/plans/2026-09-21-0900-architecture-first-planning.md`).

## Did
- Planned it as `vault/plans/2026-09-21-1330-probe-panel-input.md` (nine decisions, seven criteria, graders written first); two review rounds changed D-1 to D-4 and D-7.
- Built `bin/probe-panel.sh` (`run`, `cited`), the probe stage in `commands/_shared/critic-panel.md` §(a), the three review-step edits, the `probe:` key and its audit check.
- Added `tests/unit/probe-panel.bats`, guards in `tests/unit/v-team.bats`, `tests/unit/v-cr.bats`, `tests/unit/cr-rule-routing.bats`, and `checks/probe-panel-SC-1.sh` to `-7.sh`. `bin/gate.sh verdict --run` reports SC-1 to SC-7 MET.
- A post-build review found two confirmed majors. A framework `yes` probe run from a planted tool directory printed as `[confirmed]`. Edited probe scripts did not trigger `registry-edited`. Both are fixed with grader cases, and mutants of the helper now fail the graders.

## Learned
- `bin/probe.sh diff` with the default `--base HEAD` misses committed work and still exits 0. The helper refuses a missing `--base`.
- Under `--no-repo-code` the kit skips `yes` probes with exit 0 or 1, so exit 2 alone cannot mark a run incomplete.
- A repo registry that is the framework's own file loads as framework origin, so origin by id is not enough in this repo.
- The helper marks every row advisory when the diff edits `probes/` or `lib/probe-*`.
- `bin/probe.sh run plan` prints 54 rows on this repo today, not 95.
- A `trap ... RETURN` in a bash function fires on every nested function return; use `trap ... EXIT` with a global.

## Behaviors & rules
- `pr` posture → `--no-repo-code`, no repo registry, whatever `PROBE_PANEL_REPO_CODE` says; edge: `own` behaves the same until the operator sets `PROBE_PANEL_REPO_CODE=yes`.
- Any absent, failed or skipped probe, or a kit exit of 2 → `probe-status: INCOMPLETE`, helper exit 2, rows found still printed.
- Framework row with `executes-repo-code: no` and no repo definition of its id → `[confirmed]`; every other row → `[advisory]`.
- More than 40 rows or 12,000 bytes → the block keeps the first ones by severity and prints `withheld: <n> of <m>`.

## Next
- Operator decides whether to set `PROBE_PANEL_REPO_CODE=yes` where lizard and typos are installed.
- S8 (`/v-rule`) reads the `probe:` key; S5 measures the row-cap cost.
- In-container `yes` probes for `/v-cr --sandbox` are deferred.

## Refs
- [[../plans/2026-09-21-1330-probe-panel-input]]
- [[../plans/2026-09-21-0900-architecture-first-planning]]
- [[../decisions/ADR-003-tool-grounded-findings]]
- [[../decisions/ADR-009-v-cr-sandboxed-execution]]
- [[../decisions/ADR-031-architecture-first-planning]]
