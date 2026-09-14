---
type: report
project: vault
slug: 2026-09-14-2021-doclint-unknown-type-note-untestable
date: 2026-09-14
status: open
severity: major
found_by: /v-work, building /v-handoff and /v-report
found_in: writing checks/handoff-SC-4.sh, which tried the same assertion and had to be rewritten
files: [bin/doc-lint.sh, tests/unit/document-standard.bats]
tags: [report]
---

# doclint-unknown-type-note-untestable

## What is wrong

`bin/doc-lint.sh` emits its unknown-type note only inside the header line, and the header prints only
alongside a finding. A document with an unrecognised `type:` and no other violation is graded at the
400-line default cap in silence, and `tests/unit/document-standard.bats:308` fails because it asserts
the note on exactly such a file.

## Files

| file (exact path) | what is wrong in it |
|-------------------|---------------------|
| `bin/doc-lint.sh` | `type_note` is built at line 618 and reaches output only through the header that `finding()` triggers, so a clean file of an unknown type prints nothing |
| `tests/unit/document-standard.bats` | the test at line 305 writes `type: bananas` with the body `A line.`, which produces no finding, then asserts `unknown type` appears in the output |

## Consequence

This has already happened. The documents most likely to need a cap are the ones that escape it: an
unrecognised type takes the loosest cap in the table and nothing tells the author. The test that
exists to catch it has been red at least since `e32a921` and reports the gap as a test failure rather
than as the linter's own behaviour, so the suite carries a permanent red that nobody acts on.

## Cause

The note was written as a decoration on the header rather than as a finding. The comment at
`bin/doc-lint.sh:614-617` states the intent: the note "rides along with a real finding rather than
printing on its own", because a notice on an otherwise-clean file is noise. That reasoning holds for
noise and fails for this case, since an unknown type is the one condition that makes every other
finding unreliable.

## How to see it

```bash
T=$(mktemp -d)
printf -- '---\ntype: bananas\n---\n\nA line.\n' > "$T/odd.md"
./bin/doc-lint.sh --force "$T/odd.md"; echo "exit=$?"
```

Prints nothing and exits 0. The same file with an over-long sentence appended prints
`[bananas/contract, N lines, cap 400 — unknown type, set \`type:\` in frontmatter]`.

## Repair

Make the unknown type its own finding code rather than a header decoration, so it prints on a
file that is otherwise clean. Run it with `/v-do`: one emit site in `bin/doc-lint.sh`, one row in
`lib/doc-lint-patterns.tsv` if codes are listed there, and the existing assertion at
`tests/unit/document-standard.bats:308` then passes unchanged.

Decide first whether the finding should exit nonzero. A warning that exits 0 keeps every existing
caller's behaviour; a violation that exits 1 would newly fail any document in the repo whose type is
unregistered, which is worth counting before choosing.

## Not now because

The session that found it was adding two commands, and changing what `bin/doc-lint.sh` exits on
touches the `PostToolUse` hook that runs against every file every session writes.

## Closes when

```bash
./tests/run.sh tests/unit/document-standard.bats
```

passes with the assertion at line 308 unchanged, and the reproduction above prints the note.
