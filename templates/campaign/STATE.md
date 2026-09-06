---
type: instruction
campaign: {{slug}}
feature: {{feature}}
stack: {{disposable-stack-name}}
rounds_used: 0
tags: [campaign, state]
---

# {{slug}} — resume point

The first file a resuming session reads. It holds where the campaign stopped and what it owes.
The case ledger holds the cases; this holds only what the ledger cannot answer.

## Stack

The disposable stack this campaign runs against, and the command that rebuilds it. A session that
finds this blank stops and asks, because the precondition is the operator naming a stack they are
willing to lose.

| field | value |
|-------|-------|
| stack name | {{disposable-stack-name}} |
| rebuild command | {{restore-command}} |
| test command | {{test-command}} |
| browser harness | {{browser-harness}} |

## Rounds

`rounds_used` in the frontmatter is the count the cap is measured against, and every round increments
it before any agent spawns. A session that resumes reads it rather than starting at zero, which is
what makes the cap survive a usage limit.

| field | value |
|-------|-------|
| rounds used | 0 |
| round cap | {{loop_max_rounds}} |

## Retest queue

Cases with a `fail` verdict whose fix has landed and whose retest has not run. A session works this
before it takes new cases.

| case id | defect id | fix commit | waiting since |
|---------|-----------|------------|---------------|
|         |           |            |               |

## Never run

Case ids in the ledger with no `run_at`. When this is empty and the retest queue is empty and no case
reads `fail`, the campaign is done.

## Deferred decisions

Decisions taken mid-loop with the reversible option, to be put to the operator at the close. Each
row names what was chosen and what the other option was.

| decision | option taken | option not taken |
|----------|--------------|------------------|
|          |              |                  |
