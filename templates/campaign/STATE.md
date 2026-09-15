---
type: instruction
campaign: {{slug}}
feature: {{feature}}
adapter: {{adapter-name}}
arena: {{arena-name}}
rounds_used: 0
tags: [campaign, state]
---

# {{slug}} — resume point

The first file a resuming session reads. It holds where the campaign stopped and what it owes.
The case ledger holds the cases; this holds only what the ledger cannot answer.

## Arena

The arena this campaign runs against, and the command that restores it. A session that finds either
blank stops and asks: the precondition is the operator naming an arena they are willing to lose, and
a restore command the session has actually run.

| field | value |
|-------|-------|
| arena name | {{arena-name}} |
| restore command | {{restore-command}} |
| restore proven at intake | {{yes, and what re-reading the arena showed}} |

## The adapter's slots

Copied from `commands/v-loop/adapters/{{adapter-name}}.md` at intake, so no later session fills one
from memory.

| slot | this campaign's answer |
|------|-----------------------|
| unit of work | {{what one case is, and every path it writes}} |
| backlog | {{the command that enumerates it}} |
| actor | {{who works a case, and what it reads first}} |
| verifier | {{the command or model that produces a verdict}} |
| caps | {{rounds}} rounds, {{attempts}} attempts per case |
| stop rule | {{the observable condition that ends this}} |

## Clauses the verifier cannot detect

Each names the written rule it cites. A clause resting on judgement belongs in Deferred decisions
below, not here.

| clause | rule it cites | how a case checks it |
|--------|---------------|----------------------|
|        |               |                      |

## Rounds

`rounds_used` in the frontmatter is the count the cap is measured against, and every round increments
it before any agent spawns. A session that resumes reads it rather than starting at zero, which is
what makes the cap survive a usage limit.

| field | value |
|-------|-------|
| rounds used | 0 |
| round cap | {{loop_max_rounds}} |

## Re-verify queue

Cases whose repair has landed and whose re-verification has not run, plus any case whose files
changed after its verdict. A session works this before it takes new cases.

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
