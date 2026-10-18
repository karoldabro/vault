---
type: persona-group
group: testing-design
tags: [persona, shared, testing, generator]
---

# testing-design — generative test-design group

The **generative** counterpart of the `_shared/testing/` critic group. Where the critics *review
written tests* in the EXECUTE testing loop, these generators *design candidate tests* in the PROPOSE
sub-phase `(f2)` — **before any code exists** — and feed the Proposed test backlog. This makes test design
a first-class generative activity, split out of solution design.

## Generators vs critics — the hard contract
A generator and a critic must never collapse into one correlated vote. The boundary is structural:

| | **Generators** (this group) | **Critics** (`_shared/testing/`) |
|---|---|---|
| Phase | PROPOSE sub-phase `(f2)` — pre-implementation | EXECUTE §5.3 testing loop — post-implementation |
| Grounds in | the converged **design plan** + `indications/`+`features/` | **written tests** + a bound analyzer |
| Binds an analyzer | **No** | **Yes** (coverage / mutation / run / smell) |
| Seats on the critique panel | **Never** | Yes — owns the VOTE |
| Output | dossier entries (`advisory`), no severity | findings with severity + grounding |
| Can block convergence | **No** | Yes (only `confirmed` findings) |

**Vertical decorrelation** (generator ↔ its mirror critic) — every generator file carries `NOT → <critic>`.
**Horizontal decorrelation** (generator ↔ generator) — every generator file also carries `NOT →
<other generator>` so the same partition/error intent isn't double-emitted; `(f2)` additionally collapses
same-branch duplicate intents to one backlog row.

## The six generators
| Generator | Owns (technique) | Seats when | Mirror critic(s) — confirm post-impl (see routing table) |
|-----------|------------------|------------|------------------------------------|
| [[business-logic-cartographer]] | decision-table / cause-effect / state-transition + characterization | every `(f2)` | edge-case-hunter + system-domain-expert |
| [[boundary-property-explorer]] | BVA / equivalence partitioning + property invariants | every `(f2)` | edge-case-hunter (boundaries) + assertion-auditor (property strength) |
| [[fault-relation-prospector]] | fault hypotheses + metamorphic relations | trigger: business logic with a rule a fault can break | edge-case-hunter + assertion-auditor + system-domain-expert |
| [[api-contract-mapper]] | one contract test per endpoint outcome, response shape, auth per action | trigger: an endpoint, route, command or other public entry point changes | edge-case-hunter + test-harness-critic |
| [[abuse-case-designer]] | another user's data, extra fields, permission bypass, injection | trigger: authentication, permissions, tenancy or user-owned data changes | assertion-auditor (the test fails without its guard) |
| [[performance-budget-designer]] | query, bound and work budgets; no load tests by default | trigger: a hot path, a list or report endpoint, or a job over many records | assertion-auditor + flakiness-sentinel |

Pick: the two every-`(f2)` generators, plus each generator whose trigger the change's keywords and impact
scope hit, capped by `team_max_test_designers` (default 5). When the triggers exceed the cap, keep the
highest-risk triggers (abuse first) and note the dropped ones in the trail.

## Dossier → backlog traceability (mandatory)
Every dossier artifact — each decision-table row, each metamorphic relation, each boundary partition —
**must map to ≥1 Proposed test backlog row**. A dossier that seeds zero runnable rows is coverage-theater
at design time and fails the `(f2)` contract (a BATS check guards the rule's presence).

## Confirmation routing (post-impl, in the EXECUTE §5.3 testing loop)
Generators emit `advisory` intent; the reviewers of the testing loop (`commands/_shared/testing-loop.md`) confirm it against real code:

| Dossier artifact | Confirmed by | Analyzer |
|------------------|--------------|----------|
| decision-table / state-transition row | [[edge-case-hunter]] | branch coverage (each row → a covered branch) |
| boundary / equivalence partition | [[edge-case-hunter]] | branch coverage |
| **metamorphic relation / property invariant** | **[[assertion-auditor]]** (assertion strength) **+** [[system-domain-expert]] (rule existence) | mutation + rule grep/coverage |
| business-rule presence | [[system-domain-expert]] | rule grep in `indications/`+`features/`, confirmed by branch coverage |
| endpoint outcome row | [[edge-case-hunter]] + [[test-harness-critic]] | branch coverage; the test runs at the feature or integration level |
| abuse case | [[assertion-auditor]] | mutation of the guard: the test fails when the guard is removed |
| budget case | [[assertion-auditor]] + [[flakiness-sentinel]] | a seeded query inside the loop fails the test; no wall-clock assertion |

Note: `edge-case-hunter`'s post-impl branch-coverage VOTE spans **both** single-axis and multi-condition
branches — the cartographer's "multi-condition" ownership is **generation-scoped only**, not a coverage
carve-out. A `system-domain-expert` / `edge-case-hunter` co-fire on the same branch is **corroboration**,
not two independent blockers (the synthesizer treats it as one).

## Deferred
- **Pact / consumer-driven contracts** — cited as a source but owner-less this round; no generator yet.

## Sources
Myers, *The Art of Software Testing* (fault-based, BVA/EP, decision tables) · Beizer (state-transition) ·
Feathers, *Working Effectively with Legacy Code* (characterization) · Chen et al., metamorphic testing
(arXiv 2406.05397) · Mutation-Guided LLM Test Gen (Meta, arXiv 2501.12862) · Claessen&Hughes QuickCheck /
MacIver Hypothesis (property-based).
