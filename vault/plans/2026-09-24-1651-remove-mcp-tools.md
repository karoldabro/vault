---
type: plan
project: vault
slug: remove-mcp-tools
repos: [vault]
status: executed
process_record:
arch_spec: 2026-09-24-1651-remove-mcp-tools.arch.md
human_plan: file:2026-09-24-1651-remove-mcp-tools.human.html
session_of:
session:
tags: [plan, install, tools, mcp]
---

# remove-mcp-tools — plan

<!-- Governed by commands/_shared/document-standard.md. Contract class: current truth only. -->

## Task
Remove all support for the claude-mem memory plugin, the MorphLLM Fast Apply MCP and the Graphify
code graph from the vault framework — installer, uninstaller, commands, playbook, guides, tests, decisions and history — keep
Serena as an optional developer tool, and add `docs/uninstall-removed-tools.md` telling a user how to
remove all three from their machine.
Keywords: claude-mem, MorphLLM, Graphify, Serena, setup.sh, install profile, tool-playbook, uninstall.

## Open & deferred
- needs the operator: approve the plan, including the two edits outside the repo, `~/.claude/CLAUDE.md` and the memory file.
- deferred to the operator: the Graphify hooks and `graphify-out/` folders in 7 repos, this one included; `docs/uninstall-removed-tools.md` lists the commands.
- deferred: the plugin version in `.claude-plugin/plugin.json` stays 1.9.0; a release bump is its own
  `chore(release)` commit, as every earlier release was.
- pre-existing: 9 unit tests fail on the base commit `c23d9b1` as well, among them the doc-lint cases in the open `vault/reports/2026-09-14-2021-doclint-*` reports; this plan does not fix them.
- flaky, not this plan's: the graded tests in `tests/unit/plan-probes.bats` (T-1 to T-11) pass and fail between runs of the same commit. One SC-5 run failed on T-10; it then passed alone and in the next full run.
- deferred: other project vaults under `~/vault/<slug>/` may still mention claude-mem; this plan
  changes only this repo and the two operator files.

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Do project-wired MCPs (Jira/Asana trackers in the `VAULT.md` `tools` section, PostHog/BOE/CRM in personas) go too? | yes | `tool-playbook.md` §6, `templates/VAULT.md`, `personas/sales.md`, `commands/v-cr/tasks/asana.md` | answered | keep them; remove only what the framework installs or prescribes |
| Q-3 | Is Graphify removed too? | yes | Claude transcripts in `~/.claude/projects/`: 3 of 2388 sessions ran `graphify query\|path\|explain` | answered | yes |
| Q-2 | Are historical sessions and finished plans rewritten too? | yes | `vault/sessions/`, `vault/plans/`, `sessions/` | answered | yes, purge history too |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN `checks/mcp-purge-SC-1.sh` greps every tracked and untracked file THE SYSTEM SHALL find no mention of claude-mem, MorphLLM, Graphify or `bun` outside the uninstall guide, ADR-032, this plan's files and checks, and this session's capture | functional | command | `checks/mcp-purge-SC-1.sh` | 0 | MET | `checks/mcp-purge-SC-1.sh` exited 0 |
| SC-2 | WHEN a user runs `setup.sh --full --dry-run`, `setup.sh --light --dry-run` and `setup.sh --with-claude-mem` against a fresh HOME THE SYSTEM SHALL reach the Serena step under `--full` only, install no removed tool under either, and reject `--with-claude-mem`, `--with-graphify` and `--minimal` with exit 2 | delivery | command | `checks/mcp-purge-SC-2.sh` | 0 | MET | `checks/mcp-purge-SC-2.sh` exited 0 |
| SC-3 | WHEN a user opens `docs/uninstall-removed-tools.md` THE SYSTEM SHALL give the exact command for removing the claude-mem plugin, its marketplace and data directory, the MorphLLM MCP, `bun`, and Graphify with its hooks and output folders, plus a command that shows each is gone | functional | command | `checks/mcp-purge-SC-3.sh` | 0 | MET | `checks/mcp-purge-SC-3.sh` exited 0 |
| SC-4 | WHEN an agent reads the Serena section of `tool-playbook.md` THE SYSTEM SHALL state that Serena is optional, and `lib/installers.sh` SHALL still install it | functional | command | `checks/mcp-purge-SC-4.sh` | 0 | MET | `checks/mcp-purge-SC-4.sh` exited 0 |
| SC-5 | WHEN `tests/run.sh tests/unit` runs in Docker THE SYSTEM SHALL fail no test that passes on the base commit `c23d9b1` | functional | command | `checks/mcp-purge-SC-5.sh` | 0 | MET | `checks/mcp-purge-SC-5.sh` exited 0 · v-team PROPOSE output contract is two-layer and translates panel vocabulary |
| SC-6 | WHEN `bin/doc-lint.sh` and `bin/gate.sh all <plan> --phase approve` run on this plan THE SYSTEM SHALL exit 0 | functional | command | `checks/mcp-purge-SC-6.sh` | 0 | MET | `checks/mcp-purge-SC-6.sh` exited 0 |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| dod-1 | `test_command: ./tests/run.sh tests/unit` | met | `checks/mcp-purge-SC-5.sh`: 0 new failures; 9 tests fail on the base commit `c23d9b1` too and are named in its output |
| dod-2 | `lint_command: ./bin/doc-lint.sh --changed` | met | exited 0 with no output |
| dod-3 | `delivery_command: ./bin/gate.sh verdict <plan> --run && ./bin/gate.sh all <plan> --phase close` | met | see the close gate run |

