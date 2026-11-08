---
type: plan
project: fixture
slug: e2e-split
repos: [/fixture/app]
status: approved
tier: small
goal_fit: required
tags: [plan, feature-plan]
---

# e2e-split — feature plan

## Success criteria

| id | criterion | sessions | verdict | evidence |
|----|-----------|----------|---------|----------|
| SC1 | WHEN `tool/e2e.sh --all` runs THE SYSTEM SHALL pass every journey | S1, S2, S3 | | |

## Goal fit

| field | value | evidence |
|-------|-------|----------|
| goal | SC1 | `tool/e2e.sh --all` |
| runtime limit | 30 min | set by the operator |
| runtime estimate | 12 min | three journeys at 4 min each |
| failure paths | 2 | S2 depends on a role the account may lack; S3 needs a screen `docs/screens.md:3` lists as optional |
| baseline | | |

## Goal cases

| id | case | count | owner | status |
|----|------|-------|-------|--------|
| G-1 | value bid journey | 1 | S1 | todo |
| G-2 | dynamic screen journey | 1 | S2 | todo |
| G-3 | feed journeys | 2 | S3 | todo |

## Sessions

| id | repo | scope | command | status | depends | req | date | evidence | deviation |
|----|------|-------|---------|--------|---------|-----|------|----------|-----------|
| S1 | /fixture/app | the value bid journey | /v-work | todo | | | | | |
| S2 | /fixture/app | the dynamic screen journey | /v-work | todo | | | | | |
| S3 | /fixture/app | created data for the feed journeys | /v-work | todo | | | | | |

## Cross-session contracts

| id | contract | produced by | consumed by | shape |
|----|----------|-------------|-------------|-------|
