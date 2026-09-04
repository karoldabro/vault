---
type: plan
project: {{project}}
slug: {{slug}}
repos: [{{repos}}]                   # blast radius — every repo this touches
status: proposed                     # proposed | approved | executed | superseded
process_record: {{slug}}.trail.md    # sibling record file: findings, dispositions, rejected options
session: {{session}}                 # the session that executed this, once it has
tags: [plan]
---

# {{slug}} — plan

<!-- Governed by commands/_shared/document-standard.md. Contract class: current truth only.
     Everything about HOW this plan was reached — critic findings, rounds, rejected options,
     research that did not survive — goes to the sibling {{slug}}.trail.md and is never repeated
     here. Run bin/doc-lint.sh on this file before naming its path to anyone. -->

## Task
<!-- One sentence: what gets built and where. Then the keywords the implementer will search for. -->

## Open & deferred
<!-- The ONLY place open work lives, and it sits near the top so nobody reads 300 lines to find it.
     open (undecided, blocks work) · blocked (waiting on something named) · needs the operator.
     Then accepted deferrals: what is knowingly not being done, and why. Anything you could not
     verify belongs here. When a line closes, delete it — never mark it done. -->

## Open questions
<!-- Read by `bin/gate.sh clarify`, which refuses while any `blocks: yes` row is still `open`.
     `blocks` is `yes` only when a different answer changes what actually gets built. Everything
     else you decide yourself and record — a gate that holds work on trivia stops being used.
     `searched` names the vault paths and commands you ran BEFORE the question reached the operator;
     an empty cell is a refusal, because nobody should answer what the vault already answered.
     `status` is open | answered | defaulted. A `blocks: yes` row may never be `defaulted`.
     At most four `blocks: yes` rows: agents measurably repeat questions and ask what the prompt
     already answered. Delete a row once it is answered and the answer has moved into Decisions. -->

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
|    |          |        |          |        |        |

## Success criteria
<!-- Read by `bin/gate.sh criteria` before work items may be written, and by `bin/gate.sh verdict`
     before anything is staged. Write each criterion as `WHEN <trigger> THE SYSTEM SHALL
     <observable>` — a sentence with no trigger and no observable is a preference.

     `how` says who can decide the row:
       command   — a shell command in backticks; `gate.sh verdict --run` executes it and compares
                   the real exit code to `expect`. No model's opinion is involved.
       artifact  — a path, plus what must appear in it.
       observed  — a named procedure a person or the verifying agent follows. Legal and sometimes
                   the only honest option. It carries TWO extra things or the gate refuses it:
                   what an observer would see that makes it FAIL, and `no-command: <why no
                   detector exists>`. Without the first it closes on "it looked fine"; without the
                   second, nobody ever builds the detector.

     AT LEAST ONE ROW MUST BE `kind: delivery` — a run of the real system through the path this change
     serves, not a fixture and not a unit test. A plan with nothing to run declares
     `no-runtime: <reason>` in frontmatter instead. This is the row that catches work which passed
     its own tests and was never wired into anything.

     `verdict` and `evidence` stay empty until EXECUTE. Fill `evidence` BEFORE `verdict`. -->

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
|    |           |      |     |       |        |         |          |

## Definition of done
<!-- The baseline and the profiles live in commands/_shared/definition-of-done.md; the commands
     live in this repo's VAULT.md. Copy one row per line that applies and fill `state`:
     `met` | `failed` | `absent: <reason>`. Silence is a refusal and a `failed` row stops the close.
     A missing tool is a fact — write `absent: no duplication detector in this repo`, never blank. -->

| id | line | state | evidence |
|----|------|-------|----------|
|    |      |       |          |

## Enforcement states
<!-- Only for work whose deliverable is a RULE — a guideline, a convention, an instruction to a
     future session. One row per ruling this plan lands.
       ENFORCED     code or a failing gate, plus a test, plus one real run that exercised it
       HALF-BUILT   one end exists, the other does not, and it is labelled
       PROSE        written down, on a read path, nothing fails if it is ignored
       BOUND-UNREAD a key, flag or field exists and no code reads it — worse than nothing, and
                    `gate.sh states` refuses the close on it
       OPEN         not started
     The test for ENFORCED: if the next session reads no document, does this still bind? -->

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
|    |        |       |           |

