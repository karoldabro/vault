---
type: handoff
project: {{project}}
slug: {{slug}}
date: {{date}}
status: open                  # open | resumed
session: {{session}}          # the session doc this handoff was written from, once one exists
plan: {{plan}}                # the plan this work runs against, or empty
continues: {{continues}}      # the earlier handoff this one carries on from, or empty
tags: [handoff]
---

# {{slug}} — handoff

<!-- Contract class, governed by commands/_shared/document-standard.md: what is still true, not what
     happened. The record of what happened is the session doc named in `session`.

     The eight sections below are written every time. They are first because a handoff is read from
     the top by someone tired, and the line that gets lost is the one under the routine. The six
     sections after them are written only when this session has something to put in them; delete a
     heading you leave empty rather than writing "none". -->

## Left to do
<!-- The payload. One row per item, each with the exact file path and what must become true.
     Ordered so the first row is the one to start with. An empty table means this is not a handoff:
     run /v-capture instead. -->

| # | action | file (exact path) | done when |
|---|--------|-------------------|-----------|
| 1 |        |                   |           |

## Do not touch
<!-- Files, branches, running processes and data the next session must leave alone, and why each.
     A reason the reader can check, not "it is fragile". -->

## Unverified
<!-- What was done and not proven: a change nobody ran, a test that was not executed, a claim resting
     on an assumption. Each line names what would settle it. This is the section that stops the next
     session building on sand. -->

## Goal
<!-- One sentence: what the finished work looks like, in the terms the person asking for it uses. -->

## Task
<!-- What was assigned, in the words it was assigned in. The goal is the target; this is the brief. -->

## Requirements
<!-- The constraints the work must satisfy: rules, contracts, limits, the things that are not
     negotiable. One per line. Name the file each comes from. -->

## Next command
<!-- The exact command the next session runs first, with its arguments. Not "continue the work". -->

## Blockers
<!-- What stops progress, and who or what unblocks it. An empty section is deleted, not written. -->

## Success criteria
<!-- Written when the work has stated criteria. Copy them rather than pointing at them: the next
     session decides against this file. -->

| id | criterion | how it is decided | met |
|----|-----------|-------------------|-----|
|    |           |                   |     |

## Plan
<!-- The path to the plan file, plus the one line about where in it the work stopped. When there is
     no plan file, the ordered steps go here instead. -->

## Method
<!-- How the work is being driven: which commands, which reviewers, which tools prove each step.
     Written when the approach is not obvious from the task. -->

## Done
<!-- What was executed, and how it was executed. Exact paths, and the command or tool that made each
     change, so the next session can repeat the method rather than inventing a second one. -->

## Direction
<!-- Judgement calls already taken that the next session must keep, and the reason for each. Without
     this the next session re-opens a settled question and answers it the other way. -->

## Notes
<!-- Anything that changes an action and fits nowhere above. -->
