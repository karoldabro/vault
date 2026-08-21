---
type: decision
id: ADR-023
project: vault
status: accepted
scope: repo
date: 2026-08-21
tags: [decision, communication, documentation, tooling]
---

# ADR-023 — A shared contract for the files commands write

## Context

[[ADR-018-decision-communication-contract]] governs prose the user reads and explicitly scopes out
"vault document contents". So no rule reached plans, briefs, specs or feature dossiers — the files
that cost the operator most of his reading time. Measured across his vaults: 54 of 60 plans exceed
the cap this ADR sets, one plan runs to 1,529 lines of which 470 are a revision log, and one brief
runs to 2,036 lines repeating a single rule 24 times.

The framework was a cause, not a bystander. `templates/plan.md` mandated `## Critique trail`,
`per-round metrics` and a `### Round 0 — draft` section; `templates/integration-guide.md` mandated a
changelog table. Both put a process record inside a contract document.

A four-reviewer panel found the design's own hole: the ten rules as first written governed **which file
content belongs in** and said nothing about **how a sentence is written**. Four of the operator's
five defect examples obeyed all ten and remained unusable.

## Decision

1. **A second shared module, `commands/_shared/document-standard.md`**, sibling to
   `communication.md`, bound in 14 doc-writing command and step files by the same
   `$VAULT_FRAMEWORK_PATH` line. Capped at 120 lines; currently 95.

2. **Two axes, not one.** Filing rules (one file one question · current truth only · one rule one
   place · no process in a contract document · executable items with exact paths · open work near
   the top · references resolve) **and** register rules (conclusion before evidence · say it rather
   than allude · name the actor and use a verb · every heading and unheaded block states its kind in
   words the reader has). Filing rules alone let four of five defect examples through.

3. **Three document classes.** `contract` carries current truth; `record` (session, research,
   trail) carries chronology as its payload; `message` stays with `communication.md`. Mixing two
   classes in one file is the defect the module exists to prevent.

4. **The process record moves to a sidecar.** `plans/<slug>.trail.md`, linked from the plan's
   `process_record` frontmatter key. Verified before deciding: nothing in the framework reads a
   critique trail back — every reference under `commands/` is a writer, `plans/` is not in the
   default context-load list, and reviewers receive prior findings in context, not from disk.

5. **Mechanical enforcement, because prose alone already failed.** `bin/doc-lint.sh` with per-type
   line caps and a pattern table in `lib/doc-lint-patterns.tsv`, triggered by a non-blocking
   `PostToolUse` hook. Precision is a shipping requirement: instruction files and non-documents are
   out of scope, quoted phrases in backticks are read as quotations, and a repo exempts a check by
   naming it with a reason in `.doc-lint`.

6. **`--compare <before> <after>` gates every shortening.** It lists constraints, prohibitions and
   exact paths present before and absent after. Run against the operator's own hand-shortened plan
   it found 288 dropped named things, including every source path and two hard constraints.

7. **`/v-reconcile` applies the standard to documents that already exist** — load context, extract
   the load-bearing set, split, rewrite, verify with `--compare`, then an approval gate per file.

6b. **The caps rest on review cost, not taste.** Conforming inspection runs at 0.5–1.5 logical pages
   per hour, so a 1,000-line document is 22–66 hours of review nobody spends — it gets skimmed, and a
   buried requirement survives. Practitioner guidance lands in the same place (10–20 pages). Evidence:
   [[document-writing]] §3.

## Consequences

**Accepted costs.** The rules now live in four places (module, output style, global `CLAUDE.md`, and
`communication.md` for the shared half); the global copy sits outside this repo and no test can
reach it, so it will drift. `doc-lint.sh` is ~400 lines of hand-rolled bash — markdownlint checks
syntax and cannot express "no critique trail in a contract document", and vale would add a Go binary
this repo's own rules forbid installing globally.

**Not done.** The 54 existing over-cap plans are left alone; `/v-reconcile` handles them on demand
rather than in a migration.

**Two rules the evidence forced, against how the standard was first written.** Sentence length is doctrine; the one
measured sentence-level effect is **center-embedding**, which damages recall more than jargon or
passive voice, for expert readers too — so the standard names it explicitly. And "one rule, one
place" has a real exception: where omission is catastrophic, aviation checklist practice *mandates*
repeating the item, and plain-language guidance warns that cross-references get skipped. The
standard carries that carve-out rather than pretending the corpus agrees.

**Known limit, stated plainly.** `tests/unit/document-standard.bats` is a file contract plus real
linter behaviour tests. It proves the rules exist and the linter works. It does not prove a written
document is good. Do not read a green suite as evidence the output got shorter.

## Refs

[[ADR-018-decision-communication-contract]] · [[document-writing-standard]] · [[document-writing]] ·
[[decision-communication]] · `commands/_shared/document-standard.md` · `bin/doc-lint.sh`
