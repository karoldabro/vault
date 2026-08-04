---
type: decision
project: vault
id: ADR-022
status: accepted
scope: repo
tags: [adr, git, sync, vault, lifecycle]
---

# ADR-022 — Sync an out-of-repo vault automatically, through a script the commands must call

## Context

A project vault lives in one of two places (`vault-guide.md` §1.1): inside the code repo
(`vault_path: ./vault`) or globally at `~/vault/<slug>/`. The in-repo case rides along with the code
repo's commits and needs nothing. The global case is not covered by anything.

What the lifecycle actually did about that: `/v-work` step 5 §5.2 said "if the vault is a separate git
repo, `git add` + `git commit`" — no pull, no push, and the model hand-rolled the commands. `/v-capture`
— the command that writes the knowledge, and the one that runs standalone far more often than inside
`/v-work` — mentioned git nowhere at all. Its step 5 was already titled "Indexes + push" and did not push.

Measured on this machine at the time of writing: of eleven directories under `~/vault/`, six are git
repos (`digitally-core`, `_features`, `givore`, `kdabrow`, `magic`, `studio`) and five are not.
`~/vault` itself is not a repo. So the durable record was committed when someone remembered and pushed
by hand, and `~/vault/_features/` — the neutral cross-project workspace whose entire purpose is being
read by *other* machines and *other* projects — was no better off.

## Decision

**A shell script owns the git operations; a shared prose module says when to call it; the commands are
forbidden from running raw `git` against a vault.**

- `bin/vault-sync.sh pull|push <vault-dir>`. `push` takes `-m <subject>` and an explicit path list.
- `commands/_shared/vault-sync.md` is the contract, bound by every command that reads or writes a
  vault — the same shape as `_shared/communication.md` ([[ADR-018-decision-communication-contract]]),
  and for the same reason: one definition, many binders, no duplication to drift.
- Wired in: `/v-work` step 2 (pull) and step 6 (push), `/v-capture` step 0 (pull) and step 5 (push),
  `/v-do` orient (pull; its push comes free when the optional capture runs), `/v-pm` step 2 (pull every
  participant vault) and step 5 (push the `_features/` workspace). `/v-team` reuses the `/v-work` step
  files verbatim and inherits it.
- **`/v-ask` is excluded from both directions.** Its own hard rule is "no `git` write. No file in any
  repo or vault changes during `/v-ask`" — and `pull --rebase` rewrites the worktree. A read-only
  command that quietly rebases something is a worse defect than answering from a slightly stale vault.
  This reverses the plan the session started from, which had `/v-ask` pulling.
- The script's exit code **is** the interface, and none of it is fatal: `0` synced · `1` git failed ·
  `3` not a git repo · `4` the vault is inside the code repo · `5` no upstream. Callers branch on the
  number instead of parsing prose.
- Governed by `behaviour.vault_autosync` in `VAULT.md`, falling back to `vault_autosync` in
  `~/vault/_global/config.md`, **default on**.

### Safety properties the script commits to

- **Never `git add -A` and never `git add .`** — always an explicit pathspec, so a dirty parent or a
  sibling vault under `~/vault/` cannot be swept into a commit. Gitignore still excludes the local-only
  mounts (`memory/`, `graphify/`, `serena/`).
- **Never `git init` a vault.** Five of this machine's eleven vault dirs are deliberately not repos.
  Exit 3 is a one-line note, not a prompt loop. Consistent with [[ADR-005-installer-auto-exec]]'s line
  on doing things to a user's machine without asking.
- **Never leave a worktree mid-operation.** A conflicting `pull --rebase --autostash` is aborted and
  the stash restored before returning 1; a rebase or merge already in progress is refused outright.
- **Never create a remote branch.** No upstream means commit locally and say so — the script does not
  guess a remote and `push -u` into it.
- **Never resolve a conflict for the user.**
- Mutating git goes through the `run()` dry-run seam from [[installer-dry-run-seam]], so
  `--dry-run` prints the transcript and changes nothing.

## Consequences

**Better.** Knowledge written into a global vault reaches its remote in the same session that produced
it. `/v-capture` finally does what its own step heading claimed. A cross-project `/v-pm` plan is
visible to the other participants without a manual push. Dedupe runs against a current vault rather
than a stale one. And the git commands are now a tested artifact (17 integration tests against real
repos and a local bare remote) instead of prose the model re-improvises each run.

**Worse.** One more script on the maintenance surface, and one more thing every new vault-touching
command has to remember to bind — guarded by `tests/unit/vault-sync.bats`, which asserts the wiring
file-by-file. Automatic pushes mean the vault's history is now shaped by whatever the lifecycle
decided to commit, so a bad capture reaches the remote as fast as a good one; `vault_autosync: false`
is the escape hatch.

**Watch for.** The exit-4 check compares `git rev-parse --show-toplevel` for the vault against the
same for `$VAULT_SYNC_CODE_REPO` (default `$PWD`). A command that runs from outside the code repo
would lose that comparison and treat an in-repo vault as standalone — harmless (it would commit
already-committed files), but it is the fragile assumption here.
