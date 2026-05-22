# Commands

Slash commands provided by the vault framework. Installed into `~/.claude/commands/` by `../install.sh` (run once per machine after cloning the framework).

Each file is a Claude Code slash command definition. The `description:` frontmatter field is what shows when users invoke the command help.

| File | Slash command | What it does |
|------|---------------|--------------|
| `work.md` | `/work` | Vault-aware development lifecycle. |
| `m-capture.md` | `/m-capture` | Enhanced session capture. |

See `../vault-guide.md` §10 for usage notes.

## Why symlinks instead of copies

Pulling the framework repo updates the symlinked commands instantly — no per-machine reinstall. If you'd rather have copies, edit `install.sh`.
