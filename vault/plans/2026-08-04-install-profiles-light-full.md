---
type: plan
project: vault
status: executed
date: 2026-08-04
tags: [plan, install, setup, tooling]
---

# Plan — install profiles: light (normal) default, full (developer) opt-in

## Task

Make Serena a developer-only tool that is **not** installed by default. `setup.sh`
should ask the user which install they want: full (developer) or light (normal).

## Current state

- `setup.sh` already gates Serena behind `--with-serena` / `--full`. With **no**
  flags it installs nothing and asks nothing — so "default installs it" is false at the script
  level, but everything *around* the script pushes `--full`:
  - `INSTALL.md` flags table: `--full` … "Recommended."
  - `INSTALL.md` quick-start one-liner is `./setup.sh --full --yes`.
  - `commands/v-setup.md` Step 3 runs `--full --yes` unconditionally.
  - `scripts/detect-stack.sh` (SessionStart hook) reports missing `serena`.
  - `doctor()` prints it as a plain row, indistinguishable from required tools.
  - `tool-playbook.md` §3/§4 and `commands/v-work/steps/02-load-context.md` §2.4/§2.5 instruct the
    model to *surface* its absence and offer to install — correct for a developer, noise for a
    normal user.
- There is no interactive mode choice anywhere, and no record of which profile the machine chose.

## Research (§3a.0b)

Named install profiles with a recommended middle default are the established pattern; the community
consensus is that the *standard* profile is the non-interactive default, with an explicit flag or env
var to select minimal or full.

- [rustup — Profiles](https://rust-lang.github.io/rustup/concepts/profiles.html) — canonical
  three-tier model (`minimal` / `default` / `complete`); `default` is what you get if you say nothing.
- [affinity-cli](https://github.com/ind4skylivey/affinity-cli) — profile selectable interactively or
  non-interactively via flag/env var, so automation never has to answer a prompt.

No contradicting consensus. The design below is the rustup shape with our three tiers renamed to the
words the user asked for (light / full), plus `--minimal` kept as the existing bare-scaffold tier.

## Design

### Profiles

| Profile | Flag | Installs |
|---------|------|----------|
| Light (normal) — **default** | `--light` | the default tools |
| Full (developer) | `--full` | the default tools + Serena (uv) |
| Minimal | `--minimal` | nothing — scaffold + command links only |

Per-tool flags (`--with-serena`) stay as the escape hatch and
keep beating profile selection. `--minimal` keeps beating everything (existing test asserts this).

### Selection rules

1. Any explicit profile or tool flag → that is the answer, no prompt.
2. No flag + TTY → prompt:
   ```
   Which install?
     [1] Light (normal)     Recommended.
     [2] Full (developer)   adds Serena (uv).
     [3] Minimal            framework only, no tools.
   Choice [1]:
   ```
   Empty answer or anything unrecognised → light.
3. No flag + `--yes` (consent given, no TTY answer) → **light**.
4. No flag, no `--yes`, no TTY → **minimal**, plus one line naming the flags. ADR-005's rule holds:
   never install unattended without consent.

The existing auto-vs-hint consent prompt (vendor `curl|sh` + marketplace) is unchanged and still runs
after the profile is chosen, whenever the chosen profile installs anything.

### Record the choice

`setup.sh` writes `install_mode: light|full|minimal` into `~/vault/_global/config.md` under `## config`
and updates it on re-run. This is what lets the commands stop nagging: a light machine is not a broken
machine.

### Stop reporting the dev tools as gaps

- `scripts/detect-stack.sh` — drop `serena` from `missing[]` entirely. The hook then only
  reports a missing machine layer, which is the one real gap.
- `doctor()` — label the row `serena (developer)` so a light install does
  not read as failing. It was never required for the exit code; only the label changes.
- `tool-playbook.md` §3 + §4 — "surface it and offer to install" becomes conditional:
  offer it on a full install; on a light install fall back to grep/Glob without commentary.
- `commands/v-work/steps/02-load-context.md` §2.4/§2.5 and `commands/v-do.md` — same softening, one
  line each.

### Docs

- `INSTALL.md` — quick-start one-liner becomes `./setup.sh --yes` (light); flags table gains `--light`
  and moves "Recommended" onto it; `--full` reworded as the developer profile; add a short
  "Which install?" section naming what each profile buys.
- `README.md` — the tool-playbook bullet notes Serena is a developer-profile tool.
- `commands/v-setup.md` — Step 2's gate presents the two profiles instead of a yes/no on `--full`;
  Step 3 runs the chosen profile; front-matter `argument-hint` gains `--light`.

## Implementation steps

1. `setup.sh` — add `light` profile var + `--light` flag; rewrite the profile-resolution block
   (currently lines 45–120) to the four selection rules; add the prompt. Tool: Edit.
2. `setup.sh` — write `install_mode` into `config.md` (Step 2 block), including on re-run when the
   file already exists. Tool: Edit.
3. `lib/installers.sh` — relabel the `_doctor_row` call. Tool: Edit.
4. `scripts/detect-stack.sh` — remove the serena block. Tool: Edit.
5. `tool-playbook.md`, `commands/v-work/steps/02-load-context.md`, `commands/v-do.md` — soften the
   missing-tool instructions. Tool: Edit.
6. `commands/v-setup.md` — profile gate. Tool: Edit.
7. `INSTALL.md`, `README.md` — docs. Tool: Edit.
8. Tests (below). Tool: Edit/Write.
9. `.claude-plugin/plugin.json` — version bump (publishing requires it).

## Test plan

`tests/unit/setup-autoinstall.bats` (dry-run transcript — the primary seam):

- `--light --dry-run` emits **no** `uv tool install serena-agent`.
- `--full --dry-run` still emits it (existing test, must stay green).
- bare `--yes` with a fake PATH resolves to the light profile.
- no flags, stdin closed, no `--yes` → nothing installed (minimal), and the flag hint is printed.
- prompt: no flags with `2` on stdin → full profile; empty line → light. (Reuses the existing
  `</dev/null` / stdin pattern at `setup-autoinstall.bats:274`.)

`tests/integration/setup.bats`:

- `--minimal` still beats `--light` and every `--with-*` flag.
- `config.md` contains `install_mode: light` after `--light --yes`, and flips to `full` after a
  subsequent `--full --yes` (idempotent re-run updates rather than duplicates).

`tests/unit/plugin-install.bats`:

- `scripts/detect-stack.sh` no longer mentions serena.

Fault named per happy path: the profile resolver's failure mode is a flag silently losing to the
prompt — covered by rule 1 having its own case for both `--full` and `--with-serena`.

## Vault writes

Dedupe: grepped `vault/` for `install_mode`, `light mode`, `developer mode`, `install profile` — no
matches. Nothing to update; both are new.

- CREATE `vault/decisions/ADR-021-install-profiles.md` — light default, full for developers, plus the
  "a light machine is not a broken machine" consequence for the tool-playbook nags.
- UPDATE `vault/decisions/_inventory.md` — one row.
- CREATE the session doc at capture time (`/v-capture`).
