---
type: vault-config
tags: [config]
---

# VAULT.md — per-repo vault configuration

Optional. Put it at the code repo root. Every vault command reads it first and folds it into the run.
Delete it to fall back to the global default (`~/vault/<slug>/`). Edit the `key: value` lines below;
comments (`#`) are ignored.

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
<!-- Bounded toggles the lifecycle honors. All optional; defaults shown. -->
# load_context_extra: [runbooks]       # folders Step 2 loads beyond the defaults
capture_indications: true              # run the indication-candidate scan at capture time
# suggest_rename: true                 # step 1 surfaces a `/rename <slug>` for you to paste (default: on)

## hooks
<!-- Per-project, per-step instruction (prose only; never run as a shell command, there is no `run:`
     syntax). Both /v-work and /v-team honor them: read once at step 1, carried through the run. The 14
     phases are on_start, pre_/post_analyze, pre_/post_load_context, pre_/post_propose,
     pre_/post_execute, pre_/post_commit, pre_/post_capture, and on_end. Full contract and precedence
     in vault-guide.md §1.1. -->
# on_start: "This repo tracks work in Jira (project VAULT). If the task names a ticket, fetch it via the Jira MCP first."
# post_commit: "Remind me to move the Jira ticket to In Review (don't transition it automatically)."

## tools
<!-- Per-project tool guidance (suggestion, not a gate). Lets the lifecycle fetch ticket context from
     the tracker this repo actually uses. See tool-playbook.md §6. -->
# task_tracker: jira                   # jira | asana | linear | github-issues | none
# task_tracker_mcp: <jira mcp server>  # which MCP to query
# task_tracker_key: VAULT              # Jira project key / Asana project gid / repo
# guidance: "Fetch the ticket's description + acceptance criteria before proposing."

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
# team_max_test_designers: 3           # generators in the PROPOSE (f2) test-design fan-out
