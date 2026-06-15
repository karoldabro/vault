---
date: 2026-06-15
time: "09:00"
slug: global-framework-indications
keywords: [global-framework, no-submodule, VAULT.md, indications, feature-gate, vault-migrate]
features: []
decisions: []
---

# 2026-06-15 — Ditch submodules: global framework + indications/ + feature gate

## Goal

Three framework improvements: (1) replace the `_process/` submodule model with a single global install
plus per-repo `VAULT.md` config; (2) add a first-class `indications/` folder for project working-rules,
read early and grown ADR-style; (3) add an explicit create/update/skip gate for `features/` dossiers at
capture time.

## Did

- **Global resolution** — framework now read from `$VAULT_FRAMEWORK_PATH` (default `~/workspace/vault`,
  captured in `~/vault/_global/config.md` by `setup.sh`). Vault path resolves repo `VAULT.md` →
  global config → `~/vault/<slug>/`. Documented in `vault-guide.md` §1.1.
- **vault-init.sh** — removed the `git submodule add` block, `--no-submodule`, `VAULT_FRAMEWORK_URL`.
  Added `--in-repo` (vault under `<code-repo>/vault`, tracked by the code repo — no nested `.git`),
  writes `<code-repo>/VAULT.md`, scaffolds `indications/` + `_index.md`.
- **vault-migrate.sh + /v-migrate** — new idempotent de-submodule tool: deinit `_process`, drop
  `.gitmodules`/`.git/modules`, repoint the MOC, write `VAULT.md`, commit.
- **indications/** — canonical home for patterns/standards/testing-conventions (intra-project), distinct
  from `guides/` (cross-project contracts) and `features/` (domain dossiers). Loaded first-class in
  `v-work` Step 2 §2.3a; grown at capture via an indication-candidate scan mirroring the ADR scan.
- **feature gate** — `v-capture` Step 5b forces CREATE / UPDATE / SKIP per touched feature, reconciles
  `_feature-index.md`. Surfaced in `v-work` Step 5.5.
- **templates** — new `VAULT.md` (config/structure/behaviour) and `indication.md` (Rule/Rationale/
  Examples/Applies-to).
- **tests** — `vault-init.bats` rewritten for the global model; new `vault-migrate.bats`. 45/45
  dockerized bats pass.
- **givore migrated** — ran `vault-migrate.sh` against the real `~/vault/givore` (backup taken first).
  Commit `1c24080` touched only `.gitmodules` (D), `_process` (D), `_moc.md` (M, one line). All 700
  content files intact — verified by content digest.

## Learned

- An in-repo vault must NOT be its own git repo, or git treats it as an embedded repo — vault-init skips
  `git init`/commit when `--in-repo`, letting the code repo track it.
- `VAULT.md` is markdown the agent reads (no parser): bounded `config`/`structure`/`behaviour` sections
  keep per-repo overrides predictable vs a free-form CLAUDE.md-style block.
- Removing a submodule loses no project data — the submodule is only a clone of the framework. The
  de-submodule diff is provably limited to `.gitmodules`, the gitlink, and the MOC pointer line.
- The "never sed" rule is for the agent's in-lifecycle edits; migration shell utilities use `sed -i`
  legitimately (vault-init already does).

## Next

- `install.sh` re-run done — `/v-migrate` is symlinked and usable.
- Framework committed on `main` (`7aed46b`), not pushed — push when ready.
- givore backup at `~/givore-vault-backup-20260615-092858.tar.gz` (delete once satisfied).
- Optionally add a `VAULT.md` to the givore *code* repo (not required — its vault is at the default
  `~/vault/givore`, which resolves automatically).

## Refs

- [[../bin/vault-migrate]]
- [[../commands/v-migrate]]
- [[../commands/v-init]]
- [[../commands/v-capture]]
- [[../templates/VAULT]]
- [[../templates/indication]]
- [[../vault-guide]]
