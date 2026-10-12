---
type: trail
project: vault
plan: v-pm-planning-loop
tags: [trail, record]
---

# v-pm-planning-loop — process record

Record class. Its contract document is `vault/plans/2026-10-12-0944-v-pm-planning-loop.md`.

## Research

Seven research notes, one per planning lens, written to the session scratchpad and folded into the
lens files in S1: solution architect (SEI ATAM, arc42, Google design docs, Fairbanks, ADR practice),
codebase-fit and lazy-dev (McKinley, Fowler YAGNI, Beck, Metz, Cox, OpenSSF Scorecard), future-scope
(Bezos one-way doors, Fowler YAGNI and design stamina, evolutionary architecture), system-integration
(Pact, parallel change, Google AIP-180, Stripe idempotency and webhooks, outbox, saga), security
architect (OWASP A04, ASVS V1, API Top 10, LLM Top 10, STRIDE, LINDDUN), harness engineer (Anthropic
agent and context-engineering posts, MAST taxonomy, 12-factor agents), delivery planner (walking
skeleton, Shape Up, SPIDR, parallel change, Anthropic long-running agents, METR time horizons).

Unverified in the research: Richards/Ford full expectation list, ISO 42010 wording, retrofit-cost
multipliers (vendor figures only), ASVS v5 numbering, the ~9 and ~49 file calibration (framework
measurement, not a public source).

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| D-1 parallel panel | keep the sequential four-stage pipeline | each stage anchored on the previous one; reviewers were not independent |
| D-2 drop business and product-owner seats | keep them beside the planning lenses | intake elicitation already writes requirements; seat cost on every run |
| D-7 brief as a handoff instance | a new brief template and doc-lint type | the handoff shape already holds every brief section |
| D-9 readiness from `depends` only | readiness from contract rows, as `lib/master-check.sh` does | two rules disagreed; `check` now forces the two sets equal |
| D-9 waves derived from `depends` | an explicit `wave` column | a second source of order drifts from `depends` |
| D-11 move Step 0 to `commands/_shared/` | a second pickup file beside `00-feature-pickup.md` | two files would resolve the same feature |
| D-13 operator-confirmed conversion of legacy shards | migrate all 14 workspaces | shard shapes differ; a blind cross-vault rewrite of live workspaces |
| D-16 delete `planning-session.md` | keep it beside the trail | it restated the trail's findings and decisions |
| `templates/feature-plan.md` | instantiate `templates/plan.md` plus `templates/master-plan.md` | `templates/plan.md` carries execution gates a planning document cannot fill |

## Findings & dispositions

### Round 1

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| consumer | cons-1 | BLOCKER | confirmed | a pasted `/v-work` prompt cannot reach the brief or set `session_of` | applied: D-10 session-pickup module, W-31 to W-34 |
| consumer | cons-2 | MAJOR | confirmed | prompt format contradicts itself; a `cd` inside a session moves nothing | applied: D-9 shell run line |
| consumer | cons-3 | MAJOR | confirmed | close writes into another repo; same-wave sessions race | applied: D-12 |
| consumer | cons-4 | MAJOR | confirmed | no behaviour for a row already running or blocked | applied: D-8 `claim`, E-3 |
| consumer | cons-5 | MINOR | confirmed | synthesizer may not enforce grounding | applied: D-3 rule in the lens Output, E-5 |
| consumer | cons-6 | MINOR | confirmed | spec lacked `order` | applied: spec regenerated |
| consumer | cons-7 | MINOR | confirmed | "start from prompts" offered with no prompts | applied: option removed |
| skeptic | skep-1 | MAJOR | confirmed | live shard rows stop closing | applied: D-13 shard branch kept |
| skeptic | skep-2 | MAJOR | confirmed | up-front roadmap returns with no re-split | applied: D-11 session may amend and append; deviations shown at pickup |
| skeptic | skep-3 | MAJOR | confirmed | `session_of` unenforced; cross-repo stage impossible | applied: D-10, D-12, E-3 |
| skeptic | skep-4 | MAJOR | confirmed | research only in scratchpad | applied: copied to `vault/research/v-pm-planning-lenses/` |
| skeptic | skep-5 | MAJOR | confirmed | scale tier had no thresholds | applied: D-4 thresholds |
| skeptic | skep-6 | MINOR | confirmed | panel larger than `/v-team` with no measured gain | applied: caps 3, 4, 5; triggered seats |
| skeptic | skep-7 | MINOR | advisory | URL grounding is self-report | applied: D-3 URL alone is advisory |
| skeptic | skep-8 | MINOR | confirmed | wrong workspace count; `sessions/` collision; own table lacked `repo` | applied: 14; `briefs/`; `repo` column |
| lazy-dev | lazy-1 | MAJOR | confirmed | `templates/pm/plan.md` duplicates `templates/plan.md` + `master-plan.md` | rejected: `templates/plan.md` carries execution gates a planning document cannot fill; Sessions rules still point to `master-plan.md`; options and research moved to the trail |
| lazy-dev | lazy-2 | MAJOR | confirmed | second table parser | applied: D-8 sources `bin/gate.sh` and `lib/master-check.sh` |
| lazy-dev | lazy-3 | MAJOR | confirmed | `prompt` and `next --repo` unneeded | applied: dropped; `order` marks runnable |
| lazy-dev | lazy-4 | MAJOR | confirmed | 7 reviewers breaks the hard max 5; second key family | applied: D-4 reuses `team_max_*` |
| lazy-dev | lazy-5 | MAJOR | confirmed | lenses overlap shared personas | applied: D-2 thin lenses, "not mine" column |
| lazy-dev | lazy-6 | MAJOR | confirmed | S4 over the ~15 file split threshold | applied: templates and checks moved to S5 |
| lazy-dev | lazy-7 | MAJOR | confirmed | deleting `(f3)` drops the sizing rules | applied: D-14 |
| lazy-dev | lazy-8 | MINOR | confirmed | brief repeats the handoff format | applied: W-14 follows `templates/handoff.md` names |
| architect | arch-1 | MAJOR | confirmed | parallel closes race on one file in another repo | applied: D-12 |
| architect | arch-2 | MAJOR | confirmed | ADR-033 under-names what it supersedes | applied: D-20 |
| architect | arch-3 | MAJOR | confirmed | check ran after approval and never for single-repo | applied: E-1, D-17 |
| architect | arch-4 | MAJOR | confirmed | the loop hard-codes `/v-team` values | applied: D-1 parameter table, W-24 |
| architect | arch-5 | MAJOR | confirmed | two live features cannot close | applied: D-13 |
| architect | arch-6 | MAJOR | confirmed | four readers had no work item | applied: W-41, W-49, W-52; SC-4 grep widened |
| architect | arch-7 | MINOR | confirmed | single-repo feature lookup only in `_features` | applied: D-10 resolver order |
| architect | arch-8 | MINOR | confirmed | `~` paths not expanded | applied: absolute `repo` cells; script expands `~` |
| architect | arch-9 | MINOR | confirmed | untyped brief linted as a session record | applied: `type: session-brief`, W-18 |
| architect | arch-10 | MINOR | confirmed | spec behind the plan | applied: spec regenerated |

