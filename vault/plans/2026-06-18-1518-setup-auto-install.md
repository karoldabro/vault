---
type: plan
project: vault
slug: setup-auto-install
status: executed   # proposed | approved | executed | superseded
# Gate decisions (2026-06-18): implement all · auto-install default on Ubuntu (consent-gated, T1) · Morph MCP DROPPED entirely (T3) · keep ollama+nomic for OV (T2).
personas: [generic: software-architect, security, skeptic]
rounds: 1 propose + 1 diff-review
convergence: clean   # all confirmed BLOCKER/MAJOR applied in both loops; no open blockers
tags: [plan, team, install, setup, onboarding]
---

# setup-auto-install — team plan

Rework `setup.sh` from a "detect-and-print-a-hint" advisor into a real, Ubuntu-first **auto-installer +
onboarder** for the whole vault tool stack, with a Docker-based e2e harness that actually runs it.

## Task
Make `setup.sh` install all dependencies + tools automatically on Ubuntu (ollama, OpenViking, Graphify,
Claude plugins + MCPs) and onboard them, for a smooth one-command experience.
Keywords: setup.sh · ubuntu-apt · auto-install · ollama · openviking · graphify · claude-plugins · mcp · onboarding · idempotent.

## Converged plan (v1)

Dependency-ordered. File · action · key detail.

1. **`setup.sh` → `run()` executor + dry-run seam.** `run <cmd...>` executes; under `VAULT_SETUP_DRY_RUN=1`
   it echoes `[dry-run] <cmd>` and returns 0. Redacts secret-shaped args (`MORPH_API_KEY=…` → `***`).
   **Scope = network/privileged side-effects only** (apt, `curl|sh`, ollama pull, claude CLI, uv/bun/pipx
   installers). Pure-local scaffold (mkdir, heredocs, ov.conf, calling install.sh) stays a **direct** call
   so existing offline alpine bats stay green. [arch-3, skep-6, sec-5]
2. **`lib/installers.sh` — extract `install_<tool>` + `check_<tool>` pairs**, sourced by setup.sh. Each
   `install_X`: `check_X` (idempotent guard: `command -v` **plus** known-path probe `~/.local/bin`,
   `~/.bun/bin`, `/usr/local/bin`) → if absent, print the source URL → `run` the install → verify.
   **Continue-on-error**: a tool failure never aborts the run; record pass/fail into a status map.
   [arch-6, arch-4, skep-2 (BLOCKER), skep-10]
3. **Platform detect + consent.** Detect `apt-get` + `sudo -n true`. Ubuntu+sudo → auto-install path;
   no apt / no sudo → degrade to today's **hint path**, exit 0 (never halt). Auto-install prints what it
   will install + every remote URL, and requires consent: interactive prompt unless `--yes`.
   [arch-2, skep-1, sec-2, sec-6]
4. **Base prereqs:** `sudo apt-get update && sudo apt-get install -y git curl jq ca-certificates unzip`
   (`unzip` is required by the bun installer). [researcher]
5. **Foundational runtimes:** uv `curl -LsSf https://astral.sh/uv/install.sh | sh`; bun
   `curl -fsSL https://bun.com/install | bash` (note `bun.com`, not `bun.sh`). PATH-probe their bins. [researcher]
6. **ollama:** official `curl -fsSL https://ollama.com/install.sh | sh`; ensure the daemon runs
   (`systemctl enable --now ollama` on systemd hosts, else `ollama serve &` + readiness poll — required so
   the model pull works in containers); `ollama pull nomic-embed-text` guarded by `ollama list | grep -q`.
   [researcher, skep-5 (BLOCKER)]
7. **pipx + graphify:** `sudo apt-get install -y pipx && pipx ensurepath`; `pipx install graphifyy`
   (PyPI pkg `graphifyy`, binary `graphify`); verify `graphify --version`. Per-repo `graphify hook install`
   stays `/v-init`'s job (note only). [researcher]
8. **serena:** `uv tool install -p 3.13 serena-agent` — **CORRECTED** from the v0 draft's
   `serena-agent@latest --prerelease=allow` (not the current upstream command). [researcher]
9. **Claude plugins / MCPs (new capability).** Probe `command -v claude` + a version floor; absent/old →
   degrade this section to hints. Else, each step guarded for idempotency under `set -e`:
   - `claude plugin marketplace list | grep -q openviking || claude plugin marketplace add Castor6/openviking-plugins`,
     then `claude plugin install claude-code-memory-plugin@openviking-plugin --scope user` (guard: `claude plugin list | grep -q`).
   - `… thedotmack/claude-mem` → `claude plugin install claude-mem@claude-mem --scope user` (fallback `claude plugin install claude-mem`).
   - **Morph MCP only if `$MORPH_API_KEY` is set** (never prompt under `--yes`; pass env **by reference**, never the literal key in a logged string; redact in transcript):
     `claude mcp add filesystem-with-morph --scope user -e MORPH_API_KEY -- npx --prefer-offline -y @morphllm/morphmcp`
     (guard: `claude mcp list | grep -q`). Package **CORRECTED** to `@morphllm/morphmcp`. [researcher, skep-3, skep-7, sec-1, sec-5]
