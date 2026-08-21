# Installing the vault framework

This is the full install reference. If you just want to get going, the install in the
[README](README.md) is enough. Come here for the flags, the uninstall, and the tests.

There are **two install modes and you pick one**:

| | Plugin (recommended) | Symlinks |
|---|---|---|
| How commands arrive | Claude Code's plugin loader | `install.sh` symlinks into `~/.claude/commands/` |
| Updating | `/plugin update vault@kdabro-vault` | `git pull && ./install.sh` |
| Editing the framework itself | Awkward — you edit a cache copy that gets replaced | Direct: your clone *is* the install |
| Command names | `/v-work` and `/vault:v-work` | `/v-work` |

Running both installs every command twice, under two names, resolving to two different copies of the
files. `install.sh` refuses to run when it detects the plugin, and `setup.sh` skips its symlink step.
Override with `VAULT_ALLOW_DOUBLE_INSTALL=1` if you have a reason.

Take the symlink mode if you develop the framework itself. Otherwise take the plugin.

## Plugin install

Inside Claude Code:

```
/plugin marketplace add karoldabro/vault
/plugin install vault@kdabro-vault
```

The first line registers this repository as a marketplace; the second installs the plugin it lists.
The `/plugin` menu does the same thing with a browser if you prefer clicking. Restart Claude Code so
the commands load.

Then run **`/v-setup`** once. Installing a plugin never runs an installer on your machine — by design —
so the helper tools and the `~/vault/_global/` config are a separate, explicit step. `/v-setup` wraps
`setup.sh`: it shows you what is missing, tells you what it will run, and asks before running it.
`/v-setup --doctor` checks without changing anything.

The plugin also registers a session-start check that stays silent unless something is missing. It only
looks; it never installs.

To update: `/plugin update vault@kdabro-vault`.

**Publishing a change requires bumping `version` in `.claude-plugin/plugin.json`.** Claude Code keys
its cache on that string, so pushing commits without bumping it does nothing — `/plugin update` will
report users are already on the latest. The pin is deliberate: it means a half-finished `main` never
reaches anyone who installed the plugin. Bump it as the last step of a release, not per commit.

`make release-check` enforces it: it fails when files that ship in the plugin changed since
`origin/main` but the version string did not. Changes under `tests/`, `vault/` and `docs/` are
excluded — they ride along in the plugin cache but change nothing a user invokes, so they need no
release. An unreachable `origin/main` warns and passes rather than blocking.

