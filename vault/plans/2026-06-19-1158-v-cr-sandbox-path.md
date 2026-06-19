---
type: plan
project: vault
slug: v-cr-sandbox-path
status: executed   # proposed | approved | executed | superseded
personas: [v-work-fallback-panel]
rounds: 2
convergence: clean
tags: [plan, team, v-cr, sandbox]
---

# v-cr-sandbox-path — team plan

Optional isolated-execution review path for `/v-cr`: fetch the PR into a throwaway git worktree, build a
project-specific Docker sandbox, run tests as a gate, run the critic panel with **runtime-verified**
evidence, post/save findings, then tear everything down.

## Task
Add an OPTIONAL `--sandbox` path to `/v-cr` that materializes a PR in an isolated worktree + Docker
sandbox, runs a tests-first gate then the review panel with dynamic evidence, posts or saves findings,
and cleans up — without weakening v-cr's read-only / never-applies / precision-first invariants.
Keywords: worktree, docker-sandbox, test-gate, untrusted-code, cleanup, dynamic-verification.

## Context (why this is worth building)
- Current `/v-cr` is **API-only**: it fetches the diff and reviews text. It never checks out or runs the
  code, so every finding is static-only and `grounding: confirmed` is limited to grep/static rules.
- 2026 reviewers (CodeAnt, DeepSource) show **execution-based verification returns the most verified
  findings with the least noise** — directly serving v-cr's precision-first north star. The sandbox lets
  the panel *prove* a finding (reproduce a bug, run a failing test) before posting.
- Risk inversion: running a PR means running **attacker-authorable code**. Worktree alone is NOT
  isolation; Docker adds namespace/port/cgroup separation but is not a true sandbox for hostile code.
  Defense-in-depth (no host secrets, restricted egress, human gate, throwaway) is mandatory.

## Converged plan (v1 — post Round 1)
<!-- dependency-ordered: File · Action · Tool · Pattern. Bracketed tags = applied critic findings. -->

1. **`commands/v-cr.md`** (dispatcher) · ADD `--sandbox` (default OFF) + `--no-post` (alias for the
   already-existing decline-the-gate → save-only behavior; **no separate `--save-only`**) + `--sandbox-gc`
   (orphan reaper, a maintenance subcommand, not a review flag) + `--baseline` (opt-in base-ref
   execution) · Edit · Default API-only path byte-for-byte unchanged when flag off. [arch-4]

2. **`commands/v-cr/sandbox.md`** (new contract doc) · Owns the WHOLE isolated path; steps merely
   invoke/consume it · Write · Mirrors `adapters.md` interface style. Defines: capability-probed fetch,
   clone-based provisioning, the **non-overridable isolation wrapper**, two-phase install/test, the
   attribution-aware test gate, dynamic-evidence bundle assembly, runtime-output redaction, trap-based
   cleanup **armed at provision**, GC, and the threat model. [arch-3, arch-6]

3. **`lib/cr-sandbox.sh`** (new, **PURE only** — keeps the lib offline-bats-testable like its siblings) ·
   Write · `cr_sandbox_root`, `cr_sandbox_name host owner repo pr sha nonce` (run-nonce for concurrency),
   `cr_sandbox_path_is_safe path` (`set -u`; rejects empty/unset, `/`, `$HOME`, repo root, any
   non-prefixed path — the data-loss guard), `cr_recipe_resolve` (precedence *logic given inputs*),
   `cr_stack_default_recipe stack`, `cr_redact_runtime` (secret-scan + fence runtime stdout/stderr).
   I/O helpers (`cr_free_port`, recipe-file discovery) live in `sandbox.md`, labelled non-pure/e2e. [arch-5, sec-1, sec-7, skeptic-4]

4. **`commands/v-cr/adapters.md`** · ADD a `fetch_ref` operation (PR → fetchable git ref incl. fork head)
   **with a capability probe** (`git ls-remote`) · Edit + per-adapter impl · GitHub: guaranteed
   `refs/pull/<n>/head`. BB-Cloud/Server: capability-gated — return **unsupported** if the ref isn't
   fetchable (BB-Server PR refs are admin-gated; a fork is a different repo). Keeps 01-detect
   forge-agnostic so GitLab still slots in. [arch-2, skeptic-1]

