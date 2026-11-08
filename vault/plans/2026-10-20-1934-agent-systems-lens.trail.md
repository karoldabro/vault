---
type: trail
project: vault
plan: 2026-10-20-1934-agent-systems-lens
tags: [trail, record]
---

# 2026-10-20-1934-agent-systems-lens — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`plans/2026-10-20-1934-agent-systems-lens.md`, which carries the current truth only.

## Origin

The operator asked, on 2026-10-20 in a recycling-api session, for research on building custom API agents and for a new critic persona that scopes agent architecture. The motivation was the recycling-api support drafter: a 71-chat replay judged 52% of drafts sendable, and the operator sent 0 of 18 production drafts.

Clarify answers, 2026-10-20: the lens goes in the framework; how-to topics become plugin skills; diagnosing the drafter is a separate follow-up run.

Panel seating: the framework repo declares no persona pack, so `personas/_resolution.md` §1 falls back. The planning group was used instead, because the deliverable is prompts and agent instructions (§2.3 harness trigger). Seated: `planning/harness-engineer`, `consumer`, `planning/codebase-fit`.

## Research

Three researchers ran in parallel on 2026-10-20 and wrote to the session scratchpad. Copies land in `vault/research/v-pm-planning-lenses/agent-systems-{architecture,security,quality}.md` under W13–W15.

| record | sources | unresolved points carried into the plan |
|---|---|---|
| architecture | 40 | multi-agent reviewer context sharing; no measured agent split threshold; retrieval relevance cut-off; prompt registry vs prompts in code; OTel GenAI names unstable; Prism vs `laravel/ai` |
| security | 40 | detectors are never the boundary; human approval counts only when it binds the exact action; GDPR status of embeddings and example stores; OWASP agentic ids from secondary sources only; `laravel/mcp` has one scope |
| quality | 47 | binary vs graded judging; same model as writer, judge and learner; small-set statistics (37/71 has a Wilson 95% interval of 40.7–63.3%); self-critique without external signal |

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| planning-group lens | flat shared lens under `personas/_shared/` | the flat lenses review diffs; this lens reviews architecture, and the planning contract tests already exist |
| one new lens | extend `harness-engineer` | harness-engineer is at its checklist cap and serves developer tooling; product agents need a separate four-concern checklist |
| eight skills | one large skill | a skill loads whole; a single file would load about 1,200 lines for any one concern |
| copy research as records | rewrite research into the lens | the lens has a 150-line cap; the evidence would not fit and would mix record and contract |

## Findings & dispositions

