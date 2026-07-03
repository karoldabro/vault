---
type: decision
project: vault
id: ADR-014
status: accepted
scope: repo
tags: [adr, v-pm, requirements, business-logic, knowledge-center, testing]
---

# ADR-014 — /v-pm authors a business-knowledge / requirements layer (spec), decoupled from the coordination machinery

## Context
`/v-pm` planned a feature into a `generic-plan.md` (how) + a structured `contracts.md` (the seam), then
seeded per-project shards ([[ADR-013-v-pm-cross-project-planning]]). But the **business logic** — what the
product must do and *why*, the rules a test asserts, the ubiquitous language — evaporated into plan prose.
The user has to re-explain it every session, and neither rich tests nor AI product understanding have a
durable source. The framework already had the right *shape* for this — the `capture-behaviors-test-shaped`
indication captures business logic as test-shaped `precondition → expected [; edge]` — but only at
`/v-capture`, post-execution, per-project, "established not aspirational". Nothing captured the **spec** at
plan time. Prior art converges: BMAD (shard a PRD + architecture doc), Spec-Kit (spec→plan→tasks with a
consistency check), Specification-by-Example / BDD (acceptance criteria as the executable requirements→test
bridge), DDD (a glossary as ubiquitous language).

## Decision
Add a **business knowledge center** — a project-agnostic **`requirements.md`** authored by `/v-pm`:
business context/goals (the single source of "why"), actors, user stories, **business rules** as canonical
test-shaped `precondition → expected [; edge]` each with a stable **`REQ-NN`** id + axis tag
(`[authz]/[error]/[nfr]`), optional decision/state tables, a domain glossary, and invariants. It is an
explicit **SPEC** (aspirational by design), kept distinct from the *established* `features/` dossier.

- **Reach without a cross-repo write.** `/v-pm` never writes into a *participant* vault it doesn't own.
  For 2+ repos, `requirements.md` lives in the neutral `_features/<feature>/` (already symlinked into each
  project → visible + OV-recallable immediately); each project's own `/v-team` writes the established
  per-category docs at capture. The rejected alternative — seeding `status: stub` dossiers into sibling
  repos — reintroduced the footgun the gitignored workspace symlink exists to avoid (panel-confirmed 3/3).
- **Decoupled from the coordination machinery.** The knowledge center is worth authoring for **any**
  feature (1+ repos); only the `_features/` workspace + `conversation/` + `contracts.md` seam need 2+
  repos. So the break-even gate splits on *that* boundary: a **single-repo** feature still authors
  `requirements.md` — into the project's OWN vault at `<project-vault>/requirements/<feature>.md` (a new
  spec-stage category) — then hands execution to `/v-team`/`/v-work`. It no longer hands off empty-handed.
- **Id-traceability chain** (what makes it *ground* tests, not just describe them): `requirements.md`
  `REQ-NN` → `/v-team` reads it into LOAD CONTEXT (`00-feature-pickup` §0.2 / `02-load-context`
  `requirements/` glob) → the `(f2)` test-design fan-out echoes `REQ-NN` into the backlog `source` → at
  capture the **established** `features/<feature>` dossier `## Behaviors & rules` carries the same `REQ-NN`.
  The seam is wired at each consuming file (not folded into the pre-ANALYZE pickup step — a panel finding).
- **Single test shape.** Unify on the framework's existing `precondition → expected [; edge]`; user-story
  acceptance references rule ids rather than introducing a parallel Given/When/Then form.
- **Single-writer discipline in the shard.** The `REQ-NN` ids a project must satisfy live in a dedicated
  **v-pm-owned** `## Business rules to satisfy` section of `project-shard.md` (ownership carve-out;
  `/v-team` appends coverage, never overwrites), kept out of `## Consumed contract` so the deterministic
  drift check still diffs cleanly.

## Consequences
- **Easier**: the necessity is captured once, richly; tests and AI ground in a durable business-logic
  source; single-repo vaults (the common, convenient case) get the knowledge center too.
- **Watch for**: `requirements/` spec drifting from what shipped — mitigated by the promote-only-built
  rule + the id chain (a dossier `REQ-NN` with no coverage is visible). Two-artifact overhead — mitigated
  by omit-when-none on every optional section and single-sourcing rules by id (never copied).
- **Panel**: degraded general panel (architect · requirements/domain-modeling · skeptic), 2 rounds. All
  confirmed findings applied. The single-repo extension was added post-cap per user direction, following
  the panel's established spec/established + ownership principles.

## Cross-repo impact
Framework-only (the command + templates + the new `requirements/` project-vault category ship in the
vault repo). At runtime `requirements.md` is committed with its workspace (`_features/`, 2+ repos) or the
project vault (single repo); `/v-sync` ingests both. Depends on [[ADR-013-v-pm-cross-project-planning]]
(the workspace) and [[ADR-011-generative-test-design-subphase]] (the `(f2)` consumer of the id chain).
