---
type: decision
id: ADR-016
project: vault
status: accepted
date: 2026-07-10
tags: [decision, personas, business, v-team]
---

# ADR-016 — Business persona family: opt-in packs, shared numeric critic, multi-pack seating

## Context

The persona system covered dev stacks (api-laravel, nuxt, flutter) and one non-dev pack (marketing).
The user asked to extend it into an "agency-replacement" suite — sales, SEO + AI visibility (GEO),
customer support, business strategy & ops, startup-idea evaluation — with personas as critic-panel
lenses (one narrow skill each). Drafted by six parallel research agents (evidence-graded: every claim
solid/moderate/thin + URL or discarded), then a 2-round critique panel (skeptic, quality,
conventions-architect; 28 findings, 3 confirmed BLOCKERs).

## Decision

1. **Five new packs** — `sales`, `seo`, `support`, `business`, `startup-eval` — plus Paid Media and
   PR & Community lenses in `marketing` (6→8). Every persona binds an analyzer that exists in the
   install (sales-* skills, seo-* agents, PostHog/Bright Data/BOE MCPs, recomputation, grep-vs-KB);
   unwired source → advisory, stated.
2. **One shared numeric critic** — `_shared/business/data-evidence.md` (group like `_shared/testing/`).
   Single owner of measured-vs-prior, arithmetic recomputation, **method adequacy** (formula/sample/
   run-count/cadence), instrumentability, vanity-metric, snapshot-honesty — under an explicit
   one-cluster waiver (concentrating numeric checks is the pack-level anti-god move; split trigger
   documented in the group README). Domain lenses cede number checks to it (seo's GEO cedes the SoV
   method audit).
3. **Multi-pack seating** — `personas.use` accepts a list; first entry = primary pack. Shared critics
   load once with **union** overlays. Selection per new `_resolution.md` §2.2: one architect seat
   total, guaranteed ≥1 domain lens, data-evidence relevance-gated, skeptic on high-stakes
   (startup-eval: every go/no-go), business cap default 4 (hard max 5), one-trigger-one-lens table,
   cross-pack suppression (marketing SEO lens suppressed when seo pack seated; pricing split
   deal-instance [sales] vs model/policy [business]). Dev+business packs never mix in one list.
4. **Non-dev packs are opt-in only** (no repo marker); documented in §1.

## Alternatives rejected

- **Doer/worker personas** — user confirmed critics-panel semantics; the framework's persona = lens.
- **One mega business pack** — departments differ in failure modes and analyzers; packs per
  project_type match the existing resolution model.
- **Splitting data-evidence into two lenses now** (skeptic-11) — quality-8's merged-with-ceiling won
  on seat-math; split trigger documented instead.
- **Cross-regime dev+business precedence** — YAGNI; disallowed instead.
- **startup-eval folded into business** (skeptic-6) — kept standing per user decision at the gate;
  overlap mitigated (Demand Signal re-scope, boundary notes).

## Consequences

- A wrong-number business deliverable now fails review on a *confirmed* check (recompute/method grep),
  not opinion. Tool-pull findings stay advisory unless the tool-playbook wiring check passes.
- `_resolution.md` §2.2 + trigger table must be maintained as packs grow; README/vault-guide/templates
  carry the cap-4 and use-list contract (tested in `tests/unit/business-personas.bats`).
- Convergence note: the design panel hit the 2-round cap with round-2 fixes applied but unverified by
  a third round; the multi-pack seating semantics carry the residual risk (mitigated by a manual
  selection dry-run in EXECUTE).

Refs: [[../indications/business-persona-family]] · [[ADR-003-tool-grounded-findings]] ·
[[ADR-004-generic-packs-specifics-in-indications]] · [[ADR-006-testing-critic-group]] ·
plan artifact [[../plans/2026-07-10-1620-business-persona-packs]]
