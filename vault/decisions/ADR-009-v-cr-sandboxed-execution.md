---
type: decision
project: vault
id: ADR-009
status: accepted
scope: repo
tags: [adr, code-review, v-cr, sandbox, security]
---

# ADR-009 — /v-cr gains an optional sandboxed-execution review path with a framework-owned isolation envelope

## Context
`/v-cr` (ADR-008) reviews a remote PR **from its diff only** — it never checks out or runs the code, so
every finding is static and `grounding: confirmed` is limited to grep/static rules. The 2026 state of the
art (CodeAnt, DeepSource) shows **execution-based verification returns the most verified findings with
the least noise** — the precision multiplier for v-cr's precision-first north star: the panel can *prove*
a finding (reproduce a bug, run a failing test) before posting.

But running a PR means running **attacker-authorable code**, which inverts the threat model. A `/v-team`
design panel (Software Architect, Security, Skeptic — all tool-grounded) reviewed the proposal over 2
rounds. Security returned **3 confirmed BLOCKERs**: (1) runtime stdout/stderr is a new untrusted-data
channel with no redaction boundary; (2) the recipe let **repo-controlled files** (`.v-cr/sandbox.sh` host
hook, repo `VAULT.md`, the PR's own `Dockerfile`/`compose`) set the **isolation envelope**; (3) the
default network egress posture was left undecided. Architect + Skeptic returned REQUEST_CHANGES (panel
contract not extended, fetch refs hard-coded instead of an adapter op, GATHER overloaded with execution,
cleanup misplaced, lib mixing pure + I/O, BB-Server fork refs not fetchable, baseline doubling cost,
dynamic findings vs stable fingerprints). All 18 confirmed findings were applied; Round 2 verified the 3
BLOCKERs closed with 0 new confirmed blockers. Full trail: `vault/plans/2026-06-19-1158-v-cr-sandbox-path.md`.

## Decision
Add an **optional, default-OFF `--sandbox` path** to `/v-cr`, contracted in `commands/v-cr/sandbox.md`
with a pure core in `lib/cr-sandbox.sh` (offline-tested) and the I/O in the contract (e2e-tested):

1. **The isolation envelope is framework-owned and non-overridable.** network / resource caps / env
   passthrough / mounts / proxy / registry come ONLY from per-stack defaults + user/global config
   (`VCR_SANDBOX_MAP`, analogue of `VCR_HOST_MAP`). A project may declare only **benign recipe bits**
   (install/test/lint/ports/build/image) via its vault `indications/` or `VAULT.md` —
   `cr_is_envelope_key` strips envelope keys out of any repo/indication source. A PR's `Dockerfile`/
   `compose` is built/run **only inside** the wrapper, never widening it. **The `.v-cr/sandbox.sh` host
   hook is dropped entirely.** (Closes sec-2; extends ADR-004 "generic packs, specifics in indications".)
2. **Two-phase network; default no-egress at execution.** Install phase = a package-registry allowlist /
   caching proxy (user/global config) with lifecycle scripts off (`--ignore-scripts`); unrestricted
   egress only via the human-gated `--allow-net-install`. Execution phase = **`network: none`**, clean
   (allow-list, empty-by-default) env, resource caps, non-root. (Closes sec-3, sec-4, sec-5.)
3. **Runtime output is untrusted.** `cr_redact_runtime` secret-scrubs ALL captured stdout/stderr before
   it enters any model context, finding, comment, or capture, and it is fenced as data, never
   instructions (the `_shared/critic-panel.md` untrusted-input contract, now extended for the
   dynamic-evidence bundle). (Closes sec-1.)
4. **Provision via a throwaway clone under a guarded sandbox root, NOT a worktree of the user's repo** —
   a crash never orphans a registration in the user's `.git`. `cr_sandbox_path_is_safe` (`set -u`, run
   inside the teardown immediately before every `rm`) is the data-loss guard; teardown is trap-armed at
   provision; `--sandbox-gc` reaps SIGKILL-orphaned objects by the `com.vault.v-cr.sandbox` label.
5. **Attribution-aware test gate.** A **new** failure attributable to the PR blocks and skips the deep
   panel (the user's "tests fail → fail"); a red suite with **unverified attribution** is **advisory**,
   not a hard stop (don't gate honest PRs on someone else's broken main). `--baseline` runs the true
   upstream base under the same envelope so only new failures gate. Provisioning/build failure is
   reported **distinctly** ("could not provision"), never as a code-review verdict.
6. **Fetch is an adapter op with a capability probe.** `fetch_ref` returns a fetchable ref or
   `unsupported`; GitHub is validated (`refs/pull/<n>/head`), Bitbucket is capability-gated. Unsupported
   → **refuse `--sandbox`, fall back to API-only with a stated reason** — never review the wrong tree.
7. **Dynamic findings are aged, not pinned.** A runtime/repro finding is `confirmed` only after N
   reproductions and carries `runtime-observed`; its comment thread may be **re-resolved** later if it
   stops reproducing (the post-once-suppress-forever rule is relaxed for that class only).
8. **All ADR-008 invariants hold.** Never commit/push/apply; first-post gate; secret redaction;
   host-scoped credentials; stable static fingerprints. The sandbox is throwaway; nothing is pushed.

## Consequences
- **Easier:** findings can be runtime-verified → higher precision; static analyzers in-sandbox add a
  deterministic floor; the same dynamic-evidence bundle is reusable by a future `/v-team` runtime stage.
- **Harder / watch for:** **Docker ≠ microVM** — a kernel exploit can still escape; the envelope makes
  escape low-value, not impossible (recommend rootless/gVisor where warranted; do NOT claim
  hostile-proof). It runs attacker code and is heavy → strictly opt-in. Repos without a recipe get
  best-effort and may fail to provision (reported as infra, not a finding).
- **Coupling:** adds `commands/v-cr/sandbox.md` + `lib/cr-sandbox.sh`; extends `adapters.md` (`fetch_ref`)
  and `_shared/critic-panel.md` (optional bundle, shared with v-team). `install.sh` already symlinks
  `commands/v-cr/` wholesale, so no installer change. New unit tests: `tests/unit/cr-sandbox.bats`.

## Cross-repo impact
None (framework-internal). Consumers gain `/v-cr --sandbox` after the next `install.sh` run; using it
requires `VCR_SANDBOX_MAP` (and optionally a per-repo `behaviour.sandbox` recipe or sandbox indication).
Builds on [[ADR-008-v-cr-remote-pr-review]] and [[ADR-004-generic-packs-specifics-in-indications]];
reuses the grounding gate of [[ADR-003-tool-grounded-findings]].
