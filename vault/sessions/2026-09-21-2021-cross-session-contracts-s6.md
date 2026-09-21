---
type: session
project: vault
date: 2026-09-21
topic: cross-session contracts and gate.sh master (S6)
files_touched: [lib/master-check.sh, bin/gate.sh, templates/master-plan.md, templates/plan.md, commands/v-team.md, commands/v-team/steps/03-propose-loop.md, vault/check-budget.md, tests/unit/gate.bats, tests/unit/v-team.bats, vault/plans/2026-09-21-0900-architecture-first-planning.md]
decisions: []
tags: [session, v-team, gate]
---

# cross-session contracts and gate.sh master (S6)

## Goal
Give every master plan a required `## Cross-session contracts` table and a gate that refuses a dependency between two sessions with no contract row (D-15, E-3).

## Did
- Built `lib/master-check.sh` (`cmd_master`), routed `bin/gate.sh master`, and called it in `all --phase propose` and `approve`; `bin/gate.sh` grew from 812 to 824 lines.
- Added `templates/master-plan.md` (Sessions with `depends`, contracts, lifecycle row) and the `session_of` key in `templates/plan.md`.
- Wired step (a), (f3), (g) of `commands/v-team/steps/03-propose-loop.md` and Step 4 of `commands/v-team.md`; rule-count stayed at 181.
- Repaired the master plan: S11 moved into Sessions, S7 extra cell removed, contracts C-9 to C-11, S12 added, E-3 set to HALF-BUILT, S6 done.
- Plan `vault/plans/2026-09-21-1940-cross-session-contracts.md`; five graders `checks/master-SC-1.sh` to `-5.sh` all MET through `bin/gate.sh verdict --run`; `all --phase close` exits 0; full unit suite 951 tests, the 5 known failures only. Commit eea8cb8.

## Learned
- `checks/doc-truth-SC-3.sh` already failed on HEAD: `arch` and `human` had no row in `vault/check-budget.md`. The new rows fix all three.
- Any table line under a heading is a row for `table_rows`. A lifecycle example row inside a template comment must be indented, or the gate reads it as a contract.
- The master plan lacked contract rows for S2 on S1, S4 on S1 and S9 on S5, and held S11 inside its contracts table.
- `check_is_claimed_elsewhere` refuses a plan that names another plan's check path in backticks, including in a master plan's E-3 row.
- A seeded-mutant pass found six surviving mutants that the first graders missed; adding cases killed all six.
- `git stash` during the session touched two unrelated modified files and restored them; avoid it here.

## Behaviors & rules
- Sessions table with a `depends` entry and no contract row from the depended-on session to the depending one → `gate.sh master` exits 1 naming the pair. Edge: a bullet list under `## Sessions` is silent.
- Plan with `session_of: <master>#<id>` and a consumed contract whose producer status is not `done` → exit 1 naming contract, producer and status.
- Plan with neither a Sessions table nor `session_of` → silent exit 0.

## Next
- Session S12: the `/v-pm` shard side (`templates/_features/project-shard.md`, `04-seed-workspace.md`, `07-status.md`, `tests/unit/v-pm.bats`, close duty in `05-commit-capture.md`).
- Republish the master plan's human page at its `human_plan` link; the file on disk is current, the published copy is not.
- Deferred: shared `refuse` and path helpers, cycle check, fenced-table handling in `table_header`.

## Refs
- [[../plans/2026-09-21-1940-cross-session-contracts]]
- [[../plans/2026-09-21-0900-architecture-first-planning]]
- [[../decisions/ADR-031-architecture-first-planning]]
