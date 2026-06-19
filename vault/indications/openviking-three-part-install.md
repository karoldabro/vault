---
type: indication
project: vault
slug: openviking-three-part-install
scope: repo
tags: [indication]
---

# openviking-three-part-install

## Rule
Provisioning OpenViking means installing **three** parts, not just the Claude Code plugin. The
installer must set up all of them or the MCP fails with "Connection closed":
1. **Server** — `pipx install openviking` (`openviking-server` + the `ov` CLI), running on :1933
   (via a systemd `--user` unit).
2. **Server config** — valid JSON `~/.openviking/ov.conf` (`server.host/port`, `storage`,
   `embedding`). The old `workspace = …` 3-line format is unparseable; rewrite it.
3. **Plugin client config** — `~/.openviking/claude-code-memory-plugin/config.json` with at least
   `{ "mode": "local" }`. The MCP server **requires** this file; its absence makes the plugin exit.

## Rationale
The MCP plugin only talks to a local OV server; it does not embed one. Installing the plugin alone
leaves nothing on :1933 and no client config, so the stdio server exits before the MCP handshake and
Claude Code shows the opaque `MCP error -32000: Connection closed`. Run the plugin's
`scripts/start-memory-server.mjs` by hand to see the real error.

## Examples
- Do: `setup.sh --with-ov` → pipx-installs `openviking`, writes JSON `ov.conf` + client `config.json`
  + the `openviking.service` unit, then `systemctl --user enable --now openviking.service`.
- Don't: install `claude-code-memory-plugin` and assume OV works — there is no server and no client
  config yet.
- Note: `ov` is a real CLI from the `openviking` package; `ov: command not found` means the server
  package isn't installed, not that the command doesn't exist.

## Applies-to
`setup.sh`, `lib/installers.sh` (`install_openviking_server`, `ov_enable_service`), `~/.openviking/**`
