---
type: plan
project: vault
slug: split-test-planning-step
status: executed
process_record: 2026-06-29-0818-split-test-planning-step.trail.md
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

## Open & deferred
- **T3 — pre-impl fault cases can be vapor (advisory, mitigated):** bounded by §5.2 row-by-row
  triage (1:5–1:20 keep is normal), cartographer being spec-stable, and MRs held advisory until
  EXECUTE confirms. Measure keep-rate uplift after first use.
- **T4 — Pact/consumer-driven contracts:** cited source, still owner-less. Deferred (README note only).

## Design

> **Two governing principles:**
> 1. **Architecture:** test design is a **sub-phase of PROPOSE**, not a 7th step — no
>    renumber, no new hook phases, no fractional file numbering.
> 2. **Generate→confirm seam:** generators **emit pre-impl in PROPOSE (f2)**;
>    confirmation of the dossier happens **post-impl in EXECUTE §5.3** — never inside the PROPOSE panel.
>    This is the same "generators emit / critics own the post-impl VOTE" axis, made temporally executable.

### A. Test-design fan-out as a PROPOSE sub-phase (generation only) — v-team
- **File (edit):** `commands/v-team/steps/03-propose-loop.md` (single physical file — `~/.claude/commands/
  v-team` is a symlink to the workspace source; one edit). · **Action:** insert section **(f2)
  Test-design fan-out** between (f) convergence and (g) finalise. It spawns the generators (§B), merges
  their dossiers (with a **cross-generator dedup rule** — collapse same-branch error/partition intents to
  one row), writes the **Test Design Dossier** into the plan artifact, and is the **sole
  authoritative writer** of the Proposed test backlog. **(f2) only GENERATES — it performs no
  confirmation.** · **Pattern:** reuse only the parallel-`Agent`-spawn-and-merge skeleton of
  (c)+(e); omit the grounding-gate/de-bias convergence prose (reference, don't copy).
- **File (edit):** same file §(e) item 5 · **Action:** demote design-critic `PROPOSED_TESTS` to
  **advisory test hints**, written to an **"Advisory test hints" subsection** of the plan artifact that
  (f2) reads and reconciles. The §(d) finding schema is unchanged (still
  emitted); only its consumption changes. Removes dual ownership.
- **Gating — fail open:** (f2) is **default-ON** for any diff touching
  endpoints/handlers/migrations/business logic. It skips **only** pure refactor/docs/formatting diffs,
  with an auditable one-line note surfaced at the approval gate. (Rationale: the bias (f2) exists to
  counter must not gate its own activation.)
- **No dispatcher renumber.** `v-team.md` keeps 6 steps; PROPOSE documents the new sub-phase. Update
  `v-team.md` cost envelope to "+ up to `team_max_test_designers` generators in PROPOSE".

### B. Generative test-design group — `personas/_shared/testing/design/`
A new sub-group of **generators**, decorrelated from the six **critics** by a hard **vertical** axis
*and* a **horizontal** axis (both stated in §E README):
- **Vertical (generator↔critic):** generators ground in the DESIGN PLAN, emit candidate cases
  pre-impl, bind NO analyzer, and NEVER seat on the critique panel; critics ground in WRITTEN TESTS +
  their bound analyzer and own the post-impl VOTE. Each generator carries a `NOT → <mirror critic>` line.
- **Horizontal (generator↔generator):** each generator also carries a
  `NOT → <other generator>` line so EP/error intents don't double-emit. The horizontal lines are
  **reciprocal**: every generator names every other generator, so no pair is decorrelated in one
  direction only.
Capped by v-team-scoped `team_max_test_designers` (default 3).

1. **`fault-relation-prospector.md`** — **fault-hypothesis + metamorphic relations only**. For each
   happy-path scenario, name the fault that would break it and the metamorphic relation it should
   preserve; emit negative/error *case intent*. **No "mutation-guided" label** (mutation mutates code =
   assertion-auditor's gold lane; mutant-killing defers to EXECUTE §5.2). Each MR
   names the invariant it preserves. **MRs stay `advisory` until confirmed in EXECUTE** (§5.3) — not in
   PROPOSE. `NOT → edge-case-hunter` (post-impl coverage); `NOT →
   boundary-property-explorer` (single-axis boundaries); `NOT → business-logic-cartographer`
   (multi-condition decision tables); `NOT → assertion-auditor` (mutation/assertion strength).
2. **`business-logic-cartographer.md`** — decision-table / cause-effect graphing / state-transition +
   **characterization tests** (Feathers, for changes to existing untested logic).
   Decomposes variant/type-dependent rules (e.g. `post.type` → conditionally required params, distinct
   logic) into a **decision table**; every row maps to a code branch. **Spec-stable** (derives from
   `indications/`+`features/`, survives the diff). `NOT → edge-case-hunter` single-axis
   EP/BVA (this owns multi-condition combinations); `NOT → boundary-property-explorer`; `NOT →
   fault-relation-prospector` (fault hypotheses and metamorphic relations); `NOT →
   system-domain-expert` (that critic confirms documented rules post-impl). Characterization
   tests carry a **carve-out from assertion-auditor's snapshot-overuse rule pending refactor**, and must
   be upgraded to a semantic assertion once behavior is understood.
3. **`boundary-property-explorer.md`** — BVA / equivalence partitioning / property-based invariants;
   generative emission only. `NOT → edge-case-hunter` (post-impl boundary VOTE); `NOT →
   business-logic-cartographer` (multi-condition rows); `NOT → fault-relation-prospector` (fault
   hypotheses and metamorphic relations).
- **File (new):** `personas/_shared/testing/design/README.md` — generators-vs-critics contract, both
  decorrelation axes, dossier schema, **dossier→backlog traceability** (≥1 row per artifact), and the
  **confirmation routing table** (see §C): decision-table rows → edge-case-hunter (branch coverage);
  **metamorphic relations + property invariants → assertion-auditor (strength) AND system-domain-expert
  (rule existence)**; negative/boundary intents → edge-case-hunter. All confirmation
  is post-impl in EXECUTE. The file's mirror-critic summary table and its routing table **must agree
  row for row** — two tables naming different confirmers for the same artifact is a defect.

### C. System-domain-expert critic seat — confirms in EXECUTE
- **File (new):** `personas/_shared/testing/system-domain-expert.md` — critic instantiated from the
  repo's `indications/` + `features/` + feature dossier. Seated in the **EXECUTE diff-review loop
  (§5.3)**, post-impl, owns its vote. **Bound analyzer:** grep the rule in `indications/`+`features/`
  (rule exists — solid) AND confirm the rule's **code branch is uncovered** via edge-case-hunter's
  coverage report. A bare test-corpus keyword grep is only advisory-strength, so absence is
  confirmed by *coverage*, not keyword grep. Tacit/undocumented rule → `advisory`. Produces "rule X
  (features/posts.md) is untested" as a **confirmed, branch-attributable** finding only when coverage
  backs it.
- **File (edit):** `personas/_resolution.md` §2.1 — **(a)** when a change is business-logic-heavy /
  **(f2) ran**, seat the system-domain-expert in the EXECUTE review loop **regardless of the test-file
  glob** (new untested business logic has no test files in the diff at selection time, yet is
  the primary case); **(b)** it is a priority pick within the existing cap. The synthesizer treats a
  system-domain-expert / edge-case-hunter co-fire on the same branch as **corroboration, not two
  independent blockers**.

### D. v-work parity (vocabulary only — unchanged)
- **File (edit):** `commands/v-work/steps/03-propose.md` §3a.5 — enrich the checklist: "for variant/type-
  dependent logic build a decision table; for each happy path name one fault that breaks it
  (negative/error case)." No new step, no agents, no hook phase. Keeps v-work single-shot/cheap.

### E. Wiring, docs, tests
- **File (edit):** `personas/_shared/testing/README.md` — "Generators vs critics" section (both axes) +
  link the design sub-group; clarify **edge-case-hunter's post-impl branch-coverage VOTE spans BOTH
  single-axis and multi-condition branches** — the cartographer's "multi-condition" ownership is
  **generation-scoped only**. Note (f2) feeds the backlog the EXECUTE loop confirms.
- **File (edit):** `commands/v-team/steps/04-execute-loop.md` §5.3 — document that the
  system-domain-expert is part of the review panel when (f2) ran, and that the dossier's MRs/decision
  tables are confirmed here (the post-impl half of the generate→confirm loop). Its wikilinks to
  persona files use **bare names**, not paths.
- **File (edit):** `templates/plan.md` — add **Test Design Dossier** section with delineated roles:
  *Dossier* (decision tables / fault-hypotheses / MRs / invariants) → *Proposed test backlog*
  (actionable rows; ≥1 per artifact) → *Test plan* (harness/level strategy). Update the backlog comment
  to "authored by the (f2) test-design fan-out; critic hints are advisory inputs" and rename the
  `persona` column to **`source`**.
- **NO new hook phases, NO shared-model config**: `team_max_test_designers` lives in
  v-team's contract only, not vault-guide §1.1 symmetry.
- **File (new/edit):** BATS contracts in `tests/unit/test-design-fanout.bats` (Docker only): (1)
  `03-propose-loop.md` defines (f2) as
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
EXECUTE not PROPOSE (guards the temporal-inversion fix actually shipped).

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

## Refs
- Extends [[2026-06-19-0954-testing-persona-pack]] (the original 6-critic testing group).
- Process record: `vault/plans/2026-06-29-0818-split-test-planning-step.trail.md` — findings,
  dispositions, rejected options.
- ADR candidate: "test design is a generative PROPOSE sub-phase; generators emit pre-impl, ALL
  confirmation happens post-impl in EXECUTE — strict generate→confirm seam."
- Research: Mutation-Guided LLM Test Gen (Meta, arXiv 2501.12862, deferred to critics); metamorphic
  relations (arXiv 2406.05397); ISTQB decision-table + state-transition; Feathers characterization tests.
