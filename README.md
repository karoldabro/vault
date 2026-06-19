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

> **Run it as your normal user — not with `sudo`.** The installer is per-user: uv, bun, the
> plugins, and `~/.openviking/ov.conf` all land in `$HOME`. It escalates *for you* — when it
> reaches the apt/ollama steps it prompts once for your sudo password. Running `sudo ./setup.sh`
> would flip `$HOME` to `/root` and strand everything there, so it's refused (override with
> `VAULT_ALLOW_SUDO=1` only if you truly mean it). After it finishes, open a fresh shell
> (`exec $SHELL -l`) so the new PATH entries (uv/bun/pipx) are visible. Note there is no `ov`
> command — OpenViking is the MCP plugin + ollama backend; check it via `./setup.sh --doctor`.

`setup.sh` is the umbrella installer. On **Ubuntu** (apt + sudo) `--full` **auto-installs** the whole
tool stack — ollama + `nomic-embed-text`, the OpenViking server (`pipx install openviking`) + its
`~/.openviking/` config + a systemd `--user` service on :1933, uv + Serena, bun + claude-mem, pipx +
Graphify, and the OpenViking / claude-mem Claude Code plugins (incl. the plugin client config the MCP
requires) — scaffolds `~/vault/_global/`, runs a health-check (`doctor`) pass, then calls `install.sh`
to symlink the slash commands. Restart Claude Code afterwards so the new plugins load.

Auto-install is **consent-gated**: it prompts before touching anything (skip the prompt with `--yes`),
prints every remote source URL it runs for an audit trail, and is fully idempotent. On a host **without
apt** (macOS) — or **non-interactively without passwordless sudo** (headless CI, where it can't prompt
for the apt/ollama steps) — it degrades to printing the exact install commands instead of executing, so
it never half-installs or hangs. Verify any time with `./setup.sh --doctor`.

Flags:

| Flag | Effect |
|------|--------|
| `--full` | Install the whole stack: OpenViking, Serena, claude-mem, Graphify (recommended). |
| `--minimal` | Framework only — skip the tools. Commands degrade without them. |
| `--with-ov` | OpenViking: ollama + `nomic-embed-text`, the `openviking` server (pipx) + `ov.conf` + client `config.json` + `:1933` user service, and the OV plugin. |
| `--with-serena` / `--with-claude-mem` | Install one tool (uv+Serena / bun+claude-mem). |
| `--with-graphify` | Install pipx + Graphify (per-project commit hook is installed by `/v-init`). |
| `--yes`, `-y` | Consent non-interactively (CI/automation). |
| `--dry-run` | Echo every command that would run, without executing it. |
| `--doctor` | Only run the tool-health check, then exit. |

Auto-install runs vendor `curl\|sh` scripts (ollama/uv/bun) and adds two third-party Claude marketplaces
— every source is printed before it runs. See `vault/decisions/ADR-005-installer-auto-exec.md`. (Morph
Fast Apply is not wired by the installer — it needs a paid API key.)

> The pipx-installed tools (`openviking`, `graphifyy`) require **Python ≥3.10**; the installer pins a
> `python3.12`/`3.11`/`3.10` it finds on PATH. On an old host (e.g. WSL/Ubuntu 20.04 = Python 3.8) pipx
> would otherwise fail with the misleading "No matching distribution found" — install `python3.12`
> (`sudo apt install -y python3.12 python3.12-venv`, or the deadsnakes PPA) and re-run. `--doctor` flags
> a missing ≥3.10 interpreter.

For just refreshing the symlinks after a `git pull`:

```bash
./install.sh
```

Idempotent; refuses to overwrite any non-symlink in `~/.claude/commands/`; prunes stale symlinks pointing at deleted command sources.

> `--with-ov` also points Claude at the OV configs by writing `OPENVIKING_CC_CONFIG_FILE` and
> `OPENVIKING_CONFIG_FILE` into `~/.claude/settings.json` (`env`) — the stock OV plugin `.mcp.json`
> references those, and without them the MCP exits with "Connection closed". The merge is
> non-clobbering: a user value that points at a real file is kept; only absent or stale (missing-file)
> values are set.

### Uninstall

```bash
./bin/vault-uninstall.sh --yes          # remove framework wiring (reversible, no data loss)
./bin/vault-uninstall.sh --dry-run      # preview the plan
```

Default removes only the **wiring**: command symlinks, the OpenViking `--user` service, `ov.conf` +
the plugin client config, the two `settings.json` env keys, and the OV/claude-mem plugins. Opt into
more: `--tools` (uninstall `openviking`/`graphifyy`/`serena-agent`; never the shared
ollama/uv/bun/node), `--purge-data` (delete `~/.openviking` + `~/vault/_global` — destructive),
`--all` (both). Without `--yes` (and no TTY) it just prints the plan. Project vaults and your repos are
never touched.

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

## Vault location & `VAULT.md`

Every command resolves two paths at startup:

- **Framework path** — `$VAULT_FRAMEWORK_PATH` (default `~/workspace/vault`), recorded at install time in
  `~/vault/_global/config.md`. Holds the guide, templates, and commands. Files that get committed (a
  repo's `VAULT.md`, the `CLAUDE.md` snippet, an in-repo vault's `_moc.md`) reference it **symbolically**
  as `$VAULT_FRAMEWORK_PATH` — never a resolved absolute path — so a shared repo stays portable across
  machines and users (each resolves it from their own env / `config.md`).

- **Vault path** — first hit wins:
  1. `<repo-root>/VAULT.md` → `vault_path` (relative `./vault` = in-repo; absolute or `~/…` = global).
  2. `~/vault/_global/config.md` → `vault_home` (the global default).
  3. Built-in default `~/vault/<slug>/`.

`VAULT.md` (repo root, optional, written by `/v-init`) is the **per-repo config**. Delete it to fall back
to the global default. It carries bounded sections, read on every command:

| Section | Keys | Effect |
|---------|------|--------|
| `config` | `vault_path`, `framework_path`, `slug` | Path + identity resolution (above). |
| `structure` | `add_folders`, `rename`, `optional` | Scaffold extra folders, alias standard ones, silence missing optional ones. |
| `behaviour` | `load_context_extra`, `capture_indications` | Extra folders Step 2 loads; whether capture runs the indication scan. |
| `personas` *(for `/v-team`)* | `use`, `add`, `skip`, `team_max_*` | Which critic pack + critics review the plan/diff. |

Unknown keys are ignored; an absent `VAULT.md` means all defaults + a global vault. Full resolution rules:
[`vault-guide.md`](vault-guide.md) §1.1.

## Contents

```
vault/
├── README.md              # this file
├── vault-guide.md         # canonical process doc — read this
├── setup.sh               # umbrella installer — Ubuntu auto-install + onboarding
├── lib/installers.sh      # per-tool install_X/check_X + the run() executor seam
├── install.sh             # idempotent command installer
├── bin/                   # vault-init.sh, vault-migrate.sh, vault-uninstall.sh — host-callable scripts
├── templates/             # decision, feature, indication, session, project-moc, process, architecture, VAULT
├── personas/              # /v-team critic packs (api-laravel, nuxt, flutter, marketing) + _shared lenses (incl. _shared/testing/ group)
├── commands/              # v-work, v-team, v-capture, v-init … — linked into ~/.claude/commands/ by install.sh
├── tests/                 # bats-core: unit/ + integration/ (offline alpine) + e2e/ (opt-in Ubuntu)
└── Makefile               # `make test` (offline), `VAULT_E2E=1 make test-e2e`, `make shell`
```

## Tests

Two tiers, both in Docker. Docker is the only host prerequisite.

**Offline suite** (default, PR-blocking) — unit + integration on alpine, no network or sudo:

```bash
make test              # unit + integration
make test-unit
make test-integration
```

The repo is mounted **read-only** at `/code`; tests use a tmpfs `$HOME`. The image is built from
`tests/Dockerfile` (alpine + bats-core + bash/git/jq). The installer's execute path is covered here via
the `--dry-run` transcript (`tests/unit/setup-autoinstall.bats`) — real command construction, no real installs.

**End-to-end** (opt-in, slow) — actually runs `setup.sh` on a throwaway **Ubuntu** container with real
network, proving the installers land on disk:

```bash
VAULT_E2E=1 make test-e2e
```

Gated behind `VAULT_E2E=1` (errors otherwise) and kept off the default `make test` path. Built from
`tests/e2e/Dockerfile.ubuntu`. Covers the lightweight installers (uv via `curl|sh`, Graphify via pipx);
the ollama daemon and `claude` plugin paths are covered only at the dry-run level (see `tests/e2e/run.sh`).

## Commands provided

Installed into `~/.claude/commands/` by `install.sh`:

