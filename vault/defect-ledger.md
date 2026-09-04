---
type: process
project: vault
slug: defect-ledger
status: current
tags: [gates, measurement]
---

# Defect ledger — one row per defect class, and whether it came back

**A repair with no test that failed before it is a claim.** `bin/gate.sh recurrence` refuses a row
whose `test` cell names no path.

Recurrence is the only measurement that shows whether a repair worked. A defect class that reappears
after its repair was applied means the repair addressed an instance, not a source.

## How a row gets added

When a session repairs a defect, add the row before the close. `test` names the test that failed
before the repair and passes after — `path:line`, or the test name in backticks. `recurrences` starts
at 0 and is incremented by whoever finds the class again.

## Defect ledger

| id | defect | repair | test | recurrences |
|----|--------|--------|------|-------------|
| D-001 | A session reported work done against a criterion nothing checked | `bin/gate.sh verdict` refuses a DONE work item whose criterion has no verdict, and `scripts/completion-hook.sh` blocks the turn end | `tests/unit/completion-hook.bats:1` | 0 |
| D-002 | A check was a command string in the plan, authored by the same session it graded | `criteria` requires a committed executable; `verdict --run` writes the verdict itself | `tests/unit/gate.bats:118` | 0 |
| D-003 | A config key existed with no code reading it, so a later session believed the question settled | `bin/gate.sh readers` greps for a reader and refuses at zero | `tests/unit/gate.bats:455` | 0 |
| D-004 | A repo never declared how to run its own checks, and the gap surfaced at the close | `bin/gate.sh config` refuses at ANALYZE; `bin/vault-init.sh` writes every key | `tests/unit/gate.bats:490` | 0 |
| D-005 | `pipefail` aborted the readers walk on the exact case it exists to report, so a spurious exit read as a refusal | guard the grep with `\|\| true` and count the matches separately | `tests/unit/gate.bats:461` | 0 |
