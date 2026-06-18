---
type: indication
project: vault
slug: installer-dry-run-seam
scope: repo
tags: [indication, install, testing, bash]
---

# installer-dry-run-seam

## Rule
Route every network/privileged side-effect in an installer script through a single `run()` wrapper that
echoes (`[dry-run] …`) instead of executing when `VAULT_SETUP_DRY_RUN=1`. Keep pure-local scaffolding
(mkdir, config heredocs) as direct calls. Make the dry-run transcript the primary offline-tested surface;
prove the real path separately with an opt-in e2e that actually installs.

## Rationale
The offline bats image is alpine, read-only, no network/sudo — it cannot host real `apt`/`curl|sh`.
A `run()` seam lets the offline suite assert command construction, ordering, idempotency guards, secret
redaction, and sudo-scoping without ever executing them, while the real behaviour is proven on a separate
networked Ubuntu container. Routing only side-effects through `run()` (not local writes) keeps the
existing offline assertions (`ov.conf` written, symlinks made) green unchanged.

## Examples
- Do: `run $(_priv) apt-get install -y pipx`; `run_shell "https://astral.sh/uv/install.sh" "curl -LsSf … | sh"`.
- Do: post-install verification (`have uv`) guarded with `_dry || …` so dry-run doesn't false-fail.
- Don't: write `ov.conf` or call `install.sh` through `run()` — local scaffolding must run even in dry-run.
- Don't: lean on the e2e for command correctness — it's slow/flaky; the dry-run unit suite owns that.

## Applies-to
`setup.sh`, `lib/installers.sh`, `tests/unit/setup-autoinstall.bats`, `tests/e2e/**`
