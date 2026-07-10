---
type: plan
project: vault
slug: llm-collaboration-patterns
status: executed   # proposed | approved | executed | superseded
personas: [framework-fallback: conventions-architect, skeptic, quality]
rounds: 2
convergence: capped   # cap=2 hit; 0 open blockers — all Round 2 findings dispositioned applied
tags: [plan, team, research]
---

# llm-collaboration-patterns — team plan

Written by `/v-team`. The converged implementation plan plus the full critique trail and the
proposed-test backlog. Reviewed at the approval gate; drives EXECUTE.

## Task

Research how leading companies/practitioners structure LLM collaboration (multi-agent/persona patterns
and beyond) across development, marketing, sales, planning, and customer support, and propose which
patterns to adopt into the vault /v-team framework.
Keywords: llm-patterns, multi-agent, persona-critique, workflow-orchestration, business-domains, research

## Clarify gate (§3a.0a) — assumptions

1. **Deliverable shape** — (a) durable, source-cited pattern catalog in the vault AND (b) prioritized
   adoption proposal for the framework; what gets implemented is decided at the approval gate.
2. **Research tooling** — Bright Data CLI (`bdata` 0.3.1) installed; research agents used WebSearch
   primarily, `bdata` as fallback.
3. **Scope** — patterns for *working with* LLMs, not a vendor/tool market survey.
4. **No new code** — markdown deliverables + bats file-contract assertions per framework convention.

## Research gate (§3a.0b) — digest

5 parallel research agents (development · marketing+sales · customer support · planning/strategy/PM ·
cross-domain foundations), ~75 patterns/findings, ~150 sources. Full structured returns preserved in the
session transcript; the catalog deliverable carries the complete set. Key strands:

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

## Converged plan

*(v2 — post Round 2 synthesis. v0/v1 deltas in Critique trail.)*

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
   decision-unit (quality-10): **Decision** = (a) verifier tool-asymmetry adopted (template +
   indication); (b) prospective-hindsight adopted as a skeptic TECHNIQUE, explicitly NOT a new seat —
   records the decorrelation math and the evidence caveat (Klein's ~30% is human-team psychology, no
   LLM-context citation yet); (c) minority-flag dissent surface + sycophancy drop-metric with
   critic-owned grounding. **Consequences/Alternatives** = catalog as living evidence reference;
   known limitation: cross-family judging not feasible single-model; Tier 2/3 deferrals with reasons.
   Tool: Write.
4b. `vault/decisions/_inventory.md` — Action: Edit, append the ADR-017 row (ID · title · date ·
   status) AND backfill the missing ADR-016 row (pre-existing drift confirmed by grep — inventory
   currently ends at ADR-015; adjacent fix, noted in trail). Tool: Edit. (arch-9)
