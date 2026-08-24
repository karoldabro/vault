---
type: moc
---

# Vault Framework — Map of Contents

This is the entry point for the vault framework repo (`~/workspace/vault/`): the generic process docs,
templates, personas and commands shared by every project. This repo's own project vault has a separate
map at [[vault/_moc]].

Start with [[README]] to install it, and [[vault-guide]] to understand the layout and the lifecycle.

## Commands

- [[commands/v-setup]] — Install or repair the machine-level tool stack
- [[commands/v-init]] — Bootstrap a project vault
- [[commands/v-work]] — Vault-aware dev lifecycle
- [[commands/v-team]] — Persona-critique lifecycle (parallel critics loop over plan + diff)
- [[commands/v-pm]] — Cross-project feature planning into a shared `_features/` workspace
- [[commands/v-do]] — Small, low-risk change with no approval gate
- [[commands/v-ask]] — Read-only, vault-aware Q&A
- [[commands/v-cr]] — Review a remote PR and post comments back
- [[commands/v-capture]] — Session capture with a duplicate check
- [[commands/v-reconcile]] — Rewrite a document to the writing standard, losing no constraint
- [[commands/v-link]] — Declare coupled projects
- [[commands/v-guide]] — Generate cross-project integration guides

`attic/v-migrate.md` holds the retired `/v-migrate`; `bin/vault-migrate.sh` still works.

## Shared command modules

- [[commands/_shared/communication]] — how every command writes to the user
- [[commands/_shared/document-standard]] — how every command writes a file; `bin/doc-lint.sh` enforces it
- [[commands/_shared/critic-panel]] — the single-pass critic panel reused by `/v-cr` and `/v-team`
- [[commands/_shared/vault-sync]] — git sync for out-of-repo vaults

## Templates

- [[templates/decision]] — ADR template
- [[templates/feature]] — Feature dossier template
- [[templates/indication]] — Working rule / pattern / standard template
- [[templates/session]] — Session log template
- [[templates/plan]] — `/v-team` converged plan template
- [[templates/trail]] — The plan's process record, written beside it
- [[templates/project-moc]] — Project MOC template
- [[templates/process]] — Repeatable workflow template
- [[templates/architecture]] — System-level design doc template
- [[templates/integration-guide]] — Cross-project API contract template
- [[templates/VAULT]] — Per-repo vault config template

`templates/_features/` holds the `/v-pm` workspace templates: `requirements.md`, `generic-plan.md`,
`contracts.md`, `header.md`, `project-shard.md`, `planning-session.md`, `THREAD.md`.

## Personas (`/v-team` critic library)

Shared lenses in `personas/_shared/`: correctness, security, performance, quality, skeptic, plus the
`testing/` group that critiques AI-written tests and the `business/` group that critiques numeric
evidence.

Stack packs: `personas/api-laravel.md` (full), `personas/nuxt.md` and `personas/flutter.md` (draft).
Business packs: `marketing`, `sales`, `seo`, `support`, `business`, `startup-eval`. Selection rules live
in `personas/_resolution.md`.

## Prompts

Reusable, vault-agnostic procedures. Paste one into a session and fill the variables.

- [[prompts/consolidate-into-indications]] — sweep a vault's scattered guidelines into `indications/`

## Sessions

- [[sessions/2026-06-15-0900-global-framework-indications]] — Ditch submodules: global framework,
  `indications/`, feature gate
- [[sessions/2026-06-02-1156-v-guide-command]] — Add the `/v-guide` integration-guide command

Later sessions live in this repo's project vault at `vault/sessions/`.
