---
type: indication
project: vault
slug: sandboxed-cr-safety
scope: repo
tags: [indication, code-review, sandbox, security]
---

# sandboxed-cr-safety

## Rule
Any automation that **executes** attacker-authorable code (a PR, an untrusted repo) to inform a review
must: (1) source the **isolation envelope** (network, resource caps, env passthrough, mounts, proxy,
registry) ONLY from per-stack defaults + user/global config — **never from a repo file or project
indication**; strip envelope keys out of any repo/indication recipe (`cr_is_envelope_key`), and let a
PR's own `Dockerfile`/`compose` run only *inside* the framework wrapper, never widen it; (2) default to
**no egress at execution** — two-phase network (registry-allowlist/proxy install with `--ignore-scripts`,
then `network: none` for test/analyze), clean **allow-list** env (empty by default, never the parent
env), resource caps, non-root; (3) treat **all runtime stdout/stderr as untrusted** — secret-scrub it
(`cr_redact_runtime`) before it enters any model context, finding, comment, or capture, and fence it as
data, never instructions; (4) **provision via a throwaway clone under a guarded sandbox root, not a
worktree of the user's repo**, with `cr_sandbox_path_is_safe` (`set -u`) called immediately before every
`rm`/`worktree remove`, teardown trap-armed at provision, and a label-based GC (`--sandbox-gc`) for
SIGKILL orphans; (5) gate execution on a **fetch-capability probe** — refuse and fall back to API-only
rather than review the wrong tree; (6) make the test gate **attribution-aware** — only PR-attributable
new failures hard-block; an unattributable red suite is advisory; provisioning failure is reported as
infra, not a code finding; (7) keep **all read-only-review invariants** (never commit/push/apply,
first-post gate, secret redaction, host-scoped creds, stable static fingerprints) — the sandbox is
throwaway.

## Rationale
Running a PR inverts the threat model from [[automated-cr-safety]]: now the reviewer executes hostile
code. A git worktree alone is not isolation, and Docker is not a true sandbox for hostile code, so the
posture is *make escape irrelevant* — no host secrets in the sandbox, no egress during execution, a human
gate on every write, everything throwaway. Repo-controlled execution config (a `.v-cr/sandbox.sh` hook, a
PR `compose` setting `network: host`) is an SSRF / secret-exfiltration / escape path; runtime output is a
fresh untrusted-data + secret-leak channel; an unguarded `rm` in crash-time cleanup is host data loss.
These came out of the `/v-cr --sandbox` design panel as 3 confirmed BLOCKER + several MAJOR findings
([[../decisions/ADR-009-v-cr-sandboxed-execution]]).

## Examples
- Do: `cr_is_envelope_key network` → 0 (drop it from a repo recipe); set network/caps from
  `VCR_SANDBOX_MAP` only.
- Do: `cr_sandbox_path_is_safe "$SANDBOX_DIR" || return 0` inside the teardown trap, before `rm -rf`.
- Do: `... | cr_redact_runtime` on every captured test/build/lint log before it reaches a critic.
- Don't: read a `.v-cr/sandbox.sh` host hook; honor a PR compose's `network: host` / host mount /
  `privileged`; pass the parent env into the container; hard-block a PR on a pre-existing red suite;
  `git worktree add` against the user's working repo.

## Applies-to
`commands/v-cr/sandbox.md`, `lib/cr-sandbox.sh`, `commands/v-cr/steps/{01-detect,02-gather,03-review,04-post,05-capture}.md`,
`commands/v-cr/adapters.md` (`fetch_ref`), `commands/_shared/critic-panel.md` (dynamic-evidence bundle),
and any future review/automation that executes untrusted code. Extends [[automated-cr-safety]].
