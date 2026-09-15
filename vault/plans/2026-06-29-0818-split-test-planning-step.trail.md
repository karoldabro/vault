---
type: trail
project: vault
plan: 2026-06-29-0818-split-test-planning-step
date: 2026-06-29
personas: [degraded-no-pack, process-architect, skeptic, test-behaviorist, edge-case-hunter]
rounds: 2 propose + 1 diff-review
convergence: capped-then-applied
tags: [trail, record, team, testing, lifecycle]
---

# split-test-planning-step — process record

How `vault/plans/2026-06-29-0818-split-test-planning-step.md` was reached. That plan carries the
current truth; this file carries the findings, the dispositions and the options that lost.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Test design is a sub-phase of PROPOSE, section (f2) | A 7th lifecycle step `035-test-plan-loop.md` | A new step forces a dispatcher renumber, new hook phases and fractional file numbering for one generative fan-out |
| Generators emit pre-impl; all confirmation happens post-impl in EXECUTE §5.3 | Confirm the dossier inside the PROPOSE panel | The confirmer would vote before the dossier it confirms exists — the seam was temporally inverted |
| The generative fan-out is v-team-only; v-work gets vocabulary only | Give v-work the same fan-out | User decision. v-work stays single-shot and cheap |
| `team_max_test_designers` lives in v-team's contract only | Add a shared-model config key mirrored in `vault-guide.md` §1.1 | Symmetry with the guide is not worth a second home for one cap |
| (f2) is default-ON, skipping only refactor/docs/formatting diffs | Gate (f2) on an LLM judgement that the diff carries business logic | The happy-path bias that (f2) exists to counter would decide whether (f2) runs |
| Absence of a rule's test is confirmed by coverage | Confirm absence with a keyword grep over the test corpus | A bare grep is advisory-strength; it cannot distinguish an untested branch from a differently-named test |

## Findings & dispositions

### Round 0 — draft

v0: new 7th step `035-test-plan-loop.md`; generators reusing critic vocabulary; domain-expert with no
analyzer; new hook phases.

### Round 1 — 4 critics, all REQUEST_CHANGES → v1

12 confirmed-MAJOR applied: architecture sub-phase pivot; generator/critic decorrelation;
"mutation-guided" dropped; single backlog owner; domain-expert bound analyzer; generate→confirm loop;
dossier→backlog traceability. skeptic-3 deferred as T3. The full round-1 finding table is in git
history at the v1 revision of the plan.

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

### EXECUTE — diff-review, 2 reviewers

Both **APPROVE_WITH_NITS**. process-architect verified all 4 round-2 confirmed-MAJOR fixes PASS in the
implementation (generate→confirm seam, confirmer seating regardless of glob, single backlog owner,
MR/property routing); no broken cross-refs; v-work stayed vocabulary-only. testing-SME verified hard
gates (no mutation overclaim, generators bind no analyzer, system-domain-expert two-stage analyzer,
technique attribution, characterization carve-out). No confirmed BLOCKER/MAJOR.

| id | nit | disposition |
|---|---|---|
| sme-d-1 | prospector↔cartographer `NOT →` lines were not reciprocal | applied; the reciprocity rule is now §B of the plan |
| sme-d-2 / arch-d-1 | `design/README.md` mirror-critic summary table disagreed with its routing table | applied; the agreement rule is now §B of the plan |
| sme-d-3 | boundary-property-explorer property invariants had no assertion-strength confirmer | applied; routed to assertion-auditor |
| arch-d-2 | `04-execute-loop.md` wikilinks used paths, not bare names | applied; the bare-name rule is now §E of the plan |

## Metrics

| measure | round 2 | EXECUTE diff-review |
|---|---|---|
| critics seated | 4 | 2 |
| findings | 13 | 4 nits |
| verdicts | 3× APPROVE_WITH_NITS + 1× REQUEST_CHANGES | 2× APPROVE_WITH_NITS |
| new confirmed MAJOR | 3 (arch-r2-1, arch-r2-2, behaviorist-r2-1), all applied | 0 |
| advisory | 3 | 0 |
| previously-confirmed findings dropped | none — the 3 APPROVE critics confirmed every round-1 fix resolved | none |
| tests | — | 123/123 unit green in Docker: 14 new in `tests/unit/test-design-fanout.bats` + 109 regression |
| convergence | capped-then-applied at the default round cap of 2 | converged clean |

## Rejected / deferred

- **A 7th lifecycle step `035-test-plan-loop.md`.** The v0 shape. Killed by the architecture pivot: a
  sub-phase of PROPOSE needs no renumber, no new hook phases and no fractional file numbering.
- **The "mutation-guided" label on `fault-relation-prospector.md`.** Mutation mutates code, which is
  assertion-auditor's gold lane in EXECUTE §5.2. The generator emits fault hypotheses, not mutants.
- **A shared-model config key for `team_max_test_designers`.** Rejected with the new hook phases; the
  cap lives in v-team's contract only.
- **An opt-in round 3 against v1.1.** Round 2 ran at the user's request and hit the default cap of 2.
  Its applied fixes were re-verified by the EXECUTE diff-review instead of by a fresh design critique.
- **T1 — scope.** Resolved: v-team-only, v-work vocabulary only, by user decision.
- **Pact / consumer-driven contract testing.** Cited as a source, no owner. Carried into the plan as
  the open deferral T4 (README note only).
