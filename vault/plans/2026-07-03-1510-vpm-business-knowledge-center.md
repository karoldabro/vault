---
type: plan
project: vault
slug: vpm-business-knowledge-center
status: executed   # draft | proposed | approved | executed | superseded
process_record: 2026-07-03-1510-vpm-business-knowledge-center.trail.md
tags: [plan, team, v-pm, requirements, business-knowledge]
---

# vpm-business-knowledge-center — team plan

Extend `/v-pm` so its planning output includes a durable, structured **business-knowledge /
requirements layer** — a "knowledge center" — that (a) grounds rich test authoring and (b) gives AI a
deep product understanding, leveraging the vault's existing categories.

## Task
Enhance `/v-pm` to produce rich business-logic + requirements documentation into the vault, leveraging
every existing category (features, architecture, decisions, indications, sessions, MOC), as a durable
business knowledge center usable for rich test authoring + AI product understanding.
Keywords: v-pm, business-logic, requirements-docs, vault-categories, knowledge-center, test-grounding.

## Front gates
**Clarify (§3a.0a):** the one real fork (vault reach) was posed via AskUserQuestion; user away →
proceeded on defaults. `## Reach model` in this file then resolved the fork: `requirements.md` is
written into the neutral `_features/` workspace, never into a participant repo. That removes the
risky cross-repo action the default would have taken. Re-surfaced at the approval gate.
**Research (§3a.0b):** grounded in established prior art (no live search — conceptual design; repo's own
ADR-013 already cites the lineage): **BMAD-METHOD** (shard a PRD + architecture doc into self-contained
downstream context — requirements.md is the missing "PRD" half), **Spec-Kit** (spec→plan→tasks with a
cross-artifact consistency check), **Specification-by-Example / BDD** (acceptance criteria as executable
examples are the requirements→tests bridge), **DDD ubiquitous language** (a glossary is what lets humans
AND AI reason about the product). Reconciles with the repo's own `capture-behaviors-test-shaped`
indication, whose test shape requirements.md reuses verbatim.

## The core design tension (resolved)
`capture-behaviors-test-shaped` mandates business-logic docs be **"established, not aspirational"** and
governs per-project **feature dossiers** (written at `/v-capture`, post-execution). This request wants
**plan-time** business logic. **Resolution:** v-pm authors an explicit **SPEC** (legitimately
aspirational) in the **neutral `_features/` workspace only** — it does NOT write business rules into any
participant feature dossier. The project's own `/v-team`+`/v-capture` is the sole hand that writes
**established** Behaviors into that project's `features/`, carrying each rule's `id` forward. Spec lives
in one place; established form lives in the project; no cross-repo write, no aspirational clutter.

## Reach model
The user's ask ("reach into all categories of the specific vault") is met **without** v-pm dirtying a
sibling repo:
- `requirements.md` is written into `_features/<feature>/`, which is **already symlinked into every
  participant vault** (`<proj>/features/<feature>` → workspace) — so the knowledge center is visible in
  each project's feature index and recallable **the moment planning finishes**, zero cross-repo write.
- The per-project `projects/<proj>/plan.md` **shard** (neutral workspace, committed there) carries the
  project-relevant rule ids the project must satisfy.
- When `/v-team <feature>` runs in a project, **it** writes the established per-category docs
  (`features/`, `architecture/`, ADRs) into that project's own vault, at capture, id-carried. v-pm never
  reaches across the repo boundary. This is BMAD sharding + ownership-respecting.

## Plan
_Dependency-ordered. File · Action · Pattern._

