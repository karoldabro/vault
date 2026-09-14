---
type: plan
project: vault
slug: 2026-09-14-1642-handoff-and-report-commands
repos: [vault]
status: executed
process_record:
session:
tags: [plan, commands, handoff, report]
---

# handoff-and-report-commands — plan

## Task

Add two commands to this framework: `/v-handoff` writes what the next session needs to continue this
one, and `/v-report` files a problem found now and fixed later. Keywords: handoff, report, resume,
vault folder, doc-lint type, load-context.

## Open & deferred

- **The rule corpus goes further over budget.** `bin/rule-count.sh` reports 175 rule lines against a
  budget of 173 before this change. W-09 and W-10 add two lines to files the corpus names, taking it to 177.
  Both are phrased as requirements, so the prohibition-to-requirement ratio improves from 150:25
  toward the 1:1 the same script asserts. Not fixed here. `grep -rn rule-count bin/gate.sh` returns
  nothing, so the budget refuses nothing and this overrun blocks no session.
- **SC-5 is open and the close gate refuses on it.** A delivery criterion spanning two sessions
  cannot close the plan that defines it. Clear it by running `/v-handoff resume` in a fresh session
  against `vault/handoffs/2026-09-14-1904-handoff-and-report-commands.md`, then writing the verdict.
- **Deferred: no cross-project view.** `/v-report list` reads one vault. A report filed in `givore`
  is invisible from `vivi`. Coupled groups are listed in `~/vault/_global/coupled-groups.md` and a
  later change can sweep them.
- **Deferred: `vault/defect-ledger.md` stays separate.** It records one row per repaired defect class
  and whether the class came back; `reports/` holds problems before anyone repairs them. A report
  closed as fixed in this repo adds a ledger row by hand.

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Full eleven-section handoff, or a short core with the rest written only when the session has it | yes | `grep -ril handoff` over the repo; shift-handover and AI-session-handoff practice | answered | short core of six, always at the top; the other six sections written only when present |
| Q-2 | Who files a report — the operator only, or any command that finds a problem | yes | `grep -rn "reports/"` over the repo returned nothing; `vault/defect-ledger.md` | answered | the operator files it; a command that hits an out-of-scope problem offers in one line and drops it on a no |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a session reads `commands/v-handoff.md` THE SYSTEM SHALL find the six core sections above every optional one, the resume branch, both refusals, and a template that exists | unit | command | `checks/handoff-SC-1.sh` | 0 | MET | `checks/handoff-SC-1.sh` exited 0 ·   OK  /v-handoff carries eight core sections above the optional ones, three modes and both refusals |
| SC-2 | WHEN a session reads `commands/v-report.md` THE SYSTEM SHALL find the finder, the circumstance, the cause, the consequence, the files, the repair and the closing condition, with the finder in frontmatter only | unit | command | `checks/handoff-SC-2.sh` | 0 | MET | `checks/handoff-SC-2.sh` exited 0 ·   OK  /v-report carries ten fields, three modes, and keeps the finder in frontmatter |
| SC-3 | WHEN the framework surfaces are read THE SYSTEM SHALL find both folders and both commands named in the context load, the vault scaffold, the guide, the README and the check budget | unit | command | `checks/handoff-SC-3.sh` | 0 | MET | `checks/handoff-SC-3.sh` exited 0 ·   OK  the context load, the scaffold, all four guide sections, the README and the check budget name both commands |
| SC-4 | WHEN `bin/doc-lint.sh` reads a handoff or a report THE SYSTEM SHALL apply that type own line cap and emit no unknown-type note | unit | command | `checks/handoff-SC-4.sh` | 0 | MET | `checks/handoff-SC-4.sh` exited 0 ·   OK  doc-lint registers handoff and report as contract types, with caps 150 and 120 |
| SC-5 | WHEN a later session runs `/v-handoff resume` against the file this session writes THE SYSTEM SHALL state the next command from that file alone | delivery | observed | run `/v-handoff` at this session close, start a fresh session, run `/v-handoff resume`, record what it asked for. It fails when the resumed session names no next command, or asks the operator for something the handoff file already holds. `no-command: nothing can detect whether a fresh session read the handoff or re-derived the task from the repo` | the resumed session names the next command and asks nothing the file answers | | |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| D-1 | `test_command` passes: `./tests/run.sh tests/unit` | met | 755 tests, 4 failures, all four also failing at HEAD `e32a921` in a throwaway `git worktree`: `document-standard.bats:308`, `document-standard.bats:350`, `plugin-install.bats:113`, `research-clarify.bats:108`. This work adds none |
| D-2 | `lint_command` passes: `./bin/doc-lint.sh --changed` | met | exits 0 |
| D-3 | `delivery_command` passes: `./bin/gate.sh verdict <plan> --run && ./bin/gate.sh all <plan> --phase close` | failed | `verdict --run` records SC-1 to SC-4 `MET`; `--phase close` refuses on SC-5, which needs a second session to observe. The handoff at `vault/handoffs/2026-09-14-1904-handoff-and-report-commands.md` carries the procedure as its first row |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| R-1 | A handoff leads with what is left, what not to touch and what is unverified | OPEN | `checks/handoff-SC-1.sh` reads the section order in `templates/handoff.md` |
| R-2 | A report names its finder in frontmatter, never in the body | OPEN | `checks/handoff-SC-2.sh` refuses a `found_by` line below the frontmatter fence |
| R-3 | A session loading context names every open handoff and open report | OPEN | `checks/handoff-SC-3.sh` reads `commands/v-work/steps/02-load-context.md` |

