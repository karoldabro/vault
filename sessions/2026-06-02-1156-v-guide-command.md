---
date: 2026-06-02
time: "11:56"
slug: v-guide-command
keywords: [v-guide, integration-guide, cross-project, api-contract, guide-template]
features: []
decisions: []
---

# 2026-06-02 — Add /v-guide integration guide command

## Goal

Add a `/v-guide` vault command that generates structured cross-project integration guides from an existing feature, eliminating the need to repeat manual integration prompts for each consuming project.

## Did

- Created `_process/templates/integration-guide.md` — canonical guide template with sections: Overview, Data Flow, Enums & Constants, Data Structures, API Endpoints, Request & Response Shapes, Filtering & Pagination, Integration Checklist, Changelog.
- Created `commands/v-guide.md` — 6-step command: resolve args → load feature context (OV + vault + graphify) → extract contract → write guide → cross-link + index → output summary. Follows all existing command patterns: health checks, fallbacks, idempotency note.
- Updated `vault-guide.md`: added `guides/` to §2 folder map, added integration guide row to §6 decision tree, added `/v-guide` row to §11 commands table.
- Updated `commands/README.md`: registered `/v-guide` in command registry table.

## Learned

- The vault framework repo (`~/workspace/vault/`) has no `sessions/` directory — created it this session. No prior sessions existed as markdown files here (previous captures went only to claude-mem/OV).
- `guides/` is a new vault folder type — cross-project contracts, not internal feature docs. Distinct from `features/` (subject-matter knowledge) and `processes/` (repeatable workflows).
- The command's value is repeatability: write the guide once after building a feature; share the path with all coupled projects instead of re-prompting each time.

## Next

- Install updated framework commands on any machine using this framework (`install.sh` re-run or symlink refresh).
- When building next cross-project feature (e.g. givore recycling API), run `/v-guide recycling --source givore --for givore_app,api.givore.com` to test the new command end-to-end.

## Refs

- [[../commands/v-guide]]
- [[../commands/README]]
- [[../_process/templates/integration-guide]]
- [[../vault-guide]]
