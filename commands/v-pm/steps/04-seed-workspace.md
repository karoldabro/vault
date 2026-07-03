# Step 3 — SEED WORKSPACE (plan mode)

**Multi-repo mode only.** In **single-repo mode** (1 participant) this step is **skipped** — `01-intake.md`
§1.3 already wrote `requirements.md` into the project's own `<project-vault>/requirements/<feature>.md`
(no `_features/` workspace, no symlink, no shard). Proceed straight to CAPTURE (Step 5, project-vault
variant). The rest of this step is the 2+-repo path.

Materialise the feature workspace in the `_features/` vault and wire it into each participant project.

## 3.1 Scaffold
Create `~/vault/_features/<feature>/` from `$VAULT_FRAMEWORK_PATH/templates/_features/`:
```
<feature>/
  requirements.md    business knowledge center — what & why (Step 2)  (only v-pm writes)
  generic-plan.md    the project-agnostic plan — how/sequencing (Step 2)  (only v-pm writes)
  contracts.md       structured cross-project interface (Step 2)
  header.md          participants · status · created · slug         (header.md template)
  conversation/      empty — threads land here
  sessions/          empty — planning-session records (CAPTURE writes here)
  projects/          one project-shard per participant (each project's /v-team writes its own)
```
Instantiate `requirements.md` + `generic-plan.md` + `contracts.md` from what Step 2 produced. Instantiate
one `projects/<proj>/plan.md` **stub** per participant from `templates/_features/project-shard.md` (the
project fills the body in its own session). **Seed each shard's `## Business rules to satisfy` section**
(the one section v-pm owns) with the `REQ-NN` ids from `requirements.md` that fall to that project —
**id refs only, not copied rule text**, and **not** in `## Consumed contract` (keeps the Step-0 drift
check clean). Do **not** create a `ledger.md` — the ledger is a **derived view**:
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

## 3.3 Stage the workspace (commit happens in CAPTURE)
Leave the new `<feature>/` **staged, not committed** — the CAPTURE step (05) commits it together with the
planning-session record and any ADRs, in one commit. (`_features/` is its own committed vault; `/v-sync`
ingests it.)

## Required output
```
Workspace: ~/vault/_features/<feature>/  [seeded, staged]  (requirements.md · generic-plan.md · contracts.md)
Shard rule-ids: [<proj>: REQ-NN,… seeded into `## Business rules to satisfy`, per participant]
Symlinks: [<proj>/features/<feature> → workspace, per participant]
```
Mark SEED WORKSPACE `completed` → Step 5 (CAPTURE).
