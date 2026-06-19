---
type: session
project: vault
date: 2026-06-19
topic: v-cr-sandbox-path
files_touched: [commands/v-cr.md, commands/v-cr/sandbox.md, lib/cr-sandbox.sh, commands/v-cr/adapters.md, commands/v-cr/steps/01-detect.md, commands/v-cr/steps/02-gather.md, commands/v-cr/steps/03-review.md, commands/v-cr/steps/04-post.md, commands/v-cr/steps/05-capture.md, commands/_shared/critic-panel.md, tests/unit/cr-sandbox.bats, vault/decisions/ADR-009-v-cr-sandboxed-execution.md, vault/indications/sandboxed-cr-safety.md]
decisions: [ADR-009]
continues: [[2026-06-19-1132-v-cr-code-review-command]]
tags: [session, v-cr, sandbox, security, v-team]
---

# v-cr-sandbox-path

## Goal
Add an optional `/v-cr --sandbox` path (designed + built via `/v-team`) that runs a PR in a throwaway
worktree/Docker sandbox for runtime-verified review, without weakening v-cr's read-only/never-applies
invariants.

## Did
- Ran the full `/v-team` lifecycle. Design panel (Software Architect · Security · Skeptic, tool-grounded)
  over 2 rounds: 18 confirmed findings, 3 security BLOCKERs (runtime-output redaction, repo-controlled
  isolation envelope, undecided egress) raised and **verified closed** in round 2.
- Internet research confirmed the thesis: **execution-based verification = most verified findings, least
  noise** (CodeAnt/DeepSource), and **worktree ≠ isolation / Docker ≠ microVM** → defense-in-depth.
- Implemented the full design (user chose full scope, with provisioning generic in the framework + per-
  project overrides via the reviewed repo's `indications/`):
  - [[../../commands/v-cr/sandbox.md]] — the S0–S7 isolated-path contract + threat model.
  - [[../../lib/cr-sandbox.sh]] — pure offline-tested helpers (name, path-guard, recipe precedence,
    envelope-key filter, runtime redaction).
  - `adapters.md` `fetch_ref` op (capability-probed); steps 01–05 + `_shared/critic-panel.md` wired for
    the `--sandbox` flag + a reusable dynamic-evidence bundle.
  - [[../../tests/unit/cr-sandbox.bats]] — 29 offline unit tests.
- Ran the `/v-team` diff-review loop (Security + Correctness on the real diff). It caught **2 confirmed
  data-safety MAJORs** + an infinite-loop bug; all fixed and pinned with regression tests.
- Committed on `feat/v-cr-sandbox` (code `df2b7ed`, vault `4aa091a`). Full offline suite green: 97 unit
  (+29 new) + 50 integration.

## Learned
- **`$(printf '\n')` strips its own trailing newline** → expands to empty → a `case "$x" in *""*)` pattern
  matches everything and the splitting loop never shrinks `rest` → **infinite hang**. Fix: the trailing-
  sentinel newline var `nl="$(printf '\nX')"; nl="${nl%X}"` (bash+zsh safe). The Dockerized bats suite
  *hung* (not failed) on this — surfaced as a 28-min orphaned container, not a red test.
- A path-safety guard that checks only `"$root"/*` **plus the leaf prefix** silently blesses
  arbitrarily-deep descendants (`/root/real/vcr-fake`). Must enforce a **direct child**:
  `rel="${path#"$root"/}"; case "$rel" in */*) return 1`.
- The diff-review loop paid for itself: the design panel approved the *plan*, but two real data-loss bugs
  only existed in the *implementation* — the catch-it-in-code round is not redundant with the design round.
- `git worktree add` against the user's working repo orphans a registration in their `.git` on crash →
  provision via a **throwaway clone** under a guarded sandbox root instead (honors "worktree" intent,
  crash-safe). Isolation-envelope keys must be framework-owned (user/global only), never from repo files;
  a project may declare only benign recipe bits (install/test/lint) via its vault `indications/`.

## Next
- e2e tests (opt-in, real Docker) still deferred: SIGKILL-mid-build cleanup, fetch-capability probe,
  malicious-compose envelope override, flaky-dynamic-finding re-resolve (skeptic-t2/t3, sec-t2 full form).
- `--sandbox` needs `VCR_SANDBOX_MAP` (+ optional per-repo `behaviour.sandbox` recipe) before first real
  run. `run install.sh` to symlink the new command files; restart to load `/v-cr --sandbox`.
- Branch `feat/v-cr-sandbox` not pushed/merged — awaiting user direction.

## Refs
- [[../decisions/ADR-009-v-cr-sandboxed-execution]]
- [[../decisions/ADR-008-v-cr-remote-pr-review]]
- [[../decisions/ADR-004-generic-packs-specifics-in-indications]]
- [[../features/v-cr]]
- [[../indications/sandboxed-cr-safety]]
- [[../indications/automated-cr-safety]]
- [[../plans/2026-06-19-1158-v-cr-sandbox-path]]
- [[2026-06-19-1132-v-cr-code-review-command]]
