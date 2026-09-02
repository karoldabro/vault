---
type: session
project: vault
date: 2026-09-02
topic: consumer-seat-and-artifact-lifecycles
files_touched: [bin/doc-lint.sh, lib/doc-lint-patterns.tsv, personas/_shared/consumer.md, personas/_resolution.md, templates/plan.md, commands/v-team/steps/03-propose-loop.md, commands/v-work/steps/03-propose.md, tests/unit/document-standard.bats, vault/indications/artifact-has-a-named-consumer.md, vault/indications/_index.md]
decisions: []
tags: [session]
---

# consumer-seat-and-artifact-lifecycles

## Goal
Stop the framework producing plans that specify what gets built and never who consumes it, after a
session in another project shipped an approved plan carrying four such holes.

## Did
- Created `personas/_shared/consumer.md`, a critic that simulates the receiver instead of reviewing
  the plan: it writes the literal text the receiver gets and produces one real output from it.
- Seated it in `personas/_resolution.md` §2, §2.1 and §2.2 as a guaranteed, undroppable seat, with a
  raise to `team_max_parallel_critics: 4` rather than dropping a triggered lens.
- Added `## Artifact lifecycles` to `templates/plan.md` — who asks · who writes · who reads · what
  happens when absent or malformed — with the literal passing `none` row in the section comment.
- Added `check_plan` to `bin/doc-lint.sh`: PLAN1 on a blank cell or a row naming nothing openable,
  PLAN2 on a file-creating plan with no table.
- Registered every code the linter emits in `lib/doc-lint-patterns.tsv`, and renumbered its stale
  group comments (rules 2, 4, 9 → 5, 7, 10) to match `commands/_shared/document-standard.md`.
- Wired the seat into `commands/v-team/steps/03-propose-loop.md` §(b) and §(c), and the four
  questions into the `/v-work` lite critic at `commands/v-work/steps/03-propose.md` §3a.6.
- Added 11 tests to `tests/unit/document-standard.bats`; wrote
  `vault/indications/artifact-has-a-named-consumer.md` and registered it.
- Ran the new seat against the plan that creates it, alongside `skeptic`. Committed `125cc48`.

## Learned
- `templates/plan.md` is instantiated only by `commands/v-team/steps/03-propose-loop.md:32`.
  `/v-work` writes no plan artifact and `/v-do` writes nothing, so `check_plan` can only ever see
  `/v-team` work — and `/v-work` is the command most changes go through.
- `commands/_shared/document-standard.md` sits at 119 lines against a 120-line cap its own test
  enforces. It takes no new prose; a rule that needs a written home goes to
  `lib/doc-lint-patterns.tsv` instead.
- The bats test named "every linter check maps to a written rule" never opened
  `document-standard.md`. It looped over `lib/doc-lint-patterns.tsv` rows and checked only the group
  column, so SIZE1, LONG1, DUP1 and INDEX1–3 mapped to nothing.
- The consumer seat found two blockers on its first run that the skeptic did not, both by simulation:
  a `check_plan` gate that gave opposite answers on the same file, and a `none` escape whose obvious
  form tripped the check it was meant to escape.
- `vault/plans/` holds 24 plans and 8 still carry `status: proposed`, which caps how wide PLAN2's
  trigger can be without firing on history.

## Behaviors & rules
- A plan creates an artifact → `## Artifact lifecycles` names who asks for it, who writes it, who
  reads it, and what happens when it is absent or malformed; edge: a plan that creates nothing writes
  one `none` row carrying its reason, and a bare `none` row still fires PLAN1.
- A lifecycle row is not the `none` row → it carries at least one path or backticked identifier;
  edge: four cells of plausible prose ("the drafting session") fire PLAN1 even though none is empty.
- A plan carries the section → only PLAN1 can fire on it. A plan lacks the section → only PLAN2 can,
  and only when a work-items cell reads exactly `create` and `status` is `proposed` or `approved`.
- A file sits under `templates/` → `check_plan` skips it, because its placeholder row is empty by
  design.
- A PROPOSE panel runs → the `consumer` seat is filled; edge: dropped only when the change creates no
  handoff at all, and the drop is recorded in the trail.
- A critic claims a handoff works → it shows the receiver's literal input and one produced output; a
  description of the handoff grounds nothing.

## Next
- `/v-do` stays unguarded: it writes no plan artifact by design, so neither the table nor the linter
  reaches a handoff it introduces.
- Nothing catches a run that seated three mechanism lenses and skipped the consumer seat. The
  contract tests catch deletion and demotion; there is no runtime to check.
- Seven historical plans carry panel process inline and fail `bin/doc-lint.sh` on PROC1/PROC4. They
  predate `commands/_shared/document-standard.md`.
- Six pre-existing unit-test failures remain, none from this change.

## Refs
- [[../plans/2026-09-02-2147-consumer-seat-and-artifact-lifecycles]] — the plan this executed.
- [[../plans/2026-09-02-2147-consumer-seat-and-artifact-lifecycles.trail]] — critic findings and
  their dispositions, including the two the consumer seat caught alone.
- [[../indications/artifact-has-a-named-consumer]] — the durable rule this session established.
- [[../indications/enforced-not-just-stated]] — the rule that forced the linter and its tests rather
  than prose alone.

## Continuation 2026-09-02-2230

Closed the four findings the panel left open.

- `/v-work` now instantiates `templates/plan.md`. Its §3a "Layer 2 — to the plan artifact" listed
  everything the artifact holds and closed with "the user is told this layer exists and where", while
  `grep -rn "plans/" commands/v-work/steps/*.md` returned nothing. It promised a file it never wrote.
  No trail sidecar there, since it runs no panel; `05-commit-capture.md` stages the plan.
- `PLAN2` widened from a `create` work item to any work-items row. Seven plans still marked
  `status: proposed` were blocking that — each has a matching session record and its named paths
  exist, so all seven now say `executed`. The `v-pm` plan looked incomplete at 4 of 14 paths; the
  misses are renumbered step files, paths written without their `commands/` prefix, a scratchpad file
  and a machine-local path.
- The lifecycle table's column `who asks for it` became `what requires it`, and `absent or malformed`
  became `missing or wrong`. The section comment now settles granularity (one row per receiver-facing
  contract) and pins both ends, because the consumer seat filled the table for a sample plan and
  reported it had to invent all three conventions.
- Seven contract tests in `tests/unit/v-team.bats` assert the seat across all three selection
  regimes, the cap-raise escape, the dry-run instruction, the `/v-work` artifact and the literal
  `none` row. 448 unit tests pass.
