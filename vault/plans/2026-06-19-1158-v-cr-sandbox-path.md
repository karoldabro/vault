---
type: plan
project: vault
slug: v-cr-sandbox-path
status: executed   # proposed | approved | executed | superseded
process_record: 2026-06-19-1158-v-cr-sandbox-path.trail.md
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

## Plan
<!-- dependency-ordered: File · Action · Tool · Pattern. -->

1. **`commands/v-cr.md`** (dispatcher) · ADD `--sandbox` (default OFF) + `--no-post` (alias for the
   already-existing decline-the-gate → save-only behavior; **no separate `--save-only`**) + `--sandbox-gc`
   (orphan reaper, a maintenance subcommand, not a review flag) + `--baseline` (opt-in base-ref
   execution) · Edit · Default API-only path byte-for-byte unchanged when flag off.

2. **`commands/v-cr/sandbox.md`** (new contract doc) · Owns the WHOLE isolated path; steps merely
   invoke/consume it · Write · Mirrors `adapters.md` interface style. Defines: capability-probed fetch,
   clone-based provisioning, the **non-overridable isolation wrapper**, two-phase install/test, the
   attribution-aware test gate, dynamic-evidence bundle assembly, runtime-output redaction, trap-based
   cleanup **armed at provision**, GC, and the threat model.

3. **`lib/cr-sandbox.sh`** (new, **PURE only** — keeps the lib offline-bats-testable like its siblings) ·
   Write · `cr_sandbox_root`, `cr_sandbox_name host owner repo pr sha nonce` (run-nonce for concurrency),
   `cr_sandbox_path_is_safe path` (`set -u`; rejects empty/unset, `/`, `$HOME`, repo root, any
   non-prefixed path — the data-loss guard), `cr_recipe_resolve` (precedence *logic given inputs*),
   `cr_stack_default_recipe stack`, `cr_redact_runtime` (secret-scan + fence runtime stdout/stderr).
   I/O helpers (`cr_free_port`, recipe-file discovery) live in `sandbox.md`, labelled non-pure/e2e.

4. **`commands/v-cr/adapters.md`** · ADD a `fetch_ref` operation (PR → fetchable git ref incl. fork head)
   **with a capability probe** (`git ls-remote`) · Edit + per-adapter impl · GitHub: guaranteed
   `refs/pull/<n>/head`. BB-Cloud/Server: capability-gated — return **unsupported** if the ref isn't
   fetchable (BB-Server PR refs are admin-gated; a fork is a different repo). Keeps 01-detect
   forge-agnostic so GitLab still slots in.

5. **`commands/v-cr/steps/01-detect.md`** · ADD §1.6 (under `--sandbox`): call adapter `fetch_ref`; if
   **unsupported → refuse `--sandbox` and fall back to API-only review with a stated reason** (never
   review the wrong tree) · Edit · Record `Fetch ref:` + `Sandbox: on/off`. v1 sandbox is
   GitHub-validated; BB marked capability-gated.

6. **`commands/v-cr/steps/02-gather.md`** · Under `--sandbox`, after diff + secret-scan, **invoke
   `sandbox.md`** (delegation — the step does NOT itself build/run) which returns the evidence bundle ·
   Edit · Preserves GATHER's read-only "assemble context" responsibility.

7. **`sandbox.md` — provisioning substance** (the security core):
   - **Isolation is a non-overridable framework wrapper.** network / caps / env / mounts come ONLY from
     per-stack framework defaults + user/global `VCR_SANDBOX_MAP` (analogue of `VCR_HOST_MAP`). The PR's
     `Dockerfile`/`compose` may be **built/run only INSIDE** this wrapper and can never widen it. **The
     `.v-cr/sandbox.sh` repo host-hook is dropped entirely** — it is arbitrary host code.
   - **Materialize via a throwaway clone under the sandbox root**, NOT a `git worktree` of the user's
     working repo — a crash then never registers an orphan in the user's `.git/worktrees`. Checkout with
     `core.hooksPath=/dev/null`.
   - **Two-phase network.** Install phase: egress to a **package-registry allowlist (caching proxy)** —
     **proxy URL + registry allowlist are user/global-only keys (same class as `VCR_SANDBOX_MAP`), never
     read from repo files or the PR recipe** — or plain egress ONLY via a human-gated
     `--allow-net-install` — run with `--ignore-scripts`
     (lifecycle scripts OFF by default; enabling them is a logged, human-gated, per-run toggle). Then the
     **test/analyze phase runs `network: none`**.
   - **Clean env (allow-list, not deny-list).** Container starts EMPTY and receives only explicit
     dummy/`.env.example` values; the parent process environment is never passed through.
   - **Resource caps:** `--memory`, `--cpus`, `--pids-limit`, wall-clock timeouts.
   - **Supply-chain pre-flight (2.6):** diff `.git/hooks/`, inspect `package.json` scripts / `Makefile` /
     lockfile + new-dependency diff; surface as findings. With `--ignore-scripts` + no-egress this is
     defense-in-depth, not the sole gate.

