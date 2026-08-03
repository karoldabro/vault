---
type: session
project: vault
date: 2026-08-03-1300
topic: drop-openviking-dependency
tags: [session, dependencies, memory-stack, install, removal]
---

# Drop OpenViking as a framework dependency

## Goal

Confirm the repeated reports that OpenViking was unused and costly to install, then remove it from the
vault framework entirely and ship instructions for taking an existing install off a machine.

## Did

**Confirmed the claim with measurement, not memory.** Counted actual tool invocations across all 27
Claude Code projects, trailing 60 days, from the transcript JSONL: `memory_store` 194 · `memory_health`
139 · **`memory_recall` 17** · `ov find` 79 · logged failures 38. Reads were ~4% of traffic; failures
~40% of successful reads. `plans/2026-07-04-1030-v-family-usage-audit-retiering.md` had already traced
77% of sessions' error noise to it and left the fix open — six weeks passed with nobody restoring it.

**Removed it in three commits on `main`:**

- `b32b93c` — the removal itself, 55 files. `setup.sh --with-ov` + the OpenViking and ollama steps +
  six doctor rows; nine functions out of `lib/installers.sh`; `/v-sync`, `/v-backfill`,
  `commands/attic/v-resume.md` and the `openviking-three-part-install` indication deleted; the OV layer
  stripped from every command's context-load and capture path. New: `bin/remove-openviking.sh`,
  `docs/removing-openviking.md`, a shared `consent_gate()` + `safe_rm_under_home()` in
  `lib/installers.sh`, `tests/integration/remove-openviking.bats`, and a repo-wide grep guard.
- `82db7ad` — the diff review's findings.
- `ecec269` — plan artifact closed out.

**Ran the removal on this machine** (explicitly approved, including indexed data): service stopped +
unit deleted, `~/.openviking` purged, plugin uninstalled, `pipx uninstall openviking`. Verified: port
1933 dead, `ov` gone, second run a clean no-op. Ollama left installed.

**Updated `~/.claude/CLAUDE.md`** (outside the repo) — its memory-stack and search-precedence sections
named OV as layer 1.

**Reviews.** Three design reviewers before implementation (24 findings, all confirmed, all applied) and
one over the shipped diff (8 findings, all applied, 1 rejected on evidence). Final: 277 tests pass.

## Learned

- **`HOME=""` defeats `set -u`.** `"${HOME}/.openviking"` expands to `/.openviking` and `set -u` does
  not fire, because HOME is *set*, just empty. Every `rm -rf` built from `$HOME` needs an explicit
  guard. The first version of the fix guarded the new script and left the identical bug live in
  `bin/vault-uninstall.sh` — the diff review caught it there.
- **`consent_gate` cannot be called in `$( )`.** A command substitution runs in a subshell, so its
  `export VAULT_SETUP_DRY_RUN` is discarded and `--dry-run` silently becomes a real run. Caught by
  four integration tests failing at once; the fix is an out-parameter (`CONSENT_MODE`) plus a comment
  saying why.
- **Deleting a numbered section is cheaper than renumbering it.** `tool-playbook.md` §1 was deleted
  and §§2–7 deliberately kept their numbers, because eleven files cite them. The diff reviewer then
  advised closing the same kind of gap in `02-load-context.md`, asserting nothing cited it — applying
  that broke a test greping for `2.3c`. Reviewer findings need the same verification as anything else.
- **A "tool is optional" claim in docs is worth checking against the installer.** claude-mem was
  promoted to layer 1 while still installing only with `--full`, so a `--minimal` install would have
  had no first layer at all.
- **Reviewer subagents in this session went idle without reporting** and needed a direct follow-up
  message each. Findings arrived intact once prompted; the spawn-and-collect path is not reliable.

### Two pre-existing bugs surfaced

- `bin/vault-uninstall.sh` uninstalled claude-mem as `claude-mem@claude-mem`, an id that never
  existed — so **claude-mem had never actually been removed by the uninstaller**. `setup.sh`'s manual
  hints printed the same unqualified id. Both now use `claude-mem@thedotmack`. This is exactly the trap
  `indications/verify-plugin-marketplace-qualifier` documents.
- `bin/vault-uninstall.sh --help` printed `set -euo pipefail` and the `VAULT_ROOT=` line, because
  `usage()` was a `sed '2,30p'` range over the file header. Replaced with a heredoc.

## Behaviors & rules

- A removal script is invoked with `--dry-run` → it prints every action and no file changes byte-wise;
  edge: a step writing through `mv`/redirection must branch on the dry-run flag itself, since `run()`
  cannot intercept those.
- `HOME` is empty or `/` when a `$HOME`-derived path is deleted → refuse and warn; edge: `VAULT_HOME`
  may legitimately point outside `$HOME`, so it is guarded on being absolute with a real parent instead.
- A removal script runs a second time → every layer reports "already absent" and it exits 0.
- A script built from `[ "$flag" -eq 1 ] && step` lines → it must end with an explicit `exit 0`, or a
  clean run reports failure whenever the last flag is off.
- A shared helper sets shell state for its caller → it is called directly, never in a command
  substitution; edge: `export` inside `$( )` is discarded silently, so the failure looks like a logic
  bug, not a scoping one.
- A numbered section is deleted from a doc other files cite → the numbering gap stays and is
  documented in place; renumbering breaks the citations silently.
- A framework tool is dropped → the exit path (script + instructions) is written *before* the installer
  stops shipping it.

## Next

- **Open:** claude-mem is now the first context layer but installs only with `--full` /
  `--with-claude-mem`. Either make it a default install or accept that `--minimal` runs on grep alone.
  Every command states the grep fallback explicitly, so nothing is broken today.
- Optional local cleanup: `ollama rm nomic-embed-text` (~275 MB) — OpenViking was its only consumer here.
- `docs/vault-intro-deck.html` has uncommitted edits predating this session; left untouched.

## Refs

- [[../decisions/ADR-019-drop-openviking-dependency]]
- [[../plans/2026-08-03-1300-drop-openviking-dependency]]
- [[../plans/2026-07-04-1030-v-family-usage-audit-retiering]]
- [[../decisions/ADR-005-installer-auto-exec]]
- [[../indications/guard-home-derived-deletes]]
- [[../indications/verify-plugin-marketplace-qualifier]]
- [[../indications/installer-dry-run-seam]]
- [[../indications/per-user-installer-no-sudo]]
