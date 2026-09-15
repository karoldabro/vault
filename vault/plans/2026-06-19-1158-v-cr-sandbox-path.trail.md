---
type: trail
project: vault
plan: 2026-06-19-1158-v-cr-sandbox-path
personas: [v-work-fallback-panel]
rounds: 2
convergence: clean
tags: [trail, record]
---

# 2026-06-19-1158-v-cr-sandbox-path — process record

Contract document: `vault/plans/2026-06-19-1158-v-cr-sandbox-path.md`.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Throwaway clone under the sandbox root, `core.hooksPath=/dev/null` | `git worktree` of the user's working repo | A crash registers an orphan in the user's `.git/worktrees` |
| Framework-owned isolation wrapper; envelope keys user/global only | Repo `.v-cr/sandbox.sh` host-hook and repo-set envelope keys | The hook is arbitrary host code, and a PR could widen its own envelope |
| Two-phase network: registry-allowlist install, `network: none` test/analyze | `network: none` for the whole run | Most installs fail without egress, so every run reports a provisioning failure |
| Clean-env allow-list; container starts empty | Deny-list stripping of the parent environment | A deny-list fails open on any variable nobody thought to name |
| Attribution-aware gate; unattributable red suite is advisory | Literal "tests fail → fail" | An honest PR gets gated on someone else's broken main |
| `--no-post` as an alias for the decline-the-gate path | A separate `--save-only` flag | Two flags for one behaviour; `--sandbox-clean` also read as a review flag |
| Dynamic findings need N reproductions before `grounding: confirmed` | Treat runtime findings like static ones | Runtime output is non-deterministic, so a stable fingerprint suppresses a flake forever |
| Pure-only `lib/cr-sandbox.sh`; I/O helpers documented in `sandbox.md` | One lib holding both pure and I/O functions | The lib stops being offline-bats-testable like its siblings |
| Cleanup trap armed at provision, owned by `sandbox.md` | Cleanup in `05-capture.md` | A crash before the last step leaves the container and clone behind |

## Findings & dispositions

### Round 1

| persona | id | severity | grounding | issue (short) | disposition |
|---------|----|----------|-----------|---------------|-------------|
| Architect | arch-1 | MAJOR | confirmed | dynamic-evidence bypasses shared panel Inputs contract | **applied** → step 9 |
| Architect | arch-2 | MAJOR | confirmed | per-forge fetch refs hard-coded in 01-detect | **applied** → step 4 (`fetch_ref` op) |
| Architect | arch-3 | MAJOR | confirmed | 02-gather overloaded with build/run | **applied** → step 6 (delegate to sandbox.md) |
| Architect | arch-4 | MINOR | confirmed | `--save-only` dup; `--sandbox-clean` naming | **applied** → step 1 (`--no-post`, `--sandbox-gc`) |
| Architect | arch-5 | MINOR | confirmed | lib mixes pure + I/O fns | **applied** → step 3 (pure-only lib) |
| Architect | arch-6 | MINOR | confirmed | cleanup in last step misses crash paths | **applied** → steps 7/12 (armed at provision) |
| Security | sec-1 | BLOCKER | confirmed | runtime stdout = unredacted untrusted channel | **applied** → `cr_redact_runtime` + invariant (3,7,12) |
| Security | sec-2 | BLOCKER | confirmed | repo files set the isolation envelope | **applied** → step 7 (framework-owned wrapper; drop host-hook) |
| Security | sec-3 | BLOCKER | confirmed | default network egress undecided | **applied** → step 7 (`network: none` default, two-phase) |
| Security | sec-4 | MAJOR | confirmed | hooks-disable ≠ lifecycle-script-disable | **applied** → step 7 (`--ignore-scripts` default) |
| Security | sec-5 | MAJOR | confirmed | env stripping is deny-list (fails open) | **applied** → step 7 (clean-env allow-list) |
| Security | sec-6 | MAJOR | confirmed | baseline runs more attacker code | **applied** → step 8 (same envelope, true upstream base, opt-in) |
| Security | sec-7 | MINOR | confirmed | path-safe guard not last gate before rm | **applied** → step 3 (`set -u`, guard inside cleanup) |
| Skeptic | skeptic-1 | MAJOR | confirmed | BB-Server fork ref not reliably fetchable | **applied** → steps 4/5 (capability probe + fallback) |
| Skeptic | skeptic-2 | MAJOR | confirmed | baseline doubles cost + gates on others' red | **applied** → step 8 (attribution-aware, advisory) |
| Skeptic | skeptic-3 | MAJOR | confirmed | `network: none` breaks most installs | **applied** → step 7 (two-phase) + step 8 (distinct provision-fail) |
| Skeptic | skeptic-4 | MINOR | confirmed | worktree-of-user-repo orphans on crash | **applied** → step 7 (throwaway clone + nonce) |
| Skeptic | skeptic-5 | MAJOR | confirmed | dynamic findings non-deterministic vs stable fp | **applied** → steps 10/11 (N-repro + re-resolve class) |
| Skeptic | skeptic-6 | MINOR | advisory | full machinery large for unproven demand | **deferred** → scope decision taken by the operator |

### Round 2 — security verification

