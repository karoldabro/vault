---
type: session
project: vault
date: 2026-09-21
topic: /v-pm shard side of cross-session contracts (S12)
files_touched: [templates/_features/project-shard.md, commands/v-pm/steps/04-seed-workspace.md, commands/v-pm/steps/07-status.md, commands/v-work/steps/05-commit-capture.md, commands/v-team/steps/03-propose-loop.md, tests/unit/v-pm.bats]
decisions: []
tags: [session, v-team, v-pm]
---

# /v-pm shard side of cross-session contracts (S12)

## Goal
Give the `/v-pm` project shard the `depends` column and a contracts section, and have the status and close steps use `bin/gate.sh master` (S12, contract C-11).

## Did
- Shard template: `depends` after `status`, blank example rows dropped, header-only `## Cross-session contracts` section that points to `templates/master-plan.md`.
- Seed step seeds three sections; `/v-pm status` runs `bin/gate.sh master <shard> 2>&1` per open shard and prints a `Contract gap` line; step 5.0 of `commands/v-work/steps/05-commit-capture.md` sets the master-plan row to done through `session_of`.
- Four graders `checks/shard-contracts-SC-1.sh` to `-4.sh` MET; `all --phase close` exits 0; unit suite 956 tests with the 5 known failures only. Commit 94dcc2c.
- Republished the master plan's page and the S6 plan's page at their links.

## Learned
- Under load one plan-probes budget test failed once and passed alone; the full rerun was clean.
- Every consumer of the shard read the header by column name, so adding a column broke no test or script.
- A seeded shard with a literal `<N>` appetite line still passes the gate.

## Next
- Deferred from S6: shared `refuse` and path helpers, cycle check, fenced-table handling.
- Open master-plan sessions: S9 (stack packs) and S11 (SQL probes and auditors).
- Push `eea8cb8`, `af5f530`, `94dcc2c` and this capture: pushing is the operator's.

## Refs
- [[../plans/2026-09-21-2040-pm-shard-contracts]]
- [[../plans/2026-09-21-0900-architecture-first-planning]]
- [[../plans/2026-09-21-1940-cross-session-contracts]]
