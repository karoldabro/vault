---
type: index
project: vault
tags: [index, decisions]
---

# vault — Decisions inventory

| ID | Title | Date | Status |
|----|-------|------|--------|
| [[ADR-001-panel-loop-over-peer-debate]] | Panel→synthesize→re-loop over peer debate | 2026-06-16 | accepted |
| [[ADR-002-no-stop-on-approval-alone]] | Critique loops never converge on approval alone | 2026-06-16 | accepted |
| [[ADR-003-tool-grounded-findings]] | Persona findings are tool-grounded (confirmed vs advisory) | 2026-06-16 | accepted |
| [[ADR-004-generic-packs-specifics-in-indications]] | Generic packs; project specifics in indications | 2026-06-16 | accepted |
| [[ADR-005-installer-auto-exec]] | setup.sh auto-installs the tool stack on Ubuntu (consent-gated) | 2026-06-18 | accepted |
| [[ADR-006-testing-critic-group]] | Testing critique is a one-cluster-per-persona grounded group | 2026-06-19 | accepted |
| [[ADR-007-light-siblings-guardrail]] | Light command siblings drop the approval gate for a scope guardrail | 2026-06-19 | accepted |
| [[ADR-008-v-cr-remote-pr-review]] | /v-cr reviews remote PRs by reusing the panel single-pass, precision-first, untrusted-input | 2026-06-19 | accepted |
| [[ADR-009-v-cr-sandboxed-execution]] | /v-cr optional --sandbox path: runtime-verified review, framework-owned isolation envelope, attribution-aware test gate | 2026-06-19 | accepted |
| [[ADR-010-lifecycle-hooks-tools-rename]] | Per-project lifecycle customization via instruction-only VAULT.md hooks + tools; rename is a suggestion | 2026-06-22 | accepted |
| [[ADR-011-generative-test-design-subphase]] | Test design is a generative PROPOSE sub-phase; generators emit pre-impl, critics confirm post-impl | 2026-06-29 | accepted |
| [[ADR-012-propose-clarify-research-gates]] | PROPOSE opens with clarify + online-research front gates (shared §3a); contradicting consensus reconciled in writing | 2026-07-03 | accepted |
| [[ADR-013-v-pm-cross-project-planning]] | /v-pm plans cross-project features into a shared `_features/` blackboard workspace; file-based conversation (state-in-filename), derived ledger, auto-pickup + `/v-pm status` push, deterministic contracts-drift | 2026-07-03 | accepted |
| [[ADR-014-vpm-business-knowledge-center]] | /v-pm authors a `requirements.md` business-knowledge spec (rules REQ-NN, glossary, decision/state tables) decoupled from the coordination machinery (1+ repos; single-repo → `requirements/` category); id chain spec→backlog→established dossier; no cross-repo write | 2026-07-03 | accepted |
| [[ADR-015-retier-lifecycle-lite-critic-fast-path]] | Re-tier lifecycle: lite critic in /v-work, auto fast path, /v-team framed as escalation (usage-data driven) | 2026-07-04 | accepted |
| [[ADR-016-business-persona-family]] | Business persona family: opt-in packs (sales·seo·support·business·startup-eval), shared `business/data-evidence` numeric critic, multi-pack seating (one architect seat, §2.2 priority order, cross-pack suppression) | 2026-07-10 | accepted |
| [[ADR-017-evidence-based-panel-hardening]] | Evidence-based panel hardening: verifier tool-asymmetry corollary, pre-mortem as skeptic technique (seat rejected — correlated double-vote), minority-flag dissent surface + critic-owned grounding; catalog `research/llm-collaboration-patterns` is the living evidence reference | 2026-07-10 | accepted |
| [[ADR-018-decision-communication-contract]] | One shared `_shared/communication.md` governs all user-facing prose (bound by installed path in 12 dispatchers + 15 Required-output step files); two-layer output as a net deletion; mandatory `Impact` at gates; omit-when-empty scoped to green only; ask-gate before question shape; synthesizer caps subagent text; opt-in `director` output style; /v-cr forge rule kept (different reader); evidence in `research/decision-communication` | 2026-08-03 | accepted |
| [[ADR-019-drop-openviking-dependency]] | OpenViking dropped entirely (17 reads vs 194 writes in 60 days, four-part install); claude-mem + grep-over-vault become the context path; `/v-sync` + `/v-backfill` deleted; tool-playbook §1 removed with §§2–7 renumbering deliberately skipped; `bin/remove-openviking.sh` + docs ship as the exit path | 2026-08-03 | accepted |
| [[ADR-020-claude-code-plugin-distribution]] | Ship the framework as a Claude Code plugin alongside the `install.sh` symlink route (mutually exclusive, enforced by both installers); repo is its own single-plugin marketplace (`source: "./"`); `version` pinned so publishing is a deliberate bump; `$VAULT_FRAMEWORK_PATH` resolves `${CLAUDE_PLUGIN_ROOT}` first and is never persisted; `commands/` holds commands only; `/v-setup` is the consent-gated dependency step and the SessionStart hook detects without installing (ADR-005 line holds) | 2026-08-04 | accepted |
| [[ADR-021-install-profiles]] | Serena + Graphify demoted to developer tools: three named profiles (`--light` default / `--full` / `--minimal`), interactive prompt when no flag is passed, `[ -t 0 ]`-gated so a piped run falls to minimal rather than hanging; profile recorded as `install_mode` in `~/vault/_global/config.md`; "a light machine is not a broken machine" — detect-stack drops both tools, doctor labels them `(developer)`, tool-playbook + v-work §2.4/§2.5 + v-do read `install_mode` before offering an install | 2026-08-04 | accepted |
