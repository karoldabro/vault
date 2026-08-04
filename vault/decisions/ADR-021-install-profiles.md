---
type: decision
project: vault
id: ADR-021
status: accepted
scope: repo
tags: [adr, install, setup, tooling, onboarding]
---

# ADR-021 — Serena and Graphify are developer tools; the installer asks which install you want

## Context
`setup.sh` already hid both tools behind `--with-serena` / `--with-graphify` / `--full`, so at the
script level nothing was forced. Everything around the script pushed `--full` anyway:

- `README.md` and `INSTALL.md` gave `./setup.sh --full --yes` as *the* command, and the flags table
  labelled `--full` "Recommended".
- `commands/v-setup.md` step 3 ran `--full --yes` unconditionally, so a plugin user who typed
  `/v-setup` got the developer stack whatever they intended.
- `scripts/detect-stack.sh` (the SessionStart hook) listed `graphify` and `serena` under "missing".
- `doctor()` printed both as plain rows, indistinguishable from a required tool.
- `tool-playbook.md` §3/§4 and `v-work` step 2 §2.4/§2.5 told the model to *surface* their absence and
  offer to install — right for a developer, noise for everyone else.

The cost is real: Graphify needs pipx and Python 3.10+ (which fails outright on Ubuntu 20.04 / older
WSL), Serena needs uv, and both pull vendor `curl | sh` installers. Someone using the vault for notes,
decisions and session history gets none of that back.

## Decision
Three named install profiles, chosen interactively when no flag is passed:

| Profile | Flag | Installs |
|---------|------|----------|
| Light (normal) — **default** | `--light` | claude-mem (bun + plugin) |
| Full (developer) | `--full` | claude-mem + Serena (uv) + Graphify (pipx) |
| Minimal | `--minimal` | nothing — scaffold + command links only |

Resolution order, first match wins:

1. An explicit `--light`/`--full`/`--minimal` or any `--with-*` flag **is** the answer — never
   overridden by the prompt or the light default. A hand-picked `--with-*` set counts as `full` only
   when both developer tools landed.
2. No flag, stdin is a terminal → prompt. Empty or unrecognised answer → light.
3. No flag, `--yes` → light. Consent was given; take the recommended profile.
4. No flag, no `--yes`, no terminal → **minimal**, plus a line naming the flags. ADR-005's line holds:
   nothing is ever installed unattended without consent. This is also what a `curl | bash` run gets.

`--minimal` still beats every profile and every `--with-*` flag.

The profile is recorded as `install_mode: light|full|minimal` in `~/vault/_global/config.md`, rewritten
on every run so switching profiles updates rather than duplicates it.

## Consequences
- **A light machine is not a broken machine.** This is the load-bearing consequence and drives four
  changes: `detect-stack.sh` no longer names graphify/serena at all; `doctor()` labels both rows
  `(developer)`; `tool-playbook.md` §3/§4 and the `v-work` §2.4/§2.5 + `v-do` tool notes now read
  `install_mode` before offering an install, and fall back to grep **silently** on light. Repeating
  "install Graphify" at someone who chose not to have it reports normality as a problem, which the
  communication contract ([[ADR-018-decision-communication-contract]]) forbids.
- Light users pay more tokens per structural question — grep instead of a graph query. That is the
  stated trade and it is in the docs table, not hidden.
- The interactive prompt is gated on `[ -t 0 ]`, not merely on `/dev/tty` existing: a piped or scripted
  run has a controlling terminal but nobody to answer, and must fall to rule 4 rather than hang. This
  is also what makes the path testable — `</dev/null` reliably reaches rule 4.
- Behaviour change for scripted callers: bare `setup.sh --yes` used to install nothing and now installs
  claude-mem. `--minimal` is the flag that still means nothing.
- Grounded in the standard three-tier profile model — rustup's `minimal`/`default`/`complete`, where
  the middle tier is what you get if you say nothing — rather than invented here.

Shipped with tests in `tests/unit/setup-autoinstall.bats` (profile resolution over the dry-run
transcript), `tests/integration/setup.bats` (`install_mode` recorded and updated) and
`tests/unit/plugin-install.bats` (the hook stays quiet about both tools).