## Verified current state
- `setup.sh` installs claude-mem under `--light` and `--full` through `install_claude_mem_plugin` in `lib/installers.sh`; `bun` exists only for it · read both files · 2026-09-24
- Graphify is installed through `pipx`, and `pipx_install`/`pick_python` have no other caller · `grep -n pipx lib/installers.sh` · 2026-09-24
- No installer installs MorphLLM; only docs prescribe it · `grep -rin morph setup.sh lib/` · 2026-09-24
- On this machine the claude-mem plugin is not installed, `~/.claude-mem` exists, and no MorphLLM MCP is configured · `claude plugin list`, `claude mcp list`, `ls -d ~/.claude-mem` · 2026-09-24
- `checks/mcp-purge-SC-1.sh` finds 88 files naming a removed tool or `bun` before this change · ran it · 2026-09-24

## Decisions

| decision | reason | record |
|----------|--------|--------|
| `tool-playbook.md` keeps its section numbers; the two deleted sections leave gaps | `templates/VAULT.md` copies cite §6 into every project vault, and a renumber cannot reach them | local |
| `--minimal` exits 2 rather than aliasing `--light` | old names are deleted outright, never kept as stubs | local |
| The framework prescribes no memory plugin, no edit MCP and no code graph; Serena is the one optional developer tool | the operator removed them; Graphify ran in 3 of 2388 Claude sessions | `vault/decisions/ADR-032-remove-memory-and-edit-mcps.md` |
| Two install profiles: `--light` (no optional tools, the default) and `--full` (Serena); `--minimal` is deleted | with claude-mem gone, light and minimal install the same thing | `vault/decisions/ADR-021-install-profiles.md` |
| Readers of `install_mode` treat any value but `full` as "no developer tools" | an existing `install_mode: minimal` keeps working | local |
| Project-wired MCPs (task trackers, PostHog, BOE, CRM) stay | operator answer Q-1 | local |
| History is purged, and the one session named after claude-mem is renamed | operator answer Q-2 | local |

