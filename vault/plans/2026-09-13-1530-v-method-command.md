---
type: plan
project: vault
slug: v-method-command
repos: [vault]
status: executed
process_record:
session: 2026-09-13-1530-v-method-command
tags: [plan, command, methodology, orchestration]
---

# v-method-command — plan

## Task

Ship `/v-method`: a command that reads one heavy task and writes how to work on it — the stages, the
seats, the tools, the exit evidence and the kill criterion for each. Keywords: methodology, routing,
stage, gate, appetite, orchestration.

## Open & deferred

| item | state |
|------|-------|
| No study shows that writing a methodology up front improves the outcome. Only the parts it prescribes carry evidence individually. The command composes measured parts and claims nothing for the composition | open — stated, not resolvable |
| No validated instrument turns a task description into a process. The routing table is a heuristic, and every routing decision is recorded in the method file so later sessions can score it against what happened | open — recorded for audit |
| A fixed budget and guaranteed criteria cannot both be promised. The command asks which is fixed and records what it gave up | open — an operator decision every run |
| `commands/v-reconcile.md` carries no frontmatter, so `tests/unit/plugin-install.bats` "every top-level command has a description" fails on the committed baseline. Adding `/v-method` does not worsen it; the fix is one block and is not in this plan | open — pre-existing |
| SC-6 needs the operator. `bin/gate.sh verdict` accepts only `MET` and `NOT MET`, so this plan cannot close until someone runs `/v-method fix the slow thing` and confirms the refusal. `vault/plans/2026-09-06-1053-v-loop-autonomous-campaign.md` carries the same open row with a verdict of `OPEN`, which that gate also refuses | open, blocks the close |

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Single command file or a dispatcher with a steps directory | no | `commands/v-loop.md` (single + rules file); `commands/v-team.md`, `commands/v-pm.md`, `commands/v-cr.md` (dispatcher + steps) | answered | single file plus one reference file — the command runs one interactive pass and writes one artifact, so a six-file read set buys nothing |
| Q-2 | Where the method file is written | no | `commands/v-pm.md` §Notes; `vault-guide.md` §13; `VAULT.md` `add_folders` | answered | `_features/<feature>/method.md` in feature mode, else `<project-vault>/plans/YYYY-MM-DD-HHMM-<slug>.method.md` |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a session reads `commands/v-method.md` THE SYSTEM SHALL find three refusals, the fixed-budget question, both reference paths, and the four fields every stage carries | unit | command | `checks/v-method-SC-1.sh` | exit 0 | MET | `checks/v-method-SC-1.sh` exited 0 ·   OK  v-method.md carries three refusals, the budget question, both references and the per-stage fields |
| SC-2 | WHEN `bin/doc-lint.sh` runs over every file this plan writes THE SYSTEM SHALL report no finding | unit | command | `checks/v-method-SC-2.sh` | exit 0 | MET | `checks/v-method-SC-2.sh` exited 0 ·   OK  8 files pass doc-lint |
| SC-3 | WHEN the routing table is read THE SYSTEM SHALL find at least eight rows of four filled cells, no property phrased as a judgement, and the heuristic recorded as a heuristic | unit | command | `checks/v-method-SC-3.sh` | exit 0 | MET | `checks/v-method-SC-3.sh` exited 0 ·   OK  14 routing rows, four columns each, no blanks, no judgement-shaped property |
| SC-4 | WHEN the two `/v-method` files are counted THE SYSTEM SHALL find requirement-shaped rules outnumbering prohibition-shaped ones in each | unit | command | `checks/v-method-SC-4.sh` | exit 0 | MET | `checks/v-method-SC-4.sh` exited 0 ·   OK  commands/v-method/routing.md: 0 prohibitions, 5 requirements |
| SC-5 | WHEN both `/v-method` files are compared against the shared modules' owned rules THE SYSTEM SHALL find no restatement | unit | command | `checks/v-method-SC-5.sh` | exit 0 | MET | `checks/v-method-SC-5.sh` exited 0 ·   OK  both v-method files restate no shared-module rule |
| SC-6 | WHEN `/v-method` is invoked on a task with no written problem statement THE SYSTEM SHALL refuse and name what is missing | delivery | observed | invoke `/v-method fix the slow thing` in this repo; it fails when the session runs intake or writes a method file instead of refusing. `no-command: whether a problem statement names who the output is for is a judgement about prose, and every proxy tried accepts a one-line restatement of the task title` | a refusal naming the missing problem statement, and no method file written | OPEN | needs the operator: run `/v-method fix the slow thing` in this repo and confirm it refuses without writing a method file |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | The change does what the task asked | met | `/v-method` ships with its routing reference, its output template, five checks and 15 tests; it writes a method and runs no stage |
| B2 | Tests covering the changed behaviour pass | met | `./tests/run.sh tests/unit/v-method.bats` — 15 cases, no failures, each routing and duplication check planted with the violation it catches |
| B3 | Lint and any format check pass on the changed files | met | `checks/v-method-SC-2.sh` exited 0 over 8 documents; `bash -n` clean on all five checks |
| B4 | Every review finding is fixed or recorded | met | no panel ran on this plan; the two defects found in build — a prohibition-heavy pair of files and a planted violation too weak to trip SC-4 — are both fixed |
| B5 | Documentation and vault docs that the change invalidates are updated | met | `README.md` command table, `vault-guide.md` table plus §11.2, `vault/_moc.md`, `vault/_feature-index.md`, `vault/check-budget.md` and `vault/decisions/_inventory.md` |
| B6 | Nothing unrelated is in the commit | failed | Two inclusions beyond the plan. `checks/v-loop-SC-3.sh` plus `lib/shared-module-rules.tsv` refactor an existing check, because copying 35 pattern rows into the new check is the duplication those checks exist to prevent; that check still exits 0. And `backticked` in `bin/gate.sh` returned 1 on a cell with no backtick, which under `set -e` killed the run with nothing printed — found by this plan's own `readers` gate, and left unfixed it silently stops any session whose plan carries such a row |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| R-1 | Every routing row carries a checkable property, a method, an artifact and a stopping rule | ENFORCED | `checks/v-method-SC-3.sh` refuses a blank cell, a shifted row and a judgement-shaped property |
| R-2 | Neither `/v-method` file restates a rule a shared module owns | ENFORCED | `checks/v-method-SC-5.sh` over `lib/shared-module-rules.tsv` |
| R-3 | Both `/v-method` files are written in requirement form | ENFORCED | `checks/v-method-SC-4.sh` |
| R-4 | Every stage in a method file names its kill criterion and the exact field its verdict is read from | PROSE | `commands/v-method.md` requires it; no check reads a method file, because none exists yet to read |
| R-5 | `/v-method` refuses a task with no written problem statement | PROSE | the command requires it; SC-6 is operator-observed, and the reason no detector exists is in the criterion row |

