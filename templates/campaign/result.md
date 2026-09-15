---
type: instruction
campaign: {{slug}}
case: {{case-id}}
tags: [campaign, result]
---

# {{case-id}} — {{title}}

One file per run, at `results/{{case-id}}.md`. The orchestrator reads the last line to decide
whether the loop ends, so the last line's shape is a contract.

## What was run

The exact command, and what it returned, before and after. A number here must carry the command that
produced it.

State any clause of this case's definition of done that the verifier cannot detect, and how it was
checked instead. A green verdict must not imply work nothing measured.

## What proved this case can fail

The adapter's failure shape, and what it produced. A case whose contrary condition gives the same
result as the normal one discriminates nothing, and its verdict is `BLOCKED`.

## What was observed

What a user would see, quoted from the run rather than described.

## Evidence

Paths to the stdout capture, the device or browser log, and any screenshot.

VERDICT: PASS | FAIL | BLOCKED
