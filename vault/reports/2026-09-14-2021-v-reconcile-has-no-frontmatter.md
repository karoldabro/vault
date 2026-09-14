---
type: report
project: vault
slug: 2026-09-14-2021-v-reconcile-has-no-frontmatter
date: 2026-09-14
status: open
severity: major
found_by: /v-work, building /v-handoff and /v-report
found_in: taking a baseline test run at HEAD to separate pre-existing failures from new ones
files: [commands/v-reconcile.md, tests/unit/plugin-install.bats]
tags: [report]
---

# v-reconcile-has-no-frontmatter

## What is wrong

`commands/v-reconcile.md` opens with a block quote instead of a frontmatter fence, so it carries no
`description:` key. Every other top-level command has one, and
`tests/unit/plugin-install.bats:113` fails naming this file.

## Files

| file (exact path) | what is wrong in it |
|-------------------|---------------------|
| `commands/v-reconcile.md` | line 1 is `> **Framework root:** ...`; there is no `---` fence and no `description:` or `argument-hint:` key |
| `tests/unit/plugin-install.bats` | the assertion at line 113 walks every `commands/v-*.md` and reports this one as `no description` |

## Consequence

This has already happened, to anyone who installed the plugin. Claude Code's command picker reads
`description:` from the frontmatter, so `/v-reconcile` appears with no explanation of what it does
next to fifteen commands that have one. The user cannot tell from the picker that it rewrites a
document to the writing standard.

## Cause

The file was written before the frontmatter convention was enforced, and the check that would have
caught it — `tests/unit/plugin-install.bats:113` — has been failing rather than blocking, because
nothing gates the suite's exit on it.

## How to see it

```bash
head -1 commands/v-reconcile.md
grep -c '^description:' commands/v-reconcile.md
```

Prints the block quote and `0`. Compare `head -1 commands/v-method.md`, which prints `---`.

## Repair

Add a frontmatter block to `commands/v-reconcile.md` with `description:` and `argument-hint:`, in the
shape `commands/v-method.md` uses. Run it with `/v-do`: one file, and
`tests/unit/plugin-install.bats:113` is the test that proves it.

The description must say what the command does for the user, not what it is called. Its own README
row reads "Rewrite an existing document to the writing standard, keeping every constraint", which is
the sentence to start from.

## Not now because

Out of scope for a session adding two different commands, and the fix belongs with whoever owns the
`/v-reconcile` wording.

## Closes when

```bash
./tests/run.sh tests/unit/plugin-install.bats
```

passes, and `grep -cE '^description: .{40,}' commands/v-reconcile.md` returns 1.
