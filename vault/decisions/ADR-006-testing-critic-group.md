---
type: decision
project: vault
id: ADR-006
status: accepted
scope: repo
tags: [adr, v-team, personas, testing]
---

# ADR-006 — Testing critique is a one-cluster-per-persona grounded group

## Context
`/v-team` reviews production code well, but AI writes *tests* with predictable, documented blind spots
(tautological/mirror tests, over-mocking, happy-path bias, coverage theater, flakiness, non-compiling
harness code — see Hora & Robbes MSR'26, Yuan FSE'24 where only 24.8% of LLM tests even pass). The
existing `_shared` lenses only glance at tests (`quality` had a single "tests express behaviour" bullet).
We needed dedicated testing critics, and had to decide their **structure**: how many, where they live,
how they avoid collapsing into correlated votes, and whether broad testing concerns (test value,
strategy) each deserve a persona. A panel of correlated critics is the failure mode — N similar critics
collapse to ~2 effective votes (cf. [[ADR-001-panel-loop-over-peer-debate]]).

## Decision
Testing critics form a **group** at `personas/_shared/testing/` with these rules:
1. **One persona = one documented AI-test failure cluster.** Six: `test-behaviorist`, `assertion-auditor`,
   `edge-case-hunter`, `test-double-critic`, `flakiness-sentinel`, `test-harness-critic`.
2. **Each binds a real analyzer** (mutation, branch coverage, randomized rerun, mock-density AST metric,
   or running the test) so findings are `confirmed`, not advisory — extends
   [[ADR-003-tool-grounded-findings]]. A persona that can only ever be advisory on a stack is dropped
   from the panel rather than allowed to block.
3. **Decorrelation boundaries are written into every mandate** ("owns X, NOT Y → named neighbor"); the
   `quality` lens cedes test-code quality to the group.
4. **Selected on test-touching changes** via `_resolution.md` §2.1 (cap 3), not on every change.
5. **Cross-cutting judgments that aren't a distinct lens stay out of the persona set.** Khorikov's
   four-pillars whole-test value trade-off is applied by the **synthesizer as a rubric line**, not a 7th
   persona — adding a critic that fires on "is this test worth keeping" would correlate with every other
   lens. Likewise `test-strategist` was dropped (it owned no AI-failure cluster solely and overlapped
   two neighbors) in favour of `test-harness-critic`, which owns the largest documented cluster
   (compile/run/idiom failures).

## Consequences
- Testing critique gets the same grounded, decorrelated panel rigor as production code; the persona set
  maps 1:1 to evidence, so each seat is justifiable.
- Stack packs add per-stack analyzer **overlays** for the group (infection/stryker/mutation_test,
  coverage flags, randomize flags, mock greps) — without them the critics fall back toward advisory and
  lose their teeth. Done for `api-laravel`, `nuxt`, `flutter` (2026-06-19); future packs must include a
  Testing-group overlay block.
- Adding a future testing concern requires showing it is (a) a distinct failure cluster and (b)
  decorrelated from the six — otherwise it belongs in a mandate or the synthesizer rubric, not a new
  persona. Guards against persona sprawl.
- Operationalized by [[testing-persona-group]]; builds on [[shared-vs-stack-persona-factoring]] and
  [[confirmed-vs-advisory-findings]].
