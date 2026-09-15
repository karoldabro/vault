---
type: instruction
campaign: {{slug}}
tags: [campaign, brief]
---

# {{slug}} — agent brief

Every campaign agent reads this before it starts. It holds the traps this campaign has already paid
for, and it is the difference between paying for a mistake once and paying for it five times.

**A trap is added the moment it costs a run.** The orchestrator writes the row, from what the agent
that hit it reported.

**Current truth only.** A brief that still describes a repaired trap as live tells an agent to ignore
a real finding, so a fixed trap is deleted rather than marked.

**Every number here carries the command that produced it.** A count without one is a claim, and an
agent runs the command rather than accepting the number. Never write a line number where a `grep`
would find the thing.

## Environment

How the arena is reached, how it is restored, and which commands this campaign has proven safe here.
Writing anywhere outside the arena is a defect.

## Traps

| trap | what it looks like | what to do instead |
|------|--------------------|--------------------|
|      |                    |                    |

## The repair, step by step

The recipe for the shape most cases share, written once the first case of that shape has closed. A
later agent follows this rather than deriving it again.

## Verified facts

Facts an agent must not re-derive: a baseline read from a live endpoint, a permission the token
lacks, a limit the server enforces. Each carries the command that produced it and the date.

| fact | command | date |
|------|---------|------|
|      |         |      |
