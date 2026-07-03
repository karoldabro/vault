---
type: session
project: vault
date: 2026-07-03-1559
topic: vpm-business-knowledge-center
continues: [[2026-07-03-1240-v-pm-cross-project-planning]]
files_touched: [commands/v-pm.md, commands/v-pm/steps/01-intake.md, commands/v-pm/steps/03-plan-panel.md, commands/v-pm/steps/04-seed-workspace.md, commands/v-pm/steps/05-capture.md, commands/v-team/steps/00-feature-pickup.md, commands/v-team/steps/03-propose-loop.md, commands/v-team/steps/04-execute-loop.md, commands/v-capture.md, commands/v-work/steps/02-load-context.md, commands/v-init.md, templates/_features/requirements.md, templates/_features/generic-plan.md, templates/_features/project-shard.md, templates/_features/planning-session.md, tests/unit/v-pm.bats, vault-guide.md, vault/decisions/ADR-014-vpm-business-knowledge-center.md]
decisions: [ADR-014]
tags: [session, v-pm, requirements, business-logic, knowledge-center, testing]
---

# vpm-business-knowledge-center

## Goal
Extend `/v-pm` to author a durable business-logic / requirements "knowledge center" into the vault
(leveraging existing categories) so a feature's business logic is captured once and grounds rich tests +
AI product understanding — run via `/v-team`.

## Did
- Added [[../../templates/_features/requirements.md]] — the knowledge center: business context/goals,
  actors, user stories, **business rules** (`precondition → expected [; edge]` with `REQ-NN` ids +
  `[authz]/[error]/[nfr]` axis tags), optional decision/state tables, domain glossary, invariants.
- `03-plan-panel` emits requirements.md; **re-cut** `generic-plan.md` to *how/sequencing* (its
  `## Problem & outcome` is now a back-ref — requirements.md is the single source of "why").
- **Decoupled** the knowledge center from the coordination machinery: `01-intake` §1.3 now has a
  1-participant feature author `requirements.md` into a new **project-vault `requirements/` category**
  (no cross-repo write), skip the `_features/` workspace, then hand execution to `/v-team`/`/v-work`.
  The `_features/` workspace stays gated at 2+ repos.
- Wired the **id-traceability chain** across the consuming files: `00-feature-pickup` reads
  requirements.md; `03-propose-loop` §(c)/§f2 feeds it to the test-design fan-out + echoes `REQ-NN` into
  the backlog `source`; the `REQ-NN`→established-dossier carry lives in **shared `/v-capture` Step 5b**
  (so it closes for both `/v-work` and `/v-team`).
- `project-shard.md` gained a **v-pm-owned** `## Business rules to satisfy` section (ownership carve-out;
  `/v-team` preserves, never overwrites). `v-work/02-load-context` globs `requirements/`. Docs:
  `vault-guide.md` §2/§3/§6/§13. [[../decisions/ADR-014-vpm-business-knowledge-center]].
- Ran under `/v-team`: degraded general panel (architect · requirements · skeptic), **2 propose rounds +
  1 diff-review round**; all confirmed findings applied. 28 v-pm bats contracts pass (full suite 159/2,
  the 2 fails pre-existing + unrelated). Committed `141d00d` on `feat/vpm-business-knowledge-center`.

## Learned
- The test-grounding half was *already half-built*: the `capture-behaviors-test-shaped` convention +
  `## Behaviors & rules` existed, but only fired at `/v-capture` (post-exec, established). The gap was a
  **plan-time spec** — that's what requirements.md fills.
- Panel-confirmed (3/3) that writing stubs into *participant* vaults is a footgun (the gitignored
  workspace symlink exists precisely to avoid dirtying a sibling repo) — reach must go through the
  neutral workspace + the project's OWN `/v-team`, never a cross-repo write.
- The `REQ-NN` carry belongs in **shared `/v-capture` Step 5b**, not v-team's execute-loop — otherwise
  the `/v-work` single-repo branch silently drops the id (skep-9). Placing seams at the *consuming* file
  matters: a pre-ANALYZE pickup step is the wrong home for a capture-time write.

## Behaviors & rules
- `/v-pm` authors `requirements.md` (knowledge center) for **any** feature (1+ repos); only the
  `_features/` workspace + conversation + contracts are gated at 2+ repos.
- 1 participant → author `requirements.md` into `<project-vault>/requirements/<feature>.md`, skip the
  workspace, hand execution to `/v-team`/`/v-work`; **edge**: no longer a bare hand-off (supersedes the
  old break-even rule).
- `requirements/` = plan-time **spec** (aspirational); `features/` = **established** — `/v-capture`
  Step 5b promotes only *built* rules into the dossier, carrying each `REQ-NN` id; edge: unbuilt spec
  rules stay in requirements.md, never promoted.
- Id chain: `requirements.md (REQ-NN)` → LOAD CONTEXT → `(f2)` backlog `source` → established
  `features/` dossier Behavior — closes identically for `/v-work` and `/v-team` (shared `/v-capture` §5b).
- Shard `## Business rules to satisfy` is v-pm-seeded and single-writer-owned; `/v-team` appends coverage
  but preserves the ids; the ids stay out of `## Consumed contract` so the drift check diffs clean.

## Next
- Push branch `feat/vpm-business-knowledge-center` + open PR when ready (not pushed this session).
- Pre-existing unrelated test failures 99 (`vault-guide` says "run" not "executed") + 114 (`README`
  missing `_shared/testing`) — worth a separate cleanup pass, out of scope here.
- Optional future: a decision-table authoring helper for the `## Variant & state rules` section.

## Refs
- [[../decisions/ADR-014-vpm-business-knowledge-center]]
- [[../decisions/ADR-013-v-pm-cross-project-planning]]
- [[../features/v-pm]]
- [[../indications/capture-behaviors-test-shaped]]
- [[../indications/requirements-spec-vs-established]]
- [[../plans/2026-07-03-1510-vpm-business-knowledge-center]]
- [[2026-07-03-1240-v-pm-cross-project-planning]]
