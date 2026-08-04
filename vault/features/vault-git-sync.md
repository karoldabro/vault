---
type: feature
project: vault
slug: vault-git-sync
status: shipped
owners: []
tags: [feature, git, sync, lifecycle]
---

# vault-git-sync

## Scope
Keeps a project vault that lives **outside** the code repo (`~/vault/<slug>/`, and the shared
cross-project `~/vault/_features/`) in sync with its git remote, without the user doing it by hand:
pull before the lifecycle reads vault context, commit and push after the vault writes land.

**Non-goals.** An in-repo vault (`vault_path: ./vault`) — the code repo's own commit already covers it,
and the script detects and skips that case. Creating repos or remotes. Resolving conflicts. Anything
in `/v-ask`, which is excluded by design.

## Contracts

`$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh` — the only permitted way for a command to run git against a
vault ([[../indications/vault-git-never-raw]], [[../decisions/ADR-022-vault-git-autosync]]):

```bash
vault-sync.sh pull <vault-dir> [--dry-run]
vault-sync.sh push <vault-dir> [--dry-run] [-m <subject>] [path...]
```

The **exit code is the interface** — callers branch on the number, never on the prose:

| Code | Meaning |
|------|---------|
| 0 | synced (or nothing to do) |
| 1 | a git operation failed; the worktree is left clean |
| 2 | usage error |
| 3 | the vault dir is not inside a git worktree |
| 4 | the vault dir is inside the code repo's worktree |
| 5 | a git repo with no upstream branch |

`commands/_shared/vault-sync.md` is the contract module every vault-touching command binds to.
Bound by: `/v-work` steps 2 + 5 · `/v-capture` steps 0 + 5 · `/v-do` orient · `/v-pm` steps 2 + 5.
`/v-team` inherits it by reusing the `/v-work` step files.

Config: `behaviour.vault_autosync` in `VAULT.md` → `vault_autosync` in `~/vault/_global/config.md` →
default **true**.

Environment: `VAULT_SYNC_CODE_REPO` (worktree compared against for exit 4, default `$PWD`),
`VAULT_SETUP_DRY_RUN=1` (the shared dry-run seam).

## Behaviors & rules

- A sync failure is surfaced and the lifecycle continues → never halts, never blocks a capture.
- `pull --rebase --autostash` conflicts → the rebase is aborted and the worktree restored → exit 1;
  edge: a rebase or merge already in progress is refused outright rather than continued.
- Vault dir is not a git worktree, or does not exist → exit 3 and **no** `git init` is run.
- Vault toplevel equals the code repo toplevel → exit 4 and nothing is staged.
- `push` with no upstream → the commit is made locally, the user is told it did not leave the machine,
  and no remote branch is created.
- `push` stages only its given paths → a sibling vault or dirty parent is never swept in; edge: no
  paths given → the vault dir as an explicit absolute pathspec, never `.` and never `-A`.
- `push` with nothing staged → exit 0, no empty commit; edge: unpushed commits already present are
  still pushed.
- Gitignored local-only mounts (`memory/`, `graphify/`, `serena/`) are never staged.
- `--dry-run` prints every git command and leaves the worktree byte-identical.

## Coupling

- `~/vault/_features/` — the cross-project workspace `/v-pm` writes and other projects' `/v-team`
  sessions read. It is its own committed vault, so its push is the mechanism by which a cross-project
  plan becomes visible to the other participants at all.
- `templates/vault.gitignore` — supplies the ignores that keep the local-only mounts out of a push.
- `lib/installers.sh` — supplies `run()`, the dry-run seam ([[../indications/installer-dry-run-seam]]).

## Gotchas

- **Exit 4 depends on `$PWD`.** The in-repo check compares the vault's `git rev-parse --show-toplevel`
  against the same for `$VAULT_SYNC_CODE_REPO`, which defaults to `$PWD`. A command invoked from
  outside the code repo misclassifies an in-repo vault as standalone. Harmless (it re-commits
  already-committed files) but it is the fragile assumption in the design.
- **On this machine, half the vaults are not repos.** Six of eleven directories under `~/vault/` are
  git repos; `~/vault` itself is not. Exit 3 is the common case, not the exception.
- **The wiring test enumerates command files by path.** `tests/unit/vault-sync.bats` lists the six
  bound files explicitly, so a *new* vault-touching command can be added without the test noticing.
- A bare repo made with `git init --bare` keeps an unborn `master` HEAD even after `main` is pushed,
  so `git -C <bare> log -1` finds nothing. Tests must name the branch.

## Sessions
- [[../sessions/2026-08-04-1404-vault-git-autosync]]