## Scope & non-goals
Covers every file in this repo that `checks/mcp-purge-SC-1.sh` reports, plus the two operator files.
Does not uninstall anything from this machine or remove any repo's graph hook, does not touch other project vaults,
and does not change the VAULT.md `tools` section or persona MCP data pulls.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `docs/uninstall-removed-tools.md` | `bin/vault-uninstall.sh --help` and `INSTALL.md` link to it | this plan, W-04 | a user removing the old tools | `checks/mcp-purge-SC-3.sh` exits 1 naming the missing command |
| `install_mode` value in `~/vault/_global/config.md` | the tool fallbacks in `commands/v-work/steps/02-load-context.md`, `tool-playbook.md`, `commands/v-do.md`, `commands/v-work.md`, `commands/v-setup.md` and the doctor in `lib/installers.sh` | `setup.sh` | those six files, each testing `!= full` | any value but `full` reads as "no developer tools", so a stale `minimal` falls back to grep silently |
| the `--light`/`--full` flags of `setup.sh` | the `case "$1"` parser in `setup.sh` | this plan, W-01 | users, `INSTALL.md` and `commands/v-setup.md` | an unknown flag prints usage and exits 2 |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-C1 | `checks/mcp-purge-SC-1.sh` | created: the committed check for SC-1 | Write | exit 0 met, 1 not met, 2 unreadable | SC-1 | runs under `bin/gate.sh verdict --run` | DONE |
| W-C2 | `checks/mcp-purge-SC-2.sh` | created: the committed check for SC-2 | Write | exit 0 met, 1 not met, 2 unreadable | SC-2 | runs under `bin/gate.sh verdict --run` | DONE |
| W-C3 | `checks/mcp-purge-SC-3.sh` | created: the committed check for SC-3 | Write | exit 0 met, 1 not met, 2 unreadable | SC-3 | runs under `bin/gate.sh verdict --run` | DONE |
| W-C4 | `checks/mcp-purge-SC-4.sh` | created: the committed check for SC-4 | Write | exit 0 met, 1 not met, 2 unreadable | SC-4 | runs under `bin/gate.sh verdict --run` | DONE |
| W-C5 | `checks/mcp-purge-SC-5.sh` | created: the committed check for SC-5 | Write | exit 0 met, 1 not met, 2 unreadable | SC-5 | runs under `bin/gate.sh verdict --run` | DONE |
| W-C6 | `checks/mcp-purge-SC-6.sh` | created: the committed check for SC-6 | Write | exit 0 met, 1 not met, 2 unreadable | SC-6 | runs under `bin/gate.sh verdict --run` | DONE |
| W-01 | `setup.sh` | delete the claude-mem and Graphify steps and the `--with-claude-mem`, `--with-graphify` and `--minimal` flags; `--light` installs no optional tool, `--full` installs Serena | Edit | a no-consent run lands on `--light`, which installs nothing (ADR-005) | SC-2 | `checks/mcp-purge-SC-2.sh` | DONE |
| W-02 | `lib/installers.sh` | delete `install_bun`, `check_bun`, `install_claude_mem_plugin`, `_marketplace_add`, `_plugin_install`, `CLAUDE_MIN_VERSION`, `install_graphify`, `check_graphify`, `pipx_install`, `pick_python`, their doctor rows and `~/.bun/bin` in `ensure_session_path` | Edit | keep `claude_cli_ok`, `check_serena`, `install_serena`, `apt_install` | SC-2, SC-4 | `checks/mcp-purge-SC-2.sh` | DONE |
| W-03 | `bin/vault-uninstall.sh` | delete `remove_plugins` and its call and the graphifyy removal; `--tools` removes serena-agent only; the help text points at `docs/uninstall-removed-tools.md` | Edit | never removes uv or node | SC-1 | `tests/integration/vault-uninstall.bats` | DONE |
| W-04 | `bin/vault-init.sh` | delete step 8 (graphify hook install) and the `--no-graphify` flag | Edit | `--no-graphify` then exits as an unknown flag | SC-1 | `tests/integration/vault-init.bats` | DONE |
| W-05 | `docs/uninstall-removed-tools.md` | create: remove the claude-mem plugin, marketplace and `~/.claude-mem`; the MorphLLM MCP; `bun`; graphifyy, its skill, each repo's hook and `graphify-out/`; stale lines in a personal `CLAUDE.md`; each step with a verify command | Write | the one file allowed to name the removed tools for users | SC-3 | `checks/mcp-purge-SC-3.sh` | DONE |
| W-06 | `tool-playbook.md` | delete the claude-mem, Graphify and MorphLLM sections and table rows; state Serena is optional; retarget references to deleted sections | Edit | keep the other section numbers; keep task-tracker, PostHog and BOE guidance (Q-1) | SC-1, SC-4 | `checks/mcp-purge-SC-4.sh` | DONE |
| W-07 | `.gitignore` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-08 | `INSTALL.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-09 | `bin/vault-sync.sh` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-10 | `commands/v-ask.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-11 | `commands/v-capture.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-12 | `commands/v-cr.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-13 | `commands/v-cr/steps/02-gather.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-14 | `commands/v-do.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-15 | `commands/v-guide.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-16 | `commands/v-init.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-17 | `commands/v-loop.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-18 | `commands/v-pm.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-19 | `commands/v-pm/steps/02-load-context.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-20 | `commands/v-pm/steps/05-capture.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-21 | `commands/v-setup.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-22 | `commands/v-team.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-23 | `commands/v-work.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-24 | `commands/v-work/steps/02-load-context.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-25 | `commands/v-work/steps/03-propose.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-26 | `commands/v-work/steps/04-execute.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-27 | `commands/v-work/steps/05-commit-capture.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-28 | `personas/api-laravel.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-29 | `personas/flutter.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-30 | `personas/nuxt.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-31 | `prompts/consolidate-into-indications.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-32 | `scripts/detect-stack.sh` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-33 | `sessions/2026-06-02-1156-v-guide-command.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-34 | `templates/project-moc.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-35 | `templates/vault.gitignore` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-36 | `tests/e2e/Dockerfile.ubuntu` | drop assertions on the removed tools and flags; assert `--light` installs nothing and each removed flag exits 2 | Edit | tests run in Docker only | SC-5 | `checks/mcp-purge-SC-5.sh` | DONE |
| W-37 | `tests/e2e/autoinstall.bats` | drop assertions on the removed tools and flags; assert `--light` installs nothing and each removed flag exits 2 | Edit | tests run in Docker only | SC-5 | `checks/mcp-purge-SC-5.sh` | DONE |
| W-38 | `tests/e2e/run.sh` | drop assertions on the removed tools and flags; assert `--light` installs nothing and each removed flag exits 2 | Edit | tests run in Docker only | SC-5 | `checks/mcp-purge-SC-5.sh` | DONE |
| W-39 | `tests/integration/setup.bats` | drop assertions on the removed tools and flags; assert `--light` installs nothing and each removed flag exits 2 | Edit | tests run in Docker only | SC-5 | `checks/mcp-purge-SC-5.sh` | DONE |
| W-40 | `tests/integration/vault-sync.bats` | drop assertions on the removed tools and flags; assert `--light` installs nothing and each removed flag exits 2 | Edit | tests run in Docker only | SC-5 | `checks/mcp-purge-SC-5.sh` | DONE |
| W-41 | `tests/integration/vault-uninstall.bats` | drop assertions on the removed tools and flags; assert `--light` installs nothing and each removed flag exits 2 | Edit | tests run in Docker only | SC-5 | `checks/mcp-purge-SC-5.sh` | DONE |
| W-42 | `tests/unit/gitignore.bats` | drop assertions on the removed tools and flags; assert `--light` installs nothing and each removed flag exits 2 | Edit | tests run in Docker only | SC-5 | `checks/mcp-purge-SC-5.sh` | DONE |
| W-43 | `tests/unit/plugin-install.bats` | drop assertions on the removed tools and flags; assert `--light` installs nothing and each removed flag exits 2 | Edit | tests run in Docker only | SC-5 | `checks/mcp-purge-SC-5.sh` | DONE |
| W-44 | `tests/unit/setup-autoinstall.bats` | drop assertions on the removed tools and flags; assert `--light` installs nothing and each removed flag exits 2 | Edit | tests run in Docker only | SC-5 | `checks/mcp-purge-SC-5.sh` | DONE |
| W-45 | `tests/unit/v-pm.bats` | drop assertions on the removed tools and flags; assert `--light` installs nothing and each removed flag exits 2 | Edit | tests run in Docker only | SC-5 | `checks/mcp-purge-SC-5.sh` | DONE |
| W-46 | `vault-guide.md` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-47 | `vault/.gitignore` | replace claude-mem recall and Graphify queries with grep over the vault and source, MorphLLM edits with `Edit`; Serena reads as optional | Edit | keep project-tracker MCP guidance; `install_mode` tests read `!= full` | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-48 | `vault/_feature-index.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-49 | `vault/_moc.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-50 | `vault/decisions/ADR-005-installer-auto-exec.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-51 | `vault/decisions/ADR-007-light-siblings-guardrail.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-52 | `vault/decisions/ADR-008-v-cr-remote-pr-review.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-53 | `vault/decisions/ADR-020-claude-code-plugin-distribution.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-54 | `vault/decisions/ADR-021-install-profiles.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-55 | `vault/decisions/ADR-022-vault-git-autosync.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-56 | `vault/decisions/ADR-026-mechanical-session-gates.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-57 | `vault/decisions/_inventory.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-58 | `vault/features/install-distribution.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-59 | `vault/features/vault-git-sync.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-60 | `vault/indications/_index.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-61 | `vault/indications/light-command-siblings.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-62 | `vault/indications/per-user-installer-no-sudo.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-63 | `vault/indications/pin-pipx-python.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-64 | `vault/indications/tools-suggestions-not-rules.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-65 | `vault/indications/verify-plugin-marketplace-qualifier.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-66 | `vault/plans/2026-06-18-1518-setup-auto-install.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-67 | `vault/plans/2026-06-18-1518-setup-auto-install.trail.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-68 | `vault/plans/2026-06-19-1106-v-cr-command.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-69 | `vault/plans/2026-06-22-1152-framework-hooks-tools-rename.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-70 | `vault/plans/2026-07-04-1030-v-family-usage-audit-retiering.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-71 | `vault/plans/2026-07-20-1030-team-presentation-vault-commands.trail.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-72 | `vault/plans/2026-08-04-install-profiles-light-full.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-73 | `vault/plans/2026-08-04-vault-git-autosync.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-74 | `vault/plans/2026-09-01-1000-vcr-delivery-and-coverage.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-75 | `vault/plans/2026-09-01-1000-vcr-delivery-and-coverage.trail.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-76 | `vault/plans/2026-09-04-0900-mechanical-session-gates.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-77 | `vault/plans/2026-09-14-1327-framework-extension-points.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-78 | `vault/plans/2026-09-21-1130-probe-kit-core.arch.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-79 | `vault/plans/2026-09-21-1130-probe-kit-core.human.html` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-80 | `vault/research/subagent-token-economics.md` | rewrite to current truth: no claude-mem, MorphLLM or Graphify; profiles are light (no tools) and full (Serena) | Edit | keep every rule that does not depend on a removed tool; delete a rule that exists only for one | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-81 | `vault/sessions/2026-06-18-1518-setup-auto-install.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-82 | `vault/sessions/2026-06-19-0831-setup-sudo-deadlock-fix.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-83 | `vault/sessions/2026-06-19-0943-pin-pipx-python.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-84 | `vault/sessions/2026-06-19-1114-light-command-siblings.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-85 | `vault/sessions/2026-06-22-1152-framework-hooks-tools-rename.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-86 | `vault/sessions/2026-06-29-1233-humanize-docs.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-87 | `vault/sessions/2026-07-04-1115-v-family-usage-audit-retiering.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-88 | `vault/sessions/2026-08-04-1339-install-profiles-light-full.md` | delete sentences and table rows about the removed tools; keep everything else as written | Edit | a mixed line keeps its other facts (Q-2) | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-89 | `vault/indications/gate-prompts-on-stdin-tty.md` | switch `--minimal` to `--light` and `install_mode: minimal` to `light`; a `--minimal` run exits 2 | Edit | tests run in Docker only | SC-2, SC-5 | `checks/mcp-purge-SC-5.sh` | DONE |
| W-90 | `vault/sessions/2026-06-19-1526-setup-zstd-claude-mem-fixes.md` | rename to `vault/sessions/2026-06-19-1526-setup-zstd-fixes.md` with `git mv`, purge the body, fix every link to the old name | git mv + Edit | no link to the old name survives | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-91 | `vault/decisions/ADR-032-remove-memory-and-edit-mcps.md` | create: the framework prescribes no memory plugin, no edit MCP and no code graph; Serena is the one optional developer tool | Write | names the removed tools once; points at the uninstall guide | SC-1 | `bin/doc-lint.sh` | DONE |
| W-92 | `~/.claude/CLAUDE.md` | delete the claude-mem clause, the Graphify step of the search order, the graphify paragraph of the memory stack and the `# graphify` section | Edit | outside the repo; the operator's own file | SC-3 | `grep -ciE 'claude-mem\|graphify' ~/.claude/CLAUDE.md` prints 0 | DONE |
| W-93 | `~/.claude/projects/-home-kdabrow-workspace-vault/memory/reference_claudemem_mcp_surface.md` | delete, and its line in `MEMORY.md` | rm + Edit | outside the repo | SC-1 | `ls` shows it gone | DONE |
| W-X01 | `commands/v-method.md` | replace Graphify and MorphLLM tool picks with grep, Serena and `Edit` | Edit | keep every unrelated line | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-X02 | `commands/v-reconcile.md` | replace claude-mem recall with grep over the vault | Edit | keep every unrelated line | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-X03 | `commands/v-team/steps/03-propose-loop.md` | replace Graphify orientation with grep or Serena | Edit | keep every unrelated line | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-X04 | `vault/indications/installer-dry-run-seam.md` | drop the removed installers from its examples | Edit | keep every unrelated line | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-X05 | `vault/indications/pin-pipx-python.md` | delete with `git rm`; its rule covered only the pipx install of Graphify, and drop its `_index.md` row | git rm | keep every unrelated line | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-X06 | `vault/sessions/2026-06-19-0943-pin-pipx-python.md` | delete with `git rm`; the session covered only the pipx install of Graphify | git rm | keep every unrelated line | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-X07 | `tests/integration/vault-sync.bats` | use `serena/` as the local-only mount fixture | Edit | keep every unrelated line | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-X08 | `tests/unit/gitignore.bats` | assert the template ignores `serena/` | Edit | keep every unrelated line | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-X09 | `tests/e2e/run.sh` | describe the uv and Serena coverage | Edit | keep every unrelated line | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-X10 | `tests/e2e/Dockerfile.ubuntu` | drop the python and pipx packages | Edit | keep every unrelated line | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |
| W-X11 | `vault/.gitignore` | drop the graph output lines | Edit | keep every unrelated line | SC-1 | `checks/mcp-purge-SC-1.sh` | DONE |

