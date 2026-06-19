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
- **Testing critic group**: `personas/_shared/testing/` — 6 stack-agnostic testing lenses
  (test-behaviorist, assertion-auditor, edge-case-hunter, test-double-critic, flakiness-sentinel,
  test-harness-critic), one AI-test-failure cluster + one bound analyzer each. Selected on test-touching
  changes via `_resolution.md` §2.1 (cap 3). Rule: [[../indications/testing-persona-group]].
- **Config** (`VAULT.md` `behaviour`): `project_type`, `personas.{use,add,skip}`, `team_max_rounds`
  (2), `team_max_review_rounds` (2), `team_max_parallel_critics` (3, hard max 5).
- **Artifact**: `templates/plan.md` → `<vault>/plans/YYYY-MM-DD-HHMM-<slug>.md` (converged plan +
  critique trail + proposed-test backlog).
- **Finding schema**: severity (BLOCKER/MAJOR/MINOR/NIT) + `grounding` (confirmed|advisory) +
  PROPOSED_TESTS; only `confirmed` findings may block.

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
