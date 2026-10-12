---
type: indication
project: vault
slug: pm-plans-sessions
scope: repo
tags: [indication, v-pm, planning, tracking]
---

# pm-plans-sessions

## Rule
`/v-pm` reads the code and splits a feature into sessions; each session claims and closes its own row.
The plan's `## Sessions` table is the one tracker. Each row names the repo path its command runs in,
the command, its dependencies and its `req` ids, and has one brief with a paste-ready run line.
`bin/pm-plan.sh check` refuses a plan that breaks this; `bin/pm-plan.sh order` prints the waves.

A session starts through `commands/_shared/feature-pickup.md`, which refuses it unless the row is
`todo` and every dependency is `done`, then marks it `doing`. The close marks it `done` with the code
commit as evidence. Status elsewhere — `header.md`, the done lines — is derived from the rows.

## Rationale
An up-front roadmap stalled here because its tracker sat in a file nothing made a session open. A row
the session must claim to start, and must close to finish, is opened by construction. Rows will still
be wrong in detail: the tracker that shipped 10 of 10 sessions rewrote nearly every row on the way.

## Examples
- Do: close a row with `done · a1b2c3d · 2026-10-12 · smaller than written — the list endpoint already paginated`.
- Do: append `S4` with its brief when a session finds work no row holds.
- Don't: start a session by hand while its dependency reads `doing`.
- Don't: assign `/v-ask` to a row — it writes nothing, so it can never close one.
- Don't: hand-edit `header.md` status. Derive it, or the two copies drift again.

## Applies-to
`commands/v-pm/steps/{01-intake,03-plan-panel,05-capture,06-reconcile,07-status}.md`,
`commands/_shared/feature-pickup.md`, `commands/v-work/steps/05-commit-capture.md` §5.1a,
`templates/feature-plan.md`, `templates/handoff.md`, `bin/pm-plan.sh`,
`personas/_shared/planning/delivery-planner.md`
