---
type: plan
project: vault
slug: testing-persona-pack
status: executed   # proposed | approved | executed | superseded
process_record: 2026-06-19-0954-testing-persona-pack.trail.md
tags: [plan, team, personas, testing]
---

# testing-persona-pack — team plan

A new **testing critic group** for `/v-team`: stack-agnostic personas that review *test* code the way
the existing `_shared` lenses review production code. Motivation: AI writes tests with predictable
blind spots (tautological tests, over-mocking, happy-path bias, coverage theater, flakiness,
non-compiling harness code). Each persona owns one documented failure cluster and binds a real
analyzer so its findings are `confirmed`, not advisory.

## Task
Build testing-specialized `/v-team` critic personas, grounded in internet research on testing
best-practice and AI-test-writing failure modes.
Keywords: testing, persona, critique-lens, test-smells, coverage, flakiness, decorrelation.

## Plan

Layout: a cohesive group under `personas/_shared/testing/` (parallels the flat `_shared/*` lenses but
grouped, since six related files would clutter the flat dir). Six personas + a group README; then wire
selection + indexes.

1. `personas/_shared/testing/test-behaviorist.md` · CREATE · Write · per `_persona-template.md`
   — lens: **surface & structure**. Tests target observable behavior via the public contract, not
   internals; AAA/Given-When-Then; behavioral naming; **test-code readability/maintainability**
   (DAMP-over-DRY, Mystery Guest, fixture bloat, clear failure messages). base_agent: `quality-engineer`.
   analyzer (generic): structural AST/grep for forbidden patterns (asserting private state, interaction-
   only tests) — per-stack tiers: JS/TS `eslint-plugin-testing-library`+`eslint-plugin-jest` (confirmed),
   PHP/Python pytest-style/PHPMD (structural), Dart (advisory). Owns AI clusters C1(intent), C5.
