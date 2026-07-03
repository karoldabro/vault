# Step 3 — SEED WORKSPACE (plan mode)

Materialise the feature workspace in the `_features/` vault and wire it into each participant project.

## 3.1 Scaffold
Create `~/vault/_features/<feature>/` from `$VAULT_FRAMEWORK_PATH/templates/_features/`:
```
<feature>/
  header.md          participants · status · created · slug         (header.md template)
  generic-plan.md    the project-agnostic plan (Step 2)             (only v-pm writes)
  contracts.md       structured cross-project interface (Step 2)
  conversation/      empty — threads land here
  projects/          one project-shard per participant (each project's /v-team writes its own)
```
Instantiate `generic-plan.md` + `contracts.md` from what Step 2 produced. Instantiate one
`projects/<proj>/plan.md` **stub** per participant from `templates/_features/project-shard.md` (the
project fills it in its own session). Do **not** create a `ledger.md` — the ledger is a **derived view**:
`/v-pm status` and reconcile compute it from thread filenames on read, so there is no shared file to
race on.

## 3.2 Symlink into each project
For each participant `<proj>`, symlink the workspace into its vault so it shows in that project's feature
index and `/v-team` can find it without a slug:
```
ln -s ~/vault/_features/<feature>  ~/vault/<proj>/features/<feature>
```
Ensure the symlink is **gitignored** in the participant repo — the `templates/vault.gitignore` entry for
workspace symlinks covers it; confirm it's present in each project vault's `.gitignore`.

## 3.3 Commit the workspace
`_features/` is its own committed vault: stage + commit the new `<feature>/` (explicit paths) and let
`/v-sync` ingest it.

## Required output
```
Workspace: ~/vault/_features/<feature>/  [seeded]
Symlinks: [<proj>/features/<feature> → workspace, per participant]
Next: run `/v-team <feature>` in each project.
```
Mark SEED WORKSPACE `completed`. Tell the user the workspace is ready.
