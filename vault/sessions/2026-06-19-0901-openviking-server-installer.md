---
type: session
project: vault
date: 2026-06-19
topic: setup.sh installs the OpenViking server + configs, not just the plugin
files_touched: [setup.sh, lib/installers.sh, tests/integration/setup.bats, tests/unit/setup-autoinstall.bats, README.md]
decisions: [installer-provisions-ov-server, ov-conf-json-format]
continues: [[2026-06-19-0831-setup-sudo-deadlock-fix]]
tags: [session, installer, openviking, mcp, bugfix]
---

# setup.sh installs the OpenViking server + configs, not just the plugin

## Goal
Debug why the OpenViking MCP shows "Connection closed" on a freshly-onboarded machine and make
`setup.sh` provision OpenViking end-to-end (server + configs + service), not just the plugin.

## Did
- Live-debugged the ZenBook from this dev machine. Ran the plugin's MCP server by hand
  (`CLAUDE_PLUGIN_ROOT=… node scripts/start-memory-server.mjs`) to surface the real error the UI hides
  behind `MCP error -32000: Connection closed`:
  `Claude Code client config not found: ~/.openviking/claude-code-memory-plugin/config.json`.
- Traced the plugin runtime ([[lib/installers.sh]]-adjacent plugin source): the MCP starts a node
  runtime via `npm ci` into `~/.openviking/claude-code-memory-plugin/runtime/`, then reads a **client
  config** (`config.json`, `{ "mode": "local" }`) and connects to the **OV server** at
  `127.0.0.1:${port}` using `port`/`root_api_key` from `~/.openviking/ov.conf`.
- Found the OV **server** here is the `openviking` pipx package (`openviking-server` + `ov` CLI, 0.3.16)
  run by a systemd `--user` unit `openviking.service`. `setup.sh` installed **none** of that — only
  ollama + the plugin + a malformed 3-line `ov.conf`. So OV had never worked from a clean install.
- Rewrote the `--with-ov` step in [[setup.sh]]: write valid **JSON** `ov.conf` (rewrites the stale
  3-line format), write the plugin **client `config.json`**, write a systemd `--user` unit; then
  `tool_try openviking-server install_openviking_server`.
- Added `install_openviking_server` + `ov_enable_service` to [[lib/installers.sh]] (`pipx install
  openviking` → enable `--now` the service on :1933; degrades to a detached server where there's no
  user systemd; `loginctl enable-linger` is best-effort with a sudo hint). Doctor gains rows for the
  server binary, a `:1933 /health` curl probe, and the client config.
- Tests: integration asserts JSON `ov.conf` + client config + service unit + stale-conf rewrite; unit
  asserts the new dry-run transcript lines (`pipx install openviking`, `systemctl --user enable …`).
  Offline suite green (38 unit + 36 integration = 73, 0 fail). Committed `90cdbe9`, pushed to main.

## Learned
- **OpenViking is three parts**, all required for the MCP to connect: (1) the `openviking` server
  (pipx) on :1933, (2) a JSON `ov.conf` the server parses, (3) the plugin **client config**
  `~/.openviking/claude-code-memory-plugin/config.json` (`{ "mode": "local" }`). Missing #3 = the
  plugin process exits → "Connection closed".
- I was wrong earlier: **`ov` IS a real CLI** — it ships with the `openviking` pipx package; it just
  wasn't in the vault installer. `ov: command not found` on the ZenBook meant the server was never
  installed, not that no such command exists.
- The opaque "MCP error -32000: Connection closed" is just "the stdio server exited before handshake."
  Running the server's start script by hand prints the real cause — the fastest MCP-debug move.
- `~/.openviking/ov.conf` (server) and `…/claude-code-memory-plugin/config.json` (plugin client) are
  **different files**; in local mode `ov.conf` is read *optionally* for port/key.

## Next
- Confirm on the ZenBook: `git pull && ./setup.sh --full --yes` → `exec $SHELL -l` →
  `./setup.sh --doctor` shows OV server (:1933) + client config ✓; MCP reconnects.
- `sudo loginctl enable-linger karinaveraldi` once so the service survives logout (installer can't do
  this without root).

## Refs
- [[../decisions/ADR-005-installer-auto-exec]]
- [[../indications/openviking-three-part-install]]
- [[../indications/per-user-installer-no-sudo]]
- [[2026-06-19-0831-setup-sudo-deadlock-fix]]