5. **`commands/v-cr/steps/01-detect.md`** · ADD §1.6 (under `--sandbox`): call adapter `fetch_ref`; if
   **unsupported → refuse `--sandbox` and fall back to API-only review with a stated reason** (never
   review the wrong tree) · Edit · Record `Fetch ref:` + `Sandbox: on/off`. v1 sandbox is
   GitHub-validated; BB marked capability-gated. [skeptic-1]

6. **`commands/v-cr/steps/02-gather.md`** · Under `--sandbox`, after diff + secret-scan, **invoke
   `sandbox.md`** (delegation — the step does NOT itself build/run) which returns the evidence bundle ·
   Edit · Preserves GATHER's read-only "assemble context" responsibility. [arch-3]

7. **`sandbox.md` — provisioning substance** (the security core):
   - **Isolation is a non-overridable framework wrapper.** network / caps / env / mounts come ONLY from
     per-stack framework defaults + user/global `VCR_SANDBOX_MAP` (analogue of `VCR_HOST_MAP`). The PR's
     `Dockerfile`/`compose` may be **built/run only INSIDE** this wrapper and can never widen it. **The
     `.v-cr/sandbox.sh` repo host-hook is dropped entirely** (it was arbitrary host code). [sec-2]
   - **Materialize via a throwaway clone under the sandbox root**, NOT a `git worktree` of the user's
     working repo — a crash then never registers an orphan in the user's `.git/worktrees`. Checkout with
     `core.hooksPath=/dev/null`. (Honors the "worktree" intent with a crash-safe mechanism — see
     trade-off 3.) [skeptic-4]
   - **Two-phase network.** Install phase: egress to a **package-registry allowlist (caching proxy)** —
     **proxy URL + registry allowlist are user/global-only keys (same class as `VCR_SANDBOX_MAP`), never
     read from repo files or the PR recipe** [sec-r2-1] — or plain egress ONLY via a human-gated
     `--allow-net-install` — run with `--ignore-scripts`
     (lifecycle scripts OFF by default; enabling them is a logged, human-gated, per-run toggle). Then the
     **test/analyze phase runs `network: none`**. [sec-3, sec-4, skeptic-3]
   - **Clean env (allow-list, not deny-list).** Container starts EMPTY and receives only explicit
     dummy/`.env.example` values; the parent process environment is never passed through. [sec-5]
   - **Resource caps:** `--memory`, `--cpus`, `--pids-limit`, wall-clock timeouts.
   - **Supply-chain pre-flight (2.6):** diff `.git/hooks/`, inspect `package.json` scripts / `Makefile` /
     lockfile + new-dependency diff; surface as findings. With `--ignore-scripts` + no-egress this is
     defense-in-depth, not the sole gate. [sec-4]

