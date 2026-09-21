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
- [[decisions/ADR-001-panel-loop-over-peer-debate]] · [[decisions/ADR-002-no-stop-on-approval-alone]] · [[decisions/ADR-003-tool-grounded-findings]] · [[decisions/ADR-004-generic-packs-specifics-in-indications]] · [[decisions/ADR-005-installer-auto-exec]] · [[decisions/ADR-006-testing-critic-group]] · [[decisions/ADR-008-v-cr-remote-pr-review]] · [[decisions/ADR-016-business-persona-family]] · [[decisions/ADR-017-evidence-based-panel-hardening]] · [[decisions/ADR-018-decision-communication-contract]] · [[decisions/ADR-026-mechanical-session-gates]] · [[decisions/ADR-030-framework-extension-points]]

## Architecture

- [[architecture/plugin-extension-contract]] — the three file formats a plugin ships, and how a point is executed.
- [[architecture/session-gates]] — what `bin/gate.sh` refuses, when, and on what evidence.

## Indications
- See [[indications/_index]] — v-team authoring rules (persona factoring, loop stops, grounded findings)

## Features
<!-- Link to [[features/]] folder. Active features: -->
- [[features/session-continuity]] — `/v-handoff` writes what the next session continues into `handoffs/`; `/v-report` files a problem found during other work into `reports/`. Both are read by `commands/v-work/steps/02-load-context.md` §2.6a before the first edit
- [[features/plugin-extensions]] — two points so a separate repo extends this framework: `init` at per-repo onboarding, `dod-keys` at the config gate; see [[decisions/ADR-030-framework-extension-points]]
- [[features/v-team]] — persona-critique dev lifecycle command
- [[features/v-loop]] — autonomous campaign engine. The loop is the command; the task is an adapter. See [[decisions/ADR-030-task-agnostic-campaign-engine]]
- [[features/v-method]] — writes the method for one heavy task. Ordered stages, each with its command, seats, tools, exit evidence and a kill criterion. Runs no stage. See [[decisions/ADR-029-methodology-command]]
- [[features/v-pm]] — cross-project planning + business-logic requirements knowledge center; see [[decisions/ADR-013-v-pm-cross-project-planning]] + [[decisions/ADR-014-vpm-business-knowledge-center]]
- [[research/llm-collaboration-patterns]] — living, source-cited catalog of LLM collaboration patterns (dev/marketing/sales/planning/support + foundations); evidence reference for panel-mechanism changes (ADR-017). Covers **agent↔agent**.
- [[research/decision-communication]] — living, source-cited evidence base for how commands write **to the user** (BLUF/Minto/Amazon/SBAR doctrine + cognitive-load, jargon, question-design and human-AI decision research); drives `commands/_shared/communication.md` + `output-styles/director.md` (ADR-018). Covers **agent↔human**.
- [[research/document-writing]] — living, source-cited evidence base for how commands write **to disk**. Sources: IEEE 830 / ISO 29148, Diátaxis, Carroll's minimalism, requirements-clone and inspection-cost studies, ASD-STE100. Drives `commands/_shared/document-standard.md` + `bin/doc-lint.sh` (ADR-023). Covers **agent↔document**. Names the figures that have no primary source.
- [[research/subagent-token-economics]] — first-party measurement of one large fan-out run: 190M cache-read against 322K output. Drives the fan-out section of `commands/_shared/agent-conduct.md`. Covers **orchestrator↔agent**. n=1.
- `/v-cr` — automated code review on a remote PR (forge+task auto-detect, critic swarm, posts comments); see [[decisions/ADR-008-v-cr-remote-pr-review]] + [[plans/2026-06-19-1106-v-cr-command]]
- Testing critic group — `personas/_shared/testing/` (6 lenses for AI-written tests); see [[indications/testing-persona-group]]

## Sessions (recent)
- [[sessions/2026-09-21-1015-architecture-first-planning-s1-s2]] — Plan architecture-first planning as a nine-session master plan; build S1 and S2 (spec contract and gate)
- [[sessions/2026-09-15-0939-readme-rewrite-and-docs-cleanup]] — Rewrite README.md for a human reader and erase the retired memory dependency from the repo
- [[sessions/2026-09-14-1904-handoff-and-report-commands]] — Two commands so a session can hand its direction to the next one, and a problem found mid-task can be filed instead of derailing the work
- [[sessions/2026-09-14-1433-plugin-extension-points]] — Two framework extension points, and the code-quality gate split into its own repo as their first consumer
- [[sessions/2026-09-13-1447-coverage-gate-and-failed-sessions]] — coverage gate: a session that cannot reach its own success criteria fails instead of asking for approval; claim ledger and methodology command designed and deferred
<!-- Last N session entries appended by /v-capture. -->
- [[sessions/2026-07-03-1559-vpm-business-knowledge-center]] — /v-pm authors a `requirements.md` business-logic knowledge center for one or more repos: rules REQ-NN with axis tags, a glossary, and decision/state tables. Adds the single-repo `requirements/` category. The id chain reaches the established `features/` dossier at shared /v-capture §5b (ADR-014)
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
