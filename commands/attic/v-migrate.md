---
description: Convert an existing submodule-based project vault to the global framework model — de-init the _process/ submodule, write VAULT.md, repoint the MOC.
---

# /v-migrate — De-submodule a project vault

Older vaults carried the framework as a `_process/` git submodule. The framework is now a single global
install (`$VAULT_FRAMEWORK_PATH`, default `~/workspace/vault`), so the submodule is dead weight. This
command removes it and records the vault location in a repo `VAULT.md`.

Run it from inside the **code repo** (so the slug + `VAULT.md` location resolve).

## What it does

1. Resolves the vault dir from the code repo's slug (`$VAULT_HOME/<slug>`) or `--vault PATH`.
2. If the vault has no `_process/` submodule → reports "already migrated" and exits 0 (idempotent).
3. Removes the submodule: `git submodule deinit -f _process`, `git rm -f _process`, and clears
   `.git/modules/_process` + an emptied `.gitmodules`.
4. Repoints the `_moc.md` "Start Here" pointer at `$VAULT_FRAMEWORK_PATH/vault-guide.md`.
5. Writes `<code-repo>/VAULT.md` (from `templates/VAULT.md`) if absent.
6. Commits `chore(vault): de-submodule — migrate to global framework` in the vault repo.

## How to invoke

```bash
cd ~/workspace/<your-repo>
~/workspace/vault/bin/vault-migrate.sh
# or target a vault dir explicitly:
~/workspace/vault/bin/vault-migrate.sh --vault ~/vault/givore --slug givore
```

## Flags

| Flag | Effect |
|------|--------|
| `--slug NAME` | Override the slug derived from the code repo directory name. |
| `--vault PATH` | Operate on this vault dir directly (skips slug resolution). |
| `--framework-path PATH` | Override `$VAULT_FRAMEWORK_PATH`. |
| `--no-vault-md` | Don't write `<code-repo>/VAULT.md`. |
| `--yes`, `-y` | Non-interactive. |

## After migrating

Commit the new `VAULT.md` alongside your code, then run `/v-work` once to confirm every command resolves
the vault with no `_process/` path. Re-running `/v-migrate` on an already-migrated vault is a safe no-op.
