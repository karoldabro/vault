---
type: decision
project: vault
id: ADR-003
status: accepted
scope: repo
tags: [adr, v-team, personas]
---

# ADR-003 — Persona findings are tool-grounded (confirmed vs advisory)

## Context
A naive persona panel assumes "you are a security expert" makes a model better at *finding* security
bugs. Research says the opposite: personas help focus/rubric/format but do **not** improve detection
competence, and can slightly hurt coding accuracy. Untuned LLM reviewers also start at 40–80% false
positives — and past ~30% FP, developers ignore the bot entirely (the trust cliff).

## Decision
Every persona is **tool-grounded**: it runs a bound analyzer first (SAST, linter, query/N+1 probe,
`dart analyze`, etc.) and the persona *interprets* tool output rather than replacing it. Each finding
carries `grounding: confirmed | advisory`. **Only `confirmed` findings (backed by a concrete check) may
be BLOCKER/MAJOR and force a plan change**; `advisory` findings are recorded and surfaced but never
block convergence.

## Consequences
- Directly attacks the false-positive trust cliff; keeps blocking findings credible.
- Makes ADR-002's "no new confirmed blockers" stop condition well-defined.
- Stack packs must bind real analyzers per lens; a lens with no available analyzer downgrades its
  findings to advisory rather than blocking on vibes.
- Selection favors ~3 decorrelated lenses over many redundant ones (correlated critics ≈ 2 effective
  votes).
