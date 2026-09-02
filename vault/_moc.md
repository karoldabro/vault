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
- [[decisions/ADR-001-panel-loop-over-peer-debate]] · [[decisions/ADR-002-no-stop-on-approval-alone]] · [[decisions/ADR-003-tool-grounded-findings]] · [[decisions/ADR-004-generic-packs-specifics-in-indications]] · [[decisions/ADR-005-installer-auto-exec]] · [[decisions/ADR-006-testing-critic-group]] · [[decisions/ADR-008-v-cr-remote-pr-review]] · [[decisions/ADR-016-business-persona-family]] · [[decisions/ADR-017-evidence-based-panel-hardening]] · [[decisions/ADR-018-decision-communication-contract]] · [[decisions/ADR-019-drop-openviking-dependency]]

## Indications
- See [[indications/_index]] — v-team authoring rules (persona factoring, loop stops, grounded findings)

## Features
<!-- Link to [[features/]] folder. Active features: -->
- [[features/v-team]] — persona-critique dev lifecycle command
- [[features/v-pm]] — cross-project planning + business-logic requirements knowledge center; see [[decisions/ADR-013-v-pm-cross-project-planning]] + [[decisions/ADR-014-vpm-business-knowledge-center]]
- [[research/llm-collaboration-patterns]] — living, source-cited catalog of LLM collaboration patterns (dev/marketing/sales/planning/support + foundations); evidence reference for panel-mechanism changes (ADR-017). Covers **agent↔agent**.
- [[research/decision-communication]] — living, source-cited evidence base for how commands write **to the user** (BLUF/Minto/Amazon/SBAR doctrine + cognitive-load, jargon, question-design and human-AI decision research); drives `commands/_shared/communication.md` + `output-styles/director.md` (ADR-018). Covers **agent↔human**.
- [[research/document-writing]] — living, source-cited evidence base for how commands write **to disk** (IEEE 830 / ISO 29148 specification rules, Diátaxis mode purity, Carroll's measured minimalism, requirements-clone and inspection-cost studies, ASD-STE100 limits); drives `commands/_shared/document-standard.md` + `bin/doc-lint.sh` (ADR-023). Covers **agent↔document**. Names the figures that have no primary source.
- [[research/subagent-token-economics]] — first-party measurement of one large fan-out run: 190M cache-read against 322K output. Drives the fan-out section of `commands/_shared/agent-conduct.md`. Covers **orchestrator↔agent**. n=1.
- `/v-cr` — automated code review on a remote PR (forge+task auto-detect, critic swarm, posts comments); see [[decisions/ADR-008-v-cr-remote-pr-review]] + [[plans/2026-06-19-1106-v-cr-command]]
- Testing critic group — `personas/_shared/testing/` (6 lenses for AI-written tests); see [[indications/testing-persona-group]]

## Sessions (recent)
- [[sessions/2026-09-02-2147-consumer-seat-and-artifact-lifecycles]] — Stop the framework producing plans that specify what gets built and never who consumes it
- [[sessions/2026-09-01-1930-vcr-coverage-receipts]] — Compute /v-cr review coverage from per-file critic receipts instead of asserting it
- [[sessions/2026-09-01-1000-vcr-delivery-and-coverage]] — Fix /v-cr comment delivery verification and coverage recording
- [[sessions/2026-09-01-0900-vpm-pm-discipline]] — Give /v-pm elicitation, a Definition of Done, an appetite instead of a task list, and a tracker that lives where the working session already looks
- [[sessions/2026-08-24-1214-docs-writing-standard-pass]] — Rewrite the seven reader-facing docs to the writing contracts
<!-- Last N session entries appended by /v-capture. -->
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
