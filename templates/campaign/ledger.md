---
type: instruction
campaign: {{slug}}
tags: [campaign, ledger]
---

# {{slug}} — case ledger

The ledger is `ledger.jsonl` beside this file. This document is its contract.

## Why the ledger is append-only JSONL

A campaign session dies mid-write at a usage limit. An append-only file truncates at most its last
line, and a reader skips that line and keeps every case before it. A file rewritten in place loses
everything and takes one writer at a time.

**The last line for an id wins.** A case that runs twice appends twice, and the reader folds by id.

**A verdict expires when its case changes.** An agent that reworks a case after reporting appends a
new row rather than editing the old one, and the orchestrator re-runs the verifier before it stands.

## The row

One JSON object per line. Every field is required; an empty string is the honest value for one that
does not apply yet.

| field | meaning |
|-------|---------|
| `id` | the case id, stable for the life of the campaign |
| `surface` | the screen, endpoint or job the case exercises |
| `kind` | the adapter's case kinds; `document-corpus` uses `repair` and `control`, `test-and-repair` uses `happy` and `injection` |
| `title` | what the case proves, as an outcome the user sees |
| `discriminator` | how this row proves it can fail — the adapter's failure shape. `""` when the adapter proves it with separate control rows instead |
| `conflicts_on` | **every path this unit of work writes**, not just the one the case is named for. A case that creates a sidecar names both |
| `check` | the command that produces this row's verdict, at its exact path |
| `status` | `planned`, `authored`, `pass`, `fail`, `blocked` or `flaky` |
| `reason` | the verifier's **own message text**, never a rule code expanded from memory; on `blocked` it must state the exact unblock action |
| `run_at` | ISO timestamp of the run that produced this status |
| `evidence` | path to the result file |

## Statuses

`pass`, `fail` and `blocked` are terminal. `planned` and `authored` mean the case has not run.

**`blocked` is not `fail`.** A case that cannot run for an environmental reason is `blocked` and its
`reason` must carry the action that unblocks it. Recording it as `fail` makes the failure count
mean nothing, which is the number the campaign exists to produce.

## Conflict scopes

`conflicts_on` is how the orchestrator decides which cases may run together. Two agents run at the
same time only when their scopes are disjoint. A scope of `global` runs alone.

| scope | what it means |
|-------|---------------|
| `global` | empties a shared inbox, changes shared config, drains a queue, renames a shared file |
| `<axis>:<id>` | one tenant, store, customer or account on an axis this project has |
| `none` | reads only, and shares nothing another case writes |

The axes are the project's own. A session reads them from the repo rather than assuming them.

A scope keyed on anything but a path is a defect: two documents sharing a slug are two units of work,
and a scope naming the slug would fence them as one.
