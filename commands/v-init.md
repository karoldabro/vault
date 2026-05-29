---
description: Bootstrap a project vault for the current code repo. Creates ~/vault/<slug>/, attaches the framework as _process/ submodule, scaffolds folders + indexes, wires CLAUDE.md.
---

# /v-init — Initialize a project vault

Run this from inside a code repo to wire it into the vault framework.

## What it does

1. Resolves a project slug from the repo's directory name (override with `--slug`).
2. Refuses to overwrite if `~/vault/<slug>/` already exists.
3. Creates `~/vault/<slug>/` as a new git repo (main branch).
4. Adds the framework as a submodule at `_process/`.
5. Scaffolds folders: `sessions/`, `decisions/`, `features/`, `processes/`, `architecture/`.
6. Instantiates `_moc.md`, `_feature-index.md`, `decisions/_inventory.md`.
7. Copies `templates/vault.gitignore` to the vault's `.gitignore`.
8. Appends the slug to `~/vault/_global/coupled-groups.md`.
9. Appends a "Vault memory stack" snippet to the code repo's `CLAUDE.md`.
10. Installs the graphify post-commit hook in the code repo (if `graphify` is present) so `graph.json`
    stays fresh for free on every commit — letting `/v-work` answer structural questions from the graph
    instead of grepping. Prints the one-time `graphify .` build command (not auto-run). Skip with `--no-graphify`.
11. Makes the initial commit.

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
| `--framework-url URL` | Override the framework submodule URL (default: github SSH). |
| `--no-submodule` | Skip the submodule add (offline / detached setups). |
| `--no-claude-md` | Don't touch `<code-repo>/CLAUDE.md`. |
| `--no-graphify` | Skip the graphify post-commit hook install. |
| `--yes`, `-y` | Non-interactive. |

## Reversal

To detach: remove `~/vault/<slug>/`, remove the snippet from the code repo's `CLAUDE.md`, remove the entry from `~/vault/_global/coupled-groups.md`. A dedicated `vault detach` command will land later (P1.2).