## Rollback
`git revert` of the change commit restores every file, the removed installers included. The two
operator files live outside the repo: restore the `~/.claude/CLAUDE.md` lines from the copy saved at `~/.claude/CLAUDE.md.bak-2026-09-24`, and the memory file is
recoverable only from this plan's text.

## Test plan
- unit · `tests/unit/setup-autoinstall.bats`: `--full --dry-run` emits the Serena command and no claude-mem, bun, pipx or Graphify command.
- unit · same file: `--light --dry-run` emits no tool install, and `--with-claude-mem`, `--with-graphify` and `--minimal` exit 2.
- unit · same file: no flag, no TTY and no `--yes` lands on light.
- unit · `tests/unit/plugin-install.bats`, `tests/unit/v-pm.bats`: drop assertions on claude-mem text.
- integration · `tests/integration/vault-uninstall.bats`: `--tools` removes serena-agent only and calls neither `claude plugin uninstall` nor `pipx`.
- delivery · `checks/mcp-purge-SC-2.sh` runs the real `setup.sh`.

## Refs
- `vault/decisions/ADR-021-install-profiles.md` — the profile decision this plan rewrites.
- `vault/decisions/ADR-005-installer-auto-exec.md` — nothing installs without consent; the no-consent path must stay tool-free.
- `vault/indications/tools-suggestions-not-rules.md` — tool guidance stays suggestion; its Morph safety note goes.
