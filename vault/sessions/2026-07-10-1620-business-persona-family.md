---
type: session
project: vault
date: 2026-07-10
slug: business-persona-family
tags: [session, personas, business, sales, seo, support, startup-eval, v-team]
---

# Session — business persona family (agency-replacement critic suite)

## Goal
Extend the v-team persona system beyond dev/marketing into business-domain critic packs — the user's
"replace the entire agency" ask: positions → one research agent per position drafting personas
(persona = critic lens = one narrow skill) → panel critique → real packs. Hard gates: research first,
no claim without evidence.

## Did
- **Org design approved via AskUserQuestion**: 4 core positions (Sales, SEO & AI Visibility, Support,
  Strategy & Ops) + extras (startup-eval pack, shared Analytics/RevOps critic, marketing additions);
  new `seo.md` pack over extending marketing; all built this session.
- **6 parallel research agents** ("department heads") drafted evidence-graded packs — every external
  claim graded solid/moderate/thin + URL or discarded; each verified its analyzers exist locally.
- **2-round design panel + 2-round diff review** (skeptic, quality, conventions-architect — fallback
  panel, no pack resolves for this repo): 33 findings total, 3 confirmed BLOCKERs, all confirmed
  findings applied. Trail: [[../plans/2026-07-10-1620-business-persona-packs]].
- **Shipped** (feat/business-persona-packs @ 38a7ed8, 22 files +1734/−20): `personas/{sales,seo,
  support,business,startup-eval}.md`; `personas/_shared/business/{data-evidence.md,README.md}`;
  marketing.md → 8 lenses (Paid Media, PR & Community) + suppression cross-refs; `_resolution.md`
  §1 (use-list, union dedup, group-qualified ids, opt-in note, mixing ban) + new §2.2 selection;
  cap-4 propagated to 6 docs; tool-playbook health rows (PostHog, Bright Data, BOE);
  ADR-016 + business-persona-family indication + `tests/unit/business-personas.bats` (14 tests).
- **Tests**: 226 green in Docker (176 unit + 50 integration); repaired a pre-existing broken
  assertion (test-hooks-tools-rename.bats greped wording vault-guide never had).

## Learned
- Research-agent corrections beat the source article: AI-citation drift is **weekly** (SISTRIX:
  Google AI Mode 56%/wk, ChatGPT 74%/wk), not the article's monthly 40–60%; SEO→AI-visibility
  transfer is **engine-specific** (Google AI Mode ~93%/Perplexity ~89% citations from organic top-10;
  ChatGPT decoupled); VoltAgent has **no** `project-idea-validator` (prior art = `assumption-mapping`);
  CB Insights 2026: PMF-failure 43%.
- Panel earned its cost twice: round 2 caught my two round-1 blocker fixes **contradicting each
  other** (multi-pack list × per-pack lens guarantee > hard cap 5), and diff review caught the fix's
  own residual ambiguity ("primary pack" double-defined — skeptic-13) via the manual dry-run.
- Air Canada (Moffatt 2024 BCCRT 149) is the load-bearing citation for support's
  hallucinated-answer-is-a-BLOCKER rule.
- Cross-pack "defer to X pack" prose is dead text unless the resolver can actually co-seat packs —
  boundary language must be backed by selection mechanics.

## Behaviors & rules
- `use_shared: [business/data-evidence]` (group-qualified id) → loader resolves
  `_shared/business/data-evidence.md`; edge: dev+business packs in one `personas.use` list → invalid.
- Multi-pack seating → exactly one architect seat (primary = first list entry); guaranteed domain
  lens is trigger-chosen across ALL seated packs; edge: no trigger matches → relevance pick, never
  zero domain lenses.
- Business deliverable with decision-driving numbers → data-evidence seated; its recompute/method-grep
  findings may be `confirmed`; tool-pull findings stay `advisory` unless the tool-playbook wiring
  check passes.
- A numeric method check (SoV formula, panel size) lives in exactly one lens (data-evidence); edge:
  co-seated Paid Media cedes spend-math recompute to it.
- Support reply with a product claim no KB line backs → confirmed BLOCKER (hallucinated answer).

## Next
- Manual end-to-end: run `/v-team` on a real business project (e.g. givore marketing/support) with
  `project_type: sales|support` to validate §2.2 selection in anger.
- Consider wiring a `VAULT.md` for a business-deliverable repo as the first consumer.
- Deferred: `business/data-method` split (trigger: a 7th numeric facet); international/hreflang SEO
  lens as `personas.add`; a second wired legal source beyond BOE.

## Refs
<!-- filled in Step 4c -->
- [[../plans/2026-07-10-1620-business-persona-packs]]
- [[../decisions/ADR-016-business-persona-family]]
- [[../indications/business-persona-family]]
