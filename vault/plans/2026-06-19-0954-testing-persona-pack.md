---
type: plan
project: vault
slug: testing-persona-pack
status: executed   # proposed | approved | executed | superseded
personas: [vault-degraded-panel]   # repo has no stack pack; panel = research + design critics
rounds: 1
review_rounds: 1
convergence: clean
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

## Converged plan

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
   — lens: **assertion strength & anti-tautology**. Would the test fail if the code were wrong? No
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
   randomized-order rerun ×N (`--order-by=random` / `jest --shuffle` / `pytest-randomly` /
   `--test-randomize-ordering-seed`) + nondeterminism grep; gate to changed tests (CI cost). Owns C7.
6. `personas/_shared/testing/test-harness-critic.md` · CREATE · Write
   — lens: **runnability & framework fluency** (the biggest documented AI failure — 24.8% pass rate).
   Does it compile/run? correct framework idioms & fixture lifecycle? no hallucinated assertion/mock
   APIs? plus a light suite-level **test-level/pyramid sanity** check (the surviving test-strategist
   idea). base_agent: `quality-engineer` (fallback `Explore`). analyzer (GOLD: most objective of all —
   run the test, it runs or it doesn't): execute changed tests + layer-count/duration profile for the
   pyramid sub-check. Owns C8 + light strategy.
7. `personas/_shared/testing/README.md` · CREATE · Write — group index: the six lenses, their
   single-owner failure cluster, decorrelation boundaries (the "owns X, NOT Y → neighbor" table),
   per-stack analyzer overlay table, and the source bibliography (Khorikov, Meszaros, Fowler, Beck,
   Cooper, Langr/Hunt/Thomas, Myers, Google flaky-test, Hora&Robbes MSR'26, Yuan FSE'24, etc.).
8. `personas/_resolution.md` · UPDATE · Edit — add **§2.1 testing-critic group**: when the change
   adds/modifies test files (path globs: `*test*`, `*spec*`, `tests/`, `__tests__/`, `*.test.*`) or the
   task is test-writing, select from the testing group (cap still 3; default pick = behaviorist +
   assertion-auditor + the cluster the diff most implicates). Note the loader resolves
   `_shared/testing/<id>.md`. Keep production-code critics for non-test changes.
9. `personas/_shared/quality.md` · UPDATE · Edit — **remove** the "tests express behaviour, not
   internals" checklist bullet (decorrelation: hand it to `test-behaviorist`; specialist beats
   generalist). Replaces double-voting.
10. `README.md` + `vault/_moc.md` · UPDATE · Edit — index the testing group under the personas tree.
11. `vault/indications/testing-persona-group.md` · CREATE · Write — capture the convention: testing
    lenses live in `_shared/testing/`, one-failure-cluster-per-persona, mandatory analyzer binding,
    decorrelation boundaries; links [[shared-vs-stack-persona-factoring]], [[confirmed-vs-advisory-findings]].

## Test plan
Repo tests = bats-core, run in Docker (per [[feedback_dockerized_tests]]). New `tests/unit/testing-personas.bats`:
- each of the 6 files exists and has valid frontmatter (`type: persona`, `id:`, `base_agent:`);
- each has the required sections (Mandate · Bound analyzer · Severity rubric · Checklist · Output);
- each declares a non-"none" bound analyzer (enforces the grounding rule);
- `_resolution.md` references the testing group; `quality.md` no longer contains the moved bullet;
- README/MOC reference the group.

## Proposed test backlog

| id | persona | kind | target | intent | priority | disposition |
|----|---------|------|--------|--------|----------|-------------|
| harness-t1 | (grounding) | unit | each persona file | frontmatter + required sections present | must | implement → `testing-personas.bats` tests 33,34 |
| harness-t2 | (grounding) | unit | each persona file | bound analyzer ≠ "none" (grounding rule) | must | implement → test 35 (+ mock-metric test 36) |
| decorr-t1 | (decorrelation) | unit | quality.md | moved bullet absent (no double-vote) | should | implement → test 38 |
| resolve-t1 | (decorrelation) | unit | _resolution.md | testing-group selection rule present + cap honored | should | change → test 37 (asserts §2.1 + path; cap wording, not a count assertion) |
| index-t1 | (grounding) | unit | README + _moc | testing group indexed | nice | change → test 39 (README + indications index; _moc not asserted to keep test stable) |

_Triage: 5 proposed · 5 kept (3 implement, 2 change) · 0 skip. Kept tests run green ≥3× and are
characterization checks — each fails if its contract is broken (the file-contract equivalent of killing
a mutant). Full offline suite: 47 unit + 50 integration green._

## Open trade-offs / deferrals
- **6 vs 5 personas (resolved → 6, with a swap).** The decorrelation critic argued for merging to 5
  by dropping `test-strategist`. The AI-failure research independently showed `test-strategist` owns no
  AI-failure cluster — *but* surfaced an unowned, well-documented, highly-groundable failure (C8:
  compilation / framework idioms / hallucinated APIs). Synthesis: **drop standalone `test-strategist`,
  add `test-harness-critic`** (owns C8 + a light pyramid check). Net still six, every persona now owns a
  documented AI-failure cluster. Surfaced for the approval gate.
- **Khorikov "four-pillars" whole-test value judgment** (flagged by research + decorrelation) is *not*
  a standalone persona — it's an integrative trade-off best applied by the synthesizer when reconciling
  findings. Deferred to a shared rubric line in the group README rather than a 7th critic. (advisory)
