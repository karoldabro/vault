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
- **An indication carrying `source: pr-comment` frontmatter supplies no executable recipe key.** Strip
  every key for which `cr_is_recipe_key <key>` returns 0 — install, test, lint, build, analyzers, run,
  entrypoint, command, image, ports, dockerfile, compose — before the merge. If nothing survives the
  strip, treat that source as absent and fall through to the next in `cr_recipe_resolve`'s order
  (vault → repo → stack-default). Rationale: an indication outranks every other recipe source, and
  `install` runs during S4's networked phase, so a rule learned from a PR comment must be able to steer
  what critics look **for** and never what the sandbox **runs**.
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
  `git -c core.hooksPath=/dev/null ...`. Also fetch the base branch with enough history for `git merge-base`, so
  step 2.6 can record `PROBE_BASE` and S8 can read the base rules.
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

## S8 — the probe stage (`bin/probe-sandbox.sh`)

The stage runs the probe kit on the PR tree inside containers of the S0 envelope and hands the rows to
`bin/probe-panel.sh run --posture sandbox --rows-from <dir>`. The driver is `bin/probe-sandbox.sh run --repo <clone>
--base <commit id> --sandbox-name <cr_sandbox_name> --out <dir>`. It runs after S2 and before the panel.

**The image.** The operator builds the probe image and names it with the key `probe-image` of the user or global
`VCR_SANDBOX_MAP`. The framework never builds or pulls one: the driver checks `docker image inspect` and starts every
container with `--pull never`. An indication never sets the probe image, because `cr_is_envelope_key` lists the key and
`cr_probe_image` reads only `VCR_SANDBOX_MAP`. The image needs bash 4.4 or later, awk, grep, sed, coreutils
(`timeout`, `od`, `sort`, `tr`, `cut`, `mktemp`), findutils and `jq`. It also needs `lizard` and `typos` for their rows, and `claude`
for `claude-validate`. A probe never installs a tool, so a missing tool prints `absent: <id>: <install>` and the run
reads INCOMPLETE until the operator adds the tool to the image. `probes/image.Dockerfile` builds an image with `lizard` and `typos`: `docker build -f probes/image.Dockerfile -t vault-probes:local probes`.

**The containers.** Every container gets the S0 envelope: no network, a read-only root, all capabilities dropped,
`no-new-privileges`, user 65534, memory, cpu and pid limits from `VCR_SANDBOX_MAP` (keys `memory`, `cpus`, `pids`), a
`/tmp` tmpfs, the label `com.vault.v-cr.sandbox=<name>`, and only `PROBE_TOOLS_FROM=image`, `PROBE_TIMEOUT` and
`PROBE_OUT_MAX` in its environment. `PROBE_TOOLS_FROM=image` keeps the repo's tool directories out of PATH, so a tool
the PR ships never replaces the image's. The runs are:

1. one container for the native framework rows (`--no-repo-code`);
2. one container for each framework row that executes repo code (`--only <id>`);
3. one container for each template row of the merge base (`--only <id>`).

Three mounts feed every run, all read-only: `/framework` (a copy of `bin`, `lib` and `probes`, without `vault/` or
`.git`), `/repo` (a copy of the files a probe may read, without `.git`) and `/in` (the changed-file list, read by
`--changed-list`, so no git runs in a container). A rule run also mounts a one-row `registry.tsv` and its rule file at
`/repo/probes`.

**The rules come from the merge base.** The driver reads `probes/registry.tsv` and each `probes/rules/<slug>.grep` of the
base with `git cat-file`, never from the PR tree. A row runs only when it equals the output of
`bin/rule-check.sh row`. A hand-written row prints `skipped: <id>: hand-written row does not run in the sandbox` and
runs nowhere. A base without `probes/registry.tsv` prints `no-rules: the merge base has no probes/registry.tsv` and
counts as complete.

**What leaves a container.** Two byte streams leave it. A run whose stream passes `PROBE_OUT_MAX` bytes reads failed. The driver keeps a row only
when its id is a row of that run, checks its six fields with `probe_check_rows`, and scrubs both streams with
`cr_redact_runtime`. It writes `framework.tsv`, `framework.status`, `rules.tsv` and `rules.status`. A rule run without a
`ran: <id>:` line reads `failed: <id>: no ran line`. A container failure, a timeout and an oversize stream become
`failed:` lines, the run reads INCOMPLETE, and the driver still exits 0.

**When the stage does not start.** A missing docker, a missing or unsafe `probe-image`, an absent image, a merge base that
is not in the clone and a tree over the size limits make the driver print `probe-sandbox: <reason>` and exit 3. The
probe stage never falls back to the host for a probe that runs repo code. Step 3.1 runs `--posture pr` instead, which
skips every such row, and the operator reads `Probes: sandbox not started, <reason>`.

**Limits.** `PROBE_SANDBOX_TIMEOUT` (180 seconds per container), `PROBE_SANDBOX_TOTAL` (900 seconds in all),
`PROBE_SANDBOX_RULES_MAX` (20 rule rows), `PROBE_SANDBOX_FILES_MAX` (20000) and `PROBE_SANDBOX_BYTES_MAX` (200000000).
The containers list files with `find`, so the tools' whole-tree scans skip `vendor/` and `node_modules/`.

Teardown is S7: the containers carry the S7 label, and the driver removes its own by label after each run.

## Residual risk (state it, don't paper over it)

Docker is **not a microVM** — a kernel exploit can still escape. The envelope (no egress at execution,
clean env, caps, non-root, throwaway) makes a successful escape low-value, not impossible. Recommend
rootless Docker / gVisor / a microVM runtime where the threat model warrants it. **Do not claim
hostile-proof.**