2. `personas/_shared/testing/assertion-auditor.md` · CREATE · Write
   — lens: **assertion strength & anti-tautology**. A test must fail when the implementation breaks. No
   assertion-free / weak / tautological tests; snapshot semantic gap; coverage-theater. base_agent:
   `quality-engineer`. analyzer (generic, GOLD): **mutation testing** — Infection (PHP) / Stryker (JS) /
   mutmut|cosmic-ray (Py) / mutation_test (Dart); fallback `--fail-on-risky` / `expect-expect`. Owns
   C1(can't-fail), C4, C6.
3. `personas/_shared/testing/edge-case-hunter.md` · CREATE · Write
   — lens: **input/branch/path coverage**. BVA, equivalence partitions, error paths, null/empty/huge,
   Right-BICEP / CORRECT, property-based thinking; **a bugfix ships a failing-first regression test**.
   base_agent: `quality-engineer` (fallback `root-cause-analyst`). analyzer (GOLD): branch coverage
   (uncovered branch = enumerable missing case) + PBT presence; pair with mutation data. Owns C3.
4. `personas/_shared/testing/test-double-critic.md` · CREATE · Write
   — lens: **mocking discipline & boundaries**. Doubles taxonomy (dummy/stub/spy/mock/fake), over-
   mocking, mock-what-you-don't-own, asserting-the-mock, mocking-the-SUT; contract tests at *owned*
   boundaries. base_agent: `backend-architect` (fallback `quality-engineer`). analyzer (MANDATORY
   thresholded AST metric, else advisory): mock-density per test + concrete-vs-interface + SUT-self-mock;
   fidelity judgments stay advisory. Owns C2.
5. `personas/_shared/testing/flakiness-sentinel.md` · CREATE · Write
   — lens: **determinism & isolation (FIRST)**. Time/clock, RNG, ordering, shared state, network/FS,
   async, test pollution, test-data isolation. base_agent: `root-cause-analyst`. analyzer (GOLD):
   randomized-order rerun ×N (`--order-by=random` / `jest --randomize` / `pytest-randomly` /
   `--test-randomize-ordering-seed`) + nondeterminism grep; gate to changed tests (CI cost). Owns C7.
6. `personas/_shared/testing/test-harness-critic.md` · CREATE · Write
   — lens: **runnability & framework fluency** (the biggest documented AI failure — 24.8% pass rate).
   Does it compile/run? correct framework idioms & fixture lifecycle? no hallucinated assertion/mock
   APIs? plus a light suite-level **test-level/pyramid sanity** check. base_agent: `quality-engineer` (fallback `Explore`). analyzer (GOLD: most objective of all —
   run the test, it runs or it doesn't): execute changed tests + layer-count/duration profile for the
   pyramid sub-check. Owns C8 + light strategy.
7. `personas/_shared/testing/README.md` · CREATE · Write — group index: the six lenses, their
   single-owner failure cluster, decorrelation boundaries (the "owns X, NOT Y → neighbor" table),
   per-stack analyzer overlay table, one synthesizer rubric line for Khorikov's four pillars
   (no persona owns that judgement), and the source bibliography (Khorikov, Meszaros, Fowler, Beck,
   Cooper, Langr/Hunt/Thomas, Myers, Google flaky-test, Hora&Robbes MSR'26, Yuan FSE'24, etc.).
8. `personas/_resolution.md` · UPDATE · Edit — add **§2.1 testing-critic group**: when the change
   adds/modifies test files (path globs: `*test*`, `*spec*`, `tests/`, `__tests__/`, `*.test.*`) or the
   task is test-writing, select from the testing group (cap still 3; default pick = behaviorist +
   assertion-auditor + the cluster the diff most implicates). Note the loader resolves
   `_shared/testing/<id>.md`. Keep production-code critics for non-test changes.
9. `personas/_shared/quality.md` · UPDATE · Edit — **remove** the "tests express behaviour, not
   internals" checklist bullet **and** the "tests that assert internals instead of behaviour" phrase
   in its Mandate. Both must go, or `test-behaviorist` and `quality.md` double-vote one finding.
10. `README.md` + `vault/_moc.md` · UPDATE · Edit — index the testing group under the personas tree.
11. `vault/indications/testing-persona-group.md` · CREATE · Write — capture the convention: testing
    lenses live in `_shared/testing/`, one-failure-cluster-per-persona, mandatory analyzer binding,
    decorrelation boundaries; links [[shared-vs-stack-persona-factoring]], [[confirmed-vs-advisory-findings]].

## Test plan
Repo tests = bats-core, run in Docker (per [[feedback_dockerized_tests]]). New `tests/unit/testing-personas.bats`:
- each of the 6 files exists and has valid frontmatter (`type: persona`, `id:`, `base_agent:`);
- each has the required sections (Mandate · Bound analyzer · Severity rubric · Checklist · Output);
- each declares a non-"none" bound analyzer (enforces the grounding rule);
- `_resolution.md` references the testing group; `quality.md` carries neither the bullet nor the
  Mandate phrase;
- README/MOC reference the group.

## Proposed test backlog

| id | persona | kind | target | intent | priority | disposition |
|----|---------|------|--------|--------|----------|-------------|
| harness-t1 | (grounding) | unit | each persona file | frontmatter + required sections present | must | implement → `testing-personas.bats` tests 33,34 |
| harness-t2 | (grounding) | unit | each persona file | bound analyzer ≠ "none" (grounding rule) | must | implement → test 35 (+ mock-metric test 36) |
| decorr-t1 | (decorrelation) | unit | quality.md | moved bullet absent (no double-vote) | should | implement → test 38 |
| resolve-t1 | (decorrelation) | unit | _resolution.md | testing-group selection rule present + cap honored | should | change → test 37 (asserts §2.1 + path; cap wording, not a count assertion) |
| index-t1 | (grounding) | unit | README + _moc | testing group indexed | nice | change → test 39 (README + indications index; _moc not asserted to keep test stable) |

_Every kept test must run green ≥3× and must fail when its contract is broken. Full offline suite:
47 unit + 50 integration._

## Constraints and deferrals
- **Every persona owns exactly one documented AI-failure cluster.** A seventh lens joins the group
  only when it owns a cluster none of the six already owns.
- **Grounding tiers are uneven.** `test-behaviorist` is gold on JS/TS, structural on PHP/Python and
  advisory on Dart. Each persona spec must declare its per-stack tier, never claim uniform strength.
- **CI cost.** Mutation testing and the N-rerun flakiness check are slow. Each persona that binds one
  gates it to the changed tests or to a nightly run.

## Failure modes
- **`jest --shuffle` does not exist.** Jest 29.5+ randomizes order with `--randomize`; `--shuffle`
  belongs to Vitest. The wrong flag raises no error: the randomized-order rerun stops happening, and
  the JS grounding of `personas/_shared/testing/flakiness-sentinel.md` drops from gold to advisory.

## Refs
- [[shared-vs-stack-persona-factoring]] · [[confirmed-vs-advisory-findings]] · [[ADR-004-generic-packs-specifics-in-indications]]
- [[features/v-team]]
- Process record: `vault/plans/2026-06-19-0954-testing-persona-pack.trail.md`
- Session: [[2026-06-19-0954-testing-persona-pack]] (executes this)
