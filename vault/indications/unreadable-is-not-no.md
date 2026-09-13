---
type: indication
project: vault
slug: unreadable-is-not-no
scope: repo
tags: [indication, gates, exit-codes]
---

# unreadable-is-not-no

## Rule
A check reports "the answer is no" and "I could not read the question" as different results, and a
reader shared by two callers lets each caller choose what missing data means. Three obligations:

1. **Two exit codes, two meanings.** Exit 1 is the substantive verdict a caller may act on. Exit 2
   is an error: the input could not be parsed. A check that returns 1 for both lets a malformed
   table trigger the consequence the verdict carries.
2. **State which exit code the caller acts on.** The caller that turns an exit code into a
   destructive or terminal outcome names the code it keys on, in the step file. `/v-team` Step 4
   sets `status: failed` on exit 1 only.
3. **A shared parser returns "cannot say"; it does not decide what that means.** Where two callers
   read the same field, the extracted function signals the missing case and each caller supplies its
   own default. A single shared default makes one caller unusable and the other dishonest.

## Rationale
`due_criteria` and `cmd_coverage` in `bin/gate.sh` both read the work items' `covers` column, and
they need opposite defaults when it is absent. A close gate that refuses an unsayable question is
unusable on a multi-session plan's first checkpoint, and an unusable gate gets switched off. A
coverage gate that assumes every criterion is covered reports thoroughness it never had. Collapsing
those into one default breaks whichever caller loses.

The exit-code half has a sharper failure. `/v-team` Step 4 turns `coverage`'s exit 1 into
`status: failed`, which ends the session. Had a parse error also returned 1, a plan with a renamed
column would have been reported to the operator as work that cannot reach its own goals.

`die()` already exits 2 for an unknown subcommand, so an exit-2 assertion written before the
subcommand exists passes against a gate that was never built. A test asserting exit 2 also asserts
the message, or it is satisfied by absence.

## Examples
- Do: `covers_pairs` in `bin/gate.sh` returns 2 when the plan carries no `covers` column;
  `due_criteria` treats that as every criterion being due and `cmd_coverage` refuses to guess.
- Do: `tests/unit/gate.bats` asserts both directions — "a work-items table with no covers column
  leaves every criterion due" beside "coverage exits 2 on a work-items table with no covers column".
- Do: `cr_rule_coverage` prints its `no-match` and `unroutable` buckets rather than folding them
  into a coverage number.
- Don't: return 1 from a check for both "this plan fails" and "this plan is malformed".
- Don't: assert only an exit code when the same code is returned for an unbuilt subcommand.

## Applies-to
`bin/gate.sh` and `bin/*.sh` (where checks return codes), `lib/*.sh` (where shared readers live),
`commands/**/steps/*.md` and `commands/v-*.md` (where a caller acts on a code), `tests/unit/*.bats`.
