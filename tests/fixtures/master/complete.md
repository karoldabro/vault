---
type: plan
project: fixture
slug: master-complete
repos: [fixture]
status: proposed
tags: [plan, master-plan]
---

# master-complete — plan

## Task
A four-session master plan used by the master gate tests.

## Sessions

| id | scope | command | status | depends | date | evidence |
|----|-------|---------|--------|---------|------|----------|
| S1 | the spec format | /v-work | done | | 2026-09-21 | `docs/spec.md` |
| S2 | the renderer | /v-team | done | S1 | 2026-09-21 | `bin/render.sh` |
| S3 | the reader | /v-team | todo | S1, S2 | 2026-09-21 | |
| S4 | the report | /v-do | todo | S3 | 2026-09-21 | |

## Sequencing & dependencies
Order: S1, S2, S3, S4. S4 waits for the release of the reader.

## Cross-session contracts

| id | contract | produced by | consumed by | shape |
|----|----------|-------------|-------------|-------|
| C-1 | spec format | S1 | S2, S3 | `docs/spec.md` sections and columns |
| C-2 | rendered page | S2 | S3 | `bin/render.sh <spec>` writes `<spec>.html` |
| C-3 | reader output | S3 | S4 | TSV `id status`, exit 0 clean |

## Refs
- `docs/spec.md`: the format S1 fixes.
