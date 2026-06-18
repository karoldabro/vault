# vault — knowledge framework for software projects

Markdown-only, Obsidian-readable, git-tracked. A single **global** install per machine; each project's
vault lives globally (`~/vault/<slug>/`) or inside the repo, with an optional `VAULT.md` recording the
choice. (No submodules — the framework is read from `$VAULT_FRAMEWORK_PATH`, never vendored.)

## Layers

| Layer | Owns | Where |
|-------|------|-------|
| **Framework** (this repo) | Process docs, templates, commands. Generic. | Installed once at `$VAULT_FRAMEWORK_PATH` (default `~/workspace/vault/`) |
| **Project vault** | Features, decisions, sessions, MOC for one product. | `~/vault/<slug>/` or in-repo `<code-repo>/vault/` — resolved via `VAULT.md` |
| **Machine** | Local state: coupled-groups, config, auto-memory, OV index. | `~/vault/_global/`, never committed |

See [`vault-guide.md`](vault-guide.md) for full process documentation.

## Install (per machine)

```bash
git clone git@github.com:karoldabro/vault.git ~/workspace/vault
cd ~/workspace/vault && ./setup.sh --full --yes
```

`setup.sh` is the umbrella installer. On **Ubuntu** (apt + sudo) `--full` **auto-installs** the whole
tool stack — ollama + `nomic-embed-text`, uv + Serena, bun + claude-mem, pipx + Graphify, and the
OpenViking / claude-mem Claude Code plugins — scaffolds `~/vault/_global/`, runs a health-check
(`doctor`) pass, then calls `install.sh` to symlink the slash commands. Restart Claude Code afterwards so
the new plugins load.

Auto-install is **consent-gated**: it prompts before touching anything (skip the prompt with `--yes`),
prints every remote source URL it runs for an audit trail, and is fully idempotent. On a host **without
apt/sudo** (macOS, containers) it degrades to printing the exact install commands instead of executing —
it never half-installs or hangs. Verify any time with `./setup.sh --doctor`.

Flags:

| Flag | Effect |
|------|--------|
| `--full` | Install the whole stack: OpenViking, Serena, claude-mem, Graphify (recommended). |
| `--minimal` | Framework only — skip the tools. Commands degrade without them. |
| `--with-ov` | OpenViking: ollama + `nomic-embed-text` + `~/.openviking/ov.conf` + the OV plugin. |
| `--with-serena` / `--with-claude-mem` | Install one tool (uv+Serena / bun+claude-mem). |
| `--with-graphify` | Install pipx + Graphify (per-project commit hook is installed by `/v-init`). |
| `--yes`, `-y` | Consent non-interactively (CI/automation). |
| `--dry-run` | Echo every command that would run, without executing it. |
| `--doctor` | Only run the tool-health check, then exit. |

Auto-install runs vendor `curl\|sh` scripts (ollama/uv/bun) and adds two third-party Claude marketplaces
— every source is printed before it runs. See `vault/decisions/ADR-005-installer-auto-exec.md`. (Morph
Fast Apply is not wired by the installer — it needs a paid API key.)

For just refreshing the symlinks after a `git pull`:

```bash
./install.sh
```

Idempotent; refuses to overwrite any non-symlink in `~/.claude/commands/`; prunes stale symlinks pointing at deleted command sources.

## Attach to a project (per project)

```bash
cd ~/workspace/<your-code-repo>
~/workspace/vault/bin/vault-init.sh
# …or keep the vault inside the repo:
~/workspace/vault/bin/vault-init.sh --in-repo
```

This creates the vault (global `~/vault/<slug>/`, or `<code-repo>/vault/` with `--in-repo`), scaffolds folders + indexes (incl. `indications/`), writes `.gitignore`, writes a `VAULT.md` at the repo root recording the vault path, registers the slug in `~/vault/_global/coupled-groups.md`, appends a memory-stack snippet to the code repo's `CLAUDE.md`, and (for global vaults) makes the initial commit. See `commands/v-init.md` for flags.

### Migrating an old submodule vault

Vaults created before the global model carried a `_process/` submodule. Convert one in place:

```bash
cd ~/workspace/<your-code-repo>
~/workspace/vault/bin/vault-migrate.sh
```

It de-inits the submodule, writes `VAULT.md`, repoints the MOC, and commits. Idempotent.

## Contents

```
vault/
├── README.md              # this file
├── vault-guide.md         # canonical process doc — read this
├── setup.sh               # umbrella installer — Ubuntu auto-install + onboarding
├── lib/installers.sh      # per-tool install_X/check_X + the run() executor seam
├── install.sh             # idempotent command installer
├── bin/                   # vault-init.sh, vault-migrate.sh and other host-callable scripts
├── templates/             # decision, feature, indication, session, project-moc, process, architecture, VAULT
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

The framework leans on a few tools that keep token cost down. `./setup.sh --full` installs them on
Ubuntu:

| Tool | Role |
|------|------|
| **OpenViking** | Semantic vault memory (decisions, ADRs, sessions, pitfalls). |
| **claude-mem** | Project history via progressive-disclosure search. |
| **Serena** | Symbol-aware code navigation and refactoring. |
| **Graphify** | Structural code questions — `graph.json` kept fresh by a per-project post-commit hook (installed by `/v-init`), so querying it costs no tokens. |

**MorphLLM Fast Apply** (targeted multi-file edits) is supported but **not** wired by the installer —
it needs a paid API key; register it yourself with `claude mcp add` if you want it.

Grep / full-file reads are the last resort, used only after these layers come up empty (or to verify
an exact current line) — not a substitute. See [`vault-guide.md`](vault-guide.md) §10 for the
token-cost hierarchy and [`tool-playbook.md`](tool-playbook.md) for per-tool rules + examples.
