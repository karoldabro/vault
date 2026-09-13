---
type: feature
project: vault
slug: v-method
status: established
tags: [feature, command, methodology, orchestration]
---

# /v-method — the command that designs the method

Takes one heavy task whose approach is unknown and writes a **method file**: ordered stages, each
naming the command that runs it, the seats it spawns, the tools that prove it, the evidence that
lets it exit, and the observation that kills it. Writes the method; runs no stage.

## Scope

For a task too large for one session whose approach the operator has not settled. Outside it: what
the product must do (`/v-pm`), how much ceremony one change deserves (the `/v-ask` → `/v-do` →
`/v-work` → `/v-team` ladder), and verifying something already built (`/v-loop`).

## Contracts

- **Command**: `commands/v-method.md`, one file, plus `commands/v-method/routing.md` as its
  reference. `install.sh` `link_tree` picks both up by glob, so no installer edit is needed.
- **Output**: `templates/method.md`, instantiated to `_features/<feature>/method.md` in feature mode,
  else `<project-vault>/plans/YYYY-MM-DD-HHMM-<slug>.method.md`.
- **Three refusals**: no written problem statement naming its reader; no criterion expressible as
  `WHEN <trigger> THE SYSTEM SHALL <observable>`; a task that fits one rung of the ladder. Each names
  what is missing and stops.
- **Routing**: fourteen rows in `commands/v-method/routing.md` Table 1, each keyed on a property a
  session decides from the task, carrying its method, that method's artifact and its stopping rule.
  `checks/v-method-SC-3.sh` refuses a blank cell, a shifted row, fewer than eight rows and a property
  phrased as a judgement.
- **Seats**: Table 2, four stages. A seat enters when it owns an affordance or a context slice one
  worker lacks. Three by default, five the ceiling.
- **Tools**: Table 3 proves an implementation, Table 4 proves a cited claim. Four claim-audit signals
  ship nothing and the table says which.
- **Grammar**: `checks/v-method-SC-4.sh` holds both files to requirement form. `/v-method` is outside
  `bin/rule-count.sh`'s twelve-file corpus, so this is its budget.
- **No duplication of the shared modules**: `checks/v-method-SC-5.sh` reads
  `lib/shared-module-rules.tsv`, shared with `checks/v-loop-SC-3.sh`.
- **Tests**: `tests/unit/v-method.bats`, 15 cases; each routing and duplication check is planted with
  the violation it exists to catch.
- Decision: [[../decisions/ADR-029-methodology-command]].

## Behaviors & rules

- A task arrives with no written problem statement → the command asks for one and stops; edge: a
  one-line restatement of the task title does not satisfy it, and no script can tell the difference,
  so the delivery criterion is operator-observed.
- A task fires no routing property → the method is the fixed localise, repair, validate pipeline;
  edge: that is the first candidate rather than the last, because it is the baseline an agent
  architecture has to beat.
- Intake reaches the budget question → it waits for the operator, since a fixed budget and
  guaranteed criteria are exclusive; edge: every other unanswered question becomes a stated default,
  written into the method file and flagged, and the run proceeds.
- A stage row is written → it carries a command, seats, tools, exit evidence and a kill criterion
  naming the exact file and field the verdict is read from; edge: "the tests fail" is not a criterion
  and `checks/x.sh` exiting 1 is.
- A stage's verdict is needed → `bin/gate.sh verdict <plan> --run` produces it; edge: no model judges
  a stage, and the kill criteria are written before the stage runs.
- A method's stages exceed the appetite `/v-pm` wrote → the command cuts scope and records the cut;
  edge: it never re-derives the appetite.

## Coupling

- `/v-pm` — writes the appetite and `requirements.md`; `/v-method` consumes both. Two questions, two
  commands: what the product must do, and how to work on it.
- The ladder — every stage's `command` cell is one of `/v-do`, `/v-work`, `/v-team`, `/v-loop` or
  `/v-pm`. `/v-ask` is not eligible: it writes nothing, so it can never close a stage.
- `bin/gate.sh` — each stage's verdict comes from `verdict --run`, and a stage plan's criteria pass
  `criteria` and `coverage` like any other.

## Gotchas

- **The composition is unevidenced and the command says so.** No study measures whether writing a
  methodology in advance improves the outcome; each part it prescribes carries evidence alone. The
  honesty statement is in the command's own output, not a footnote.
- **The routing is a heuristic.** No validated instrument maps a task description to a process. The
  method file keeps every property answer, the ones that did not fire included, so a later session
  can score the record against what happened.
- **No check reads a written method file**, because none exists yet to read. The per-stage field rules
  are prose until one does; recorded in `vault/check-budget.md`.
- **Adoption volume is not currency.** One formally deprecated package draws over fifty million
  downloads a month. A standing signal is advisory evidence a reviewer interprets.

## Sessions

- [[../sessions/2026-09-13-1447-coverage-gate-and-failed-sessions]] — the design this command was built from, written as `plans/2026-09-13-1355-v-method.brief.md`