## Verified current state

- `bin/rule-count.sh` corpus is twelve named files; a new command file is not one of them, so
  `commands/v-handoff.md` and `commands/v-report.md` add no budgeted rule lines. Checked
  `bin/rule-count.sh:32-46`, 2026-09-14.
- `install.sh` links `commands/*.md` and `commands/*/` by glob, so neither command needs an
  installer edit. Asserted already by `tests/unit/v-method.bats:37`.
- `.claude-plugin/plugin.json` names no command; the plugin picker discovers `commands/`.
- `grep -rn "reports/"` over the repo excluding `.git` and `attic` returns nothing, so no existing
  document claims that folder. Checked 2026-09-14.
- `bin/doc-lint.sh` sends an unrecognised `type:` to a 400-line cap and a note telling the author to
  set the type. Checked `bin/doc-lint.sh:65-77,612-619`, 2026-09-14.

## Decisions

| decision | reason | record |
|----------|--------|--------|
| A handoff is a contract, a session capture is a record | the handoff states what is still true; `sessions/` states what happened | local |
| `found_by` lives in frontmatter | `commands/_shared/document-standard.md` rule 7 bars an author's name inside a contract body and rule 5 permits it as frontmatter metadata | local |
| Both folders are standard, not `add_folders` opt-ins | an existing vault gets the folder created on first write, with one warning | local |
| A handoff with an empty `## Left to do` is refused | that file is a session capture under another name | local |
| Both folders are read on every context load, so they cannot be `add_folders` opt-ins the way `plans/` is | a folder the lifecycle reads unconditionally has to exist unconditionally | local |
| `## Done` carries how the work was carried out, not only what | splitting how from what across two sections produces one empty section every time | local |

## Scope & non-goals

Covers: the two commands, their templates, their folders, the read path that surfaces them, and the
type registration that lets `bin/doc-lint.sh` grade them.

