---
type: handoff
project: demo
slug: csv-export-S2
plan: @DIR@/plan.md
id: S2
tags: [handoff]
---

# csv-export-S2 — handoff

## Left to do

| # | action | file (exact path) | done when |
|---|--------|-------------------|-----------|
| 1 | build the screen part | /tmp/demo/admin/README.md | the success criterion holds |

## Goal
Session S2 of csv-export: the screen part.

## Next command

cd /tmp/demo/admin && claude --add-dir @DIR@ "/v-work @DIR@/plan.md#S2"

## Success criteria
SC-1 — WHEN an admin clicks Export on the orders page THE SYSTEM SHALL download a CSV of the filtered rows.
