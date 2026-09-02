---
type: plan
project: vault
slug: business-persona-packs
status: executed   # proposed | approved | executed | superseded
personas: [fallback-panel (skeptic, quality, conventions-architect)]
rounds: 2
convergence: capped-round-2-fixes-applied-unverified   # cap hit; round-2 findings fixed in v2, no round 3 ran
tags: [plan, team, personas, business, sales, seo, support]
---

# business-persona-packs — team plan

Written by `/v-team`. Extend the persona-critic system beyond dev/marketing into an
"agency-replacement" suite of business-domain packs.

## Task

Extend the v-team persona system with business-domain critic packs — sales, SEO + AI visibility
(GEO), customer support, business strategy & ops, startup-idea evaluation — plus a shared
Analytics/RevOps critic and Paid Media + PR/Community additions to the existing marketing pack.
Personas are **critique lenses** (critic-panel agents). Persona = one narrow skill or a small
skill-set; broad departments get several personas.
Keywords: personas, persona-pack, sales, seo-geo, customer-support, business-strategy,
startup-eval, agency.

## Clarifications (front gate §3a.0a)

- User (mid-turn): "by personas I mean critics panel agents" → same architecture as marketing.md.
- AskUserQuestion: all 4 core positions approved; all extras approved (startup-eval pack, shared
  Analytics/RevOps critic, marketing additions); SEO = new seo.md pack; build all this session.
- Hard gates set by user: no claims without evidence; research first; ask when unsure.

## Research (front gate §3a.0b)

- **AI-SoV article** (digitalapplied.com, grade moderate) → GEO critic. Drafter research refined it:
  citation drift is *weekly* (SISTRIX 82,619 prompts: Google AI Mode replaces 56%/wk, ChatGPT
  74%/wk) and SEO→AI transfer is *engine-specific* (Google AI Mode ~93% / Perplexity ~89% citations
  from organic top-10; ChatGPT decoupled). Prompt-panel bars refined: ≥100 competitive / 15-20 per
  topic directional / ≥2 averaged runs.
- **Local reusable assets** (verified by ls/read): 14 sales-* skills; 6 seo-* agents;
  support-responder, business-panel-experts, finance-tracker, legal-compliance-checker (on-disk
  analyzers); Bright Data skills; PostHog MCP; humanizer; givore-support precedent (maps 1:1 onto
  the support lenses).
- **Public collections**: gtm-agents (role taxonomy, SOLID), VoltAgent assumption-mapping (VUBF +
  kill criteria, fetched live; correction: no project-idea-validator exists there), CB Insights
  failure report verified live (Mar 2026: PMF-failure 43%). Sales tiering (BANT 1-2 stakeholders /
  MEDDIC 3-5 / MEDDPICC 6+) moderate ×3 converging sources; HBR/Bain 1,700-firm pricing survey
  solid; Moffatt v. Air Canada 2024 BCCRT 149 solid (hallucinated support answer = liability).
- **Per-pack evidence appendices**: in the six drafts (session scratchpad `draft-*.md`), every claim
  graded solid/moderate/thin + URL; ungradeable claims discarded.

## Converged plan (v2 — after Round 2 synthesis)

### Persona files

1. **`personas/_shared/business/data-evidence.md`** — CREATE from draft. Mandate widened to own
   method-adequacy (formula / sample / run count / cadence disclosure) alongside recompute,
   measured-source, instrumentability, vanity-metric, snapshot-honesty [skeptic-4]. **Kept as one
   lens with an explicit one-cluster waiver**: concentrating numeric checks in one shared backstop
   is the deliberate anti-god move at pack level [resolves skeptic-11 vs quality-8 conflict —
   quality's position + skeptic's fallback clause; a second shared lens would worsen seat pressure].
2. **`personas/_shared/business/README.md`** — CREATE minus the slug-keyed overlay table
   [quality-1]; keep generic default + `fallback: recompute-only`. ADD the split trigger note: "a
   7th numeric concern splits the group into measurement-validity vs decision-honesty" [quality-8]
   and the one-cluster waiver rationale [skeptic-11].
3. **`personas/sales.md`** — CREATE from draft. Proposal & Pricing re-scoped to the **deal
   instance** (price within approved band, discount ladder + concession compliance, scope↔price,
   paper-process); **cedes reflexive-discounting-as-policy and price-model/margin critique to
   business Unit Economics & Pricing**, boundary line added [quality-7a/b].
4. **`personas/seo.md`** — CREATE from draft; GEO cedes SoV-formula/panel-size/run-count lines to
   data-evidence [skeptic-3]; keeps multi-engine coverage, per-engine citation-bias, citation
   levers, channel instrumentation.
5. **`personas/support.md`** — CREATE from draft; voice findings rule-sourced unconditionally
   [quality-5].
