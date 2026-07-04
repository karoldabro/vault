# vault — a knowledge framework for your projects

The vault keeps what you learn about a project where you (and Claude) can find it again: decisions,
features, session notes, and the rules for working on the code. It's plain Markdown, readable in
Obsidian, and tracked in git.

You install it once on your machine. Each project then points at that one install and gets its own
vault, either alongside your code or inside the repo. Nothing gets copied into your projects.

## Install

You'll need Linux (Ubuntu is the tested path), git, Python 3.10+, and Claude Code already installed. On a
Mac the installer prints the commands to run by hand instead. Full details are in [INSTALL.md](INSTALL.md).

```bash
git clone git@github.com:karoldabro/vault.git ~/workspace/vault && cd ~/workspace/vault && ./setup.sh --full --yes
```

Run it as your normal user (not `sudo`). It sets up the framework plus a few helper tools, then asks for
your sudo password once when it needs it. When it finishes, open a fresh shell with `exec $SHELL -l` and
restart Claude Code.

That's the happy path. For the full list of options, the uninstall, and the tests, see
[INSTALL.md](INSTALL.md).

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

These install into `~/.claude/commands/`. Type them in Claude Code.

| Command | What it's for |
|---------|---------------|
| `/v-work` | The main loop: load context, propose a plan, get your approval, do the work, save it. |
| `/v-team` | The careful version of `/v-work` for big or risky changes. Runs critic personas over the plan and the diff. |
| `/v-pm` | Plan a feature that spans several repos, once. Drafts a shared cross-project plan + contract so each repo's `/v-team` session coordinates through files instead of you copy-pasting between them. |
| `/v-do` | A small, low-risk change with no approval gate. |
| `/v-ask` | Ask a question about the project. Read-only, no changes. |
| `/v-cr` | Review a pull request and post comments back. Optional `--sandbox` actually runs the PR to verify findings. |
| `/v-capture` | Save the current session into the vault. |
| `/v-init` | Set up a vault for the current repo. |
| `/v-sync` | Re-index a vault's knowledge for search. |
| `/v-link` | Link two projects so they share recall. |
| `/v-backfill` | Pull past Claude Code sessions into search. |
| `/v-guide` | Generate a cross-project integration guide from a feature. |

Archived (see `commands/attic/`): `/v-migrate` (migration finished; `bin/vault-migrate.sh` remains),
`/v-resume` (superseded by the OpenViking auto-recall SessionStart hook).

## Learn more

- [vault-guide.md](vault-guide.md) — how the vault is laid out and how the lifecycle works. The doc to
  read if you want to understand the framework.
- [tool-playbook.md](tool-playbook.md) — the helper tools (OpenViking, Serena, Graphify, claude-mem) and
  when to use each.
- [INSTALL.md](INSTALL.md) — install options, uninstall, and tests.
