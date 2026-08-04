---
type: session
project: vault
date: 2026-08-04
topic: vault-git-autosync
files_touched:
  - bin/vault-sync.sh
  - commands/_shared/vault-sync.md
  - commands/v-work/steps/02-load-context.md
  - commands/v-work/steps/05-commit-capture.md
  - commands/v-capture.md
  - commands/v-do.md
  - commands/v-pm/steps/02-load-context.md
  - commands/v-pm/steps/05-capture.md
  - templates/VAULT.md
  - vault-guide.md
  - tests/unit/vault-sync.bats
  - tests/integration/vault-sync.bats
  - .claude-plugin/plugin.json
decisions: [ADR-022]
tags: [session, git, sync, plugin, distribution]
---

# vault-git-autosync

## Goal
Answer whether the Claude Code plugin route auto-updates, then make the lifecycle keep an out-of-repo
vault synced with git on its own — pull before reading, commit and push after writing.

## Did

**Plugin update question (answer only, no code change).** Read the two current doc pages
(<https://code.claude.com/docs/en/plugins>, <https://code.claude.com/docs/en/plugin-marketplaces>) and
checked them against this repo's manifests. Confirmed [[../decisions/ADR-020-claude-code-plugin-distribution]]
still holds: updates are automatic, gated on the `version` string. Nothing to specify at install time.

**Vault git sync.**
- Wrote `bin/vault-sync.sh` — `pull` / `push` subcommands, exit code as the interface
  (`0` synced · `1` git failed · `3` not a repo · `4` in-repo · `5` no upstream), `--dry-run` through
  the existing `run()` seam from [[../indications/installer-dry-run-seam]].
- Wrote `commands/_shared/vault-sync.md` as the binding contract, same shape as
  `_shared/communication.md` — one definition, many binders.
- Wired six command files: `/v-work` steps 2 + 5, `/v-capture` steps 0 + 5, `/v-do` orient,
  `/v-pm` steps 2 + 5. `/v-team` inherits it by reusing the `/v-work` step files.
- Documented `behaviour.vault_autosync` (default on) in `templates/VAULT.md` and `vault-guide.md` §1.1.
- 30 tests: 17 integration against real git repos with a local bare remote, 13 file contracts for the
  wiring. Full offline suite 348 green, `make validate-plugin` clean.
- Bumped `plugin.json` to **1.2.0** and pushed `main` to origin (`951d7ef..66fb784`).

Also committed two pre-existing uncommitted change sets so the tree is clean: the OpenViking removal
script hardening plus its tests, and the intro deck refresh.

## Learned

- **Claude Code plugins do auto-update, but the version string is a hard gate.** Background refresh
  `git pull`s the marketplace and applies new versions unattended. If `plugin.json` pins a version and
  a commit lands without bumping it, `/plugin update` reports "already latest" and nobody gets the
  change. Omitting `version` entirely makes every commit a release (commit SHA becomes the version).
- `tests/unit/plugin-install.bats` asserts a semver **exists**, never that it **changed**. The silent
  publish failure is still unguarded.
- **Six of eleven directories under `~/vault/` are git repos; five are not, and `~/vault` itself is
  not one.** Any design that assumes "the vault is a repo" is wrong on this machine roughly half the time.
- A bare repo created with `git init --bare` keeps an unborn `master` HEAD even after a `main` branch
  is pushed to it, so `git -C <bare> log -1` finds nothing. Name the branch explicitly in tests.
- `/v-capture` step 5 has been titled "Indexes + push" with no push in it. The heading was the only
  evidence the step was ever intended.
- Dedupe scored 85% against an unrelated session on generic keywords (`git sync vault push`) and 20%
  on specific ones (`vault-sync autosync rebase upstream exit-code`). Keyword choice drives the
  false-positive rate more than content overlap does.
- A concurrent session committed install-profiles work and bumped the plugin to 1.1.0 mid-run, which
  is why this feature shipped as 1.2.0.

## Behaviors & rules

- A vault sync failure is surfaced and the lifecycle continues → never halts, never blocks a capture;
  edge: a conflicting `pull --rebase` aborts and restores the worktree before returning 1.
- Vault dir is not inside a git worktree → exit 3, noted once, and `git init` is **not** run; edge: a
  missing directory is also exit 3.
- Vault toplevel equals the code repo's toplevel → exit 4 and nothing is staged, because the code
  commit already covers it.
- `push` finds no upstream → the commit is made locally and the user is told it did not leave the
  machine; no remote branch is created.
- `push` stages only the paths it was given → a sibling vault or a dirty parent is never swept in;
  edge: with no paths given it uses the vault dir as an explicit pathspec, never `.` and never `-A`.
- `push` with nothing staged → exit 0 and no empty commit.
- `/v-ask` never calls the sync script in either direction → its "no git write, no file changes"
  contract holds; a `pull --rebase` would rewrite the worktree and break it.
- `plugin.json` version unchanged on a release commit → installed users receive nothing, silently.

## Next

- ~~**Unguarded:** nothing fails a release commit that forgot to bump `plugin.json`.~~ **Closed in
  this session** — `bin/release-check.sh` + `make release-check` fail when shipped files changed since
  `origin/main` without a bump (`tests/`, `vault/`, `docs/` excluded; unreachable base ref warns and
  passes). 11 tests in `tests/unit/release-check.bats`. Shipped as **1.2.1**. Note the base is a
  branch, not `git describe` — this repo has no release tags.
- `tests/unit/vault-sync.bats` enumerates the wired command files by path, so a *new* vault-touching
  command can be added without the test noticing. Recorded in the indication.
- The exit-4 check compares against `$VAULT_SYNC_CODE_REPO` (default `$PWD`); a command invoked from
  outside the code repo would misclassify an in-repo vault as standalone. Harmless but fragile.
- End-to-end check of the plugin install route on a machine without the symlink install is still
  outstanding from the previous session.

## Refs
- [[../decisions/ADR-022-vault-git-autosync]]
- [[../decisions/ADR-020-claude-code-plugin-distribution]]
- [[../decisions/ADR-018-decision-communication-contract]]
- [[../decisions/ADR-005-installer-auto-exec]]
- [[../indications/vault-git-never-raw]]
- [[../indications/installer-dry-run-seam]]
- [[../indications/guard-home-derived-deletes]]
- [[../plans/2026-08-04-vault-git-autosync]]