## Verified current state

- `install.sh` links `commands/*.md` and every immediate subdirectory by glob, so a new command needs no installer edit · `link_tree` in `install.sh` · 2026-09-13.
- `bin/rule-count.sh` reads an explicit twelve-file corpus, so `/v-method` is outside the `/v-team` budget and needs its own count check · `CORPUS` in `bin/rule-count.sh` · 2026-09-13.
- `/v-loop` is the precedent for a single-file command with one reference file, and for an operator-observed delivery criterion · `vault/plans/2026-09-06-1053-v-loop-autonomous-campaign.md` · 2026-09-13.
- `commands/v-reconcile.md` is the one top-level command with no frontmatter description · `tests/unit/plugin-install.bats:100` fails on the committed baseline · 2026-09-13.

## Decisions

| decision | reason | record |
|----------|--------|--------|
| D-1 | One command file plus one reference file, not a dispatcher and a steps directory | the command runs one pass and writes one artifact; a six-file read set costs attention and buys no structure | `vault/decisions/ADR-029-methodology-command.md` |
| D-2 | The routing table keys on checkable task properties, never on a complexity classification | no classifier has been validated, and the one 2x2 most often proposed was repudiated by its own author for this use | `vault/decisions/ADR-029-methodology-command.md` |
| D-3 | The command asks which of budget and criteria is fixed, and records what it sacrificed | the two cannot both be promised, and a command that implies otherwise produces a plan that silently breaks one | `vault/decisions/ADR-029-methodology-command.md` |
| D-4 | The owned-rule pattern list moves to `lib/shared-module-rules.tsv`, read by both duplication checks | copying 35 rows into a second check is the duplication those checks exist to prevent | local |
| D-5 | A stage's kill criterion names the exact file and field its verdict is read from | a production gate flagged none of a hundred cases it should have caught because its condition read a field that was always empty | `vault/decisions/ADR-029-methodology-command.md` |
| D-6 | `/v-method` writes a method and runs no stage | the stages are existing commands with their own gates; a command that both chose the method and executed it would grade its own choice | `vault/decisions/ADR-029-methodology-command.md` |