6. **`personas/startup-eval.md`** — CREATE from draft; "Market Skeptic" → **"Demand Signal"**
   [quality-2 + quality-9 rename], re-scoped to demand reachability + real search/scrape signal,
   ceding TAM-as-demand + competitor-traction to skeptic; boundary vs business pack noted.
7. **`personas/marketing.md`** — UPDATE: append Paid Media + PR & Community; "six"→"eight" (lines
   13 + 189) [arch-6]; reciprocal cross-ref on SEO & Discoverability → seo.md [quality-4]; Unit
   Economics boundary note on Paid Media (recompute spend math is deal/campaign-instance scope).

### Resolution & selection (`personas/_resolution.md`)

8. **§1** — use_shared ids may be group-qualified `<group>/<id>` → `_shared/<group>/<id>.md`
   [arch-1]. Non-dev packs resolve only via `VAULT.md` `project_type`/`personas.use` [arch-3].
   **`personas.use` accepts a list** (multi-pack seating) with:
   - **dedup = union**: a shared critic (skeptic, data-evidence) loads once; its overlay is the
     UNION of the seated packs' bindings, each binding running against its pack's deliverable
     surface — never a silent single-pick [skeptic-9];
   - **dev+business mixing disallowed** in one list (a repo that is both runs separate sessions
     per deliverable type; documented with rationale) [skeptic-10];
   - §2 record example updated to show multi-pack seating (`Personas: sales+marketing → [...]`)
     [arch-11].
9. **§2.2 Business-pack critic selection** (new) [arch-2, skeptic-2, skeptic-8, quality-7c]:
   - Seat priority order (deterministic): **primary pack's architect** (primary = first
     `personas.use` entry, single definition — ONE architect seat total; other seated packs'
     architects become relevance-picked lenses) → **guaranteed domain lens** (family-wide ≥1,
     trigger-chosen across ALL seated packs — need not belong to the primary pack) →
     **data-evidence** (when decision-driving numbers) → **skeptic** (high-stakes; startup-eval:
     every go/no-go + sizing doc) → remaining seats fill by relevance.
   - Caps: business packs default `team_max_parallel_critics: 4`; multi-pack (N≥2) seating uses
     hard max 5. Drop order: relevance extras first, never the guaranteed lens or primary
     architect. Note drops in the trail.
   - Keyword→lens table with **one trigger → one lens**: proposal-instance→Proposal & Pricing;
     pricing-model/tiers→Unit Economics & Pricing; sequence→Outreach & Sequencing; go-no-go/
     sizing→startup-eval lenses; KB/deflection→KB & Deflection; escalation→Churn & Escalation;
     content-brief→Content & E-E-A-T; audit→Technical SEO; AI-visibility→GEO [quality-7c].
   - **Cross-pack suppression rule**: a declared-overlap lens is suppressed when the deep pack is
     seated (marketing SEO & Discoverability suppressed when seo.md seated) [quality-7c].

### Docs, tooling, tests

10. **Cap-4 propagation** [arch-8] — §2.2 is the single source; cross-reference it at:
    `_resolution.md:30`, `commands/v-team/steps/03-propose-loop.md:34`, `vault-guide.md:398`,
    `templates/VAULT.md:58`, repo `VAULT.md:52`, `vault/features/v-team.md:37`
    (`commands/_shared/critic-panel.md:50` stays generic, must not contradict).
11. **`templates/VAULT.md` + repo `VAULT.md`** [arch-9, arch-10] — document `personas.use` list
    form (`use: [sales, seo]`); extend project_type enum comment to
    `api-laravel | nuxt | flutter | marketing | sales | seo | support | business | startup-eval`;
    grep vault-guide.md for another enum instance before EXECUTE.
12. **`tool-playbook.md`** [skeptic-5, skeptic-12] — health-check rows with **executable checks**:
    PostHog MCP (a cheap `posthog__exec`/health query), Bright Data (`bdata` auth/status), BOE MCP
    (handshake); note: agent-analyzers resolve via `_resolution.md` §3 base_agent fallback;
    tool-pull findings advisory unless the wiring check passes — recompute/grep = confirmed tier.
13. **Index/docs parity** [arch-5]: README.md `_shared/business` line; vault `indications/_index.md`
    row; **ADR-016** (business persona family: multi-pack seating + union dedup + §2.2 selection +
    data-evidence contract); session capture.