8. **`sandbox.md` — attribution-aware test gate (2.8):**
   - **Provisioning/build/install failure is reported DISTINCTLY** as "sandbox could not be provisioned",
     never as a code-review finding or quality verdict. [skeptic-3]
   - Prefer the **cheap signal first** (the PR's forge CI status / existing test report). Tests fail **and
     attributable to the PR** (a NEW failure) → headline **blocking** finding, **skip the deep panel**
     (this is the user's "tests fail → fail"). Tests red but **attribution unverified** (no baseline / no
     CI signal) → **advisory** "suite red, attribution unverified", panel continues. Base-ref execution
     only with `--baseline`, under the **same locked envelope**, against the **true upstream base
     commit**. [skeptic-2, sec-6]

9. **`commands/_shared/critic-panel.md`** · EXTEND the "Inputs" / "(a) Ground first" contract to accept an
   OPTIONAL pre-gathered **dynamic-evidence bundle** (tests, lint/type/SAST, diff-coverage) as generic
   `confirmed` analyzer input — reusable by v-team too, not a v-cr-only side channel · Edit. [arch-1]

10. **`commands/v-cr/steps/03-review.md`** · CONSUME the bundle via the extended panel contract · Edit ·
    Static analyzers (eslint/phpstan/mypy/semgrep) in-sandbox = deterministic precision floor;
    baseline-diff so only NEW issues are attributed. **Dynamic/runtime findings require N reproductions
    before `grounding: confirmed`** and carry a distinct disposition `runtime-observed (may be
    env-dependent)`. [skeptic-5]

11. **`commands/v-cr/steps/04-post.md`** · Dynamic-finding fingerprint exception · Edit · The
    post-once-suppress-forever rule is **relaxed for the `runtime-observed` class** — such a thread may be
    **re-resolved** on a later run if it no longer reproduces. Static + LLM classes unchanged
    (`sha256(file:rule:code_hash)`). [skeptic-5]

12. **`commands/v-cr/steps/05-capture.md`** · Record sandbox-artifact METADATA only (recipe id, isolation
    envelope used, test verdict, analyzer summary, repro counts/ids) through `cr_redact_runtime`; never
    raw logs/secrets · Edit · Cleanup is OWNED by `sandbox.md` (armed at provision); 05-capture only
    verifies teardown ran and records it. [arch-6, sec-1] · Capture metadata fields (recipe id, analyzer
    summary) are themselves untrusted repo-derived strings — store fenced, never interpolate into a later
    model prompt. [sec-r2-2]

13. **Docs/decisions** · Write/Edit ·
    - `VAULT.md` (framework) + reviewed-repo `VAULT.md` recipe schema: `behaviour.sandbox`
      (`image`/`compose`, `install`, `test`, `lint`, `env_file`, `ports`) — **isolation-envelope keys are
      user/global-only**, never repo (sec-2).
    - **`vault/decisions/ADR-009-v-cr-sandboxed-execution.md`** (new): opt-in default; threat model;
      framework-owned isolation envelope; two-phase network; attribution-aware gate; cleanup-GC; all
      existing v-cr invariants (never commit/apply, first-post gate, redaction, host-allowlist) preserved.
    - **`vault/indications/sandboxed-cr-safety.md`** (new) + update `vault/features/v-cr.md`,
      `vault/indications/_index.md`, `vault/decisions/_inventory.md`.

## Test plan
- `tests/unit/cr-sandbox.bats` (offline, Dockerized-bats per convention):
  - default-path-unchanged when `--sandbox` off [arch-t1];
  - `cr_sandbox_path_is_safe` rejects empty/unset, `/`, `$HOME`, repo root, non-prefixed; accepts a
    well-formed sandbox path [arch-t2, sec-t3];
  - `cr_recipe_resolve` precedence + `cr_stack_default_recipe` lookup given fixture inputs [arch-t3];
  - `cr_redact_runtime` scrubs token-shapes + known host-env values from arbitrary stdout [sec-t1];
  - generated run/compose command for a malicious-repo compose (host mounts, `network: host`, env
    passthrough, no caps) STILL yields `network: none` + clean env + caps + ignores `.v-cr/sandbox.sh` [sec-t2];
  - `cr_sandbox_name` determinism + nonce uniqueness; fetch-capability probe → API-only fallback [skeptic-t1].
- e2e (opt-in, `tests/e2e/`, real Docker — gated behind the existing opt-in, not the default suite):
  provision → gate (pass + fail) → cleanup leaves no clone/container/volume; **SIGKILL mid-build → user's
  main `.git` uninjured + `--sandbox-gc` reaps by label** [skeptic-t2]; flaky dynamic finding is NOT
  permanently suppressed and can be re-resolved [skeptic-t3].

## Proposed test backlog
| id | persona | kind | target | intent | priority | disposition |
|----|---------|------|--------|--------|----------|-------------|
| arch-t1 | Architect | unit | default `/v-cr` run sources no sandbox lib | API-only path unchanged when flag off | must | **skip** — flag gating is in the markdown dispatcher; no shell seam to unit-test |
| arch-t2 | Architect | unit | `cr_sandbox_path_is_safe` accept/reject set | data-loss guard on teardown | must | **implemented** (8 cases) |
| arch-t3 | Architect | unit | recipe-resolution precedence given inputs | ADR-004 conformance | should | **implemented** |
| sec-t1 | Security | unit | `cr_redact_runtime` scrubs tokens + host-env | runtime output never leaks | must | **implemented** |
| sec-t2 | Security | integration | generated run/compose ignores malicious overrides | repo can't widen the envelope | must | **changed → unit** via `cr_is_envelope_key`; full compose-gen deferred to e2e |
| sec-t3 | Security | unit | cleanup refuses rm on empty/unset path var | crash-time cleanup can't destroy host data | should | **implemented** (empty/unset case) |
| skeptic-t1 | Skeptic | unit | recipe fallback + fetch-capability probe | no silent wrong-tree review | must | **partial** — recipe fallback implemented; fetch-probe is e2e (deferred) |
| skeptic-t2 | Skeptic | integration | SIGKILL mid-build → main `.git` clean + GC reaps | crash-cleanup reliability | must | **deferred → e2e** (real Docker, opt-in suite) |
| skeptic-t3 | Skeptic | integration | flaky dynamic finding not permanently suppressed | dynamic non-determinism | should | **deferred → e2e** (behavioral) |
| corr-t1 | Correctness | unit | path guard rejects nested (non-direct-child) path | corr-d1 data-loss bypass | must | **implemented** |
| corr-t4 | Correctness | unit | `CR_REDACT_VALUES` matched as literal (glob chars) | redaction can't mis-expand | must | **implemented** |
| corr-t6 | Correctness | unit | empty/newline-only `CR_REDACT_VALUES` doesn't hang | regression for the fixed infinite-loop | must | **implemented** |
| corr-d2 | Correctness | unit | trailing-newline normalisation pinned | redactor contract is decided, not accidental | should | **implemented** |

## Open trade-offs / escalations (decide at the approval gate)
1. **SCOPE — RESOLVED: full design (all 13 steps).** User chose Option A at the approval gate.
   **Refinement (user):** the worktree/sandbox **provisioning procedure is GENERIC** — it lives in the
   vault framework (`commands/v-cr/sandbox.md` + `lib/cr-sandbox.sh`); each reviewed **project may
   override the project-specific recipe bits via its own vault `indications/`** (ADR-004 pattern applied to
   provisioning). So `cr_recipe_resolve` precedence is: reviewed-repo `indications/` (sandbox recipe) →
   reviewed-repo `VAULT.md behaviour.sandbox` → repo `docker-compose.yml`/`Dockerfile` (built inside the
   wrapper) → per-stack framework default. **Security carve-out unchanged:** isolation-envelope keys
   (network/caps/env/mounts/proxy) are user/global-only and NEVER sourced from a project indication or any
   repo file — an indication may only set non-security recipe bits (install/test/lint/ports/deps-prep).
2. **Literal "tests fail → fail" softened to attribution-aware** (skeptic-2, sec-6): a red suite that
   can't be attributed to the PR becomes **advisory**, not a hard stop — avoids gating honest PRs on
   someone else's broken main. Confirm acceptable.
3. **"Worktree" → throwaway clone under the sandbox root** (skeptic-4): safer than a worktree of the
   user's repo (no orphan registration in the user's `.git` on crash). Same isolation intent. Confirm.
