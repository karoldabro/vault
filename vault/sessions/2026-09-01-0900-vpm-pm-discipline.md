---
type: session
project: vault
date: 2026-09-01
topic: vpm-pm-discipline
files_touched: [commands/_shared/elicitation.md, commands/_shared/definition-of-done.md, commands/v-pm.md, commands/v-pm/steps/01-intake.md, commands/v-pm/steps/03-plan-panel.md, commands/v-pm/steps/04-seed-workspace.md, commands/v-pm/steps/07-status.md, commands/v-team/steps/00-feature-pickup.md, commands/v-team/steps/03-propose-loop.md, commands/v-work/steps/05-commit-capture.md, commands/v-do.md, commands/v-capture.md, templates/_features/requirements.md, templates/_features/generic-plan.md, templates/_features/project-shard.md, vault-guide.md, tests/unit/v-pm.bats, tests/unit/v-team.bats, tests/unit/research-clarify.bats, tests/unit/communication-contract.bats]
decisions: [ADR-024-vpm-pm-discipline]
tags: [session, v-pm, elicitation, definition-of-done, tracking]
---

# vpm-pm-discipline

## Goal
Make `/v-pm` behave like a product manager: elicit requirements properly, size the work, define what
"done" means, and keep the plan trackable.

## Did
- Researched real PM practice against the command specs, and measured what past sessions in this vault
  actually did about splitting work.
- Recounted feature execution directly from `~/vault/_features/` after a reviewer challenged the first
  figure, then rebuilt the plan on the corrected numbers.
- Added `commands/_shared/elicitation.md` and `commands/_shared/definition-of-done.md`.
- Rewrote `/v-pm`'s intake, plan panel, seeding and status steps; extended `/v-team`'s propose loop and
  feature pickup, `/v-work`'s commit step, `/v-do`'s self-review and `/v-capture`.
- Added `## Appetite`, `## First slice` and `## Options considered` to `generic-plan.md`, a `## Sessions`
  tracker to `project-shard.md`, and `## Assumptions to test` plus rule priorities to `requirements.md`.
- Wrote [[../decisions/ADR-024-vpm-pm-discipline]] and
  [[../indications/plan-appetite-not-tasks]]; corrected a wrong step reference in
  [[../indications/requirements-spec-vs-established]].
- Ran the suite: 430 pass, 11 fail, every failure matching the pre-existing set by name.

## Learned
- **The metric used to diagnose the problem was an instance of the problem.** "9 of 12 features never
  executed" came from `header.md` `status:`, which no command writes after seeding. Counted from the
  shards, only 3 of 12 have never started. The stale field was the real finding, and it killed the
  motivation for capping the planner's output.
- **Bats numbers tests positionally**, so adding tests renumbers everything after them. Comparing
  failures by number across a change is meaningless; compare by name. The recorded baseline of 8
  pre-existing failures was also wrong — a clean worktree at `HEAD` fails 21.
- **`bin/doc-lint.sh` does not check `commands/_shared/`.** That directory is absent from
  `is_document_folder()`, and the existing modules carry no frontmatter, so the linter exits 0 on any
  content. "Lint clean" proves nothing for a file there; assert line caps in bats instead.
- **An up-front session split is not inherently fragile.** The `ask-digitally` tracker shipped 10 of 10
  sessions while rewriting nearly every row. What separated it from the roadmap that stalled at 2 of 15
  is where the tracker lived — in the shard the working session already opens, against a file nothing
  forced anyone to read.
- **A gate's position decides whether it is a gate.** The Definition of Done was first placed in the
  capture step §5.4, which runs after §5.1 has already committed.
- Two reviewer findings were correct about the text but wrong about the consequence: collapsing
  §3a.0a's question rules would have deleted strings a prior session deliberately pinned in
  `tests/unit/research-clarify.bats`.

## Behaviors & rules
- A Definition-of-Done line is `met`, `failed`, or `not-applicable` with a reason → a line that cannot
  be honestly asserted is recorded, never ticked; edge: a repo with no runtime meets the test line by
  naming the real check it ran instead (linter, file contracts, an actual invocation).
- The done check runs before staging → a failed line stops the close; edge: feature-mode lines apply
  only when a `## Sessions` row exists, so a plain session is never blocked by a row it does not have.
- A `## Sessions` row reaches `done` only with evidence recorded → a `done` row with an empty evidence
  cell is invalid and is flagged by `/v-pm status` and by feature pickup.
- `/v-pm` writes an appetite and a first slice, never session rows → the repo's own `/v-team` session
  writes every row at propose-time `(f3)`; edge: a plan that does not fit its appetite cuts `[could]`
  then `[should]` rules rather than exceeding it.
- A feature's `header.md` status is derived from its shard rows by `/v-capture` Step 4e → all `todo`
  gives `planning`, any movement gives `in-progress`, all `done` or `dropped` gives `shipped`.
- Elicitation stops when the technique menu is exhausted and every remaining question fails the
  relevance test → whatever is still open becomes a stated default in `## Assumptions to test`; edge: a
  plan-fork with no safe default still hard-blocks.

## Next
- The question-shaping rules remain in two places: `commands/_shared/communication.md` and
  `commands/v-work/steps/03-propose.md` §3a.0a. Collapsing them needs a decision about the pinned test
  in `tests/unit/research-clarify.bats`, not a quiet edit.
- The plan carries its own success criterion with a **2026-10-15** review date: every feature's
  `header.md` status matching its shard rows, and every `done` row carrying evidence. If the mismatch
  count is still above zero then, the rollup did not work and the status field should be removed rather
  than left lying.
- Whether the three never-started features indicate over-planning or simply shifting priorities is
  unresolved; nothing measured here separates them.
- Branch `feat/vpm-pm-discipline` is committed but not pushed.

## Refs
- [[../plans/2026-09-01-0900-vpm-pm-discipline]] — the plan, with the verified counts and work items.
- [[../plans/2026-09-01-0900-vpm-pm-discipline.trail]] — reviewer findings, rejected options, and what
  was found while executing.
- [[../decisions/ADR-024-vpm-pm-discipline]] — the decision record; amends ADR-012 for `/v-pm` only.
- [[../indications/plan-appetite-not-tasks]] — the working rule this session established.
