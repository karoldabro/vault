---
type: feature
project: vault
slug: lifecycle-hooks
status: in_progress
owners: []
tags: [feature, hooks, lifecycle, tooling]
---

# lifecycle-hooks

## Scope
Per-project customization of the `/v-work` + `/v-team` lifecycles via `VAULT.md`: `hooks` (per-phase
instructions), `tools` (task-tracker MCP guidance), and a step-1 session-rename suggestion. Non-goals:
shell execution from config (instruction-only), zero-touch rename (impossible — `/rename` is user-only),
hooking the approval gate or v-team panel-loop rounds.

## Contracts
- `VAULT.md` sections `hooks` (phase→prose) and `tools` (`task_tracker`, `task_tracker_mcp`,
  `task_tracker_key`, `guidance`); `behaviour.suggest_rename` (bool, default true). Documented in
  `vault-guide.md` §1.1; per-project examples in `templates/VAULT.md`; tool scenario in
  `tool-playbook.md` §6. See [[../decisions/ADR-010-lifecycle-hooks-tools-rename]].
- 14 hook phases: `on_start`, `pre_/post_analyze`, `pre_/post_load_context`, `pre_/post_propose`,
  `pre_/post_execute`, `pre_/post_commit`, `pre_/post_capture`, `on_end`.

## Behaviors & rules
- VAULT.md read once at step 1 §1.4; all five sections carried forward (steps 2–6 don't re-read).
- Hook value = prose injected at its phase, never run as shell; no `run:` syntax.
- Precedence: `CLAUDE.md` + `indications/` override a conflicting hook; down MCP → fall back + surface;
  malformed → skip + note. Never halt.
- `post_commit` after `git commit`, before `/v-capture`; `post_capture` after; `on_end` on any exit.
- APPROVAL GATE + v-team panel-loop rounds non-hookable (pre/post fire at the loop's outer boundary).
- `suggest_rename` true → step 1 surfaces `/rename <slug>`; never claims the rename happened.

## Coupling
Lives entirely in the framework repo; downstream project repos opt in via their own `VAULT.md`. Shared
by both lifecycles through `commands/v-work/steps/01-analyze.md` (v-team reuses it verbatim).

## Gotchas
- `/rename` works mid-session but only from user input — the model can't fire it; "auto-rename" is not
  achievable, hence `suggest_rename`.
- Per-step hooks must be soft (command-honored) — Claude Code's real hook system fires on tool events
  and can't hook a lifecycle step.

## Sessions
- [[../sessions/2026-06-22-1152-framework-hooks-tools-rename]]
