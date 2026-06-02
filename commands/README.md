# Commands

Slash commands provided by the vault framework. Installed into `~/.claude/commands/` by `../install.sh` (run once per machine after cloning the framework).

Each file is a Claude Code slash command definition. The `description:` frontmatter field is what shows when users invoke the command help.

| File | Slash command | What it does |
|------|---------------|--------------|
| `v-init.md` | `/v-init` | Bootstrap a project vault for the current code repo. |
| `v-work.md` | `/v-work` | Vault-aware development lifecycle. |
| `v-capture.md` | `/v-capture` | Enhanced session capture. |
| `v-resume.md` | `/v-resume` | Force fresh context recall (vault + OpenViking). |
| `v-sync.md` | `/v-sync` | Re-ingest curated knowledge into OpenViking. |
| `v-link.md` | `/v-link` | Declare two projects as coupled. |
| `v-backfill.md` | `/v-backfill` | Targeted ingest of past Claude Code sessions. |
| `v-guide.md` | `/v-guide` | Generate a cross-project integration guide from an existing feature. |

See `../vault-guide.md` §10 for usage notes.

## Why symlinks instead of copies

Pulling the framework repo updates the symlinked commands instantly — no per-machine reinstall. If you'd rather have copies, edit `install.sh`.
