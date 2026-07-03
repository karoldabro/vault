---
type: feature
project: vault
slug: v-pm
status: in_progress
owners: []
tags: [feature, v-pm, cross-project, planning]
---

# v-pm

## Scope
Cross-project feature planning + async agent coordination. `/v-pm` drafts a project-agnostic plan into a
shared `_features/<feature>/` workspace; per-project `/v-team <feature>` sessions read it and coordinate
through file-based conversation threads instead of the human relaying context. Non-goals: execution
(that stays with `/v-team` / `/v-work`); a live agent-to-agent channel (coordination is file-based, async).

## Contracts
- **Command**: `/v-pm <necessity>` (plan) · `/v-pm reconcile <feature>` · `/v-pm status`. Dispatcher
  `commands/v-pm.md` (with a tool health-check/fallback table) + steps `01-intake` · `02-load-context`
  (vault-first, OV-first, across every participant vault + `_global` + `_features`) · `03-plan-panel` ·
  `04-seed-workspace` · `05-capture` (planning-session record + cross-project ADRs + OV push + commit) ·
  `06-reconcile` (captures at end) · `07-status`.
- **Workspace** `~/vault/_features/<feature>/`: `requirements.md` (knowledge center — rules `REQ-NN`,
  glossary, decision/state tables; only v-pm writes) · `header.md` · `generic-plan.md` (only v-pm writes;
  how/sequencing, why→requirements) · structured `contracts.md` · `conversation/` ·
  `projects/<proj>/plan.md` (its `## Business rules to satisfy` REQ-id list is v-pm-seeded). No `ledger.md`.
- **Single-repo**: `requirements.md` into `<project-vault>/requirements/<feature>.md` (new `requirements/`
  vault category — plan-time spec); no workspace, no symlink. See [[../decisions/ADR-014-vpm-business-knowledge-center]].
- **Thread protocol**: filename encodes state — `THREAD_<n>_OPEN_→<proj|pm>.md` →
  `…_ANSWERED_<answerer>.md` → `…_RESOLVED.md`; frontmatter `from`/`to`/`asks`.
- **v-team seam**: `commands/v-team/steps/00-feature-pickup.md` (feature-gated Step 0) — auto-pickup +
  deterministic contracts-drift check. Templates under `templates/_features/`. Docs: `vault-guide.md` §13.

## Behaviors & rules
- `/v-pm` authors the `requirements.md` business-knowledge center for **any** feature (1+ repos); only
  the `_features/` workspace + conversation + contracts are gated at 2+ repos (break-even split).
- 1 resolved participant → author `requirements.md` into `<project-vault>/requirements/<feature>.md`
  (project's own vault, no cross-repo write), skip the workspace, hand **execution** to `/v-team`/
  `/v-work`; edge: not a bare hand-off (supersedes the old "no workspace, straight to /v-team" rule).
- `requirements/` = plan-time spec (aspirational); `features/` = established. `/v-capture` Step 5b
  promotes only *built* rules into the dossier carrying each `REQ-NN` id — the id chain
  `requirements.md → (f2) backlog source → established dossier` closes for both `/v-work` and `/v-team`.
- Shard `## Business rules to satisfy` is v-pm-seeded + single-writer-owned; `/v-team` appends coverage,
  preserves the ids, keeps them out of `## Consumed contract` (drift check stays clean).
- Ledger is derived from thread filenames on read → no writer, no multi-session race.
- Thread `→pm` (generic-plan / contract change) is drained only by `/v-pm reconcile`.
- Step 0 contracts-drift check is deterministic (field-by-field vs structured `contracts.md`); LLM
  phrases rationale only.
- Unknown `<feature>` slug → warn loudly, continue as a plain `/v-team` run.
- Reply latency = next open of the asking project's session, or `/v-pm status`; no live channel.

## Coupling
- Inherits the PROPOSE clarify + research front gates from `/v-work` §3a (ADR-012).
- Planning panel borrows finding-schema + synthesize from `/v-team` `03-propose-loop` (not
  `_shared/critic-panel.md`). Execution runs through `/v-team` Step 0. `_features/` wired into `/v-sync`.

## Gotchas
- `_features/` is a separate committed vault, not under any project — it holds the source-of-truth plan +
  contracts and must be versioned + synced independently (never lives next to the local-only `_global/`).
- `contracts.md` must stay structured (tables / typed blocks) or the deterministic drift check degrades.
- Auto-pickup is pull-only; `/v-pm status` is the required push surface so threads don't orphan.

## Sessions
- [[../sessions/2026-07-03-1240-v-pm-cross-project-planning]]
- [[../sessions/2026-07-03-1559-vpm-business-knowledge-center]] — requirements knowledge center (1+ repos), id chain, ADR-014
