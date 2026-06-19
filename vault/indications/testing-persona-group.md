---
type: indication
project: vault
slug: testing-persona-group
scope: repo
tags: [indication, personas, v-team, testing]
---

# testing-persona-group

## Rule
Testing critics live as a **group** in `personas/_shared/testing/` (not the flat `_shared/`, not a stack
pack). Six lenses — `test-behaviorist`, `assertion-auditor`, `edge-case-hunter`, `test-double-critic`,
`flakiness-sentinel`, `test-harness-critic` — each owns **exactly one** documented AI-test failure
cluster and **must bind a real analyzer** (mutation, branch coverage, randomized rerun, mock-density
AST metric, or running the test). They are selected when a change touches test files (resolution §2.1).
Decorrelation boundaries are written into each mandate (owns X, NOT Y → named neighbor) so no two
critics double-vote.

## Rationale
AI writes tests with predictable blind spots (tautologies, over-mocking, happy-path bias, coverage
theater, flakiness, non-compiling harness code). One-cluster-per-persona keeps the panel decorrelated
(correlated critics collapse to ~2 effective votes); mandatory analyzer binding keeps findings
`confirmed` not advisory (the framework grounding rule). The set is evidence-driven: every persona maps
to an empirically documented LLM-test failure mode (e.g. Yuan FSE'24 24.8% pass rate → `test-harness-critic`;
Hora & Robbes MSR'26 agent over-mocking → `test-double-critic`).

## Examples
- Do: add a stack analyzer via the pack overlay (`assertion-auditor` → `infection` for PHP, `stryker`
  for JS) and let the generic persona supply the lens.
- Do: move shared production-code/test overlap to the specialist — `quality` no longer carries
  "tests express behaviour, not internals"; `test-behaviorist` owns it.
- Don't: add a seventh persona for Khorikov's four-pillars value judgment — it's a synthesizer rubric
  line in the group README, not a critic.
- Don't: keep `test-double-critic` in the panel on a stack where its mock-density metric can't be
  produced — it would be advisory-only.

## Applies-to
`personas/_shared/testing/**`, `personas/_resolution.md` (§2.1 selection) — authoring or selecting
testing critics. Links [[shared-vs-stack-persona-factoring]], [[confirmed-vs-advisory-findings]],
[[packs-detect-not-assume]], [[ADR-004-generic-packs-specifics-in-indications]],
[[ADR-006-testing-critic-group]].
