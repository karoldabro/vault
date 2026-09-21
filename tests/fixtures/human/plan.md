---
type: plan
project: fixture
slug: fixture
arch_spec: ../arch/code-complete.arch.md
human_plan: https://claude.ai/artifact/LHVhsU2fsQWNFpJTH6NKuC
---

# fixture — plan

## Task
Session S3 fixture.

Second paragraph with `code` and a second line.

## Open & deferred
- needs the operator: approve the fixture.
- deferred: nothing else.

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN it runs THE SYSTEM SHALL render | functional | command | `checks/x.sh` | exit 0 | | |

## Decisions

| decision | reason | record |
|----------|--------|--------|
| D-1 A script renders the page | a function of the plan cannot omit a diagram | local |

## Sessions

| id | scope | command | status | depends | date | evidence |
|----|-------|---------|--------|---------|------|----------|
| S1 | first | /v-work | done | | 2026-09-21 | |
| S2 | second | /v-team | done | S1 | 2026-09-21 | |
| S3 | third | /v-team | todo | S1, S2 | 2026-09-21 | |

## Cross-session contracts

| id | contract | produced by | consumed by | shape |
|----|----------|-------------|-------------|-------|
| C-1 | first output | S1 | S2, S3 | `bin/first.sh` prints one line |
| C-2 | second output | S2 | S3 | `bin/second.sh` prints one line |
