---
type: moc
---

# Vault Framework — Map of Contents

The entry point for the vault framework (`~/workspace/vault/`). Generic process docs, templates, and commands for all projects.

## Commands

- [[commands/v-init]] — Bootstrap a project vault
- [[commands/v-migrate]] — Convert a submodule vault to the global model
- [[commands/v-work]] — Vault-aware dev lifecycle
- [[commands/v-team]] — Persona-critique lifecycle (parallel critics loop over plan + diff)
- [[commands/v-do]] — Small, low-risk change with no approval gate
- [[commands/v-ask]] — Read-only, vault-aware Q&A
- [[commands/v-cr]] — Review a remote PR and post comments back
- [[commands/v-capture]] — Session capture + dedupe
- [[commands/v-resume]] — Force fresh context recall
- [[commands/v-sync]] — Re-ingest curated knowledge into OV
- [[commands/v-link]] — Declare coupled projects
- [[commands/v-backfill]] — Targeted past-session ingest
- [[commands/v-guide]] — Generate cross-project integration guides

## Templates

- [[templates/decision]] — ADR template
- [[templates/feature]] — Feature dossier template
- [[templates/indication]] — Working rule / pattern / standard template
- [[templates/session]] — Session log template
- [[templates/plan]] — /v-team converged plan + critique trail template
- [[templates/project-moc]] — Project MOC template
- [[templates/process]] — Repeatable workflow template
- [[templates/architecture]] — System-level design doc template
- [[templates/integration-guide]] — Cross-project API contract template
- [[templates/VAULT]] — Per-repo vault config template

## Personas (`/v-team` critic library)

Shared lenses (`personas/_shared/`): security · performance · quality · skeptic. Stack packs compose
them + add stack-local architects: `personas/api-laravel.md` (full), `personas/nuxt.md` +
`personas/flutter.md` (draft). Selection rules: `personas/_resolution.md`.

## Prompts

Reusable, vault-agnostic procedure docs (paste into a session, fill the variables):
- [[prompts/consolidate-into-indications]] — sweep a vault's scattered guidelines into `indications/`

## Guides

_(none yet — created by `/v-guide` when run on a feature)_

## Sessions (recent)

- [[sessions/2026-06-29-1233-humanize-docs]] — Humanize + slim instruction docs; split out INSTALL.md
- [[sessions/2026-06-15-0900-global-framework-indications]] — Ditch submodules: global framework + indications/ + feature gate
- [[sessions/2026-06-02-1156-v-guide-command]] — Add /v-guide integration guide command
