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
slug: vault

## structure
<!-- Declarative tweaks to the standard folder set. All optional. -->
add_folders: [plans]                   # /v-team plan artifacts
# add_folders: [runbooks]              # extra folders to scaffold + treat as vault dirs
# rename: {indications: conventions}   # local aliases for standard folders
# optional: [research, legal]          # folders that may be absent without a warning

## behaviour
<!-- Bounded toggles the lifecycle honors. All optional; defaults shown. -->
# load_context_extra: [runbooks]       # folders Step 2 loads beyond the defaults
capture_indications: true              # run the indication-candidate scan at capture time
# suggest_rename: true                 # step 1 surfaces a `/rename <slug>` for you to paste (default: on)

## hooks
<!-- Per-project, per-step INSTRUCTION (prose only — never run as a shell command). 14 phases:
     on_start · pre_/post_analyze · pre_/post_load_context · pre_/post_propose · pre_/post_execute ·
     pre_/post_commit · pre_/post_capture · on_end. Contract + precedence: vault-guide.md §1.1.
     This framework repo declares none (no external tracker); examples are commented in templates/VAULT.md. -->

## tools
<!-- Per-project tool guidance (task-tracker MCP, etc.). Suggestion, not a gate. See tool-playbook.md §6.
     This repo declares none — it has no external task tracker. -->

<!-- /v-team multi-agent persona config (all optional). Selects which critic personas review the
     plan + diff. Auto-detected from the stack if omitted. See personas/_resolution.md. -->
# project_type: api-laravel            # api-laravel | nuxt | flutter — selects the default persona pack
# personas:
#   use: api-laravel                   # explicit pack (defaults to project_type)
#   add: [./vault/personas/billing-domain.md]   # custom persona files (repo-relative)
#   skip: [skeptic]                    # drop a persona by id
# team_max_rounds: 2                   # plan-critique loop cap
# team_max_review_rounds: 2            # diff-review loop cap
# team_max_parallel_critics: 3         # critics selected per change (hard max 5)
