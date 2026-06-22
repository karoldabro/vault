---
type: session
project: vault
date: 2026-06-22
topic: framework-hooks-tools-rename
files_touched: [VAULT.md, templates/VAULT.md, vault-guide.md, tool-playbook.md, commands/v-work.md, commands/v-team.md, commands/v-work/steps/01-analyze.md, commands/v-work/steps/02-load-context.md, commands/v-work/steps/03-propose.md, commands/v-work/steps/04-execute.md, commands/v-work/steps/05-commit-capture.md, commands/v-team/steps/03-propose-loop.md, commands/v-team/steps/04-execute-loop.md, tests/unit/test-hooks-tools-rename.bats]
decisions: [ADR-010]
tags: [session, hooks, tooling, lifecycle, session-rename]
---

# framework-hooks-tools-rename

## Goal
Add three lifecycle capabilities to `/v-work` + `/v-team`: per-project task-tracker/MCP guidance, per-project per-step instruction hooks, and an auto session-rename after step 1.

## Did
- Ran `/v-team` (degraded to v-work-with-a-panel — no persona pack resolves for the framework repo itself). Plan artifact: [[../plans/2026-06-22-1152-framework-hooks-tools-rename]].
- Added `hooks` (14 instruction-only phases) + `tools` (task-tracker MCP) sections to [[VAULT.md]] schema; documented the contract once in `vault-guide.md` §1.1 (table rows + "Lifecycle hooks — phases, precedence & failure modes").
- Wired honoring into `commands/v-work/steps/01-analyze.md` (load+carry all 5 sections at §1.4; fire `on_start`/`pre_analyze` at §1.4b; suggest `/rename` at §1.5) and one-line honor markers in steps 02–05 + v-team loop steps.
- Added `tool-playbook.md` §6 "Project tools" + a top "suggestions, not rules" framing note; softened selection language, kept safety rules firm.
- Synced `templates/VAULT.md` + repo `VAULT.md`; new `tests/unit/test-hooks-tools-rename.bats` (7 doc-consistency tests). Full unit suite 109/109 green in Docker.
- Two-lens critic panel at PROPOSE (REQUEST_CHANGES → all confirmed findings applied) and at diff-review (APPROVE + APPROVE_WITH_NITS → 3 minor nits applied).
- Committed `144351c` on branch `feat/lifecycle-hooks-tools-rename`.

## Learned
- **`/rename` exists and works mid-session, but is user-invoked only.** The model cannot fire built-in slash commands from inside a turn (harness interprets slash commands only from user input). Confirmed via claude-code-guide. Title is not in the transcript JSONL; no hook/CLI/settings path sets it. → "auto-rename" is impossible; the honest deliverable surfaces `/rename <slug>` for a one-paste run.
- The framework already reads `VAULT.md` **once at step 1 §1.4 and carries it forward**; steps 02–06 don't re-read it. Any per-step config (hooks) must ride that carry-forward, not a re-read.
- Per-lifecycle-step hooks must be **soft** (command-honored), not harness hooks — the Claude Code hook system fires on tool events, and can't hook "v-work step 3".

## Behaviors & rules
- VAULT.md is read once at step 1 §1.4 → all five sections (`config`/`structure`/`behaviour`/`hooks`/`tools`) carried through the run; steps 2–6 never re-read it.
- A `hooks` value is prose injected at its phase, never executed as a shell command; no `run:` syntax exists.
- Hook precedence: `CLAUDE.md` + `indications/` override a conflicting hook (surface at gate); a hook needing a down MCP falls back + surfaces; malformed hook → skip + note. Never halt.
- Phase set = 14: `on_start` + `pre_/post_` per step (analyze, load_context, propose, execute, commit, capture) + `on_end`; APPROVAL GATE and v-team panel-loop rounds are non-hookable.
- `post_commit` fires after `git commit`, before `/v-capture`; `post_capture` after `/v-capture`; `on_end` on any termination (success, gate-reject, abort).
- `behaviour.suggest_rename` default true → step 1 surfaces `/rename <slug>`; the lifecycle never claims the rename happened.
- tool-playbook guidance is suggestion, not gate — Claude auto-selects; only genuine safety notes (Morph markers) stay firm.

## Next
- Merge `feat/lifecycle-hooks-tools-rename` → main (not yet pushed).
- `pre_<step>` hooks shipped, but no per-critic-round hooks in v-team (panel rounds non-hookable) — revisit only if a real need appears.
- Consider a future real per-project task-tracker example repo (Jira/Asana) to dogfood the `tools` section end-to-end.

## Refs
- [[../decisions/ADR-010-lifecycle-hooks-tools-rename]]
- [[../features/lifecycle-hooks]]
- [[../plans/2026-06-22-1152-framework-hooks-tools-rename]]
- [[tools-suggestions-not-rules]]
