---
type: plan
project: vault
slug: business-persona-packs
status: executed   # proposed | approved | executed | superseded
process_record: 2026-07-10-1620-business-persona-packs.trail.md
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

## Plan

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
     content-brief→Content & E-E-A-T; audit→Technical SEO; AI-visibility→GEO [quality-7c]. The
     landed table also covers every pre-existing marketing lens; `personas/_resolution.md` §2.2
     holds its authoritative form and this plan must not restate it.
   - **No-match fallthrough**: a deliverable matching no trigger falls through to a relevance pick.
     The guarantee still holds — seat the most relevant domain lens, never zero [quality-10].
   - **Cross-pack suppression rule**: a declared-overlap lens is suppressed when the deep pack is
     seated (marketing SEO & Discoverability suppressed when seo.md seated) [quality-7c]. Paid Media
     cedes the spend-math **recompute** to `business/data-evidence` when a business pack is
     co-seated, keeping bid-strategy, incrementality and ad-policy judgement [quality-11].

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
`## Proposed test backlog` below is the authoritative list.

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

1. **Residual risk: multi-pack seating semantics** (§1 list + union dedup + §2.2 priority order).
   The design fixes in this area were applied but never independently re-verified. **Failure mode:**
   a multi-pack seating that silently drops a seated pack's binding, or exceeds the hard max of 5
   seats. **Mitigation:** the manual dry-run s4 at EXECUTE, which must run before this plan closes.
2. **startup-eval as a standing pack** [skeptic-6]: 2 of 3 lenses overlap business.md. Kept per
   user opt-in, mitigated by Demand Signal re-scope + boundaries. Alternative: fold into business
   + `personas.add`. User decides.
3. **data-evidence kept merged** (6 numeric facets) with an explicit waiver + a documented split
   trigger: a 7th numeric concern splits the group into measurement-validity vs decision-honesty.
   Seat math favored the merge. Two opposed positions were reconciled here, so the approval gate
   should confirm it rather than inherit it.
4. **dev+business pack mixing disallowed** [skeptic-10]: simplest safe rule; a mixed repo runs
   separate sessions per deliverable type. Alternative (cross-regime precedence) deemed YAGNI.
5. **GEO confirmed-bar posture**: without a wired SoV tracker, competitive GEO findings stay
   advisory by design.
6. Boilerplate repetition accepted per marketing.md self-containment convention [quality-3/6].

## Refs

- Process record: `vault/plans/2026-07-10-1620-business-persona-packs.trail.md` — the findings,
  dispositions and rejected options behind this plan.
- `personas/_resolution.md` §1 and §2.2 — the seating contract this plan writes.
- `commands/_shared/critic-panel.md` — the generic panel contract the cap-4 rule must not contradict.