### Round 1

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| consumer | consumer-1 | MAJOR | confirmed | determinism rule made an uncalibrated same-model judge a recommendation | applied: `## Lens severity` names it MAJOR and lists deterministic vs probabilistic controls |
| consumer | consumer-2 | MAJOR | confirmed | W1 gave 80 candidate questions and no rule for choosing 12 | applied: `## Lens checklist` fixes the 12 items with concern and skill |
| consumer | consumer-3 | MAJOR | confirmed | C3 passes on any three findings, not the known judge gap | applied: C3 requires a finding citing `judge_model` or `sendable_score` |
| consumer | consumer-4 | MINOR | confirmed | overlay key and tier unstated | applied: overlay dropped; W18 sets tier medium |
| consumer | consumer-5 | MINOR | advisory | skill marker format undefined | applied: `skill: skills/agent-<name>/SKILL.md` line |
| consumer | consumer-6 | MINOR | confirmed | harness-engineer body not told to hand off | applied: W2c |
| consumer | consumer-7 | NIT | advisory | bare words tool and agent over-trigger | applied: runtime condition in W3 |
| harness-engineer | harness-engineer-1 | MAJOR | confirmed | C3 script counts prose and accepts `none, could not run` | applied: W17 block parser, W24 fixtures |
| harness-engineer | harness-engineer-2 | MAJOR | confirmed | C3 spawn uncapped and does not prove novelty over other lenses | partly applied: one spawn, raw output; novelty baseline rejected, see Rejected; minority flag |
| harness-engineer | harness-engineer-3 | MAJOR | confirmed | trifecta and judge rules would live in three homes | applied: W2a, W2b, W2c; R3 test |
| harness-engineer | harness-engineer-4 | MAJOR | confirmed | api-laravel overlay has no reader on the /v-pm path | applied: overlay dropped; detection examples in the Bound analyzer |
| harness-engineer | harness-engineer-5 | MAJOR | confirmed | link test checks set equality only | applied: per-item skill path, fail fixture |
| harness-engineer | harness-engineer-6 | MINOR | confirmed | trigger overlaps harness-engineer | applied: runtime condition |
| harness-engineer | harness-engineer-7 | MINOR | confirmed | no byte or description cap | applied: 12000 bytes, 300 characters |
| harness-engineer | harness-engineer-8 | MINOR | advisory | eight untested skills with no reader yet | rejected: the operator chose skills; each maps to checklist items and the link test binds them |
| harness-engineer | harness-engineer-9 | MINOR | confirmed | research load row contradicts never-by-agent | applied: load row removed |
| harness-engineer | harness-engineer-10 | MINOR | confirmed | fail partitions had no fixtures | applied: W23, W24 |
| codebase-fit | codebase-fit-1 | MAJOR | confirmed | moved rules stay in the other lens bodies | applied: W2b, W2c |
| codebase-fit | codebase-fit-2 | MAJOR | confirmed | overlay never loads for a planning lens | applied: overlay dropped; `use_shared` entry instead |
| codebase-fit | codebase-fit-3 | MAJOR | confirmed | §2 trigger is a second way to seat a planning lens | partly applied: trigger keyed to runtime; `use_shared` composes the lens in api-laravel, following the group-qualified `business/data-evidence` precedent; round 2 moved the trigger text to §2.3 only |
| codebase-fit | codebase-fit-4 | MINOR | confirmed | research in a second layout, no MOC line | applied: W13–W16 |
| codebase-fit | codebase-fit-5 | MINOR | confirmed | README intro names two kinds | applied: W2a |
| codebase-fit | codebase-fit-6 | MINOR | confirmed | plugin layout test, guide and install.sh miss skills/ | applied: W19, W20, W25 |
| codebase-fit | codebase-fit-7 | NIT | confirmed | release-check fails until the version bump | applied: D4 |

### Round 2

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| consumer | consumer-r2-1 | MAJOR | confirmed | missing measurements and release steps had no severity | applied: `## Lens severity` line |
| consumer | consumer-r2-2 | MINOR | confirmed | BLOCKER vs MAJOR choice and relevance threshold undefined | applied |
| consumer | consumer-r2-3 | MINOR | confirmed | finding granularity and non-goal code scope undefined | applied: `## Lens review rules` |
| consumer | consumer-r2-4 | MAJOR | confirmed | gate calls check scripts with no argument | applied: optional argument with default |
| consumer | consumer-r2-5 | MINOR | confirmed | C3 parser terms undefined | applied: `## C3 parser rules`, fixtures |
| consumer | consumer-r2-6 | NIT | confirmed | trail named the rejected research folder | applied |
| codebase-fit | codebase-fit-r2-1 | MAJOR | confirmed | install.sh change breaks the install idempotence test | applied: W27 |
| codebase-fit | codebase-fit-r2-2 | MINOR | confirmed | §2 bullet applies beyond the pack that composes the lens | applied: §2 line scoped to PROPOSE and to packs listing it |
| codebase-fit | codebase-fit-r2-3 | MINOR | confirmed | security-architect trigger still names AI agents with tools | applied: W3 |
| codebase-fit | codebase-fit-r2-4 | MINOR | confirmed | three files for one lens; false frontmatter claim | partly applied: claim corrected, MOC line for the folder; three files kept with a stated reason |
| codebase-fit | codebase-fit-r2-5 | MINOR | confirmed | INSTALL.md and install.sh header miss skills | applied: W19, W20b |
| codebase-fit | codebase-fit-r2-6 | NIT | confirmed | trail research sentence stale | applied |
| harness-engineer | harness-engineer-r2-1 | MAJOR | confirmed | harness-engineer takes the only medium-tier trigger seat first | applied: agent-systems first; harness trigger narrowed |
| harness-engineer | harness-engineer-r2-2 | MAJOR | confirmed | gate calls check scripts with no argument | applied, same as consumer-r2-4 |
| harness-engineer | harness-engineer-r2-3 | MAJOR | confirmed | one-owner test not decidable; rubrics keep the rules | applied: word-level test over whole files; W2b and W2c reword rubrics |
| harness-engineer | harness-engineer-r2-4 | MAJOR | confirmed | install.bats idempotence breaks | applied: W27 |
| harness-engineer | harness-engineer-r2-5 | MINOR | confirmed | W2b line numbers pointed at the wrong lines | applied: quoted item text |
| harness-engineer | harness-engineer-r2-6 | MINOR | advisory | 150-line cap at risk | applied: URL and skill on one line |
| harness-engineer | harness-engineer-r2-7 | MINOR | confirmed | §2 bullet puts a planning lens on diff review | applied: PROPOSE only |

