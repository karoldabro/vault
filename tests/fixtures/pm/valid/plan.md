---
type: plan
project: demo
slug: csv-export
repos: [api, admin]
status: approved
tier: medium
process_record: plan.trail.md
tags: [plan, feature-plan]
---

# csv-export — feature plan

## Need
Admins need the filtered order list outside the app.

## Success criteria

| id | criterion | sessions | verdict | evidence |
|----|-----------|----------|---------|----------|
| SC-1 | WHEN an admin clicks Export on the orders page THE SYSTEM SHALL download a CSV of the filtered rows | S1 S2 | | |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| DD-1 | planning done | met | approved |
| DD-2 | code implemented | | |
| DD-3 | code tested | | |
| DD-4 | static analysis passed | | |

## Decisions

| decision | reason | record |
|----------|--------|--------|
| stream the CSV from the api | the admin holds no order data | local |

## Sessions

| id | repo | scope | command | status | depends | req | date | evidence | deviation |
|----|------|-------|---------|--------|---------|-----|------|----------|-----------|
| S1 | /tmp/demo/api | export endpoint | /v-team | todo | | REQ-01 | | | |
| S2 | /tmp/demo/admin | export button | /v-work | todo | S1 | REQ-02 | | | |

## Cross-session contracts

| id | contract | produced by | consumed by | shape |
|----|----------|-------------|-------------|-------|
| C-1 | export endpoint | S1 | S2 | GET /orders/export.csv returns text/csv |

## Risks & rollback
S1 adds one route; revert its commit.
