# Attic — archived commands

Retired command definitions, kept for reference. Not installed (no `~/.claude/commands/` symlinks).

| File | Was | Why archived (2026-07-04) |
|------|-----|---------------------------|
| `v-migrate.md` | `/v-migrate` | One-shot migration (submodule → global framework) finished across all vaults. The underlying `bin/vault-migrate.sh` still works standalone if an old vault ever resurfaces. |

To restore one: `git mv` it back to `commands/` and re-run `install.sh` (or re-create the symlink).
