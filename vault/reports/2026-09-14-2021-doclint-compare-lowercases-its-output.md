---
type: report
project: vault
slug: 2026-09-14-2021-doclint-compare-lowercases-its-output
date: 2026-09-14
status: open
severity: minor
found_by: /v-work, building /v-handoff and /v-report
found_in: taking a baseline test run at HEAD to separate pre-existing failures from new ones
files: [bin/doc-lint.sh, tests/unit/document-standard.bats]
tags: [report]
---

# doclint-compare-lowercases-its-output

## What is wrong

`./bin/doc-lint.sh --compare` prints each dropped rule in lower case, so an identifier the author
wrote as `VP8X` comes back as `vp8x`. `tests/unit/document-standard.bats:350` asserts the original
casing and fails.

## Files

| file (exact path) | what is wrong in it |
|-------------------|---------------------|
| `bin/doc-lint.sh` | the `--compare` path case-folds each rule line for matching and then prints the folded copy instead of the source line |
| `tests/unit/document-standard.bats` | the assertion at line 350 is `[[ "$output" == *VP8X* ]]`, which the folded output cannot satisfy |

## Consequence

Latent for correctness, live for usability. `--compare` finds the right dropped constraint and names
it; it just names it in the wrong case. The output is the thing an author greps for in the file they
are rewriting, and a case-folded identifier does not match. The proof obligation in
`commands/_shared/document-standard.md` — "`bin/doc-lint.sh --compare <before> <after>` proves which
you did" — is therefore harder to act on than it reads.

## Cause

Case folding is correct for the comparison, which must treat `Never` and `never` as the same rule,
and was carried into the printing by reusing the folded string. Matching and display need different
copies of the line.

## How to see it

```bash
T=$(mktemp -d)
printf -- '---\ntype: plan\n---\n\nThe payload must include the three reserved bytes in `VP8X`.\nNever derive format from `mime_type`.\n' > "$T/before.md"
printf -- '---\ntype: plan\n---\n\nNever derive format from `mime_type`.\n' > "$T/after.md"
./bin/doc-lint.sh --compare "$T/before.md" "$T/after.md"
```

Prints ``the payload must include the three reserved bytes in `vp8x`.``

## Repair

Keep the folded string for matching and print the source line. Run it with `/v-do`: one function in
`bin/doc-lint.sh` carries both, and the existing assertion at `tests/unit/document-standard.bats:350`
is the test.

## Not now because

Cosmetic against a session whose scope was two new commands, and the comparison itself is correct.

## Closes when

The reproduction above prints `VP8X`, and `./tests/run.sh tests/unit/document-standard.bats` passes
with the assertion at line 350 unchanged.
