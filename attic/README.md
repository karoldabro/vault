# Attic — archived commands

Retired command definitions, kept for reference. Never installed by either route — this directory sits
outside `commands/` precisely so the plugin's default scan can't turn these files back into commands.

| File | Was | Why archived (2026-07-04) |
|------|-----|---------------------------|
| `v-migrate.md` | `/v-migrate` | One-shot migration (submodule → global framework) finished across all vaults. The underlying `bin/vault-migrate.sh` still works standalone if an old vault ever resurfaces. |

To restore one: `git mv` it back to `commands/`. A plugin install picks it up at the next
`/plugin update`; a symlink install needs `install.sh` re-run.
