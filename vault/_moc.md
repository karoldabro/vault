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
- [[decisions/ADR-001-panel-loop-over-peer-debate]] · [[decisions/ADR-002-no-stop-on-approval-alone]] · [[decisions/ADR-003-tool-grounded-findings]] · [[decisions/ADR-004-generic-packs-specifics-in-indications]] · [[decisions/ADR-005-installer-auto-exec]] · [[decisions/ADR-006-testing-critic-group]] · [[decisions/ADR-008-v-cr-remote-pr-review]] · [[decisions/ADR-016-business-persona-family]] · [[decisions/ADR-017-evidence-based-panel-hardening]]

## Indications
- See [[indications/_index]] — v-team authoring rules (persona factoring, loop stops, grounded findings)

## Features
<!-- Link to [[features/]] folder. Active features: -->
- [[features/v-team]] — persona-critique dev lifecycle command
- [[features/v-pm]] — cross-project planning + business-logic requirements knowledge center; see [[decisions/ADR-013-v-pm-cross-project-planning]] + [[decisions/ADR-014-vpm-business-knowledge-center]]
- [[research/llm-collaboration-patterns]] — living, source-cited catalog of LLM collaboration patterns (dev/marketing/sales/planning/support + foundations); evidence reference for panel-mechanism changes (ADR-017)
- `/v-cr` — automated code review on a remote PR (forge+task auto-detect, critic swarm, posts comments); see [[decisions/ADR-008-v-cr-remote-pr-review]] + [[plans/2026-06-19-1106-v-cr-command]]
- Testing critic group — `personas/_shared/testing/` (6 lenses for AI-written tests); see [[indications/testing-persona-group]]

## Sessions (recent)
- [[sessions/2026-07-10-1740-llm-collaboration-patterns]] — Research LLM-collaboration patterns (5 domains) and adopt evidence-backed panel hardening (ADR-017 + living catalog)
- [[sessions/2026-07-10-1620-business-persona-family]] — Business persona family: 5 packs + shared data-evidence critic + multi-pack seating (ADR-016)
- [[sessions/2026-07-04-1115-v-family-usage-audit-retiering]] — usage audit → re-tiering, capture extraction, memory/hook fixes
<!-- Last N session entries appended by /save or OV auto-capture. -->
- [[sessions/2026-07-03-1559-vpm-business-knowledge-center]] — /v-pm authors a `requirements.md` business-logic knowledge center (rules REQ-NN + axis tags, glossary, decision/state tables) for 1+ repos; single-repo `requirements/` category; id chain → established `features/` dossier at shared /v-capture §5b (ADR-014)
- [[sessions/2026-07-03-1240-v-pm-cross-project-planning]] — build /v-pm: cross-project feature planning into a shared `_features/` workspace + file-based conversation (state-in-filename, derived ledger, auto-pickup + `/v-pm status`, deterministic contracts-drift); flip clarify gate to hard-block (ADR-013)
- [[sessions/2026-07-03-1205-propose-clarify-research-gates]] — add clarify (§3a.0a) + online-research (§3a.0b) front gates to shared PROPOSE §3a; both /v-work and /v-team; reconcile contradicting consensus in writing (ADR-012)
- [[sessions/2026-06-29-0818-split-test-planning-step]] — split test design into a generative PROPOSE (f2) fan-out (fault/business-logic/boundary generators) + system-domain-expert critic; generators emit pre-impl, critics confirm post-impl (ADR-011)
- [[sessions/2026-06-22-1152-framework-hooks-tools-rename]] — add per-project VAULT.md `hooks` (14 instruction-only phases) + `tools` (task-tracker MCP) + step-1 `/rename` suggestion to both lifecycles (ADR-010)

## Code
- Graph: `graphify/<repo>/graph.json` per sub-repo.
- Repo roots: `<path-to-repo>`.

## External refs
<!-- Links to source repos at `/media/...` or `/home/.../workspace/...`. -->

## Start Here
- Process docs: `/home/kdabrow/workspace/vault/vault-guide.md` (global framework install)
