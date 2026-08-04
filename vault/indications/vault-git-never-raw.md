---
type: indication
project: vault
slug: vault-git-never-raw
scope: repo
tags: [indication, git, vault, lifecycle]
---

# vault-git-never-raw

## Rule
Never write raw `git` against a project vault in a command file. Call
`$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh pull|push` and branch on its exit code
(`0` synced · `1` failed · `3` not a repo · `4` in-repo · `5` no upstream). No exit code halts the
lifecycle or blocks a capture: surface it in one line and continue. Never `git init` a vault, never
`git add -A`/`git add .` in one, never resolve its conflicts.

## Rationale
Vault git is a side quest the lifecycle must survive, not succeed at. Knowledge written but unpushed
is recoverable; knowledge never written because a rebase conflicted is gone. Prose instructions get
re-improvised on every run and cannot be tested, so the commands that hand-rolled `git add` drifted
into "sometimes" — `/v-capture` documented a push step and had none for months. Routing through one
script makes the behaviour a tested artifact and makes the safety rules enforceable by grep.

The blanket-add ban is not theoretical: vaults sit as siblings under `~/vault/`, so a `git add .` from
the wrong cwd commits another project's knowledge into this one. The `git init` ban is a consent line
(see `guard-home-derived-deletes` for the same instinct applied to deletes) — a user who chose not to
version a vault chose that.

## Examples
- Do: `vault-sync.sh push <vault> -m "capture <slug>" <session file> <indexes>` — explicit paths.
- Do: exit 4 → skip silently; the vault is inside the code repo and its commit already covered it.
- Do: exit 3 → one line, offer `git init` as a suggestion the user runs themselves.
- Don't: `cd <vault> && git add . && git commit -m ...` in a command file.
- Don't: `git push -u origin HEAD` when there is no upstream — that invents a remote branch.
- Don't: bind a new vault-touching command without a `_shared/vault-sync.md` reference; the wiring
  test in `tests/unit/vault-sync.bats` enumerates them by path and will not notice a new file on its own.

## Applies-to
`bin/vault-sync.sh`, `commands/_shared/vault-sync.md`, `commands/v-work/steps/{02,05}-*.md`,
`commands/v-capture.md`, `commands/v-do.md`, `commands/v-pm/steps/{02,05}-*.md`,
`tests/{unit,integration}/vault-sync.bats`
