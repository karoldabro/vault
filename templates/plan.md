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

## Verified current state
<!-- Facts the implementer must not re-derive: `fact · how it was checked · date`. Only facts that
     change an implementation choice. An assumption that was NOT verified goes in Open & deferred. -->

## Decisions
<!-- What is settled, so nobody re-opens it mid-implementation. One line each:
     `decision — the one-line reason it went this way`. The reason must be shorter than the decision.
     No alternatives, no who-argued-what: those live in the process_record file. -->

## Scope & non-goals
<!-- What this covers, then explicitly what it does not — stated so it is not mistaken for done. -->

## Artifact lifecycles
<!-- Every thing this plan creates that something else then has to use: a file, a field, a marker, a
     report, a prompt, a row on a choice surface. Four answers per row, no blank cells. The middle
     two come easily; the two ends are where plans fail — a binding nothing asks for, a report no
     seat must read, a marker with no parser. If this plan creates nothing anyone else consumes,
     write exactly one row in this shape, reason included:

         | none | this plan edits three existing files and creates nothing anyone else consumes | | | |

     Silence is not a pass, and doc-lint enforces it: PLAN1 on a blank cell or on a row naming
     nothing checkable, PLAN2 on a file-creating plan with no table. Every row that is not the
     `none` row must carry at least one path or backticked identifier — "the implementing session"
     in all four cells is a row that named nobody. The blank row below stays blank on purpose: it
     fires PLAN1 until someone fills it. -->

| artifact | who asks for it | who writes it | who reads it | absent or malformed |
|---|---|---|---|---|
|  |  |  |  |  |

## Work items
<!-- THE PAYLOAD. Dependency-ordered, one row per NAMED FILE. Never collapse several files into a
     phrase like "the resources" or "the composables": the exact path is the thing an implementing
     agent cannot reconstruct, and it is the first thing lost when a plan gets shortened. A file
     that changes gets a row even if the change is one line. The narrative around this table is what
     gets cut; the table does not. -->

| id | file (exact path) | action | tool | constraint | verification | status |
|----|-------------------|--------|------|------------|--------------|--------|
|    |                   |        |      |            |              | TODO   |

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
