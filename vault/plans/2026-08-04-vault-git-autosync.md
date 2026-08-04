---
type: plan
project: vault
date: 2026-08-04
status: implemented
tags: [plan, git, sync, plugin, distribution]
---

# Plan — automatic git sync for out-of-repo vaults (+ plugin update semantics)

Two asks in one session:

1. **Question only.** How does the Claude Code plugin route handle updates — is it automatic, and does
   anything need pinning at deploy time?
2. **Change.** When a project vault lives outside the code repo, the lifecycle should pull, commit and
   push it on its own.

---

## Part 1 — plugin updates (answer, no code change proposed)

### What the docs say

Sources read 2026-08-04:

- <https://code.claude.com/docs/en/plugins> — "`version`: Optional. If set, users only receive updates
  when you bump this field. If omitted and your plugin is distributed via git, the commit SHA is used
  and every commit counts as a new version."
- <https://code.claude.com/docs/en/plugin-marketplaces> — "Version resolution and release channels":
  version resolves from `plugin.json` → marketplace entry → git commit SHA. "Plugin versions determine
  cache paths and update detection: if the resolved version matches what a user already has,
  `/plugin update` and auto-update skip the plugin."
- Same page, "Background auto-updates": Claude Code refreshes marketplaces in the background with
  `git pull`; a failed background pull falls back to a full re-clone. Credential helpers are disabled
  for the background pull, which only matters for private marketplaces.

### Applied to this repo

`.claude-plugin/plugin.json` pins `"version": "1.0.0"`. `.claude-plugin/marketplace.json` sets no
`version` and no `ref`, so the source is the default branch (`main`) of `karoldabro/vault`.

Consequences:

- Updates **are** automatic — Claude Code refreshes the marketplace in the background and applies new
  versions without the user doing anything. `/plugin update` is the manual equivalent.
- But automation is **gated on the version string**. Pushing to `main` without bumping `plugin.json`
  reaches nobody, and the failure is silent: `/plugin update` reports "already latest". This is exactly
  the consequence recorded in [[ADR-020-claude-code-plugin-distribution]] and it holds.
- Nothing extra is needed at install time. Users run `/plugin marketplace add karoldabro/vault` then
  `/plugin install vault@kdabro-vault`. No version, ref or tag is specified by the installer.
- The repo is public, so the private-marketplace credential caveat does not apply.

### The remaining gap (not proposed, recorded as a follow-up)

`tests/unit/plugin-install.bats:26` asserts a semver **exists**; nothing asserts it **changed** since
the last release. A release check that compares `plugin.json` version against the version at the last
git tag would turn the silent failure into a loud one. Deliberately left out of this plan's scope.

### Alternative considered

Drop `version` from `plugin.json` so every commit on `main` ships. Rejected — it reverses the
deliberate-publishing property ADR-020 chose, and would push half-finished commits to installed users.

---

## Part 2 — automatic git sync for out-of-repo vaults

### Problem

`/v-work` step 5 §5.2 says: "If `<project-vault>/` is a separate git repo: `git add` + `git commit`".
There is no pull and no push, and `/v-capture` — which is the command that actually writes the
knowledge, and which runs standalone far more often than inside `/v-work` — mentions git nowhere at
all.

Measured on this machine (`~/vault/`): six of eleven project vaults are git repos
(`digitally-core`, `_features`, `givore`, `kdabrow`, `magic`, `studio`); five are not. `~/vault` itself
is not a repo. So knowledge written into a global vault is committed only when someone remembers, and
is pushed only by hand.

### Design

**A shell script does the git work; a shared prose module says when to call it.** This mirrors the
existing split (`bin/*.sh` for deterministic work, `commands/_shared/communication.md` for a contract
every command binds to) and makes the behaviour testable in bats rather than improvised by the model.

#### New — `bin/vault-sync.sh`

Two subcommands, both taking the resolved vault path:

```
vault-sync.sh pull <vault-dir> [--dry-run]
vault-sync.sh push <vault-dir> [--dry-run] [-m <subject>] [paths...]
```

Exit-code contract (callers branch on it; nothing here is fatal to a lifecycle):

| Code | Meaning | Caller behaviour |
|------|---------|------------------|
| 0 | synced | continue silently |
| 3 | vault dir is not inside a git worktree | note once, offer `git init`, never run it |
| 4 | vault dir is inside the *code* repo's worktree | skip — the code commit already covers it |
| 5 | git repo, but no remote / no upstream branch | `pull` no-ops; `push` commits locally, says so once |
| 1 | git operation failed (conflict, rejected push, network) | surface, leave the tree clean, continue |

Behaviour:

- `pull` → `git -C <dir> pull --rebase --autostash`. On rebase conflict: `git rebase --abort`, restore
  the stash, exit 1. The vault is never left mid-rebase.
