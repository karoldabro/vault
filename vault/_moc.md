---
type: moc
project: vault
tags: [moc]
---

# vault — Map of Contents

## Coupled with
<!-- Sibling projects. e.g., - [[../<other-project>/_moc]] (api shares contracts) -->

## Decisions
<!-- Auto: link to [[decisions/]] folder. Notable ADRs: -->
- [[decisions/ADR-001-panel-loop-over-peer-debate]] · [[decisions/ADR-002-no-stop-on-approval-alone]] · [[decisions/ADR-003-tool-grounded-findings]] · [[decisions/ADR-004-generic-packs-specifics-in-indications]] · [[decisions/ADR-005-installer-auto-exec]] · [[decisions/ADR-006-testing-critic-group]] · [[decisions/ADR-008-v-cr-remote-pr-review]]

## Indications
- See [[indications/_index]] — v-team authoring rules (persona factoring, loop stops, grounded findings)

## Features
<!-- Link to [[features/]] folder. Active features: -->
- [[features/v-team]] — persona-critique dev lifecycle command
- `/v-cr` — automated code review on a remote PR (forge+task auto-detect, critic swarm, posts comments); see [[decisions/ADR-008-v-cr-remote-pr-review]] + [[plans/2026-06-19-1106-v-cr-command]]
- Testing critic group — `personas/_shared/testing/` (6 lenses for AI-written tests); see [[indications/testing-persona-group]]

## Sessions (recent)
<!-- Last N session entries appended by /save or OV auto-capture. -->
- [[sessions/2026-06-22-1152-framework-hooks-tools-rename]] — add per-project VAULT.md `hooks` (14 instruction-only phases) + `tools` (task-tracker MCP) + step-1 `/rename` suggestion to both lifecycles (ADR-010)
- [[sessions/2026-06-20-1900-v-capture-business-logic]] — /v-capture captures test-shaped `## Behaviors & rules` in sessions + features for business/feature/integration/UI test enablement
- [[sessions/2026-06-19-1605-v-cr-panel-spawn-coverage-brevity]] — harden /v-cr: enforce real panel spawn (+`Spawned:` proof), surface coverage + test posture, tighten comments
- [[sessions/2026-06-19-1526-setup-zstd-claude-mem-fixes]] — fix fresh-install: zstd prereq for ollama + correct claude-mem marketplace qualifier (claude-mem@thedotmack)
- [[sessions/2026-06-19-1325-v-cr-sandbox-path]] — add optional /v-cr --sandbox: runtime-verified review in a throwaway clone+Docker sandbox (ADR-009)

## Code
- Graph: `graphify/<repo>/graph.json` per sub-repo.
- Repo roots: `<path-to-repo>`.

## External refs
<!-- Links to source repos at `/media/...` or `/home/.../workspace/...`. -->

## Start Here
- Process docs: `/home/kdabrow/workspace/vault/vault-guide.md` (global framework install)
