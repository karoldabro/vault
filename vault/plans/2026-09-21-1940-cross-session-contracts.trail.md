---
type: trail
project: vault
plan: 2026-09-21-1940-cross-session-contracts
tags: [trail, record]
---

# 2026-09-21-1940-cross-session-contracts — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`plans/2026-09-21-1940-cross-session-contracts.md`, which carries the current truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| detect a master plan by its `## Sessions` table | a `master-plan` tag in `tags:` | the tag can disagree with the file, and the table is what the gate reads |
| dependency source is the `depends` column only | the column plus a regex over Sequencing prose | prose repeats the column and fails on rewording |
| sibling `templates/master-plan.md` | sections inside `templates/plan.md` | about 40 unused comment lines in every ordinary plan |
| split the `/v-pm` files into S12 | one session of about 23 paths | past the ~15 at which sessions drop work |
| E-3 becomes HALF-BUILT | ENFORCED | no hook fails without a document |

## Findings & dispositions

### Round 1

Three reviewers (architect, consumer, skeptic) and one reuse auditor ran. All confirmed MAJOR findings were applied; the second round was skipped for cost.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| architect | architect-1 | MAJOR | confirmed | one process substitution is read once, so CRLF would miss the second table | applied: a fresh substitution per helper call |
| architect | architect-2 | MAJOR | confirmed | `all --repo` handling of `cmd_master` unstated | applied: one argument, no `--repo`, bats case |
| architect | architect-4, -5 | MAJOR, MINOR | confirmed | later tables and wrong-width rows read as rows | applied: row-width refusal, no `## ` comment line |
| architect | architect-3, -6, -7, -8 | MINOR, NIT | mixed | copied printer, reverse-direction contracts, Sequencing prose, rule homes | applied: printer note, sentence list; reverse direction stays deferred |
| consumer | consumer-1 | MAJOR | confirmed | refusal did not say what the row contains | applied: refusal names the row and the condition for dropping |
| consumer | consumer-2 | MAJOR | confirmed | shard column edit unspecified | applied: insert `depends` after `status` |
| consumer | consumer-3 | MAJOR | confirmed | nothing writes `session_of` | applied: step (a) reads the master path |
| consumer | consumer-4 | MAJOR | confirmed | nothing writes `done` | applied: lifecycle row, refusal fix, close duty to S12 |
| consumer | consumer-5, -6 | MINOR | mixed | presence proof only, vague split trigger | applied: E-1 wording, checkable trigger |
| skeptic | skeptic-1 | MAJOR | confirmed | master page goes stale and `human-SC-9.sh` fails | applied: W-20, same commit |
| skeptic | skeptic-2 | MAJOR | confirmed | human fixture reads as a master | applied: W-19 |
| skeptic | skeptic-3 | MAJOR | confirmed | `## Sessions` also names bullet lists | applied: detection needs a table with `id` and `status`; T-3 |
| skeptic | skeptic-4 to -8 | MINOR, NIT | advisory | typo heading, reverse direction, `dropped`, recount, graders | applied where cheap; typo heading and reverse direction recorded as limits |

### Diff review

Correctness, consumer and architect reviewers ran one round on the diff.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| architect | A-1 | MAJOR | confirmed | six seeded mutants survived every grader | applied: cases in `gate.bats`, `checks/master-SC-2.sh` and `-3.sh`; all six now fail a grader |
| architect | A-2 to A-6 | MINOR | confirmed | copied printer and path rule, repeated reads, two unrelated modified files, 6 lines of headroom | deferred: recorded in Open & deferred; unrelated files stay unstaged |
| correctness | F1 | MAJOR | confirmed | a Sessions table with no `status` or `id` column passed silently | applied: any table under `## Sessions` is checked, and a missing column is refused |
| correctness | F2, F4 | MINOR | confirmed | duplicate ids were last-wins in the ordering check, self-dependency gave an odd fix | applied: first row wins, `depends on itself` refusal |
| correctness | F3, F5, F6 | MINOR, NIT | confirmed | placeholder tokens, fenced tables, cycles | applied for the token message; fences and cycles recorded as limits |
| consumer | F1 to F3 | MINOR, NIT | confirmed | blank template passes, separator row, wording | applied: step wording; blank-template limit recorded |

## Metrics

## Advisory test hints

## Rejected / deferred
