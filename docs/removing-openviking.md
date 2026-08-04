---
type: process
tags: [process, install, removal]
---

# Removing OpenViking

The vault framework used to depend on OpenViking for semantic recall over your vault. It no longer
does. If you installed it before that change, this page takes it off your machine.

Nothing here touches your vaults, your repos, or the rest of the framework. OpenViking only ever held
an *index* built from your markdown — the markdown itself is the source of truth and is untouched.

## Why it was dropped

Measured across 27 projects over 60 days, OpenViking was written to 194 times and read from 17 times.
Four percent of its traffic was the part that provided value, against 38 logged connection failures.
It cost a four-part install to run and was, in practice, a write-only store.

What replaced it: **claude-mem** for project history, and plain search over the vault markdown. Both
were already documented as the fallback path in every command.

## What gets removed

OpenViking installed four separate pieces, which is most of why it was awkward to set up:

1. **The server** — the `openviking` Python package, installed with pipx, providing
   `openviking-server` and the `ov` command.
2. **A background service** — a per-user systemd unit keeping that server alive on port 1933.
3. **Two config files** — `~/.openviking/ov.conf` for the server, and a separate client config at
   `~/.openviking/claude-code-memory-plugin/config.json` that the Claude Code plugin refused to start
   without.
4. **The Claude Code plugin** — `claude-code-memory-plugin`, plus two environment keys in
   `~/.claude/settings.json` pointing at the config files above.

Point 4 repeats per Claude config dir. A second Claude home — `CLAUDE_CONFIG_DIR` pointing at
something like `~/workspace/.claude-work/` — keeps its own `settings.json` and its own plugin
registry. Clean only `~/.claude` and that other home still loads the plugin, whose
`UserPromptSubmit` hook then fails on the config file point 3 just deleted:

```
[openviking-memory] Claude Code client config not found: ~/.openviking/claude-code-memory-plugin/config.json
```

The script cleans `$CLAUDE_CONFIG_DIR`, `~/.claude`, and every `--config-dir` you pass, then reports
any other config dir under `$HOME` still mentioning OpenViking so you can re-run against it.

There is also `~/.openviking/data`, the indexed content itself. That is kept unless you ask for it to
go.

## Doing it

```bash
~/workspace/vault/bin/remove-openviking.sh --dry-run   # see exactly what would happen
~/workspace/vault/bin/remove-openviking.sh --all --yes # do all of it, including the indexed data
```

Run `--dry-run` first. It prints every command it would run and changes nothing — that printout *is*
the step-by-step manual procedure, which is why it isn't duplicated here. Copying the commands into
this page would only let the two drift apart.

| Flag | Effect |
|---|---|
| *(none)* | Service, config files, settings keys, plugin. Keeps the indexed data and the package. |
| `--config-dir D` | Also clean Claude config dir `D`. Repeatable. |
| `--tools` | Also `pipx uninstall openviking`. |
| `--purge-data` | Also deletes `~/.openviking` entirely, **including the index**. Irreversible. |
| `--all` | Both of the above. |
| `--dry-run` | Print the plan, change nothing. |
| `--yes` | Skip the confirmation prompt. |

Without `--yes`, and with no terminal to confirm on, the script prints its plan and stops. It is safe
to run twice — every step reports "already absent" rather than failing.

Restart Claude Code afterwards so the plugin unloads.

## Optional extra

The framework used to install `ollama` and its `nomic-embed-text` model purely to generate embeddings
for OpenViking. Neither is removed automatically, because ollama is generally useful and you may be
using it for something else. If you aren't, the model is about 275 MB:

```bash
ollama rm nomic-embed-text
```

## If you'd rather keep it

Nothing stops you. The framework simply no longer reads from it or installs it, so it becomes a tool
you maintain yourself. No vault command will call it.