To remove: `/plugin uninstall vault@kdabro-vault`. That takes away the commands and leaves your vaults
and the helper tools alone — see [Uninstall](#uninstall) for the rest.

## Symlink install — one machine, once

```bash
git clone git@github.com:karoldabro/vault.git ~/workspace/vault && cd ~/workspace/vault && ./setup.sh
```

`setup.sh` is the installer. Run with no flags it asks which install you want.

## Which install?

| Install | Flag | You get | You give up |
|---------|------|---------|-------------|
| **Light** — recommended | `--light` | bun, claude-mem and its Claude Code plugin: memory recall across sessions | Questions about code structure fall back to grep, so they cost more tokens |
| **Full** — for developers | `--full` | Everything in light, plus uv + Serena and pipx + Graphify: symbol navigation and a structural code graph, so code work is much cheaper | Vendor `curl \| sh` installs, apt, and Python 3.10 or newer |
| Minimal | `--minimal` | The commands, nothing else | Every context lookup is grep |

Serena and Graphify are **developer tools**. If you use the vault for notes, decisions and session
history rather than for working on code, take the light install — the commands all work without them.
You can add them later with `./setup.sh --full`; it is idempotent.

Whichever you pick is recorded as `install_mode` in `~/vault/_global/config.md`, which is how the
commands know not to keep offering you tools you chose not to install.

With no terminal to answer the question, `--yes` gives you the light install and passing nothing at all
gives you the minimal one — the installer never installs unattended without consent.

Setup then scaffolds `~/vault/_global/`, runs a health check, and links the slash commands into
`~/.claude/commands/`. Restart Claude Code afterwards so the new plugins load. (If the vault plugin is
already installed, it skips the linking step and leaves the plugin's commands as the only copy.)

Run it as your normal user, not with `sudo`. Everything is per-user: uv, bun and the plugins all land
in your `$HOME`. When the installer reaches the apt steps it asks for your sudo password once and
escalates for you. `sudo ./setup.sh` would point `$HOME` at `/root`
and strand everything there, so it's refused. (If you really mean it, set `VAULT_ALLOW_SUDO=1`.)

When it finishes, open a fresh shell so the new PATH entries show up:

```bash
exec $SHELL -l
```

Check what actually landed any time with `./setup.sh --doctor`.

**OpenViking was removed from this stack.** It is no longer installed or used. If you have an install
from before that change, see [removing-openviking.md](docs/removing-openviking.md).

## Consent and safety

Auto-install asks before it touches anything (`--yes` skips the prompt), prints every remote URL it runs
so you have an audit trail, and is safe to run twice. On a Mac (no apt), or non-interactively without
passwordless sudo, it prints the exact commands instead of running them, so it never half-installs or
hangs.

It does run vendor `curl | sh` scripts (uv, bun) and adds a third-party Claude marketplace.
Every source is printed before it runs. See `vault/decisions/ADR-005-installer-auto-exec.md` for the
reasoning. MorphLLM Fast Apply is not installed for you — it needs a paid API key.

## Flags

| Flag | What it does |
|------|--------------|
| `--light` | claude-mem only. Recommended — see [Which install?](#which-install). |
| `--full` | Adds the developer tools: Serena and Graphify. |
| `--minimal` | Framework only, no tools. Commands degrade without the tools. |
| `--with-serena` / `--with-claude-mem` | Install one tool (uv + Serena, or bun + claude-mem). |
| `--with-graphify` | Install pipx + Graphify. (The per-project commit hook is added by `/v-init`.) |
| `--yes`, `-y` | Say yes without prompting. For CI and automation. |
| `--dry-run` | Print every command that would run, without running it. |
| `--doctor` | Run the health check and exit. |

## Python 3.10 or newer

Only the full (developer) install needs this. The pipx tool (`graphifyy`) needs Python 3.10+. The installer picks a `python3.12`,
`3.11`, or `3.10` it finds on your PATH. On an old box (for example WSL or Ubuntu 20.04, which ship
Python 3.8) pipx fails with a misleading "No matching distribution found". Install a newer Python and
re-run:

```bash
sudo apt install -y python3.12 python3.12-venv   # or the deadsnakes PPA
```

`--doctor` flags a missing 3.10+ interpreter.

## Refresh after a pull

On a plugin install there is nothing to relink — `/plugin update vault@kdabro-vault` fetches and
swaps the whole thing.

On a symlink install, after `git pull`, relink the commands:

```bash
./install.sh
```

It's safe to run repeatedly. It won't overwrite anything in `~/.claude/commands/` or
`~/.claude/output-styles/` that isn't already a symlink, and it prunes links that point at deleted
sources.

### Optional: the `director` output style

`output-styles/director.md` ships with both install modes — the plugin loads it directly, and
`install.sh` links it into `~/.claude/output-styles/`. It applies the framework's writing rules —
answer first, no jargon, options with their consequences, decisions capped at ~15 lines — to
**every** Claude Code session, not just v-* commands, and it carries the document rules from
`commands/_shared/document-standard.md` too.

**Linking it and switching it on are separate steps.** The file arrives with every install; the
switch never flips itself. Pick one:

```
install.sh --enable-style          # writes "outputStyle": "director" to ~/.claude/settings.json
/config  ->  Output style  ->  director    # interactive; the /output-style command was removed in v2.1.91
```

By hand, if you prefer: add `"outputStyle": "director"` to `~/.claude/settings.json`. Takes effect
in a new session.

**Scope matters.** `/config` writes to the *project's* `.claude/settings.local.json`, so it applies
to that project only and does not travel between machines. `--enable-style` writes to
`~/.claude/settings.json`, which applies everywhere. A separate Claude home (e.g. a work config with
its own `settings.json`) needs its own line.

### Optional: document linting

`scripts/doc-lint-hook.sh` runs `bin/doc-lint.sh` on every markdown document Claude writes and hands
the findings back to it. It never blocks a write and never prompts you. A plugin install picks it up
from `hooks/hooks.json`; a symlink install links the script and needs the hook registered:

```
install.sh --enable-doc-lint
```

Turn it off any time with `DOC_LINT=off`. `install.sh --enable-all` does both this and the style.

Both flags edit `~/.claude/settings.json`, back it up first, and are idempotent. Without a flag,
`install.sh` never touches your settings.

### A second Claude config directory

`CLAUDE_CONFIG_DIR` lets you run a separate Claude home — a work profile, say:

```
alias claude-work='CLAUDE_CONFIG_DIR="$HOME/workspace/.claude-work" claude'
```

`install.sh` does not know about it: every path it writes is `~/.claude/...`. Wire the second home
by hand, once. Symlinking rather than copying means both homes track the framework:

```
W="$HOME/workspace/.claude-work"
ln -s ~/.claude/commands      "$W/commands"        # if not already linked
ln -s ~/.claude/output-styles "$W/output-styles"
ln -s ~/.claude/hooks         "$W/hooks"
```

Then add to `$W/settings.json` — that file is separate from `~/.claude/settings.json` and inherits
nothing from it:

```json
"outputStyle": "director",
"hooks": { "PostToolUse": [{ "matcher": "Write|Edit|MultiEdit",
  "hooks": [{ "type": "command",
              "command": "$HOME/workspace/.claude-work/hooks/doc-lint-hook.sh" }] }] }
```

`CLAUDE.md` is worth symlinking too, so one edit reaches both profiles.

## Uninstall

On a plugin install, `/plugin uninstall vault@kdabro-vault` removes the commands. The helper tools,
`~/vault/_global/`, and your project vaults survive it — use the script below for those.

```bash
./bin/vault-uninstall.sh --yes        # remove the framework wiring (reversible, no data loss)
./bin/vault-uninstall.sh --dry-run    # preview first
```

By default this removes only the wiring: the command symlinks and the claude-mem plugin. To go
further:

- `--tools` also uninstalls `graphifyy` and `serena-agent` (never the shared uv/bun/node).
- `--purge-data` deletes `~/vault/_global`. This is destructive.
- `--all` does both.

To remove an OpenViking install from before it was dropped, use `./bin/remove-openviking.sh` — see
[removing-openviking.md](docs/removing-openviking.md).

Without `--yes` and with no terminal attached, it just prints the plan. Your project vaults and your
code repos are never touched.

## Tests

Two tiers, both run in Docker. Docker is the only thing you need installed.

The plugin manifests have their own checks. `tests/unit/plugin-install.bats` covers the manifests, the
repo layout the plugin loader assumes, the session-start hook, and the double-install guard. Claude
Code's own validator is worth running before you publish a change to either manifest:

```bash
claude plugin validate . --strict
```


The offline suite is the default and gates pull requests. It runs the unit and integration tests on
alpine with no network and no sudo:

```bash
make test              # unit + integration
make test-unit
make test-integration
```

The repo is mounted read-only at `/code` and the tests use a throwaway `$HOME`. The image comes from
`tests/Dockerfile` (alpine + bats-core + bash/git/jq). The installer's execute path is covered here
through its `--dry-run` transcript (`tests/unit/setup-autoinstall.bats`): real command construction, no
real installs.

The end-to-end suite is opt-in and slow. It actually runs `setup.sh` on a throwaway Ubuntu container
with real network, so it proves the installers really land on disk:

```bash
VAULT_E2E=1 make test-e2e
```

It errors out unless `VAULT_E2E=1` is set, so it stays off the default path. It's built from
`tests/e2e/Dockerfile.ubuntu` and covers the lightweight installers (uv via `curl|sh`, Graphify via
pipx). The `claude` plugin paths are covered at the dry-run level (see `tests/e2e/run.sh`).