| Command | Purpose |
|---------|---------|
| `/v-work` | Vault-aware dev lifecycle: load context → propose (with dedupe) → approval → execute → commit + capture. |
| `/v-team` | Heavier sibling of `/v-work` for high-stakes work — parallel persona critics review the plan + diff in tool-grounded loops. |
| `/v-cr` | Automated code review on a remote PR/MR — auto-detects the forge, gathers diff + linked task + vault knowledge, runs the critic panel, posts inline + summary comments. Optional `--sandbox` runs the PR in an isolated Docker clone for runtime-verified findings. See [Code review (`/v-cr`)](#code-review-v-cr) below. |
| `/v-capture` | Capture this session into the vault. Dedupes, updates indexes, extracts ADR + indication candidates, cross-links Refs. |
| `/v-init` | Bootstrap a project vault for the current code repo (writes `VAULT.md`, scaffolds folders + indexes). |
| `/v-migrate` | Convert an old `_process/` submodule vault to the global model. |
| `/v-resume` | Force a fresh recall from the vault + OpenViking. |
| `/v-sync` | Re-ingest a project's curated knowledge into OpenViking. |
| `/v-link` | Declare two projects as a coupled group (shared recall). |
| `/v-backfill` | Ingest past Claude Code chat transcripts into OpenViking. |
| `/v-guide` | Generate a cross-project integration guide from a feature. |

See [`vault-guide.md`](vault-guide.md) §10 for the full command reference.

## Code review (`/v-cr`)

`/v-cr` reviews a remote pull/merge request and posts grounded comments back. It auto-detects the forge
from your git remote, gathers the diff + linked task (Jira/Asana/forge issue) + your vault knowledge, runs
the tool-grounded critic panel, and writes deduplicated inline + summary comments. **It never commits,
pushes, or applies code** — read-only on the codebase, write-only to the forge's comments.

```bash
/v-cr                      # review the PR for the current branch (auto-detected)
/v-cr <url|number>         # review a specific PR/MR
/v-cr --no-post            # review + capture only; never post (findings still saved to the vault)
/v-cr --post               # skip re-confirmation after a target was confirmed this session
/v-cr --unpost             # remove every comment this tool posted to the target PR
```

**The first post to any `host/owner/repo#PR` is always gated** — `/v-cr` renders the exact comment bodies
and targets and stops for your confirmation before writing anything. `--post` only skips *re-confirmation*
within a session. Setup: works out of the box for GitHub (`gh auth status`) and Bitbucket Cloud/Server.
Self-hosted hosts: map them with `VCR_HOST_MAP` (host→platform). Jira/Asana context is opt-in via
`VCR_JIRA_PROJECTS` (key allowlist) / the Asana MCP. Comments are deduplicated by a stable
`sha256(file:rule:code_hash)` fingerprint, so re-running on an updated PR won't repost unchanged findings.

### `--sandbox` — runtime-verified review (optional, off by default)

Plain `/v-cr` only *reads* the diff. `--sandbox` actually **runs** the PR so the panel can *prove* a
finding (reproduce a bug, run a failing test) instead of guessing — the precision multiplier. It fetches
the PR into a **throwaway clone** (never a git worktree against your repo), builds a locked-down Docker
sandbox, runs a **tests-first gate**, hands the panel runtime evidence (analyzers, diff-coverage, repro),
then **tears everything down**.

```bash
/v-cr --sandbox                  # fetch → isolate → tests-first → runtime-verified review → teardown
/v-cr --sandbox --baseline       # also run the upstream base, so only NEW test failures gate the PR
/v-cr --sandbox --allow-net-install   # allow unrestricted egress during install (off by default)
/v-cr --sandbox-gc               # maintenance: reap orphaned sandbox containers/volumes/dirs
```

**Prerequisites & setup:**
- **Docker** running on the host. **GitHub** is the validated path; Bitbucket is fetch-capability-gated and
  falls back to API-only review if the PR ref isn't fetchable.
- **`VCR_SANDBOX_MAP`** (user/global env) is the **isolation envelope** — network policy, resource caps
  (`--memory`/`--cpus`/`--pids-limit`), env-passthrough policy, mounts, and the package-registry proxy +
  allowlist. It is **framework-owned**: it is read only from per-stack defaults + your user/global config,
  **never** from the repo or a project indication. A PR's own Dockerfile/compose can be built and run only
  *inside* this envelope — it can never widen it.
- A project may override only **benign recipe bits** (image / install / test / lint / ports / build) via
  its vault `indications/` or `VAULT.md` `behaviour.sandbox`. Every isolation-envelope key is stripped from
  a repo/indication recipe before merging.
- Optional `VCR_SANDBOX_ROOT` relocates where throwaway clones live (default `$TMPDIR/v-cr-sandbox`).

**Concurrency.** Yes — you can run several `/v-cr --sandbox` at once, even on the same PR. Each run gets a
unique sandbox (clone dir + Docker objects labelled `com.vault.v-cr.sandbox=<name>` + its own free ports)
keyed by a per-run nonce, so concurrent runs never collide. Because provisioning is a clone (not a
worktree), a crashed run never leaves an orphan in your repo's `.git/worktrees`; sweep any leftover Docker
objects/dirs with `/v-cr --sandbox-gc`.

**Test gate behaviour.** A *new* failure attributable to the PR → headline **blocking** finding (the deep
panel is skipped — this is "tests fail → fail"). A red suite with **unverified attribution** (no CI signal,
no `--baseline`) → **advisory** only; the panel continues, so an honest PR is never blocked on someone
else's broken `main`.

**Safety posture.** `--sandbox` runs **attacker-authorable code**. Docker is *not* a true sandbox for
hostile code, so the posture is *make escape irrelevant*: no host secrets in the container (empty env,
allow-list only), **no egress during execution**, resource caps, non-root, everything throwaway, and a
human gate on every write. All runtime output (test logs, analyzer output, even a `postinstall` body
surfaced as a finding) is secret-scrubbed and fenced as untrusted data before it reaches a critic, comment,
or the vault. Residual risk: a kernel exploit can still escape — for a hostile threat model, run rootless
Docker / gVisor / a microVM runtime. See `commands/v-cr/sandbox.md`,
`vault/decisions/ADR-009-v-cr-sandboxed-execution.md`, and `vault/indications/sandboxed-cr-safety.md`.

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
