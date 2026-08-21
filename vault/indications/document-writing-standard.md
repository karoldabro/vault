---
type: indication
project: vault
slug: document-writing-standard
scope: repo
tags: [indication]
---

# document-writing-standard

## Rule

Every file a command writes is governed by `commands/_shared/document-standard.md`, bound at the top
of each doc-writing command and step file by `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md`.
Never duplicate the rules into a command; bind the module. Its sibling `communication.md` keeps the
terminal and owns every rule the two share.

Four rules bind the *authoring* of any new command, step or template:

1. **Pick a class, and write only that class.** `contract` carries current truth; `record` carries
   chronology. A template that mandates a history section inside a contract document is the defect —
   `templates/plan.md` was the framework's own instance of it.
2. **Filing rules alone are not enough.** How a sentence is built decides whether the document can be
   used. Four of the five defect examples that motivated this obeyed every filing rule.
3. **Shortening deletes narrative, never constraints.** A plan is read by an implementing agent as
   well as a person, and the exact file path is the first thing a summarising pass drops. Prove it
   with `bin/doc-lint.sh --compare <before> <after>`.
4. **A rule with no trigger is not enforced.** `communication.md` shipped for months against
   unchanged output because nothing ran. Every check here has a `PostToolUse` hook behind it, and a
   check the linter cannot make stays human judgement rather than becoming an unread instruction.

**Precision before coverage.** A linter that fires on legitimate work gets switched off and then
enforces nothing. Instruction files and non-documents are out of scope, a backticked phrase is read
as a quotation, and a repo exempts a check by naming it with its reason in `.doc-lint`.

**Out of scope, deliberately:** source code, commit messages, machine-read schemas, your reasoning,
and record-class documents' history. An ADR keeps its rejected options — those are its current truth.

## Rationale

The framework's own templates mandated the bloat: a critique trail, `per-round metrics` and a draft
section inside the contract document, plus a changelog table in the integration guide. Nothing
governed documents, so [[ADR-018-decision-communication-contract]]'s gains stopped at the terminal.

## Applies to

`commands/_shared/document-standard.md` · `bin/doc-lint.sh` · `lib/doc-lint-patterns.tsv` ·
`templates/plan.md` · `templates/trail.md` · `templates/integration-guide.md` ·
`commands/v-reconcile.md` · the 14 bound command and step files · `output-styles/director.md`

## Guard

`tests/unit/document-standard.bats` — the contract half proves the rules exist and are bound; the
linter half is real behaviour testing, including the false-positive cases. **A green suite is not
evidence that a written document is good.**

## Refs

[[ADR-023-document-writing-standard]] · [[user-facing-communication]] ·
[[ADR-018-decision-communication-contract]] · [[decision-communication]]