14. **Tests** — new `tests/unit/business-personas.bats` (Docker):
    t1 pack frontmatter contract + ≥1 `## Persona:` per pack; data-evidence persona shape; README
    `group: business` · t2 _resolution.md wires the family (5 slugs, group-path, §2.2, opt-in
    sentence, use-list, union-dedup sentence, dev+business disallow) [+skeptic-t5] · t3
    marketing.md "eight" + both new headers · t4 templates/VAULT.md list form + extended enum
    [arch-t4] · t5 cap-4 stated in 03-propose-loop.md [arch-t5] · q2 no slug-keyed overlay table in
    _shared README · q3 no local-persona name colliding (incl. near-collision) with a shared critic
    id [quality-9 guard] · s3 SoV-method check owned exactly once in seo.md · s6 method-adequacy
    owned in exactly one place with waiver noted [skeptic-t6].
    Manual at EXECUTE self-review: multi-pack selection dry-run fixture (sales+marketing,
    high-stakes numeric → ≤5 seats, ≥1 domain lens, one architect) [skeptic-t4].
    No installer change [arch-4].

## Test plan

Framework repo — bats in Docker. Item 14 is the authoritative backlog. Existing suites unaffected
(verified: v-team.bats + testing-personas.bats iterate only dev packs).

## Test Design Dossier

Docs-only diff → (f2) generative fan-out **skipped** (per §f2 gating; surfaced here for the gate).
The proposed-test backlog below is populated from the panel's PROPOSED_TESTS instead.

### Advisory test hints
- skeptic-t1 (cross-pack deference grep guard) — superseded by multi-pack §1; folded into t2.
- skeptic-t4 (selection dry-run) — manual at EXECUTE self-review (LLM-side logic, not bats-able).

## Proposed test backlog

| id | source | kind | target | intent | priority | disposition |
|----|--------|------|--------|--------|----------|-------------|
| t1 | arch | bats | new pack files | frontmatter contract + persona headers | must | implemented (business-personas.bats ×2 tests) |
| t2 | arch+skeptic | bats | _resolution.md | family wired: slugs, group-path, §2.2, opt-in, use-list, union, disallow | must | implemented (+skeptic-t5 folded in) |
| t3 | arch | bats | marketing.md | "eight" + 2 new persona headers | should | implemented |
| t4 | arch | bats | templates/VAULT.md | use-list form + extended project_type enum | must | implemented |
| t5 | arch | bats | 03-propose-loop.md | business cap-4 stated where the loop reads it | should | implemented |
| q2 | quality | bats | _shared/business/README.md | no slug-keyed overlay table | should | implemented |
| q3 | quality | bats | all packs | no (near-)collision local name vs shared critic id | should | implemented (incl. near-collision list) |
| s3 | skeptic | bats | seo.md | SoV-method check owned exactly once | should | implemented |
| s6 | skeptic | bats | _shared/business/ | method-adequacy single-owner + waiver note | should | implemented |
| s4 | skeptic | manual | selection dry-run | multi-pack ≤5 seats, ≥1 domain lens, 1 architect | must | done — [sales,marketing]+spend forecast seats Deal Strategist + Paid Media + data-evidence + skeptic = 4≤5; exposed skeptic-13, fixed |
| s7 | skeptic (diff) | bats | _resolution.md §2.2 | guaranteed lens not bound to primary pack; "primary" defined once | must | implemented (skeptic-13 guard in seat-rules test) |
| q4 | quality (diff) | bats | §2.2 + marketing.md | trigger-table completeness + suppression pairs incl. Paid Media→data-evidence | should | implemented (quality-10/11 guard test) |
| a6 | arch (diff) | bats | VAULT.md files | knob-block ordering parity | low | skipped — cosmetic; ordering made identical instead (arch-12), section-parity guard already exists |

## Open trade-offs / escalations (for the approval gate)

1. **CONVERGENCE: capped at round 2.** Round 2 raised 1 new confirmed BLOCKER (skeptic-8) +
   5 confirmed MAJORs; all fixes are applied in v2 **but no round 3 verified them** (hard cap).
   Residual risk concentrates in the multi-pack seating semantics (§1 list + union dedup + §2.2
   priority order) — the manual dry-run s4 at EXECUTE is the mitigation.
2. **startup-eval as a standing pack** [skeptic-6]: 2 of 3 lenses overlap business.md. Kept per
   user opt-in, mitigated by Demand Signal re-scope + boundaries. Alternative: fold into business
   + `personas.add`. User decides.
3. **Resolved critic conflict** [skeptic-11 vs quality-8]: data-evidence kept merged (6 numeric
   facets) with explicit waiver + documented split trigger — quality's position adopted via
   skeptic's own fallback clause; seat-math favored it. Flagging because the synthesizer picked
   a side between two critics.
4. **dev+business pack mixing disallowed** [skeptic-10]: simplest safe rule; a mixed repo runs
   separate sessions per deliverable type. Alternative (cross-regime precedence) deemed YAGNI.
5. **GEO confirmed-bar posture**: without a wired SoV tracker, competitive GEO findings stay
   advisory by design.
