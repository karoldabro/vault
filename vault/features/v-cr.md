---
type: feature
project: vault
slug: v-cr
status: in_progress
owners: []
tags: [feature, command, code-review]
---

# v-cr

## Scope
The **review** sibling of `/v-work` and `/v-team`: automated code review on a remote PR/MR. Auto-detects
the forge from the git remote, gathers the diff + linked task + vault knowledge, runs the tool-grounded
critic panel **single-pass**, and posts deduplicated inline + sticky-summary comments back. Read-only on
the codebase, write-only to the forge's comments. **Non-goals:** authoring/fixing code (it never commits,
pushes, or applies), webhook/CI auto-trigger (CLI on-demand only in v0), whole-repo RAG grounding.

## Contracts
- Dispatcher `commands/v-cr.md` → 5 steps `commands/v-cr/steps/01-detect..05-capture.md`.
- Shared panel sub-procedure `commands/_shared/critic-panel.md` (also used by v-team §5.3).
- Forge adapter interface `commands/v-cr/adapters.md` → `adapters/{github,bitbucket-cloud,bitbucket-server}.md`.
- Task-source contract → `tasks/{jira,asana,forge-issue}.md`.
- Pure logic: `lib/forge-detect.sh` (URL→platform, host allowlist, `forge_validate_host`),
  `lib/cr-helpers.sh` (`cr_fingerprint`, `cr_code_hash`, `cr_jira_keys`, `cr_asana_gids`).
- Persona: `personas/_shared/correctness.md`; selection wired in `personas/_resolution.md` §2.
- Tests: `tests/unit/forge-detect.bats`, `tests/unit/v-cr.bats`.
- Config (user/global env): `VCR_HOST_MAP` (self-hosted host→platform), `VCR_JIRA_PROJECTS` (Jira-key
  allowlist), `VCR_MAX_TOKENS`, `--max-comments`, `--post`, `--unpost`.
- Decision: [[../decisions/ADR-008-v-cr-remote-pr-review]].

## Coupling
- Depends on the shared assets `personas/_resolution.md` + `commands/_shared/critic-panel.md` + the
  vault context loader — **not** on the v-work/v-team lifecycles. v-team's `04-execute-loop.md` §5.3 now
  points at the same shared panel module (kept its own fix-and-reloop wrapper).
- `install.sh` auto-symlinks `commands/v-cr.md`, `commands/v-cr/`, `commands/_shared/` (no installer
  change). Reads the reviewed repo's vault by base-repo slug.

## Gotchas
- **Idempotency fingerprint = `sha256(file:rule:code_hash)`** — never the LLM message (non-deterministic)
  or line number (rebase-fragile). Comment generation at temperature 0.
- **Untrusted input**: diff/PR-body/ticket fenced as data; verdict + post decision from the grounding
  gate, never agent prose. Secret redaction before LLM context, at the post boundary, and before capture.
- **Host-scoped credentials**: tokens go only to exact-match-allowlisted hosts; self-hosted needs
  confirmation; Jira/Asana base config from user/global only (SSRF guard).
- **Non-bypassable first-post gate** per `host/owner/repo#PR`; `--post` only skips re-confirmation.
- **resolve-stale** touches only bot-authored, zero-human-reply threads.
- Sourced libs avoid IFS word-splitting (zsh vs bash parity).

## Sessions
- [[../sessions/2026-06-19-1132-v-cr-code-review-command]] — designed + built via /v-team design panel
