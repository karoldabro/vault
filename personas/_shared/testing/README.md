---
type: persona-group
group: testing
tags: [persona, shared, testing]
---

# testing — critic group

A **stack-agnostic testing critic group** for `/v-team`: these lenses review *test* code the way the
flat `_shared/*` lenses review production code. Selected when a change adds/modifies tests (see
`personas/_resolution.md` §2.1). Each persona owns **one documented AI-test failure cluster** and binds
a **real analyzer** so its findings can be `confirmed` (only confirmed findings block — see
[[confirmed-vs-advisory-findings]]).

Like every `_shared` lens, these stay generic and **detect** the project's tooling; a stack pack binds
the concrete analyzer per stack via its overlay (see the table below). Project-specific test conventions
live in each repo's `indications/` (ADR-004), which `/v-team` loads into every critic's envelope.

## The six lenses

| Persona | Owns (AI failure cluster) | Grounding |
|---------|---------------------------|-----------|
| [[test-behaviorist]] | mirror/tautological-by-intent; impl-detail coupling; unreadable test code | uneven (JS gold, PHP/Py structural, Dart advisory) |
| [[assertion-auditor]] | weak/absent assertions; coverage theater; snapshot overuse | **gold** — mutation testing |
| [[edge-case-hunter]] | happy-path bias; missing boundary/error cases; no regression-test-for-fix | **gold** — branch coverage |
| [[test-double-critic]] | over-mocking; assert-the-mock; mock-the-SUT | metric-gated (mandatory mock-density AST metric) |
| [[flakiness-sentinel]] | time/RNG/order/shared-state nondeterminism | **gold** — randomized rerun/shuffle |
| [[test-harness-critic]] | compile/run failures; framework idioms; hallucinated APIs; + light pyramid | **gold** — run the test |

## Decorrelation boundaries (each owns X, NOT Y → neighbor)

Multi-agent panels lose value when critics correlate. Boundaries are enforced in each persona's mandate:

- **behaviorist** owns *where the test points* (surface/structure/readability), NOT *how hard it
  asserts* → assertion-auditor.
- **assertion-auditor** owns *assertion strength / would-it-fail* (incl. anti-tautology as a
  can't-fail property), NOT *what surface it targets* → behaviorist.
- **edge-case-hunter** owns *which concrete inputs/branches* are exercised, NOT *should the failure
  mode exist* → `skeptic` (design altitude), NOT *at what level* → test-harness-critic.
- **test-double-critic** owns *the decision to double + the double's fidelity*, NOT *non-determinism in
  general* → flakiness-sentinel.
- **flakiness-sentinel** owns *determinism/isolation regardless of cause*, NOT *whether to mock* →
  test-double-critic.
- **test-harness-critic** owns *runnability + level placement*, NOT *individual missing inputs* →
  edge-case-hunter, NOT *assertion strength* → assertion-auditor.

Also: the flat `quality` lens **no longer** carries "tests express behaviour, not internals" — that
bullet moved to `test-behaviorist` (specialist beats generalist; removes a double-vote).

## Per-stack analyzer overlay

A stack pack's overlay binds the real tool. Generic defaults shown per persona; stack examples:

```
assertion-auditor: { php: infection, js: stryker, py: "mutmut|cosmic-ray", dart: mutation_test,
                     fallback: "phpunit --fail-on-risky | eslint expect-expect | flake8-assertive" }
edge-case-hunter:  { php: "phpunit --coverage (xdebug path)", js: "c8 --branches",
                     py: "coverage --cov-branch", dart: "flutter test --coverage (line-only)" }
flakiness-sentinel:{ php: "phpunit --order-by=random", js: "jest --randomize", py: "pytest-randomly",
                     dart: "flutter test --test-randomize-ordering-seed=random" }
test-double-critic:{ generic: "AST mock-density + concrete-mock + SUT-self-mock metric (MANDATORY)" }
test-behaviorist:  { js: "eslint-plugin-testing-library + eslint-plugin-jest", php: phpmd,
                     py: "ruff PT rules", dart: advisory }
test-harness-critic:{ generic: "run changed tests + JUnit/JSON duration & layer-count parse" }
```

## Synthesizer rubric — the four-pillars trade-off (not a persona)

When reconciling findings, the synthesizer applies Khorikov's four pillars as a tie-break, not as a
seventh critic: a good test trades **protection-against-regressions × resistance-to-refactoring × fast
feedback × maintainability**. The first two are in tension — flag a test that maximizes one by
destroying another, and prefer deleting a zero-value test over patching it.

## Selection (default for a test-touching change)
Cap is 3 (per `_resolution.md` §2). Default pick: **test-behaviorist + assertion-auditor + the lens the
diff most implicates** (collaborators → test-double-critic; stateful/async → flakiness-sentinel; new
branches → edge-case-hunter; new/failing harness → test-harness-critic). Drop the metric-gated
test-double-critic if its mock metric can't be produced on the stack (grounding rule).

## Sources
Khorikov, *Unit Testing: Principles, Practices, and Patterns* (2020) · Beck, *TDD by Example* (2002) ·
Ian Cooper, "TDD, Where Did It All Go Wrong" (2013) · Meszaros, *xUnit Test Patterns* (2007) · Fowler,
"Mocks Aren't Stubs" & "The Practical Test Pyramid" · Freeman & Pryce, *GOOS* (2009) · Myers, *The Art
of Software Testing* (1979) · Langr/Hunt/Thomas, *Pragmatic Unit Testing* (Right-BICEP, CORRECT) ·
Claessen & Hughes, QuickCheck (2000) / MacIver, Hypothesis · R.C. Martin, *Clean Code* (FIRST) · Google
Testing Blog, "Flaky Tests at Google" (2016/17) · Cohn, *Succeeding with Agile* (Test Pyramid) · Dodds,
"The Testing Trophy" · Pact (consumer-driven contracts) · Hora & Robbes, MSR'26 (agent over-mocking) ·
Yuan et al., FSE 2024 (ChatGPT unit-test eval, 24.8% pass) · Schmidt et al., 2026 (LLM-test flakiness).
