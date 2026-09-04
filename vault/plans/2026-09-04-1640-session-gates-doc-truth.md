---
type: plan
project: vault
slug: session-gates-doc-truth
repos: [vault]
status: executed
process_record:
session:
tags: [plan, gates, enforcement]
---

# session-gates-doc-truth — plan

## Task

Make `vault/architecture/session-gates.md` and `vault/check-budget.md` describe only the checks
`bin/gate.sh` actually runs, and add three checks that keep them honest.

Keywords: `gate subcommand`, `artifact criterion`, `check budget`, `document drift`.

## Open & deferred

- Deferred: building the seven checks the document currently claims (`clarify`, `coverage`, `dod`,
  `bindings`, `decisions`, `states`, `tracker`). They move to
  `vault/architecture/session-gates-unbuilt.md`, each with an owner and a command that closes it.
- Deferred: implementing artifact-row verification in `bin/gate.sh`. SC-2 fails the moment it is
  built, which is what makes the document claim come back with it.
- Dropped: the second-instance rule and the failing-test prohibition. The first already exists in
  narrower form at `commands/_shared/elicitation.md:77`; the second has two candidate homes
  (`commands/_shared/definition-of-done.md` and the testing personas, where
  `vault/research/llm-collaboration-patterns.md:177` already assigns it). Neither is decided here.
- Not a defect: `/v-team` does reach `commands/_shared/definition-of-done.md`. `commands/v-team.md:118`
  reads `commands/v-work/steps/05-commit-capture.md`, which reads it at line 30.

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Do the seven unbuilt checks belong in `session-gates.md` or their own file? | no | `wc -l vault/architecture/session-gates.md` (198); `bin/doc-lint.sh:70` caps `architecture` at 200; `commands/_shared/document-standard.md` §"split rather than lengthen" | answered | Their own file. The document has two lines of headroom, and a list of unbuilt work is a second job. |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a subcommand is named in `session-gates.md` THE SYSTEM SHALL answer to it on the real dispatcher, and every subcommand the dispatcher answers to SHALL be named | delivery | command | `checks/doc-truth-SC-1.sh` | exit 0 | MET | `checks/doc-truth-SC-1.sh` exited 0 |
| SC-2 | WHEN `bin/gate.sh verdict --run` reads an `artifact` criterion THE SYSTEM SHALL behave as `session-gates.md` says it behaves | delivery | command | `checks/doc-truth-SC-2.sh` | exit 0 | MET | `checks/doc-truth-SC-2.sh` exited 0 |
| SC-3 | WHEN `bin/gate.sh` implements a check THE SYSTEM SHALL carry a row for it in `vault/check-budget.md` | unit | command | `checks/doc-truth-SC-3.sh` | exit 0 | MET | `checks/doc-truth-SC-3.sh` exited 0 |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | The change does what the task asked | met | both documents now name only what `bin/gate.sh` answers to; the second-instance rule was cut and is recorded in `## Open & deferred` |
| B2 | Tests covering the changed behaviour pass | met | `bin/gate.sh verdict --run` recorded SC-1, SC-2 and SC-3 MET; `./tests/run.sh tests/unit` still fails exactly its four pre-existing tests (194, 200, 340, 386) |
| B3 | Lint and any format check pass on the changed files | met | `bin/doc-lint.sh` exit 0 on all five changed documents |
| B4 | Every review finding is fixed or recorded | met | the panel's confirmed findings either changed this plan or are recorded in `## Open & deferred`; the `/v-team` finding was checked and refuted at `commands/v-team.md:118` |
| B5 | Documentation and vault docs that the change invalidates are updated | met | `session-gates.md`, `session-gates-unbuilt.md`, `check-budget.md`, `defect-ledger.md` |
| B6 | Nothing unrelated is in the commit | met | `git diff --stat` matches the work-item list |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | `session-gates.md` names only subcommands the dispatcher answers to | HALF-BUILT | `checks/doc-truth-SC-1.sh` runs at this plan's close; no recurring runner exists for `checks/` |
| E-2 | The document's account of an `artifact` row matches the gate's behaviour | HALF-BUILT | `checks/doc-truth-SC-2.sh`, same limit as E-1 |
| E-3 | Every implemented check is counted in the check budget | HALF-BUILT | `checks/doc-truth-SC-3.sh`, same limit as E-1 |