- **Grounding tiers are uneven.** `test-behaviorist` is gold on JS/TS, structural on PHP/Py, advisory on
  Dart; persona spec must declare this, not claim uniform strength. (applied in design)
- **CI cost**: mutation testing + N-rerun flakiness are slow — personas gate to changed tests / nightly.

## Critique trail

### Round 0 — draft
v0 = six personas: behaviorist | assertion-auditor | edge-case-hunter | test-double-critic |
flakiness-sentinel | **test-strategist**, in `_shared/testing/`. No README, no resolution wiring, no
gap handling.

### Round 1 — findings + dispositions
| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| decorrelation | dc-1 | MAJOR | confirmed | behaviorist × assertion-auditor collapse (both fire on the assert block); anti-tautology stated twice | applied — anti-tautology → auditor; behaviorist = surface/structure only |
| decorrelation | dc-2 | MAJOR | confirmed | behaviorist duplicates quality's "behaviour not internals" bullet → double-vote | applied — remove bullet from quality.md, own in behaviorist (step 9) |
| decorrelation | dc-3 | MAJOR | confirmed | edge-case-hunter × test-strategist overlap on "untested risky branch" | applied — strategist idea demoted; level-check folded into harness-critic, forbidden from naming individual cases |
| decorrelation | dc-4 | MINOR | advisory | edge-case-hunter × skeptic both touch error paths | applied — altitude split documented (skeptic = should-it-exist; hunter = is-it-tested) |
| decorrelation | dc-5 | MAJOR | confirmed | gaps: test-code maintainability + regression-test-for-fix unowned | applied — maintainability → behaviorist; regression-test → edge-case-hunter |
| decorrelation | dc-6 | MAJOR | advisory | recommend merge to 5 (drop strategist) | partially-rejected — strategist dropped, but replaced by harness-critic (see grounding + AI-failure); net 6, each cluster-justified |
| grounding | gr-1 | BLOCKER | confirmed | test-double-critic mostly-advisory without a metric | applied — mandatory thresholded AST mock-density metric; fidelity = advisory |
| grounding | gr-2 | MAJOR | confirmed | test-strategist verdict is contextual opinion; only duration-mislabeling is confirmed | applied — strategist demoted to a sub-check inside harness-critic (run-based grounding) |
| grounding | gr-3 | MAJOR | confirmed | behaviorist grounding uneven across stacks | applied — per-stack tier declaration required in spec |
| grounding | gr-4 | MINOR | confirmed | edge-case-hunter weak on Dart (line-oriented coverage) | applied — pair branch coverage with mutation data; note Dart limit |
| ai-failure | af-1 | BLOCKER | confirmed | C8 (compile/idiom/hallucinated-API; 24.8% pass rate) owned by nobody | applied — new test-harness-critic owns C8 |
| ai-failure | af-2 | MAJOR | confirmed | over-mocking is an empirically-confirmed agent failure (Hora&Robbes MSR'26) | applied — strengthens test-double-critic mandate |
| ai-failure | af-3 | MINOR | confirmed | snapshot-overuse lacks a clear owner | applied — assigned to assertion-auditor (semantic-assertion gap) |
| research | rs-1 | MINOR | advisory | four-pillars whole-test value judgment unowned | deferred — synthesizer rubric line in README, not a persona |

_Metrics: new confirmed blockers: 2 (gr-1, af-1, both resolved) · findings-delta: 14 · persona overlap pairs found: 4 (all decorrelated by boundary wording) · confirmed: 11 / advisory: 3 · panel tokens: ~151k (2 research + 2 critique)._

_Convergence: round cap (`team_max_rounds` default 2) not needed — round 1 added no *unresolved* confirmed blocker; both blockers (grounding mock-metric, missing C8 owner) resolved in synthesis. Stop on no-new-blocking-findings._

### Diff-review round 1 — findings + dispositions (EXECUTE §5.3)
Analyzers first: bats offline suite green (47 unit + 50 integration). Two review critics over the diff.
| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| grounding-accuracy | ga-1 | BLOCKER | confirmed | `jest --shuffle` is a hallucinated flag — Jest uses `--randomize` (29.5+); `--shuffle` is Vitest. Silently degrades the JS gold-standard grounding to advisory | applied — fixed in flakiness-sentinel.md + README overlay; verified via web (jestjs.io/docs/cli) |
| diff-fidelity | fid-1 | MAJOR | confirmed | quality.md *Mandate* still claimed "tests that assert internals instead of behaviour" (only the checklist bullet was moved) → revives the dc-2 double-vote | applied — struck the phrase from quality.md mandate |
| diff-fidelity | fid-2 | MINOR | confirmed | no literal `## Mandate` heading in the 6 testing personas (folded into intro), inconsistent with template + siblings | applied — added `## Mandate` to all 6; bats section-check tightened to require it |
| grounding-accuracy | ga-2 | NIT | advisory | assert-the-mock grep is heuristic; property-test presence is a dep check not coverage | deferred — already scoped as advisory in the persona bodies |

_Metrics: new confirmed blockers: 1 (ga-1, resolved) · MAJOR: 1 (resolved) · findings-delta: 4 · both worst decorrelation pairs re-verified non-contradictory across files · confirmed: 3 / advisory: 1 · review tokens: ~131k. Suite re-run green after fixes. Convergence: clean (no open blockers)._

## Refs
- [[shared-vs-stack-persona-factoring]] · [[confirmed-vs-advisory-findings]] · [[ADR-004-generic-packs-specifics-in-indications]]
- [[features/v-team]]
- Session: [[2026-06-19-0954-testing-persona-pack]] (executes this)
