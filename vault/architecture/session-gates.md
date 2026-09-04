---
type: architecture
project: vault
slug: session-gates
status: current
tags: [gates, definition-of-done, enforcement]
---

# Session gates — what refuses, when, and on what evidence

`bin/gate.sh` is the single executable that refuses. Every check below is a subcommand returning
exit 1 with the missing thing named. A `/v-*` step that reaches a nonzero exit stops the lifecycle;
it never proceeds with a warning.

## Open

| id | item | state |
|----|------|-------|
| G-OPEN-2 | `/v-cr` coverage is partial by design — it reviews work it did not plan, so `criteria` and `verdict` never apply there | ACCEPTED |

## Where the state lives

The plan artifact is the session's machine-readable state. Gates parse its markdown tables; no
second state file exists. `/v-do` writes a stub plan carrying only `## Open questions`,
`## Success criteria` and `## Definition of done`.

## The subcommands

| subcommand | runs before | refuses when |
|---|---|---|
| `criteria <plan>` | work items are written | `## Success criteria` has no rows; a row has an empty `check` or `expect`; a row's `how` is not one of `command`, `artifact`, `observed`; an `observed` row names no disconfirming condition or no `no-command:` reason; no row has `kind: delivery` and the plan declares no `no-runtime:` reason |
| `verdict <plan> [--run]` | staging | `--run` re-runs every `how: command` check and the exit code disagrees with `expect`; any other row has a `verdict` other than `MET`, empty `evidence`, or `evidence` carrying neither a backticked command nor a `path:line` |
| `readers <plan>` | staging | a backticked identifier in `## Artifact lifecycles` has no reader in code outside its declaring file |
| `config <repo>` | ANALYZE, before any context load | `VAULT.md` declares no `dod_profile`, or a profile line has neither a command nor an `absent: <reason>` |
| `budget [file]` | staging | a row in `vault/check-budget.md` shows a check firing wrongly more than one time in ten |
| `recurrence [file]` | staging | a `vault/defect-ledger.md` row's `test` cell names no path |

Seven further checks are specified and not built. They live in
`vault/architecture/session-gates-unbuilt.md`, one row each with an owner and the command that
closes it. A phase that names one of them runs nothing.

`gate.sh all <plan> --phase <propose\|approve\|close>` runs that phase's subset.

## Escape hatch

`GATE=off` skips every check and exits 0. Its use is recorded in the close report as an exception,
the same way `DOC_LINT=off` is. No per-check suppression exists: a gate that can be silenced one
check at a time gets silenced.

## Table schemas the gates parse

### `## Open questions`

| id | question | blocks | searched | status | answer |

`blocks` is `yes` when a different answer changes what gets built. `searched` names the vault paths
and commands run before the question reached the operator; an empty cell is a refusal, because the
operator must never answer what the vault already answered. `status` is `open`, `answered`, or
`defaulted`. A `blocks: yes` row may not be `defaulted`.

**At most four `blocks: yes` rows per session.** A fifth refuses, and the session merges or defaults
until four remain. Agents measurably repeat questions, ask what the prompt already answered, and ask
more than the answer is worth; an uncapped gate turns into the readiness checkpoint that stops work
over small gaps.

### `## Success criteria`

| id | criterion | kind | how | check | expect | verdict | evidence |

`kind` is `unit`, `delivery`, or `artifact`. `expect` is the outcome that counts as met. `verdict` is
empty before execution, then `MET` or `NOT MET`. `evidence` carries the command and its output, or
`path:line`.

`how` says who can decide the row, and it takes three values:

| `how` | `check` holds | who decides |
|---|---|---|
| `command` | a shell command | `gate.sh verdict --run` executes it and compares the exit code to `expect` |
| `artifact` | a path, and a pattern that must appear in it | the operator; `verdict --run` executes `command` rows only and never opens the file |
| `observed` | a named procedure: what to look at, and what would make it fail | the operator |

**Not every criterion can be a command, and forcing one produces a worse check than admitting it.**
A judgement dressed as a metric is the defect: when several proxies have been tried and all of them
accept the rejected cases, the thing is unmeasured, and it is labelled unmeasured.

An `observed` row carries two extra things or the gate refuses it:

- **the disconfirming condition** — what an observer would see that makes this `NOT MET`. Without
  it the row closes on "it looked fine", which is not a check.
