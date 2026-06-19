---
type: session
project: vault
date: 2026-06-19
topic: testing-persona-group
files_touched: [personas/_shared/testing/test-behaviorist.md, personas/_shared/testing/assertion-auditor.md, personas/_shared/testing/edge-case-hunter.md, personas/_shared/testing/test-double-critic.md, personas/_shared/testing/flakiness-sentinel.md, personas/_shared/testing/test-harness-critic.md, personas/_shared/testing/README.md, personas/_resolution.md, personas/_shared/quality.md, README.md, vault/_moc.md, vault/indications/_index.md, vault/indications/testing-persona-group.md, vault/plans/2026-06-19-0954-testing-persona-pack.md, tests/unit/testing-personas.bats]
decisions: [keep-6-swap-strategist-for-harness-critic, four-pillars-is-rubric-not-persona, testing-critics-live-in-shared-testing-group]
continues: [[2026-06-16-1038-v-team-persona-critique-command]]
tags: [session, personas, v-team, testing]
---

# testing-persona-group

## Goal
Add a testing-specialized critic group to `/v-team` — distinct, internet-research-grounded testing
personas — so AI-written tests get the same panel-critique rigor as production code.

## Did
- Ran the full `/v-team` lifecycle on the framework repo itself (no stack pack → degraded to
  v-work-with-a-panel; the panel = research + design critics).
- PROPOSE panel (4 parallel agents): 2 internet-research (canonical testing lenses + AI-test failure
  modes) + 2 design critics (decorrelation/coverage + tool-grounding). Converged in 1 round.
- Authored six lenses in [[personas/_shared/testing/]]: test-behaviorist, assertion-auditor,
  edge-case-hunter, test-double-critic, flakiness-sentinel, test-harness-critic — each owns ONE
  documented AI-test failure cluster + binds a real analyzer (grounding rule). Plus a group README
  (decorrelation-boundary table, per-stack analyzer overlays, source bibliography).
- Wired selection: `_resolution.md` §2.1 (testing-group, test-touching changes, cap 3). Removed the
  "tests express behaviour, not internals" lane from [[personas/_shared/quality.md]] → owned by
  test-behaviorist (kills a double-vote). Indexed in README / [[_moc]] / [[indications/_index]].
- EXECUTE diff-review panel (2 critics) over the diff; applied all confirmed findings.
- Tests: [[tests/unit/testing-personas.bats]] (8 cases: file + grounding contract). Offline suite green
  (47 unit + 50 integration, Dockerized).
- Plan + full critique trail: [[plans/2026-06-19-0954-testing-persona-pack]]. New rule:
  [[indications/testing-persona-group]]. Committed `c45d196` to main.

## Learned
- The three research/critique sources converged independently on the same gaps — strong signal: (1)
  test-code maintainability, (2) Khorikov four-pillars whole-test value judgment, (3) framework-idiom /
  compilation / hallucinated-API failures (Yuan FSE'24: only **24.8%** of ChatGPT-generated tests even
  pass). The third was the biggest hole and drove the test-strategist→test-harness-critic swap.
- **Diff-review caught a real bug an LLM (me) introduced:** `jest --shuffle` is wrong — Jest uses
  `--randomize` (29.5+); `--shuffle` is Vitest's spelling. Verified against jestjs.io/docs/cli. Exactly
  the hallucinated-flag failure mode test-harness-critic / the grounding rule exist to catch — a nice
  self-demonstration.
- Decorrelation is the hard part of a persona panel, not coverage: behaviorist×assertion-auditor and
  edge-case-hunter×test-strategist collapse unless boundaries are written into each mandate ("owns X,
  NOT Y → named neighbor"). Correlated critics = ~2 effective votes wearing 6 hats.
- The four-pillars trade-off is an integrative *synthesizer* judgment, not a standalone lens — folded
  into the group README rubric, not a 7th persona.

## Next
- Stack packs (`api-laravel`/`nuxt`/`flutter`) don't yet `use_shared` the testing group via overlays —
  add per-stack analyzer bindings (infection/stryker/mutmut, c8/coverage, randomize flags) when next
  touching those packs.
- Consider a `team_max_parallel_critics` note for mixed prod+test diffs (one testing critic added
  within the cap).
- OV `memory_store` reported "extraction returned 0 memories" (raw text still stored) — watch if it
  recurs.

## Refs
- [[plans/2026-06-19-0954-testing-persona-pack]]
- [[indications/testing-persona-group]] · [[indications/shared-vs-stack-persona-factoring]] · [[indications/confirmed-vs-advisory-findings]] · [[indications/packs-detect-not-assume]]
- [[decisions/ADR-004-generic-packs-specifics-in-indications]] · [[decisions/ADR-003-tool-grounded-findings]] · [[decisions/ADR-001-panel-loop-over-peer-debate]]
- [[features/v-team]]
- [[sessions/2026-06-16-1038-v-team-persona-critique-command]] · [[sessions/2026-06-16-1135-v-team-nuxt-flutter-packs]]