Nothing runs `checks/` on a schedule — `grep -rn "checks/" --include=*.sh --include=*.json` finds no
runner, and `bin/gate.sh:558` executes a check only for the plan handed to `verdict --run`. Calling
any row here `ENFORCED` would repeat the defect this plan repairs.

## Verified current state

- `bin/gate.sh` answers to six subcommands plus `all`: `criteria`, `verdict`, `readers`, `config`,
  `budget`, `recurrence`. Enumerated from the case arms at `bin/gate.sh:613-635` and each one
  invoked, 2026-09-04.
- Before this change `session-gates.md` §"The subcommands" named ten, seven of which the dispatcher
  rejected with `unknown subcommand`. `./checks/doc-truth-SC-1.sh`, exit 1, 2026-09-04.
- Before this change `session-gates.md:19` stated `bin/gate.sh` does not exist. The file is 646 lines and committed at
  `dd605f8`. Checked 2026-09-04.
- Before this change `session-gates.md` said an `artifact` row is one "the gate checks". `cmd_verdict` executes only
  `how = command` (`bin/gate.sh:600`); an artifact row keeps whatever verdict the session typed.
  `./checks/doc-truth-SC-2.sh` closes a criterion `MET` against a file lacking the pattern, exit 1,
  2026-09-04.
- Before this change `vault/check-budget.md` `## Check budget` omitted `budget` and `recurrence`.
  `./checks/doc-truth-SC-3.sh`, exit 1, 2026-09-04.
- Before this change `vault/architecture/session-gates.md` was 198 lines against a 200-line cap for `architecture`
  (`bin/doc-lint.sh:70`). `wc -l`, 2026-09-04.
- `bin/gate.sh --help` prints the comment block at lines 2-30 via `usage()` (`bin/gate.sh:53`), which
  the dispatcher never reads. A check built on it cannot see a deleted case arm.
- Four unit tests fail before this change: `document-standard.bats` 194 and 200, plus 340 and 386.
  `./tests/run.sh tests/unit | grep -c '^not ok'` returns 4, 2026-09-04.

## Decisions

| decision | reason | record |
|----------|--------|--------|
| SC-1 enumerates the case arms and then invokes each name | `--help` is a hand-written comment the dispatcher never consults, so a check reading it cannot fail | local |
| The unbuilt checks move to their own file | `session-gates.md` has two lines of headroom, and a backlog is a second job | local |
| Every enforcement state is `HALF-BUILT`, not `ENFORCED` | no runner executes `checks/` outside this plan's own close | local |
| The second-instance rule is dropped from this plan | `commands/_shared/elicitation.md:77` already carries it for one actor; what it adds needs its own decision | local |

## Scope & non-goals

Covers: the two documents that describe the gate, one new file for the unbuilt checks, three check
scripts, and one defect-ledger row.

