# vault — a knowledge framework for your projects

The vault keeps what you learn about a project where you (and Claude) can find it again: decisions,
features, session notes, and the rules for working on the code. It's plain Markdown, readable in
Obsidian, and tracked in git.

You install it once on your machine. Each project then points at that one install and gets its own
vault, either alongside your code or inside the repo. Nothing gets copied into your projects.

## Install

You'll need Linux (Ubuntu is the tested path), git, Python 3.10+, and Claude Code already installed. On a
Mac the tool installer prints the commands to run by hand instead. Full details are in
[INSTALL.md](INSTALL.md).

Inside Claude Code:

```
/plugin marketplace add karoldabro/vault
/plugin install vault@kdabro-vault
```

Restart Claude Code, then run `/v-setup` once. That second step installs the helper tools and creates
the machine-level config; Claude Code never runs an installer for you when a plugin lands, so it has to
be asked for. `/v-setup` shows you what it will run before it runs anything.

Prefer not to use plugins? Clone the repo and symlink the commands instead:

```bash
git clone git@github.com:karoldabro/vault.git ~/workspace/vault && cd ~/workspace/vault && ./setup.sh --full --yes
```

Run it as your normal user (not `sudo`). When it finishes, open a fresh shell with `exec $SHELL -l` and
restart Claude Code.

**Pick one or the other.** With both active every command exists twice, under two names, reading two
different copies of the files. `install.sh` refuses to run when it finds the plugin installed.

For the full list of options, the uninstall, and the tests, see [INSTALL.md](INSTALL.md).

## Add it to a project

```bash
cd ~/workspace/<your-code-repo>
~/workspace/vault/bin/vault-init.sh            # vault lives in ~/vault/, in a folder named after your project
~/workspace/vault/bin/vault-init.sh --in-repo  # ...or keep it inside the repo
```

This creates the vault, sets up its folders and index files, writes a small `VAULT.md` at your repo root
recording where the vault lives, and adds a short note to your repo's `CLAUDE.md`. After that, use
`/v-work` to do work and `/v-capture` to save what happened.

Already have an old vault with a `_process/` submodule? Convert it in place with
`~/workspace/vault/bin/vault-migrate.sh`.

## Commands

Type them in Claude Code. With the plugin they are also reachable as `/vault:v-work` and so on, which
is how you disambiguate if another plugin ships a command with the same name.

| Command | What it's for |
|---------|---------------|
| `/v-setup` | Install or repair the helper tools and the machine-level config. Run once per machine. |
| `/v-work` | The main loop: load context, propose a plan, get your approval, do the work, save it. |
| `/v-team` | The careful version of `/v-work` for big or risky changes. Runs critic personas over the plan and the diff. |
| `/v-pm` | Plan a feature that spans several repos, once. Drafts a shared cross-project plan + contract so each repo's `/v-team` session coordinates through files instead of you copy-pasting between them. |
| `/v-do` | A small, low-risk change with no approval gate. |
| `/v-ask` | Ask a question about the project. Read-only, no changes. |
| `/v-cr` | Review a pull request and post comments back. Optional `--sandbox` actually runs the PR to verify findings. |
| `/v-capture` | Save the current session into the vault. |
| `/v-init` | Set up a vault for the current repo. |
| `/v-link` | Link two projects so context loading sweeps both. |
| `/v-guide` | Generate a cross-project integration guide from a feature. |

Archived (see [attic/](attic/)): `/v-migrate` (migration finished; `bin/vault-migrate.sh` remains).

## Persona packs

`/v-team` critics come from packs in [personas/](personas/): dev stacks (`api-laravel`, `nuxt`,
`flutter`) plus the business family (`marketing`, `sales`, `seo`, `support`, `business`,
`startup-eval`). Shared critics live once in `personas/_shared/` — including the `_shared/testing`
group (AI-written-test critique) and the `_shared/business` group (numeric-evidence critique).
Business packs are opt-in via a repo's `VAULT.md` (`project_type` or `personas.use`, which also
accepts a list to seat several packs). Selection rules: `personas/_resolution.md`.

## Learn more

- [vault-guide.md](vault-guide.md) — how the vault is laid out and how the lifecycle works. The doc to
  read if you want to understand the framework.
- [tool-playbook.md](tool-playbook.md) — the helper tools (claude-mem, Serena, Graphify) and when to
  use each.
- [docs/removing-openviking.md](docs/removing-openviking.md) — OpenViking was dropped; this takes an
  older install off your machine.
- [INSTALL.md](INSTALL.md) — install options, uninstall, and tests.
