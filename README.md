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

```bash
git clone git@github.com:karoldabro/vault.git ~/workspace/vault
cd ~/workspace/vault && ./setup.sh --minimal --yes
```

`setup.sh` is the umbrella installer. It checks prereqs, scaffolds `~/vault/_global/`, optionally wires OpenViking + Graphify, then calls `install.sh` to symlink the slash commands.

Flags:

| Flag | Effect |
|------|--------|
| `--minimal` | Just the framework — skip OV + Graphify. |
| `--with-ov` | Wire OpenViking (writes `~/.openviking/ov.conf`, prints Ollama / plugin install hints). |
| `--with-graphify` | Print Graphify install hints. |
| `--yes`, `-y` | Non-interactive. |

Network-requiring installs (Ollama, pipx) are never auto-executed — `setup.sh` prints the exact command to run. Re-run anytime; it's idempotent.

For just refreshing the symlinks after a `git pull`:

```bash
./install.sh
```

Idempotent; refuses to overwrite any non-symlink in `~/.claude/commands/`; prunes stale symlinks pointing at deleted command sources.

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
├── setup.sh               # umbrella installer (prereqs, OV, Graphify, machine layer)
├── install.sh             # idempotent command installer
├── templates/             # decision, feature, session, project-moc, process, architecture
├── commands/              # v-work.md, v-capture.md — linked into ~/.claude/commands/ by install.sh
├── tests/                 # bats-core suite, runs in Docker (`make test`)
└── Makefile               # `make test`, `make shell`
```

## Tests

Run the full suite in a Docker container (reproducible, no host pollution):

```bash
make test
```

Or scope it:

```bash
make test-unit
make test-integration
make test-e2e
```

The image is built from `tests/Dockerfile` (alpine + bats-core + bash/git/jq). The repo is mounted **read-only** at `/code`; tests use a tmpfs `$HOME`. Docker is the only host prerequisite.

## Commands provided

| Command | Purpose |
|---------|---------|
| `/v-work` | Vault-aware dev lifecycle: load context → propose (with dedupe) → approval → execute → commit + capture. |
| `/v-capture` | Capture this session into the vault. Dedupes, updates indexes, extracts ADR candidates, cross-links Refs. |

See [`vault-guide.md`](vault-guide.md) §10 for the full command reference.

## OpenViking is optional

Every command has a grep-based fallback for semantic search. The framework works without OpenViking installed; it just goes faster with it.
