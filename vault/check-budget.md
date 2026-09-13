---
type: process
project: vault
slug: check-budget
status: current
tags: [gates, measurement]
---

# Check budget — how often each gate check is wrong

**A check that fires wrongly more than one time in ten is fixed or deleted.** `bin/gate.sh budget`
reads this file and refuses above that line.

The number is not tidiness. Google launches a Tricorder analyzer only below a 10% false-positive
rate and disables one that climbs above it; their whole platform runs under 5%. A check people stop
trusting is not ignored selectively — it is switched off wholesale, and every other check goes with
it. `GATE=off` is this framework's version of that switch, so one noisy check costs all of them.

## How a row gets updated

Add one to `fires` each time the check refuses. Add one to `wrong` when the thing it refused is
correct in the working system: the check matched the text and misread the state. Only the operator
sets `wrong`; a session never scores its own refusal.

## Check budget

| check | fires | wrong | note |
|-------|-------|-------|------|
| criteria | 0 | 0 | |
| coverage | 0 | 0 | `cmd_coverage`; refuses only on a criterion no work item's `covers` cell names |
| verdict | 0 | 0 | |
| readers | 0 | 0 | |
| config | 0 | 0 | |
| budget | 0 | 0 | |
| recurrence | 0 | 0 | |
| completion-hook | 0 | 0 | |
| staging-hook | 0 | 0 | |
| rule-coverage | 0 | 0 | `cr_rule_coverage`; refuses only on a routed rule nobody decided |
| anchor-check | 0 | 0 | `cr_anchor_check`; refuses a citation whose token is not on the line it names |

## What the checks do not cover

`checks/v-loop-SC-3.sh` matches the shared modules' literal wording. A rule reworded rather than
copied passes it, so a green run means no verbatim duplicate rather than no duplicate.

`cr_rule_coverage` measures the rules a changed-file glob could reach. Two buckets are outside it and
are printed rather than counted as clean: `no-match`, a rule whose globs reached nothing in this diff,
and `unroutable`, a rule whose index cell is prose no router can read. A rule about a contract between
files or repos names no changed path and lands in one of them on every diff: 42 of 44 rows
(`bin/indication-route-audit.sh ~/vault/givore/indications/cross-repo/_index.md`). Nobody verdicts
those rules, and a summary that folds them into a coverage number reports thoroughness it did not
have.

`bin/rule-count.sh` counts the `/v-team` corpus. `commands/v-loop.md` and its rules file are counted
apart, by `checks/v-loop-SC-4.sh`, because a campaign is a separate read set: no session loads both.
Counting them together would raise a budget that is already over, which hides the overrun instead of
recording it.

## Rules kept as prose

Rules with no check behind them. This list stays short: every entry is a rule the framework asks a
session to remember, and compliance falls as that count rises.

| rule | where | why no check |
|------|-------|--------------|
| read the communication contract before writing output | `commands/_shared/communication.md` | no hook fires before a model writes prose; `bin/output-lint.sh` measures the reply afterwards instead |
| a criterion decided by observation | `vault/architecture/session-gates.md` | no artifact carries the signal; the operator decides it against the failing condition the row names |
| leave pushing to the operator | `commands/v-work/steps/05-commit-capture.md` | unmeasurable as written: a push the operator asked for and a push taken unprompted leave the same trace, so no check can separate them |
| the campaign operating rules | `commands/v-loop/campaign-rules.md` | a campaign runs against a stack that is not this repo, so nothing here can observe whether a rule held. The one rule that needed a counter — a cap on concurrent testers — was reworded to "one tester unless the conflict sets are disjoint", which a session decides from the ledger row it is writing. Revisit when a run violates one |
