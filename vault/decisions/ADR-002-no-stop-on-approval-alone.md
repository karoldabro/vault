---
type: decision
project: vault
id: ADR-002
status: accepted
scope: repo
tags: [adr, v-team, convergence]
---

# ADR-002 — Critique loops never converge on unanimous approval alone

## Context
A multi-agent critique loop needs a stop condition. The intuitive "loop until all critics approve" is,
per the research, the #1 false-convergence trap: sycophancy drives premature agreement and the
synthesizer/judge carries position, verbosity, and self-preference biases. Consensus ≠ correctness.

## Decision
`/v-team` loops stop on **ANY** of: (1) a hard round cap (`team_max_rounds` / `team_max_review_rounds`,
default 2); or (2) **no new confirmed BLOCKER/MAJOR** findings in a full round. **Unanimous approval is
never a stop condition by itself.** A cap hit with open confirmed blockers stops the loop and
**escalates to the user** (`CONVERGENCE: capped with N open blockers`) — it never auto-continues.

## Consequences
- Guards against false/premature convergence; bounds cost with hard caps.
- Requires the "confirmed vs advisory" grounding distinction so "no new *confirmed* blockers" is
  meaningful — see [[ADR-003-tool-grounded-findings]].
- A genuinely contentious change surfaces to the human instead of being silently rubber-stamped.
