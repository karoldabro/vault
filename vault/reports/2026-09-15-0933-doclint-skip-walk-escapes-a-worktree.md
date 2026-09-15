---
type: report
project: vault
slug: doclint-skip-walk-escapes-a-worktree
date: 2026-09-15
status: open
severity: major
found_by: 2026-09-15-0933-doc-corpus campaign, case DOC-03
found_in: linting documents inside a git worktree
files: [bin/doc-lint.sh]
tags: [report]
---

# doclint-skip-walk-escapes-a-worktree — report

## What is wrong

`load_skip_file` ends its upward walk at `[ -d "${dir}/.git" ]`, and a git worktree's `.git` is a
file, so the walk passes the repository root and reads `.doc-lint` files from outside it.

## Files

| file (exact path) | what is wrong in it |
|-------------------|---------------------|
| `bin/doc-lint.sh` | line 391 tests `-d "${dir}/.git"`; a worktree, a submodule and a `git init --separate-git-dir` checkout all carry `.git` as a file |

## Consequence

A document linted inside a worktree is graded against exemptions its repository never declared, and
a passing exit code means only that no unexempted rule fired. Whoever owns the parent directory
decides which rules apply — under `/tmp` that is any process on the machine.

This has already happened: a repository placed under `/tmp` inherits whatever `.doc-lint` sits in a
`/tmp` parent.

## Cause

The check asks whether a directory named `.git` exists, which answers "is this a normal checkout"
rather than "is this a repository root". `git rev-parse --show-toplevel` answers the second and is
what the walk needs.

## How to see it

Two runs of the same file, differing only in whether `.git` is a file or a directory:

```
mkdir -p /tmp/probe/repo
printf 'HIST7\n' > /tmp/probe/.doc-lint
printf -- '---\ntype: instruction\ntags: [probe]\n---\n\n# probe\n\nSessions used to be process-oriented and carried no assertable statement.\n' > /tmp/probe/repo/d.md

printf 'gitdir: /nowhere\n' > /tmp/probe/repo/.git     # worktree shape
./bin/doc-lint.sh /tmp/probe/repo/d.md                 # exit 0 — suppressed from outside the repo

rm -f /tmp/probe/repo/.git && mkdir /tmp/probe/repo/.git
./bin/doc-lint.sh /tmp/probe/repo/d.md                 # exit 1 — HIST7 reported
```

## Repair

Stop the walk at the real repository root. In `load_skip_file`, replace the `-d` test with a check
that accepts both shapes — `[ -e "${dir}/.git" ]` — or resolve the boundary once with
`git -C "$dir" rev-parse --show-toplevel`. The same boundary is described at `bin/doc-lint.sh:226`
for the second walk, which needs the same correction.

`/v-work` covers it: it changes how every document in every worktree is graded, and
`./tests/run.sh tests/unit` must gain a case for each `.git` shape.

## Not now because

A campaign is running against this linter, and changing the verifier mid-run voids the verdicts
already recorded in `vault/campaigns/2026-09-15-0933-doc-corpus/ledger.jsonl`.

## Closes when

The two runs under "How to see it" both report `HIST7` and exit 1.
