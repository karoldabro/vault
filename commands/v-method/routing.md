---
type: reference
project: vault
slug: v-method-routing
tags: [reference, methodology, orchestration]
---

# /v-method routing reference

Read once by `commands/v-method.md`. Four tables: which method a task property selects, which seats
each stage holds, which tools prove an implementation, and which prove a cited claim.

**The routing is a heuristic.** No validated instrument turns a task description into a process.
Every candidate is practitioner doctrine, and the two-by-two most often proposed for it was
repudiated by its own author for this use. So each row keys on a property a session can decide from
the task in front of it, the method file records which properties fired, and a later session scores
that record against what actually happened.

## Table 1 — task property to method

One property selects one method, and a task matching several shall get one stage each, in this order.

| task property | method | its artifact | its stopping rule |
|---|---|---|---|
| The problem statement is not written | elicitation, then `/v-pm` | a statement naming who the output is for | the statement exists and names its reader |
| One assumption could invalidate everything | a riskiest-assumption test, then a throwaway probe | a probe answering one question | the assumption is confirmed or refuted; the probe is discarded |
| The cause is unknown and the symptom reproduces | an is / is-not specification | the specification table | one candidate cause explains every `is` and contradicts no critical `is-not` |
| An automatic verifier exists — tests, types, a query | a fixed localise, repair, validate pipeline | a patch and a passing validation run | validation passes, or the attempt budget is spent |
| Half-finished attempts can be scored | branch and evaluate | a scored search tree | a branch reaches the goal score, or the frontier stops improving |
| Information exceeds one context window | one orchestrator with parallel readers | per-reader findings of 1,000 to 2,000 tokens each | every input item carries an identifier in some reader's output |
| One artifact, and conflicting implicit decisions | a single writer with clean-context reviewers | one linear diff plus review findings | no new blocking finding, or the round cap |
| Steps depend on each other over a long horizon | plan, then execute, with a named replan trigger | a plan with named steps | every step done, or the replan trigger fires |
| A wrong direction is expensive to reverse | `/v-team` | the settled plan plus the dissent record | no new blocking finding, or the round cap with open blockers escalated |
| The criteria must be demonstrably met | a goal-question-metric tree, plus a checklist generated from the task statement | the tree, and one checklist per stage | every checklist item passes, each read from a named field |
| The budget is fixed and the scope is not | an appetite in sessions and tokens | a shaped pitch carrying the appetite | the appetite is spent; no extension without a fresh decision |
| Continuing wrongly is expensive | stage gates with teeth | per-stage kill criteria, written before the stage | a kill criterion is observed, or the stage's exit evidence exists |
| The bottleneck sits in one step | name the constraint and cap spend elsewhere | the named constraint and the cap | the constraint moves, then re-identify |
| Choosing between prompts, models or topologies | a factorial run table | factors, levels and the table | the factorial completes and an effect is estimable |

**Rejected routers, so they are not proposed again.** A complexity-domain classifier has no validity
proof and its domain assignment is subjective. A two-by-two on predictability was repudiated by its
author for process selection. An observe-orient-decide-act framing yields nothing checkable. A
competing-hypotheses matrix is not a gate: randomised against analysts it did not beat doing
nothing, and the trained group skipped its steps.

## Table 2 — seats per stage

A seat shall own an affordance or a context slice one worker lacks.
Role labels do jurisdiction work, not competence work. The default three are analyst, implementer
and tester, and the analyst seat carries most of the measured gain.

| stage | seats | the affordance each owns |
|---|---|---|
| understand | `requirements-analyst`, `personas/_shared/consumer.md` | the analyst writes the specification; consumer produces one real output from the text its receiver gets |
| plan | the pack architect, the one lens the task's keywords trigger, `personas/_shared/skeptic.md` on high stakes | each holds a different analyzer, so each finding rests on evidence the others lacked |
| execute | one writer, as the architect's `base_agent` | it holds the diff; a second writer resolves the same implicit decision a second way |
| verify | `personas/_shared/correctness.md`, the group at `personas/_shared/testing/` | tests and analyzers — evidence the writer did not hold |

**Size.** Three seats by default, five the ceiling, sized by a pilot at five or fewer before any
wider fan-out. Past that point added members share evidence sources, and aggregation amplifies a
shared error rather than cancelling it.