10. **Secret-bearing config files** (ov.conf + anything holding a key): write under `( umask 077; … )` →
    `0600`; `chmod 700` `~/.openviking` and `~/.claude`. [sec-4]
11. **Doctor pass** (`setup.sh --doctor`, also auto-run at end): per tool check presence/health via absolute
    path or a **fresh** `claude` invocation (not the live session); print a ✓/✗ table; exit non-zero only if a
    *required* tool failed; print "restart Claude Code to load new plugins/MCPs". Never prints secrets.
    [arch-4, skep-4, sec-5]
12. **Flags:** add `--dry-run` (sugar → `VAULT_SETUP_DRY_RUN=1`, implies non-interactive) and `--doctor`;
    keep `--full/--minimal/--with-*/--yes`; document precedence (`--minimal` zeroes tools first). [arch-8]
13. **Tests** — see Test plan.
14. **README rewrite** + **ADR-005** documenting the safety-stance reversal (auto-exec, consent-gated,
    audit-logged, degrade-on-non-apt). Folds in the minimal doc/name fixes (wrong plugin id). [arch-2, skep-1, skep-8]

## Test plan
- **Keep** existing `tests/unit/install.bats` + `tests/integration/setup.bats` green unchanged — on the
  offline alpine image (no apt) setup.sh takes the hint path, so all current assertions hold. [arch-t4, skep-t8]
- **New `tests/unit/setup-autoinstall.bats`** (offline; fake `apt-get`/`claude`/`sudo` on PATH + `--dry-run`):
  assert the dry-run transcript has the right commands in the right order, idempotency guards are emitted,
  secrets are redacted, sudo is scoped to apt only, `claude`-absent degrades to hints, and a stubbed
  mid-run failure still runs later tools + reports via doctor. This is the **primary tested surface** for
  the execute-path logic (closes the coverage illusion). [arch-t1/t2/t3/t5, sec-t1/t3/t4, skep-t1–t4,t7]
- **New `tests/e2e/`** — own `tests/e2e/run.sh` + `tests/e2e/Dockerfile.ubuntu` (real Ubuntu, `--network`,
  root, writable repo copy). Runs `setup.sh --full --yes`, starts `ollama serve` explicitly, asserts
  binaries land + doctor exits 0. **Gated behind `VAULT_E2E=1`** (errors with a clear message otherwise);
  re-point the Makefile `test-e2e` target at it. Off the default `make test` path. [arch-1, arch-t6/t7, skep-t6]

## Tool-instruction grounding (researcher, GitHub/official sources)
| tool | install | verify | idempotency guard |
|------|---------|--------|-------------------|
| ollama | `curl -fsSL https://ollama.com/install.sh \| sh` + `ollama pull nomic-embed-text` | `ollama --version` | `ollama list \| grep -q '^nomic-embed-text'` |
| OpenViking plugin | `claude plugin marketplace add Castor6/openviking-plugins` + `claude plugin install claude-code-memory-plugin@openviking-plugin` | `claude plugin list \| grep -q claude-code-memory-plugin` | same |
| graphify | `pipx install graphifyy` | `graphify --version` | `pipx list \| grep -q graphifyy` |
| claude-mem | `claude plugin marketplace add thedotmack/claude-mem` + `claude plugin install claude-mem` (bun auto-installed) | `claude plugin list \| grep -q claude-mem` | same |
| serena | `uv tool install -p 3.13 serena-agent` | `serena --help` | `uv tool list \| grep -q serena-agent` |
| morph MCP | `claude mcp add filesystem-with-morph --scope user -e MORPH_API_KEY -- npx -y @morphllm/morphmcp` | `claude mcp list \| grep -q filesystem-with-morph` | same |
| uv | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `uv --version` | `command -v uv` / `~/.local/bin/uv` |
| bun | `curl -fsSL https://bun.com/install \| bash` (needs `unzip`) | `bun --version` | `command -v bun` / `~/.bun/bin/bun` |

Corrections vs v0 draft: **serena** = `-p 3.13 serena-agent` (no `@latest`/`--prerelease`); **morph** = `@morphllm/morphmcp` (not `@razorback16/morph-mcp`); **bun** = `bun.com/install` + needs `unzip`.

## Proposed test backlog