The review stopped at the round cap of 2. Round 2 raised 7 new confirmed MAJOR findings; all were applied after the round, and no third round reviewed those edits.

### Execute — code review

One reviewer covered the architect, quality and correctness seats in one pass over the diff from `5a8f2fc`.

| id | severity | grounding | issue | disposition |
|----|----------|-----------|-------|-------------|
| dr-1 | MAJOR | confirmed | C3 parser joined lines no deeper than `- id:` to the check field | applied: indent rule, `trailing-prose.md` fixture |
| dr-2 | MAJOR | confirmed | agent-evals score grep also matched retrieval `min_score` | applied |
| dr-3 | MAJOR | confirmed | agent identity stated in two skills | applied: agent-trust-boundaries owns it |
| dr-4 | MINOR | confirmed | example-store admission rule in three skills | applied: agent-self-improvement owns it |
| dr-5 | MINOR | confirmed | paid-call severity clashed between two lenses | applied: security-architect scoped to non-LLM calls |
| dr-6 | MINOR | confirmed | one-owner test banned words, not the rule | applied: phrase check with the harness-engineer exception |
| dr-7 | MINOR | confirmed | three checklist items had no severity; four concerns omitted operations | applied |
| dr-8 | MINOR | confirmed | skills cited lens item numbers | applied: numbers removed |
| dr-9 | MINOR | advisory | framework skill paths unusable from a product repo | applied: skill named by invocable name |
| dr-10 | MINOR | confirmed | product-specific text in framework skills | applied |
| dr-11 | NIT | confirmed | three small rules in two skills each | applied |
| dr-12 | NIT | confirmed | mixed rule format; inverted checklist item 3 | applied |

### Execute — live lens run

The lens reviewed `~/vault/givore/plans/2026-10-19-1055-api-support-drafter-one-rulebook.md` once and wrote `vault/plans/2026-10-20-1934-agent-systems-lens.c3-run.md`: 12 confirmed findings (9 MAJOR, 3 MINOR). `checks/agent-systems-lens-C3.sh` counts 10 with a command or `path:line`, one on the judge.

## Metrics

Round 2: 3 reviewers; 19 findings; 18 confirmed, 1 advisory; 7 confirmed MAJOR, all new.

Round 1: 3 reviewers; 24 findings; 19 confirmed, 5 advisory; 10 confirmed MAJOR. Overlap: the C3 weakness, the overlay reader and the rule ownership were each raised by two or three reviewers.

## Advisory test hints

- consumer-t1, harness-engineer-t2: a checklist item with no skill line fails the link test.
- consumer-t2, harness-engineer-t1: the C3 parser rejects weak fixtures.
- consumer-t3: the rubric names an uncalibrated gating judge under MAJOR.
- harness-engineer-t3: byte and description caps fail on oversize fixtures.
- codebase-fit-t1: `skills/` at the plugin root with descriptions.
- codebase-fit-t2: one lens holds the trifecta and judge items.
- codebase-fit-t3: §2 names no planning id; rejected with codebase-fit-3.

## Rejected / deferred

- Novelty baseline for C3 (harness-engineer-2): running harness-engineer and security-architect on the drafter plan as a baseline costs two more spawns. After W2b and W2c those lenses no longer ask the moved questions, so the baseline would measure the edit, not the lens.
- api-laravel overlay block for agent-systems: no reader on the /v-pm path.
- `vault/research/agent-systems/` folder with its own README: a second research layout.
