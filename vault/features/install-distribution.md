---
type: feature
project: vault
slug: install-distribution
status: in_progress
owners: []
tags: [feature, install, distribution, plugin]
---

# install-distribution

## Scope

How the framework reaches a machine, and how a change to the framework reaches its users. Covers the two
install routes, the path resolution that lets one set of files serve both, the dependency step, and the
publishing procedure.

Non-goals: what the commands *do* once installed (see the per-command dossiers), and the per-project
vault scaffold (`/v-init`, `bin/vault-init.sh`).

## Contracts

**Plugin route** — [[../decisions/ADR-020-claude-code-plugin-distribution]]

- `.claude-plugin/plugin.json` — name `vault`, pinned semver `version`.
- `.claude-plugin/marketplace.json` — marketplace name `kdabro-vault`, one plugin entry, `source: "./"`.
- Install: `/plugin marketplace add karoldabro/vault` → `/plugin install vault@kdabro-vault`.
- Update: `/plugin update vault@kdabro-vault`. Remove: `/plugin uninstall vault@kdabro-vault`.
- Component roots scanned by Claude Code: `commands/`, `output-styles/`, `hooks/hooks.json`, `bin/`, `scripts/`
  (added to the Bash tool's PATH).

**Symlink route**

- `install.sh` — links `commands/` → `~/.claude/commands/`, `output-styles/` →
  `~/.claude/output-styles/`; prunes stale links; refuses to overwrite non-symlinks.
- **Hooks are declared once, in `install.sh`'s `HOOK_ROWS` array** — `script;flag;event;matcher;
  off-switch;description`, semicolon-separated because a matcher contains a pipe. Three loops read
  it: link, register, and the not-switched-on notice. Adding a hook is one row, not five edits.
  `hooks/hooks.json` carries the same set for the plugin route.
- Activation flags: `--enable-style`, `--enable-doc-lint`, `--enable-brevity`, `--enable-all`. Each
  edits `~/.claude/settings.json`, backs it up first, appends only when absent, and leaves entries
  the user already had in place. **Without a flag, `install.sh` never touches settings.**
- `setup.sh` — base prerequisites, `~/vault/_global/` scaffold, tool stack per profile, doctor pass,
  then `install.sh`. Flags: `--light`, `--full`, `--minimal`, `--with-*`, `--yes`, `--dry-run`,
  `--doctor`.

**Install profiles** — [[../decisions/ADR-021-install-profiles]]

- `--light` (default) = claude-mem · `--full` = + Serena (uv) + Graphify (pipx) · `--minimal` = no tools.
- Recorded as `install_mode: light|full|minimal` under `## config` in `~/vault/_global/config.md`.
- Serena and Graphify are **developer tools**. Anything that reads their absence — `doctor()`,
  `scripts/detect-stack.sh`, `tool-playbook.md` §3/§4, `v-work` §2.4/§2.5, `v-do.md`, `v-work.md` —
  checks `install_mode` first and stays silent on a light machine.

**Shared**

- `$VAULT_FRAMEWORK_PATH` resolution order: `${CLAUDE_PLUGIN_ROOT}` → `VAULT.md` `framework_path` →
  `~/vault/_global/config.md` → `~/workspace/vault`. Documented in `vault-guide.md` §1.1 and
  `commands/v-work/steps/01-analyze.md` §1.4.
- `lib/plugin-detect.sh` — `vault_running_from_plugin_cache`, `vault_plugin_installed`.
- `/v-setup` → `setup.sh` behind a consent gate. `hooks/hooks.json` → `scripts/detect-stack.sh` (SessionStart)
  and `scripts/doc-lint-hook.sh` (PostToolUse). A **symlink install reads no manifest**, so `install.sh`
  links the hook into `~/.claude/hooks/` and prints the `settings.json` snippet for the user to paste —
  it never edits `settings.json` itself.
- Uninstall beyond the wiring: `bin/vault-uninstall.sh` (`--tools`, `--purge-data`, `--all`).

## Behaviors & rules

- A file lands under `commands/` → it becomes an invocable slash command under a plugin install; docs
  and retired commands live outside it; edge: `commands/_shared/` is accepted noise, since moving it
  would ripple through every dispatcher.
- A command file references a framework file → it addresses it through `$VAULT_FRAMEWORK_PATH`, never
  `~/.claude/commands` and never a relative path.
- A file uses `$VAULT_FRAMEWORK_PATH` → it also carries the resolution rule, because step files load on
  demand many turns after the dispatcher resolved it.
- A note is added to a command file with no frontmatter → it goes below the first heading; edge: above
  it, the note silently becomes the command's picker description.
- The framework root resolves to a plugin cache path → it is never written to `config.md` or a
  `VAULT.md`; that directory is versioned and is replaced on every update.
- Both install routes are active → every command exists twice under two names, reading two different
  copies. `install.sh` refuses and `setup.sh` skips its symlink step; edge:
  `VAULT_ALLOW_DOUBLE_INSTALL=1` is the deliberate override.
- A plugin change is published → `version` in `plugin.json` is bumped; edge: without a bump,
  `/plugin update` reports users are already current and ships nothing.
- Something runs unattended at SessionStart → it detects only and never installs
  ([[../decisions/ADR-005-installer-auto-exec]]).
- A manifest changes → `claude plugin validate . --strict` passes before it is published
  (`make validate-plugin`).
- `setup.sh` is invoked under `sudo` → it refuses, because `$HOME` would become `/root` and strand the
  whole per-user install there; edge: `VAULT_ALLOW_SUDO=1` overrides.
- No profile flag is passed → stdin is a terminal means prompt (empty answer → light), `--yes` means
  light, and neither means minimal with nothing installed; edge: an explicit `--with-*` set is never
  widened by the light default, and `--minimal` beats everything.
- A tool is absent → it is reported as a gap only when `install_mode` says it should have been there;
  a light machine missing Serena or Graphify is the expected state, not a fault.
- The installer re-runs with a different profile → `install_mode` is rewritten in place, so the file
  always holds exactly one such line.
- `install.sh` runs with no activation flag → every shipped hook is linked into `~/.claude/hooks/`
  and `~/.claude/settings.json` is untouched, and the closing output names each linked-but-off hook
  with the flag that turns it on.
- `install.sh` runs twice with the same flag → each hook holds exactly one settings entry; edge: an
  unrelated entry the user already had in that event's bucket is preserved.
- A hook row carries an empty matcher → the registered entry has no `matcher` key at all, rather
  than an empty one.

## Coupling

Framework-internal only — this repo has no cross-repo consumers. Per-project repos couple to it through
`VAULT.md` (`framework_path`, optional) and `~/vault/_global/config.md`, both of which hold a **clone**
path and are meaningless under a plugin install.

## Gotchas

- `${CLAUDE_PLUGIN_ROOT}` substitutes inside command and skill **content**, not only in hook and MCP
  configs. That substitution is what the resolution rule branches on: absolute path means plugin, literal
  text means clone.
- The plugin cache is a copy, not a checkout. `git pull` in the clone changes nothing for a plugin
  install.
- Publishing failure is silent. Pushing without a `version` bump produces "already at the latest
  version", not an error. **Guarded since 2026-08-04:** `make release-check` (`bin/release-check.sh`)
  fails when files that ship in the plugin changed since `origin/main` without a bump. `tests/`,
  `vault/` and `docs/` are excluded — they ride in the cache but change nothing a user invokes. It is
  deliberately **not** part of `make test`: the offline container has no `origin/main` ref. An
  unreachable base ref warns and passes, so it never blocks work offline.
- The plugin cache holds the whole repo, `tests/` and the framework's own `vault/` included. Harmless
  today; revisit if cache size ever matters.
- Developing the framework through a plugin install means editing a cache copy that the next update
  replaces. Use the symlink route for framework work.

## Sessions

- [[../sessions/2026-09-03-0929-mechanical-brevity-enforcement]]
- [[../sessions/2026-08-04-1339-install-profiles-light-full]]
- [[../sessions/2026-08-04-1225-claude-code-plugin-install]]
- [[../sessions/2026-08-03-1300-drop-openviking-dependency]]
