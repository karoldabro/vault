---
type: indication
project: vault
slug: hooks-never-fail-their-host
scope: repo
tags: [indication]
---

# hooks-never-fail-their-host

## Rule

A Claude Code hook this framework ships exits 0 on every path it can reach, and never blocks a turn.
Four parts, all required:

1. **Exit 0 when you cannot do the job.** A missing linter, an absent library, a malformed payload
   and an unparseable state file all mean "do nothing", never "fail".
2. **Never exit 2 from a `Stop` hook.** Exit 2 blocks the stop and continues the conversation, so the
   model appends more text. Only `PostToolUse` may use exit 2, and only to hand findings back.
3. **Guard every `source`.** Test the file with `[ -r ... ]` inside an `if`, never `a && b` — under
   `set -e` a failing `&&` list aborts the script. A caller that lost a library skips that one check
   and runs the rest.
4. **Validate anything that reaches a filename or a shell.** A session id is `[A-Za-z0-9_-]` only.
   Values that reach an interpreter are passed as data, never pasted into its source text.

Linking a hook and switching it on are separate steps. `install.sh` links every row in `HOOK_ROWS`
on any run and edits `~/.claude/settings.json` only behind that row's flag.

## Rationale

A hook runs on someone else's turn. When it fails, the failure is attributed to the work, not to the
hook: `scripts/doc-lint-hook.sh` returns its stderr to the model as lint findings, so an aborted
`bin/doc-lint.sh` would deliver shell errors as if they were rules — on every file write, in every
session, until someone noticed.

The `Stop` rule is the sharper one. A brevity hook that exits 2 makes the reply longer, which is the
opposite of its purpose, and the failure looks like the model ignoring its instructions.

## Examples

**Do** — `scripts/output-lint-hook.sh`: sources `lib/hook-common.sh` behind `[ -r ... ] || exit 0`,
resolves the state path through `hook_state_path` (which returns 1 for a session id that is not a
plain token), and ends `exit 0` whatever happened.

**Do** — `bin/doc-lint.sh`: `if [ -r "${SCRIPT_DIR}/../lib/sentence-count.sh" ]; then . ...; fi`, and
`check_sentences()` opens with `command -v count_long_sentences >/dev/null 2>&1 || return 0`.

**Don't** — `[ -r "$lib" ] && . "$lib"` at the top level of a `set -e` script: the whole list returns
non-zero when the file is absent and the script dies before its first check.

**Don't** — build the same path in two hooks. `scripts/output-lint-hook.sh` writes what
`scripts/brevity-reminder-hook.sh` reads; two copies of the filename drift apart and the only symptom
is a hook that silently stops speaking.

## Applies-to

`scripts/*-hook.sh` · `lib/hook-common.sh` · `hooks/hooks.json` · `install.sh` `HOOK_ROWS` and its
registration loop · `tests/unit/brevity-hooks.bats` · `tests/unit/install.bats`
