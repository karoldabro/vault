---
type: plan
project: vault
slug: split-test-planning-step
status: proposed
personas: [degraded-no-pack, process-architect, skeptic, test-behaviorist, edge-case-hunter]
rounds: 2
convergence: capped-then-applied (round-2 surfaced 2 confirmed-MAJOR structural fixes; all applied in v1.1; fixes re-aligned the design to its own pre-impl/post-impl axis)
tags: [plan, team, testing, lifecycle]
---

# split-test-planning-step — team plan

Make test design a **first-class generative sub-phase of PROPOSE** (generation only), confirm the
generated dossier **in EXECUTE** (where real tests + analyzers exist), and extend the **EXECUTE** testing
critic panel with a **system-domain-expert** seat grounded in the repo's own business rules.
Framework-only change to the vault repo. Scope decision: **v-team only** (v-work gets vocabulary only).

## Task
Split planning and test-planning so the test plan is authored by a dedicated generative fan-out (same
coordinator pattern as the design planner). Fix three documented LLM test-design failures: happy-path
bias (fault-hypothesis + metamorphic generation), skipped business logic (decision-table /
state-transition decomposition of type/variant rules), and a stack-generic panel blind to the system's
own rules (system-domain-expert seat).
Keywords: test-planning, adversarial-testing, business-logic-branches, persona-panel, sub-agent-fanout, lifecycle-step

## Converged plan (v1.1 — after round 2)

> **Two governing principles (both from the critic loop):**
> 1. **Architecture (round 1, arch-4):** test design is a **sub-phase of PROPOSE**, not a 7th step — no
>    renumber, no new hook phases, no fractional file numbering.
> 2. **Generate→confirm seam (round 2, arch-r2-1/2):** generators **emit pre-impl in PROPOSE (f2)**;
>    confirmation of the dossier happens **post-impl in EXECUTE §5.3** — never inside the PROPOSE panel.
>    This is the same "generators emit / critics own the post-impl VOTE" axis, made temporally executable.

