---
type: session
project: vault
date: 2026-07-10
topic: llm-collaboration-patterns
files_touched: [VAULT.md, vault-guide.md, commands/v-team/steps/03-propose-loop.md,
  personas/_persona-template.md, personas/_shared/skeptic.md, tests/unit/v-team.bats,
  vault/decisions/ADR-017-evidence-based-panel-hardening.md, vault/decisions/_inventory.md,
  vault/indications/confirmed-vs-advisory-findings.md, vault/research/llm-collaboration-patterns.md,
  vault/plans/2026-07-10-1740-llm-collaboration-patterns.md]
decisions: [ADR-017]
tags: [session, research, personas, v-team]
---

# llm-collaboration-patterns

## Goal

Research how companies/practitioners structure LLM collaboration across development, marketing, sales,
planning, and customer support, and adopt the evidence-backed patterns into the /v-team framework.

## Did

- Ran the full `/v-team` lifecycle end-to-end — **first production run of a panel session on the
  framework repo since the business-persona shipment**. Research gate = 5 parallel research agents
  (dev · marketing+sales · support · planning/PM · cross-domain foundations), ~75 patterns / ~150
  sources; Bright Data CLI available but WebSearch sufficed.
- Wrote the durable catalog [[llm-collaboration-patterns]] (`vault/research/`, 527-line living doc,
  IDs F-/D-/M-/S-/P-/C- + §7 validated-choices table + §8 sources) — declared `optional: [research]`
  in `VAULT.md`, broadened vault-guide §2 research/ description.
- 2-round design panel (conventions-architect · skeptic · quality; 30 findings, 7 confirmed MAJORs)
  reshaped the plan hard: premortem SEAT killed (correlated double-vote), new indication killed (third
  home), Tier 1 shrunk 10→6 surfaces. Full trail in [[2026-07-10-1740-llm-collaboration-patterns]].
- Shipped ADR-017 adoptions: verifier tool-asymmetry ([[confirmed-vs-advisory-findings]] corollary +
  `_persona-template.md`), pre-mortem as skeptic technique, minority-flag dissent surface +
  critic-owned grounding + sycophancy metric in `03-propose-loop.md` §(e).
- Backfilled the missing ADR-016 `_inventory.md` row (drift caught by the panel's own grep); added the
  every-ADR-registered bats invariant + phrase-drift guards. Suite 226→229, green.
- 1-round diff review: quality APPROVE, arch/skeptic APPROVE_WITH_NITS; fixed C-06 arithmetic
  (90%×90%→error-complement form), dangling wikilink, empty-id test guard.
- Commit `7964139` on `feat/llm-collaboration-patterns` (11 files, +920/−8).

## Learned

- **The foundations literature independently validates the framework's core bets**: tool-grounded
  critique is the active ingredient (CRITIC; self-correction without external signal fails); debate
  loses to independent-parallel-critics at equal compute; sycophancy flips correct→incorrect from
  round 2; decorrelation is the load-bearing panel assumption (heterogeneous 2 ≈ homogeneous 16).
  ADR-001/002/003 now have citations.
- **Verifier tool-asymmetry is the highest-leverage upgrade class**: the generation-verification gap
  widens when the verifier holds affordances the generator lacked — cheaper than adding critics.
- The panel worked exactly as designed against its own designer: Round 1 killed the plan's flagship
  proposal (premortem persona) using the plan's own cited evidence; Round 2's skeptic found the
  minority-flag clause was escapable via synthesizer grounding re-grade (fixed: critic-owned
  grounding); diff-review skeptic caught a self-inconsistent arithmetic claim (90%×90%≠99%) that
  placement/duplication lenses waved through.
- Pre-mortem's quantified benefit (~30%, Klein) is human-team psychology — no LLM-context replication
  exists; adopted at technique level only, seat deferred pending evidence.
- OV `memory_store` still returns 0 extractions on dense structured text (known, embedding-only mode);
  push succeeded, recall stays routed via `ov find`.

## Behaviors & rules

- [ADR-017] Critic grounding is critic-owned → synthesizer may not re-grade `confirmed` downward to
  alter blocking status; edge: a confirmed BLOCKER/MAJOR dispositioned ≠ applied surfaces at the gate
  as a minority flag regardless of relabeling.
- [ADR-017] A confirming check must add evidence the drafter didn't have → re-reading the author's
  prose or re-citing the author's own analyzer run is not grounding.
- Panel round metrics include previously-confirmed-dropped count → a round that drops previously
  confirmed findings is flagged as possible sycophancy regression.
- Any `vault/decisions/ADR-*.md` file → must have a same-commit `_inventory.md` row (bats-enforced);
  edge: malformed ADR filename (no numeric id) fails loudly, never passes vacuously.
- Panel-mechanism change proposals → cite [[llm-collaboration-patterns]] or equivalent primary
  evidence (the catalog is the living evidence reference).

## Next

- Tier-2 backlog (each its own future run): synthetic-customer/buyer-committee lens for business packs
  (advisory-only by construction), war-game/competitor mode (business+startup-eval), PR/FAQ
  narrative-gauntlet mode for /v-pm, confidence-gated auto-accept for /v-cr (dual-condition:
  threshold + N consecutive human approvals), red-line topic list for business packs.
- Tier-3: replay/regression corpus of past panel decisions, Ralph-loop overnight mode, forecaster
  lens, architect/editor model split in EXECUTE.
- Repo-wide ADR frontmatter drift (template `scope:`/`tags:` vs recent practice) — separate cleanup.
- Merge `feat/llm-collaboration-patterns` to main after user review; `/v-sync` to re-ingest catalog +
  ADR-017 into OV.

## Refs

[[2026-07-10-1740-llm-collaboration-patterns]] · [[ADR-017-evidence-based-panel-hardening]] ·
[[ADR-016-business-persona-family]] · [[ADR-001-panel-loop-over-peer-debate]] ·
[[ADR-002-no-stop-on-approval-alone]] · [[ADR-003-tool-grounded-findings]] ·
[[llm-collaboration-patterns]] · [[confirmed-vs-advisory-findings]] · [[v-team]] ·
[[2026-07-10-1620-business-persona-family]]
