---
type: trail
project: vault
plan: 2026-09-21-2040-pm-shard-contracts
tags: [trail, record]
---

# 2026-09-21-2040-pm-shard-contracts — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`plans/2026-09-21-2040-pm-shard-contracts.md`, which carries the current truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| close-duty bullet in `commands/v-work/steps/05-commit-capture.md` | a new row F7 in `commands/_shared/definition-of-done.md` | the F table applies to feature shard rows, and the master-plan row is not one |
| the status step checks open shards only | every shard | a finished feature needs no further reading, by the existing S.2 rule |

## Findings & dispositions

### Round 1

Two reviewers (architect, consumer) ran. All confirmed MAJOR findings were applied. The plan-time probe block held no rows, so no auditor started.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| consumer | consumer-1 | MAJOR | confirmed | the close bullet named no file, row or evidence that exists at step 5.0 | applied: PS-4 names the file before `#`, the row after it, and the verdict result as evidence |
| consumer | consumer-2 | MAJOR | confirmed | the status step gave no command form, filtering or digest row | applied: PS-3 literal command, filtering and placement |
| consumer | consumer-3 | MAJOR | confirmed | every legacy shard would print noise nobody must act on | applied: one line that names the shard's `/v-team` session as the actor |
| consumer | consumer-4, -5, -6 | MINOR, NIT | confirmed | count words, blank example row, falsifier of the close bullet | applied: PS-1, PS-2, PS-4 |
| architect | architect-1 to -6 | MINOR, NIT | confirmed | count words, duplicated rules, duplicated procedure, grader robustness, first assertion, wording of the bullet | applied: PS-1, PS-2, W-1, T-5, PS-4 |

### Diff review

Correctness and consumer reviewers ran one round on the diff. No BLOCKER or MAJOR.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| correctness | F1 | MINOR | confirmed | the `three` guard matched old text | applied: distinctive strings, fixed-string grep |
| correctness | F3 | MINOR | reasoned | step (f3) inserted `depends` unconditionally | applied: `when the header lacks it` |
| correctness | F4 | NIT | confirmed | grader inserters tied to separator width | applied: the grader asserts the inserted rows |
| correctness | F2, F5 | MINOR, NIT | mixed | 181 pin depends on the tree; legacy blank-row clause | recorded: same pin as S5 and S6 |
| consumer | F1, F2 | MINOR, NIT | mixed | literal placeholders pass; sample wording | recorded in Open & deferred |

## Metrics

## Advisory test hints

## Rejected / deferred
