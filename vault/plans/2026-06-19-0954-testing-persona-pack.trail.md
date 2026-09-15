---
type: trail
project: vault
plan: 2026-06-19-0954-testing-persona-pack
personas: [vault-degraded-panel]   # repo has no stack pack; panel = research + design critics
rounds: 1
review_rounds: 1
convergence: clean
tags: [trail, record]
---

# 2026-06-19-0954-testing-persona-pack — process record

Contract document: `vault/plans/2026-06-19-0954-testing-persona-pack.md`. That file carries the
current truth; this one carries how it was reached.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Six personas, `test-harness-critic` among them | Five personas, `test-strategist` dropped and not replaced | C8 (compilation, framework idioms, hallucinated APIs) would have stayed unowned |
| Group the lenses under `personas/_shared/testing/` | Six more files flat in `personas/_shared/` | Six related files clutter the flat directory |
| Four-pillars judgement is a README rubric line | A seventh persona owning it | It is an integrative trade-off the synthesizer applies, not a single lens |
| `test-behaviorist` owns "behaviour not internals" | `personas/_shared/quality.md` keeps its bullet | Specialist beats generalist, and two owners double-vote |

## Findings & dispositions

### Round 0 — draft

v0 was six personas: behaviorist, assertion-auditor, edge-case-hunter, test-double-critic,
flakiness-sentinel and `test-strategist`, in `_shared/testing/`. It had no README, no resolution
wiring and no gap handling.

### Round 1 — design panel

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

### Diff-review round 1 — EXECUTE §5.3

Analyzers ran first: the bats offline suite was green at 47 unit + 50 integration. Two review
critics then read the diff.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| grounding-accuracy | ga-1 | BLOCKER | confirmed | `jest --shuffle` is a hallucinated flag — Jest uses `--randomize` (29.5+); `--shuffle` is Vitest. Silently degrades the JS gold-standard grounding to advisory | applied — fixed in flakiness-sentinel.md + README overlay; verified via web (jestjs.io/docs/cli) |
| diff-fidelity | fid-1 | MAJOR | confirmed | quality.md *Mandate* still claimed "tests that assert internals instead of behaviour" (only the checklist bullet was moved) → revives the dc-2 double-vote | applied — struck the phrase from quality.md mandate |
| diff-fidelity | fid-2 | MINOR | confirmed | no literal `## Mandate` heading in the 6 testing personas (folded into intro), inconsistent with template + siblings | applied — added `## Mandate` to all 6; bats section-check tightened to require it |
| grounding-accuracy | ga-2 | NIT | advisory | assert-the-mock grep is heuristic; property-test presence is a dep check not coverage | deferred — already scoped as advisory in the persona bodies |

## Metrics

| round | new confirmed blockers | findings | confirmed / advisory | overlap pairs | tokens |
|---|---|---|---|---|---|
| 1 — design panel | 2 — gr-1 and af-1, both resolved in synthesis | 14 | 11 / 3 | 4, all decorrelated by boundary wording | ~151k (2 research + 2 critique) |
| diff-review 1 | 1 — ga-1, resolved; 1 MAJOR resolved | 4 | 3 / 1 | the 2 worst pairs re-verified non-contradictory across files | ~131k |

Convergence after round 1: the cap (`team_max_rounds`, default 2) was not reached. Round 1 added no
unresolved confirmed blocker, so the panel stopped on no-new-blocking-findings.

Convergence after diff-review: clean, no open blockers. The suite was re-run green after the fixes.

## Test triage

5 tests proposed, 5 kept — 3 implemented as written, 2 changed. None skipped.

## Rejected / deferred

| approach | what killed it |
|---|---|
| `test-strategist` as a standalone persona | It owns no documented AI-failure cluster, and its verdict is contextual opinion rather than a confirmed finding. Its level-check survives as a sub-check inside `test-harness-critic` |
| Merging the group down to five personas | Dropping `test-strategist` left C8 unowned; the slot went to `test-harness-critic` instead |
| A seventh persona for Khorikov's four pillars | A whole-test value judgement is integrative; the synthesizer applies it from a README rubric line |
