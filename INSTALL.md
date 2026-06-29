# Installing the vault framework

This is the full install reference. If you just want to get going, the one-line install in the
[README](README.md) is enough. Come here for the flags, the uninstall, and the tests.

## One machine, once

```bash
git clone git@github.com:karoldabro/vault.git ~/workspace/vault && cd ~/workspace/vault && ./setup.sh --full --yes
```

`setup.sh` is the installer. On Ubuntu, `--full` sets up the whole tool stack for you:

- ollama plus the `nomic-embed-text` model
- the OpenViking server (installed with pipx, a tool that puts Python apps in their own isolated
  environment), its `~/.openviking/` config, and a per-user service on port 1933
- uv and Serena
- bun and claude-mem
- pipx and Graphify
- the OpenViking and claude-mem Claude Code plugins

It then scaffolds `~/vault/_global/`, runs a health check, and links the slash commands into
`~/.claude/commands/`. Restart Claude Code afterwards so the new plugins load.

Run it as your normal user, not with `sudo`. Everything is per-user: uv, bun, the plugins, and
`~/.openviking/ov.conf` all land in your `$HOME`. When the installer reaches the apt and ollama steps it
asks for your sudo password once and escalates for you. `sudo ./setup.sh` would point `$HOME` at `/root`
and strand everything there, so it's refused. (If you really mean it, set `VAULT_ALLOW_SUDO=1`.)

When it finishes, open a fresh shell so the new PATH entries show up:

```bash
exec $SHELL -l
```

There is no `ov` command. OpenViking runs as the plugin plus the ollama backend. Check on it any time
with `./setup.sh --doctor`.

## Consent and safety

Auto-install asks before it touches anything (`--yes` skips the prompt), prints every remote URL it runs
so you have an audit trail, and is safe to run twice. On a Mac (no apt), or non-interactively without
passwordless sudo, it prints the exact commands instead of running them, so it never half-installs or
hangs.

It does run vendor `curl | sh` scripts (ollama, uv, bun) and adds two third-party Claude marketplaces.
Every source is printed before it runs. See `vault/decisions/ADR-005-installer-auto-exec.md` for the
reasoning. MorphLLM Fast Apply is not installed for you — it needs a paid API key.

## Flags

| Flag | What it does |
|------|--------------|
| `--full` | Install the whole stack: OpenViking, Serena, claude-mem, Graphify. Recommended. |
| `--minimal` | Framework only, no tools. Commands degrade without the tools. |
| `--with-ov` | Just OpenViking: ollama + `nomic-embed-text`, the server (pipx) + `ov.conf` + client config + the port-1933 service + the plugin. |
| `--with-serena` / `--with-claude-mem` | Install one tool (uv + Serena, or bun + claude-mem). |
| `--with-graphify` | Install pipx + Graphify. (The per-project commit hook is added by `/v-init`.) |
| `--yes`, `-y` | Say yes without prompting. For CI and automation. |
| `--dry-run` | Print every command that would run, without running it. |
| `--doctor` | Run the health check and exit. |

`--with-ov` also points Claude at the OpenViking config by writing `OPENVIKING_CC_CONFIG_FILE` and
`OPENVIKING_CONFIG_FILE` into the `env` block of `~/.claude/settings.json`. The plugin needs these, or
its MCP exits with "Connection closed". The merge keeps any value of yours that points at a real file
and only fills in the ones that are missing or stale.

## Python 3.10 or newer

The pipx tools (`openviking`, `graphifyy`) need Python 3.10+. The installer picks a `python3.12`,
`3.11`, or `3.10` it finds on your PATH. On an old box (for example WSL or Ubuntu 20.04, which ship
Python 3.8) pipx fails with a misleading "No matching distribution found". Install a newer Python and
re-run:

```bash
sudo apt install -y python3.12 python3.12-venv   # or the deadsnakes PPA
```

`--doctor` flags a missing 3.10+ interpreter.

## Refresh after a pull

After `git pull`, relink the commands:

```bash
./install.sh
```

It's safe to run repeatedly. It won't overwrite anything in `~/.claude/commands/` that isn't already a
symlink, and it prunes links that point at deleted commands.

## Uninstall

```bash
./bin/vault-uninstall.sh --yes        # remove the framework wiring (reversible, no data loss)
./bin/vault-uninstall.sh --dry-run    # preview first
```

By default this removes only the wiring: the command symlinks, the OpenViking service, `ov.conf` and the
plugin client config, the two `settings.json` env keys, and the OV and claude-mem plugins. To go
further:

- `--tools` also uninstalls `openviking`, `graphifyy`, and `serena-agent` (never the shared
  ollama/uv/bun/node).
- `--purge-data` deletes `~/.openviking` and `~/vault/_global`. This is destructive.
- `--all` does both.

Without `--yes` and with no terminal attached, it just prints the plan. Your project vaults and your
code repos are never touched.

## Tests

Two tiers, both run in Docker. Docker is the only thing you need installed.

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
pipx). The ollama daemon and the `claude` plugin paths are covered at the dry-run level (see
`tests/e2e/run.sh`).
