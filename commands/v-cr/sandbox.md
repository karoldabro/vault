# v-cr sandbox — isolated execution path (the `--sandbox` contract)

The optional path that lets `/v-cr` **run** the PR instead of only reading its diff: fetch the PR into a
throwaway clone, build a locked-down Docker sandbox, run a tests-first gate, hand the panel
**runtime-verified** evidence, then tear everything down. Default **OFF** — `/v-cr` without `--sandbox`
is unchanged (API-only). This doc is the contract the pipeline steps delegate to; pure helpers live in
`lib/cr-sandbox.sh` (offline-tested), the I/O lives here (e2e-tested).

**Why it exists.** Execution-based verification returns the most verified findings with the least noise
(CodeAnt/DeepSource, 2026) — it is the precision multiplier for v-cr's precision-first north star. The
panel can *prove* a finding (reproduce a bug, run a failing test) before posting.

**Why it is dangerous.** It runs **attacker-authorable code**. A git worktree alone is NOT isolation;
Docker adds namespace/cgroup/port separation but is **not a true sandbox for hostile code**. The posture
is therefore *make escape irrelevant*: no host secrets in the sandbox, no egress during execution, a
human gate on every write, everything throwaway. See `vault/decisions/ADR-009-v-cr-sandboxed-execution.md`
and `vault/indications/sandboxed-cr-safety.md`.

**Invariants preserved.** Everything ADR-008 fixed still holds: never commit/push/apply; untrusted input
fenced as data; verdict + post decision from the grounding gate, not prose; secret redaction; host-scoped
credentials; non-bypassable first-post gate; stable `sha256(file:rule:code_hash)` fingerprints.

---

## S0 — the non-overridable isolation envelope (sec-2)

The sandbox's security boundary is **framework-owned** and assembled here from **per-stack defaults +
user/global config only**. It is NEVER read from a repo file or a project indication:

- `VCR_SANDBOX_MAP` (user/global env, analogue of `VCR_HOST_MAP`) and the per-stack defaults from
  `cr_stack_default_recipe` set: **network**, **resource caps** (`--memory`, `--cpus`, `--pids-limit`),
  **env passthrough policy**, **mounts**, **proxy URL + registry allowlist**.
- A project may declare only **benign recipe bits** (install/test/lint/ports/build/image) via its vault
  `indications/` or `VAULT.md behaviour.sandbox`. Before merging any repo/indication recipe, drop every
  key for which `cr_is_envelope_key <key>` returns 0.
- A PR's own `Dockerfile`/`compose` may be **built and run only INSIDE** this envelope — it can never
  widen it. Any `network: host`, host mount, env passthrough, `privileged`, or cap-add it requests is
  ignored; the framework wrapper is applied as the outer, authoritative spec.
- **The repo `.v-cr/sandbox.sh` host-hook does not exist** — it would be arbitrary code on the host.

Defaults: `network: none`; clean (empty) env; `--pids-limit` + memory/cpu caps; read-only source mount
where the stack allows; non-root container user.

## S1 — fetch the PR ref (capability-probed; via the adapter)

Provisioning needs a **fetchable git ref**, resolved through the adapter `fetch_ref` op
(`commands/v-cr/adapters.md`), not hard-coded here:

- **GitHub** — `refs/pull/<n>/head` (guaranteed, incl. fork heads). Validated path for v1.
- **Bitbucket Cloud / Server** — capability-gated. The op probes with `git ls-remote <remote>
  <candidate-ref>`; if the ref is absent (BB-Server PR refs are admin-gated; a fork is a different repo),
  the op returns **unsupported**.

If `fetch_ref` returns unsupported → **refuse `--sandbox`, fall back to API-only review, and say why**
(step 1 §1.6). Never review a tree that isn't the PR's.

## S2 — provision the clone (skeptic-4)

