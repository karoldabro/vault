---
type: decision
project: vault
id: ADR-020
status: accepted
scope: repo
tags: [adr, install, distribution, plugin]
---

# ADR-020 — Distribute the framework as a Claude Code plugin, alongside the symlink install

## Context

The framework has shipped one way since the `_process/` submodule was dropped (2026-06-15): clone the
repo, run `setup.sh`, and `install.sh` symlinks `commands/` into
`~/.claude/commands/` and `output-styles/` into `~/.claude/output-styles/`. That works, but it asks a
new user for a git clone, a shell, and a path convention before they get a single slash command.

Claude Code's plugin system does the same job through a two-line install and handles updates, so the
question was what it costs to support it.

Three things stood in the way:

1. **Hardcoded install paths.** 57 references to `~/.claude/commands/...` (dispatchers reading their
   step files) and 68 to `$VAULT_FRAMEWORK_PATH/...` (templates, personas, the guide). A plugin's files
   live in a versioned cache directory that is neither.
2. **`commands/` was not clean.** A plugin turns every `.md` under `commands/` into an invocable
   command. `install.sh` skipped `README.md` and `attic/` by name; the plugin loader has no such list.
3. **Dependencies.** `setup.sh` installs the tool stack (uv/Serena, bun/claude-mem, pipx/Graphify) and
   scaffolds `~/vault/_global/`. Claude Code deliberately runs no installer when a plugin lands, and
   [[ADR-005-installer-auto-exec]] commits us to printing every source before running it — which rules
   out doing this silently from a hook even though the hook API allows it.

## Decision

**Ship both install routes. The plugin is the documented default; `install.sh` stays for developing the
framework itself.** They are mutually exclusive and the installers enforce that.

- The repo is its own single-plugin marketplace: `.claude-plugin/plugin.json` plus
  `.claude-plugin/marketplace.json` with `"source": "./"`. One repo, one clone, one URL to share.
- **`version` in `plugin.json` is pinned and bumped per release.** Omitting it makes Claude Code fall
  back to the commit SHA, which ships every commit on the default branch to everyone installed. A pinned
  version makes publishing deliberate. It also satisfies `claude plugin validate --strict`, which we run
  via `make validate-plugin`.
- **`$VAULT_FRAMEWORK_PATH` resolves `${CLAUDE_PLUGIN_ROOT}` first**, then `VAULT.md` →
  `framework_path`, then `~/vault/_global/config.md`, then `~/workspace/vault`. The placeholder is
  substituted inside command content under a plugin install and stays literal otherwise, so one file
  serves both routes without a build step. The plugin path is **never persisted** to `config.md` or a
  `VAULT.md`: it is a versioned cache directory and goes stale on every update.
- Every hardcoded `~/.claude/commands/...` becomes `$VAULT_FRAMEWORK_PATH/commands/...`. Every file that
  uses the variable carries the resolution rule, because step files load on demand long after the
  dispatcher resolved it.
- `commands/` holds commands only. `attic/` and `docs/commands.md` moved out of it.
- **`/v-setup` is the dependency step**, run explicitly by the user, wrapping `setup.sh` behind a
  consent gate. A `SessionStart` hook detects a missing stack and points at it. **The hook installs
  nothing** — that is the ADR-005 line, and it holds even though the hook API would permit it.
- `install.sh` refuses when the plugin is installed or when it is running from the plugin cache;
  `setup.sh` skips its symlink step in the same conditions. `VAULT_ALLOW_DOUBLE_INSTALL=1` overrides.

## Consequences

**Easier.** Install is two lines typed into Claude Code, no clone and no shell. Updates are
`/plugin update`. Sharing the framework is sharing a repo name. Command names are namespaced
(`/vault:v-work`), which resolves collisions with other plugins.

**Harder.** Publishing now needs a `version` bump — pushing to main alone reaches nobody, and that
failure is silent (`/plugin update` reports "already latest"). **Closed 2026-08-04** by
`bin/release-check.sh` / `make release-check`, which fails when shipped files changed since
`origin/main` without a version bump (`tests/`, `vault/`, `docs/` excluded — they ship in the cache
but change nothing a user invokes). Covered by `tests/unit/release-check.bats`. Two install routes mean two paths to
reason about in every future change to command wiring. Editing the framework through a plugin install
means editing a cache copy that the next update replaces, which is why `install.sh` survives.

**Watch for.** Step files are the fragile part: they are invocable commands in their own right, so
anything added to their top edits their picker description, and anything that assumes the dispatcher's
context is unavailable when they are read fresh. `tests/unit/plugin-install.bats` guards the layout, the
manifests, the path rule, the hook's no-install property and the double-install refusal; the grep guard
against `~/.claude/commands` is the one most likely to catch a real regression.

The plugin cache holds a full copy of the repo, `tests/` and the framework's own `vault/` included.
Accepted as harmless for now.
