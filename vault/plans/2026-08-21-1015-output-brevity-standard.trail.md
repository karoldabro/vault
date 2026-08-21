---
type: trail
project: vault
plan: 2026-08-21-1015-output-brevity-standard
tags: [trail, record]
---

# output-brevity-standard — process record

Contract document: `vault/plans/2026-08-21-1015-output-brevity-standard.md`.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Process record moves to `plans/<slug>.trail.md` | delete it entirely | after the session ends nobody could check why a reviewer's blocker was overruled |
| Process record moves to a sidecar | keep it at the bottom of the plan | the file still passes 1,000 lines and the operator still scrolls past it |
| Rules plus a checker script | prose rules only | `communication.md` shipped months earlier and plans still reached 1,529 lines |
| Non-blocking `PostToolUse` hook | step-file instructions only | the skippable-instruction mechanism is the one that already failed |
| Non-blocking hook | hook that refuses the write | would block legitimate long documents and need frequent overrides |
| Six rules inline in global `CLAUDE.md` + pointer | pointer only | `CLAUDE.md` is the always-loaded channel; a pointer needs Claude to choose to read it |
| Six rules inline | full copy of all ten | a fourth untestable copy of rules that already live in three files |
| Hand-rolled `doc-lint.sh` | markdownlint | checks markdown syntax; cannot express "no critique trail in a contract document" |
| Hand-rolled `doc-lint.sh` | vale | a Go binary installed globally, which this user's own rules forbid |
| `guide` cap raised to 600 | keep 250 and split `vault-guide.md` | a reference manual indexes many questions by design; the cap catches accidental doubling |

## Findings & dispositions

### Round 1 — four reviewers, design + implementation

| persona | id | severity | grounding | issue | disposition |
|---|---|---|---|---|---|
| writer | 1 | BLOCKER | confirmed | the ten rules govern filing only; four of five defect examples pass them | applied — four register rules added |
| writer | 5 | MAJOR | confirmed | rule 7's own test does not separate its own example pair; both headings are imperative | applied — test is now "words the reader already has" |
| writer | 6 | BLOCKER | confirmed | the two modules are disjoint by declaration, so answer-first and the sentence ceiling reach no file | applied — restated as this file's rules |
| writer | 7 | MAJOR | advisory | nominalization is the largest missing rule; four of five examples put an abstraction in the subject slot | applied — "name the actor, use a verb" |
| writer | 8 | MAJOR | advisory | rules 2 and 4 strip an ADR of the rejected options that are its purpose | applied — explicit exception in rule 7 |
| writer | 9,10 | MAJOR | confirmed | two sections break three of the rules they state | applied — both deleted, funding the additions |
| writer | 13 | MINOR | advisory | four unconditional deletions with no floor remove error-recovery content | applied — never-cut list added |
| writer | 14 | NIT | confirmed | the plan lists caps as open while the shipped linter already has them | applied |
| skeptic | 11 | BLOCKER | confirmed | nothing executes `doc-lint.sh`; framework hooks are prose, never shell | applied — `PostToolUse` hook, after the user chose it |
| skeptic | — | MAJOR | confirmed | `04-execute-loop.md:74` appends to a heading the template no longer has | applied |
| skeptic | — | MAJOR | confirmed | `v-team.md:114` stages the plan but not the sidecar | applied |
| skeptic | — | MAJOR | confirmed | `tests/unit/v-team.bats:43` greps the template for `Critique trail` and goes red | applied |
| skeptic | — | MAJOR | confirmed | the plan claimed `/v-capture` reads the trail; `v-capture.md` contains no occurrence of `plan` or `trail` | applied — claim corrected |
| quality | 1,2,3 | MAJOR/MINOR | confirmed | rules 9, the scope caveat and the report-exceptions clause duplicate `communication.md` | applied — that module owns them |
| quality | 4 | BLOCKER | confirmed | the linter fired on five legitimate shipped files | applied — `PROC3b` dropped, `HIST7` narrowed, scoping added |
| quality | 5 | MAJOR | confirmed | `templates/_features/planning-session.md` already is a record sidecar | applied — vocabulary aligned, both point at each other |
| quality | 6 | MAJOR | confirmed | the change turns a two-way tested duplication into a four-way one, one copy untestable | accepted with the cost stated in ADR-023 |
| quality | 7 | MINOR | confirmed | the linter enforced a 30-word ceiling whose only home was a bash comment | applied — written into rule 3 |
| quality | 8 | MINOR | confirmed | the indication and ADR-018 document a binding path no file uses | open — F14 |
| quality | 9 | MINOR | confirmed | "every doc-writing step file" is not a testable set | applied — 14 paths pinned |
| quality | 10 | NIT | confirmed | 400 lines of bash, of which ~80 are argument parsing | applied — patterns moved to `lib/doc-lint-patterns.tsv` |
| correctness | — | — | — | did not return findings | — |
| skeptic | 6 | MINOR | confirmed | `vault-guide.md` and `vault/features/v-team.md` still tell the next session the trail lives in the plan | applied |
| skeptic | 7 | MAJOR | confirmed | `templates/decision.md` defines `## Context` as pure origin story; read literally the rule deletes it | applied — the exception names `## Context` and `## Consequences` |
| skeptic | 8 | MAJOR | confirmed | the register rules have no pattern behind them and the standard implied every rule was checked | applied — the standard now says which rules are judgement |
| skeptic | 9 | MAJOR | confirmed | the plan restated all ten rules, breaking the rule it introduces | applied — cut to a pointer |
| skeptic | 12 | MINOR | confirmed | a first sweep over an existing vault buries the operator and earns a permanent `DOC_LINT=off` | applied — `--changed` scopes to the working tree |
| skeptic | 13 | MINOR | confirmed | an unrecognised type silently took the loosest cap | applied — unknown types are reported |

## Metrics

Four reviewers spawned, three returned. 45 findings: 42 applied, 1 accepted with its cost stated in
ADR-023, 2 left open as work items. One reviewer (correctness) returned nothing, so the linter's
execution bugs were found by a 27-case behaviour harness run directly instead.

The skeptic's full findings arrived after the first implementation pass and six of them were still
live — the stale trail references, the ADR `## Context` carve-out, the unchecked register rules, the
plan restating its own rules, the unscoped first sweep, and the silent unknown-type cap.

## Rejected / deferred

- **Migrating the 54 existing over-cap plans in this change.** `/v-reconcile` handles them on demand,
  one approval gate per file, rather than a bulk rewrite nobody can review.
- **`PROC3b` (`N findings`).** It cannot distinguish a process count from a ban on process counts,
  and fired on `communication.md`'s own quoted prohibition.
- **Bare `no longer` / `previously` in `HIST7`.** An ADR's Consequences section legitimately says
  "X is no longer installed"; that is current state, not history.
- **Activating the `director` output style.** The user reviews it first. It is installed at
  `~/.claude/output-styles/director.md` and active in none of 18 projects.
- **Research on measured document limits.** Two research agents ran; neither returned in time. The
  caps are judgement, and the plan says so.
