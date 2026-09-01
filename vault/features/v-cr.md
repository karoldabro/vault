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
- **Optional `--sandbox` path** (ADR-009): isolated-execution contract `commands/v-cr/sandbox.md`; pure
  core `lib/cr-sandbox.sh` (offline-tested `tests/unit/cr-sandbox.bats`). Adds adapter op `fetch_ref`
  (`adapters.md`) + an optional dynamic-evidence bundle to `_shared/critic-panel.md`. Flags `--sandbox`,
  `--baseline`, `--allow-net-install`, `--sandbox-gc`, `--no-post`. Decision:
  [[../decisions/ADR-009-v-cr-sandboxed-execution]]; safety: [[../indications/sandboxed-cr-safety]].
- Shared panel sub-procedure `commands/_shared/critic-panel.md` (also used by v-team §5.3).
- Forge adapter interface `commands/v-cr/adapters.md` → `adapters/{github,bitbucket-cloud,bitbucket-server}.md`.
- Task-source contract → `tasks/{jira,asana,forge-issue}.md`.
- Pure logic: `lib/forge-detect.sh` (URL→platform, host allowlist, `forge_validate_host`),
  `lib/cr-helpers.sh` (`cr_fingerprint`, `cr_code_hash`, `cr_jira_keys`, `cr_asana_gids`,
  `cr_diff_stats`, `cr_vault_leak_check`, `cr_verify_posted`, `cr_coverage`).
- Persona: `personas/_shared/correctness.md`; selection wired in `personas/_resolution.md` §2.
- Tests: `tests/unit/forge-detect.bats`, `tests/unit/v-cr.bats`, `tests/unit/cr-coverage.bats`.
- Config (user/global env): `VCR_HOST_MAP` (self-hosted host→platform), `VCR_JIRA_PROJECTS` (Jira-key
  allowlist), `VCR_MAX_TOKENS`, `--max-comments`, `--post`, `--unpost`.
- Decision: [[../decisions/ADR-008-v-cr-remote-pr-review]].

## Coupling
- Depends on the shared assets `personas/_resolution.md` + `commands/_shared/critic-panel.md` + the
  vault context loader — **not** on the v-work/v-team lifecycles. v-team's `04-execute-loop.md` §5.3 now
  points at the same shared panel module (kept its own fix-and-reloop wrapper).
- `install.sh` auto-symlinks `commands/v-cr.md`, `commands/v-cr/`, `commands/_shared/` (no installer
  change). Reads the reviewed repo's vault by base-repo slug.

## Behaviors & rules
- The panel returns findings **and** a `FILES_EXAMINED` receipt per critic → `cr_coverage` diffs the
  merged receipt against the changed-file list and reports three buckets; edge: a finding list alone
  cannot separate examined-clean from never-opened, which is how a review reported coverage it had
  not earned.
- A receipt row claims `read` → its reason carries a line anchor the caller checks against the diff;
  edge: an unverifiable anchor counts as not examined, so echoing the file list back scores nothing.
- The unexamined set is non-empty → step 4's gate demands fresh confirmation and the summary names the
  paths; edge: the operator may accept the gap, recorded as `coverage_accepted`.
- One testing critic owns every changed test file → its receipt lists each one and §3.6 reports
  unexamined test files as their own count; edge: `personas/_resolution.md` §2.1 seats only one, so
  per-file assignment is unavailable.

## Gotchas
- **Idempotency fingerprint = `sha256(file:rule:code_hash)`** — never the LLM message (non-deterministic)
  or line number (rebase-fragile). Comment generation at temperature 0.
- **Untrusted input**: diff/PR-body/ticket fenced as data; verdict + post decision from the grounding
  gate, never agent prose. Secret redaction before LLM context, at the post boundary, and before capture.
- **Coverage is computed, never asserted.** `files_examined` comes from `cr_coverage`, `files_changed`
  and `changed_lines` from `cr_diff_stats`, delivery counts from `cr_verify_posted`. A field with no
  function behind it gets invented — that is how a run recorded 33 files read against a true 41 of 48.
- **Host-scoped credentials**: tokens go only to exact-match-allowlisted hosts; self-hosted needs
  confirmation; Jira/Asana base config from user/global only (SSRF guard).
- **Non-bypassable first-post gate** per `host/owner/repo#PR`; `--post` only skips re-confirmation.
- **resolve-stale** touches only bot-authored, zero-human-reply threads.
- Sourced libs avoid IFS word-splitting (zsh vs bash parity).
- **Panel spawn is mandatory + proven**: `critic-panel.md` (c) requires one real `Agent` per critic and
  reports a `Spawned:` line; an inlined panel is non-conformant. The review summary must surface
  **coverage** (reviewed/inline/silent), **test posture** (tests run only under `--sandbox`), and keep
  comments short (inline ≤3 lines). See [[../indications/cr-panel-spawn-and-visibility]].

## Sessions
- [[../sessions/2026-06-19-1132-v-cr-code-review-command]] — designed + built via /v-team design panel
- [[../sessions/2026-06-19-1605-v-cr-panel-spawn-coverage-brevity]] — enforce real panel spawn, surface coverage + test posture, tighten comments
- [[../sessions/2026-09-01-1000-vcr-delivery-and-coverage]] — verify comment delivery on the forge, record coverage durably
- [[../sessions/2026-09-01-1930-vcr-coverage-receipts]] — compute coverage from per-file critic receipts; wire cr_diff_stats
