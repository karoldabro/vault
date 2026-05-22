# vault — knowledge framework for software projects

Markdown-only, Obsidian-readable, git-tracked. Attached as a submodule to per-project vaults so the process travels with the repo.

## Layers

| Layer | Owns | Where |
|-------|------|-------|
| **Framework** (this repo) | Process docs, templates, commands. Generic. | `git@github.com:karoldabro/vault.git` |
| **Project vault** | Features, decisions, sessions, MOC for one product. | Per-project repo, attaches this one at `_process/` |
| **Machine** | Local state: coupled-groups, auto-memory, OV index. | `~/vault/_global/`, never committed |

See [`vault-guide.md`](vault-guide.md) for full process documentation.

## Install (per machine)

Clone, then run `install.sh`. It symlinks the commands into `~/.claude/commands/`.

```bash
git clone git@github.com:karoldabro/vault.git ~/workspace/vault
cd ~/workspace/vault && ./install.sh
```

Idempotent. Re-run after pulling updates to refresh links. Refuses to overwrite any non-symlink file in `~/.claude/commands/`.

## Attach to a project (per project)

Inside a per-project vault repo:

```bash
git submodule add git@github.com:karoldabro/vault.git _process
git commit -m "chore(vault): attach framework as submodule"
```

Then link `[[_process/vault-guide]]` from the project's `_moc.md`.

After cloning a project vault elsewhere:

```bash
git clone <project-vault-url>
cd <project-vault>
git submodule update --init
```

## Contents

```
vault/
├── README.md              # this file
├── vault-guide.md         # canonical process doc — read this
├── install.sh             # idempotent command installer
├── templates/             # decision, feature, session, project-moc, process, architecture
└── commands/              # work.md, m-capture.md — linked into ~/.claude/commands/ by install.sh
```

## Commands provided

| Command | Purpose |
|---------|---------|
| `/work` | Vault-aware dev lifecycle: load context → propose (with dedupe) → approval → execute → commit + capture. |
| `/m-capture` | Capture this session into the vault. Dedupes, updates indexes, extracts ADR candidates, cross-links Refs. |

See [`vault-guide.md`](vault-guide.md) §10 for the full command reference.

## OpenViking is optional

Every command has a grep-based fallback for semantic search. The framework works without OpenViking installed; it just goes faster with it.