1. **`templates/_features/requirements.md`** · CREATE · The project-agnostic business knowledge center.
   Sections (❖ = optional, omit-when-none per `capture-behaviors-test-shaped`):
   - `## Business context & goals` — the why · user need · success metric. **SINGLE source of the "why"**
     (generic-plan back-references this).
   - `## Actors` — who uses it.
   - `## User stories` — `As a <role>, I want <capability>, so that <benefit>`; each story lists the
     `## Business rules` **ids** that constitute its acceptance (no separate Given/When/Then shape —
     unify on the framework's one canonical test shape).
   - `## Business rules` — **canonical** test-shaped `precondition → expected [; edge]` (reuse
     `capture-behaviors-test-shaped` verbatim). Each rule has a **stable `id`** (`REQ-NN`) and an axis
     tag where relevant (`[authz]` · `[error]` · `[nfr]`). **This is the single source** for
     rules/acceptance; contracts.md + project dossiers reference by `id`, never copy. **[R2/req-7]**
     Include one template example rule that encodes an explicit action-trigger (`; edge: when X then Y`)
     so authors preserve the BDD "When" for interaction/event-driven acceptance where it matters.
   - `## Variant & state rules` ❖ — decision table (conditions × values → required rule) and/or
     state-transition table `((state,event) → (next,action))`. The direct seam to
     `personas/_shared/testing/design/business-logic-cartographer` (which consumes exactly these).
   - `## Domain glossary` — term → definition (ubiquitous language; grounds AI understanding).
   - `## Invariants & edge cases` ❖ — what must always/never hold.
   - `## Open questions` ❖ — feed `conversation/` threads.
   - Header note: "Project-agnostic SPEC. Only `/v-pm` writes it. Specs are aspirational by design;
     per-project feature dossiers hold the *established* form (validated at `/v-capture`, id-carried)."

2. **`commands/v-pm/steps/03-plan-panel.md`** · UPDATE · The existing business→product→architect→contract
   pipeline already *generates* this material but discards it to prose. Add a generative output: emit the
   structured `requirements.md` (product-owner → user stories + business rules; business-advisor →
   context/goals/glossary; architect → invariants + variant/state rules). NOT a new critic — a new
   **output**. **Re-cut generic-plan** here: its `## Problem & outcome` shrinks to a one-line
   back-reference to `requirements.md`; generic-plan owns solution-shape + sequencing. State the triad:
   generic-plan = *how/sequencing* · contracts = *interface seam* · requirements = *what & why*.
   **[R2/arch-8]** Also rewrite §(a) line-12 prose: drop "the problem, the user-facing outcome" and point
   it at requirements.md, so the panel instruction doesn't re-inflate what the template just shed.

3. **`templates/_features/generic-plan.md`** · UPDATE · Shrink `## Problem & outcome` to a back-reference
   to `requirements.md` (single source of why); keep solution-shape + sequencing + research.

3b. **`templates/_features/project-shard.md`** · UPDATE **[R2/arch-7,skep-8]** · Add a dedicated
   `## Business rules to satisfy (from requirements.md — REQ-NN id refs)` section that **v-pm owns/seeds**.
   Amend the template's line-11 ownership note ("Written by this project's /v-team … not /v-pm") to
   **carve out** this one section as v-pm-seeded; state `/v-team` **appends established evidence and
   preserves the ids (merge, not overwrite)**. Keep ids OUT of `## Consumed contract` so the deterministic
   drift check (00-feature-pickup §0.5) still diffs cleanly. This is the durable, single-writer-clean home
   for the "which rules this project must satisfy" list.

4. **`commands/v-pm/steps/04-seed-workspace.md`** · UPDATE · (a) Scaffold `requirements.md` from template
   into `_features/<feature>/` (add to the layout block). (b) **[R2]** Seed the project-relevant
   business-rule **ids** into the shard's new `## Business rules to satisfy` section (step 3b) — the
   v-pm-owned section, **not** the /v-team-authored body. **No participant-vault write, no
   `_feature-index.md` append** (Round-1 finding — reach is the existing symlink). Update Required output.

5. **`commands/v-pm/steps/05-capture.md`** · UPDATE · Reference requirements.md as the knowledge center
   in the planning-session record; push its **glossary + business rules + `## Variant & state rules`
   tables** into the record **[R2/req-6: include the variant/state tables — the cartographer's
   primary input, not just glossary+rules]** so each project's `/v-team` LOAD CONTEXT recalls the product
   knowledge even via the fallback recall path.

6. **id-traceability seam — split across THREE files by lifecycle moment [R2/arch-9,req-6]** (the whole
   "grounds rich tests end-to-end" claim rides on placing it where it actually fires):
   - **`commands/v-team/steps/00-feature-pickup.md`** §0.2 · add `requirements.md` (via the symlink) to
     the **read list** so it enters session context. (Reads only — no capture-time id-writing here.)
   - **`commands/v-team/steps/03-propose-loop.md`** §(c)/§(f2)-item1 · name `requirements.md` (esp.
     `## Variant & state rules` + `## Business rules`) as an **explicit input in the LOAD-CONTEXT digest**
     handed to the f2 generators/`business-logic-cartographer`; the backlog `source` column echoes the
     originating `REQ-NN`. This is the file that actually feeds the cartographer.
   - **`commands/v-capture.md`** Step 4d · the single canonical carry, shared by `/v-team` and `/v-work`.
     When the project's `features/<feature>` dossier `## Behaviors & rules` is written, each bullet carries
     its `REQ-NN` id inline and records only **established** (built) rules. Closes id(spec) → id(dossier) →
     backlog-row at the moment the dossier is actually authored.
     `commands/v-team/steps/04-execute-loop.md` §5.4a defers here and must not carry the id itself.

7. **`vault-guide.md`** · UPDATE · §13: add requirements.md to the workspace layout + a "business
   knowledge center" subsection (spec→shard→established lifecycle + the id-traceability seam + the reach
   model). §6 decision tree: one line placing requirements.md (plan-time spec, neutral workspace) vs
   features (established, project vault).