## Verified current state
<!-- Facts the implementer must not re-derive: `fact · how it was checked · date`. Only facts that
     change an implementation choice. An assumption that was NOT verified goes in Open & deferred. -->

## Decisions
<!-- What is settled, so nobody re-opens it mid-implementation. The reason must be shorter than the
     decision. No alternatives, no who-argued-what: those live in the process_record file.
     `record` is the ADR path that carries this decision, or the literal `local` when it binds only
     this change. `bin/gate.sh decisions` refuses a row with neither — a decision that exists only
     as prose gets re-litigated, and answering the same question twice is what this column stops. -->

| decision | reason | record |
|----------|--------|--------|
|          |        |        |

## Scope & non-goals
<!-- What this covers, then explicitly what it does not — stated so it is not mistaken for done. -->

## Artifact lifecycles
<!-- Everything this plan hands to something else: a file, a field, a marker, a report, a prompt, a
     row on a choice surface, a flag. Four answers per row, no blank cells.

     One row per receiver-facing contract, not per file. A flag and the format it emits are two rows
     when two different things consume them, and one row when the same receiver consumes both.

     "What requires it" is the surface that would carry a blank without this artifact — the walk step
     that collects it, the allowlist it must appear in, the parser that expects it. It is not whoever
     asked for the work.

     "Missing or wrong" is the behaviour at the moment the receiver reaches for it, not at build
     time: what the parser does with a malformed value, what the step does when the file is not
     there. Name the refusal, or say plainly that it fails silently.

     Fill the two ends first. The middle two come by habit; plans fail at a binding nothing requires
     and a report no seat must read. If this plan hands nothing to anyone, write exactly one row in
     this shape, reason included:

         | none | this plan edits three existing files and hands nothing to anyone | | | |

     Silence is not a pass. doc-lint enforces it: PLAN1 on a blank cell or on a row naming nothing
     checkable, PLAN2 on a plan that has work items and no table. Every row that is not the `none`
     row carries at least one path or backticked identifier — "the implementing session" in all four
     cells is a row that named nobody. The blank row below stays blank on purpose: it fires PLAN1
     until someone fills it. -->

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
|  |  |  |  |  |

## Work items
<!-- THE PAYLOAD. Dependency-ordered, one row per NAMED FILE. Never collapse several files into a
     phrase like "the resources" or "the composables": the exact path is the thing an implementing
     agent cannot reconstruct, and it is the first thing lost when a plan gets shortened. A file
     that changes gets a row even if the change is one line. The narrative around this table is what
     gets cut; the table does not. -->

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
|    |                   |        |      |            |        |              | TODO   |

## Sequencing & dependencies
<!-- Cross-repo and cross-session order, and anything external this waits on: which repo moves
     first, which id cannot start before another lands, which release is gated. Omit this section
     when the Work-items order already says everything. -->

## Rollback
<!-- How to undo this if it lands badly: the exact revert, the switch to flip, or what makes it
     irreversible. State irreversibility plainly — that is what the approval gate approves. -->

## Test plan
<!-- Harness and level strategy. Per unit: type · scenarios · file location (exact path). -->

## Test design dossier
<!-- Decision tables (variant/state rules), fault hypotheses + metamorphic relations, boundary
     partitions + property invariants. Routing: personas/_shared/testing/design/README.md.
     Every artifact here maps to at least one Test-backlog row below. -->

## Test backlog
<!-- `disposition` is filled during EXECUTE: implement | change | skip + reason. In feature mode a
     row grounded in a requirements.md rule echoes its REQ-NN in `source`. -->

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
|    |        |      |                     |        |          |             |

## Refs
<!-- Repo-relative path plus one line on why it matters here — a bare wikilink is a defect.
     ADRs this obeys · feature dossiers it changes · the process_record file · the session. -->
