---
type: decision
project: vault
slug: mechanical-session-gates
status: accepted
date: 2026-09-04
tags: [decision, gates, enforcement, measurement]
---

# ADR-026 — a check that runs, in place of a rule that is written

## Status

Accepted, 2026-09-04.

## Context

The framework had one executable check, `bin/doc-lint.sh`, which reads document form. Everything
else was prose a session was asked to follow. Sessions repeatedly reported work finished that was
not, shipped components that never reached the running system, and re-answered questions already
settled.

Four measurements set the boundary of what prose can do.

**Instructions are followed at well under half.** AGENTIF drew 707 instructions from 50 real agentic
applications, averaging 11.9 constraints each; the best model satisfied every constraint on under
30% of them. IFScale found compliance falling as instruction count rises — 68% at 500.

**Rewriting the file does not help.** A factorial study over 1,650 Claude Code sessions and 16,050
observations found no detectable effect from file size, instruction position, file architecture, or
contradictions between adjacent files. It measured one trivial annotation on two TypeScript
projects, so it bounds the claim rather than settling it.

**Grammar does help.** Across 4,416 trials, prohibitions fell from 73% compliance at turn 5 to 33%
by turn 16 while requirements held at 100%. Re-injecting a constraint restores it. This framework
carries 178 prohibitions against 32 requirements.

**A model cannot judge whether an agent finished.** Across 9,876 trajectories, 75.8% of failures in
self-assessing coding agents were reported as success. No judge configuration — five judges, five
prompt strategies, full task specifications — exceeded 0.65 AUROC at detecting it, and 0.54 on
execution traces. Judges anchor on confident closing language, which is what a false claim produces.
An independent process reading environment state cut false success from 44–52% to 3%.

## Decision

**A check is a committed script, never a command string in a plan.** The session that writes the
work does not author the thing that grades it. A script is reviewable at approval, survives the
session, and the operator can re-run it on a clean checkout.

**No model decides whether work was done.** `bin/gate.sh verdict --run` executes each check and
writes the verdict and the captured output into the plan itself. Those two cells are the only part
of a plan a session never writes.

**Every change carries one criterion of kind `delivery`** — a run of the real system that finds this
change in what the run produced. An existing suite passes green while a new field never reaches the
output, because the suite predates the field.

**Assertions read what a run produced, never what the system wrote about itself.** A manifest
records intent; the artifact records delivery.

**A session may not end on an unproven claim.** `scripts/completion-hook.sh` blocks the turn end
when a work item is marked done and its criterion has no verdict, and returns the failing check as
the next instruction. It makes no model call.

**Rules are written as requirements, never as prohibitions**, and a rule with no check behind it is
deleted rather than reworded. An unenforced rule competes for the same attention as an enforced one.

**A check firing wrongly more than one time in ten is fixed or deleted.** Google disables a
Tricorder analyzer at that line; their platform runs under 5%.

**A repo declares how its own checks run, or a session stops at its first step.** An omitted key in
`VAULT.md` is refused; `absent: <reason>` is legal.

## Options rejected

**An agent that verifies the implementation against the criteria.** This was the operator's initial
request. It is the 0.54-AUROC mechanism, and agreement bias grows with the capability gap between
the agent and its verifier, so a small verifier is worse rather than cheaper.

**A gate that refuses to write output before the communication contract is read.** No hook fires
before a model writes prose. `bin/output-lint.sh` measures the reply afterwards instead, and the
rule is recorded as prose in `vault/check-budget.md` rather than claimed as enforced.

**Reachability through the code graph, to prove a change is wired in.** This repo's
`graphify-out/graph.json` holds 2,598 nodes, all markdown documents, and 2,385 edges, all
`contains`; `bin/`, `scripts/` and `lib/` are unindexed. `bin/gate.sh readers` greps instead.

**A gate with no escape hatch.** `GATE=off` stays, whole-run only. A gate with no relief valve is
abandoned wholesale rather than used with a stated exception.

## Consequences

Hooks are escapable: they do not fire in `claude -p` pipe mode, subagent and MCP tool calls ignore a
deny, and a model blocked from one tool has been observed reaching the same result through another.
This is the strongest mechanism available and it is not airtight.

The instruction cut waits on measurement. `vault/plans/2026-09-04-1100-rule-compliance-study.md`
scores framework rules against 150 commits and 1,708 transcripts before anything is deleted, because
two rules in one sentence of one file already differ by 74 points in compliance — which no file-level
explanation covers.

`bin/gate.sh` now refuses on nine conditions. Every one of them is a candidate for the ten percent
budget, and a check that crosses it is removed rather than tolerated.