8. **`sandbox.md` — attribution-aware test gate (2.8):**
   - **Provisioning/build/install failure is reported DISTINCTLY** as "sandbox could not be provisioned",
     never as a code-review finding or quality verdict.
   - Prefer the **cheap signal first** (the PR's forge CI status / existing test report). Tests fail **and
     attributable to the PR** (a NEW failure) → headline **blocking** finding, and **skip the deep panel**.
     Tests red but **attribution unverified** (no baseline / no
     CI signal) → **advisory** "suite red, attribution unverified", panel continues. Base-ref execution
     only with `--baseline`, under the **same locked envelope**, against the **true upstream base
     commit**.

9. **`commands/_shared/critic-panel.md`** · EXTEND the "Inputs" / "(a) Ground first" contract to accept an
   OPTIONAL pre-gathered **dynamic-evidence bundle** (tests, lint/type/SAST, diff-coverage) as generic
   `confirmed` analyzer input — reusable by v-team too, not a v-cr-only side channel · Edit.

10. **`commands/v-cr/steps/03-review.md`** · CONSUME the bundle via the extended panel contract · Edit ·
    Static analyzers (eslint/phpstan/mypy/semgrep) in-sandbox = deterministic precision floor;
    baseline-diff so only NEW issues are attributed. **Dynamic/runtime findings require N reproductions
    before `grounding: confirmed`** and carry a distinct disposition `runtime-observed (may be
    env-dependent)`.

11. **`commands/v-cr/steps/04-post.md`** · Dynamic-finding fingerprint exception · Edit · The
    post-once-suppress-forever rule is **relaxed for the `runtime-observed` class** — such a thread may be
    **re-resolved** on a later run if it no longer reproduces. Static + LLM classes unchanged
    (`sha256(file:rule:code_hash)`).

12. **`commands/v-cr/steps/05-capture.md`** · Record sandbox-artifact METADATA only (recipe id, isolation
    envelope used, test verdict, analyzer summary, repro counts/ids) through `cr_redact_runtime`; never
    raw logs/secrets · Edit · Cleanup is OWNED by `sandbox.md` (armed at provision); 05-capture only
    verifies teardown ran and records it. · Capture metadata fields (recipe id, analyzer
    summary) are themselves untrusted repo-derived strings — store fenced, never interpolate into a later
    model prompt.

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
  - default-path-unchanged when `--sandbox` off;
  - `cr_sandbox_path_is_safe` rejects empty/unset, `/`, `$HOME`, repo root, non-prefixed; accepts a
    well-formed sandbox path;
  - `cr_recipe_resolve` precedence + `cr_stack_default_recipe` lookup given fixture inputs;
  - `cr_redact_runtime` scrubs token-shapes + known host-env values from arbitrary stdout;
  - generated run/compose command for a malicious-repo compose (host mounts, `network: host`, env
    passthrough, no caps) STILL yields `network: none` + clean env + caps + ignores `.v-cr/sandbox.sh`;
  - `cr_sandbox_name` determinism + nonce uniqueness; fetch-capability probe → API-only fallback.
- e2e (opt-in, `tests/e2e/`, real Docker — gated behind the existing opt-in, not the default suite):
  provision → gate (pass + fail) → cleanup leaves no clone/container/volume; **SIGKILL mid-build → user's
  main `.git` uninjured + `--sandbox-gc` reaps by label**; flaky dynamic finding is NOT
  permanently suppressed and can be re-resolved.

## Test backlog
| id | kind | target | intent | priority | disposition |
|----|------|--------|--------|----------|-------------|
| arch-t1 | unit | default `/v-cr` run sources no sandbox lib | API-only path unchanged when flag off | must | **skip** — flag gating is in the markdown dispatcher; no shell seam to unit-test |
| arch-t2 | unit | `cr_sandbox_path_is_safe` accept/reject set | data-loss guard on teardown | must | **implemented** (8 cases) |
| arch-t3 | unit | recipe-resolution precedence given inputs | ADR-004 conformance | should | **implemented** |
| sec-t1 | unit | `cr_redact_runtime` scrubs tokens + host-env | runtime output never leaks | must | **implemented** |
| sec-t2 | integration | generated run/compose ignores malicious overrides | repo can't widen the envelope | must | **changed → unit** via `cr_is_envelope_key`; full compose-gen deferred to e2e |
| sec-t3 | unit | cleanup refuses rm on empty/unset path var | crash-time cleanup can't destroy host data | should | **implemented** (empty/unset case) |
| skeptic-t1 | unit | recipe fallback + fetch-capability probe | no silent wrong-tree review | must | **partial** — recipe fallback implemented; fetch-probe is e2e (deferred) |
| skeptic-t2 | integration | SIGKILL mid-build → main `.git` clean + GC reaps | crash-cleanup reliability | must | **deferred → e2e** (real Docker, opt-in suite) |
| skeptic-t3 | integration | flaky dynamic finding not permanently suppressed | dynamic non-determinism | should | **deferred → e2e** (behavioral) |
| corr-t1 | unit | path guard rejects nested (non-direct-child) path | data-loss bypass on deep descendants | must | **implemented** |
| corr-t4 | unit | `CR_REDACT_VALUES` matched as literal (glob chars) | redaction can't mis-expand | must | **implemented** |
| corr-t6 | unit | empty/newline-only `CR_REDACT_VALUES` doesn't hang | regression for the redactor infinite loop | must | **implemented** |
| corr-d2 | unit | trailing-newline normalisation pinned | redactor contract is decided, not accidental | should | **implemented** |

## Recipe resolution and the isolation carve-out

Scope is the full design: all 13 steps. The provisioning procedure is generic and lives in the
framework, at `commands/v-cr/sandbox.md` and `lib/cr-sandbox.sh`. Each reviewed project may override
the project-specific recipe bits through its own vault `indications/`, which is the ADR-004 pattern
applied to provisioning.

`cr_recipe_resolve` precedence, highest first:

1. reviewed-repo `indications/` sandbox recipe;
2. reviewed-repo `VAULT.md behaviour.sandbox`;
3. repo `docker-compose.yml` / `Dockerfile`, built inside the wrapper;
4. per-stack framework default.

**Security carve-out.** Isolation-envelope keys — network, caps, env, mounts, proxy — are
user/global only. They are NEVER sourced from a project indication or from any repo file. An
indication may set only non-security recipe bits: install, test, lint, ports, deps-prep.

## Open decisions

1. **Attribution-aware gate instead of a literal "tests fail → fail".** A red suite that cannot be
   attributed to the PR is advisory, not a hard stop. This avoids gating an honest PR on someone
   else's broken main. Confirm acceptable.
2. **Throwaway clone under the sandbox root instead of a worktree of the user's repo.** Same
   isolation intent, and no orphan registered in the user's `.git` on crash. Confirm acceptable.
3. **Network during install** is a caching proxy over a registry allowlist. Plain egress requires an
   explicit `--allow-net-install`. Test and analyze phases always run `network: none`.
   Residual risk: Docker is not a microVM. Document that, recommend rootless or gVisor, and do NOT
   claim the sandbox is hostile-proof.

## Guard contracts (`lib/cr-sandbox.sh`)

Each line is a contract the implementation must hold and a named test that pins it.

- `cr_sandbox_path_is_safe` accepts only a DIRECT child of the sandbox root. The path relative to the
  root must contain no `/`. A deeper descendant such as `/root/real/vcr-fake` is rejected, because
  prefix-checking the leaf alone blesses it. Test: corr-t1.
- `cr_sandbox_path_is_safe` rejects any path containing `//` and any path with a trailing `/`.
- `cr_redact_runtime` carries a text-only contract: trailing newlines are normalised, and NUL is not
  carried through. Pin the normalisation in a test rather than leaving it accidental. Test: corr-d2.
- `CR_REDACT_VALUES` entries match as literal strings. Glob characters must never expand. Test: corr-t4.
- **Failure mode:** an empty or newline-only `CR_REDACT_VALUES` must not send `cr_redact_runtime` into an infinite loop.
  Pin a trailing sentinel newline (`nl="$(printf '\nX')"; nl="${nl%X}"`). Test: corr-t6.
- The `Bearer` token regex has no minimum-length floor. Over-redaction is the accepted direction.
- `commands/v-cr/sandbox.md` S3 (supply-chain pre-flight) quotes attacker-authored whole files, which
  the diff secret-scan never sees. S3 carries the same redaction and fencing note as S5 and S6.
- Python install uses `pip install .`. `--no-build-isolation` is not the default: it breaks most
  installs. Go has no install-script surface, so it needs no scripts-off flag.

## Refs
- [[../decisions/ADR-008-v-cr-remote-pr-review]]
- [[../features/v-cr]]
- [[../indications/automated-cr-safety]]
- Process record: `vault/plans/2026-06-19-1158-v-cr-sandbox-path.trail.md` — findings, dispositions, rejected options.
