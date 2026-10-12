---
type: handoff
project: demo
slug: csv-export-S1
plan: @DIR@/plan.md
id: S1
tags: [handoff]
---

# csv-export-S1 — handoff

## Left to do

| # | action | file (exact path) | done when |
|---|--------|-------------------|-----------|
| 1 | build the core part | /tmp/demo/api/README.md | the success criterion holds |

## Goal
Session S1 of csv-export: the core part.

## Next command

cd /tmp/demo/api && claude --add-dir @DIR@ "/v-team @DIR@/plan.md#S1"

## Success criteria
SC-1 — WHEN an admin clicks Export on the orders page THE SYSTEM SHALL download a CSV of the filtered rows.