| id | persona | kind | target | intent | priority | disposition |
|----|---------|------|--------|--------|----------|-------------|
| arch-t1 | architect | unit | scaffold files written even under dry-run | run() doesn't swallow local writes (keeps bats valid) | must | |
| arch-t2 | architect | unit | dry-run transcript: commands + order, no real apt/net | dry-run seam covers privileged cmds only | must | |
| arch-t3 | architect | unit | stubbed single-tool failure → others run + doctor summary | partial-failure continuation | must | |
| arch-t4 | architect | integration | non-apt host → hint path, exit 0, old bats pass | degrade contract backward-compat | must | |
| arch-t5 | architect | unit | second run reports zero install actions | re-runnable idempotency + PATH probe | should | |
| arch-t6 | architect | e2e | Ubuntu+network `--full --yes` → doctor all-present, exit 0 | the "does it install" gate | should | |
| arch-t7 | architect | e2e | e2e runner refuses without VAULT_E2E=1 | keep net installs off PR path | nice | |
| sec-t1 | security | unit | Morph dry-run transcript has no raw key | secret never echoed | must | |
| sec-t2 | security | integration | ov.conf + secret files are 0600, dirs not world-readable | secret-at-rest perms | must | |
| sec-t3 | security | unit | URL/source printed before each curl\|sh + marketplace add | consent/audit trail even under --yes | should | |
| sec-t4 | security | unit | only apt prefixed with sudo; absent sudo → hint path | sudo scoping | should | |
| sec-t5 | security | unit | doctor with key configured prints no key value | doctor never leaks secret | should | |
| skep-t3 | skeptic | unit | claude absent / below floor → hints, exit 0 | no hard failure on missing CLI | must | |
| skep-t2 | skeptic | unit | re-run with artifacts present → each guard fires, no-op | marketplace/plugin/model idempotency under set -e | must | |
| skep-t6 | skeptic | e2e | Ubuntu w/ `ollama serve` started, model pull deterministic | non-flaky e2e | should | |
| skep-t7 | skeptic | unit | Morph with `$MORPH_API_KEY` set vs unset under --yes | both secret branches, no TTY prompt | should | |

## Open trade-offs / escalations (decide at gate)

- **T1 — safety-stance reversal (architect arch-2 + skeptic skep-1).** Both critics wanted default = today's
  hints with an opt-in `--auto`. I resolved **toward auto-install-as-default on Ubuntu** because that's the
  explicit ask ("smooth experience"). Mitigations adopted: every remote URL/source printed, consent prompt
  unless `--yes`, degrade-on-non-apt, ADR-005. **→ Confirm you want auto-install to be the default (consent-gated), not a separate opt-in flag.**
- **T2 — OpenViking embedding backend.** The researcher notes the OV *plugin* uses its own providers, while
  our current `ov.conf` points at ollama + `nomic-embed-text` (matches the working vault stack). Plan keeps
  ollama+nomic; full OV-server bootstrap (`pip install openviking` + `openviking-server`) left as an advisory
  note, not auto-run. **→ OK to keep ollama+nomic and not auto-bootstrap the OV server?**
- **T3 — Morph needs a paid API key.** Skipped unless `$MORPH_API_KEY` is in the environment (never prompted).
  **→ OK to skip Morph silently-with-a-note when the key is absent?**
- **Deferred (recorded, non-blocking):** sec-7 hostile-path hardening (NIT), skep-4 restart-race (doctor uses
  fresh `claude` + prints restart note), arch-8 flag-matrix docs.
- **skep-8 (rejected, advisory):** "ship only the minimal name/doc fix." Rejected — counter to the explicit
  ask for full auto-install + e2e. Its minimal fixes (correct plugin id, reconcile README/bats) are folded in.

## Critique trail

### Round 0 — draft
Design v0 (run()/dry-run, Ubuntu detect+degrade, real installers, doctor, Ubuntu e2e). Full v0 in git history.

