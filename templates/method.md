---
type: method
project: {{project}}
slug: {{slug}}
repos: [{{repos}}]
fixed: {{budget | criteria}}        # which one the operator fixed; the other varies
appetite: {{sessions}}              # from /v-pm when a feature workspace exists, else the operator
status: proposed                    # proposed | running | met | abandoned
tags: [method]
---

# {{slug}} — method

<!-- Governed by commands/_shared/document-standard.md. Contract class: current truth only. A stage
     that is replaced is deleted, not struck through. Run bin/doc-lint.sh on this file before naming
     its path to anyone. Written by /v-method; each stage is run by the command its row names. -->

## Problem statement
<!-- The written statement /v-method refused to proceed without. One paragraph: what is wrong or
     wanted, and who the output is for. Not the task title restated. -->

## Success criteria
<!-- `WHEN <trigger> THE SYSTEM SHALL <observable>`, one row each. These are the campaign's criteria,
     not a stage's: a stage's own plan carries its own. The last stage's exit evidence is what makes
     one of these true. Read by bin/gate.sh criteria when a stage's plan inherits a row. -->

| id | criterion | decided by | verdict |
|----|-----------|------------|---------|
|    |           |            |         |

## What this method gives up
<!-- The operator fixed one of budget and criteria; this says what the other one loses. A fixed
     budget names the criteria that may be cut, in the order they would be cut. Fixed criteria state
     that the session count is open. One or the other, never both, never neither. -->

## Stages
<!-- THE PAYLOAD. Ordered. One row per stage, five filled cells beside the id.

     `command` is the rung that runs it: /v-do, /v-work, /v-team, /v-loop or /v-pm. /v-ask is not
     eligible — it writes nothing, so it can never close a stage.

     `kill criterion` names the exact file and field its verdict is read from. A production gate
     once flagged none of a hundred cases it should have caught because its condition read a field
     that was always empty, so "the tests fail" is not a criterion and "`checks/x.sh` exits 1" is.

     `exit evidence` is a path or a command, never a description. It is what must exist for the
     stage to be finished.

     A loop stage names its signal, its interval and its iteration count inside `tools`. -->

| id | stage | command | seats | tools | exit evidence | kill criterion | status |
|----|-------|---------|-------|-------|---------------|----------------|--------|
| S-1 |      |         |       |       |               |                | todo   |

## Routing record
<!-- Every property in commands/v-method/routing.md Table 1, and the answer this task got — the ones
     that did not fire as much as the ones that did. The routing is a heuristic with no validated
     instrument behind it, so this is the record a later session scores against what happened.
     `answer` is yes | no. `basis` is the fact about the task that decided it, or `guess`. -->

| property | answer | basis | stage it contributed |
|----------|--------|-------|----------------------|
|          |        |       |                      |

## Stated defaults
<!-- Questions intake left unanswered, and the default taken for each. Every row was surfaced to the
     operator at hand-off so it can still be corrected. Delete a row once its answer arrives and the
     stage rows reflect it. -->

| question | default taken | who can correct it |
|----------|---------------|--------------------|
|          |               |                    |

## Open & deferred
<!-- Anything that could not be routed, any tool a stage names that this project does not have
     installed, and any stage whose appetite is exceeded. Near the top of what a reader acts on, and
     never cut when this file is shortened. -->

## Refs
<!-- Repo-relative path plus one line on why it matters here. The /v-pm requirements.md when one
     exists, the ADRs the stages obey, and each stage's own plan once it is written. -->
