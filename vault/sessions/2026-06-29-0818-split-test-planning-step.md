---
type: session
project: vault
date: 2026-06-29
topic: split-test-planning-step
continues: [[2026-06-19-0954-testing-persona-group]]
files_touched: [commands/v-team.md, commands/v-team/steps/03-propose-loop.md, commands/v-team/steps/04-execute-loop.md, commands/v-work/steps/03-propose.md, personas/_resolution.md, personas/_shared/testing/README.md, personas/_shared/testing/design/, personas/_shared/testing/system-domain-expert.md, templates/plan.md, templates/VAULT.md, tests/unit/test-design-fanout.bats]
decisions: [ADR-011-generative-test-design-subphase]
tags: [session, v-team, testing, lifecycle]
---

# split-test-planning-step

## Goal
Split test design out of solution design in `/v-team` into a generative fan-out (adversarial + business-logic + boundary agents) and add a system-expert critic seat — run via `/v-team` on the framework itself.

## Did
- Ran the full `/v-team` lifecycle (2 PROPOSE rounds + 1 EXECUTE diff-review round) on the framework repo.
- Researched the named techniques behind the user's asks: fault-based / mutation-guided test gen (Meta arXiv 2501.12862), metamorphic relations (arXiv 2406.05397), decision-table / cause-effect / state-transition (the business-logic techniques), characterization tests.
- Added PROPOSE sub-phase **(f2)** to [[../../commands/v-team/steps/03-propose-loop]] — a generation-only fan-out; sole authoritative writer of the Proposed test backlog; design-critic `PROPOSED_TESTS` demoted to advisory hints; fail-open gating.
- Created the generator group `personas/_shared/testing/design/`: `fault-relation-prospector`, `business-logic-cartographer`, `boundary-property-explorer` + README (generator↔critic contract, routing table, traceability).
- Created [[../../personas/_shared/testing/system-domain-expert]] critic (two-stage analyzer: grep rule in `indications/`+`features/`, confirm absence via branch coverage), seated in EXECUTE §5.3.
- Wired confirmation into [[../../commands/v-team/steps/04-execute-loop]] §5.3; updated `_resolution.md` §2.1a, the testing README, `templates/plan.md` (Test Design Dossier + `source` column), `templates/VAULT.md` (`team_max_test_designers`), and v-work §3a.5 (vocabulary-only checklist).
- Added `tests/unit/test-design-fanout.bats` (14 contracts). Full unit suite **123/123 green in Docker**.
- Committed `27469d4` on `feat/split-test-planning-step`.

## Learned
- The framework already had a 6-lens **critic** testing group; the user's ask was really for a **generative** counterpart, so the design split generation (PROPOSE) from critique (EXECUTE) rather than duplicating lenses.
- The decisive round-2 catch: a generate→confirm loop is unexecutable if generation happens *after* panel convergence but the confirmer votes *during* the panel — confirmation must live in EXECUTE, not PROPOSE. This re-aligned the design to its own pre-impl/post-impl axis.
- "Mutation-guided" is wrong for a plan-time generator: mutation mutates code, owned by `assertion-auditor` post-impl. Generators hypothesize faults; critics kill mutants.
- The existing `testing-personas.bats` iterates a hardcoded six-critic list requiring a bound analyzer, so analyzer-less generators must live in a separate `design/` group with their own BATS file.
- Markdown line-wrap can split a grep'd phrase across lines and fail a contract test — keep asserted phrases on one line.

## Behaviors & rules
- A test-design generator binds no analyzer, emits `advisory` dossier entries, and never seats on the critique panel → only post-impl critics can block.
- (f2) is the sole authoritative writer of the Proposed test backlog; design-critic `PROPOSED_TESTS` are advisory hints → no dual ownership.
- Every dossier artifact maps to ≥1 backlog row → no design-time coverage theater.
- system-domain-expert finding is `confirmed` only when the rule is documented AND its branch is uncovered; bare keyword-grep absence → `advisory`.
- (f2) gating fails open: default-ON for endpoints/handlers/migrations/business logic; skip only pure refactor/docs, with an auditable note.
- system-domain-expert is seated whenever (f2) ran, regardless of the test-file glob → confirmer present for new-untested-logic, the primary case.

## Next
- Measure the generator keep-rate uplift after first real use (T3 — pre-impl fault cases can be vapor).
- Pact / consumer-driven contracts remain owner-less (T4) — assign a generator if it recurs.

## Refs
- [[../decisions/ADR-011-generative-test-design-subphase]]
- [[../decisions/ADR-006-testing-critic-group]]
- [[../features/v-team]]
- [[../indications/generators-emit-critics-confirm]]
- [[../indications/testing-persona-group]]
- [[../plans/2026-06-29-0818-split-test-planning-step]]
- [[2026-06-19-0954-testing-persona-group]]
