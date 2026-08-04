# Shared module — keeping an out-of-repo vault synced with git

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

Binding on every v-* command that **reads from or writes to** a project vault. A vault living outside
the code repo (`~/vault/<slug>/`, and the shared `~/vault/_features/`) is not covered by the code
repo's commits — without this it is committed only when someone remembers and pushed only by hand.

**Never run raw `git` against a vault.** Call the script; branch on its exit code.

```bash
$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh pull <vault>
$VAULT_FRAMEWORK_PATH/bin/vault-sync.sh push <vault> -m "<subject>" [paths...]
```

## When it fires

| Moment | Call | Commands |
|--------|------|----------|
| Before reading vault context | `pull` | `/v-work` step 2 · `/v-team` (same step) · `/v-do` orient · `/v-capture` step 0 · `/v-pm` |
| After the vault writes land | `push` | `/v-capture` step 5 · `/v-work` step 6 · `/v-pm` |

**`/v-ask` is excluded from both.** Its own contract is "no `git` write, no file in any repo or vault
changes" — and a `pull` rewrites the vault worktree. A read-only command that quietly rebases
something is a worse defect than answering from a slightly stale vault. `/v-do` inherits `push`
through `/v-capture` when its optional capture runs; it never pushes on its own.

Run `pull` **once per session** — the first command that needs it does it; later steps in the same
run do not repeat it.

## The exit codes

| Code | Meaning | What you do |
|------|---------|-------------|
| 0 | synced | nothing — do **not** tell the user a normal thing was normal |
| 1 | a git operation failed | say so in one line, keep going |
| 3 | the vault is not a git repo | say so **once per session**; offer `git init` as a suggestion and **never run it** |
| 4 | the vault is inside the code repo | skip silently — the code commit already covers it |
| 5 | no upstream branch | `push` committed locally; tell the user it did not leave the machine |

## The rules

1. **A sync failure never halts the lifecycle and never blocks a capture.** Knowledge that is written
   but unpushed is recoverable; knowledge that was never written is not. Surface and continue.
2. **Never `git add -A` and never `git add .`** in a vault. Pass the paths this run actually touched,
   or none at all and let the script use the vault dir as an explicit pathspec.
3. **Never `git init` a vault for the user.** Creating a repo where they chose not to have one is
   theirs to decide. Exit 3 is a one-line note, not a prompt loop.
4. **Never resolve a conflict on the user's behalf.** The script aborts a conflicting rebase and
   leaves the worktree clean; report it and let them handle it.
5. **Report exceptions only.** A clean sync produces no output, per `_shared/communication.md`.

## Opt-out

`behaviour.vault_autosync` in the repo's `VAULT.md`, falling back to `vault_autosync` in
`~/vault/_global/config.md`, default **true**. `false` disables `pull` and `push` entirely — the
vault is then the user's to commit by hand. The value is read once at step 1 §1.4 and carried
through the run like every other `behaviour` key.
