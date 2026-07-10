---
type: persona-group
group: business
tags: [persona, shared, business]
---

# business — critic group

A **stack-agnostic business/analytics critic group** for the business-pack family — the non-dev packs
whose deliverables are decisions and numbers rather than code: `sales`, `seo`, `support`, `business`,
`startup-eval`. These lenses review *business deliverables* the way `_shared/testing/*` reviews test
code. A pack composes them via `use_shared: [business/data-evidence]` (group-qualified id — the loader
resolves `_shared/business/<id>.md`, see `_resolution.md` §1) plus its own **inline overlay** binding
the real data source — the pack's overlay is the single source of truth for the binding; this README
carries no per-pack table. Each lens binds a **real check** so findings can be `confirmed` — only
confirmed findings block (see [[confirmed-vs-advisory-findings]]). Like every `_shared` lens they stay
generic and **detect** the project's wired tooling ([[packs-detect-not-assume]]); an unwired source
downgrades the finding to `advisory`. Universal fallback binding: **recomputation only + grep the
analytics docs** — always available, no external tool.

## The lenses

| Persona | Owns (failure cluster) | Grounding |
|---------|------------------------|-----------|
| [[data-evidence]] | unsourced/fabricated numbers · broken arithmetic chains · undisclosed/inadequate metric method · vanity-for-decision metric · snapshot-as-trend · non-instrumentable KPI | **gold** — recomputation + method grep (always available); measured source where wired |

**Facet ceiling (split trigger).** `data-evidence` deliberately concentrates the numeric checks under a
documented one-cluster waiver (see its file) — that concentration is the pack-level anti-god move. Its
ceiling is the six facets above: if a **seventh** numeric concern arrives, split the group into two
lenses — *measurement-validity* (recompute · measured-source · instrumentability) and *decision-honesty*
(method adequacy · vanity metric · snapshot-as-trend) — instead of widening further. Structured as a
group so that split needs no pack re-plumbing.

## Decorrelation boundary
`data-evidence` owns *whether the number is real and its method sound* (measured / recomputed /
disclosed / instrumentable), NOT *whether the assumption behind it holds* → [[skeptic]], NOT *whether
it's the right strategic lever* → the pack's architect. It audits the figure; it does not re-pick the
strategy.

## Selection
Per `_resolution.md` §2.2: seated when a business deliverable carries numbers that drive a decision
(spend, pricing, forecast, funnel, market size); skipped on pure-qualitative work (tone, positioning
narrative). Relevance-gated, not default-in.
