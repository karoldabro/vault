---
type: decision
id: ADR-015
date: 2026-07-04
status: accepted
tags: [decision, tiering, lifecycle, cost]
---

# ADR-015 — Re-tier the lifecycle: lite critic in /v-work, auto fast path, v-team as explicit escalation

## Context

Usage data (Jun–Jul 2026): /v-team — documented as "BIG/high-stakes only" — grew to 78% of lifecycle
runs at ~2× cost per run, while delivering the same ~79% completion rate as /v-work. /v-do sat at 8
lifetime uses. Diagnosis: the do/work/team ladder conflated two orthogonal axes — **trust** (approval
gate or not) and **rigor** (adversarial critique or not). The only route to *any* second opinion was
the full 3-critic × 2-round × 2-loop panel, and the user had to pre-classify smallness to get the cheap
path. 2026 community consensus (spec-tool benchmarks, Sant'Anna worker-critic, Anthropic guidance)
matches: single-pass review for routine work, convergence loops only when a wrong decision is expensive
to reverse.

## Decision

1. **/v-work gains a lite critic** (`03-propose.md` §3a.6): exactly one read-only critic, one pass,
   never loops; panel-worthy risk → advise escalating to /v-team rather than looping locally.
2. **/v-work auto-detects small jobs** (`01-analyze.md` §1.4c runs the /v-do guardrail) and takes the
   /v-do flow itself — no user pre-classification; "full lifecycle" overrides. /v-do remains as a
   direct alias that skips ANALYZE entirely. /v-team never fast-paths.
3. **/v-team is framed as the escalation, not the default**, with a measured cost line (~2× a v-work
   session; same completion rate) in the dispatcher.
4. The PROPOSE research gate fires only on genuinely **novel** choices (new library/architecture/
   schema/integration), not "any non-trivial work".

## Consequences

- A second opinion no longer costs a panel; expected shift of routine runs back from /v-team.
- Small jobs stop paying gate + research + capture ceremony (the /v-do starvation fix).
- /v-team's convergence mechanics are unchanged (cap 2 rounds, stop on no-new-confirmed-blockers) —
  the fix is routing, not the panel itself.
- Watch: whether v-team share falls below ~20% of lifecycle runs by August 2026; if not, revisit.
