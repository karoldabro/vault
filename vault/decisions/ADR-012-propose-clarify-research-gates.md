---
type: decision
project: vault
id: ADR-012
status: accepted
scope: repo
tags: [adr]
---

# ADR-012 — PROPOSE opens with clarify + online-research front gates

## Context
Two recurring failure modes in the lifecycles: the model **jumps to a plan without fully understanding
the task** (guessing past ambiguity about direction/technology/scope), and it **asserts design choices
from its prior** rather than from how the problem is actually solved in the wild (hallucination). Both
land before any code is written, in PROPOSE. The `/v-work` and `/v-team` propose steps share `§3a`, so a
single seam fixes both.

## Decision
Open PROPOSE `§3a` with two front gates, before code location/design:
- **§3a.0a Understand & clarify** — state understanding + assumptions, list open doubts, and route each:
  answer from context/research, ask the user via `AskUserQuestion` (batched) only for plan-changing
  doubts with no safe default, or state a safe default. Guessing past real ambiguity is disallowed;
  user-unavailable → proceed on stated defaults and flag them at the approval gate.
- **§3a.0b External research** — research how the problem is solved in the wild before committing; gated
  (skips pure refactor/docs/formatting/rename). A credible contradicting consensus must be **adopted or
  refuted in writing** (never silently ignored); cite sources in the plan artifact.

`/v-team` runs both in the v0 draft **before the panel spawns**; an unresearched design or unsound
assumption is a legitimate critic finding.

## Consequences
- Fewer wrong plans and hallucinated approaches; the cost is up-front web searches + occasional user
  questions (gated to non-trivial work, so routine changes are unaffected).
- The gates are instruction-only prose (no new tooling); dialable — could later force ≥1 clarifying
  question per run, or let research block v-team convergence (BLOCKER-grade) instead of reconcile-only.
- `tool-playbook.md` §7 documents web research as correctness-saving (not token-saving).

## Cross-repo impact
None — framework-internal. Applies to every repo that uses `/v-work` or `/v-team`.
