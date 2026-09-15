---
type: plan
project: vault
slug: llm-collaboration-patterns
status: executed   # proposed | approved | executed | superseded
process_record: 2026-07-10-1740-llm-collaboration-patterns.trail.md
tags: [plan, team, research]
---

# llm-collaboration-patterns — team plan

Written by `/v-team`. The implementation plan and the proposed-test backlog. Drives EXECUTE.

## Task

Research how leading companies/practitioners structure LLM collaboration (multi-agent/persona patterns
and beyond) across development, marketing, sales, planning, and customer support, and propose which
patterns to adopt into the vault /v-team framework.
Keywords: llm-patterns, multi-agent, persona-critique, workflow-orchestration, business-domains, research

## Open trade-offs / deferrals

- **Cross-family judging** — evidence-backed, not feasible in a single-model install → ADR-017 known
  limitation.
- **Catalog split** — `vault/research/llm-collaboration-patterns.md` stays one file (527 lines,
  ~8% over the soft split threshold); revisit only if it outgrows usefulness.
- **Catalog folder fit** — resolved by broadening the vault-guide `research/` description (step 2)
  rather than moving the catalog to architecture/.
- **Pre-mortem evidence** — pre-mortem's quantified benefit is human-team evidence; adopted only
  at technique level, recorded in ADR-017; seat-level adoption deferred until LLM-context evidence.
- **ADR `scope:` field** — `vault/decisions/ADR-017-evidence-based-panel-hardening.md` omits the
  `scope:` key that `templates/decision.md:6` specifies, as ADR-016 does. Repo-wide
  template↔practice drift; cleaned up separately, not here.

## Clarify gate (§3a.0a) — assumptions

1. **Deliverable shape** — (a) durable, source-cited pattern catalog in the vault AND (b) prioritized
   adoption proposal for the framework; what gets implemented is decided at the approval gate.
2. **Research tooling** — Bright Data CLI (`bdata` 0.3.1) installed; research agents used WebSearch
   primarily, `bdata` as fallback.
3. **Scope** — patterns for *working with* LLMs, not a vendor/tool market survey.
4. **No new code** — markdown deliverables + bats file-contract assertions per framework convention.

## Research gate (§3a.0b) — digest

Five research strands (development · marketing+sales · customer support · planning/strategy/PM ·
cross-domain foundations) produced ~75 patterns/findings from ~150 sources.
`vault/research/llm-collaboration-patterns.md` carries the complete set. Key strands:

**Foundations (evidence-graded):**
- Tool-grounded external critique works; intrinsic self-critique does not (CRITIC ICLR'24; Huang et al.
  ICLR'24). Validates ADR-003.
- Debate ≠ better: at equal compute, independent-parallel-critics + aggregation ≥ multi-round debate;
  sycophancy flips correct→incorrect from round 2 (arXiv 2509.05396, 2509.23055). Validates ADR-001/002.
- Verification is cheaper than generation; the gap WIDENS when the verifier holds tools the generator
  lacked (arXiv 2508.16665, 2506.18203) → *verifier tool-asymmetry* is the highest-leverage upgrade.
- Judge biases are systematic (position/verbosity/self-preference); rubrics + per-criterion structured
  scoring materially raise judge reliability (arXiv 2606.08625).
- Panel value = decorrelation; heterogeneous 2-agent ≈ homogeneous 16-agent (A-HMAD, Springer 2025).
- Persona prompting helps DIVERGENCE, can hurt objective factual accuracy (EMNLP'24 Findings).
- Most multi-agent failures are orchestration bugs (MAST, NeurIPS'25: termination, repetition,
  spec-disobedience).
- Human gates: risk-targeted, not uniform (HBS/BCG jagged-frontier).
- Read-fan-out/single-writer split (Anthropic multi-agent research; Cognition "Don't Build
  Multi-Agents" + 2026 update: reviewers with CLEAN context catch what the fatigued builder misses).

**Development:** spec-driven development (GitHub Spec Kit, Kiro); RPI phase artifacts (12-Factor
Agents); architect/editor split (Aider); TDD-as-leash + test-deletion guard (Kent Beck); Ralph loop
(ghuntley); worktree parallelism.

**Marketing/Sales:** synthetic audience / buyer-committee simulation (directional-only validity);
generator→editor→fact-checker pipelines (Klarna Copy Assistant); campaign pre-mortem red-teams;
adversarial buyer roleplay (Nooks, Gong); interrogable scoring (top-3 reasons, human-policy vs
AI-judgment split); confidence-gated CRM commits.

**Support:** confidence-tiered routing + dual-condition auto-send gates; supervisor/policy-critic model
(Sierra, Decagon — two ~90% checks ≈ 99% effective via error-complement); pre-send hallucination gates; red-line topics (confidence-independent escalation);
KB gap mining; replay/regression corpora; Klarna full-automation walk-back.

**Planning/PM:** persona × mode matrix (WHO critiques × HOW: debate, pre-mortem, red-blue war-game,
narrative gauntlet, scoring rubric); pre-mortem prospective hindsight (Klein — human-team evidence);
war-gaming competitor personas (McKinsey); PR/FAQ gauntlet (Amazon); ensemble forecasting with
calibration; **personas as method-enforcers**; high-variance CoT ideation (Wharton).

## Plan

**Tier 0 — the catalog (durable research):**
1. `VAULT.md` — Action: declare `optional: [research]` under `## structure` (research/ is a standard
   optional folder per vault-guide §2 + templates/VAULT.md:26 — NOT `add_folders`). Tool: Edit.
2. `vault-guide.md` §2 folder taxonomy — Action: broaden `research/` description to "User research,
   qual data, secondary/literature research (optional)". Tool: Edit (one line).
3. `vault/research/llm-collaboration-patterns.md` — Action: CREATE the pattern catalog as an
   **undated living doc**: §0 how-to-read + validity grades · §1 Foundations (17 findings) ·
   §2 Development (15) · §3 Marketing (8) · §4 Sales (7) · §5 Planning/Strategy/PM (16) ·
   §6 Customer Support (14) · §7 Cross-cutting takeaways + "validated current choices" table
   (pattern → ADR it confirms) · §8 full source list. Every pattern: WHAT / EVIDENCE+URL / MATURITY /
   FIT. One file (single research effort — split per-domain only if it outgrows ~usefulness; no
   pre-split, YAGNI). Tool: Write.

**Tier 1 — evidence-backed hardening (minimal deltas only):**
4. `vault/decisions/ADR-017-evidence-based-panel-hardening.md` — Action: CREATE, shaped as ONE
   decision-unit: **Decision** = (a) verifier tool-asymmetry adopted (template +
   indication); (b) prospective-hindsight adopted as a skeptic TECHNIQUE, explicitly NOT a new seat —
   records the decorrelation math and the evidence caveat (Klein's ~30% is human-team psychology, no
   LLM-context citation yet); (c) minority-flag dissent surface + sycophancy drop-metric with
   critic-owned grounding. **Consequences/Alternatives** = catalog as living evidence reference;
   known limitation: cross-family judging not feasible single-model; Tier 2/3 deferrals with reasons.
   Tool: Write.
4b. `vault/decisions/_inventory.md` — Action: Edit, append the ADR-017 row (ID · title · date ·
   status) AND backfill the missing ADR-016 row (pre-existing drift confirmed by grep — inventory
   currently ends at ADR-015; adjacent fix). Tool: Edit.
5. `personas/_persona-template.md` — Action: Edit, two sentences only: fold "applied consistently to
   every item, not case-by-case opinion" into the existing "critique lens, not a competence boost"
   opener; add ONE verifier-asymmetry sentence ("the critic must exercise a verification affordance
   the drafter didn't — run the check, execute the query, replay the flow"). No new sections. Tool: Edit.
6. `vault/indications/confirmed-vs-advisory-findings.md` — Action: Edit, add the verifier-asymmetry
   corollary next to the existing concrete-check rule (grounding rule and its tool-asymmetry corollary
   live together); Refs [[ADR-017-evidence-based-panel-hardening]]. Wording must be a genuine corollary, not a verbatim copy of the
   step-5 template sentence. No new indication file. Tool: Edit.
7. `personas/_shared/skeptic.md` — Action: Edit, add prospective-hindsight as a named technique:
   one mandate line ("Run a pre-mortem: assume the plan shipped and failed; name the cause in past
   tense — prospective hindsight surfaces risks conditional framing misses") + one checklist line.
   No new persona file. Tool: Edit.
8. `commands/v-team/steps/03-propose-loop.md` — Action: Edit, three minimal deltas: (a) §(e) —
   one clause: any CRITIC-assigned `grounding: confirmed` BLOCKER/MAJOR not reflected as an applied
   plan change MUST surface at the approval gate as a minority flag, **regardless of synthesizer
   relabeling**; (b) §(e) — one line: `grounding` is critic-owned; the synthesizer may not re-grade
   it downward to alter blocking status, which closes the re-grade escape hatch; (c) §(e)
   item 6 metrics list gains the entry `previously-confirmed findings dropped this round (sycophancy flag)`.
   §(f) stop-conditions untouched. Tool: Edit.
9. `tests/unit/v-team.bats` — Action: Edit, add token-grep assertions (short stable tokens per the
   file's own convention — NOT full-sentence matches): (a) `pre-mortem` /
   `prospective hindsight` in skeptic.md; (b) `minority flag` + `sycophancy` in 03-propose-loop.md;
   (c) should-priority: every `vault/decisions/ADR-*.md` file carries a row in `_inventory.md`, with
   an empty-id guard so a malformed filename fails instead of passing vacuously — this guards
   unregistered-ADR drift permanently. No changes to business-personas.bats. Tool: Edit.

**Tier 2 — recorded backlog (not this session):** synthetic-customer/buyer-committee persona class for
business packs (advisory-only by construction); war-game/competitor mode for business+startup-eval;
PR/FAQ narrative-gauntlet mode for /v-pm; confidence-gated auto-accept in /v-cr (dual-condition:
confidence + N consecutive human approvals); red-line topic list for business packs; premortem as a
SUBSTITUTE seat (never co-seated with skeptic) if LLM-context pre-mortem evidence emerges — such a
seat SUPERSEDES (removes) the skeptic.md pre-mortem technique line, never coexists with it (skeptic-10).

**Tier 3 — exploratory backlog:** replay/regression corpus of past panel decisions re-run on
persona/rubric changes; Ralph-loop overnight mode for converged specs; forecaster lens with calibrated
probabilities; architect/editor model split in EXECUTE.

## Test plan

Docs-only deliverable → bats assertions only (dockerized, `make test`):
- v-team.bats phrase-drift guards for the skeptic technique line and the 03-propose-loop minority-flag
  clause + sycophancy metric (plan step 9).
- Full suite must stay green (README indexing, indications index, persona contracts untouched).

## Test Design Dossier

(f2) fan-out gating: **skipped — docs-only deliverable** (no endpoints/handlers/migrations/business
logic). Surfaced at the approval gate per 03-propose-loop §(f2). The phrase-drift assertions above are
the whole test surface.

## Proposed test backlog

| id | source | kind | target | intent | priority | disposition |
|----|--------|------|--------|--------|----------|-------------|
| main-t1 | synthesis | unit(bats) | skeptic.md `pre-mortem`/`prospective hindsight` token | technique can't silently drift out | must | implement — v-team.bats, red on pre-change tree |
| main-t2 | synthesis | unit(bats) | 03-propose-loop `minority flag` + `sycophancy` tokens | dissent surface can't silently drift out | must | implement — v-team.bats, red on pre-change tree |
| arch-t3 | arch | unit(bats) | decisions/_inventory.md covers every ADR file | no ADR ships unregistered | should | change — strengthened to EVERY ADR registered; red on pre-change tree (ADR-016 gap) |
| skeptic-t3 | skeptic | unit(bats) | 03-propose-loop grounding-ownership clause | critic-owned grounding can't drift out | should | change — folded into main-t2 (`critic-owned` token, same test) |

## Refs

- Process record: `vault/plans/2026-07-10-1740-llm-collaboration-patterns.trail.md`
- [[ADR-001-panel-loop-over-peer-debate]] · [[ADR-002-no-stop-on-approval-alone]] ·
  [[ADR-003-tool-grounded-findings]] · [[ADR-016-business-persona-family]] ·
  [[business-persona-family]] · [[v-team]]
