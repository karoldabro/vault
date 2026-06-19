---
type: session
project: vault
date: 2026-06-19
topic: setup.sh sudo deadlock + non-programmatic plugin install fix
files_touched: [setup.sh, lib/installers.sh, tests/unit/setup-autoinstall.bats, README.md]
decisions: [refuse-sudo-invocation, accept-interactive-sudo]
continues: [[2026-06-18-1518-setup-auto-install]]
tags: [session, installer, sudo, onboarding, bugfix]
---

# setup.sh sudo deadlock + non-programmatic plugin install fix

## Goal
Fix the new Ubuntu auto-installer failing both ways a fresh user could run it (reported from a
real onboarding on another machine): `sudo ./setup.sh` strands everything in `/root`, and plain
`./setup.sh` installs nothing.

## Did
- Diagnosed the deadlock from [[setup.sh]] + [[lib/installers.sh]]:
  - `sudo ./setup.sh` → `$HOME=/root` → uv/bun/plugins/`ov.conf` land in root's home (invisible to
    the user); `claude` not on root's PATH → `claude_cli_ok` false → plugin auto-install skipped →
    user installed plugins by hand.
  - `./setup.sh` as the user → `sudo_available()` required **passwordless** sudo (`sudo -n true`),
    which a normal workstation user lacks → degraded to hint-only, printing `sudo apt …` hints that
    contradict the per-user model.
- Relaxed `sudo_available()` to also accept **interactive** sudo (`[ -t 0 ] || [ -t 1 ]`) so the
  per-user run reaches the auto path and prompts for the password at the apt/ollama steps.
- Added a **sudo footgun guard** in `setup.sh`: refuse when `$SUDO_USER` is set (override
  `VAULT_ALLOW_SUDO=1`); genuine container/CI root has no `$SUDO_USER`, so e2e is untouched.
- Pre-warm `sudo -v` once in the AUTO branch (single password prompt; skipped under dry-run/root/
  passwordless).
- Done-section messaging: reload shell (`exec $SHELL -l`) for PATH; clarify there is **no `ov`
  CLI** — OpenViking is the MCP plugin + ollama backend, health via `--doctor`.
- Added 3 offline tests to [[tests/unit/setup-autoinstall.bats]] (guard fires / override bypasses /
  `sudo_available` privilege model). Updated [[README.md]] install section.
- Offline suite green (37 unit + 35 integration = 72, 0 fail). Committed `98ac293`, pushed to main.

## Learned
- The plugin install was **already** programmatic (`install_openviking_plugin` /
  `install_claude_mem_plugin` run `claude plugin marketplace add` + `install --scope user`). It only
  appeared "manual" because `sudo` hid `claude` from root's PATH — the fix is the privilege model,
  not the plugin code.
- `$SUDO_USER` is the clean signal to distinguish a human `sudo` invocation (set) from genuine root
  in a container/CI (unset) — lets the guard fire for the footgun without breaking the e2e/root path.
- The whole installer is per-user by design: `_priv()` already scopes `sudo` to apt only. The right
  pattern is "run as yourself, escalate internally," not "wrap the installer in sudo."
- `ov: command not found` is expected — the stack ships no `ov` binary.

## Next
- Optional: pre-authenticate cleanup / consider `apt-get -o` quiet flags for the single-prompt UX.
- Verify on the affected ZenBook as `karinaveraldi`: `./setup.sh --full --yes` → `exec $SHELL -l`
  → `./setup.sh --doctor` all ✓.

## Refs
- [[../decisions/ADR-005-installer-auto-exec]]
- [[../indications/installer-dry-run-seam]]
- [[../indications/per-user-installer-no-sudo]]
- [[2026-06-18-1518-setup-auto-install]]
