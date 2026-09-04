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

<!-- The closed list of surfaces an indication may be scoped to — one value per real surface, no
     synonyms. `indications/_index.md`'s `scope` column is filtered against it when /v-cr loads the
     project's rules, so a row naming an undeclared surface is silently unreachable. Declare it and
     `bin/doc-lint.sh` (INDEX3) flags drift; omit it and the check does not run.
     A single-repo project needs only `repo` and `cross-repo`. -->
# indication_scopes: [api.example.com, app.example.com, mobile, cross-repo]

## behaviour
<!-- Bounded toggles the lifecycle honors. All optional; defaults shown. -->
# load_context_extra: [runbooks]       # folders Step 2 loads beyond the defaults
capture_indications: true              # run the indication-candidate scan at capture time
# suggest_rename: true                 # step 1 surfaces a `/rename <slug>` for you to paste (default: on)
# vault_autosync: true                 # pull the vault before reading it, commit + push after writing
                                       # (default: on). Only bites when the vault is a git repo OUTSIDE
                                       # this code repo — an in-repo vault rides the code commit.
                                       # Set false to keep committing the vault by hand.

## definition of done
<!-- How this repo runs its own checks, written by bin/vault-init.sh and confirmed by you.
     `bin/gate.sh config` refuses at the FIRST step of a session when a key is omitted.
     `absent: <reason>` is legal: a tool this repo does not have is a fact, and recording it is what
     stops the next session assuming the question was settled.
     Profiles: `code` (tests, lint, duplication, documented interface) or `ai-instructions`
     (observable in real output, tooling present, exercised by a real run). -->
dod_profile: {{dod_profile}}
test_command: {{test_command}}
lint_command: {{lint_command}}
delivery_command: {{delivery_command}}

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
# project_type: api-laravel            # api-laravel | nuxt | flutter | marketing | sales | seo | support | business | startup-eval
# personas:
#   use: api-laravel                   # explicit pack (defaults to project_type); a LIST seats multiple
#                                      # packs — use: [sales, marketing] — first entry = primary pack
#                                      # (dev + business packs must not mix; _resolution.md §1)
#   add: [./vault/personas/billing-domain.md]   # custom persona files (repo-relative)
#   skip: [skeptic]                    # drop a persona by id
# team_max_rounds: 2                   # plan-critique loop cap
# team_max_parallel_critics: 3         # critics selected per change (hard max 5; business packs default 4, §2.2)
# team_max_review_rounds: 2            # diff-review loop cap
# team_max_test_designers: 3           # generators in the PROPOSE (f2) test-design fan-out
