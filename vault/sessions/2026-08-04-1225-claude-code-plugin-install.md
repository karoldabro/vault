---
type: session
project: vault
date: 2026-08-04
topic: Ship the framework as a Claude Code plugin (second install route)
files_touched:
  - .claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - commands/v-setup.md
  - hooks/hooks.json
  - scripts/detect-stack.sh
  - lib/plugin-detect.sh
  - install.sh
  - setup.sh
  - vault-guide.md
  - INSTALL.md
  - README.md
  - docs/commands.md
  - tests/unit/plugin-install.bats
decisions: [ADR-020]
tags: [session, install, plugin, distribution]
---

# Ship the framework as a Claude Code plugin (second install route)

## Goal
Make the vault framework installable through Claude Code's plugin system, alongside the existing
`install.sh` symlink route, without breaking the symlink route.

## Did
- Added `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. The repo is its own
  single-plugin marketplace (`"source": "./"`), so one clone serves both roles. Install is
  `/plugin marketplace add karoldabro/vault` then `/plugin install vault@kdabro-vault`.
- Moved `commands/attic/` → `attic/` and `commands/README.md` → `docs/commands.md`. Every `.md` under
  `commands/` becomes an invocable command under a plugin install; `install.sh` skipped both by name,
  the plugin loader does not.
- Reworked framework-path resolution ([[../decisions/ADR-020-claude-code-plugin-distribution]]).
  `$VAULT_FRAMEWORK_PATH` now resolves `${CLAUDE_PLUGIN_ROOT}` first, then `VAULT.md`, then
  `~/vault/_global/config.md`, then the default. Replaced all 57 hardcoded `~/.claude/commands/`
  references with `$VAULT_FRAMEWORK_PATH/commands/`. Documented in `vault-guide.md` §1.1 and
  `01-analyze.md` §1.4.
- Added a one-line path note to the 18 step files that use `$VAULT_FRAMEWORK_PATH`, placed **below**
  the first heading — a note at the top of a frontmatter-less file becomes its picker description.
- Added `/v-setup` (`commands/v-setup.md`): wraps `setup.sh` with a consent gate, since installing a
  plugin never runs an installer. Added `hooks/hooks.json` + `scripts/detect-stack.sh`: a SessionStart
  check that detects a missing stack and points at `/v-setup`, and installs nothing.
- Added `lib/plugin-detect.sh` and wired it into both installers: `install.sh` refuses when the plugin
  is present or when it is itself running from the plugin cache; `setup.sh` skips its symlink step in
  the same conditions. `VAULT_ALLOW_DOUBLE_INSTALL=1` overrides.
- Added `tests/unit/plugin-install.bats` (21 tests) and `make validate-plugin`. Updated
  `communication-contract.bats` and `v-pm.bats` for the moved paths. Full offline suite: 303 passing.
- Rewrote the install docs across `README.md`, `INSTALL.md`, `docs/commands.md`, `vault-guide.md` §11.

## Learned
- `${CLAUDE_PLUGIN_ROOT}` substitutes inside skill and command **content**, not just hook and MCP
  configs. That is what makes one file work from both a plugin cache and a git clone: the placeholder
  resolves under a plugin install and stays literal otherwise, so the text can branch on its own form.
- A plugin's install directory is versioned and changes on every update. Anything that persists it —
  `config.md`'s `framework_path`, a `VAULT.md` key — goes stale silently and points at a
  garbage-collected directory.
- `claude plugin validate --strict` fails on a missing `version`. Omitting `version` makes Claude Code
  fall back to the git commit SHA, so every commit to main ships to every installed user.
- Claude Code takes a command's picker description from frontmatter, or from the file's first line when
  there is none. Inserting a note at the top of the 18 frontmatter-less step files replaced every step's
  description with that note.
- The plugin cache is a **copy**, not a checkout. `git pull` in the clone does nothing for a plugin
  install; only `/plugin update` does, and only when `version` changed.

## Behaviors & rules
- A file lands under `commands/` → it becomes an invocable slash command under a plugin install; docs
  and retired commands therefore live outside it; edge: `commands/_shared/` is accepted noise, since
  moving it would ripple through every dispatcher.
- A command file references a framework file → it addresses it through `$VAULT_FRAMEWORK_PATH`, never
  through `~/.claude/commands` or a relative path.
- Any file that uses `$VAULT_FRAMEWORK_PATH` → it also carries the resolution rule, because step files
  are loaded on demand many turns after the dispatcher resolved it.
- A note or directive is added to a command file with no frontmatter → it goes below the first heading,
  never above it; edge: above the heading it silently becomes the command's description.
- Both install routes are active → every command exists twice under two names reading two different
  copies; installers refuse or skip rather than produce that state; edge:
  `VAULT_ALLOW_DOUBLE_INSTALL=1` is the deliberate override.
- A plugin change is published → `version` in `plugin.json` is bumped; edge: without a bump
  `/plugin update` reports users are already current and ships nothing.
- Something runs unattended at SessionStart → it detects only, never installs (ADR-005 consent gate).

## Next
- Not yet published: the marketplace is only usable once `feat/claude-code-plugin` reaches the default
  branch on GitHub. `/plugin marketplace add karoldabro/vault` reads the default branch.
- Not yet installed anywhere. The plugin route is untested end-to-end against a live Claude Code
  install; only `claude plugin validate --strict` and the bats suite have run.
- Open: whether to keep `install.sh` long-term. Kept for now because this machine runs on it and the
  framework is developed in-place, where a cache copy is the wrong thing to edit.
- The plugin copies the whole repo into the cache, including `tests/` and the framework's own `vault/`.
  Harmless, but a `.claudeignore`-style trim would be worth checking if the cache size ever matters.

## Refs
- [[../decisions/ADR-020-claude-code-plugin-distribution]]
- [[../decisions/ADR-005-installer-auto-exec]]
- [[2026-08-03-1300-drop-openviking-dependency]]
- [[2026-08-03-1045-decision-communication-contract]]
