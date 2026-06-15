---
type: vault-config
tags: [config]
---

# VAULT.md — per-repo vault configuration

Optional. Place at the **code repo root**. Every vault command reads it first and folds it into the
lifecycle. Delete it to fall back to the global default (`~/vault/<slug>/`). Edit the `key: value`
lines below; comments (`#`) are ignored.

## config
<!-- Where this repo's vault lives. Relative paths resolve against the repo root, so `./vault` keeps
     the vault inside the repository; an absolute path like `~/vault/givore` keeps it global.
     Omit vault_path entirely to use the global default `~/vault/<slug>/`. -->
vault_path: ./vault
# framework_path: ~/workspace/vault   # override the global framework install (rarely needed)
slug: {{slug}}

## structure
<!-- Declarative tweaks to the standard folder set. All optional. -->
# add_folders: [runbooks]              # extra folders to scaffold + treat as vault dirs
# rename: {indications: conventions}   # local aliases for standard folders
# optional: [research, legal]          # folders that may be absent without a warning

## behaviour
<!-- Bounded hooks the lifecycle honors. All optional; defaults shown. -->
# load_context_extra: [runbooks]       # folders Step 2 loads beyond the defaults
capture_indications: true              # run the indication-candidate scan at capture time
