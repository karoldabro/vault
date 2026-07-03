# Step 2 — PLAN PANEL (plan mode)

Turn the necessity into a **project-agnostic** plan through a sequential critic pipeline, then split the
cross-project contract out as a first-class artifact. This is generative planning, not code — do not
read or write source here.

**Front gate (inherited).** Run `v-work/steps/03-propose.md` **§3a.0b external research** (soft — the AI
decides, or `--research` / `--no-research`) to ground the approach in how this class of problem is solved
in the wild, before drafting. Cite sources in the plan.

## (a) Draft the generic plan v0
Write a project-agnostic plan: the problem, the user-facing outcome, scope + non-goals, the shape of the
solution across the products, and the sequencing (which project moves first — usually the api). Ground it
in the **Step 2 LOAD CONTEXT digest** — reuse existing contracts / decisions / overlapping feature
dossiers instead of reinventing the seam. Follow the BMAD principle: capture enough context that each
project can act without re-deriving the whole thing.

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
generic-plan.md: [drafted — sections]
contracts.md: [endpoints / enums / shapes captured]
```
Mark PLAN PANEL `completed` → Step 3.
