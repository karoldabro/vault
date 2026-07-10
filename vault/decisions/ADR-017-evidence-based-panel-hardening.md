---
type: decision
id: ADR-017
project: vault
status: accepted
date: 2026-07-10
tags: [decision, personas, v-team, research]
---

# ADR-017 — Evidence-based panel hardening: verifier asymmetry, pre-mortem technique, dissent surface

## Context

A five-agent research sweep (~75 patterns, ~150 sources; development · marketing · sales · planning ·
customer support · cross-domain foundations) produced the living catalog
[[llm-collaboration-patterns]] (`vault/research/`). The foundations strand independently validates the
framework's core choices — tool-grounded critique over self-critique (CRITIC, ICLR'24; Huang et al.,
ICLR'24 → ADR-003), independent parallel critics over multi-round debate (sycophancy flips
correct→incorrect from round 2; arXiv 2509.05396, 2509.23055 → ADR-001/002), decorrelated small panels
over homogeneous large ones (A-HMAD, Springer 2025 → `_resolution.md` §2) — and surfaced three
adoptable, evidence-backed hardening upgrades. A 2-round critique panel (conventions-architect,
skeptic, quality; 30 findings, 7 confirmed MAJORs) shaped what was adopted vs. rejected.

## Decision

1. **Verifier tool-asymmetry.** A critic's confirming check must add evidence the drafter didn't
   already have — run the test, execute the query, probe the real path. Adopted as a corollary in
   [[confirmed-vs-advisory-findings]] and an authoring rule in `_persona-template.md`. Basis:
   verification is cheaper than generation and the gap *widens* when the verifier holds tools the
   generator lacked (arXiv 2508.16665, 2506.18203).
2. **Pre-mortem as a skeptic TECHNIQUE, not a seat.** Prospective hindsight ("it shipped and failed —
   name the cause, past tense") is added to `_shared/skeptic.md`'s mandate + checklist. A separate
   `premortem` persona was proposed and **rejected**: same jurisdiction and same high-stakes trigger as
   skeptic → correlated double-vote, and on a cap-3 panel it evicts a decorrelated domain lens — the
   exact anti-pattern the decorrelation evidence warns against. Evidence caveat recorded: the
   quantified pre-mortem benefit (~30% better risk identification, Klein) is *human-team* psychology;
   no LLM-context replication is known. A future substitute seat (never co-seated with skeptic) would
   supersede the technique line, and only if LLM-context evidence emerges.
3. **Dissent surface + critic-owned grounding.** In `03-propose-loop.md` §(e): a critic-assigned
   `grounding: confirmed` BLOCKER/MAJOR dispositioned anything other than *applied* surfaces at the
   approval gate as a **minority flag**, regardless of relabeling; `grounding` is critic-owned — the
   synthesizer may not re-grade it downward to alter blocking status (closes the re-grade escape
   hatch); round metrics gain *previously-confirmed findings dropped this round* (sycophancy flag).

## Consequences

- `vault/research/llm-collaboration-patterns.md` is the **living evidence reference** for future
  panel-mechanism changes — proposals should cite it (or equivalent primary evidence).
- Guard tests in `tests/unit/v-team.bats`: pre-mortem technique token, minority-flag +
  grounding-ownership tokens, and an every-ADR-registered inventory check. The latter is a **new
  cross-cutting ADR-hygiene invariant** (added in EXECUTE, panel-reviewed post-hoc): any ADR file
  without a same-commit `decisions/_inventory.md` row fails the suite — it already caught the
  previously-unregistered ADR-016.
- Tier-2 backlog recorded in the plan artifact ([[2026-07-10-1740-llm-collaboration-patterns]]):
  synthetic-customer/buyer-committee persona class (advisory-only by construction), war-game/competitor
  mode, PR/FAQ narrative gauntlet for /v-pm, confidence-gated auto-accept for /v-cr, red-line topic
  list for business packs. Tier-3: replay/regression corpus for persona changes, Ralph-loop overnight
  mode, forecaster lens, architect/editor split in EXECUTE.

## Alternatives considered

- **Premortem persona seat** — rejected (Decision 2).
- **New indication `evidence-based-panel-design`** — rejected: third home for rules owned by
  [[confirmed-vs-advisory-findings]] / [[critique-loop-stop-conditions]]; the novel rule lives here.
- **Cross-family judging** (synthesizer from a different model family — mitigates self-preference
  bias) — evidence-backed but **not feasible** in a single-model Claude Code install; known limitation.
- **Multi-round debate topology** — rejected on the evidence (loses to independent critics +
  aggregation at equal compute; reaffirms ADR-001).

## Refs

[[llm-collaboration-patterns]] · [[ADR-001-panel-loop-over-peer-debate]] ·
[[ADR-002-no-stop-on-approval-alone]] · [[ADR-003-tool-grounded-findings]] ·
[[ADR-016-business-persona-family]] · [[2026-07-10-1740-llm-collaboration-patterns]]
