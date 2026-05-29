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

`setup.sh` is the umbrella installer. It checks prereqs, scaffolds `~/vault/_global/`, wires the
required tools (OpenViking, Serena, MorphLLM, claude-mem) plus Graphify, then calls `install.sh` to
symlink the slash commands. `--minimal` (above) skips the tools for a framework-only install — but
the commands assume the tools are present, so prefer `--full` on a real workstation.

Flags:

| Flag | Effect |
|------|--------|
| `--full` | Wire all four required tools + Graphify in one pass (recommended). |
| `--minimal` | Framework only — skip the tools. Commands degrade without them. |
| `--with-ov` | Wire OpenViking (writes `~/.openviking/ov.conf`, prints Ollama / plugin install hints). |
| `--with-serena` / `--with-morph` / `--with-claude-mem` | Wire one required tool. |
| `--with-graphify` | Print Graphify install hints (per-project commit hook is installed by `/v-init`). |
| `--yes`, `-y` | Non-interactive. |

Network-requiring installs (Ollama, pipx) are never auto-executed — `setup.sh` prints the exact command to run. Re-run anytime; it's idempotent.

For just refreshing the symlinks after a `git pull`:

```bash
./install.sh
```

Idempotent; refuses to overwrite any non-symlink in `~/.claude/commands/`; prunes stale symlinks pointing at deleted command sources.

## Attach to a project (per project)

```bash
cd ~/workspace/<your-code-repo>
~/workspace/vault/bin/vault-init.sh
```

This creates `~/vault/<slug>/`, attaches the framework as a `_process/` submodule, scaffolds folders + indexes, writes `.gitignore`, registers the slug in `~/vault/_global/coupled-groups.md`, appends a memory-stack snippet to the code repo's `CLAUDE.md`, and makes the initial commit. See `commands/v-init.md` for flags.

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
├── bin/                   # vault-init.sh and other host-callable scripts
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

## Required tools

The framework assumes four tools are installed and reachable — they are the cheap path that keeps
token cost down. Wire them all with `./setup.sh --full`:

| Tool | Role |
|------|------|
| **OpenViking** | Semantic vault memory (decisions, ADRs, sessions, pitfalls). |
| **claude-mem** | Project history via progressive-disclosure search. |
| **Serena** | Symbol-aware code navigation and refactoring. |
| **MorphLLM Fast Apply** | Targeted multi-line / multi-file edits. |

Plus **Graphify** for structural code questions — its `graph.json` is kept fresh by a per-project
post-commit hook installed by `/v-init`, so querying it costs no tokens.

Grep / full-file reads are the last resort, used only after these layers come up empty (or to verify
an exact current line) — not a substitute. See [`vault-guide.md`](vault-guide.md) §10 for the
token-cost hierarchy and [`tool-playbook.md`](tool-playbook.md) for per-tool rules + examples.
