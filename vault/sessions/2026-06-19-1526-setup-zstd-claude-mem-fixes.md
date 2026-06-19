---
type: session
project: vault
date: 2026-06-19
topic: setup-zstd-claude-mem-fixes
files_touched: [lib/installers.sh, tests/unit/setup-autoinstall.bats]
decisions: []
tags: [session, setup, installer, ollama, claude-mem]
continues: [[2026-06-18-1518-setup-auto-install]]
---

# setup-zstd-claude-mem-fixes

## Goal
Fix two fresh-install failures observed on a clean Ubuntu host: ollama failing for lack of `zstd`, and the claude-mem plugin install using the wrong marketplace qualifier.

## Did
- Added `ensure_zstd()` to [[../../lib/installers.sh]], called from `install_ollama` (both dry-run and real branches) before the remote installer runs. apt hosts install `zstd`; non-apt degrades to a warn (never fatal).
- Fixed `install_claude_mem_plugin` qualifier: `claude-mem@claude-mem` → `claude-mem@thedotmack`. Verified against the repo's `.claude-plugin/marketplace.json` (`name: thedotmack`, plugin `claude-mem`).
- Updated [[../../tests/unit/setup-autoinstall.bats]]: corrected the masking stub (`plugin list`/`marketplace` now emit `thedotmack`), added a dry-run assertion for `claude plugin install claude-mem@thedotmack`, and two `ensure_zstd` tests (installs when absent, no-op when present).
- Full suite green: 99 unit + 50 integration, 0 failures (dockerized).
- Committed `cb781ed` (only the two files; left in-progress v-cr sandbox changes untouched).

## Learned
- ollama's `install.sh` now extracts a **zstd-compressed** tarball and hard-fails without the `zstd` binary — a new runtime prereq not covered by the generic base-prereq apt step (which is gated on git/curl/jq).
- A Claude Code plugin's qualified id is `<plugin-name>@<marketplace-name>`, where marketplace-name is the `name` field in `marketplace.json` — **not** the repo owner or path. For `thedotmack/claude-mem` that resolves to `claude-mem@thedotmack`.
- The old unit-test stub returned `claude-mem@claude-mem`, so the grep-key idempotency check still matched and the bug stayed invisible until a real fresh install (confirmed by obs 14723).
- The `ensure_zstd` test had to override `have`/`_priv` in the subshell because the docker test image already ships `zstd` (short-circuited the apt path) and runs non-root (sudo prefix would miss the stub).

## Next
- None blocking. Consider a doctor row for `zstd` if more vendor installers adopt zstd tarballs.

## Refs
- [[installer-dry-run-seam]]
- [[verify-plugin-marketplace-qualifier]]
- [[2026-06-18-1518-setup-auto-install]]
