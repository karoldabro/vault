---
type: instruction
campaign: 2026-09-15-0933-doc-corpus
tags: [campaign, engine, slots]
---

# What a non-testing campaign needed from the engine

This campaign exists to answer one question with observations instead of a claim: does the `/v-loop`
loop work on a task that is not testing? Each row below is a slot the engine must offer, how this
campaign filled it, and whether the testing shape fit.

The consumer of this file is the session that writes the task-agnostic engine. A row marked
**differs** is a place where the engine cannot keep its current wording.

## The slots

| slot | how this campaign filled it | fits the testing shape? |
|------|-----------------------------|--------------------------|
| unit of work | one document, plus any sidecar the repair creates | differs — a case is not always one file |
| backlog | the 17 documents whose `./bin/doc-lint.sh` exit is non-zero, enumerated by running it over every `vault/**/*.md` | fits |
| actor | an agent that rewrites one document against `commands/_shared/document-standard.md` | fits |
| verifier | `./bin/doc-lint.sh <path>`, an exit code | differs — see "The verifier decides the rules" |
| caps | 3 rounds, 3 repair attempts per document | fits |
| stop rule | every ledger row terminal and none failing | fits |

## The discriminator is a case, not a field

The engine asks every case for a contrary condition that must produce a different outcome. For a
test that is one field on the row. For a document rewrite the contrary condition is **a different
input file**, so it cannot sit on the row it is meant to discriminate.

This campaign uses **control rows** instead: `CTL-01` and `CTL-02` name documents that already pass,
and each must come back byte-identical, checked by `git hash-object` against the value recorded when
the ledger was written. A campaign whose control rows drift has an actor rewriting things nobody
asked it to rewrite, and its passes mean nothing.

**For the engine:** the discriminator belongs to the adapter, not to the shared contract. The shared
contract asks only that every campaign be able to fail — how it proves that is the adapter's answer.

## The arena needs two facts, and one of them is usually wrong

The arena is the git worktree on branch `campaign/doc-corpus`, and the restore is
`git checkout -- vault/ && git clean -fd vault/`.

`git checkout -- vault/` on its own restores tracked files and leaves every untracked file in place,
so an arena restored with it still carries the last run's output. A restore command is only real when
the session runs it once at intake and re-reads the arena afterwards.

A worktree was required rather than preferred: another session works in the main checkout, so a
campaign acting there would have destroyed work nobody offered up.

**For the engine:** the refusal asks for the arena's name and its restore command, and then proves
the restore by running it. Naming it is not enough.

## A conflict scope covers the unit, not the file

Thirteen cases move a `## Critique trail` section out of a plan and into a sidecar that does not
exist yet. Each case therefore writes two paths. A scope of `file:<path>` fences only one of them and
lets a second agent take the sidecar.

**For the engine:** `conflicts_on` names every path the unit of work touches, and the fence is built
from that list rather than from the case's own file.

Rules the engine must state about verification, backlogs and briefs: `engine-rules.md`.