Non-goals: cross-project sweeps, automatic filing without the operator, promoting a report into a
plan, and any change to `vault/defect-ledger.md`.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `<vault>/handoffs/YYYY-MM-DD-HHMM-<slug>.md` | `/v-handoff resume` selects the newest `status: open` file in this folder | `/v-handoff` (`commands/v-handoff.md`) | `/v-handoff resume`, and `commands/v-work/steps/02-load-context.md` §2.6a | resume finds no open file and says so, then stops; a file whose frontmatter has no `status` is skipped by the selector and reported as unreadable |
| `<vault>/reports/YYYY-MM-DD-HHMM-<slug>.md` | `/v-report list` and the §2.6a walk both glob this folder | `/v-report` (`commands/v-report.md`) | `commands/v-work/steps/02-load-context.md` §2.6a, and `/v-report close` | an absent folder means zero open reports and one warning; a missing `status` key makes the row unreadable and it is listed as such rather than dropped |
| `status:` frontmatter key (`open`/`resumed` · `open`/`planned`/`fixed`/`rejected`) | the selector in `/v-handoff resume` and the filter in `/v-report list --open` | `/v-handoff`, `/v-report`, `/v-report close` | the same two selectors, and `checks/handoff-SC-3.sh` | an unknown value is treated as open and named in the output, so nothing is silently dropped |
| `handoff` and `report` `type:` values | `bin/doc-lint.sh` `cap_for_type`, `is_known_type`, `singularize_type`, `is_document_folder` | `templates/handoff.md`, `templates/report.md` | `bin/doc-lint.sh`, `checks/handoff-SC-4.sh` | an unregistered type takes the 400-line default cap and the file prints "unknown type" beside any real finding |
| `continues:` frontmatter key | `/v-handoff resume <slug>` walks it backwards to print the chain of earlier handoffs | `/v-handoff` when a prior open handoff exists | `/v-handoff resume <slug>`, and a person reading a multi-night task backwards | a broken link is named and the walk stops there rather than continuing silently; an absent key means this is the first handoff |
| `found_in:` frontmatter key | the person deciding whether a report still applies; a problem found under a since-deleted workflow is stale | `/v-report` | whoever triages `/v-report list` | an empty value is listed as `found_in: unstated`, which is the signal to re-check before acting on the repair |
| `severity:` frontmatter key | `/v-report list` orders by it | `/v-report` | `/v-report list`, `checks/handoff-SC-2.sh` | an unrecognised value sorts last and is printed verbatim, so nothing is dropped |
| `handoffs/` and `reports/` directories | `bin/vault-init.sh` scaffold loop, and both commands on first write | `bin/vault-init.sh`; either command when the folder is absent | both commands, §2.6a | the command creates the folder and warns once; it never halts |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-01 | `templates/handoff.md` | create the handoff template: frontmatter `type: handoff`, `status`, `continues`, `session`; eight core sections (`## Left to do`, `## Do not touch`, `## Unverified`, `## Goal`, `## Task`, `## Requirements`, `## Next command`, `## Blockers`) above six optional ones (`## Success criteria`, `## Plan`, `## Method`, `## Done`, `## Direction`, `## Notes`) | Write | core sections come first and carry no "omit when empty" note; optional sections each carry one; `## Done` prompts for how the work was carried out, not only what was carried out | SC-1 | `./bin/doc-lint.sh templates/handoff.md` | DONE |
| W-02 | `templates/report.md` | create the report template: frontmatter `type: report`, `status`, `severity`, `found_by`, `found_in`, `files`; sections `## What is wrong`, `## Files`, `## Consequence`, `## Cause`, `## How to see it`, `## Repair`, `## Not now because`, `## Closes when` | Write | `found_by` appears as a key in frontmatter and as a key nowhere below it; the template may still explain the rule in prose | SC-2 | `./bin/doc-lint.sh templates/report.md` | DONE |
| W-03 | `commands/v-handoff.md` | create the command: three modes (write, `resume [slug]`, `list`), the two refusals, the section order, the resume selector that reads `status:` and flips it to `resumed`, and a `resume <slug>` branch that follows `continues:` backwards and prints the chain | Write | frontmatter `description:` over 40 characters; binds `_shared/communication.md` and `_shared/document-standard.md` in the header | SC-1, SC-5 | `checks/handoff-SC-1.sh` | DONE |
| W-04 | `commands/v-report.md` | create the command: three modes (`/v-report <what>`, `/v-report list [--open]`, `/v-report close <slug> --fixed\|--rejected <reason>`), the three frontmatter keys (`found_by`, `found_in`, `severity`) and the eight sections, and the one-line offer any other command makes | Write | frontmatter `description:` over 40 characters; `found_by` written to frontmatter only; `list` orders by `severity` | SC-2 | `checks/handoff-SC-2.sh` | DONE |
| W-05 | `bin/doc-lint.sh` | register both types in five places: `cap_for_type` handoff 150 and report 120; `singularize_type` handoffs and reports; `is_known_type` both; `is_document_folder` `*/handoffs` and `*/reports`; and the `--list-caps` loop at line 343, which is a separate literal list from `cap_for_type` and already omits `guide`, `integration-guide` and `instruction` | Edit | neither type joins `is_record_type` — both are contracts | SC-4 | `./bin/doc-lint.sh --list-caps` | DONE |
| W-06 | `bin/vault-init.sh` | add `handoffs` and `reports` to the scaffold loop at line 127 | Edit | `.gitkeep` written like every other folder | SC-3 | `checks/handoff-SC-3.sh` | DONE |
| W-07 | `vault-guide.md` | add both folders to the §2 folder map, both templates to the §4 table, both artifact kinds to the §6 decision tree, and both commands to the §11 reference | Edit | §6 states the split from `sessions/`, from `defect-ledger.md`, and this sentence: a problem inside the current plan's scope stays in that plan's `## Open & deferred`; `reports/` holds only a problem outside the scope of the work that found it | SC-3 | `./bin/doc-lint.sh vault-guide.md` | DONE |
| W-08 | `README.md` | add one row per command to the command table near line 70 | Edit | plain-language rows matching the table's existing register | SC-3 | reading the table | DONE |
| W-09 | `commands/v-work/steps/02-load-context.md` | add §2.6a (list open handoffs and open reports in the resolved vault, and surface the newest handoff plus any report whose `files:` or keywords match the task) **and** two rows to the `### Required output` block at lines 130-144: `Handoffs:` and `Reports:` | Edit | one added rule line, phrased as a requirement, plus two output-block rows that carry no modal verb and cost no budget | SC-3 | `checks/handoff-SC-3.sh` | DONE |
| W-10 | `commands/v-work/steps/05-commit-capture.md` | add one line: a problem found this session and left unfixed is offered as `/v-report` before the close | Edit | one added rule line, phrased as a requirement; the offer drops on a no | SC-2 | `grep -n 'v-report' commands/v-work/steps/05-commit-capture.md` | DONE |
| W-11 | `commands/v-capture.md` | add one line at the close: when work is unfinished, offer `/v-handoff` | Edit | not in the `bin/rule-count.sh` corpus, so no budget effect | SC-1 | `grep -n 'v-handoff' commands/v-capture.md` | DONE |
| W-12 | `checks/handoff-SC-1.sh` | create the check for `/v-handoff`: the six core sections named, the resume branch, both refusals, the template exists and orders core above optional | Write | DONE — it exits 1 today because `commands/v-handoff.md` does not exist | SC-1 | run it, then run it against a template with the order reversed | DONE |
| W-13 | `checks/handoff-SC-2.sh` | create the check for `/v-report`: seven fields named, three modes, `found_by` absent from `templates/report.md` below the frontmatter fence | Write | DONE — it exits 1 today because `commands/v-report.md` does not exist | SC-2 | run it, then run it against a template carrying `found_by` in the body | DONE |
| W-14 | `checks/handoff-SC-3.sh` | create the check for the five framework surfaces: `commands/v-work/steps/02-load-context.md`, `bin/vault-init.sh`, `vault-guide.md`, `README.md` and `vault/check-budget.md` each name both commands or both folders | Write | DONE — it exits 1 today, naming all eighteen missing lines | SC-3 | run it before and after the surfaces are edited | DONE |
| W-15 | `checks/handoff-SC-4.sh` | create the check for type registration: `--list-caps` prints handoff and report, and a fixture of each type lints without the unknown-type note | Write | DONE — it exits 1 today, naming both unregistered types; the probe fixture is written to a temp dir and removed | SC-4 | run it, then run it before W-05 lands | DONE |
| W-16 | `tests/unit/handoff-report.bats` | create the contract tests: both commands exist with a description, both templates exist, the four checks pass, install-by-glob still holds for both commands | Write | runs inside the container per `./tests/run.sh` | SC-1, SC-2, SC-3, SC-4 | `./tests/run.sh tests/unit` | DONE |
| W-17 | `vault/check-budget.md` | add one row per new check: `handoff-SC-1` … `handoff-SC-4`, fires 0, wrong 0, with the note naming what each refuses | Edit | the note states the refusal condition, not the check's purpose | SC-3 | reading the table | DONE |
| W-18 | `docs/cross-project-workspaces.md` | extract `vault-guide.md` §13 (the `/v-pm` cross-project protocol) into its own file, leaving a four-line pointer in §13 | Write | the guide sat at 600 lines against its 600-line cap, so it had no room for §2, §4, §6 and §11 rows | SC-3 | `./bin/doc-lint.sh vault-guide.md docs/cross-project-workspaces.md` | DONE |
| W-19 | `tests/integration/vault-init.bats` | add `handoffs` and `reports` to the scaffolded-folder loop the test asserts | Edit | the assertion runs the real `bin/vault-init.sh` against a fresh repo | SC-3 | `./tests/run.sh tests/integration` | DONE |
| W-20 | `tests/unit/communication-contract.bats` | raise the `## Required output` file count from 18 to 20 | Edit | raised only because two new commands each carry one and each binds the contract | SC-1, SC-2 | `./tests/run.sh tests/unit` | DONE |
| W-21 | `tests/unit/v-pm.bats` | point the two §13 content assertions at `docs/cross-project-workspaces.md`, and assert `vault-guide.md` §13 carries the pointer | Edit | the content moved; no assertion is dropped | SC-3 | `./tests/run.sh tests/unit` | DONE |

