---
type: research
project: vault
slug: rule-inventory
status: living
date_researched: 2026-09-04
tags: [research, compliance, measurement, rules]
---

# Rule inventory — the ten framework rules `bin/rule-audit.sh` scores

`bin/rule-audit.sh` parses the table below and scores every row. Editing a row changes what the
audit measures; the script holds no rule list of its own. Results and their reading:
`vault/research/rule-compliance.md`.

## How a row is scored

A rule is scored from a real invocation, never from a text match. Transcript rules count only
`tool_use` blocks named `Bash`, split into simple commands with heredoc bodies and quoted strings
removed, so a rule quoted in prose, in a `grep` pattern, or inside a document being written is not
counted as an invocation.

`corpus` names the unit being counted:

| corpus | unit | denominator matched against | source |
|---|---|---|---|
| `git-subject` | one commit | the subject line | `git log` in this repo |
| `transcript-cmd` | one simple shell command | the command text | `Bash` tool_use blocks in `~/.claude/projects` |
| `reply-text` | one main-loop assistant reply | the reply text | `text` blocks, sidechains excluded |
| `doc-blob` | one committed version of a document | the file path | every blob under `vault/` reachable from any ref, excluding `*.trail.md` record sidecars |
| `none` | — | — | the rule has no mechanical trace; the audit prints UNSCORABLE |

`compliant` is an ERE the unit must match, `!` plus an ERE it must not match, or one of two tokens:
`@sentence<=N` (no sentence over N words, counted by `lib/sentence-count.sh`) and `@lines<=N`.
`@doc-lint:HIST` expands to the `HIST` group of `lib/doc-lint-patterns.tsv`. Write `\|` for a
literal pipe inside a cell.

`self_checkable` is yes when compliance is decidable by looking at the text being written, and no
when it needs counting or state the writer does not hold at write time. `enforced` is yes when a
hook or script blocks the violation rather than describing it.

## Rules

| id | rule | source | corpus | form | self_checkable | enforced | denominator | compliant | note |
|----|------|--------|--------|------|----------------|----------|-------------|-----------|------|
| R-01 | commit subject uses a conventional type prefix | `commands/v-work/steps/05-commit-capture.md:57` | git-subject | requirement | yes | no | `.` | `^(feat\|fix\|refactor\|test\|docs\|chore)(\([^)]+\))?!?: ` | |
| R-02 | commit subject is 50 characters or fewer | `commands/v-work/steps/05-commit-capture.md:58` | git-subject | requirement | no | no | `.` | `^.{1,50}$` | |
| R-03 | do not auto-push | `commands/v-work/steps/05-commit-capture.md:58` | none | prohibition | yes | no | | | a push the user asked for and a push the model took on its own leave the same trace |
| R-04 | stage specific files; never `git add -A` or `git add .` | `commands/v-work/steps/05-commit-capture.md:54` | transcript-cmd | prohibition | yes | no | `^git add( \|$)` | `!^git add (-A\|-a\|--all\|\.)( \|$)` | |
| R-05 | run the bats suite through `tests/run.sh`, never bare `bats` | `tests/run.sh:2` | transcript-cmd | requirement | yes | no | `^(bats\|[^ ]*tests/run\.sh)( \|$)` | `!^bats( \|$)` | |
| R-06 | never read the contents of a file under `~/.keys/` | `~/.claude/CLAUDE.md:83` | transcript-cmd | prohibition | yes | yes | `(~\|\$HOME\|/home/[a-z]+)/\.keys(/\|$\| )` | `!^(cat\|less\|more\|head\|tail\|grep\|rg\|bat\|xxd\|od\|base64\|strings)( \|$)` | `~/.claude/hooks/block-keys.sh` runs as a `PreToolUse` hook |
| R-07 | use pnpm, never npm | `~/.claude/CLAUDE.md:84` | transcript-cmd | prohibition | yes | no | `^(npm\|pnpm\|yarn) (i\|install\|add\|ci\|remove\|up\|update)( \|$)` | `!^(npm\|yarn) ` | |
| R-08 | no sentence over 25 words in a reply | `commands/_shared/communication.md:58` | reply-text | requirement | no | no | `.` | `@sentence<=25` | enforced only from 2026-09-03 by the `Stop` hook in `hooks/hooks.json` |
| R-09 | a plan document stays under its line cap | `commands/_shared/document-standard.md:47` | doc-blob | requirement | no | yes | `^vault/plans/[^/]+\.md$` | `@lines<=300` | cap value from `bin/doc-lint.sh:65` |
| R-10 | a contract document carries no superseded state | `commands/_shared/document-standard.md:65` | doc-blob | prohibition | yes | yes | `^vault/(plans\|decisions\|architecture\|indications\|features)/` | `!@doc-lint:HIST` | |

## What the classifications rest on

R-01 is recognition: the prefix is either the first token or it is not. R-02 needs a character
count the writer does not have. R-08 needs a word count per sentence. R-09 needs a line count of a
file still being written. Every other row is decidable from the command about to be run.

`enforced` is yes on three rows only. `~/.claude/hooks/block-keys.sh` refuses the tool call for
R-06. `scripts/doc-lint-hook.sh` runs `bin/doc-lint.sh` after every `Write`, `Edit` and `MultiEdit`,
which reports R-09 and R-10 back to the model in the same turn.