## Scope & non-goals

Covers the command, its routing reference, the method template, five checks, contract tests, the
decision record, the feature dossier and the doc wiring in `README.md` and `vault-guide.md`.

Excluded: executing a stage; a check that reads a written method file, since none exists yet; the
claim ledger; the `commands/v-reconcile.md` frontmatter fix; extending `bin/rule-count.sh`'s corpus.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `commands/v-method.md` | `install.sh` `link_tree`, which globs `commands/*.md` into the user's command directory | this plan | the operator invoking `/v-method`, and `checks/v-method-SC-{1,4,5}.sh` | the command does not appear in the picker and `checks/v-method-SC-1.sh` exits 1 |
| `commands/v-method/routing.md` | `commands/v-method.md`, which reads it to route the task | this plan | the session running the command, and `checks/v-method-SC-3.sh` | the session routes from memory; `checks/v-method-SC-3.sh` exits 1 naming the missing table |
| `templates/method.md` | `commands/v-method.md`, which instantiates it as the output | this plan | the session writing the method file, and the operator reading it | the session invents a shape per run and no two method files compare; `checks/v-method-SC-1.sh` exits 1 |
| `plans/*.method.md` | the operator, and the `/v-team` or `/v-work` session that runs a stage from it | the `/v-method` session, from `templates/method.md` | the operator, and each stage's own session | the run produces advice in the terminal and nothing survives it |
| `lib/shared-module-rules.tsv` | `checks/v-loop-SC-3.sh` and `checks/v-method-SC-5.sh`, which read its patterns | this plan, moving the list out of the v-loop check | both checks | both exit 1 naming the missing file, so neither duplication check runs |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `lib/shared-module-rules.tsv` | create | Write | the 35 owned-rule patterns, with the literal-wording limit in its own header | SC-5 | `checks/v-loop-SC-3.sh` still exits 0 | DONE |
| W-2 | `checks/v-loop-SC-3.sh` | modify | Write | read the shared file; no heredoc left behind | SC-5 | its own exit code, unchanged at 0 | DONE |
| W-3 | `checks/v-method-SC-1.sh` | create | Write | grep each thing the command cannot run without | SC-1 | its own exit code | DONE |
| W-4 | `checks/v-method-SC-2.sh` | create | Write | doc-lint over every file this plan writes | SC-2 | its own exit code | DONE |
| W-5 | `checks/v-method-SC-3.sh` | create | Write | row count, width, blanks, judgement words, the heuristic admission | SC-3 | its own exit code | DONE |
| W-6 | `checks/v-method-SC-4.sh` | create | Write | the same two grammar patterns `bin/rule-count.sh` uses | SC-4 | its own exit code | DONE |
| W-7 | `checks/v-method-SC-5.sh` | create | Write | both files against the shared pattern list | SC-5 | its own exit code | DONE |
| W-8 | `commands/v-method.md` | create | Write | three refusals; the fixed-budget question; read `routing.md`; instantiate `templates/method.md`; per stage a command, seats, tools, exit evidence and a kill criterion naming its file and field; defer to `agent-conduct.md`; requirement form | SC-1 SC-4 SC-5 SC-6 | `checks/v-method-SC-1.sh`, and SC-6 observed by the operator | DONE |
| W-9 | `commands/v-method/routing.md` | create | Write | the property-to-method table with four filled columns and at least eight rows; the seats-per-stage table; the verification-tool table; the claim-audit table; the heuristic stated as a heuristic | SC-3 SC-4 SC-5 | `checks/v-method-SC-3.sh` | DONE |
| W-10 | `templates/method.md` | create | Write | the stage table carrying all five per-stage fields, plus what the run gave up and the routing answers it recorded | SC-1 SC-2 | `bin/doc-lint.sh` | DONE |
| W-11 | `tests/unit/v-method.bats` | create | Write | the command is installed by glob, the routing table parses, a planted blank cell and a planted judgement property each turn SC-3 red | SC-3 | `tests/run.sh tests/unit/v-method.bats` | DONE |
| W-12 | `vault/decisions/ADR-029-methodology-command.md` | create | Write | records D-1, D-2, D-3, D-5, D-6 and the rejected routers | SC-2 | `bin/doc-lint.sh` | DONE |
| W-13 | `vault/decisions/_inventory.md` | modify | Edit | register ADR-029 in the same commit as W-12 | SC-2 | `tests/unit/v-team.bats` | DONE |
| W-14 | `vault/features/v-method.md` | create | Write | scope, contracts, coupling with `/v-pm` and the ladder, gotchas, sessions | SC-2 | `bin/doc-lint.sh` | DONE |
| W-15 | `vault/_feature-index.md` | modify | Edit | one row for the feature | SC-2 | `bin/doc-lint.sh` | DONE |
| W-16 | `vault/check-budget.md` | modify | Edit | one row per new check, at 0 and 0, plus the literal-wording limit of SC-5 under what the checks do not cover | SC-2 | `bin/gate.sh budget` | DONE |
| W-17 | `README.md` | modify | Edit | one row in the command table | SC-2 | `bin/doc-lint.sh` | DONE |
| W-18 | `vault-guide.md` | modify | Edit | one row in the command table and one section on the method file and its stage gates | SC-2 | `bin/doc-lint.sh` | DONE |
| W-19 | `vault/_moc.md` | modify | Edit | the feature link | SC-2 | `bin/doc-lint.sh` | DONE |
| W-20 | `bin/gate.sh` | modify | Edit | `backticked` returns 0 when a cell carries no backtick; under `set -e` its failure killed the whole run at the caller's assignment, with nothing printed | SC-2 | `tests/unit/gate.bats` "readers never exits nonzero without naming what it refused" | DONE |
| W-21 | `tests/unit/gate.bats` | modify | Edit | one case proving `readers` exits 0 on a lifecycle row with no backticked identifier | SC-2 | `tests/run.sh tests/unit/gate.bats` | DONE |
| W-22 | `tests/unit/v-loop.bats` | modify | Edit | both duplication cases follow the pattern list to `lib/shared-module-rules.tsv`; the scratch tree copies it | SC-5 | `tests/run.sh tests/unit/v-loop.bats` | DONE |
| W-23 | `tests/unit/communication-contract.bats` | modify | Edit | the pinned Required-output file count rises from 17 to 18 for the new command, with the reason | SC-1 | `tests/run.sh tests/unit/communication-contract.bats` | DONE |

