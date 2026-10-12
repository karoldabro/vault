# Step 4 — SEED WORKSPACE (plan mode, after approval)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

Runs only after the operator approved the plan. **Single-repo mode skips this step**: the plan home
from Step 1 already holds everything, so go to Step 5.

Multi-repo mode wires the `~/vault/_features/<feature>/` workspace into each participant.

## 4.1 Scaffold what the plan does not already hold
`plan.md`, `plan.trail.md`, `briefs/`, `requirements.md` and `contracts.md` exist from Step 3. Add:
```
<feature>/
  header.md          participants · status · created · slug   (templates/_features/header.md)
  conversation/      empty — threads land here
  projects/<proj>/plan.md   one shard per participant (templates/_features/project-shard.md)
```
A shard holds what that repo consumes from `contracts.md`, its constraints and its tests. The session
tracker stays in `plan.md` `## Sessions`, its one home; a shard carries no second copy.

## 4.2 Symlink into each participant
```
ln -s ~/vault/_features/<feature>  ~/vault/<proj>/features/<feature>
```
Confirm each participant vault's `.gitignore` carries the workspace-symlink entry from
`$VAULT_FRAMEWORK_PATH/templates/vault.gitignore`.

## 4.3 Stage, commit in Step 5
Leave the workspace staged. Step 5 commits it with the trail and any ADRs, in one commit.

## Required output
```
Workspace: ~/vault/_features/<feature>/  [plan · briefs · requirements · contracts · shards]
Symlinks: [<proj>/features/<feature> → workspace, per participant]
```
Mark SEED WORKSPACE `completed` → Step 5.
