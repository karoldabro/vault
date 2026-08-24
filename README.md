# vault — a knowledge framework for your projects

The vault stores what you learn about a project as plain Markdown that you and Claude can both search:
decisions, features, session notes, and the rules for working on the code. Obsidian reads it and git
tracks it.

You install the framework once per machine. Each project then points at that one install and gets its
own vault, either beside your code or inside the repo.

## Install once per machine

You need Linux, git, Python 3.10 or newer, and Claude Code. Ubuntu is the tested path; on a Mac the tool
installer prints the commands for you to run by hand. [INSTALL.md](INSTALL.md) carries the flags, the
uninstall, and the tests.

```
/plugin marketplace add karoldabro/vault
/plugin install vault@kdabro-vault
```

Restart Claude Code, then run `/v-setup` once. It installs the helper tools and creates the machine-level
config, because installing a plugin never runs an installer on your machine. It prints every command
before it runs it.

**Take the symlink install instead if you edit the framework itself.** The plugin copies the files into a
versioned cache that each update replaces, so edits made there do not survive.

```bash
git clone git@github.com:karoldabro/vault.git ~/workspace/vault && cd ~/workspace/vault && ./setup.sh
```

`setup.sh` asks which install you want. Choose the light one unless you write code with these commands;
the developer install adds Serena and Graphify, which need uv, pipx and Python 3.10 or newer. Switch
later with `./setup.sh --full`.

Run `setup.sh` as your normal user, never with `sudo`. When it finishes, open a fresh shell with
`exec $SHELL -l` and restart Claude Code.

**Install the plugin or the symlinks, never both.** With both active every command exists twice, under
two names, reading two different copies of the files. `install.sh` refuses to run when it finds the
plugin already installed.

## Add a vault to a project

```bash
cd ~/workspace/<your-code-repo>
~/workspace/vault/bin/vault-init.sh            # vault lives in ~/vault/<project>/
~/workspace/vault/bin/vault-init.sh --in-repo  # vault lives inside the repo
```

`vault-init.sh` creates the vault, scaffolds its folders and index files, writes a `VAULT.md` at your
repo root recording where the vault lives, and adds a short note to your repo's `CLAUDE.md`. After that,
run `/v-work` to do work and `/v-capture` to save what happened.

`~/workspace/vault/bin/vault-migrate.sh` converts an older vault that still carries a `_process/`
submodule.

## The commands

Type them in Claude Code. A plugin install also exposes each one as `/vault:v-work` and so on, which is
how you disambiguate when another plugin ships the same name.

| Command | What it's for |
|---------|---------------|
| `/v-setup` | Install or repair the helper tools and the machine-level config. Run once per machine. |
| `/v-work` | The main loop: load context, propose a plan, get your approval, do the work, save it. |
| `/v-team` | The careful version of `/v-work` for big or risky changes. Reviewers critique the plan and the diff. |
| `/v-pm` | Plan a feature spanning several repos once. Writes a shared plan and contract, so each repo's `/v-team` session coordinates through files instead of through you. |
| `/v-do` | A small, low-risk change with no approval gate. |
| `/v-ask` | Ask a question about the project. Read-only, no changes. |
| `/v-cr` | Review a pull request and post comments back. `--sandbox` runs the PR to verify findings. |
| `/v-capture` | Save the current session into the vault. |
| `/v-init` | Set up a vault for the current repo. |
| `/v-link` | Link two projects so context loading sweeps both. |
| `/v-guide` | Generate a cross-project integration guide from a feature. |
| `/v-reconcile` | Rewrite an existing document to the writing standard, keeping every constraint. |

[attic/](attic/) holds `/v-migrate`, whose migration finished. `bin/vault-migrate.sh` still works.

## Reviewer packs for /v-team

`/v-team` draws its reviewers from packs in [personas/](personas/): the development stacks
`api-laravel`, `nuxt` and `flutter`, and the business family `marketing`, `sales`, `seo`, `support`,
`business` and `startup-eval`. Reviewers used by several packs live once in `personas/_shared/`,
including the `_shared/testing` group that critiques AI-written tests and the `_shared/business` group
that critiques numeric evidence.

A repo opts into a business pack through its `VAULT.md`, using `project_type` or `personas.use`; the
second key also accepts a list, which seats several packs at once. `personas/_resolution.md` holds the
selection rules.

## Where to read more

- [vault-guide.md](vault-guide.md) — the vault layout and the lifecycle. Read this to understand the
  framework.
- [tool-playbook.md](tool-playbook.md) — the helper tools and when to reach for each.
- [INSTALL.md](INSTALL.md) — install options, uninstall, and tests.
- [docs/removing-openviking.md](docs/removing-openviking.md) — takes an OpenViking install off a machine
  that still has one.