| check | result | basis |
|-------|--------|-------|
| sec-1 (runtime redaction) | **closed** | `cr_redact_runtime` at model-context + capture boundaries (steps 3,7,12), backed by sec-t1 |
| sec-2 (repo-controlled envelope) | **closed** | non-overridable framework wrapper; `.v-cr/sandbox.sh` dropped; envelope keys user/global-only (steps 7,13), backed by sec-t2 |
| sec-3 (network egress default) | **closed** | two-phase: registry-allowlist install, `network: none` test/analyze (step 7) |
| sec-r2-1 | MINOR/advisory | pin proxy+allowlist config to user/global → **applied** to step 7 |
| sec-r2-2 | NIT/advisory | capture metadata strings are untrusted → **applied** to step 12 |

### Diff-review round 1 (EXECUTE §5.3)

Analyzers ran first: the full offline suite was green at 97 unit tests, including 29 new cr-sandbox
cases, plus 50 integration tests. A two-seat panel (Security, Correctness) then read the built code.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| Correctness | corr-d1 | MAJOR | confirmed | `cr_sandbox_path_is_safe` blessed arbitrarily-deep descendants (only the leaf was prefix-checked) → `/root/real/vcr-fake` accepted | **fixed** — enforce direct child (`rel` has no `/`); +regression test corr-t1 |
| Correctness | corr-d2 | MAJOR | confirmed | `cr_redact_runtime` `$(cat)` drops trailing newlines / NUL — not output-faithful | **fixed** — documented text-only contract; +pin test |
| Correctness | corr-d3 | MINOR | confirmed | guard accepted `//` but rejected trailing `/` (inconsistent) | **fixed** — reject `*//*`; +test |
| Security | sec-d1 | MINOR | confirmed | S3 supply-chain pre-flight quotes attacker-authored full-file content (outside the diff secret-scan) without the redaction/fencing note S5/S6 carry | **fixed** — added the boundary note to `sandbox.md` S3 |
| Correctness | corr-d5 / sec-d2 | NIT | confirmed | python default `--no-build-isolation` breaks most installs; go has no scripts-off | **fixed** python (`pip install .`); go NIT accepted (no install-script surface) |
| Correctness | corr-d4 | NIT | advisory | `Bearer` regex has no min-length floor | **accepted** (fail-safe direction; over-redaction not a leak) |

The `CR_REDACT_VALUES` infinite loop surfaced during the analyzer run, before the panel read anything:
`$(printf '\n')` strips its own newline, the `case` pattern goes empty, and `rest` never shrinks.
The fix pins a trailing sentinel, `nl="$(printf '\nX')"; nl="${nl%X}"`, with regression test corr-t6.

## Metrics

| measure | round 1 | round 2 | diff-review round 1 |
|---|---|---|---|
| findings | 19 | 5 | 6 |
| confirmed BLOCKER | 3 | 0 | 0 |
| confirmed MAJOR | 9 | 0 | 2 |
| confirmed MINOR | 6 | 0 | 2 |
| advisory | 1 | 2 | 1 |
| dispositioned `applied` or `fixed` | 18/18 confirmed | all | 5/6 |
| persona overlap | low — architect=structure, security=execution, skeptic=operability | n/a, single seat | low — correctness=data safety, security=untrusted input |
| previously-confirmed findings dropped (sycophancy flag) | 0 | 0 | 0 |
| seats × token cost | 3 × ~62k | 1 × ~49k | 2 × ~63k + ~55k |
| stop reason | round cap not reached | no new blocking findings | both MAJORs closed by passing regression tests |

## Advisory test hints

| id | persona | target |
|----|---------|--------|
| arch-t1 | Architect | default `/v-cr` run sources no sandbox lib |
| arch-t2 | Architect | `cr_sandbox_path_is_safe` accept/reject set |
| arch-t3 | Architect | recipe-resolution precedence given inputs |
| sec-t1 | Security | `cr_redact_runtime` scrubs tokens + host-env |
| sec-t2 | Security | generated run/compose ignores malicious overrides |
| sec-t3 | Security | cleanup refuses rm on empty/unset path var |
| skeptic-t1 | Skeptic | recipe fallback + fetch-capability probe |
| skeptic-t2 | Skeptic | SIGKILL mid-build → main `.git` clean + GC reaps |
| skeptic-t3 | Skeptic | flaky dynamic finding not permanently suppressed |
| corr-t1 | Correctness | path guard rejects nested (non-direct-child) path |
| corr-t4 | Correctness | `CR_REDACT_VALUES` matched as literal (glob chars) |
| corr-t6 | Correctness | empty/newline-only `CR_REDACT_VALUES` does not hang |
| corr-d2 | Correctness | trailing-newline normalisation pinned |

The plan's `## Test backlog` is the authoritative list; these are the proposals it reconciled.

## Rejected / deferred

The draft carried 10 steps. It reviewed a PR inside a `git worktree` of the user's own repo, let the
repo supply its own isolation settings through a `.v-cr/sandbox.sh` host-hook, ran everything with
plain egress, and failed any PR whose suite was red. The Decisions table above carries what replaced
each of those.

A narrower scope was live at the approval gate: ship only the test-gate and skip the panel-facing
dynamic-evidence path. The full 13-step design was chosen instead.