## Sequencing & dependencies

W-1 lands before W-2, or `checks/v-loop-SC-3.sh` exits 1 on a missing file. W-9 lands before W-8,
because the command references the table it routes from. W-12 and W-13 ship in the same commit, or
`tests/unit/v-team.bats` refuses an unregistered decision record.

## Rollback

Revert the commit. `/v-method` is additive: nothing else reads it, no existing command dispatches to
it, and `install.sh` picks it up by glob so its removal needs no installer change. The one edit to
existing behaviour is W-2, which moves `checks/v-loop-SC-3.sh`'s pattern list into a file and is
proven behaviour-preserving by that check's own exit code.

## Test plan

`tests/unit/v-method.bats`, run through `tests/run.sh` inside Docker.

| unit | scenarios |
|------|-----------|
| installation | `install.sh` links `commands/v-method.md` and the `commands/v-method/` directory without an installer edit |
| routing table | the table parses to four columns; a planted blank cell turns `checks/v-method-SC-3.sh` red; a planted judgement-shaped property turns it red; a row count under eight turns it red |
| duplication | a planted restatement of an `agent-conduct.md` rule turns `checks/v-method-SC-5.sh` red |
| grammar | a planted prohibition-heavy block turns `checks/v-method-SC-4.sh` red |
| template | `templates/method.md` carries all five per-stage fields, asserted with `run grep` and a status check |

## Refs

- `vault/plans/2026-09-13-1355-v-method.brief.md` — the design this plan builds, including the routing rows, the seat table and the tool tables with their sources.
- `vault/decisions/ADR-026-mechanical-session-gates.md` — why each stage's verdict is read from a named field by a committed script rather than judged.
- `vault/indications/unreadable-is-not-no.md` — the exit-code rule every check here follows.
- `vault/indications/light-command-siblings.md` — the ladder a task is sent down when a campaign is not warranted.
- `commands/v-loop.md` — the single-file command precedent, and the operator-observed delivery criterion.
