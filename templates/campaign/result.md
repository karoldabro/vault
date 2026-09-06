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

The exact command, and what it returned. A number here must carry the command that produced it.

## What the injection changed

The contrary condition, and the outcome it produced. When the injected condition gives the same
result as the normal one, the case discriminates nothing and its verdict is `BLOCKED`.

## What was observed

What a user would see, quoted from the run rather than described.

## Evidence

Paths to the stdout capture, the device or browser log, and any screenshot.

VERDICT: PASS | FAIL | BLOCKED
