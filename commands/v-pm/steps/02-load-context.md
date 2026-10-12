# Step 2 — LOAD CONTEXT (plan mode)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

Ground the plan in what the vault and the code already say — **before** the panel drafts anything. A
cross-project planner loads context from **every participant**, not one. Query **cheapest-first**: the
vault before the code; stop as soon as you have enough.

**`/v-pm` writes no code.** This step reads source and runs read-only commands only: no edit, no
install, no build, no test run, no migration.

## 2.0 Sync every participant's vault first
A cross-project planner reads vaults other people write to, so a stale copy here is likelier than
anywhere else. Unless `behaviour.vault_autosync` is `false`, pull each participant vault **and**
`~/vault/_features` before the sweep below:

```bash
$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh pull ~/vault/<proj>
```

Exit 0 and 4 are silent; 1, 3 and 5 get one line each, grouped into a single note rather than one per
project. Nothing here halts the sweep. Contract: `$VAULT_FRAMEWORK_PATH/commands/_shared/vault-sync.md`.

## 2.1 Vault sweep — always first, across every participant
For each participant `<proj>` (plus `_global` and the `_features/` vault), grep the vault:
`grep -ril "<necessity keywords>" ~/vault/<proj>/{decisions,features,sessions,indications}/`. Surface:
related **ADRs / decisions**, **existing feature dossiers** that overlap this necessity, prior
**cross-project plans**, past **sessions**, and **coupling** notes. This is the cheapest layer and
covers the whole vault — do it before anything else.

## 2.2 Existing knowledge to honor
- **`_features/`** — is there already a workspace or dossier for an adjacent feature? Reuse its contracts
  / decisions; don't reinvent the seam.
- **Per-project `conventions.md` / `indications/`** — working rules that constrain each project (they
  override generic defaults).
- **`_global/coupled-groups.md`** — the declared coupling for the participants (already read at intake).

## 2.3 Cross-project coupling map
Per participant, note what it already exposes / consumes that this feature touches (endpoints, enums,
shared types). This seeds the **contract critic** in Step 3 and flags where the new plan meets existing
code.

## 2.4 Read-only code orientation, per participant
The session split in Step 3 is cut against real files, so read each repo at its absolute path:

1. **Serena** when `check_onboarding_performed()` answers: `get_symbols_overview` on the modules the
   keywords touch, `find_symbol` for each capability the need adds. Otherwise `git ls-files`, `grep -rn`
   and reading the files.
2. **Manifests**: `composer.json`, `package.json`, `pubspec.yaml`, `pyproject.toml` — what is already
   installed, so a reviewer can check a package against the repo instead of guessing.
3. **The entry points** the need runs through: route files, command files, the module that owns the
   entity.
4. **The conventions in force**: two or three sibling files of each kind the plan will add.

Write the result as a **code index**: one line per path, with what it is and why it matters here. The
index is what every reviewer receives, so no reviewer re-greps the tree
(`$VAULT_FRAMEWORK_PATH/commands/_shared/agent-conduct.md` "Fan-out").

## Required output — the LOAD CONTEXT digest
```
Vaults loaded: [<proj>… + _global + _features]
Related ADRs / decisions: [...]
Existing features / dossiers: [overlap → reuse, don't reinvent]
Prior cross-project plans: [...]
Conventions / indications that constrain this: [...]
Coupling touchpoints: [per participant]
Code index: [<repo>: <path> — <what it is, why it matters>, …]
```
This digest is **passed to every critic in Step 3** (they plan grounded in project knowledge, not blind)
and referenced by the draft. Mark LOAD CONTEXT `completed` → Step 3.
