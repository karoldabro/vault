---
type: feature
project: vault
slug: v-team
status: in_progress
owners: []
tags: [feature, command, multi-agent]
---

# v-team

## Scope
`/v-team` — a persona-critique development lifecycle command, heavier sibling of `/v-work` for BIG /
high-stakes work. After an initial plan draft, a panel of project-specific persona critics reviews in
parallel (each through a tool-grounded lens), proposing design fixes + tests; a synthesizer revises and
the panel re-loops to convergence. The same personas then review the implementation diff. Non-goals:
not the default lifecycle (routine work stays on `/v-work`); critics do not message each other.

## Contracts
- **Command**: `commands/v-team.md` (dispatcher) + `commands/v-team/steps/{03-propose-loop,
  04-execute-loop}.md`. Reuses `/v-work` steps 01/02/05 verbatim → **depends on `/v-work` installed**.
- **Persona library**: `personas/_shared/{security,performance,quality,skeptic}.md` (reusable lenses)
  composed by stack packs `personas/{api-laravel,nuxt,flutter}.md` via `use_shared` + overlays + local
  architects. Selection + resolution: `personas/_resolution.md`. Authoring specs: `_persona-template.md`,
  `_pack-template.md`.
- **Business persona family** (ADR-016): non-dev packs `personas/{marketing,sales,seo,support,business,
  startup-eval}.md` (opt-in only — `VAULT.md` `project_type`/`personas.use`, no repo marker) + shared
  numeric critic `personas/_shared/business/data-evidence.md` (group-qualified `use_shared` id; single
  owner of arithmetic recompute + metric method audit, one-cluster waiver). Multi-pack seating:
  `personas.use` list (first entry = primary → the one architect seat), union overlay dedup, `§2.2`
  selection (guaranteed trigger-chosen lens across all seated packs, business cap 4, one-trigger-one-
  lens, cross-pack suppression); dev+business never mix in one list. Analyzer wiring health checks:
  `tool-playbook.md` (PostHog/Bright Data/BOE rows). Rule: [[../indications/business-persona-family]].
  Tests: `tests/unit/business-personas.bats`.
- **Testing critic group**: `personas/_shared/testing/` — 6 stack-agnostic testing lenses
  (test-behaviorist, assertion-auditor, edge-case-hunter, test-double-critic, flakiness-sentinel,
  test-harness-critic), one AI-test-failure cluster + one bound analyzer each. Selected on test-touching
  changes via `_resolution.md` §2.1 (cap 3). Rule: [[../indications/testing-persona-group]]. Plus a 7th
  critic `system-domain-expert` (grounded in the repo's own `indications/`+`features/` rules), seated in
  EXECUTE §5.3 whenever the (f2) fan-out ran (`_resolution.md` §2.1a).
- **Test-design generators** (ADR-011): `personas/_shared/testing/design/` — fault-relation-prospector,
  business-logic-cartographer, boundary-property-explorer. Run in PROPOSE sub-phase **(f2)** (generation
  only, no analyzer, never on the panel); author the Test Design Dossier + Proposed test backlog;
  confirmed post-impl in EXECUTE. Rule: [[../indications/generators-emit-critics-confirm]].
- **Config** (`VAULT.md` `behaviour`): `project_type`, `personas.{use,add,skip}` (`use` accepts a list
  for multi-pack seating), `team_max_rounds` (2), `team_max_review_rounds` (2),
  `team_max_parallel_critics` (3, business packs 4, hard max 5), `team_max_test_designers` (3).
- **Artifact**: `templates/plan.md` → `<vault>/plans/YYYY-MM-DD-HHMM-<slug>.md` (converged plan +
  critique trail + proposed-test backlog).
- **Finding schema**: severity (BLOCKER/MAJOR/MINOR/NIT) + `grounding` (confirmed|advisory) +
  PROPOSED_TESTS; only `confirmed` findings may block.
- **Panel hardening** (ADR-017): `grounding` is critic-owned (synthesizer may not re-grade it downward);
  a confirmed BLOCKER/MAJOR dispositioned ≠ applied surfaces at the gate as a **minority flag**; round
  metrics carry a previously-confirmed-dropped (sycophancy) count; confirming checks obey **verifier
  asymmetry** ([[../indications/confirmed-vs-advisory-findings]] corollary); pre-mortem is a skeptic
  TECHNIQUE, never a seat. Evidence reference: [[../research/llm-collaboration-patterns]] (living
  catalog). Guards: `tests/unit/v-team.bats` (token greps + every-ADR-registered invariant).
- **PROPOSE front gates** (ADR-012, shared `§3a`): `§3a.0a` clarify (assumptions + `AskUserQuestion`
  for plan-changing doubts) and `§3a.0b` external research (ground vs the wild; reconcile contradicting
  consensus in writing). Run in the v0 draft **before the panel spawns**; an unresearched design /
  unsound assumption is a legitimate critic finding. Rule: [[../indications/propose-front-gates]].

## Coupling
- Reuses Claude Code agent types as persona `base_agent`s (system-architect, backend-architect,
  security-engineer, performance-engineer, refactoring-expert, mobile-app-builder, frontend-*).
- Falls back to `/v-work` dispatch + `deploy-review-panel` when no pack resolves.
- Distributed by `install.sh` (no change needed — existing globs); `personas/` + `templates/` resolve
  at runtime via `$VAULT_FRAMEWORK_PATH`.

## Gotchas
- Stop conditions: round cap OR no-new-confirmed-blockers — **never unanimous approval alone** (false-
  convergence guard). Cap hit with open blockers → escalate to user.
- Personas are focus/rubric, not competence — each must run its bound analyzer; unbacked claims are
  `advisory`, never blocking.
- Do not run `/v-team` inside harness plan mode (blocks the `plans/` write; Step 4 is its own gate).
- `nuxt`/`flutter` packs are grounded against the real givore repos but kept **generic** (state
  approach detected, not hardcoded); project specifics (state pattern, service layer, brand, domain
  rules) flow in from each repo's `indications/`. Each has 3 local lenses (Nuxt: Component/State,
  Integration/SSR, Accessibility & i18n · Flutter: Widget/State, Platform Integration, UX & Resilience).

## Sessions
- [[../sessions/2026-06-16-1038-v-team-persona-critique-command]]
- [[../sessions/2026-06-16-1135-v-team-nuxt-flutter-packs]]
- [[../sessions/2026-06-19-0954-testing-persona-group]]
- [[../sessions/2026-06-29-0818-split-test-planning-step]]
- [[../sessions/2026-07-10-1620-business-persona-family]]
- [[../sessions/2026-07-03-1205-propose-clarify-research-gates]]
- [[../sessions/2026-07-10-1740-llm-collaboration-patterns]]