- Materialize under `cr_sandbox_root`, in a directory named `cr_sandbox_name <host> <owner> <repo> <pr>
  <sha> <nonce>` (nonce = `$$` or a run id, so concurrent runs don't collide). **Use a throwaway clone /
  detached fetch — NOT `git worktree add` against the user's working repo**, so a crash never registers
  an orphan in the user's `.git/worktrees`.
- Fetch only the PR ref (shallow where possible) and check it out with hooks disabled:
  `git -c core.hooksPath=/dev/null ...`.
- **Arm teardown NOW** (S7), before any build — a trap so a crash at any later stage still cleans up.

## S3 — supply-chain pre-flight (sec-4)

Before building, statically inspect the materialized tree and surface anything dangerous as a review
finding (not an auto-fail):

- `.git/hooks/` diff vs empty (any committed hook is suspicious);
- `package.json` `preinstall`/`postinstall`/`prepare` scripts, `Makefile` targets the test cmd invokes;
- the lockfile diff + any newly-added dependency.

This is defense-in-depth layered with S4's `--ignore-scripts` + `network: none`, not the sole gate.
The inspected content (a `postinstall` body, a committed hook, a new dep) is attacker-authored **full-file**
content outside the 02-gather §2.2 diff secret-scan — so any S3 finding that quotes it must be
`cr_redact_runtime`-scrubbed AND fenced as untrusted data before it reaches a critic/comment/capture
(same boundary as S5/S6 runtime output; sec-d1).

## S4 — build / install (two-phase network; sec-3, sec-5, skeptic-3)

1. **Install phase (the only networked phase).** Egress restricted to the **package-registry allowlist /
   caching proxy** from `VCR_SANDBOX_MAP` (user/global only). Run with lifecycle scripts **off**
   (`npm/pnpm --ignore-scripts`, `composer --no-scripts`, `pip --no-build-isolation` etc. — see
   `cr_stack_default_recipe`). Plain unrestricted egress requires the explicit, human-gated
   `--allow-net-install`; enabling lifecycle scripts is likewise a logged, off-by-default per-run toggle.
2. **Execution phase.** Drop to **`network: none`**, clean env, resource caps, for everything in S5–S6.

**Env is allow-list, never deny-list (sec-5).** The container starts EMPTY and receives only explicit
dummy / `.env.example` values. The parent process environment is never passed through.

**Provisioning / build / install failure is reported DISTINCTLY** as "sandbox could not be provisioned"
— it is infra, NOT a code-review finding or a quality verdict (skeptic-3).

## S5 — the attribution-aware test gate (skeptic-2, sec-6)

Run the recipe's test command inside the execution-phase sandbox with a wall-clock timeout. Then:

- **Prefer the cheap signal first** — the PR's forge CI status / existing test report, if available, to
  judge whether a red suite is the PR's fault.
- **New failure attributable to the PR** → headline **blocking** finding; **skip the deep panel** (this
  is the user's "tests fail → fail"). The failing-test output is `cr_redact_runtime`-scrubbed before it
  enters the finding/comment/capture.
- **Red but attribution unverified** (no CI signal, no baseline) → **advisory** "suite red, attribution
  unverified"; the panel continues. Never hard-block an honest PR on someone else's broken main.
- `--baseline` opts into running the test cmd on the **true upstream base commit** first (NOT a
  PR-supplied ref), under the **same locked envelope**, so only NEW failures gate. This runs more
  attacker code and doubles the heaviest cost — opt-in, documented.

## S6 — assemble the dynamic-evidence bundle (for the panel)

Run the recipe's analyzers in the execution-phase sandbox and assemble the bundle the panel consumes via
the extended `_shared/critic-panel.md` "Inputs" contract:

- **static analyzers** (eslint/phpstan/mypy/ruff/semgrep) — deterministic precision floor;
- **diff-coverage** — PR lines with no covering test;
- **test results** from S5;
- **runtime reproduction** evidence — a targeted/generated check that demonstrates a bug.

All analyzer/runtime output is `cr_redact_runtime`-scrubbed AND fenced as untrusted data before it
reaches any critic. **Baseline-diff** the analyzers (S5 `--baseline`) so only NEW issues are attributed.

**Dynamic findings are non-deterministic (skeptic-5).** A runtime/repro finding qualifies as
`grounding: confirmed` only after **N reproductions** (default 2); it carries the disposition
`runtime-observed (may be env-dependent)` so step 3/4 can treat it specially.

## S7 — teardown (owned here, armed at S2)

Idempotent, trap-based, and **path-guarded**:

```sh
_cr_teardown() {
    cr_sandbox_path_is_safe "$SANDBOX_DIR" || return 0   # fail closed, never widen the rm
    docker compose -p "$SANDBOX_NAME" down -v --remove-orphans 2>/dev/null || true
    docker ps  -aq --filter "label=com.vault.v-cr.sandbox=$SANDBOX_NAME" | xargs -r docker rm -f
    docker volume ls -q --filter "label=com.vault.v-cr.sandbox=$SANDBOX_NAME" | xargs -r docker volume rm
    rm -rf -- "$SANDBOX_DIR"
}
trap _cr_teardown EXIT INT TERM
```

- Every container/volume is created with the label `com.vault.v-cr.sandbox=<cr_sandbox_name>`.
- `cr_sandbox_path_is_safe` runs **inside** the teardown, immediately before the `rm` — `set -u` means an
  empty/unset `$SANDBOX_DIR` fails the guard rather than expanding to a dangerous default (sec-7).
- **SIGKILL / OOM bypass traps.** `/v-cr --sandbox-gc` is the swept-orphan reaper: it removes any
  `com.vault.v-cr.sandbox`-labelled docker objects and any `vcr-*` dir under `cr_sandbox_root` left by a
  crashed run. Because provisioning is a clone (not a user-repo worktree), no `git worktree prune` of the
  user's repo is ever needed (skeptic-4).

## Residual risk (state it, don't paper over it)

Docker is **not a microVM** — a kernel exploit can still escape. The envelope (no egress at execution,
clean env, caps, non-root, throwaway) makes a successful escape low-value, not impossible. Recommend
rootless Docker / gVisor / a microVM runtime where the threat model warrants it. **Do not claim
hostile-proof.**
