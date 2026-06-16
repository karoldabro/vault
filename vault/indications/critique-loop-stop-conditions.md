---
type: indication
project: vault
slug: critique-loop-stop-conditions
scope: repo
tags: [indication, multi-agent, v-team]
---

# critique-loop-stop-conditions

## Rule
Multi-agent critique loops stop on a **hard round cap** OR **no new confirmed BLOCKER/MAJOR findings** —
never on unanimous approval alone. Caps are ceilings: a cap hit with open confirmed blockers escalates
to the user, it never auto-continues.

## Rationale
"Loop until critics approve" is a documented false-convergence trap (sycophancy + LLM-judge bias).
Hard caps bound cost; the no-new-confirmed-blockers gate ends nit-loops; escalation keeps a human in
the loop on genuinely contentious changes. See [[ADR-002-no-stop-on-approval-alone]].

## Examples
- Do: `commands/v-team/steps/03-propose-loop.md` §f — stop on `team_max_rounds` or no new confirmed
  blocker; cap-with-blockers → `CONVERGENCE: capped with N open blockers`.
- Don't: continue looping because "one critic still wants changes" past the cap, or stop because "all
  critics said APPROVE".

## Applies-to
Any looped agent panel in the framework (`commands/v-team/steps/**`).
