---
type: session
project: vault
date: 2026-06-19
topic: settings.json env for OV plugin + vault-uninstall.sh
files_touched: [setup.sh, lib/installers.sh, bin/vault-uninstall.sh, tests/integration/setup.bats, tests/integration/vault-uninstall.bats, README.md]
decisions: [settings-env-non-clobber, uninstall-layered-consent]
continues: [[2026-06-19-0901-openviking-server-installer]]
tags: [session, installer, openviking, mcp, uninstall]
---

# settings.json env for OV plugin + vault-uninstall.sh

## Goal
Close the last OpenViking onboarding gap (the plugin's `.mcp.json` env placeholders) in `setup.sh`,
and add a safe `vault-uninstall.sh` that reverses the installer.

## Did
- Diagnosed the final ZenBook failure (server alive, MCP still "Connection closed"): the stock plugin
  `.mcp.json` passes `${OPENVIKING_CC_CONFIG_FILE}` / `${OPENVIKING_CONFIG_FILE}` as env; when those
  vars are unset, Claude injects the **literal** `${VAR}` as a path → server can't find the file →
  exits. By-hand it worked (vars unset → default path); only the Claude-launched MCP failed →
  env-injection problem, not config. (This dev machine works because its `.mcp.json` was hand-edited.)
- Confirmed the fix with the user: set the two keys in `~/.claude/settings.json` `env` → placeholders
  resolve → MCP green.
- Added `ov_set_env_key` to [[lib/installers.sh]] and called it from the `--with-ov` step in
  [[setup.sh]]. **Non-clobbering + self-healing**: add when absent; keep a present value whose file
  exists (deliberate override); rewrite only a value whose file is missing (stale). Other env keys
  untouched. Uses `jq` (a guaranteed base prereq).
- Wrote [[bin/vault-uninstall.sh]] — reverses `setup.sh`/`install.sh` in **safety layers**. Default
  (consent-gated) removes only reversible wiring: command symlinks pointing into this repo, the OV
  `--user` service, `ov.conf` + plugin client config, the two `settings.json` env keys, and the
  OV/claude-mem plugins. Opt-in: `--tools` (openviking/graphifyy/serena-agent; never
  ollama/uv/bun/node), `--purge-data` (`~/.openviking` + `_global`), `--all`. No `--yes` and no TTY →
  prints the plan, changes nothing. Sources `lib/installers.sh` for the `run()`/dry-run + consent seam.
- Tests: +3 integration (env set / preserved+idempotent / user-override kept) and a new
  [[tests/integration/vault-uninstall.bats]] (11 cases). Offline suite green (37 unit + 50
  integration = 87, 0 fail). Committed `cf3b13e`, pushed to main.

## Learned
- OpenViking is effectively a **four-part** install: server + `ov.conf` + plugin client `config.json`
  + the `settings.json` env that makes the plugin's `.mcp.json` placeholders resolve. Missing the env
  is indistinguishable (in the UI) from missing the client config — both surface as "Connection closed".
- Claude Code injects `${VAR}` from `.mcp.json` env **literally** when the var is unset (it does not
  drop to empty/default). So a plugin that ships placeholder env requires those vars to be provided —
  `settings.json` `env` is the clean place.
- An installer that edits a user-owned JSON file should be **non-clobbering + self-healing**: only set
  absent or provably-stale values; keep valid user overrides. `jq` makes this a safe merge.
- For the uninstaller, reusing `setup.sh`'s `VAULT_SETUP_DRY_RUN` seam doubles as the "no consent →
  just print the plan" path — one mechanism for both preview and dry-run.

## Next
- ZenBook is fully working now. A clean `git pull && ./setup.sh --full --yes` should reproduce it end
  to end (server + all configs + settings env + plugins).

## Refs
- [[../decisions/ADR-005-installer-auto-exec]]
- [[../indications/openviking-three-part-install]]
- [[../indications/per-user-installer-no-sudo]]
- [[2026-06-19-0901-openviking-server-installer]]