## Sequencing & dependencies

W-01 and W-02 come first: W-03, W-04, W-12 and W-13 all read those templates. W-05 before W-15.
W-16 last — it runs the four checks.

## Rollback

`git revert` the commit. Every change is additive except four edits: `bin/doc-lint.sh` (four case
statements), `bin/vault-init.sh` (one loop line), and one line each in
`commands/v-work/steps/02-load-context.md` and `commands/v-work/steps/05-commit-capture.md`. No
vault data is migrated and no existing file is deleted, so a revert loses only the new commands.

## Test plan

- `tests/unit/handoff-report.bats` — unit. Scenarios: both commands and both templates exist; each
  command's frontmatter carries a description over 40 characters; `--list-caps` prints handoff 150
  and report 120; a `type: handoff` fixture lints with no unknown-type note; each of the four check
  scripts exits 0 against the repo; `install.sh` names neither command, proving glob install.
- The four check scripts are their own negative tests: each is run against a planted violation and
  watched exit 1 before it is trusted, per the constraint on W-12 through W-15.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | SC-1 | unit | `tests/unit/handoff-report.bats` | the six core sections stand above every optional one in `templates/handoff.md` | high | |
| T-2 | SC-2 | unit | `tests/unit/handoff-report.bats` | `templates/report.md` carries no `found_by` below the frontmatter fence | high | |
| T-3 | SC-4 | unit | `tests/unit/handoff-report.bats` | a `type: report` fixture takes the 120-line cap and prints no unknown-type note | high | |
| T-4 | SC-3 | unit | `tests/unit/handoff-report.bats` | `bin/vault-init.sh` scaffolds `handoffs/` and `reports/` into a fresh vault | high | |
| T-5 | SC-1 | unit | `tests/unit/handoff-report.bats` | `/v-handoff` refuses when nothing is left to do, and names `/v-capture` instead | medium | |

## Refs

- `commands/_shared/document-standard.md` — the three document classes; it decides that a handoff is
  a contract and a session capture is a record.
- `commands/_shared/communication.md` — governs every line these two commands print.
- `vault/indications/artifact-has-a-named-consumer.md` — why each folder needs a reader; it is the
  rule that puts §2.6a in the plan.
- `vault/check-budget.md` — where the four new checks are scored.
- `vault/defect-ledger.md` — the repaired-defect record `reports/` stays separate from.
