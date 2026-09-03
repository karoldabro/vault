# Installing the vault framework

This is the full install reference: the flags, the uninstall, and the tests. The short version in the
[README](README.md) is enough to get going.

## Pick one install mode

| | Plugin (recommended) | Symlinks |
|---|---|---|
| How commands arrive | Claude Code's plugin loader | `install.sh` symlinks into `~/.claude/commands/` |
| Updating | `/plugin update vault@kdabro-vault` | `git pull && ./install.sh` |
| Editing the framework itself | You edit a cache copy that the next update replaces | Your clone is the install, so edits stay |
| Command names | `/v-work` and `/vault:v-work` | `/v-work` |

Take the symlink mode if you develop the framework itself. Otherwise take the plugin.

Running both installs every command twice, under two names, resolving to two different copies of the
files. `install.sh` refuses to run when it detects the plugin, and `setup.sh` skips its symlink step.
`VAULT_ALLOW_DOUBLE_INSTALL=1` overrides that guard.

## Install the plugin

```
/plugin marketplace add karoldabro/vault
/plugin install vault@kdabro-vault
```

The first line registers this repository as a marketplace; the second installs the plugin it lists. The
`/plugin` menu does the same through a browser. Restart Claude Code so the commands load.

Then run **`/v-setup`** once. Installing a plugin never runs an installer on your machine, by design, so
the helper tools and the `~/vault/_global/` config need a separate explicit step. `/v-setup` wraps
`setup.sh`: it reports what is missing, prints what it will run, and asks before running it.
`/v-setup --doctor` checks without changing anything. The plugin also registers a session-start check
that stays silent unless something is missing, and never installs.

