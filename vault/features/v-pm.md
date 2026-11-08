---
type: feature
project: vault
slug: v-pm
status: in_progress
owners: []
tags: [feature, v-pm, planning, cross-project]
---

# v-pm

## Scope
Read-only feature planning across one or many repos. `/v-pm` refuses without operator success
criteria, reads vault and code, researches prior art, runs a parallel panel of planning reviewers,
and writes a normalized plan split into sessions, each with a brief and a paste-ready run line.
Non-goals: implementation (sessions run through `/v-work` or `/v-team`); a live agent-to-agent
channel (multi-repo coordination stays file-based and async).

## Contracts
- **Command**: `/v-pm <need>` (plan) · `/v-pm reconcile <feature>` · `/v-pm status`. Dispatcher
  `commands/v-pm.md`; steps `01-intake` · `02-load-context` · `03-plan-panel` · `04-seed-workspace` ·
  `05-capture` · `06-reconcile` · `07-status`. Approval gate between steps 3 and 4.
- **Plan home**: single-repo `<project-vault>/plans/<feature>/`; multi-repo `~/vault/_features/<feature>/`.
  Both hold `plan.md` (`templates/feature-plan.md`), `plan.trail.md` and `briefs/<id>-<slug>.md`
  (`templates/handoff.md` with `plan` and `id`).
- **Script**: `bin/pm-plan.sh check | order | set`.
- **Reviewers**: `personas/_shared/planning/` (eight lenses) plus `consumer` and `skeptic`; selection
  `personas/_resolution.md` §2.3; tiers and grounding in the group README.
- **Execution seam**: `commands/_shared/feature-pickup.md`, Step 0 of `/v-work` and `/v-team`; close
  step 5.1a of `commands/v-work/steps/05-commit-capture.md`.
- **Multi-repo workspace**: `requirements.md` · `contracts.md` · `header.md` · `conversation/` ·
  `decisions/` · `projects/<proj>/plan.md` (consumed contract, no tracker). Thread state lives in the
  filename. Docs: `docs/cross-project-workspaces.md`. Record: `vault/decisions/ADR-033-v-pm-planning-loop.md`.

## Behaviors & rules
- No operator success criterion → intake refuses with a drafted line; edge: an explicit yes to the
  drafted line counts, silence does not.
- A plan whose row lacks a brief, whose run line names another repo or command, whose criterion no
  session reaches, or which lacks DD-1 to DD-4 → `bin/pm-plan.sh check` exits 1 and the approval gate
  refuses.
- A session whose dependency is not `done` → feature pickup prints its `order` line and ends the
  session; edge: a dropped dependency reads `blocked` until reconcile re-points it.
- A session closes → step 5.1a writes `done` with the code commit after the commit exists; edge: a
  sync failure is recorded, never halts the close.
- A planning finding blocks only with a repo path, a vault path or a re-runnable command; edge: a URL
  alone stays advisory.
- A legacy workspace (no `plan.md`) keeps its shard readers; edge: reconcile converts it only after
  the operator confirms the row mapping.
- Thread `→pm` is drained only by `/v-pm reconcile`. The contracts-drift check is deterministic.
- A plan whose product makes an LLM call at runtime for its users → `planning/agent-systems` takes a
  trigger seat before `planning/harness-engineer`; edge: developer tooling for Claude Code seats
  `harness-engineer` only.

## Coupling
- Reuses `commands/v-team/steps/03-propose-loop.md` §(c) to §(f); runs no `(f2)`.
- Reads elicitation from `commands/_shared/elicitation.md`, which states the `/v-pm` refusal once.
- `/v-method` reads the session count from `plan.md`.

## Gotchas
- `~/vault/_features` is a separate committed vault with no upstream on this machine, so a claimed row
  stays local until it gets one.
- `contracts.md` must stay structured or the drift check degrades.

## Sessions
- [[../sessions/2026-07-03-1240-v-pm-cross-project-planning]]
- [[../sessions/2026-07-03-1559-vpm-business-knowledge-center]] — requirements knowledge center (1+ repos), id chain, ADR-014
- [[../sessions/2026-10-12-1042-v-pm-planning-loop]] — read-only planner, planning panel, session split, ADR-033
- [[../sessions/2026-10-20-1934-agent-systems-lens]] — agent-systems planning lens, eight agent skills
