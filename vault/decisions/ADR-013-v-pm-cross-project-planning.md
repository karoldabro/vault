---
type: decision
project: vault
id: ADR-013
status: accepted
scope: repo
tags: [adr, v-pm, cross-project, planning, blackboard]
---

# ADR-013 — /v-pm plans cross-project features into a shared blackboard workspace

## Context
Working several products at once, one agent session per repo, made the human the **message bus**:
context was hand-carried between sessions, and a frontend problem tracing back to the api meant shuttling
it back, re-explaining, and carrying the answer forward. Prior art converges on a fix: BMAD-METHOD
(dedicated planning agents produce a plan that gets sharded into self-contained per-worker context),
Spec-Kit (a linear spec→plan→tasks pipeline with a cross-artifact consistency check), and the blackboard
architecture / file-based A2A pattern (agents coordinate through a shared workspace, never live, with
state encoded in filenames for a free audit trail).

## Decision
Add `/v-pm`: a **planner-first** command (modes `plan` · `reconcile` · `status`) that runs a **sequential**
business→product→architect→contract critic pipeline and writes a project-agnostic `generic-plan.md` +
**structured** `contracts.md` into `~/vault/_features/<feature>/` — its own committed vault, symlinked
into each participant project. Per-project `/v-team <feature>` sessions coordinate asynchronously through
a file-based `conversation/`:
- **State lives in the thread filename** (`OPEN_→<proj>` / `ANSWERED_<answerer>` / `RESOLVED`); the
  ledger is a **derived view** computed on read, so nothing writes it and parallel sessions never race.
- **Auto-pickup**: `/v-team`'s new Step 0 (`00-feature-pickup.md`, feature-gated) answers threads
  addressed to this project and runs a **deterministic** contracts-drift check (LLM phrases rationale
  only, never decides existence of drift). `/v-work`'s shared load-context is left untouched.
- **`/v-pm status`** is the push-side surface — one cross-feature inbox sweep — because auto-pickup alone
  is pull-only and would orphan threads, leaving the human in the loop.
- **Break-even gate**: a single-participant feature hands off to `/v-team`; the workspace is overhead
  below 2 repos worked in separate sessions.

The planning panel reuses only the finding-schema + de-biased synthesize from
`v-team/steps/03-propose-loop.md` — **not** `_shared/critic-panel.md`, which is diff-review machinery.

## Consequences
- **Easier**: no more copy-pasting context between sessions; the workspace is the message bus, with a
  full file-based audit trail and crash-safe resume.
- **Honest latency**: there is no live agent-to-agent channel — a reply surfaces only at the next open of
  the asking project's session, or via `/v-pm status`. This is documented, not hidden.
- **Watch for**: threads that stall because a project session is never reopened (`reconcile` staleness
  flag + `status` mitigate); the deterministic drift check depends on `contracts.md` staying structured
  (parseable), not prose. The broad LLM consistency-pass, per-group constitution, and feature archival
  are deferred.
- **Depends on** the clarify + research front gates (ADR-012), which v-pm inherits via the planning
  pipeline. Panel-reviewed (architect·skeptic·dx); all confirmed findings applied.

## Cross-repo impact
Framework-only (the command + templates ship in the vault repo). At runtime `_features/` is a new,
separately-committed vault wired into `/v-sync`; participant project repos gitignore the
`features/<feature>` workspace symlink.
