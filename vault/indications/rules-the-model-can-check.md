---
type: indication
project: vault
slug: rules-the-model-can-check
scope: repo
tags: [indication, rules, compliance, enforcement]
---

# rules-the-model-can-check

## Rule
Write a rule the model can decide from the text it is writing. Where compliance needs a count, or
state the writer does not hold at write time, ship the check or delete the rule. Four obligations:

1. **State the rule as a recognition test.** "The subject starts with one of these six types" is
   decidable while writing. "The subject is 50 characters or fewer" is not — it needs a count.
2. **A rule that needs a count needs a hook.** A cap the model cannot check itself against holds only
   because something counts for it. Name the script and register it, or drop the cap.
3. **Do not reword a rule to fix compliance.** Grammar is not the lever. Rewriting a prohibition as a
   requirement changes every file a session reads and moves nothing measurable.
4. **Score a rule before deleting it.** `bin/rule-audit.sh` scores a rule from real invocations.
   Unchecked rules span 18.1% to 98.8%, so "no check behind it" is not a reason to cut.

## Rationale
Two rules sit in one sentence at `commands/v-work/steps/05-commit-capture.md:57-58`. Same file, same
position, same age, both requirements, neither enforced. The conventional-type prefix is followed on
144 of 155 commits; the 50-character subject limit on 28 of 155. A 74.8-point gap that no account of
file size, position, structure or grammar covers.

Across the eight framework rules that could be scored, rules decidable from the text average 92.0%
and rules needing a count 64.3%. Inside the unenforced group the split is 88.6% against 46.5%. The
300-line plan cap is the counter-case that proves the second obligation: it is uncountable at write
time and holds at 50 of 50, because `scripts/doc-lint-hook.sh` counts the lines after every write.

Grammar runs the wrong way here. Prohibitions average 89.5% and requirements 76.9%.

Full rates, limits and the commands behind them: `vault/research/rule-compliance.md`.

## Examples
- Do: `commands/v-work/steps/05-commit-capture.md:57` names six commit types. The model checks the
  first token against a list it is holding.
- Do: the plan line cap lives in `bin/doc-lint.sh` and fires through `scripts/doc-lint-hook.sh`, so
  the model is told the count it could not take.
- Don't: write "subject ≤50 chars" with nothing that counts characters. It scores 18.1%.
- Don't: rewrite `Never git add -A` as `Stage each file by name` and expect the rate to move. The
  prohibition scores 74.1%; its grammar is not what is costing the other 25.9%.
- Don't: delete a rule because no check enforces it. The bats-through-`tests/run.sh` requirement has
  no check and scores 98.8%.

## Applies-to
`commands/**/*.md` and `commands/_shared/*.md` (where rules are written), `hooks/hooks.json` and
`scripts/*-hook.sh` (where a rule that needs a count gets one), `bin/rule-audit.sh` and
`vault/research/rule-inventory.md` (where a rule is scored before it is cut).