Update with `/plugin update vault@kdabro-vault`. Remove with `/plugin uninstall vault@kdabro-vault`,
which takes the commands away and leaves your vaults and the helper tools alone — see
[Uninstall](#uninstall) for those.

**Publishing a change requires bumping `version` in `.claude-plugin/plugin.json`.** Claude Code keys its
cache on that string, so commits pushed without a bump reach nobody. Bump it as the last step of a
release, never per commit. `make release-check` fails when files that ship in the plugin changed since
`origin/main` and the version did not; it excludes `tests/`, `vault/` and `docs/`, and an unreachable
`origin/main` warns rather than blocks.

## Install the symlinks

```bash
git clone git@github.com:karoldabro/vault.git ~/workspace/vault && cd ~/workspace/vault && ./setup.sh
```

`setup.sh` is the installer. With no flags it asks which of the three tool sets you want.

## Pick light, full, or minimal

| Install | Flag | You get | You give up |
|---------|------|---------|-------------|
| **Light** — recommended | `--light` | bun, claude-mem and its Claude Code plugin: memory recall across sessions | Questions about code structure fall back to grep, so they cost more tokens |
| **Full** — for developers | `--full` | Everything in light, plus uv + Serena and pipx + Graphify: symbol navigation and a structural code graph, so code work is much cheaper | Vendor `curl \| sh` installs, apt, and Python 3.10 or newer |
| Minimal | `--minimal` | The commands, nothing else | Every context lookup is grep |

Serena and Graphify are developer tools. Take the light install if you use the vault for notes,
decisions and session history rather than for working on code; every command works without them. Add
them later with `./setup.sh --full`, which is safe to run repeatedly.

`setup.sh` records your choice as `install_mode` in `~/vault/_global/config.md`. That is how the commands
know not to keep offering tools you chose not to install. With no terminal to answer, `--yes` selects
light and passing nothing selects minimal; the installer never installs unattended without consent.

`setup.sh` then scaffolds `~/vault/_global/`, runs a health check, and links the slash commands into
`~/.claude/commands/`. Restart Claude Code afterwards. It skips the linking step when the vault plugin is
already installed, leaving the plugin's commands as the only copy.

Run it as your normal user, never with `sudo`. Everything lands per-user: uv, bun and the plugins go into
your `$HOME`. At the apt steps it asks for your sudo password once and escalates for you.
`sudo ./setup.sh` is refused, because it would point `$HOME` at `/root` and leave everything there. Set
`VAULT_ALLOW_SUDO=1` if you mean it.

When it finishes, open a fresh shell so the new PATH entries appear:

```bash
exec $SHELL -l
```

`./setup.sh --doctor` reports what actually landed, at any time.

**OpenViking is no longer part of this stack.** To take an install predating that change off your
machine, see [removing-openviking.md](docs/removing-openviking.md).

## Consent and safety

Auto-install asks before it touches anything, prints every remote URL it runs, and is safe to run twice.
`--yes` skips the prompt. On a Mac, which has no apt, and non-interactively without passwordless sudo, it
prints the exact commands instead of running them, so it never half-installs and never hangs.

It does run vendor `curl | sh` scripts for uv and bun, and it adds a third-party Claude marketplace, and
it prints every source first. `vault/decisions/ADR-005-installer-auto-exec.md` records why. MorphLLM Fast
Apply is not installed for you, because it needs a paid API key.

## Flags

| Flag | What it does |
|------|--------------|
| `--light` | claude-mem only. Recommended — see [Pick light, full, or minimal](#pick-light-full-or-minimal). |
| `--full` | Adds the developer tools: Serena and Graphify. |
| `--minimal` | Framework only, no tools. Commands degrade without the tools. |
| `--with-serena` / `--with-claude-mem` | Install one tool (uv + Serena, or bun + claude-mem). |
| `--with-graphify` | Install pipx + Graphify. `/v-init` adds the per-project commit hook. |
| `--yes`, `-y` | Say yes without prompting. For CI and automation. |
| `--dry-run` | Print every command that would run, without running it. |
| `--doctor` | Run the health check and exit. |

## Python 3.10 or newer, for the full install only

The pipx tool `graphifyy` needs Python 3.10 or newer. The installer picks up a `python3.12`, `3.11` or
`3.10` from your PATH. On an older box such as WSL or Ubuntu 20.04, which ship Python 3.8, pipx fails
with a misleading "No matching distribution found". Install a newer Python and re-run:

```bash
sudo apt install -y python3.12 python3.12-venv   # or the deadsnakes PPA
```

`--doctor` flags a missing 3.10-or-newer interpreter.

## Refresh after a pull

A plugin install has nothing to relink: `/plugin update vault@kdabro-vault` swaps the whole thing.

A symlink install needs `./install.sh` after `git pull`. It is safe to run repeatedly, overwrites nothing
in `~/.claude/commands/` or `~/.claude/output-styles/` that is not already a symlink, and prunes links
pointing at deleted sources.

### Turn on the `director` output style

`output-styles/director.md` applies the framework's writing rules to **every** Claude Code session, not
only the v-* commands: answer first, no jargon, options with their consequences, decisions capped at
about 15 lines. It carries the document rules from `commands/_shared/document-standard.md` too.

Both install modes ship the file — the plugin loads it directly, `install.sh` links it into
`~/.claude/output-styles/` — but **shipping it and switching it on are separate steps**. Pick one:

```
install.sh --enable-style          # writes "outputStyle": "director" to ~/.claude/settings.json
/config  ->  Output style  ->  director    # interactive; the /output-style command was removed in v2.1.91
```

By hand, add `"outputStyle": "director"` to `~/.claude/settings.json`. It takes effect in a new session.

**The two routes write to different files.** `/config` writes the *project's*
`.claude/settings.local.json`, so it applies to that project alone and does not travel between machines.
`--enable-style` writes `~/.claude/settings.json`, which applies everywhere. A separate Claude home needs
its own line.

### Turn on document linting

`scripts/doc-lint-hook.sh` runs `bin/doc-lint.sh` on every markdown document Claude writes and hands the
findings back to it. It never blocks a write and never prompts you. A plugin install picks it up from
`hooks/hooks.json`. A symlink install links the script and needs the hook registered:

```
install.sh --enable-doc-lint
```

`DOC_LINT=off` turns it off at any time.

### Turn on reply measurement

Two hooks do for what Claude *says* what document linting does for what it writes.
`scripts/output-lint-hook.sh` measures each reply and records it in `~/.claude/brevity-log.jsonl`.
`scripts/brevity-reminder-hook.sh` then tells Claude, at your next turn, what that reply overran — and
stays silent when nothing did, so text before a prompt always means something went over. Neither ever
blocks a turn or prompts you.

```
install.sh --enable-brevity
```

`BREVITY=off` turns both off at any time. `install.sh --enable-all` switches on the style, document
linting and reply measurement together. Every flag edits `~/.claude/settings.json`, backs it up first,
leaves entries you already had in place, and is safe to run repeatedly. Without a flag, `install.sh`
never touches your settings.

### Wire a second Claude config directory

`CLAUDE_CONFIG_DIR` runs a separate Claude home, a work profile for example:

```
alias claude-work='CLAUDE_CONFIG_DIR="$HOME/workspace/.claude-work" claude'
```

`install.sh` does not know about it: every path it writes is `~/.claude/...`. Wire the second home by
hand, once. Symlink rather than copy, so both homes track the framework:

```
W="$HOME/workspace/.claude-work"
ln -s ~/.claude/commands      "$W/commands"        # if not already linked
ln -s ~/.claude/output-styles "$W/output-styles"
ln -s ~/.claude/hooks         "$W/hooks"
```

Then add these keys to `$W/settings.json`, which is separate from `~/.claude/settings.json` and inherits
nothing from it:

```json
"outputStyle": "director",
"hooks": { "PostToolUse": [{ "matcher": "Write|Edit|MultiEdit",
  "hooks": [{ "type": "command",
              "command": "$HOME/workspace/.claude-work/hooks/doc-lint-hook.sh" }] }] }
```

Symlink `CLAUDE.md` too, so one edit reaches both profiles.

## Uninstall

On a plugin install, `/plugin uninstall vault@kdabro-vault` removes the commands. The helper tools,
`~/vault/_global/`, and your project vaults survive it; the script below removes those.

```bash
./bin/vault-uninstall.sh --yes        # remove the framework wiring (reversible, no data loss)
./bin/vault-uninstall.sh --dry-run    # preview first
```

By default it removes only the wiring: the command symlinks and the claude-mem plugin. To go further:

- `--tools` also uninstalls `graphifyy` and `serena-agent`, never the shared uv, bun or node.
- `--purge-data` deletes `~/vault/_global`. This destroys data.
- `--all` does both.

Without `--yes` and with no terminal attached, it prints the plan and stops. It never touches your
project vaults or your code repos.

`./bin/remove-openviking.sh` removes an OpenViking install predating its removal from the stack — see
[removing-openviking.md](docs/removing-openviking.md).

## Tests

Two tiers, both run in Docker. Docker is the only thing you need installed.

The offline suite is the default and gates pull requests. It runs on alpine with no network and no sudo,
mounts the repo read-only at `/code`, and uses a throwaway `$HOME`:

```bash
make test              # unit + integration
make test-unit
make test-integration
```

The image comes from `tests/Dockerfile` (alpine + bats-core + bash/git/jq).
`tests/unit/setup-autoinstall.bats` covers the installer's execute path through its `--dry-run`
transcript: real command construction, no real installs. `tests/unit/plugin-install.bats` covers the
plugin manifests, the repo layout the plugin loader assumes, the session-start hook, and the
double-install guard.

The end-to-end suite is opt-in and slow. It runs `setup.sh` on a throwaway Ubuntu container with real
network, proving the installers land on disk:

```bash
VAULT_E2E=1 make test-e2e
```

It errors out unless `VAULT_E2E=1` is set. It builds from `tests/e2e/Dockerfile.ubuntu` and covers the
lightweight installers (uv via `curl|sh`, Graphify via pipx); `tests/e2e/run.sh` covers the `claude`
plugin paths at the dry-run level.

Run Claude Code's own validator before publishing a change to either plugin manifest:

```bash
claude plugin validate . --strict
```