6. Boilerplate repetition accepted per marketing.md self-containment convention [quality-3/6].

## Critique trail

### Round 1 — panel: skeptic, quality, conventions-architect. 3× REQUEST_CHANGES.
16 findings: 2 BLOCKER (conf), 8 MAJOR (conf), 7 MINOR, 2 NIT. All confirmed BLOCKER/MAJOR applied
in v1; skeptic-6 deferred to gate; quality-3/6 accepted per convention. (Full table in git history
of this file; key: skeptic-1 multi-pack, skeptic-2 cap eviction, skeptic-3/4 SoV/method ownership,
skeptic-5 health checks, arch-1/2/3 resolution contract, quality-1 overlay dual-truth, quality-2
Market Skeptic double-vote.)

### Round 2 — same panel re-verified v1. 3× REQUEST_CHANGES.
All 16 round-1 findings verified resolved as written. 12 NEW: 1 BLOCKER (conf), 5 MAJOR (conf),
4 MINOR, 2 NIT — all confirmed findings applied in v2:

| finding | sev | disposition |
|---------|-----|-------------|
| skeptic-8 §1×§2.2 unsatisfiable under multi-pack | BLOCKER | applied — one-architect seat, family-wide guarantee, N≥2 cap 5, drop order (item 9) |
| skeptic-9 dedup semantics undefined | MAJOR | applied — union composition (item 8) |
| skeptic-10 dev+business mixing unspecified | MAJOR | applied — disallowed + documented (item 8) |
| skeptic-11 data-evidence god-critic | MAJOR | resolved vs quality-8 — merged + waiver + split trigger (items 1-2); escalation #3 |
| skeptic-12 health rows need real commands | MINOR | applied (item 12) |
| quality-7 cross-pack pricing double-vote | MAJOR | applied — deal-vs-model boundary, single owner, 1-trigger-1-lens, suppression rule (items 3, 9) |
| quality-8 data-evidence at god-ceiling | MINOR | applied — waiver + split trigger (item 2) |
| quality-9 Demand Evidence name near-collision | NIT | applied — renamed Demand Signal (item 6) |
| arch-8 cap-4 under-propagated (6 locations) | MAJOR | applied (item 10) |
| arch-9 personas.use list undocumented in template | MAJOR | applied (item 11) |
| arch-10 project_type enum stale | MINOR | applied (item 11) |
| arch-11 ANALYZE record single-pack | MINOR | applied (item 8) |

Metrics: R1 16 findings (13 conf/3 adv) → R2 12 new (10 conf/2 adv). Overlap: the multi-pack fix
drew findings from all three critics (skeptic-8, quality-7, arch-9/11) — clustered into items 8-9.
Convergence: **capped-with-fixes-applied-unverified** (cap 2; new confirmed blocker in final round).

### Diff-review loop (EXECUTE §5.3) — same panel, review posture, on the staged branch

**Round 1.** Verdicts: skeptic REQUEST_CHANGES · quality APPROVE_WITH_NITS · architect
APPROVE_WITH_NITS. All 28 design-round findings verified honored in the real files; the panel's must-
tests confirmed present in `tests/unit/business-personas.bats`. New findings (5):

| finding | sev | disposition |
|---------|-----|-------------|
| skeptic-13 "primary pack" double-defined; guaranteed lens wrongly bound to primary pack (dry-run self-contradiction — cap-eviction bug resurfacing) | MAJOR conf | applied — single first-entry definition; lens trigger-chosen across ALL seated packs; bats guard added |
| quality-10 four pre-existing marketing lenses missing from §2.2 trigger table | MINOR conf | applied — 4 triggers + no-match fallthrough sentence + bats guard |
| quality-11 Paid Media ↔ data-evidence spend-math double-vote reachable under [sales, marketing] co-seating | MINOR conf | applied — conditional cede in Paid Media + suppression-list entry + bats guard |
| arch-12 knob-comment ordering diverged template vs repo VAULT.md | NIT conf | applied — repo reordered to match template |
| arch-13 "primary" ambiguity (same as skeptic-13) | MINOR adv | applied via skeptic-13 fix (first-entry kept; relevance gloss deleted) |

Also verified by architect: the `test-hooks-tools-rename.bats:29` wording fix aligns the test to the
doc's longstanding phrasing (pre-existing failure on main), correct direction.

**Round 2 (scoped verification).** skeptic verdict: **APPROVE** — skeptic-13 closed (both
contradictions removed; the dry-run now provable from the text); the quality-10/11 + fallthrough +
suppression edits checked: no new confirmed BLOCKER/MAJOR ("closes a gap, not opens one"). One NIT
(skeptic-14: this plan doc's item 9 carried the pre-fix wording) — synced.
Review convergence: **clean** (no new confirmed BLOCKER/MAJOR in the final round).
