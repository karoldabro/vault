---
type: decision
project: vault
id: ADR-005
status: accepted
scope: repo
tags: [adr, install, setup, onboarding, security]
---

# ADR-005 — setup.sh auto-installs the tool stack on Ubuntu (consent-gated)

## Context
The original `setup.sh` deliberately **never executed** network installs: it detected what was missing
and printed the command to run, to avoid surprise `curl | bash` and stay test-friendly (header comment,
old lines 18–20). In practice this meant "the installer doesn't install" — every tool (ollama,
OpenViking, Graphify, Serena, the Claude plugins/MCPs) was a manual copy-paste, and the printed hints
had drifted wrong (e.g. `/plugin install openviking` — the real plugin is
`claude-code-memory-plugin@openviking-plugin`). The goal is a smooth one-command install on Ubuntu.

The `/v-team` panel (architect + security + skeptic) flagged that reversing the no-auto-exec stance is a
real safety decision, not a refactor: it adds `curl|sh` supply-chain exposure, `sudo apt`, and
third-party Claude marketplace code execution.

## Decision
`setup.sh` **auto-installs** the stack on Ubuntu (apt + sudo present), **consent-gated**:

- **Consent** — interactive prompt before any side-effect, or `--yes` for non-interactive/CI. No TTY and
  no `--yes` → degrade to the old hint behaviour rather than hang.
- **Degrade, never halt** — no apt / no sudo (macOS, alpine, restricted hosts) → print the exact install
  commands (the prior behaviour). This is also why the offline alpine test image keeps exercising the
  hint path unchanged.
- **`run()` seam** — every network/privileged command goes through one wrapper; `--dry-run`
  (`VAULT_SETUP_DRY_RUN=1`) echoes instead of executing and is the primary tested surface.
- **Audit + secrets** — every remote URL / marketplace source is printed before it runs; `run()` redacts
  `*_KEY`/`*_TOKEN`/`*_SECRET` values; secret-bearing config files are `0600`.
- **Continue-on-error + doctor** — one tool failing never aborts the run; a `doctor` pass verifies what
  landed and owns the exit code (non-zero only if a required tool failed).

Morph Fast Apply was **dropped** from the installer (it needs a paid API key; out of scope).

## Consequences
- One-command install on Ubuntu (`./setup.sh --full --yes`); the same script stays safe on non-Ubuntu by
  degrading to hints.
- The execute path is covered offline via the dry-run transcript (`tests/unit/setup-autoinstall.bats`)
  and proven for real on an opt-in Ubuntu container (`tests/e2e/`, `VAULT_E2E=1 make test-e2e`).
- Per-tool installers live in `lib/installers.sh` (`install_<tool>`/`check_<tool>`); `setup.sh`
  orchestrates; `install.sh` (symlinks) is unchanged.
- Removing `--with-morph` is a clean break (no deprecation stub) — it is now an unknown flag.
- Supply-chain trust is explicit: the user consents to vendor `curl|sh` scripts and two third-party
  marketplaces (`Castor6/openviking-plugins`, `thedotmack/claude-mem`), printed for an audit trail.

### Follow-up (2026-06-19) — privilege model correction
Real-world onboarding exposed a deadlock: the installer is **per-user** (uv/bun/plugins/`ov.conf` in
`$HOME`), yet (a) the auto path was gated on *passwordless* sudo, so a normal user got hint-only, and
(b) running it under `sudo` flipped `$HOME` to `/root`, stranding every artifact and hiding `claude`.
Resolved (`98ac293`): run **as the user, escalate internally for apt only**, accept **interactive**
sudo (prompt at the escalation point), and **refuse a `sudo` invocation** (`$SUDO_USER` set; override
`VAULT_ALLOW_SUDO=1`) — genuine container/CI root (no `$SUDO_USER`) is unaffected. See
[[../indications/per-user-installer-no-sudo]] and [[../sessions/2026-06-19-0831-setup-sudo-deadlock-fix]].
