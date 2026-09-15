---
type: plan
project: vault
slug: setup-auto-install
status: executed   # proposed | approved | executed | superseded
process_record: 2026-06-18-1518-setup-auto-install.trail.md
tags: [plan, team, install, setup, onboarding]
---

# setup-auto-install — plan

Rework `setup.sh` from a detect-and-print-a-hint advisor into an Ubuntu-first auto-installer and
onboarder for the whole vault tool stack, with a Docker-based e2e harness that runs it.

## Task
Make `setup.sh` install all dependencies and tools automatically on Ubuntu (ollama, Graphify,
Claude plugins and MCPs) and onboard them, for a one-command experience.
Keywords: setup.sh · ubuntu-apt · auto-install · ollama · graphify · claude-plugins · mcp · onboarding · idempotent.

## Open & deferred

- **Latent secret leak in `lib/installers.sh`.** `run_shell` prints its pipeline verbatim with no
  redaction, and `_redact_args` only masks `KEY=val`-shaped suffixes. Nothing secret reaches either
  path today, because Morph is the only secret-bearing tool and it is not installed. Adding any
  keyed tool re-opens this. The guardrail lives as a comment at `lib/installers.sh:66`.
- **Deferred: hostile-path hardening in `setup.sh`.** Path validation against adversarial `$HOME` or
  `$PATH` values is not done.
- **Deferred: empty-array expansion under `set -u`.** `${arr[@]}` aborts on bash 4.3 and older. The
  target is Ubuntu with bash 5.2, and the shipped patterns use the empty-safe `[*]` and
  `${#arr[@]}` forms, so no host in scope hits it.
- **Coverage gap: real `claude` marketplace idempotency is unverified.** No `claude` binary exists in
  the e2e image, so re-add behaviour is only stub-tested in `tests/unit/setup-autoinstall.bats`.
- **Coverage gap: e2e proves only uv and graphify.** The ollama and claude install paths are covered
  by dry-run transcript assertions, not by a real install. Noted in `tests/e2e/run.sh`.

## Decisions

| decision | reason | record |
|---|---|---|
| Auto-install is the default on Ubuntu, gated by consent | The ask was a one-command experience; the safety cost is paid by printed URLs, a consent prompt and degrade-on-non-apt | `vault/decisions/ADR-005-installer-auto-exec.md` |
| Morph MCP is not installed at all, and `--with-morph` is not a flag | A paid key for a tool most runs skip is not worth a live secret surface in `setup.sh` | local |
| ollama plus `nomic-embed-text` stays the embedding backend | It matches the working vault stack; the daemon bootstrap stays an advisory note | local |
| The dry-run transcript is the primary tested surface for execute-path logic | The offline alpine suite can never reach the privileged path | local |

## Work items

Dependency-ordered. File · action · key detail.

1. **`setup.sh` → `run()` executor plus dry-run seam.** `run <cmd...>` executes; under
   `VAULT_SETUP_DRY_RUN=1` it echoes `[dry-run] <cmd>` and returns 0. It redacts secret-shaped args.
   **Scope = network and privileged side-effects only** (apt, `curl|sh`, ollama pull, claude CLI,
   uv/bun/pipx installers). Pure-local scaffold (mkdir, heredocs, tool config, calling install.sh)
   stays a **direct** call so the existing offline alpine bats stay green.
2. **`lib/installers.sh` — extract `install_<tool>` and `check_<tool>` pairs**, sourced by setup.sh.
   Each `install_X` runs `check_X` (idempotent guard: `command -v` **plus** a known-path probe of
   `~/.local/bin`, `~/.bun/bin`, `/usr/local/bin`), then if absent prints the source URL, `run`s the
   install and verifies. **Continue-on-error**: a tool failure never aborts the run; record pass/fail
   into a status map.
3. **Platform detect plus consent.** Detect `apt-get` and `sudo -n true`. Ubuntu with sudo takes the
   auto-install path; no apt or no sudo degrades to the hint path and exits 0, never halting.
   Auto-install prints what it will install and every remote URL, and requires consent: an
   interactive prompt unless `--yes`.
4. **Base prereqs:** `sudo apt-get update && sudo apt-get install -y git curl jq ca-certificates unzip`
   (`unzip` is required by the bun installer).
5. **Foundational runtimes:** uv via `curl -LsSf https://astral.sh/uv/install.sh | sh`; bun via
   `curl -fsSL https://bun.com/install | bash`. PATH-probe their bins.
6. **ollama:** official `curl -fsSL https://ollama.com/install.sh | sh`; ensure the daemon runs
   (`systemctl enable --now ollama` on systemd hosts, else `ollama serve &` plus a readiness poll,
   required so the model pull works in containers); `ollama pull nomic-embed-text` guarded by
   `ollama list | grep -q`.
7. **pipx plus graphify:** `sudo apt-get install -y pipx && pipx ensurepath`; `pipx install graphifyy`
   (PyPI package `graphifyy`, binary `graphify`); verify `graphify --version`. Per-repo
   `graphify hook install` stays `/v-init`'s job, noted only.
8. **serena:** `uv tool install -p 3.13 serena-agent`.
9. **Claude plugins (new capability).** Probe `command -v claude` plus a version floor; absent or old
   degrades this section to hints. Otherwise each step is guarded for idempotency under `set -e`:
   `claude plugin marketplace add thedotmack/claude-mem` then
   `claude plugin install claude-mem@claude-mem --scope user`, falling back to
   `claude plugin install claude-mem`.
10. **Secret-bearing config files** (anything holding a key): write under `( umask 077; … )` so they
    land `0600`; `chmod 700` on `~/.claude`.
