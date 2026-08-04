---
type: session
project: vault
date: 2026-08-04
topic: install profiles — light default, full for developers
files_touched: [setup.sh, lib/installers.sh, scripts/detect-stack.sh, tool-playbook.md, commands/v-setup.md, commands/v-work.md, commands/v-do.md, commands/v-work/steps/02-load-context.md, INSTALL.md, README.md, .claude-plugin/plugin.json, tests/unit/setup-autoinstall.bats, tests/integration/setup.bats, tests/unit/plugin-install.bats]
decisions: [ADR-021]
tags: [session, install, setup, tooling, onboarding]
---

# install profiles — light default, full for developers

## Goal
Make Serena and Graphify developer-only tools that are not installed by default, and have `setup.sh`
ask whether the user wants the full (developer) or light (normal) install.

## Did
- Added three named profiles to [[../../setup.sh]]: `--light` (claude-mem only, the default), `--full`
  (adds Serena + Graphify), `--minimal` (nothing). Per-tool `--with-*` flags kept as the escape hatch.
- Wrote the profile resolver: an explicit flag wins; no flag + terminal → prompt; no flag + `--yes` →
  light; no flag, no consent, no terminal → minimal plus a line naming the flags.
- Recorded the choice as `install_mode` in `~/vault/_global/config.md`, rewritten on every run so
  re-running with a different profile updates the value instead of appending a second one.
- Stopped four places from reporting a light machine as a broken one: `scripts/detect-stack.sh` no
  longer names either tool, `doctor()` labels both rows `(developer)` and prints the recorded install,
  and [[../../tool-playbook.md]] §3/§4 plus `v-work` §2.4/§2.5, `v-work.md` and `v-do.md` now read
  `install_mode` before offering an install.
- Rewrote the install docs: `INSTALL.md` gained a "Which install?" table with what each profile costs,
  the quick-start one-liner dropped `--full --yes`, and `/v-setup` now presents the three profiles
  instead of a yes/no on `--full`.
- Added 10 tests (profile resolution over the dry-run transcript, `install_mode` recorded and updated,
  the hook staying quiet about both tools). Suite: 318 pass.
- Bumped the plugin to 1.1.0 — Claude Code keys its cache on that string, so the change is invisible
  to plugin users without it.

## Learned
- The script was never the thing forcing the tools. `setup.sh` already hid both behind flags; what
  actually pushed `--full` on everyone was the docs one-liner, `/v-setup` running `--full` unprompted,
  and the SessionStart hook listing both as "missing". Fixing only the flags would have changed nothing.
- Gating the prompt on `/dev/tty` being readable is not enough: a `curl | bash` or piped run has a
  controlling terminal but nobody to answer, so it would hang. `[ -t 0 ]` is the right gate, and it is
  also what makes the path testable — `</dev/null` reliably reaches the no-consent branch.
- Verifying an interactive prompt needs a real pty; `printf '2\n' | setup.sh` exercises the *scripted*
  path, not the prompt. `script -qec "<cmd>" /dev/null` with the answer on stdin drives the real one.
- Reporting a deliberately-absent tool as missing is the same defect the communication contract names:
  it reports normality as a problem. Demoting a tool means auditing every place that expected it.

## Behaviors & rules
- No profile flag and stdin is a terminal → prompt; an empty or unrecognised answer resolves to light.
- No profile flag with `--yes` → light; edge: with no `--yes` and no terminal → minimal, and nothing is
  installed.
- Any explicit `--with-*` flag → that exact set installs, never widened by the light default; edge:
  `--with-serena --with-graphify` with no profile flag records `install_mode: full`.
- `--minimal` beats every profile flag and every `--with-*` flag.
- Re-running with a different profile → `install_mode` is updated in place; edge: the file always holds
  exactly one `install_mode:` line.
- `graphify-out/graph.json` missing and `install_mode` is light or minimal → fall back to grep without
  telling the user; edge: on `full` the per-repo hook is genuinely absent, so offer to install it.

## Next
- The e2e Ubuntu container (`VAULT_E2E=1 make test-e2e`) still exercises `--full`; a light-profile e2e
  case would cover the new default on a real box. Not run this session.
- Four files unrelated to this work are still uncommitted in the tree: `bin/remove-openviking.sh`,
  `docs/removing-openviking.md`, `docs/vault-intro-deck.html`,
  `tests/integration/remove-openviking.bats`, plus an untracked
  `vault/plans/2026-08-04-vault-git-autosync.md`.

## Refs
- [[../decisions/ADR-021-install-profiles]]
- [[../decisions/ADR-005-installer-auto-exec]]
- [[../decisions/ADR-018-decision-communication-contract]]
- [[../decisions/ADR-020-claude-code-plugin-distribution]]
- [[../plans/2026-08-04-install-profiles-light-full]]
- [[2026-08-04-1225-claude-code-plugin-install]]
