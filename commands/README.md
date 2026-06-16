# Commands

Slash commands provided by the vault framework. Installed into `~/.claude/commands/` by `../install.sh` (run once per machine after cloning the framework).

Each file is a Claude Code slash command definition. The `description:` frontmatter field is what shows when users invoke the command help.

| File | Slash command | What it does |
|------|---------------|--------------|
| `v-init.md` | `/v-init` | Bootstrap a project vault for the current code repo. |
| `v-migrate.md` | `/v-migrate` | Convert a submodule-based vault to the global framework model. |
| `v-work.md` | `/v-work` | Vault-aware development lifecycle. |
| `v-team.md` | `/v-team` | Persona-critique lifecycle: parallel project-specific critics loop over plan + diff. |
| `v-capture.md` | `/v-capture` | Enhanced session capture. |
| `v-resume.md` | `/v-resume` | Force fresh context recall (vault + OpenViking). |
| `v-sync.md` | `/v-sync` | Re-ingest curated knowledge into OpenViking. |
| `v-link.md` | `/v-link` | Declare two projects as coupled. |
| `v-backfill.md` | `/v-backfill` | Targeted ingest of past Claude Code sessions. |
| `v-guide.md` | `/v-guide` | Generate a cross-project integration guide from an existing feature. |

Multi-step commands (`v-work`, `v-team`) keep their steps in a sibling subdirectory (`v-work/steps/`,
`v-team/steps/`) loaded on demand. `/v-team` reuses `/v-work`'s steps 01/02/05 and adds looped variants
for propose/execute; its critic definitions live in `../personas/` (shared lenses + per-stack packs).

See `../vault-guide.md` §11 for the command reference (and §1.1 for vault path/config resolution).

## Why symlinks instead of copies

Pulling the framework repo updates the symlinked commands instantly — no per-machine reinstall. If you'd rather have copies, edit `install.sh`.
