# Step 2 — PLAN PANEL (plan mode)

Turn the necessity into a **project-agnostic** plan through a sequential critic pipeline, then split the
cross-project contract out as a first-class artifact. This is generative planning, not code — do not
read or write source here.

**Single-repo mode (1 participant, per `01-intake.md` §1.3):** emit **only `requirements.md`** — the
knowledge center is the whole deliverable. **Skip `contracts.md`** (no cross-project seam) and **skip
`generic-plan.md`** (single-repo execution planning is `/v-team`'s job). The sequential pipeline still
runs to sharpen requirements.md; the contract critic simply has no seam to split. Everything below about
`contracts.md`/`generic-plan.md` applies to **multi-repo** mode.

**Front gate (inherited).** Run `v-work/steps/03-propose.md` **§3a.0b external research** (soft — the AI
decides, or `--research` / `--no-research`) to ground the approach in how this class of problem is solved
in the wild, before drafting. Cite sources in the plan.

## (a) Draft the requirements knowledge center + the generic plan v0
Author **two** artifacts, grounded in the **Step 2 LOAD CONTEXT digest** (reuse existing contracts /
decisions / overlapping feature dossiers instead of reinventing). Follow BMAD: capture enough that each
project can act without re-deriving the whole thing.

1. **`requirements.md`** (`templates/_features/requirements.md`) — the **business knowledge center**: the
   *why* + user need (Business context & goals — the single source of "why"), actors, user stories,
   **business rules** as canonical test-shaped `precondition → expected [; edge]` bullets each with a
   stable `REQ-NN` id + axis tag (`[authz]/[error]/[nfr]`) where relevant, optional variant/state tables
   (decision + state-transition — the seam the test-design fan-out consumes), a domain glossary, and
   invariants. This is what grounds rich tests + lets AI understand the product. Don't manufacture rules —
   only what the necessity actually implies; omit ❖ sections when empty.
2. **`generic-plan.md`** — the *how*: **solution shape** across the products + **sequencing** (which
   project moves first — usually the api) + scope/non-goals. Its `## Problem & outcome` is a **one-line
   back-reference** to `requirements.md`, NOT a restatement (requirements owns the why). generic-plan =
   *how/sequencing* · contracts = *interface seam* · requirements = *what & why* — three non-overlapping
   artifacts.

## (b) The pipeline — sequential, each stage consumes the last
Unlike `/v-team`'s **parallel** design panel, planning is a **linear pipeline**: each critic refines the
artifact the previous one produced. Reuse only the **finding schema** and the **de-biased synthesize**
sub-steps from `v-team/steps/03-propose-loop.md` §(d)/§(e) — **not** `_shared/critic-panel.md` (that
module reviews a code diff and has nothing to ground on here).

Run in order (spawn each as an `Agent`; read-only; feed it the current draft + all prior stages'
findings + the **LOAD CONTEXT digest** from Step 2, so each critic reasons from real project knowledge,
not blind):
1. **business / market advisor** — is this worth doing? ROI, the cheaper path, what's unsaid, the real
   user need behind the ask.
2. **product owner** — scope, acceptance criteria, what's in / out of the first cut, sequencing.
3. **architect / tech lead** — system design, data model, boundaries, feasibility, cross-project impact.
4. **contract / integration critic** — the api↔frontend seam: endpoints, enums, data shapes, the exact
   fields each side needs. This is where the user's pain lives — be concrete.

Each returns findings in the `03-propose-loop.md` §(d) schema (severity · grounding · target ·
recommendation). After each stage, **synthesize** (de-bias per §(e)) and revise the draft.

**Who fills `requirements.md`:** business/market advisor → Business context & goals + glossary seed;
product owner → user stories + business rules (`REQ-NN`) + acceptance; architect → invariants + variant/
state tables. The contract critic still owns `contracts.md` (the interface seam), which references
requirements rules by `REQ-NN` id rather than restating them.

## (c) Rounds + convergence
Cap at `pm_max_rounds` (default 2) — a full pipeline pass adding no new confirmed BLOCKER/MAJOR
converges. A cap hit with open blockers is surfaced to the user. Same discipline as `/v-team` §(f):
never stop on unanimous approval alone.

## (d) Split the contract out
Extract the cross-project interface into a **structured** `contracts.md` — endpoints, request/response
shapes, enums, events — with each field marked. Keep it parseable: the per-project `/v-team` pickup does
a **deterministic diff** against it to catch drift, so structure it as data (tables / typed blocks), not
prose. The generic plan references it; the contract is the single source of truth for the seam.

## Required output
```
Research: [sources + takeaways | skipped (trivial) | unavailable]
Rounds: <n> · Convergence: <clean | capped-with-open-blockers>
requirements.md: [business rules REQ-NN · glossary terms · variant/state tables · invariants]
generic-plan.md: [drafted — solution shape + sequencing; why → requirements.md]
contracts.md: [endpoints / enums / shapes captured — refs requirements by REQ-NN]
```
Mark PLAN PANEL `completed` → Step 3.
