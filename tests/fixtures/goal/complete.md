---
type: plan
project: fixture
slug: goal-complete
repos: [fixture]
status: proposed
goal_fit: required
tags: [plan, master-plan]
---

# goal-complete — plan

## Task
A three-session master plan whose sessions own every case of its goal. Used by the goal gate tests.

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC1 | WHEN `bin/report.sh --all` runs THE SYSTEM SHALL print one passing line per catalogue case | delivery | command | `checks/sc1.sh` | 0 | | |
| SC2 | WHEN the reader parses a spec THE SYSTEM SHALL keep every column | behaviour | command | `checks/sc2.sh` | 0 | | |

## Sequencing & dependencies
Order: S1, S2, S3.

## Goal fit

| field | value | evidence |
|-------|-------|----------|
| goal | SC1 | `bin/report.sh --all` |
| runtime limit | 2 h | set by the operator |
| runtime estimate | 45 min | 30 cases at 1.5 min each, measured on `docs/timing.md:4` |
| failure paths | 2 | S2 may not parse nested specs, so cases from G-2 fail; `docs/spec.md:12` allows a column the reader drops |
| baseline | | |

## Goal cases

| id | case | count | owner | status |
|----|------|-------|-------|--------|
| G-1 | flat specs | 10 | S2 | todo |
| G-2 | nested specs | 18 | S3 | todo |
| G-3 | signed release check | 2 | operator | todo |

## Sessions

| id | scope | command | status | depends | date | evidence |
|----|-------|---------|--------|---------|------|----------|
| S1 | the spec format | /v-work | done | | 2026-11-08 | `docs/spec.md` |
| S2 | the reader for flat specs | /v-team | todo | S1 | | |
| S3 | the reader for nested specs | /v-team | todo | S1, S2 | | |

## Cross-session contracts

| id | contract | produced by | consumed by | shape |
|----|----------|-------------|-------------|-------|
| C-1 | spec format | S1 | S2, S3 | `docs/spec.md` sections and columns |
| C-2 | flat reader | S2 | S3 | `bin/read.sh <spec>` prints TSV |

## Open & deferred
- needs the operator: sign the release check (G-3).
