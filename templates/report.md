---
type: report
project: {{project}}
slug: {{slug}}
date: {{date}}
status: open                  # open | planned | fixed | rejected
severity: {{severity}}        # blocking | major | minor
found_by: {{found_by}}        # the session, command or person that hit it
found_in: {{found_in}}        # what was being done when it surfaced
files: []                     # every path involved, exact
tags: [report]
---

# {{slug}} — report

<!-- Contract class, governed by commands/_shared/document-standard.md: what is wrong now, and what
     would fix it. The finder is a frontmatter key and appears nowhere below this fence — rule 7 bars
     an author's name inside a contract body, and rule 5 permits it as metadata.

     A problem inside the current plan's scope belongs in that plan's `## Open & deferred`. This
     folder holds only a problem outside the scope of the work that found it. -->

## What is wrong

<!-- One sentence stating the defect as current truth. Name the thing and the verb. -->

## Files

| file (exact path) | what is wrong in it |
|-------------------|---------------------|
|                   |                     |

## Consequence

<!-- What breaks, and who notices. "It is bad" is not a consequence; "a session reads a check as
     gated when nothing runs it" is. State whether it has already happened or is still latent. -->

## Cause

<!-- Why it is this way. `unknown: <what was checked and came back empty>` is a legal and honest
     answer — an invented cause is worse than a recorded gap. -->

## How to see it

<!-- The command, path or steps that show the problem, so nobody has to take this file on trust.
     `no reproduction: <why>` when the state that produced it is gone. -->

## Repair

<!-- The suggested fix, and the command that would run it: /v-do for a small one, /v-work for a
     normal one, /v-team for architecture, schema, auth, billing or cross-repo. Name the files it
     would touch. -->

## Not now because

<!-- Why this was not fixed when it was found. Scope, risk, a dependency, or the session's own
     budget. This is what a later reader uses to decide whether the reason still holds. -->

## Closes when

<!-- The observable condition that ends this report: a command that exits 0, a test that passes, a
     file that stops existing. `/v-report close` reads nothing else. -->
