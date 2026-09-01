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
that computes it and ship a test that fails without it. Three obligations:

1. **A number needs a measurement.** A threshold with no helper behind it can never fire. Name the
   function in the step file, in a fenced call.
2. **Calling a check "mechanical" makes it code, not prose.** If no function implements it, delete
   the word or write the function.
3. **Prove the guard can fail.** Plant the violation the test exists to catch and watch it go red
   before you trust it green.

Applies equally to a rule this repo writes about itself and to one it writes for a project.

## Rationale
A stated-but-unenforced rule reads exactly like an enforced one, so nobody looks again. Three
instances shipped in this framework and survived review:

- `03-review.md` §3.2 set a large-diff guard at ~1500 changed lines while `lib/cr-helpers.sh` held no
  function that measured a diff — a 523-file, 50,817-line changeset ran through it untouched.
- `04-post.md` §4.2 described a "mechanical" vault-text check and justified it with "an instruction is
  not a control", while being only an instruction itself.
- The anti-git-write test matched `^[^#|>-]*`, whose negated class cannot consume a leading `-`, so
  every bullet was exempt; it passed against a planted `git push` in a step file.

The third is the general case: a guard nobody has seen fail is a guess about its own regex.

## Examples
- Do: `03-review.md` §3.2 names `cr_diff_stats`, `lib/cr-helpers.sh` defines it, and
  `tests/unit/cr-coverage.bats` asserts it on a 523-file fixture.
- Do: pair every contract-grep test with one that runs the same pattern against a planted violation
  (`tests/unit/v-cr.bats`, "the anti-write test actually fails on a planted violation").
- Don't: write "cap the set at 10" or "reject bodies over N characters" with nothing that counts.
- Don't: assert a step file contains a sentence and call the behaviour covered — that test still
  passes when the rule is demoted to a rationale aside.

## Applies-to
`commands/**/steps/*.md` and `commands/_shared/*.md` (any stated threshold or check), `lib/*.sh`
(where the computation lives), `bin/doc-lint.sh`, and `tests/unit/*.bats`.
