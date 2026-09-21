---
type: trail
project: vault
plan: 2026-09-21-0900-architecture-first-planning
tags: [trail, record]
---

# 2026-09-21-0900-architecture-first-planning — process record

Record class. Its contract document is `vault/plans/2026-09-21-0900-architecture-first-planning.md`.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Probe kit in this framework | extend `vault-quality-gates` | that plugin runs at push time against a baseline; probes run while an agent plans and reviews |
| Profile taken from `dod_profile` | new `arch_profile` key | a second key would need its own `gate.sh config` check and can disagree with the first |
| Execute S1 and S2 this session | execute all eight | median clean session touches about 9 files; sessions near 49 dropped work |
| Human view generated from the spec and verified by a gate | agent hand-writes the HTML each time | hand-written views omit diagrams silently and vary per run |

## Findings & dispositions

### Round 1

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| consumer | consumer-1 | BLOCKER | confirmed | spec sections, columns, call form missing | applied: Spec contract, two fixtures |
| consumer | consumer-2 | MAJOR | confirmed | SC-5 greps the word arch | applied: checks assert `arch: ok` |
| consumer | consumer-3 | MAJOR | confirmed | SC-3 does not check row names | applied: checks grep the offending name |
| consumer | consumer-4 | MAJOR | confirmed | profile stored twice | applied: `arch_profile` key, spec profile compared |
| consumer | consumer-5 | MAJOR | advisory | no fallback when publishing fails | applied: S3 fallback to local HTML |
| consumer | consumer-6..9 | MINOR/NIT | mixed | probe ownership, cap row format, path base, DONE status | applied |
| skeptic | skeptic-1 | BLOCKER | confirmed | all repos declare dod_profile code | applied: `arch_profile`, this repo harness |
| skeptic | skeptic-2 | BLOCKER | confirmed | no v-team step runs the gate | applied: W-18, W-19; profiled repo refuses a plan with no spec |
| skeptic | skeptic-3 | MAJOR | confirmed | SC-5 can pass vacuously | applied |
| skeptic | skeptic-4 | MAJOR | confirmed | artifact arrives late | deferred: renderer reads the spec, so S3 follows S2; this session publishes a hand-built page instead |
| skeptic | skeptic-5 | MAJOR | confirmed | review-to-rule may duplicate rule store | applied: D-9 |
| skeptic | skeptic-6, 7 | MAJOR | confirmed | plan cap, no cost ceiling | applied: Scope, D-10 |
| skeptic | skeptic-8, 9 | MINOR | mixed | ADR-030 duplicate, repo without VAULT.md | applied: noted in Open & deferred; second rejected, refused earlier at ANALYZE |
| quality | quality-1..3 | MAJOR | confirmed | is_known_type, type inference, claimed-elsewhere scan | applied: W-15, W-16 |
| quality | quality-4 | MAJOR | confirmed | fixtures against repo convention | applied: two fixtures, defects inline |
| quality | quality-5 | MAJOR | advisory | 200 lines too small | applied: D-11, cap 300 |
| quality | quality-6..12 | MINOR/NIT | mixed | multi-table parse, second profile reader, usage window, verification wording, dead paths, type name | applied |

### Round 2

consumer re-check only; the other two reviewers' concerns were closed by revision and verified by the commands in the plan. Round cap reached; the revision below was not re-reviewed.

| reviewer | ref | severity | grounding | problem | result |
|----------|-----|----------|-----------|---------|--------|
| consumer | consumer-1 | BLOCKER | confirmed | code fixture run against a harness repo fails SC-2 and SC-3 | applied: checks pass `--repo` to a temp repo |
| consumer | consumer-2 | MAJOR | confirmed | three sections lack columns | applied: `commands/_shared/architecture-spec.md` Sections table |
| consumer | consumer-3 | MAJOR | confirmed | help grep already true | applied: greps `gate.sh arch` |
| consumer | consumer-4 | MAJOR | confirmed | "index" appears in the temp file name | applied: neutral names, full message asserted |
| consumer | consumer-5 | MAJOR | confirmed | message text undefined | applied: Messages table |
| consumer | consumer-6 | MAJOR | confirmed | helpers need CR-stripped input, own printer | applied: W-15 |
| consumer | consumer-7, 8 | MAJOR | advisory | vault_key grammar, check precedence | applied: Profile source, Order of checks |
| consumer | consumer-9..12 | MINOR/NIT | mixed | row width, heading form, stale references, padding | applied |

### Diff review

| seat | finding | severity | grounding | what was wrong | outcome |
|------|---------|----------|-----------|----------------|---------|
| quality | Q1 | MAJOR | confirmed | template `arch_spec` inline comment read as part of the value | applied: gate strips a trailing comment; template value empty |
| quality | Q2 | MAJOR | confirmed | no test guards the v-team wiring | applied: three guards in `tests/unit/v-team.bats` |
| quality | Q3, Q4, Q7, Q8, Q9, Q10, Q11 | MINOR | advisory or confirmed | wording, exit 2, message table, placeholder refusal, missing rows | applied |
| quality | Q5 | MINOR | confirmed | row-loop skeleton repeated seven times | deferred: recorded in the plan |
| quality | Q6 | MINOR | advisory | tempdir leak on a second call, implicit global ordering | applied |
| correctness | correctness-1..6 | MINOR, NIT | confirmed | missing option value, arrow types, dash-only rows dropped, unclosed frontmatter, repeated `--repo`, `VAULT.md` directory | applied |

## Metrics

Round 1: 3 reviewers, 5 confirmed BLOCKER or MAJOR from consumer, 2 BLOCKER and 4 MAJOR confirmed from skeptic, 4 MAJOR confirmed from quality. Test design: 3 generators, 22 backlog rows, 13 contract gaps resolved.

## Research that did not enter the plan
- Research reports: `/tmp/claude-1000/-home-kdabrow-workspace-vault/8beafd47-cd78-40af-a2da-112677df5c21/scratchpad/research-ai-slop.md` and `research-probes.md`.
- Evidence for "longer plans reduce rework" is weak; one ablation shows planning mattered for a weak model and was flat on accuracy for strong ones (https://arxiv.org/html/2609.20804, summary only).