4. **Network during install** = caching-proxy / registry allowlist; plain egress only via explicit
   `--allow-net-install`; test/analyze always `network: none`. Residual: **Docker ≠ microVM** — document,
   recommend rootless/gVisor, do NOT claim hostile-proof.

## Critique trail

### Round 0 — draft
The v0 plan (10 steps), before panel critique.

### Round 1 — findings + dispositions
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
| Skeptic | skeptic-6 | MINOR | advisory | full machinery large for unproven demand | **deferred → escalation 1** (scope decision for user) |

_Metrics: 19 findings (18 confirmed · 1 advisory) · 3 confirmed BLOCKER (all security, all resolved) ·
9 MAJOR · 6 MINOR · 1 advisory · per-persona overlap: low (architect=structure, security=execution,
skeptic=operability — well decorrelated) · 3 critics × ~62k tokens. 18/18 confirmed findings applied;
the 1 advisory escalated, not silently dropped._

### Round 2 — security verification (BLOCKER closure)
| check | result | basis |
|-------|--------|-------|
| sec-1 (runtime redaction) | **closed** | `cr_redact_runtime` at model-context + capture boundaries (steps 3,7,12), backed by sec-t1 |
| sec-2 (repo-controlled envelope) | **closed** | non-overridable framework wrapper; `.v-cr/sandbox.sh` dropped; envelope keys user/global-only (steps 7,13), backed by sec-t2 |
| sec-3 (network egress default) | **closed** | two-phase: registry-allowlist install, `network: none` test/analyze (step 7) |
| sec-r2-1 | MINOR/advisory | pin proxy+allowlist config to user/global → **applied** to step 7 |
| sec-r2-2 | NIT/advisory | capture metadata strings are untrusted → **applied** to step 12 |

