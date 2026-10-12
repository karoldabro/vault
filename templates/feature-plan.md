---
type: plan
project: {{project}}
slug: {{slug}}
repos: [{{repos}}]                   # every repo a session runs in
status: proposed                     # proposed | approved | executed
tier: {{tier}}                       # small | medium | large — personas/_shared/planning/README.md
process_record: plan.trail.md        # findings, options considered, research
tags: [plan, feature-plan]
---

# {{slug}} — feature plan

<!-- Written by /v-pm, read by every session the plan starts. Contract class: current truth only;
     how the plan was reached goes to plan.trail.md. `bin/pm-plan.sh check plan.md` refuses this file
     until every table below is filled. Each session has one brief in briefs/<id>-<slug>.md, an
     instance of templates/handoff.md with the keys `plan` (absolute path to this file) and `id`. -->

## Need
<!-- One sentence: the problem, not the requested solution. The business rules live in
     requirements.md; this section links it and restates none of it. -->

## Open & deferred
<!-- The only place open work lives. Same status words as templates/plan.md. -->

## Success criteria
<!-- Stated by the operator; /v-pm refuses to plan without at least one row
     (commands/v-pm/steps/01-intake.md). Write each as WHEN <trigger> THE SYSTEM SHALL <observable>.
     This is the single home of the feature's target; requirements.md references it.
     `sessions` names the Sessions ids that reach the criterion. `check` refuses a row whose cell is
     empty or names a session the table lacks. `verdict` and `evidence` are written when the last
     session named in `sessions` closes. -->

| id | criterion | sessions | verdict | evidence |
|----|-----------|----------|---------|----------|

## Definition of done
<!-- The four default lines stay; the operator adds rows below them. Each line is decided per
     session by commands/_shared/definition-of-done.md, which owns the states. `check` refuses a
     missing default line and accepts a blank state; /v-pm status fills DD-2 to DD-4 once every row
     is done or dropped. -->

| id | line | state | evidence |
|----|------|-------|----------|
| DD-1 | planning done: plan approved and `bin/pm-plan.sh check` exits 0 | | |
| DD-2 | code implemented: every Sessions row `done` with evidence, or `dropped` with a reason (F2, F3) | | |
| DD-3 | code tested: each session's tests pass (B2) | | |
| DD-4 | static analysis passed: the repo's `lint_command` (B3), or not-applicable with a reason | | |

## Decisions
<!-- Column rules: templates/plan.md `## Decisions`. Each row names its evidence — a repo path, a vault
     path, or a source URL — because /v-pm proposes from evidence and holds no opinion of its own. -->

| decision | reason | record |
|----------|--------|--------|

## Solution shape
<!-- How the repos together deliver the need: components, data flow, which repo moves first. A
     mermaid block when more than two parts interact. -->

## Sessions
<!-- Column rules: templates/master-plan.md, including the optional repo, req and deviation columns.
     `bin/pm-plan.sh order plan.md` prints the run order in waves; one wave may run in parallel. -->

| id | repo | scope | command | status | depends | req | date | evidence | deviation |
|----|------|-------|---------|--------|---------|-----|------|----------|-----------|

## Cross-session contracts
<!-- Column rules: templates/master-plan.md. `check` refuses a contract whose consumer does not list
     its producer in `depends`. -->

| id | contract | produced by | consumed by | shape |
|----|----------|-------------|-------------|-------|

## Risks & rollback
<!-- Per session where it differs: the exact revert, the flag to flip, or what is irreversible. -->