8. **`vault/decisions/ADR-014-*.md`** · CREATE · Record: v-pm authors a project-agnostic
   requirements/business-knowledge layer in the neutral workspace; the aspirational-vs-established
   resolution (spec-in-workspace, established-via-/v-team, no cross-repo write); the canonical test shape
   + id-traceability seam; the decision-table/glossary grounding.

9. **`commands/v-pm.md`** + **`templates/_features/planning-session.md`** · UPDATE (small) · Dispatcher
   Notes list requirements.md as a first-class workspace artifact; planning-session `Refs` adds it.

## Test plan
bats file-contract style (matches `tests/unit/v-pm.bats` — grep assertions on doc contracts; agent-loop
behavior validated by dry-run). Dockerized run. (Populated authoritatively by the (f2) fan-out below.)

## Test Design Dossier
**(f2) generative fan-out — SKIPPED, with note (per §f2 skip clause).** This diff is pure
framework-markdown + bats **file-contract** tests: no endpoints/handlers/migrations/runtime business
logic. The design generators (`fault-relation-prospector`, `business-logic-cartographer`,
`boundary-property-explorer`) target runtime decision-tables / metamorphic relations / BVA — they have
nothing to bite on in doc-contract grep tests. So the backlog below is consolidated directly from the
panel's `PROPOSED_TESTS` (the appropriate test set for a doc/contract change), deduped across critics.
Every backlog row is a bats `grep`-contract assertion on the doc surface, run in the Docker harness.

## Proposed test backlog

| id | source | kind | target | intent | priority |
|----|--------|------|--------|--------|----------|
| T1 | arch-t1,skep-t1 | unit | 04-seed-workspace | states NO participant-vault write + NO `_feature-index.md` append; reach = existing symlink | must |
| T2 | arch-t4,skep-t4/8 | unit | project-shard.md + 04-seed | shard has dedicated **v-pm-seeded** `## Business rules to satisfy` section; ownership note carves v-pm out for it; `/v-team` preserves ids (merge-not-overwrite); ids NOT in `## Consumed contract` | must |
| T3 | arch-t5,req-t4 | unit | 00-feature-pickup + 03-propose-loop + 04-execute-loop | seam split correct: pickup only READS requirements.md; 03-propose-loop names it in the f2 digest + backlog `source` echoes `REQ-NN`; capture writes id into established dossier Behaviors | must |
| T4 | req-t1,req-t2 | unit | requirements.md template | exists + required sections (context/goals, actors, user stories, business rules `precondition → expected` **with `REQ-NN` ids**, variant & state rules, glossary, invariants); `_features` templates count → **seven** | must |
| T5 | arch-t6,req-t3 | unit | generic-plan.md + 03-plan-panel | single-source-of-why: requirements owns why; generic-plan `## Problem & outcome` back-refs; 03-plan-panel §(a) prose no longer claims generic-plan owns problem/outcome | should |
| T6 | req-t2 | unit | requirements.md template | ONE canonical test shape — no Given/When/Then vs `precondition → expected` duplication | should |
| T7 | skep-t2 | unit | requirements.md + feature dossier | established-only guard: spec rules live in requirements.md; project dossier `## Behaviors & rules` not pre-filled with unvalidated rules | should |
| T8 | (synth) | unit | 05-capture | references requirements.md + the record includes glossary + business rules + variant/state tables | should |
| T9 | (synth) | unit | vault-guide | §13 documents requirements.md + knowledge-center lifecycle + id seam; §6 places requirements(spec) vs features(established) | should |
| T10 | (synth) | unit | ADR-014 | ADR-014 file exists + `decisions/_inventory.md` row | should |

## Approval + post-approval scope change (user-directed)
Approved to execute through capture. User resolved both escalations:
1. **Reach** — confirmed. "Each writes their own; the pm just saves the business logic so the user
   doesn't repeat themselves and data is richer." The neutral-workspace redesign stands.
2. **Single-repo is NOT deferred — it's first-class.** "Single vault repos exist and are strong
   (e.g. `~/vault/givore`), in fact more convenient than split." → **Decouple the knowledge center from
   the coordination machinery.** v-pm authors `requirements.md` for **any** feature (1+ repos); the
   `_features/` workspace + conversation + contracts + shards remain gated at **2+ repos**.

