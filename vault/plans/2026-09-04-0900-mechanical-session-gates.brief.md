---
type: plan
project: vault
slug: mechanical-session-gates-brief
status: proposed
tags: [brief]
---

# Session gates — the architecture

One new program, `bin/gate.sh`, is the only thing that refuses. Every rule you asked for becomes a
subcommand of it that exits non-zero and names what is missing. A command step that hits a non-zero
exit stops; it never continues with a warning.

The session's state lives in the plan file, in tables a script can read. There is no second state
file to drift.

## What refuses, and when

| moment | the gate | it refuses when |
|---|---|---|
| before any design | `clarify` | a question that would change what gets built is still open, or does not record which vault paths were already searched. Capped at four such questions per session |
| before work items exist | `criteria` | there are no success criteria, or none of them invokes the real system, or a judgement criterion does not say what would make it fail |
| before approval | `coverage` | a success criterion no work item advances |
| after each work item | `verdict --run` | the gate runs every criterion's check itself and compares the real exit code to what the plan claimed. No model reports whether the work was done |
| before commit | `verdict` `dod` `bindings` `decisions` `states` | any criterion unmet, a done-line silently skipped, a setting nothing reads, a decision with no record, a ruling that binds nothing |

The commit block is a Claude Code hook. A hook denies the tool call before the permission check and
holds even when permission prompting is off; an instruction in a command file does not.

No model reports whether a criterion was met. Where a check is a command, the gate runs it and reads
the exit code. Asking a model to judge does not work: across five judges and five prompt strategies,
none exceeded 0.65 at telling a real completion from a false one, and 0.54 on execution traces.
Judges anchor on confident closing language, which is exactly what a false claim produces.

## Not every check is a command

A criterion is decided one of three ways: a command the gate runs, a file the gate inspects, or a
named observation a person or agent makes. The third is legitimate and stays. It carries two extra
things or the gate refuses it: what an observer would see that makes it fail, and why no detector
exists. Without the first it closes on "it looked fine". Without the second, no detector ever gets
built.

The close report counts observed criteria separately, so the enforced number says how much of the
plan a script could actually decide rather than flattering it.

## Where the repo configuration comes from

`bin/vault-init.sh` asks once, at onboarding, for this repo's test, lint, duplication and
end-to-end commands, and writes them into `VAULT.md` with the chosen done profile. A command it
cannot resolve is written as `absent: <reason>`. Omitting a key is what makes the next session
believe the question was settled, so the gate refuses an omission and accepts a stated absence.

A session in a repo that was never onboarded stops at its first step, not at its last.

## What "done" means

Two profiles ship. Code: integration tests over the changed behaviour, the linter run, the
duplication detector at zero, the interface documented. AI instructions: the new element observable
in real output, the tooling it needs already present, and one run of the real workflow that used it.

Each line reads met, failed, or absent with a stated reason. Silence refuses. A missing tool is
legal once named; skipping the line is not.

## The delivery check — the change that attacks your biggest loss

Every change carries one check that runs the real system, then looks for **this change** in what the
run produced. Two parts: the project's existing end-to-end suite catches what you broke; one new
assertion, written as part of the change, catches what never arrived.

The second part is the one that matters. An existing suite passes green while a new field never
reaches the output, because the suite was written before the field existed.

The evidence is the artifact the run produced — a manifest, a rendered file, a row in a database.
The session cannot write it; the run does. It runs after each work item, not once at the end.

## Sequence

Phase 1 today: the program, two of its checks, the plan template, the wiring into `/v-work`, the
tests, and one real run of the whole chain against this plan itself.

Phases 2 to 6 later: the remaining seven checks, the done profiles, the delivery check, the
wiring into `/v-team` `/v-do` `/v-pm` `/v-cr`, the cross-plan tracker, the defect ledger, the
commit hook, and the decision record.
