---
type: indication
project: vault
slug: plan-appetite-not-tasks
scope: repo
tags: [indication, v-pm, planning, tracking]
---

# plan-appetite-not-tasks

## Rule
A planner that does not read the code emits a **budget**, never a task list. `/v-pm` writes an
`## Appetite` (sessions per repo) and a `## First slice` into `generic-plan.md`, and seeds the
`## Sessions` header in each shard with **no rows**. The repo's own `/v-team` session decomposes at
propose-time `(f3)`: it sizes units against ~9 files, cuts `[could]` then `[should]` rules to fit the
appetite rather than exceeding it, picks each unit's command from the `/v-do` → `/v-work` → `/v-team`
ladder, and owns every row thereafter.

The tracker lives in `projects/<proj>/plan.md` — the file the working session already opens. Every row
carries `evidence` and `last touched`; a `done` row with no evidence is invalid. Status is **derived**:
`/v-capture` Step 4e rolls `header.md` up from the rows, and nothing hand-maintains a second copy.

## Rationale
Two failures, both measured in this vault. A roadmap of 15 up-front sessions ran 2 in 5.5 weeks, while
a 14-row tracker shipped 10 of 10 — the difference was that the second lived in the shard its session
already opened, and the first sat in a file nothing forced anyone to read. Separately, nine of twelve
features read `planning` in `header.md` while their shards read `done`, because the field had two homes
and only one was ever written.

Deviation is not the defect. That 10-of-10 tracker rewrote nearly every row as it went — scope cut, work
added, a session inserted no plan predicted — and recorded each one. A row that drifts **silently** is
the defect; a row that says how it drifted is the tracker working.

## Examples
- Do: `## Appetite | api | 3 sessions | contract must land before the app can start` → the api's
  `/v-team` writes 3 rows, cuts a `[could]` rule to fit, and notes the cut.
- Do: close a row with `done · a1b2c3d · 2026-09-01 · smaller than written — the list endpoint already
  paginated`.
- Don't: let `/v-pm` write `S1 add migration, S2 add service, S3 add controller` — it has not read the
  code, and those are layers, not slices.
- Don't: exceed the appetite quietly. Cut scope, or take the re-size to the operator.
- Don't: assign `/v-ask` to a row — it writes nothing, so it can never close one.
- Don't: hand-edit `header.md` status. Derive it, or the two copies drift again.

## Applies-to
`commands/v-pm/steps/{03-plan-panel,04-seed-workspace,07-status}.md`,
`commands/v-team/steps/{00-feature-pickup,03-propose-loop}.md`, `commands/v-capture.md` (Step 4e),
`templates/_features/{generic-plan,project-shard}.md`, `vault-guide.md` §13