### Single-repo extension (folds into the edit list — steps S1–S7)
- **S1 · `commands/v-pm/steps/01-intake.md` §1.3** — reshape the break-even gate. 1 participant no longer
  bare-hands-off. Instead: run the plan panel + author `requirements.md` into the **project's OWN vault**
  at `<proj-vault>/requirements/<feature>.md`, **skip** the coordination machinery (no `_features/`
  workspace, `conversation/`, `contracts.md`, symlinks, shards), run CAPTURE against the project vault
  (commit there), then hand execution to `/v-team`/`/v-work`. 2+ participants → unchanged.
- **S2 · new project-vault category `requirements/`** — the spec-stage home (aspirational-by-design),
  kept distinct from `features/` (established) — mirrors how the neutral workspace keeps requirements.md
  separate from the eventual dossier. Add to `vault-guide.md` §2 folder map (optional) + `v-init` scaffold
  (+ `requirements/_index.md`). Committed project knowledge (not gitignored).
- **S3 · LOAD CONTEXT reads `requirements/`** — add `requirements` to `v-work/steps/02-load-context.md`
  §2.3b glob + the `03-propose-loop.md` f2 digest, so single-repo requirements.md grounds tests + AI
  understanding the same way the multi-repo one does (multi-repo reaches it via the workspace symlink).
- **S4 · `templates/_features/requirements.md`** — the header note becomes mode-aware ("project-agnostic
  in `_features/`; single-project when in `<proj>/requirements/`"); body identical. One shared template.
- **S5 · `commands/v-pm.md`** — rewrite "When to use" + Modes: v-pm authors the requirements knowledge
  center for **1+ repos**; the coordination workspace is the **2+-repo delta**. (Clean rename of the
  identity, no stub.)
- **S6 · ADR-014** — record the decoupling (knowledge center 1+ repos; coordination 2+).
- **S7 · tests** — single-repo path: intake authors requirements.md for 1 participant with NO workspace;
  `requirements/` category documented + scaffolded; load-context reads it.
- **Principle check:** stays inside the panel's established rules — spec/established separation
  (`requirements/` = spec, `features/` = established, /v-team validates at capture, id-carried); v-pm
  writes only into a vault it plans for (the project's own, single-repo = no cross-repo footgun).

## Mode-branch guards
Every line below is a point where single-repo and multi-repo diverge. Each names the failure that
follows from missing the branch.

- **`commands/v-capture.md` Step 4d** — the `REQ-NN` → dossier carry is defined here once, shared by
  `/v-team` and `/v-work`. Define it in `commands/v-team/steps/04-execute-loop.md` instead and the
  single-repo `/v-work` chain never closes.
- **`commands/v-pm/steps/01-intake.md` §1.4** — the slug-collision check must branch by mode. Multi-repo
  checks `_features/<feature>/`; single-repo checks `<project-vault>/requirements/<feature>.md`. Checking
  `_features/` alone lets a single-repo run overwrite an existing spec.
- **`commands/v-pm/steps/01-intake.md` §1.3.4** — points at `/v-capture` Step 4d rather than restating the
  carry, so the two cannot drift apart.
- **`requirements/_index.md`** — needs a `vault-guide.md` §3 maintenance row and a `_moc` trigger. Without
  them the index rots as specs accumulate.
- **`commands/v-pm/steps/05-capture.md`** — the Required-output block must branch for single-repo.
  Unbranched, it reports a `_features/` commit that single-repo mode never made.
- **`vault-guide.md` §6** — the decision tree lists four categories, not three.

## Open trade-offs / deferrals
- **Section modesty** — every ❖ section is omit-when-none so a light feature stays light (skep-6).
- **`requirements/` is optional/on-demand** — v-init scaffolds it for new vaults; existing vaults get it
  created on first single-repo `/v-pm` run with a one-line note (no forced migration).

## Test triage / result
(f2) fan-out skipped (docs/contract diff) — backlog realised as bats file-contracts. **28 v-pm tests
pass; full suite 159 pass / 2 fail.** The 2 failures (99, 114) are **pre-existing + unrelated** — they
assert strings in `vault-guide` §1.1 hooks / `README.md` testing-group that this diff never touches
(`vault-guide` says "never *run* as a shell command"; the test greps for "*executed*"). Not introduced
here; left out of scope (clean-scope discipline).

## Refs
- Process record: `vault/plans/2026-07-03-1510-vpm-business-knowledge-center.trail.md`
- [[../decisions/ADR-013-v-pm-cross-project-planning]]
- [[../indications/capture-behaviors-test-shaped]]
- [[../indications/cross-project-conversation-workspace]]