- **`no-command: <reason>`** — why no detector exists. This forces the question every time, and it
  is how a detector eventually gets built instead of assumed impossible.

Counting `observed` rows separately — so the enforced fraction says how much of a plan a script
can actually decide — is one of the unbuilt checks.

Write the `criterion` cell as a condition and an observable behaviour: `WHEN <trigger> THE SYSTEM
SHALL <observable>`. A criterion with no trigger and no observable is a preference, and the gate
cannot tell the two apart — the shape is what makes it checkable.

**At least one `delivery` row is required.** It may be `observed` when no runnable end-to-end path exists. An `delivery` check invokes the real system through the path the
change is meant to serve. A unit test, a fixture, and a static read are not `delivery`. A plan with no
runtime declares `no-runtime: <reason>` in frontmatter instead.

### `## Definition of done`

| id | line | state | evidence |

`state` is `met`, `failed`, or `absent: <reason>`. Silence is a refusal. A named absent reason is
legal; a missing tool is a fact, not a pass.

### `## Decisions`

| decision | reason | record |

`record` is the ADR path that carries this decision, or `local` when it binds only this change. A
decision with neither is refused, because a decision that exists only as prose gets re-litigated.

### `## Enforcement states`

| id | ruling | state | mechanism |

`state` is `ENFORCED`, `HALF-BUILT`, `PROSE`, `BOUND-UNREAD`, or `OPEN`. `ENFORCED` requires code or
a failing gate, plus a test, plus one real run. `mechanism` names the file and check that binds it.
`BOUND-UNREAD` refuses the close: a key nothing reads makes the next session believe a question is
settled and gives it no way to find out otherwise.

### `## Work items`

The existing table gains a `covers` column carrying the criterion ids that row advances.

## Definition-of-done profiles

`commands/_shared/definition-of-done.md` owns the baseline and the two profiles, `code` and
`ai-instructions`. Which one applies is read from `dod_profile:` in `VAULT.md`, and a plan may
override it in frontmatter. Nothing enforces the profile's rows yet; `dod` is unbuilt.

**Onboarding writes the profile and every command in it.** `bin/vault-init.sh` resolves the repo's
test, lint, duplication and end-to-end commands from `scripts/detect-stack.sh`, presents them for
confirmation, and writes them into `VAULT.md` under `## definition of done`. A command it cannot
resolve is written as `absent: <reason>`, never omitted.

A key that is omitted is the failure this whole design exists to stop: the next session reads no
line, assumes the question was settled, and has no way to find out otherwise. `gate.sh config`
refuses at ANALYZE when the block is missing, so an un-onboarded repo fails at the start of a
session instead of at its close.

## Verification

**The gate runs the check. No model reports whether a criterion was met.**
`gate.sh verdict --run` executes every `check` cell that is a command and compares its exit code to
`expect`.

A model asked to judge whether an agent finished cannot do it. Across 5 judges, 5 prompt strategies
and full task specifications, no configuration exceeded 0.65 AUROC, and 0.54 on execution traces —
a coin flip. Judges anchor on confident closing language, which is exactly what a false completion
claim produces. What works instead, by an order of magnitude, is an independent process that reads
the state: false completion falls from 44–52% to 3%.

### The delivery check

Every change carries one criterion that runs the real system and then looks for **this change** in
what the run produced.

Two parts, and both are needed:

| part | catches |
|---|---|
| the project's existing end-to-end suite, unchanged | what this change broke |
| one new assertion, written as part of this change | what never arrived |

The second part is the one that catches work built and never wired in. An existing suite passes
green while a new field never reaches the output, because the suite was written before the field
existed.

The evidence is the artifact the run produced — a manifest, a rendered file, a database row. The
session cannot write it; the run does. That is the property that makes this check worth more than
every other check in this file.

It runs after **each work item**, not once at the close. A check that runs only at the end finds the
same problem at the point where it costs the most.

### Reading the new thing

A criterion the gate cannot execute is `observed`: a person decides it, against the failing
condition the row names. There is no agent seat. A judgement dressed as an automated verdict is
worse than a judgement labelled as one.

A `NOT MET` verdict routes by cause and the session cannot close:

| cause | routes to |
|---|---|
| the criterion was never achievable as written | PROPOSE |
| the work was not built | EXECUTE |
| the work exists and the check does not exercise it | the test triage |

Two loops maximum. A third `NOT MET` goes to the operator with the criterion and what it would cost
to meet.
