---
type: session
project: vault
date: 2026-06-18
topic: setup-auto-install
files_touched: [setup.sh, lib/installers.sh, Makefile, README.md, vault-guide.md, VAULT.md, tests/unit/setup-autoinstall.bats, tests/e2e/run.sh, tests/e2e/Dockerfile.ubuntu, tests/e2e/autoinstall.bats, vault/decisions/ADR-005-installer-auto-exec.md, vault/plans/2026-06-18-1518-setup-auto-install.md]
decisions: [ADR-005]
tags: [session, install, setup, onboarding, v-team]
---

# setup-auto-install

## Goal
Turn `setup.sh` from a "detect-and-print-a-hint" advisor into a real, consent-gated Ubuntu
auto-installer + onboarder for the whole tool stack, run via `/v-team`.

## Did
- Ran `/v-team`: ANALYZE → LOAD CONTEXT → PROPOSE panel (generic Software-Architect + security + skeptic,
  no stack pack resolves for a bash repo) → approval gate → EXECUTE with a diff-review panel.
- Grounded every tool's install command against its GitHub/official source (researcher agent). Corrected
  the repo's wrong hints: OV plugin is `claude-code-memory-plugin@openviking-plugin` (not `openviking`),
  serena is `uv tool install -p 3.13 serena-agent`, morph is `@morphllm/morphmcp`, bun is `bun.com` + needs `unzip`.
- Extracted per-tool `install_<tool>`/`check_<tool>` into [[../../lib/installers.sh]] behind a `run()`
  dry-run seam (`VAULT_SETUP_DRY_RUN=1` / `--dry-run`) with secret redaction + continue-on-error; doctor
  pass owns the exit code.
- Rewrote [[../../setup.sh]]: Ubuntu (apt+sudo) auto-installs ollama+nomic / uv+Serena / bun+claude-mem /
  pipx+Graphify + the OV & claude-mem Claude plugins via the scriptable `claude` CLI; consent prompt or
  `--yes`; degrades to hints on non-apt; added `--dry-run`/`--doctor`; dropped Morph (`--with-morph` removed).
- Tests: new offline dry-run unit suite `tests/unit/setup-autoinstall.bats` (16 tests — transcript,
  redaction, sudo-scoping, idempotency, degrade, partial-failure) + an opt-in real-Ubuntu e2e harness
  `tests/e2e/` (`VAULT_E2E=1 make test-e2e`) that **actually installs uv+graphify**. Makefile keeps e2e
  off the default PR path.
- Diff-review round fixed: stale `--with-morph` in `vault-guide.md`, `ensure_ollama_running` now signals
  daemon-start failure (return 1 + disown), tautological e2e assert → `✓] graphify` glyph, consent
  precedence braces, e2e coverage-gap note. Wrote [[../decisions/ADR-005-installer-auto-exec]].
- All green: 34 unit + 35 integration + 4 e2e. Commits `922fd18` (feat) + `2f4ffa8` (docs) on
  `feat/setup-auto-install`.

## Learned
- The `claude` CLI is scriptable: `claude plugin marketplace add <repo>`, `claude plugin install
  <id>@<marketplace> --scope user`, `claude mcp add` — so Claude plugins/MCPs CAN be installed from a
  shell script (the previous "manual `/plugin install`" hint was unnecessary). Real marketplace sources:
  OV = `Castor6/openviking-plugins`, claude-mem = `thedotmack/claude-mem`.
- Test-harness tension: the offline bats image is **alpine, read-only mount, no network/sudo**. Solution
  was a `run()` dry-run seam (offline-testable transcript) + a **separate** Ubuntu e2e runner with
  `--network`/root — the offline `tests/run.sh` cannot host real installs. The alpine suite naturally
  exercises the hint path (no apt), so existing tests stayed green unchanged.
- Under `set -euo pipefail`, set -e is suspended inside a function called as a condition (`if fn` /
  `tool_try`), so per-tool continue-on-error works; install fns still use explicit `|| return 1` for
  clarity. `run $(_priv) apt-get` is safe — empty `$(_priv)` as root is dropped by word-splitting.
- ollama's installer needs a running daemon for `ollama pull`; in a container (no systemd) you must
  `ollama serve &` + poll readiness, and treat an unreachable daemon as a recorded failure, not a skip.

## Next
- e2e does **not** cover the ollama daemon path or real `claude` plugin/marketplace idempotency (no
  `claude` in the image, model pull too heavy) — covered only at dry-run construction level. A heavier
  opt-in e2e tier could close this if it matters.
- Push the branch / open a PR when ready (not pushed this session).
- Latent: `_redact_args` only catches `KEY=val` suffixes — fine while no secret ships (Morph dropped);
  revisit if a keyed installer returns.

## Continuation 2026-06-18-1600 — onboarding model
- **Dropped** the global `~/.claude/CLAUDE.md` snippet from `setup.sh` — it was stale and the installer
  shouldn't author user-owned global config. Framework path now lives only in `$VAULT_FRAMEWORK_PATH` +
  `~/vault/_global/config.md`. setup.sh instead prints a per-repo onboarding instruction (run
  `bin/vault-init.sh` / `/v-init` in the repo) and an optional `export VAULT_FRAMEWORK_PATH=…` line.
- **Portability fix** in `bin/vault-init.sh`: committed per-repo files (code-repo `CLAUDE.md`, in-repo
  `_moc.md` Start Here) now write the **literal** `$VAULT_FRAMEWORK_PATH/vault-guide.md` instead of the
  resolved absolute path — so a shared repo's pointer resolves per-user, not to one dev's install dir.
- Decision: install stays machine-level; onboarding stays an explicit per-folder step (user's call).
- Updated `tests/integration/setup.bats` (onboarding-instruction + "don't touch global CLAUDE.md");
  removed now-dead `CLAUDE_HOME` from setup.sh. All green: 34 unit + 35 integration.

## Continuation 2026-06-18-1620 — README completeness
- Audited README vs the implementation; closed gaps: documented the two test tiers (offline unit+integration
  default vs opt-in real-Ubuntu e2e behind `VAULT_E2E=1`), listed all 10 shipped commands (was 2 — `/v-team`,
  `/v-init`, etc. missing), refreshed the Contents tree (`personas/`, `commands/`, `tests/e2e/`).
- Added a **"Vault location & `VAULT.md`"** section: two-path resolution (framework path via
  `$VAULT_FRAMEWORK_PATH` + `~/vault/_global/config.md`; vault path via `VAULT.md` → config.md → default),
  the portability rule, and the `VAULT.md` config/structure/behaviour/personas key table.
- Confirmed no stale legacy in README (`--with-morph`, "never auto-executed", "paste this snippet" all gone).
- Merged `feat/setup-auto-install` → `main` and pushed.

## Refs
- [[../decisions/ADR-005-installer-auto-exec]]
- [[../plans/2026-06-18-1518-setup-auto-install]]
- [[../indications/installer-dry-run-seam]]
- [[2026-06-16-1038-v-team-persona-critique-command]]