- `push` → stage **only the listed paths** (default: the vault dir itself, never `-A` from a parent),
  commit `docs(vault): <subject>`, then `git push` when an upstream exists. Nothing staged → exit 0
  without an empty commit.
- Case 4 is detected by comparing `git -C <vault-dir> rev-parse --show-toplevel` against the code
  repo's toplevel. Equal → the vault is in-repo (`vault_path: ./vault`, as in this framework repo).
- `--dry-run` prints the git commands without running them, per
  [[installer-dry-run-seam]].
- Local-only paths (`memory/`, `graphify/`, `serena/` — already gitignored per `templates/vault.gitignore`)
  are never force-added.

#### New — `commands/_shared/vault-sync.md`

The contract module every lifecycle command binds to. States: when sync fires, the exit-code table
above, the opt-out, and the hard rule that **a sync failure is surfaced and the lifecycle continues** —
it never halts and never blocks a capture. Same shape as `_shared/communication.md`.

#### Wiring

| File | Change |
|------|--------|
| `commands/v-work/steps/02-load-context.md` | New §2.0 — pull the vault before reading it |
| `commands/v-work/steps/05-commit-capture.md` | §5.2 rewritten to call `push` instead of hand-rolled `git add`/`git commit` |
| `commands/v-capture.md` | Pull before dedupe; push after the session file + indexes are written |
| `commands/v-do.md` | Push when the optional capture actually runs |
| `commands/v-pm.md` | Same treatment for `~/vault/_features/` (its own git repo, per vault-guide §…) |
| ~~`commands/v-ask.md`~~ | **Reversed during execution — `/v-ask` is excluded entirely.** Its hard rule is "no `git` write. No file in any repo or vault changes", and `pull --rebase` rewrites the worktree. Recorded in [[ADR-022-vault-git-autosync]]. |
| `vault-guide.md` §1.1 | Document `vault_autosync` and the sync contract |
| `templates/VAULT.md` | Commented `vault_autosync: true` under `## behaviour` |
| `VAULT.md` (this repo) | Nothing — in-repo vault, case 4, sync is a no-op here |

`/v-team` reuses the `/v-work` step files verbatim, so it inherits this for free.

#### Opt-out

`behaviour.vault_autosync` in a repo's `VAULT.md`, falling back to `vault_autosync` in
`~/vault/_global/config.md`, defaulting to **true**. `false` restores today's behaviour (commit only,
no pull, no push).

### Test plan

`tests/integration/vault-sync.bats` — real temp git repos, a bare remote, no network:

| Scenario | Expect |
|----------|--------|
| clean vault + bare remote, remote ahead | `pull` fast-forwards, exit 0 |
| local edits + remote ahead | `pull --rebase --autostash` replays, exit 0 |
| conflicting edit both sides | exit 1, `git status` clean, no `.git/rebase-merge` left |
| `push` with staged paths | one commit, remote advances, exit 0 |
| `push` with nothing to stage | exit 0, no empty commit |
| `push` on a repo with no remote | exit 5, commit exists locally |
| vault dir is not a git repo | exit 3, no `git init` performed |
| vault toplevel == code repo toplevel | exit 4, nothing staged |
| `--dry-run` on every path | prints commands, working tree byte-identical |
| gitignored `memory/` present | never staged |

`tests/unit/vault-sync.bats` — wiring greps, in the style of `communication-contract.bats`:

- every command file that writes to a vault references `_shared/vault-sync.md`
- `05-commit-capture.md` no longer hand-rolls `git add` for the vault
- `bin/vault-sync.sh` contains no `git add -A` and no `git add .`
- `templates/VAULT.md` documents `vault_autosync`

Tests run in the container, never on the host (per the project's testing rule).

### Vault writes this produces

| Doc | Action | Dedupe |
|-----|--------|--------|
| `decisions/ADR-021-vault-git-autosync.md` | CREATE | no existing ADR covers vault git sync |
| `indications/vault-sync-never-halts.md` | CREATE | closest existing rule is `guard-home-derived-deletes.md`; different subject |
| `vault-guide.md` §1.1 | UPDATE | |
| `decisions/_inventory.md`, `_moc.md` | UPDATE | index reconciliation |
| `sessions/2026-08-04-*.md` | CREATE at capture | |

### Gates

- **Clarify (§3a.0a)** — no plan-changing fork left open. The user specified pull + commit + push
  outright; defaults for the unspecified edges are stated above and flagged at the approval gate.
- **Research (§3a.0b)** — run for Part 1 (two doc pages, cited above). Part 2 is ordinary shell +
  git work following this repo's own patterns; gate skipped per §3a.0b's skip rule.
- **Lite critic (§3a.6)** — **skipped**. The session carries a standing instruction not to spawn
  subagents unless asked. Surfaced at the approval gate.
