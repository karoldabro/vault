---
type: instruction
campaign: {{slug}}
tags: [campaign, brief]
---

# {{slug}} — tester brief

Every campaign agent reads this before it starts. It holds the traps this campaign has already paid
for, and it is the difference between paying for a mistake once and paying for it five times.

**A trap is added the moment it costs a run.** The agent that hit it writes the row.

**Current truth only.** A brief that still describes a fixed defect as live tells a tester to ignore
a real finding, so a repaired trap is deleted rather than marked.

## Environment

How the stack is reached, how it is rebuilt, and which commands the campaign has proven safe here.

## Traps

| trap | what it looks like | what to do instead |
|------|--------------------|--------------------|
|      |                    |                    |

## Verified facts

Facts an agent must not re-derive: a baseline read from a live endpoint, a permission the token
lacks, a limit the server enforces. Each carries the command that produced it and the date.
