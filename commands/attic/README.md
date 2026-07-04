# Attic — archived commands

Retired command definitions, kept for reference. Not installed (no `~/.claude/commands/` symlinks).

| File | Was | Why archived (2026-07-04) |
|------|-----|---------------------------|
| `v-migrate.md` | `/v-migrate` | One-shot migration (submodule → global framework) finished across all vaults. The underlying `bin/vault-migrate.sh` still works standalone if an old vault ever resurfaces. |
| `v-resume.md` | `/v-resume` | Superseded by the OpenViking `auto-recall.mjs` SessionStart hook, which does the same recall automatically (0 uses since). If the auto-hook misses, `memory_recall(query=...)` directly covers it. |

To restore one: `git mv` it back to `commands/` and re-run `install.sh` (or re-create the symlink).