11. **Doctor pass** (`setup.sh --doctor`, also auto-run at the end): per tool, check presence and
    health via an absolute path or a **fresh** `claude` invocation, never the live session. Print a
    ✓/✗ table. Exit non-zero only if a *required* tool failed. Print "restart Claude Code to load new
    plugins/MCPs". Never print secrets.
12. **Flags:** add `--dry-run` (sugar for `VAULT_SETUP_DRY_RUN=1`, implies non-interactive) and
    `--doctor`; keep `--full/--minimal/--with-*/--yes`; document precedence, where `--minimal` zeroes
    tools first.
13. **Tests** — the `## Test plan` section below.
14. **README rewrite** plus `vault/decisions/ADR-005-installer-auto-exec.md`, documenting the safety
    stance: auto-exec, consent-gated, audit-logged, degrade-on-non-apt. Folds in the doc and name
    fixes, including the wrong plugin id.

## Tool install commands

| tool | install | verify | idempotency guard |
|------|---------|--------|-------------------|
| ollama | `curl -fsSL https://ollama.com/install.sh \| sh` + `ollama pull nomic-embed-text` | `ollama --version` | `ollama list \| grep -q '^nomic-embed-text'` |
| graphify | `pipx install graphifyy` | `graphify --version` | `pipx list \| grep -q graphifyy` |
| claude-mem | `claude plugin marketplace add thedotmack/claude-mem` + `claude plugin install claude-mem` (bun auto-installed) | `claude plugin list \| grep -q claude-mem` | same |
| serena | `uv tool install -p 3.13 serena-agent` | `serena --help` | `uv tool list \| grep -q serena-agent` |
| uv | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `uv --version` | `command -v uv` / `~/.local/bin/uv` |
| bun | `curl -fsSL https://bun.com/install \| bash` (needs `unzip`) | `bun --version` | `command -v bun` / `~/.bun/bin/bun` |

## Test plan
- **Keep** `tests/unit/install.bats` and `tests/integration/setup.bats` green unchanged. On the
  offline alpine image there is no apt, so setup.sh takes the hint path and every current assertion
  holds.
- **New `tests/unit/setup-autoinstall.bats`** (offline; fake `apt-get`/`claude`/`sudo` on PATH plus
  `--dry-run`). It asserts that the dry-run transcript carries the right commands in the right order,
  that idempotency guards are emitted, that secrets are redacted, that sudo is scoped to apt only,
  that an absent `claude` degrades to hints, and that a stubbed mid-run failure still runs later
  tools and reports through doctor. This is the primary tested surface for the execute path.
- **New `tests/e2e/`** — its own `tests/e2e/run.sh` and `tests/e2e/Dockerfile.ubuntu` (real Ubuntu,
  `--network`, root, writable repo copy). It runs `setup.sh --full --yes`, starts `ollama serve`
  explicitly, and asserts binaries land and doctor exits 0. **Gated behind `VAULT_E2E=1`**, erroring
  with a clear message otherwise. Re-point the Makefile `test-e2e` target at it. Off the default
  `make test` path.

## Test backlog

| id | source | kind | target | intent | priority | disposition |
|----|--------|------|--------|--------|----------|-------------|
| arch-t1 | design review | unit | scaffold files written even under dry-run | run() doesn't swallow local writes (keeps bats valid) | must | |
| arch-t2 | design review | unit | dry-run transcript: commands + order, no real apt/net | dry-run seam covers privileged cmds only | must | |
| arch-t3 | design review | unit | stubbed single-tool failure → others run + doctor summary | partial-failure continuation | must | |
| arch-t4 | design review | integration | non-apt host → hint path, exit 0, old bats pass | degrade contract backward-compat | must | |
| arch-t5 | design review | unit | second run reports zero install actions | re-runnable idempotency + PATH probe | should | |
| arch-t6 | design review | e2e | Ubuntu+network `--full --yes` → doctor all-present, exit 0 | the "does it install" gate | should | |
| arch-t7 | design review | e2e | e2e runner refuses without VAULT_E2E=1 | keep net installs off PR path | nice | |
| sec-t2 | security review | integration | secret files are 0600, dirs not world-readable | secret-at-rest perms | must | |
| sec-t3 | security review | unit | URL/source printed before each curl\|sh + marketplace add | consent/audit trail even under --yes | should | |
| sec-t4 | security review | unit | only apt prefixed with sudo; absent sudo → hint path | sudo scoping | should | |
| sec-t5 | security review | unit | doctor with key configured prints no key value | doctor never leaks secret | should | |
| skep-t3 | skeptic review | unit | claude absent / below floor → hints, exit 0 | no hard failure on missing CLI | must | |
| skep-t2 | skeptic review | unit | re-run with artifacts present → each guard fires, no-op | marketplace/plugin/model idempotency under set -e | must | |
| skep-t6 | skeptic review | e2e | Ubuntu w/ `ollama serve` started, model pull deterministic | non-flaky e2e | should | |

## Rollback

Revert the commit that adds `lib/installers.sh` and rewrites `setup.sh`. Nothing installed on a host
is undone by that revert: uv, bun, ollama, pipx, graphify and serena stay where they landed, and
`~/.claude` keeps its `0700` mode. To stop auto-install without reverting, run `setup.sh` on a host
with no `apt-get` or no passwordless sudo, or pass `--dry-run`; both take the hint path and exit 0.

## Refs
- `vault/decisions/ADR-005-installer-auto-exec.md` — the ruling that lets `setup.sh` execute remote
  installers, and the conditions it must meet.
- Process record: `vault/plans/2026-06-18-1518-setup-auto-install.trail.md` — the findings, the
  corrections to the draft commands, and the options that lost.
