---
type: decision
project: vault
id: ADR-021
status: accepted
scope: repo
tags: [adr, install, setup, tooling, onboarding]
---

# ADR-021 — Serena is a developer tool; the installer asks which install you want

## Context
`setup.sh` hid Serena behind `--with-serena` / `--full`, so at the script level nothing was forced.
Everything around the script pushed `--full` anyway:

- `README.md` and `INSTALL.md` gave `./setup.sh --full --yes` as *the* command, and the flags table
  labelled `--full` "Recommended".
- `commands/v-setup.md` step 3 ran `--full --yes` unconditionally, so a plugin user who typed
  `/v-setup` got the developer stack whatever they intended.
- `scripts/detect-stack.sh` (the SessionStart hook) listed `serena` under "missing".
- `doctor()` printed Serena as a plain row, indistinguishable from a required tool.
- `tool-playbook.md` §3/§4 and `v-work` step 2 §2.4/§2.5 told the model to *surface* its absence and
  offer to install — right for a developer, noise for everyone else.

The cost is real: Serena needs uv, which is a vendor `curl | sh` installer. Someone using the vault for
notes, decisions and session history gets nothing back for it.

## Decision
Two named install profiles, chosen interactively when no flag is passed:

| Profile | Flag | Installs |
|---------|------|----------|
| Light (normal) — **default** | `--light` | no optional tools — scaffold + command links only |
| Full (developer) | `--full` | Serena (uv) |

Resolution order, first match wins:

1. An explicit `--light`/`--full` or `--with-serena` flag **is** the answer — never overridden by the
   prompt or the light default. A hand-picked `--with-serena` records `full`, since Serena is the one
   developer tool.
2. No flag, stdin is a terminal → prompt. Empty or unrecognised answer → light.
3. No flag, `--yes` or no terminal → light. Light installs no tool, so ADR-005's line holds: nothing is
   ever installed unattended without consent. This is also what a `curl | bash` run gets.

The profile is recorded as `install_mode: light|full` in `~/vault/_global/config.md`, rewritten on
every run so switching profiles updates rather than duplicates it. Every reader treats any value
other than `full` as "no developer tools".

## Consequences
- **A light machine is not a broken machine.** This is the load-bearing consequence and drives four
  changes: `detect-stack.sh` does not name serena at all; `doctor()` labels its row `(developer)`;
  `tool-playbook.md` §3/§4 and the `v-work` §2.4/§2.5 + `v-do` tool notes read `install_mode` before
  offering an install, and fall back to grep and Read **silently** on light. Repeating "install
  Serena" at someone who chose not to have it reports normality as a problem, which the communication
  contract ([[ADR-018-decision-communication-contract]]) forbids.
- Light users pay more tokens per symbol question — grep and Read instead of a Serena symbol lookup.
  That is the stated trade and it is in the docs table, not hidden.
- The interactive prompt is gated on `[ -t 0 ]`, not merely on `/dev/tty` existing: a piped or scripted
  run has a controlling terminal but nobody to answer, and must fall to rule 3 rather than hang. This
  is also what makes the path testable — `</dev/null` reliably reaches rule 3.

Tests: `tests/unit/setup-autoinstall.bats` (profile resolution over the dry-run transcript),
`tests/integration/setup.bats` (`install_mode` recorded and updated) and
`tests/unit/plugin-install.bats` (the hook stays quiet about Serena).