**Cost.** A subagent fan-out runs about four times a single worker's tokens, and a many-seat panel
about fifteen. At an equalised thinking budget one worker matches or beats a team on multi-hop work,
so the fan-out buys context isolation and tool asymmetry; headcount alone buys nothing.

## Table 3 — tools that prove an implementation

Ordered by leverage per hour of setup. Each shall be cited with the defect class it uniquely catches.

| tool | the defect it uniquely catches | cost |
|---|---|---|
| `diff-cover --fail-under` | a changed line no test executes | the cheapest hard gate available |
| `osv-scanner`, `npm audit`, `pip-audit` | a new dependency carrying a published advisory | zero setup |
| `tsc --noEmit`, `mypy`, `phpstan` | every call site inconsistent with a changed signature, repo-wide | free on a typed repo |
| `go test -race`, ASan, TSan, UBSan | a data race or memory error on tests that already pass | one compile flag |
| `mutmut`, `stryker`, PIT, scoped to the diff | a test that executes a line and asserts nothing | diff-scoped only; a whole-repo run is too slow to finish |
| OpenTelemetry in-memory span assertions | an N+1 query, a retry that stays idle, a cache that stays cold | needs instrumentation; the highest-leverage untapped check |
| a two-run metamorphic assertion | a wrong result where nobody knows the right answer | an ordinary test; inventing the relation is the work |
| `hypothesis`, `fast-check` | boundary and degenerate inputs nobody enumerated | authoring the invariant is the cost |
| `semgrep --config auto --error` | mechanical defect patterns | held to one wrong finding in ten, per `vault/check-budget.md` |
| `rr replay`, `vcrpy`, a Playwright trace | a failure that does not reproduce | Linux and x86 only |

**Diff-scoped mutation carries a stated ceiling.** Across 357 real faults in five Java programs, 73%
coupled to at least one mutant and 27% to none. It measures whether a test would catch a defect, not
whether the code is right.

## Table 4 — tools that prove a cited claim

Each is one command, and each shall carry its stated limit wherever it is cited.

| signal | command | what it does not prove |
|---|---|---|
| the cited work exists and is not retracted | `curl -s 'https://api.openalex.org/works/doi:<DOI>?select=title,is_retracted'` | that it says what was claimed |
| the maintainer deprecated it | `curl -s https://registry.npmjs.org/<pkg>/latest \| jq -r .deprecated` | that the named replacement is right |
| the runtime is past end of life | `curl -s https://endoflife.date/api/<product>.json` | vendor extended support |
| the standard is superseded | `curl -s https://www.rfc-editor.org/rfc/rfc<N>.json \| jq .obsoleted_by` | W3C, ECMA and ISO carry no equivalent field |
| an advisory is open | `curl -s -X POST -d '{"package":{"name":"<p>","ecosystem":"npm"}}' https://api.osv.dev/v1/query` | reachability; no advisory is not safety |
| what the page said when it was cited | `curl -s 'https://web.archive.org/cdx/search/cdx?url=<u>&output=json&filter=statuscode:200'` | uncrawled and JavaScript-rendered pages |
| the claimed wording is on the page | `curl -sL <url> \| strip-tags \| grep -i -C2 "<phrase>"` | meaning, context, inversion; a miss proves nothing |
| the sentence is entailed by its source | `minicheck` run locally | anything outside the document supplied to it |

**Four signals ship nothing, and the method file says so rather than implying a check exists.**
Source independence for blogs and documentation has no tool: the published algorithms need a whole
citation graph. Scoring a source as machine-generated ships nothing, because all fourteen detectors
tested scored under 80% and a false positive rejects a correct human source. One consultancy's
technology radar has no machine-readable dataset. A public fact-check API refuses unregistered
callers.

**Adoption volume is not currency.** One formally deprecated package draws over fifty million
downloads a month and last released in 2020. A standing signal is advisory evidence a reviewer
interprets, and the method file records it as advisory.

**A citation count names the API that produced it.** Three bibliographic services returned 465, 602
and 676 citations for one paper on one day.

## Refs

- `vault/plans/2026-09-13-1355-v-method.brief.md` — the design these tables came from, with the source behind each row.
- `vault/research/llm-collaboration-patterns.md` — the living catalog for orchestration and seat-sizing evidence.
- `vault/check-budget.md` — the one-in-ten line every tool above is held to.