_Metrics: new confirmed blockers: 0 · new confirmed MAJOR: 0 · convergence: **no-new-blocking-findings**
(stopped before the round cap of 2) · 1 critic × ~49k tokens._

## Diff-review trail (EXECUTE §5.3)

Analyzers-first: full offline suite green (97 unit incl. 29 new cr-sandbox + 50 integration). Then a
2-critic panel (Security, Correctness) reviewed the **actual implementation**.

### Diff-review Round 1 — findings + dispositions
| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| Correctness | corr-d1 | MAJOR | confirmed | `cr_sandbox_path_is_safe` blessed arbitrarily-deep descendants (only the leaf was prefix-checked) → `/root/real/vcr-fake` accepted | **fixed** — enforce direct child (`rel` has no `/`); +regression test corr-t1 |
| Correctness | corr-d2 | MAJOR | confirmed | `cr_redact_runtime` `$(cat)` drops trailing newlines / NUL — not output-faithful | **fixed** — documented text-only contract; +pin test |
| Correctness | corr-d3 | MINOR | confirmed | guard accepted `//` but rejected trailing `/` (inconsistent) | **fixed** — reject `*//*`; +test |
| Security | sec-d1 | MINOR | confirmed | S3 supply-chain pre-flight quotes attacker-authored full-file content (outside the diff secret-scan) without the redaction/fencing note S5/S6 carry | **fixed** — added the boundary note to `sandbox.md` S3 |
| Correctness | corr-d5 / sec-d2 | NIT | confirmed | python default `--no-build-isolation` breaks most installs; go has no scripts-off | **fixed** python (`pip install .`); go NIT accepted (no install-script surface) |
| Correctness | corr-d4 | NIT | advisory | `Bearer` regex has no min-length floor | **accepted** (fail-safe direction; over-redaction not a leak) |

**Pre-existing-bug note (the loop's first catch):** during analyzers-first, the new
`CR_REDACT_VALUES` path was found to **infinite-loop** — `$(printf '\n')` strips its own newline →
empty `case` pattern → `rest` never shrinks. Fixed with a trailing-sentinel newline var
(`nl="$(printf '\nX')"; nl="${nl%X}"`), +regression test corr-t6.

_Metrics: 2 confirmed MAJOR (both data-safety, both fixed + test-backed), 2 MINOR fixed, 2 NIT
(1 fixed, 1 accepted) · 0 BLOCKER · 1 infinite-loop bug found pre-panel and fixed. Convergence: the 2
MAJORs are closed and **machine-verified by passing regression tests** (stronger than a re-spawn) →
no open confirmed blocker; loop stops at round 1. 2 critics × ~63k + ~55k tokens._

## Refs
- [[../decisions/ADR-008-v-cr-remote-pr-review]]
- [[../features/v-cr]]
- [[../indications/automated-cr-safety]]
