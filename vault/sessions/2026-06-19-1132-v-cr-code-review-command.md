---
type: session
project: vault
date: 2026-06-19
topic: v-cr automated code-review command
files_touched: [commands/v-cr.md, commands/v-cr/steps/01-detect.md, commands/v-cr/steps/02-gather.md, commands/v-cr/steps/03-review.md, commands/v-cr/steps/04-post.md, commands/v-cr/steps/05-capture.md, commands/_shared/critic-panel.md, commands/v-cr/adapters.md, commands/v-cr/adapters/github.md, commands/v-cr/adapters/bitbucket-cloud.md, commands/v-cr/adapters/bitbucket-server.md, commands/v-cr/tasks/jira.md, commands/v-cr/tasks/asana.md, commands/v-cr/tasks/forge-issue.md, personas/_shared/correctness.md, personas/_resolution.md, commands/v-team/steps/04-execute-loop.md, commands/README.md, lib/forge-detect.sh, lib/cr-helpers.sh, tests/unit/forge-detect.bats, tests/unit/v-cr.bats]
decisions: [ADR-008-v-cr-remote-pr-review]
tags: [session, code-review, v-cr, command]
---

# v-cr automated code-review command

## Goal
Design and build `/v-cr` — a new framework command that auto-detects the forge (GitHub/Bitbucket) and
linked task (Jira/Asana/issue), deploys a critic swarm to review a PR/MR, and posts grounded comments
back — informed by how other companies do automated code review.

## Did
- Built via `/v-team` (full lifecycle: analyze → context → propose-panel → approval → execute → capture).
- **Research** (2 deep-research agents, web): mapped the 2026 automated-CR landscape — CodeRabbit,
  Greptile, Qodo/PR-Agent, GitHub Copilot review, Graphite, Cursor Bugbot, Sourcery, Bito, Ellipsis,
  Korbit, Codacy, Gemini + the CLI/API mechanics for posting to GitHub/GitLab/Bitbucket + Jira linkage.
- **Design panel** (3 critics: Software Architect, Skeptic, Security) reviewed plan v0. Security returned
  **BLOCK** (3 confirmed blockers); Architect + Skeptic **REQUEST_CHANGES** (11 confirmed MAJORs). All 22
  findings applied into plan v1 — see [[../plans/2026-06-19-1106-v-cr-command]] critique trail.
- Implemented the command: thin dispatcher [[../../commands/v-cr.md]] + 5 steps (DETECT → GATHER →
  REVIEW → POST → CAPTURE); extracted the single-pass panel into
  [[../../commands/_shared/critic-panel.md]] (shared with v-team §5.3); forge adapters
  (`v-cr/adapters/{github,bitbucket-cloud,bitbucket-server}`) + task sources
  (`v-cr/tasks/{jira,asana,forge-issue}`); new `correctness` bug-hunter lens wired into `_resolution.md`.
- Pure logic extracted to `lib/forge-detect.sh` (URL→platform parse, host allowlist) + `lib/cr-helpers.sh`
  (stable fingerprint, allowlisted Jira-key extraction). **19 new bats tests; full suite 118/118 green.**
- Committed on branch `feat/v-cr-command` (5e2140f feat, 7d8842d docs). Not pushed.

## Learned
- **The 2026 reference CR architecture ≈ v-team's panel already**: deterministic linters as a precision
  floor → parallel specialised critics → a *generate-then-verify* confidence filter → summary + inline
  comments, precision-first ("say nothing when unsure" — Copilot is silent in 29% of reviews). The
  novelty was I/O (forge adapters) + task grounding, not the review engine.
- **Don't reuse v-team's `04-execute-loop` §5.3 wholesale** — it's a *fix-and-reloop* (3 of 5 steps:
  implement / apply-fixes / re-spawn) that's meaningless against a static remote PR. Extract the
  single-pass sub-procedure to `_shared/critic-panel.md`; v-team wraps it in its fix loop, v-cr runs it
  once. (arch-1 / skeptic-1 / skeptic-9.)
- **Sourced shell libs must not rely on IFS word-splitting** — zsh doesn't split unquoted `$VAR`, so the
  `VCR_HOST_MAP` loop collapsed under the user's zsh while working in bash. Fixed with a portable
  `${rest%%;*}` split loop. (Tests run under bash-in-Docker; the command runs in the host zsh — both must
  agree.)
- **Comment idempotency must key on stable signals**: `sha256(file:rule:code_hash)`, never the LLM
  message text (non-deterministic → double-posts) and never the line number (shifts on rebase).
- **Untrusted-input is the dominant CR security risk**: the diff/PR-body/ticket are attacker-authorable;
  the verdict + post decision must come from the machine-checked grounding gate, not agent prose.
- ADR number collision: `ADR-007` was already taken (light-siblings) — this one is **ADR-008**.

## Next
- Manual end-to-end dry-run per forge where creds exist (the `*-t1/t2/t3` integration tests are
  spec-only offline — prompt-injection, token-leak, SSRF-no-egress, resolve-stale safety).
- v1 candidates: GitLab adapter (contract is forge-agnostic), webhook/CI auto-trigger, whole-repo RAG
  grounding, auto-suppression of recurring nits.
- Merge `feat/v-cr-command` when reviewed.

## Refs
- [[../decisions/ADR-008-v-cr-remote-pr-review]]
- [[../plans/2026-06-19-1106-v-cr-command]]
- [[../features/v-cr]]
- [[../decisions/ADR-001-panel-loop-over-peer-debate]] · [[../decisions/ADR-003-tool-grounded-findings]]
- [[../indications/automated-cr-safety]]
