---
type: architecture
project: vault
slug: session-gates-unbuilt
status: current
tags: [gates, enforcement, backlog]
---

# Session gates — the checks that are specified and not built

`vault/architecture/session-gates.md` describes the gate that refuses. This file holds the six
checks that document specified before they existed. A phase that names one of them runs nothing, and
a plan relying on one closes ungated.

Each row carries the command that closes it. The command exits 2 with `unknown subcommand` today;
it exits 0 or 1 on a real plan once the check is built, and `checks/doc-truth-SC-1.sh` then refuses
until the row is deleted here and added to the subcommand table in `session-gates.md`.

## The unbuilt checks

| id | check | would refuse when | owner | closes when |
|----|-------|-------------------|-------|-------------|
| U-1 | `clarify <plan>` | a `## Open questions` row has `blocks: yes` and `status: open`; a row has an empty `searched` cell; a row has `blocks: yes` and `status: defaulted` | operator | `bin/gate.sh clarify <plan>` exits 1 on a plan with a blocking open question and 0 on one without |
| U-3 | `dod <plan>` | a `## Definition of done` row's `state` is not `met`, `failed`, or `absent: <reason>`; any row is `failed` | operator | `bin/gate.sh dod <plan>` exits 1 on a plan with an empty `state` cell |
| U-4 | `bindings <plan> [root]` | a backticked identifier in `## Artifact lifecycles` has no reader in code outside its declaring file | operator | `bin/gate.sh bindings <plan>` exits 1 on a plan naming an identifier nothing reads. `readers` already does this; U-4 closes by deleting the name or by splitting the two |
| U-5 | `decisions <plan>` | a `## Decisions` row's `record` cell is neither a repo-relative path nor the literal `local` | operator | `bin/gate.sh decisions <plan>` exits 1 on a plan with an empty `record` cell |
| U-6 | `states <plan>` | any `## Enforcement states` row reads `BOUND-UNREAD`; prints `ENFORCED n/total` | operator | `bin/gate.sh states <plan>` exits 1 on a plan carrying a `BOUND-UNREAD` row and prints the fraction on one that does not |
| U-7 | `tracker <vault>` | a plan with `status: proposed` or `approved` has open rows absent from `vault/_open.md` | operator | `bin/gate.sh tracker vault/` exits 1 while `vault/_open.md` is missing, which it is |

## Why they are listed rather than deleted

A specified check that is deleted is re-specified by the next session that wants it, and the
argument is had twice. A specified check left inside the contract document is read as active, and a
session believes its work was gated when nothing ran. The row is the third option: the check is
still wanted, it does not run, and the command that would prove it works is written down.

U-4 is the one to resolve first, because `readers` already refuses on the same condition. Either the
two are the same check under two names, or `bindings` covers something `readers` does not — and
until that is settled, `session-gates.md` risks growing the name back.
