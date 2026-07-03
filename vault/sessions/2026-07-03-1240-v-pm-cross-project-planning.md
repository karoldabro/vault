---
type: session
project: vault
date: 2026-07-03
topic: v-pm-cross-project-planning
continues: [[2026-07-03-1205-propose-clarify-research-gates]]
files_touched:
  - commands/v-pm.md
  - commands/v-pm/steps/01-intake.md
  - commands/v-pm/steps/02-plan-panel.md
  - commands/v-pm/steps/03-seed-workspace.md
  - commands/v-pm/steps/04-reconcile.md
  - commands/v-pm/steps/05-status.md
  - commands/v-team/steps/00-feature-pickup.md
  - commands/v-team.md
  - commands/v-work/steps/03-propose.md
  - templates/_features/
  - templates/vault.gitignore
  - vault-guide.md
  - README.md
  - commands/README.md
  - tests/unit/v-pm.bats
  - tests/unit/research-clarify.bats
  - vault/plans/2026-07-03-1230-v-pm-cross-project-planning.md
decisions: [ADR-013]
tags: [session, v-pm, cross-project, planning, coordination, blackboard, clarify-gate]
---

# v-pm-cross-project-planning

## Goal
Design + build `/v-pm` — a cross-project feature-planning command that drafts a project-agnostic plan
into a shared `_features/` workspace so per-project `/v-team` sessions coordinate through files instead
of the human relaying context between agent sessions.

## Did
- **Understood the problem** (human-as-message-bus across api↔frontend sessions) and **researched prior
  art** online: BMAD-METHOD (planning agents + self-contained "shards"), GitHub Spec-Kit (spec→plan→tasks
  + `/analyze` consistency check + constitution), blackboard architecture + file-based A2A (shared
  workspace, state-in-filename, control shell). Concluded v-pm = assembly of these, not a novel invention.
- **Locked design decisions** with the user: planner-first v-pm + thin `reconcile`; auto-pickup routing;
  `~/vault/_features/<feature>/` (own committed vault); 4 planning critics (business·product·architect·
  contract); v-team-style dispatcher/steps/rounds; soft AI-decided research + `--research` flag.
- **Flipped the clarify gate to always-wait** (`3124a7d`): the just-shipped `§3a.0a` proceeded on a
  "default" for a no-safe-default fork when the user was away — a contradiction. Now a plan-changing
  question with no safe default **hard-blocks** until answered; safe-default assumptions still pass and
  surface at the approval gate. Updated `research-clarify.bats` #53.
- **Ran /v-team on the v-pm plan**: wrote the plan artifact, spawned an architect·skeptic·dx panel
  (fallback-shared — no pack resolves for this markdown repo). All three returned REQUEST_CHANGES; 18
  findings → 11 clusters, all confirmed findings applied. Biggest catch: pull-only auto-pickup would
  orphan threads and leave the human in the loop → added `/v-pm status` (push surface).
- **Built v-pm** (`c04e85f`): dispatcher (plan·reconcile·status) + 5 steps; `_features` templates
  (header, generic-plan, structured contracts, BMAD project-shard, THREAD); v-team `00-feature-pickup.md`
  pre-step (auto-pickup + deterministic contracts-drift); vault-guide §13; README one-liners; gitignore.
  15 file-contract tests, all green (146 ok / 2 pre-existing unrelated failures #99 #114).

## Learned
- **The clarify gate's old "proceed on defaults if away" was internally inconsistent** — it fired only
  when there was *no* safe default, then fell back to one anyway. Hard-block is the coherent resolution.
- **`_shared/critic-panel.md` is diff-review machinery** (inputs = diff/changed-files/analyzers, grounding
  gate = SAST/fingerprint suppression). It cannot ground a no-diff *planning* panel — the planning
  pipeline must borrow only the finding-schema + synthesize from `v-team/steps/03-propose-loop.md`.
- **`v-team` has no own `02-load-context.md`** — it reuses `/v-work`'s verbatim; so cross-project pickup
  had to be a new `v-team/steps/00-feature-pickup.md`, not an edit to load-context (which would leak into
  `/v-work`).
- **`install.sh` is glob-based** (`commands/*.md` + `commands/*/`), so v-pm auto-installs with no
  installer edit; the test asserts the symlink appears after a run.
- **Shared working tree across parallel sessions**: the parallel session that shipped the front gates
  committed direct-to-`main` with explicit staging (no branch switch, which would yank HEAD from another
  session). Followed that convention here instead of branching.
- `docs-readme-landing-page.md` has a stray `</content>` artifact on its last line (its own line-31 guard
  warns about exactly this) — noted, not yet fixed.

## Behaviors & rules
- Clarify gate: a plan-changing question with **no safe default** → **hard-block** (always wait); never
  fall back to a guess; edge: a doubt *with* a safe default is stated and passes without blocking.
- `/v-pm` with **1 resolved participant** → hand off to `/v-team`, seed no workspace (break-even gate).
- The feature ledger is a **derived view** from thread filenames on read → no file is written, so parallel
  sessions never race; edge: `/v-pm status` and `reconcile` compute it, nothing persists it.
- Thread state lives in the **filename** (`OPEN_→<proj>` / `ANSWERED_<answerer>` / `RESOLVED`), not file
  body; a thread `→pm` is drained only by `/v-pm reconcile`.
- `/v-team <feature>` Step 0 contracts-drift check is **deterministic** (field-by-field vs structured
  `contracts.md`); the LLM phrases rationale only, never decides whether drift exists.
- A given `<feature>` slug that matches no workspace → **warn loudly**, proceed as a plain `/v-team` run
  (never silently find nothing).

## Next
- **Behavioral dry-run**: exercise v-pm on a real 2-repo feature (the file-contract tests prove structure,
  not agent-loop behavior).
- Deferred (in the plan): broad LLM consistency-pass; Spec-Kit per-group `constitution`; feature archival
  → `_features/_done/`.
- Fix the two pre-existing failing tests (#99 vault-guide hooks, #114 README testing-group).
- Fix the stray `</content>` in `indications/docs-readme-landing-page.md`.

## Refs
- [[../decisions/ADR-013-v-pm-cross-project-planning]]
- [[../decisions/ADR-012-propose-clarify-research-gates]]
- [[../features/v-pm]]
- [[../features/v-team]]
- [[cross-project-conversation-workspace]]
- [[propose-front-gates]]
- [[../plans/2026-07-03-1230-v-pm-cross-project-planning]]
- [[2026-07-03-1205-propose-clarify-research-gates]]
