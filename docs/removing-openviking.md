---
type: process
tags: [process, install, removal]
---

# Removing OpenViking

This page takes OpenViking off a machine that still has it. The vault framework no longer depends on it
for semantic recall; `vault/decisions/ADR-019-drop-openviking-dependency.md` records why, and claude-mem
plus plain search over the vault markdown replaced it.

Nothing here touches your vaults, your repos, or the rest of the framework. OpenViking only ever held an
*index* built from your markdown, and the markdown itself is the source of truth.

## Run the remover

```bash
~/workspace/vault/bin/remove-openviking.sh --dry-run   # see exactly what would happen
~/workspace/vault/bin/remove-openviking.sh --all --yes # do all of it, including the indexed data
```

Run `--dry-run` first. It prints every command it would run and changes nothing, and that printout is
the step-by-step manual procedure. This page does not duplicate those commands, because the two copies
would drift apart.

| Flag | Effect |
|---|---|
| *(none)* | Service, config files, settings keys, plugin. Keeps the indexed data and the package. |
| `--config-dir D` | Also clean Claude config dir `D`. Repeatable. |
| `--tools` | Also `pipx uninstall openviking`. |
| `--purge-data` | Also deletes `~/.openviking` entirely, **including the index**. Irreversible. |
| `--all` | Both of the above. |
| `--dry-run` | Print the plan, change nothing. |
| `--yes` | Skip the confirmation prompt. |

Without `--yes` and with no terminal to confirm on, the script prints its plan and stops. It is safe to
run twice: every step reports "already absent" rather than failing.

Restart Claude Code afterwards so the plugin unloads.

## What gets removed

OpenViking installs four separate pieces, which is most of why it is awkward to set up:

1. **The server** — the `openviking` Python package, installed with pipx, providing `openviking-server`
   and the `ov` command.
2. **A background service** — a per-user systemd unit keeping that server alive on port 1933.
3. **Two config files** — `~/.openviking/ov.conf` for the server, and a separate client config at
   `~/.openviking/claude-code-memory-plugin/config.json` that the Claude Code plugin refuses to start
   without.
4. **The Claude Code plugin** — `claude-code-memory-plugin`, plus two environment keys in
   `~/.claude/settings.json` pointing at the config files above.

`~/.openviking/data` holds the indexed content itself. The script keeps it unless you pass
`--purge-data`.

**Failure mode: a second Claude config directory keeps the plugin loaded.** Point 4 repeats per Claude
config dir. A second home, such as `CLAUDE_CONFIG_DIR` set to `~/workspace/.claude-work/`, keeps its own
`settings.json` and its own plugin registry. Clean only `~/.claude` and that other home still loads the
plugin, whose `UserPromptSubmit` hook then fails on the config file point 3 just deleted:

```
[openviking-memory] Claude Code client config not found: ~/.openviking/claude-code-memory-plugin/config.json
```

The script cleans `$CLAUDE_CONFIG_DIR`, `~/.claude`, and every `--config-dir` you pass. It then reports
any other config dir under `$HOME` still mentioning OpenViking, so you can re-run against it.

## Remove ollama's embedding model too, if nothing else uses it

The framework used to install `ollama` and its `nomic-embed-text` model purely to generate embeddings
for OpenViking. The script removes neither, because ollama is generally useful and you may run something
else on it. The model is about 275 MB:

```bash
ollama rm nomic-embed-text
```

## Keeping OpenViking

Nothing stops you. The framework no longer reads from it and no longer installs it, so it becomes a tool
you maintain yourself. No vault command calls it.