Does not cover: changing `bin/gate.sh` behaviour, building any of the seven deferred checks,
building a recurring runner for `checks/`, or the two rules dropped above.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `vault/architecture/session-gates-unbuilt.md` | the one-line pointer replacing the seven rows deleted from `vault/architecture/session-gates.md` §"The subcommands" | this plan, W-2 | a session or operator asking which gate checks are still missing | the pointer names a file that is not there, and the seven deferred checks become invisible instead of merely unbuilt |
| `checks/doc-truth-SC-1.sh` | the `check` cell of SC-1, which `bin/gate.sh criteria` refuses unless it is an existing executable | this plan, already on disk | `bin/gate.sh verdict --run` at this plan's close | `criteria` refuses SC-1 and the session cannot close |
| the `## The subcommands` table in `vault/architecture/session-gates.md` | `checks/doc-truth-SC-1.sh`, which parses its first column | this plan, W-1 | a session choosing which gate check to run at a phase | a session runs `bin/gate.sh dod` and gets `unknown subcommand`, then proceeds ungated believing the check ran |
| the `## Check budget` rows for `budget` and `recurrence` | `checks/doc-truth-SC-3.sh`, and `bin/gate.sh budget` which reads the table it is counted in | this plan, W-3 | the operator scoring a check that fired wrongly | a check's wrong-fire rate is never counted, and an unmeasured check is the one that gets the whole gate switched off |
| the `D-008` row in `vault/defect-ledger.md` | `bin/gate.sh recurrence`, which refuses a row whose `test` cell names no path | this plan, W-4 | the next session that finds this defect class again | `recurrence` refuses the close; a repeat of the class is recorded as new rather than as a recurrence |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `vault/architecture/session-gates.md` | modify | Edit | delete the seven rows for checks the dispatcher rejects; add rows for `readers`, `budget`, `recurrence`; delete the `## Open` row claiming `bin/gate.sh` does not exist; change the `artifact` row so it says the operator decides it and the gate does not open the file; add one line pointing at the unbuilt file; stay at or under 200 lines | SC-1, SC-2 | `./checks/doc-truth-SC-1.sh`, `./checks/doc-truth-SC-2.sh`, `wc -l` | DONE |
| W-2 | `vault/architecture/session-gates-unbuilt.md` | create | Write | `type: architecture`; one row per deferred check with what it would refuse, an owner, and a command whose exit code closes it; no prose restating what `session-gates.md` already says | SC-1 | `bin/doc-lint.sh` on the file | DONE |
| W-3 | `vault/check-budget.md` | modify | Edit | add `budget` and `recurrence` rows to `## Check budget`, both at `0 \| 0` | SC-3 | `./checks/doc-truth-SC-3.sh` | DONE |
| W-4 | `vault/defect-ledger.md` | modify | Edit | one row: a contract document named a check that did not exist, so a session believed its work was gated; repair names the three check scripts; `test` names `checks/doc-truth-SC-1.sh` | | `./bin/gate.sh recurrence` | DONE |
| W-5 | `checks/doc-truth-SC-1.sh` | create | Write | enumerate case arms, then invoke each name and fail on `unknown subcommand`; tolerate escaped pipes and bold in the table; never read `--help` | SC-1 | delete a case arm in a scratch copy and confirm exit 1 | DONE |
| W-6 | `checks/doc-truth-SC-2.sh` | create | Write | build a scratch plan with an `artifact` row over a file lacking the pattern, run the real gate, compare its behaviour to the document's claim in both directions | SC-2 | run it | DONE |
| W-7 | `checks/doc-truth-SC-3.sh` | create | Write | every implemented subcommand has a `## Check budget` row; non-subcommand rows ignored | SC-3 | run it | DONE |

## Sequencing & dependencies

W-1 before W-2 (the pointer must name the file that exists). W-1 and W-3 before the close, because
SC-1, SC-2 and SC-3 all read what W-1 and W-3 write.

## Rollback

`git revert` the single commit. Three new files are deleted and three documents return to their
previous text. No runtime behaviour changes, so nothing else has to be undone.

## Test plan

The three check scripts are the tests, and each was proven by breaking what it reads:

- SC-1: deleting `budget)` from a scratch `bin/gate.sh` produced `documented, but the dispatcher
  rejects it: budget`. This is the case the previous `--help`-based check missed entirely.
- SC-2: the real gate closed an `artifact` criterion `MET` against an empty file, exit 0, which is
  the condition the check refuses while the document claims otherwise.
- SC-3: `budget` and `recurrence` are absent from the budget table today, and the check names both.

`./tests/run.sh tests/unit` guards the existing suite. Its four pre-existing failures are named in
`## Verified current state` and are not inherited silently.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | SC-1 | integration | `checks/doc-truth-SC-1.sh` | a case arm deleted from `bin/gate.sh` fails the check | high | implement |
| T-2 | SC-2 | integration | `checks/doc-truth-SC-2.sh` | artifact verification being built fails the check until the document claim returns | medium | implement |
| T-3 | SC-1 | unit | `checks/doc-truth-SC-1.sh` | a table row written with an escaped pipe or bold still parses | medium | implement |

## Refs

- `vault/architecture/session-gates.md` — the contract this plan repairs.
- `vault/indications/enforced-not-just-stated.md` — the rule the current document breaks: a stated
  check must name the code that runs it.
- `vault/check-budget.md` — where an unmeasured check becomes a measured one.
- `vault/defect-ledger.md` — carries D-008, the class this plan repairs.
