---
type: decision
project: vault
id: ADR-010
status: accepted
scope: repo
tags: [adr, hooks, lifecycle, tooling]
---

# ADR-010 — Per-project lifecycle customization via instruction-only VAULT.md hooks + tools

## Context
`/v-work` and `/v-team` are generic lifecycles, but projects differ in how-they-work: one tracks
tickets in Jira, another in Asana; some want a reminder or a fetch at a specific lifecycle point. We
needed per-project, per-step customization without (a) executing arbitrary shell from a repo-committed
config, (b) fragmenting the contract across new docs, or (c) re-reading `VAULT.md` at every step (the
framework already reads it once at step 1 §1.4 and carries it forward). We also wanted a meaningful
session name early — but `/rename` can only be invoked by the user, not the model.

## Decision
- **Hooks are instruction-only.** `VAULT.md` `hooks` maps a lifecycle phase → prose, injected into the
  agent at that phase and treated as binding. Never executed as a shell command; there is no `run:`
  syntax. 14 phases: `on_start` + `pre_/post_` per machine step (analyze, load_context, propose,
  execute, commit, capture) + `on_end`. APPROVAL GATE and v-team panel-loop rounds are non-hookable.
- **Per-project tool guidance lives in `VAULT.md` `tools`** (task_tracker, task_tracker_mcp,
  task_tracker_key, guidance); `tool-playbook.md` §6 documents it generically as a **suggestion, not a
  gate** (Claude auto-selects). See [[ADR-004-generic-packs-specifics-in-indications]] — same split.
- **The contract is defined once** in `vault-guide.md` §1.1 (table rows + precedence/failure-mode
  subsection); step files carry only one-line honor markers; config is read once at step 1 and carried.
- **Session rename is a suggestion, not automation.** Step 1 surfaces `/rename <slug>` for the user to
  paste, gated by `behaviour.suggest_rename` (default true). Named `suggest_rename`, not `auto_rename`.

## Consequences
- No new shell-execution surface from repo-committed config; safe by construction.
- Precedence is explicit: `CLAUDE.md` + `indications/` override a conflicting hook; a down MCP falls
  back and surfaces; malformed hook is skipped — never halt (framework ethos).
- Behavior is markdown-honored, so it's not runtime-testable; guarded by doc-consistency bats tests
  (`tests/unit/test-hooks-tools-rename.bats`) incl. a template↔repo VAULT.md drift check.
- The rename can't be zero-touch; users do one paste. Accepted as the honest ceiling of `/rename`.

## Cross-repo impact
Repo-local (the framework). Downstream project repos opt in by adding `hooks`/`tools` to their own
`VAULT.md`; no change is forced on them (all sections optional).
