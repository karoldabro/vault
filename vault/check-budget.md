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
| verdict | 0 | 0 | |
| readers | 0 | 0 | |
| config | 0 | 0 | |
| completion-hook | 0 | 0 | |
| staging-hook | 0 | 0 | |

## Rules kept as prose

Rules with no check behind them. This list stays short: every entry is a rule the framework asks a
session to remember, and compliance falls as that count rises.

| rule | where | why no check |
|------|-------|--------------|
| read the communication contract before writing output | `commands/_shared/communication.md` | no hook fires before a model writes prose; `bin/output-lint.sh` measures the reply afterwards instead |
| a criterion decided by observation | `vault/architecture/session-gates.md` | no artifact carries the signal; the operator decides it against the failing condition the row names |
| leave pushing to the operator | `commands/v-work/steps/05-commit-capture.md` | unmeasurable as written: a push the operator asked for and a push taken unprompted leave the same trace, so no check can separate them |