The operator added two requirements during round 1. Each session names its repo and run order (D-6, D-8, D-9). Planning is refused without operator success criteria, and four default done lines apply (D-18, D-19).

### Round 2

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| consumer | cons2-1 | MAJOR | confirmed | row set `done` before the code commit exists | applied: D-13 step 5.1a after 5.1 |
| consumer | cons2-2 | MAJOR | confirmed | vault-sync exit 4 and 5 undefined; unlocked claim race | applied: D-12 per-exit branches; `flock` in `set` |
| consumer | cons2-3 | MAJOR | confirmed | master criteria have no grader | applied: D-11 copies reached criteria; D-13 writes verdicts back; D-19 status fills DD lines |
| consumer | cons2-4 | MAJOR | confirmed | elicitation module contradicts the refusal | applied: D-18, W-22 |
| consumer | cons2-5 | MINOR | confirmed | Step 0 not in the task list; refused claim undefined | applied: D-11 task 0, refusal ends the session |
| consumer | cons2-6 | MINOR | advisory | bare `/v-work` in a quoted prompt unverified | applied: SC-7 observed check; `--add-dir` in D-10 |
| skeptic | skep2-1 | MAJOR | confirmed | two homes for the success target | applied: D-18 single home |
| skeptic | skep2-2 | MAJOR | confirmed | DD states cannot be met at planning time | applied: D-19 checks presence, not state |
| skeptic | skep2-3 | MAJOR | confirmed | "stop the close" breaks the sync contract | applied: D-12 never halts |
| skeptic | skep2-4 | MAJOR | confirmed | legacy inventory wrong; shapes differ | applied: rescanned; D-13 operator-confirmed mapping; legacy readers exempt in SC-4 |
| skeptic | skep2-5 | MINOR | confirmed | three grader lines pass on today's tree | applied: graders grep new-only strings; SC-5 checks headings |
| skeptic | skep2-6 | MINOR | confirmed | `dropped` dependency undefined; own table lacked columns | applied: D-9 `blocked`; columns added |
| architect | arch2-1 | MAJOR | confirmed | two readiness rules | applied: D-9 |
| architect | arch2-2 | MAJOR | confirmed | claim never published; no release | applied: D-11 writes through D-12; D-14 release |
| architect | arch2-3 | MAJOR | confirmed | loop couplings beyond the parameter table | applied: D-1 names the trail only; no `(f2)` for `/v-pm`; cap precedence in D-4 |
| architect | arch2-4 | MAJOR | confirmed | tracker resolution written in five readers | applied: D-11 one resolver; W-39 references; W-14 columns in `master-plan.md` |
| architect | arch2-5 | MAJOR | confirmed | ADR-014 clause unnamed; second DoD home | applied: D-20; D-19 references B/F lines |
| architect | arch2-6 | MINOR | confirmed | spec and trail behind the plan | applied: both regenerated |
| lazy-dev | lazy2-1 | MAJOR | confirmed | brief template duplicates the handoff | applied: D-7 |
| lazy-dev | lazy2-2 | MAJOR | confirmed | second Step 0 file | applied: D-11 `git mv` |
| lazy-dev | lazy2-3 | MINOR | confirmed | `claim` repeats a gate | applied: replaced by `order` plus `set` |
| lazy-dev | lazy2-4 | MAJOR | confirmed | parameter table rows bind identical values | applied: D-1 one sentence; per-run caps |
| lazy-dev | lazy2-5 | MAJOR | confirmed | DD lines restate the DoD module | applied: D-19 references |
| lazy-dev | lazy2-6 | MINOR | confirmed | `fill.sh` wraps a sed | applied: variants built inline |

## Metrics

| round | reviewers | findings | confirmed must-fix | applied | rejected |
|-------|-----------|----------|--------------------|---------|----------|
| 1 | 4 | 33 | 1 BLOCKER, 19 MAJOR | 32 | 1 |
| 2 | 4 | 24 | 16 MAJOR | 24 | 0 |

Round cap reached with round-2 fixes applied and not re-reviewed.
