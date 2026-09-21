---
type: indication
project: vault
slug: bats-negative-assertions-need-a-function
scope: repo
tags: [indication, testing, bats]
---

# bats-negative-assertions-need-a-function

## Rule
In a bats test, assert that text is absent with a function that returns 1, never with a bare `! grep`
in the middle of the test body.

Recognition test: every line of a test body that begins with `!` is the last command of that test, or
it is not there.

## Rationale
Bash `set -e` does not fail on a negated command, so `! grep -q x file` in the middle of a test passes
whether or not the text is present. In this repo a seeded break in the page renderer survived a test
that held three such lines. Routing the assertion through `absent() { if grep -qF -- "$1" "$2"; then
return 1; fi; }` made the same break fail. `tests/unit/v-team.bats` still carries the bare form.

## Examples
- Do: `absent '<script' "${PAGE}"`.
- Do: after a change, break the code on purpose in a copy and confirm a test fails.
- Don't: `! grep -q '<script' "${PAGE}"` followed by more assertions.

## Applies-to
`tests/unit/*.bats`
