---
type: indication
project: vault
slug: enforced-not-just-stated
scope: repo
tags: [indication, contracts, testing, doc-lint]
---

# enforced-not-just-stated

## Rule
A command contract that states a threshold, a limit, or a mechanical check must name the function
that computes it and ship a test that fails without it. Five obligations:

1. **A number needs a measurement.** A threshold with no helper behind it can never fire. Name the
   function in the step file, in a fenced call.
2. **Calling a check "mechanical" makes it code, not prose.** If no function implements it, delete
   the word or write the function.
3. **Prove the guard can fail.** Plant the violation the test exists to catch and watch it go red
   before you trust it green.
4. **Assert absence through `run`, never `! grep`.** A command prefixed with `!` is exempt from
   `set -e`, so `! grep -q '<string that is present>'` returns success and the assertion is
   decorative. Write `run grep -q <pattern> <file>` then `[ "$status" -ne 0 ]`.
5. **A contract grep names the fenced call, not the bare token.** A function's name also appears in
   the prose around it, so a token grep still passes after the invocation is deleted — and pair it
   with `grep -qE '^<fn>\(\)' lib/<file>.sh` so the step file cannot name a function nobody wrote.

Applies equally to a rule this repo writes about itself and to one it writes for a project.

## Rationale
A stated-but-unenforced rule reads exactly like an enforced one, so nobody looks again. Four
instances shipped in this framework and survived review:

- `03-review.md` §3.2 set a large-diff guard at ~1500 changed lines while `lib/cr-helpers.sh` held no
  function that measured a diff — a 523-file, 50,817-line changeset ran through it untouched.
- `04-post.md` §4.2 described a "mechanical" vault-text check and justified it with "an instruction is
  not a control", while being only an instruction itself.
- The anti-git-write test matched `^[^#|>-]*`, whose negated class cannot consume a leading `-`, so
  every bullet was exempt; it passed against a planted `git push` in a step file.
- Every `! grep` absence assertion in `tests/unit/` is a no-op — roughly 24 of them across seven
  files. A probe confirmed it: `! grep -q 'test-unit' Makefile` passed with the string present,
  while `run grep` + `[ "$status" -ne 0 ]` on the same input failed.

The last two are the general case: a guard nobody has seen fail is a guess about its own regex.

## Examples
- Do: `03-review.md` §3.2 names `cr_diff_stats`, `lib/cr-helpers.sh` defines it, and
  `tests/unit/cr-coverage.bats` asserts it on a 523-file fixture.
- Do: pair every contract-grep test with one that runs the same pattern against a planted violation
  (`tests/unit/v-cr.bats`, "the anti-write test actually fails on a planted violation").
- Don't: write "cap the set at 10" or "reject bodies over N characters" with nothing that counts.
- Don't: assert a step file contains a sentence and call the behaviour covered — that test still
  passes when the rule is demoted to a rationale aside.
- Don't: write `! grep -q <superseded wording> <file>` and believe the old wording is gone.

## Applies-to
`commands/**/steps/*.md` and `commands/_shared/*.md` (any stated threshold or check), `lib/*.sh`
(where the computation lives), `bin/doc-lint.sh`, and `tests/unit/*.bats`.