### Round 1 — findings + dispositions
| persona | id | severity | grounding | issue (short) | disposition |
|---------|----|----------|-----------|---------------|-------------|
| architect | arch-1 | MAJOR | confirmed | e2e can't reuse run.sh (no net/sudo, :ro) | applied (own e2e runner) |
| architect | arch-2 | MAJOR | confirmed | silent contract inversion of --full | applied (consent + ADR + README) → T1 |
| architect | arch-3 | MAJOR | confirmed | run() must not swallow local scaffold writes | applied (run scope = privileged only) |
| architect | arch-4 | MAJOR | confirmed | set -e aborts before doctor on first fail | applied (continue-on-error + doctor exit) |
| architect | arch-5/6/7/8 | MINOR/NIT | confirmed | PATH probe, lib extraction, e2e opt-in, flag matrix | applied |
| security | sec-1 | MAJOR | confirmed | key in argv via `-e KEY=val` | applied (pass by ref + redact) |
| security | sec-2 | MAJOR | confirmed | curl\|sh no integrity/consent | applied (print URL + consent; two-step where feasible) |
| security | sec-3 | MAJOR | confirmed | untrusted marketplaces auto-added | applied (print source + README note) |
| security | sec-4 | MAJOR | confirmed | secret files under default umask | applied (umask 077 / 0600) |
| security | sec-5 | MAJOR | advisory | dry-run/doctor may echo key | applied (redact + test) |
| security | sec-6/7/8 | MINOR/NIT | confirmed/advisory | sudo scope, path validation, --yes audit | applied / deferred (sec-7) |
| skeptic | skep-2 | BLOCKER | confirmed | partial failure leaves wedged state | applied (artifact-level guards + continue-on-error) |
| skeptic | skep-5 | BLOCKER | confirmed | ollama needs running daemon; e2e flaky | applied (explicit `ollama serve` + readiness; deterministic e2e) |
| skeptic | skep-1/3/7 | MAJOR | confirmed | safety reversal, claude CLI assumed, marketplace re-add | applied |
| skeptic | skep-4 | MAJOR | advisory | live-config mutation race / restart | applied (doctor fresh invocation + restart note) |
| skeptic | skep-6 | MAJOR | confirmed | alpine suite never covers execute path | applied (dry-run transcript = primary tested surface) |
| skeptic | skep-8 | MAJOR | advisory | is full rewrite necessary | rejected (explicit user ask) — minimal fixes folded in |
| skeptic | skep-9/10 | MINOR | confirmed | secret prompt under --yes, shell-rc PATH | applied |

_Metrics: confirmed blockers raised: 2 (both applied) · confirmed MAJORs: 12 (applied) · advisory: 4 · persona overlap: high on safety-reversal (arch-2≈skep-1) and coverage (arch-3≈skep-6) → clustered · round-2 skipped: every confirmed BLOCKER/MAJOR applied, no open blockers (per 03-propose-loop §f observability note)._

### Diff-review round 1 — findings on the implemented code + dispositions
| persona | id | severity | grounding | issue (short) | disposition |
|---------|----|----------|-----------|---------------|-------------|
| skeptic | skep-r7 | MAJOR | confirmed | stale `setup.sh --with-morph` in vault-guide.md (now a broken instruction) | applied (fixed guide; serena cmd too) |
| skeptic | skep-r2 | MAJOR | confirmed | `ensure_ollama_running` returns 0 even if daemon never came up | applied (returns 1 on poll exhaustion; install_ollama records fail, skips pull) |
| skeptic | skep-r4 | MAJOR | confirmed | e2e doctor assertion `*graphify*` tautological (matches ✓ or ✗) | applied (assert `✓] graphify` glyph) |
| architect | arch-r2 | MAJOR | confirmed | consent precedence `(read&&[y])||[Y]` fragile | applied (braces group the test) |
| skeptic/architect | skep-r1/arch-r3 | MAJOR | confirmed | e2e covers only uv+graphify; ollama/claude paths not e2e-proven | applied (coverage note in run.sh; dry-run covers construction) |
| architect | arch-r6/skep-r3 | MINOR | confirmed | background `ollama serve` not disowned / no failure surface | applied (disown + warn + return 1) |
| architect | arch-r8 | NIT | confirmed | bun apt_install unzip without apt guard on non-apt host | applied (guard apt_available+sudo_available) |
| architect | arch-r5 | MINOR | confirmed | obsidian detection `||/&&` precedence (pre-existing) | applied (braces) |
| skeptic | skep-r5 | MINOR | confirmed | unit doctor test weak (no row asserted) | applied (assert ✓uv / ✗ollama rows) |
| security | sec-r1/r2 | MINOR | confirmed | run_shell unredacted; redaction only KEY=val suffixes | applied note (guardrail comment); latent — no secret ships (Morph dropped) |
| architect | arch-r1 | MAJOR | advisory | dry-run vs real are separate branches | accepted: install COMMAND strings identical across arms (run/run_shell), only prechecks/verify differ — divergence bounded |
| architect | arch-r4 | MINOR | advisory | empty-array `${arr[@]}` under set -u on bash≤4.3 | deferred: target is Ubuntu (bash 5.2); patterns use `[*]`/`${#..[@]}` which are empty-safe |
| skeptic | skep-r6 | MINOR | advisory | real `claude` marketplace idempotency unverified (no claude in e2e) | deferred: documented coverage gap; stub-tested |

_Metrics: diff-review confirmed MAJORs: 5 (all applied) · MINOR/NIT applied: 5 · advisory deferred: 3 · security verdict: APPROVE_WITH_NITS (no live secret surface) · tests after fixes: 34 unit + 35 integration + 4 e2e green._

## Refs
<!-- session that executes this; ADR-005-installer-auto-exec -->
