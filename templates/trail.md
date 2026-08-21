---
type: trail
project: {{project}}
plan: {{plan-slug}}
tags: [trail, record]
---

# {{plan-slug}} — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`plans/{{plan-slug}}.md`, which carries the current truth only.

Nothing in the lifecycle reads this file back — reviewers exchange findings in context, not through
disk. It exists so a decision can be audited months later. Write it, link it, do not print it.
`/v-pm` writes the same record for a feature as `_features/<feature>/planning-session.md`.

## Decisions & trade-offs

<!-- One row per decision that had a real alternative. This is the section anyone actually returns
     to. The chosen option itself lives in the plan; only the cost of choosing it lives here. -->

| decision | alternative rejected | why it lost |
|---|---|---|
|  |  |  |

## Findings & dispositions

<!-- One subsection per round: findings with disposition (applied / deferred / rejected + reason).
     A `confirmed` blocker dispositioned anything other than `applied` is a minority flag and must
     have surfaced to the user at the approval gate. -->

### Round 1

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
|         |    |          |           |       |             |

## Metrics

<!-- Per round: new confirmed blockers · findings-delta · persona overlap · confirmed/advisory ·
     previously-confirmed findings dropped this round (sycophancy flag) · token cost. -->

## Advisory test hints

<!-- Design critics review design, not written tests, so their PROPOSED_TESTS are not authoritative.
     They land here as input; the test-design fan-out reconciles them into the plan's Test backlog,
     which is the only authoritative list. -->

## Rejected / deferred

<!-- Approaches that were live and then replaced, with one line on what killed each, plus research
     that did not survive into the plan. The plan must not mention any of it: this is the only place
     it exists, so the next agent does not spend a session re-evaluating an abandoned path. -->