### A. Test-design fan-out as a PROPOSE sub-phase (generation only) — v-team
- **File (edit):** `commands/v-team/steps/03-propose-loop.md` (single physical file — `~/.claude/commands/
  v-team` is a symlink to the workspace source; one edit). · **Action:** insert section **(f2)
  Test-design fan-out** between (f) convergence and (g) finalise. It spawns the generators (§B), merges
  their dossiers (with a **cross-generator dedup rule** — collapse same-branch error/partition intents to
  one row, edge-r2-2), writes the **Test Design Dossier** into the plan artifact, and is the **sole
  authoritative writer** of the Proposed test backlog. **(f2) only GENERATES — it performs no
  confirmation** (arch-r2-1). · **Pattern:** reuse only the parallel-`Agent`-spawn-and-merge skeleton of
  (c)+(e); omit the grounding-gate/de-bias convergence prose (reference, don't copy — arch-5).
- **File (edit):** same file §(e) item 5 · **Action:** demote design-critic `PROPOSED_TESTS` to
  **advisory test hints**, written to an **"Advisory test hints" subsection** of the plan artifact that
  (f2) reads and reconciles (named sink — arch-r2-4). The §(d) finding schema is unchanged (still
  emitted); only its consumption changes. Removes dual ownership (arch-1, skeptic-4).
- **Gating — fail open (skeptic-r2-3):** (f2) is **default-ON** for any diff touching
  endpoints/handlers/migrations/business logic. It skips **only** pure refactor/docs/formatting diffs,
  with an auditable one-line note surfaced at the approval gate. (Rationale: the bias (f2) exists to
  counter must not gate its own activation.)
- **No dispatcher renumber.** `v-team.md` keeps 6 steps; PROPOSE documents the new sub-phase. Update
  `v-team.md` cost envelope to "+ up to `team_max_test_designers` generators in PROPOSE" (arch-r2-4).

### B. Generative test-design group — `personas/_shared/testing/design/`
A new sub-group of **generators**, decorrelated from the six **critics** by a hard **vertical** axis
*and* a **horizontal** axis (both stated in §E README):
- **Vertical (generator↔critic):** generators ground in the DESIGN PLAN, emit candidate cases
  pre-impl, bind NO analyzer, and NEVER seat on the critique panel; critics ground in WRITTEN TESTS +
  their bound analyzer and own the post-impl VOTE. Each generator carries a `NOT → <mirror critic>` line.
- **Horizontal (generator↔generator, behaviorist-r2-2):** each generator also carries a
  `NOT → <other generator>` line so EP/error intents don't double-emit.
Capped by v-team-scoped `team_max_test_designers` (default 3).

1. **`fault-relation-prospector.md`** — **fault-hypothesis + metamorphic relations only**. For each
   happy-path scenario, name the fault that would break it and the metamorphic relation it should
   preserve; emit negative/error *case intent*. **No "mutation-guided" label** (mutation mutates code =
   assertion-auditor's gold lane; mutant-killing defers to EXECUTE §5.2 — edge-1, behaviorist-3). Each MR
   names the invariant it preserves. **MRs stay `advisory` until confirmed in EXECUTE** (§5.3) — not in
   PROPOSE (arch-r2-1, behaviorist-5). `NOT → edge-case-hunter` (post-impl coverage); `NOT →
   boundary-property-explorer` (single-axis boundaries).
2. **`business-logic-cartographer.md`** — decision-table / cause-effect graphing / state-transition +
   **characterization tests** (Feathers, for changes to existing untested logic — behaviorist-4).
   Decomposes variant/type-dependent rules (e.g. `post.type` → conditionally required params, distinct
   logic) into a **decision table**; every row maps to a code branch. **Spec-stable** (derives from
   `indications/`+`features/`, survives the diff — skeptic-3). `NOT → edge-case-hunter` single-axis
   EP/BVA (this owns multi-condition combinations); `NOT → boundary-property-explorer`. Characterization
   tests carry a **carve-out from assertion-auditor's snapshot-overuse rule pending refactor**, and must
   be upgraded to a semantic assertion once behavior is understood (behaviorist-r2-3).
3. **`boundary-property-explorer.md`** — BVA / equivalence partitioning / property-based invariants;
   generative emission only. `NOT → edge-case-hunter` (post-impl boundary VOTE); `NOT →
   business-logic-cartographer` (multi-condition rows).
- **File (new):** `personas/_shared/testing/design/README.md` — generators-vs-critics contract, both
  decorrelation axes, dossier schema, **dossier→backlog traceability** (≥1 row per artifact), and the
  **confirmation routing table** (see §C): decision-table rows → edge-case-hunter (branch coverage);
  **metamorphic relations + property invariants → assertion-auditor (strength) AND system-domain-expert
  (rule existence)** — behaviorist-r2-1; negative/boundary intents → edge-case-hunter. All confirmation
  is post-impl in EXECUTE.

### C. System-domain-expert critic seat — confirms in EXECUTE
- **File (new):** `personas/_shared/testing/system-domain-expert.md` — critic instantiated from the
  repo's `indications/` + `features/` + feature dossier. Seated in the **EXECUTE diff-review loop
  (§5.3)**, post-impl, owns its vote. **Bound analyzer:** grep the rule in `indications/`+`features/`
  (rule exists — solid) AND confirm the rule's **code branch is uncovered** via edge-case-hunter's
  coverage report (skeptic-r2-2: a bare test-corpus keyword grep is only advisory-strength, so absence is
  confirmed by *coverage*, not keyword grep). Tacit/undocumented rule → `advisory`. Produces "rule X
  (features/posts.md) is untested" as a **confirmed, branch-attributable** finding only when coverage
  backs it.
- **File (edit):** `personas/_resolution.md` §2.1 — **(a)** when a change is business-logic-heavy /
  **(f2) ran**, seat the system-domain-expert in the EXECUTE review loop **regardless of the test-file
  glob** (arch-r2-2: new untested business logic has no test files in the diff at selection time, yet is
  the primary case); **(b)** it is a priority pick within the existing cap. The synthesizer treats a
  system-domain-expert / edge-case-hunter co-fire on the same branch as **corroboration, not two
  independent blockers** (edge-r2-3).

### D. v-work parity (vocabulary only — unchanged)
- **File (edit):** `commands/v-work/steps/03-propose.md` §3a.5 — enrich the checklist: "for variant/type-
  dependent logic build a decision table; for each happy path name one fault that breaks it
  (negative/error case)." No new step, no agents, no hook phase. Keeps v-work single-shot/cheap.

### E. Wiring, docs, tests
- **File (edit):** `personas/_shared/testing/README.md` — "Generators vs critics" section (both axes) +
  link the design sub-group; clarify **edge-case-hunter's post-impl branch-coverage VOTE spans BOTH
  single-axis and multi-condition branches** — the cartographer's "multi-condition" ownership is
  **generation-scoped only** (edge-r2-1). Note (f2) feeds the backlog the EXECUTE loop confirms.
- **File (edit):** `commands/v-team/steps/04-execute-loop.md` §5.3 — document that the
  system-domain-expert is part of the review panel when (f2) ran, and that the dossier's MRs/decision
  tables are confirmed here (the post-impl half of the generate→confirm loop).
- **File (edit):** `templates/plan.md` — add **Test Design Dossier** section with delineated roles
  (arch-6): *Dossier* (decision tables / fault-hypotheses / MRs / invariants) → *Proposed test backlog*
  (actionable rows; ≥1 per artifact) → *Test plan* (harness/level strategy). Update the backlog comment
  to "authored by the (f2) test-design fan-out; critic hints are advisory inputs" and rename the
  `persona` column to **`source`** (arch-r2-3).
- **NO new hook phases, NO shared-model config** (arch-4, skeptic-6): `team_max_test_designers` lives in
  v-team's contract only, not vault-guide §1.1 symmetry.
- **File (new/edit):** BATS contracts (Docker only): (1) `03-propose-loop.md` defines (f2) as
  generation-only + sole backlog writer + names the advisory-hint sink + cross-generator dedup; (2) the
  three `design/*` generators exist with frontmatter + BOTH a `NOT → <critic>` and `NOT → <generator>`
  line + declare design-plan grounding / no analyzer; (3) `system-domain-expert.md` has a `## Bound
  analyzer` block AND is wired into `04-execute-loop.md` §5.3 (confirms post-impl); (4) `_resolution.md`
  §2.1 seats the domain-expert when (f2) ran regardless of test-file glob; (5) `design/README.md`
  routing table maps MR + property invariants to **assertion-auditor** (not only domain-expert); (6)
  `templates/plan.md` has "Test Design Dossier" + `source` column + dossier→backlog rule; (7) full suite
  green.

## Test plan
Docs/markdown + BATS framework change — test design = contract assertions (§E items 1–7). Plus a
**negative dogfood** case: assert (f2) performs no confirmation and the system-domain-expert is wired to
EXECUTE not PROPOSE (guards the round-2 temporal-inversion fix actually shipped).

## Proposed test backlog

| id | source | kind | target | intent | priority | disposition |
|----|--------|------|--------|--------|----------|-------------|
| seed-1 | self | contract | 03-propose-loop.md (f2) = generation-only + sole-backlog-writer + dedup + hint-sink | sub-phase wired, no confirmation in PROPOSE | must | |
| seed-2 | self | contract | design/ generators: frontmatter + `NOT→critic` + `NOT→generator` + no-analyzer | generators valid & doubly decorrelated | must | |
| seed-3 | self | contract | system-domain-expert.md bound-analyzer + wired into 04-execute-loop §5.3 | confirmer is post-impl (inversion fixed) | must | |
| seed-4 | self | contract | _resolution.md §2.1 seats domain-expert when (f2) ran regardless of glob | confirmer seated for primary case | must | |
| seed-5 | self | contract | design/README routing: MR+property → assertion-auditor | assertion artifacts get a strength critic | should | |
| seed-6 | self | contract | templates/plan.md Dossier + `source` column + ≥1-row rule | template + traceability | should | |
| seed-7 | self | negative | (f2) does no confirmation; design-critic PROPOSED_TESTS advisory | split + seam are real | should | |
| seed-8 | self | regression | full bats suite green in Docker | no regressions | must | |

## Open trade-offs / deferrals
- **T1 — Scope (RESOLVED):** generative fan-out is **v-team-only**; v-work vocabulary only (user decision).
- **T2 — Convergence status (ESCALATE):** round 2 ran (user-requested) and surfaced **2 confirmed-MAJOR
  structural fixes** (generate→confirm temporal inversion + confirmer selection mismatch). Both **applied
  in v1.1** by relocating all confirmation to EXECUTE — a re-alignment to the design's own axis, not new
  architecture. We are at the default round cap (2). v1.1's applied fixes have **not** been re-verified by
  a fresh critic pass. *User decides: proceed to EXECUTE, or run an opt-in round 3 against v1.1.*
- **T3 — skeptic-3 (advisory, mitigated):** pre-impl fault cases can be vapor; bounded by §5.2 row-by-row
  triage (1:5–1:20 keep is normal — skeptic confirmed the mitigation is structural, not cosmetic),
  cartographer being spec-stable, and MRs held advisory until EXECUTE confirms. Measure keep-rate uplift
  after first use.
- **T4 — Pact/consumer-driven contracts:** cited source, still owner-less. Deferred (README note only).

## Critique trail

### Round 0 — draft
v0: new 7th step `035-test-plan-loop.md`; generators reusing critic vocabulary; domain-expert with no
analyzer; new hook phases. (Superseded.)

### Round 1 — 4 critics, all REQUEST_CHANGES → v1
12 confirmed-MAJOR applied (architecture sub-phase pivot; generator/critic decorrelation; "mutation-
guided" dropped; single backlog owner; domain-expert bound analyzer; generate→confirm loop;
dossier→backlog traceability). skeptic-3 deferred (T3). Full finding table archived in v1 (git history).

### Round 2 — 4 critics vs v1 → v1.1
| persona | id | severity | grounding | issue (short) | disposition |
|---------|----|----------|-----------|---------------|-------------|
| process-architect | arch-r2-1 | MAJOR | confirmed | generate→confirm temporally inverted (confirmer votes before dossier exists) | **applied** — all confirmation moved to EXECUTE §5.3 |
| process-architect | arch-r2-2 | MAJOR | confirmed | domain-expert selection trigger (test-file glob) never fires for new untested logic | **applied** — §2.1 seats it when (f2) ran regardless of glob |
| process-architect | arch-r2-3 | MINOR | confirmed | template backlog provenance still "persona"/"every critic" | **applied** — `source` column + (f2)-authored comment |
| process-architect | arch-r2-4 | MINOR | advisory | hint sink unnamed; v-team cost envelope under-counts | **applied** — named sink + cost line |
| behaviorist | behaviorist-r2-1 | MAJOR | confirmed | MR/property artifacts have no assertion-strength confirmer | **applied** — route to assertion-auditor too |
| behaviorist | behaviorist-r2-2 | MINOR | confirmed | no generator↔generator (horizontal) decorrelation | **applied** — `NOT → <generator>` lines |
| behaviorist | behaviorist-r2-3 | MINOR | advisory | characterization tests collide with snapshot-overuse rule | **applied** — carve-out pending refactor |
| edge-case-hunter | edge-r2-1 | NIT | confirmed | "multi-condition" wording could carve coverage vote from edge | **applied** — README clause: vote spans both |
| edge-case-hunter | edge-r2-2 | MINOR | confirmed | (f2) merges dossiers w/o cross-generator dedup | **applied** — dedup rule in (f2) |
| edge-case-hunter | edge-r2-3 | advisory | advisory | domain-expert + edge can co-fire on same branch | **applied** — synthesizer treats as corroboration |
| skeptic | skeptic-r2-2 | MINOR | confirmed | grep-absence over-claims "confirmed" strength | **applied** — absence confirmed by coverage, else advisory |
| skeptic | skeptic-r2-3 | MINOR | confirmed | gate self-referential (LLM bias decides if logic present) | **applied** — fail open (default-ON; skip only refactor/docs) |
| skeptic | skeptic-r2-1/4 | INFO | confirmed | T3 mitigation real; no new unjustified assumption | noted |

_Metrics: round 2 — 4 critics · 13 findings · verdicts: 3× APPROVE_WITH_NITS + 1× REQUEST_CHANGES · new
confirmed-MAJOR: 3 (arch-r2-1, arch-r2-2, behaviorist-r2-1) — all applied in v1.1 · advisory: 3 · the 3
APPROVE critics confirmed all round-1 fixes resolved with zero new blockers in their lanes. Convergence:
capped-then-applied; v1.1 fixes await user decision on opt-in round 3._

### EXECUTE — diff-review (round 1, 2 reviewers) → converged
Both **APPROVE_WITH_NITS**. process-architect verified all 4 round-2 confirmed-MAJOR fixes PASS in the
implementation (generate→confirm seam, confirmer seating regardless of glob, single backlog owner,
MR/property routing); no broken cross-refs; v-work stayed vocabulary-only. testing-SME verified hard
gates (no mutation overclaim, generators bind no analyzer, system-domain-expert two-stage analyzer,
technique attribution, characterization carve-out). 4 NITs applied: reciprocal prospector↔cartographer
`NOT →` lines (sme-d-1); design/README mirror-critic summary table reconciled with routing table
(sme-d-2/arch-d-1); boundary-property-explorer property invariants route to assertion-auditor (sme-d-3);
04-execute-loop wikilinks normalized to bare names (arch-d-2). **Tests: 123/123 unit green in Docker**
(14 new in `test-design-fanout.bats` + 109 regression). No confirmed BLOCKER/MAJOR → converged clean.

## Refs
- Extends [[2026-06-19-0954-testing-persona-pack]] (the original 6-critic testing group).
- ADR candidate: "test design is a generative PROPOSE sub-phase; generators emit pre-impl, ALL
  confirmation happens post-impl in EXECUTE — strict generate→confirm seam."
- Research: Mutation-Guided LLM Test Gen (Meta, arXiv 2501.12862, deferred to critics); metamorphic
  relations (arXiv 2406.05397); ISTQB decision-table + state-transition; Feathers characterization tests.
