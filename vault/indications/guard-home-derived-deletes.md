---
type: indication
project: vault
slug: guard-home-derived-deletes
scope: repo
tags: [indication, shell, safety]
---

# guard-home-derived-deletes

## Rule
Never `rm -rf` a path built from `$HOME` (or from a variable defaulting to `$HOME`) without first
validating the target. Use `safe_rm_under_home` from `lib/installers.sh`, or an equivalent explicit
check: `$HOME` non-empty, not `/`, and the target genuinely under it.

For a variable that may legitimately point outside `$HOME` — `VAULT_HOME`, which defaults to
`${HOME}/vault` but is overridable — assert instead that it is **absolute with a real parent**, and
reject the value the empty-`HOME` default collapses to (`/vault`).

## Rationale
`set -u` does **not** catch an empty `HOME`. The variable is *set*, just empty, so `"${HOME}/.foo"`
expands to `/.foo` and the delete points at the filesystem root:

```bash
$ HOME= bash -c 'set -euo pipefail; echo "[${HOME}/.cache]"'
[/.cache]
```

This is easy to fix once and easy to miss everywhere else. When
[[../decisions/ADR-019-drop-openviking-dependency]] added a teardown script, the guard went into the
new file and the identical bug stayed live in the sibling script for a whole commit —
`vault-uninstall.sh` still did a raw `rm -rf "${VAULT_HOME}/_global"`, which with an empty `HOME`
resolved to `/vault/_global`. A review caught it; `set -euo pipefail` and code review of the new file
did not.

## Examples
- Do: `safe_rm_under_home "${HOME}/.some-tool"` — refuses empty/`/` `HOME`, refuses paths outside
  `$HOME`, reports "already absent" instead of failing, and honours the dry-run seam via `run`.
- Do: guard an overridable root by shape —
  `case "${VAULT_HOME}" in /|""|/_global) refuse ;; /*) ;; *) refuse ;; esac`.
- Don't: `run rm -rf "${HOME}/.thing"` on the assumption `set -u` covers it.
- Test it: assert the refusal with `HOME=""` **and** `HOME=/`, and assert nothing was deleted — a
  script that merely exits non-zero has already done the damage.

## Applies-to
`bin/*.sh` (esp. `vault-uninstall.sh` and the ADR-019 teardown script), `lib/installers.sh`, any future
teardown script. See also [[installer-dry-run-seam]].
