---
type: indication
project: vault
slug: rules-routed-not-recalled
scope: repo
tags: [indication]
---

# rules-routed-not-recalled

## Rule
Compute which project rules a change can break, assign each one to a reviewer, and print how many
were decided — never let rule-fetching be a consequence of what a file reminded a reviewer of. A
reviewer's verdict counts only when a tool can resolve the line it cites; a verdict that asserts the
rule never applied states the rule's own trigger instead, and is counted apart from the rules that
were actually decided.

## Rationale
A reviewer handed a rule index cites the rules a file happens to bring to mind. That produces sound
findings and an unearned silence: no citation for a rule is indistinguishable from the rule having
been checked and held. A review that consulted four rules of a hundred and forty-nine reads exactly
like one that consulted all of them, because the only number it prints is the count of findings.

Routing fixes the numerator. The anchor check is what stops the fix from being cosmetic — without
it, a reviewer that echoes its assignment back with "holds" and any line from the diff scores full
coverage, and a reviewer that answers "not applicable" to everything scores it too.

The buckets the routing cannot reach are the point of printing them. A rule about a contract between
files names no changed path, so it lands in `no-match` on every diff; a rule whose index cell is
prose lands in `unroutable` on every diff in the project. Those are unmeasured, not clean, and a
summary that folds them into a coverage number is worse than one that prints no number at all.

## Examples
Do: `cr_rule_route` in `lib/cr-helpers.sh` buckets every index row exactly once against the changed
files; `cr_anchor_check` rejects a citation whose quoted token is not on the line it names;
`cr_rule_coverage` prints `checked · routed-unchecked · no-match · unroutable` and refuses only on
the second. `bin/indication-route-audit.sh` lists the rows a project's own index cannot route.

Don't: "fetch a full rule body on demand, by slug, when a critic is about to cite that rule" — the
instruction this replaced. It makes the model's recall the router, records nothing, and cannot be
audited afterwards.

## Applies-to
`lib/cr-helpers.sh`, `commands/v-cr/steps/**`, `commands/_shared/critic-panel.md`, `bin/indication-route-audit.sh`
