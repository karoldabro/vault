---
description: Bootstrap a project vault for the current code repo. Creates the vault (global or in-repo), writes VAULT.md, scaffolds folders + indexes, wires CLAUDE.md. No submodule — the framework is read globally.
---

# /v-init — Initialize a project vault

Run this from inside a code repo to wire it into the vault framework. The framework is a single global
install (`$VAULT_FRAMEWORK_PATH`, default `~/workspace/vault`); it is **not** vendored into the vault.

## What it does

1. Resolves a project slug from the repo's directory name (override with `--slug`).
2. Resolves the vault path: global `~/vault/<slug>/` by default, or `<code-repo>/vault/` with `--in-repo`.
   Refuses to overwrite if it already exists.
3. Creates the vault. Global vaults are their own git repo (main branch); an in-repo vault is tracked by
   the code repo (no nested git repo).
4. Scaffolds folders: `sessions/`, `decisions/`, `features/`, `indications/`, `processes/`, `architecture/`.
5. Instantiates `_moc.md`, `_feature-index.md`, `decisions/_inventory.md`, `indications/_index.md`.
6. Copies `templates/vault.gitignore` to the vault's `.gitignore`.
7. Writes `<code-repo>/VAULT.md` (from `templates/VAULT.md`) recording `vault_path` + `slug`, unless absent
   is overridden by `--no-vault-md` or the file already exists.
8. Appends the slug to `~/vault/_global/coupled-groups.md`.
9. Appends a "Vault memory stack" snippet to the code repo's `CLAUDE.md` (pointing at the global framework).
10. Installs the graphify post-commit hook in the code repo (if `graphify` is present) so `graph.json`
    stays fresh for free on every commit — letting `/v-work` answer structural questions from the graph
    instead of grepping. Prints the one-time `graphify .` build command (not auto-run). Skip with `--no-graphify`.
11. Makes the initial commit (global vaults only).

## How to invoke

Direct script (preferred for now):

```bash
cd ~/workspace/<your-repo>
~/workspace/vault/bin/vault-init.sh
# or with explicit slug:
~/workspace/vault/bin/vault-init.sh --slug my-product
```

After init, you'll usually want to push the vault repo to a remote:

```bash
cd ~/vault/<slug>
gh repo create karoldabro/vault.<slug> --private --source=. --push
```

## Flags

| Flag | Effect |
|------|--------|
| `--slug NAME` | Override the slug derived from the code repo directory name. |
| `--in-repo` | Keep the vault inside the code repo at `<code-repo>/vault` (sets `vault_path: ./vault`). |
| `--framework-path PATH` | Override `$VAULT_FRAMEWORK_PATH` (the global framework install). |
| `--no-vault-md` | Don't write `<code-repo>/VAULT.md`. |
| `--no-claude-md` | Don't touch `<code-repo>/CLAUDE.md`. |
| `--no-graphify` | Skip the graphify post-commit hook install. |
| `--yes`, `-y` | Non-interactive. |

## Reversal

To detach: remove the vault dir (`~/vault/<slug>/` or `<code-repo>/vault/`), delete `<code-repo>/VAULT.md`, remove the snippet from the code repo's `CLAUDE.md`, and remove the entry from `~/vault/_global/coupled-groups.md`. A dedicated `vault detach` command will land later (P1.2).

## Already on a submodule vault?

If this repo's vault was created the old way (framework as a `_process/` submodule), convert it with
`/v-migrate` (`bin/vault-migrate.sh`) instead of re-running `/v-init`.
