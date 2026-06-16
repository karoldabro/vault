---
type: decision
project: vault
id: ADR-001
status: accepted
scope: repo
tags: [adr, v-team, multi-agent]
---

# ADR-001 — Panel→synthesize→re-loop over true peer-to-peer debate

## Context
`/v-team` needs a way for multiple persona critics to review a plan/diff and "exchange ideas". Two
shapes: (a) parallel independent critics whose only shared channel is a synthesizer-revised plan, or
(b) true peer-to-peer debate where named agents message each other before a verdict. Web research (~25
papers + AI-code-review postmortems) was decisive.

## Decision
Use the **panel → synthesize → re-loop** model: each round spawns critics in parallel; they never
message each other; a de-biased synthesizer merges findings and revises the plan; the panel re-runs on
the revised plan. No agent-to-agent messaging.

## Consequences
- Preserves the diversity that makes aggregation work; avoids sycophantic groupthink (correct→wrong
  flips) documented in debate setups.
- Cheaper and deterministic (parallel, cost-bounded) vs serial debate.
- Critics can't react to each other within a round — acceptable; cross-round visibility comes via the
  revised plan + prior-round findings in the envelope.
- Synthesizer is an LLM-judge → must be de-biased (source-blind ranking, order randomization,
  anti-verbosity). See [[ADR-002-no-stop-on-approval-alone]].