5. `personas/_persona-template.md` — Action: Edit, two sentences only: fold "applied consistently to
   every item, not case-by-case opinion" into the existing "critique lens, not a competence boost"
   opener; add ONE verifier-asymmetry sentence ("the critic must exercise a verification affordance
   the drafter didn't — run the check, execute the query, replay the flow"). No new sections. Tool: Edit.
6. `vault/indications/confirmed-vs-advisory-findings.md` — Action: Edit, add the verifier-asymmetry
   corollary next to the existing concrete-check rule (grounding rule and its tool-asymmetry corollary
   live together); Refs [[ADR-017-evidence-based-panel-hardening]]. Wording must be a genuine corollary, not a verbatim copy of the
   step-5 template sentence (quality-9). No new indication file. Tool: Edit.
7. `personas/_shared/skeptic.md` — Action: Edit, add prospective-hindsight as a named technique:
   one mandate line ("Run a pre-mortem: assume the plan shipped and failed; name the cause in past
   tense — prospective hindsight surfaces risks conditional framing misses") + one checklist line.
   No new persona file. Tool: Edit.
8. `commands/v-team/steps/03-propose-loop.md` — Action: Edit, three minimal deltas: (a) §(e) —
   one clause: any CRITIC-assigned `grounding: confirmed` BLOCKER/MAJOR not reflected as an applied
   plan change MUST surface at the approval gate as a minority flag, **regardless of synthesizer
   relabeling**; (b) §(e) — one line: `grounding` is critic-owned; the synthesizer may not re-grade
   it downward to alter blocking status (skeptic-8 — closes the re-grade escape hatch); (c) §(e)
   item 6 metrics list gains "previously-confirmed findings dropped this round (sycophancy flag)".
   §(f) stop-conditions untouched. Tool: Edit.
9. `tests/unit/v-team.bats` — Action: Edit, add token-grep assertions (short stable tokens per the
   file's own convention — NOT full-sentence matches; skeptic-9/arch-10): (a) `pre-mortem` /
   `prospective hindsight` in skeptic.md; (b) `minority flag` + `sycophancy` in 03-propose-loop.md;
   (c) should-priority: no ADR file newer than the last `_inventory.md` row (guards the arch-9 class
   permanently). No changes to business-personas.bats. Tool: Edit.

**Dropped from v0 (Round 1):** `personas/_shared/premortem.md` + its `_resolution.md`/README/bats
registration (steps 6–9 v0) — correlated double-vote; new indication `evidence-based-panel-design`
(step 10 v0) — third home for owned rules; `add_folders` miscategorization (step 1 v0); dated
research filename (step 2 v0).

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

### Advisory test hints

- skeptic-t1 (mutual-exclusion guard) — moot in v1: premortem seat dropped entirely.
- skeptic-t2 / quality-t1/t2 / arch tests — superseded by v1 step 9 (v-team.bats assertions) or moot
  (no new persona, no new indication).

## Proposed test backlog

| id | source | kind | target | intent | priority | disposition |
|----|--------|------|--------|--------|----------|-------------|
| main-t1 | synthesis | unit(bats) | skeptic.md `pre-mortem`/`prospective hindsight` token | technique can't silently drift out | must | implement — v-team.bats, red on pre-change tree |
| main-t2 | synthesis | unit(bats) | 03-propose-loop `minority flag` + `sycophancy` tokens | dissent surface can't silently drift out | must | implement — v-team.bats, red on pre-change tree |
| arch-t3 | arch (R2) | unit(bats) | decisions/_inventory.md covers newest ADR file | no ADR ships unregistered (arch-9 class) | should | change — strengthened to EVERY ADR registered; red on pre-change tree (ADR-016 gap) |
| skeptic-t3 | skeptic (R2) | unit(bats) | 03-propose-loop grounding-ownership clause | critic-owned grounding can't drift out (skeptic-8) | should | change — folded into main-t2 (`critic-owned` token, same test) |

## Open trade-offs / deferrals

- **Cross-family judging** — evidence-backed, not feasible in a single-model install → ADR-017 known
  limitation.
- **quality-8 (advisory)** — catalog stays one file; revisit split only if it outgrows usefulness.
- **arch-5 (advisory)** — resolved by broadening vault-guide research/ description (step 2) rather than
  moving the catalog to architecture/.
- **skeptic-3 (advisory MAJOR)** — pre-mortem's quantified benefit is human-team evidence; adopted only
  at technique level, recorded in ADR-017; seat-level adoption deferred until LLM-context evidence.

## Critique trail

### Round 0 — draft

v0 proposed: catalog under `add_folders: [research]` + dated filename; new `_shared/premortem.md`
persona seated alongside skeptic on high-stakes work + README/_resolution/bats registration; new
indication `evidence-based-panel-design`; method-enforcer + verifier-asymmetry template notes;
dissent-preservation subsection + flip-tracking in §(e)+(f). Panel: conventions-architect · skeptic ·
quality (framework-fallback seating; precedent: business-persona-family session).

### Round 1 — findings + dispositions

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| skeptic | skeptic-1 | MAJOR | confirmed | premortem = correlated double-vote with skeptic (same jurisdiction, same trigger) | **applied** — seat dropped; technique folded into skeptic.md (v1 step 7) |
| skeptic | skeptic-2 | MAJOR | confirmed | premortem as 4th critic over cap-3 evicts a decorrelated domain lens | **applied** — moot with seat dropped; substitute-seat variant recorded in Tier 2 |
| skeptic | skeptic-3 | MAJOR | advisory | strongest-cost adoption rests on non-LLM evidence (Klein human-team ~30%) | **applied** — technique-level only; caveat recorded in ADR-017 + Open trade-offs |
| skeptic | skeptic-4 | MINOR | confirmed | method-enforcer note duplicates template opener | **applied** — folded into existing paragraph (v1 step 5) |
| skeptic | skeptic-5 | MINOR | confirmed | flip-tracking = metric with no consumer | **applied** — merged into §(e) item-6 metrics + minority-flag gate surface (v1 step 8) |
| skeptic | skeptic-6 | MINOR | confirmed | dissent-preservation ~80% existing; real gap = downgraded confirmed blocker | **applied** — reduced to one clause scoped to downgrade/reject case (v1 step 8) |
| skeptic | skeptic-7 | MINOR | confirmed | ~4 of 10 Tier-1 files exist only to wire the contested seat | **applied** — Tier 1 shrunk 10→6 framework surfaces |
| quality | quality-1 | MAJOR | confirmed | new indication = third home for rules owned elsewhere | **applied** — indication dropped; asymmetry folds into confirmed-vs-advisory-findings (v1 step 6) |
| quality | quality-2 | MINOR | confirmed | method-enforcer restates template opener | **applied** — same as skeptic-4 |
| quality | quality-3 | MINOR | confirmed | verifier-asymmetry note duplicates grounding rule; keep only asymmetry sentence | **applied** (v1 step 5) |
| quality | quality-4 | MINOR | confirmed | dissent subsection duplicates §(e) 3/4/6 | **applied** — one clause only (v1 step 8) |
| quality | quality-5 | MINOR | confirmed | flip-tracking is one metrics-list entry, not a mechanism | **applied** (v1 step 8) |
| quality | quality-6 | MINOR | confirmed | premortem tests belong with shared siblings in v-team.bats, not business-personas.bats | **applied** — moot for premortem (dropped); v1 step 9 targets v-team.bats |
| quality | quality-7 | NIT | confirmed | dated filename matches neither convention for a living reference | **applied** — undated filename (v1 step 3) |
| quality | quality-8 | NIT | advisory | one-file catalog OK (single-responsibility); split only if it outgrows | **recorded** — Open trade-offs |
| arch | arch-1 | MAJOR | confirmed | research/ is a standard optional folder; `add_folders` miscategorizes it | **applied** — `optional: [research]` (v1 step 1) |
| arch | arch-2 | MAJOR | confirmed | premortem is a MODE per the research's own persona×mode framing; fold into skeptic | **applied** — same cluster as skeptic-1 (v1 step 7) |
| arch | arch-3 | MAJOR | confirmed | business-personas.bats tests the wrong shape for flat _shared critics | **applied** — moot for premortem; v1 step 9 uses v-team.bats precedent |
| arch | arch-4 | MINOR | confirmed | README names no flat critic individually; premortem line would create asymmetry | **applied** — README edit dropped |
| arch | arch-5 | MINOR | advisory | catalog is a loose fit for research/ as documented | **applied** — vault-guide description broadened (v1 step 2) |
| arch | arch-6 | MINOR | confirmed | indication restates existing mechanisms; scope to the novel rule | **applied** — via quality-1 disposition; novel rule lives in ADR-017 |
| arch | arch-7 | NIT | confirmed | flip-tracking belongs in §(e) metrics, not §(f) | **applied** (v1 step 8) |
| arch | arch-8 | MINOR | confirmed | verifier-asymmetry should live with the grounding rule (indication), not template-only | **applied** (v1 step 6) |

_Metrics: new confirmed blockers: 0 BLOCKER / 6 confirmed MAJOR · findings: 23 (16 confirmed, 4
advisory, 3 NIT-confirmed) · persona overlap: 3 clusters (premortem-seat ×3 personas, §(e)-dedupe ×5
findings, template-dedupe ×3 findings) · previously-confirmed dropped: n/a (round 1)_

### Round 2 — verification + new findings + dispositions

Verdicts: quality APPROVE_WITH_NITS · skeptic APPROVE_WITH_NITS · conventions-architect
REQUEST_CHANGES. All 21 Round 1 dispositions independently verified applied by their raising critics.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| arch | arch-9 | MAJOR | confirmed | ADR-017 unregistered in decisions/_inventory.md; ADR-016 row already missing (drift proven by grep, independently re-verified by synthesizer) | **applied** — v2 step 4b: append ADR-017 row + backfill ADR-016 |
| arch | arch-10 | NIT | advisory | full-sentence phrase assertions are brittle | **applied** — v2 step 9 token-grep style |
| skeptic | skeptic-8 | MINOR | confirmed | minority-flag escapable via synthesizer grounding re-grade (confirmed→advisory ends the obligation) | **applied** — v2 step 8(b): grounding is critic-owned, no downward re-grade; flag keys on critic-assigned grounding |
| skeptic | skeptic-9 | NIT | confirmed | v-team.bats precedent asserts short structural tokens, not prose sentences | **applied** — v2 step 9 (same cluster as arch-10) |
| skeptic | skeptic-10 | NIT | advisory | Tier-2 substitute seat would double-home the technique | **applied** — supersede note added to Tier 2 item |
| quality | quality-9 | NIT | confirmed | verifier-asymmetry in template+indication+ADR mirrors existing grounding-rule factoring — NOT a duplication regression | **no change needed** — wording-corollary note added to v2 step 6 |
| quality | quality-10 | MINOR | advisory | ADR-017 six-peer-decisions shape looser than ADR-016 precedent | **applied** — v2 step 4: (a)–(c) Decision, rest Consequences/Alternatives |

_Metrics: new confirmed blockers: 0 BLOCKER / 1 confirmed MAJOR (arch-9) · findings-delta: 23→7 ·
persona overlap: 1 cluster (assertion-brittleness ×2) · previously-confirmed dropped this round
(sycophancy flag): 0 — all Round 1 confirmed findings remain applied._

**Convergence: capped** — round cap (2) hit; Round 2 introduced 1 new confirmed MAJOR (arch-9), so the
no-new-blocking-findings stop was not met, but it is dispositioned **applied** in v2 → **0 open
blockers** at the gate.

### Diff review — round 1 (EXECUTE)

Analyzers first: full suite 229/229 green (3 new guards red on pre-change tree — fault-detection
proven). Verdicts: quality **APPROVE** · conventions-architect **APPROVE_WITH_NITS** · skeptic
**APPROVE_WITH_NITS**. All prior confirmed recommendations verified honored in the real diff by their
raising critics. **Stop: no new confirmed BLOCKER/MAJOR → converged clean in 1 round.**

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| quality | quality-11 | NIT | advisory | catalog 527 lines, ~8% over soft split threshold | **recorded** — keep one file per standing disposition |
| arch | arch-11 | NIT | confirmed | bare `[[ADR-017]]` wikilink in plan artifact doesn't resolve | **fixed** — full slug |
| arch | arch-12 | NIT | confirmed | ADR-017 omits `scope:` vs template/majority (matches ADR-016 precedent) | **recorded** — repo-wide template↔practice drift, separate cleanup |
| arch | arch-13 | NIT | advisory | catalog + ADR-017 not yet in _moc | **deferred to capture** (step 6 surface) |
| skeptic | skeptic-11 | MINOR | confirmed | C-06 "90%×90% ≈ 99%" arithmetic self-inconsistent (reads as 81%) | **fixed** — error-complement form (1 − 0.1×0.1) in catalog + plan digest |
| skeptic | skeptic-12 | MINOR | confirmed | every-ADR-registered test was unplanned EXECUTE scope; empty-id vacuous-pass hole | **fixed** — empty-id guard added; invariant recorded in ADR-017 Consequences |

_Metrics: new confirmed blockers: 0 · findings: 6 (4 confirmed MINOR/NIT, 2 advisory NIT) ·
previously-confirmed dropped: 0 · post-fix suite: 229/229 green._

## Refs

[[ADR-001-panel-loop-over-peer-debate]] · [[ADR-002-no-stop-on-approval-alone]] ·
[[ADR-003-tool-grounded-findings]] · [[ADR-016-business-persona-family]] ·
[[business-persona-family]] · [[v-team]]
