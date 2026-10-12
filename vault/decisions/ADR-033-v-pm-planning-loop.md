---
type: decision
project: vault
id: ADR-033
slug: v-pm-planning-loop
status: accepted
scope: repo
date: 2026-10-12
supersedes_in_part: [ADR-013, ADR-014, ADR-024, ADR-029]
tags: [adr, v-pm, planning, personas, sessions]
---

# ADR-033 — /v-pm reads the code, runs a planning panel, and splits the work into sessions

## Context

`/v-pm` planned without reading code. ADR-024 decision 3 therefore made it emit a budget (an appetite
per repo and a first slice) and left each repo's `/v-team` session to split the work at step `(f3)`.
Its reviewers ran as a sequential pipeline (ADR-013): business advisor, product owner, architect,
contract. Each stage anchored on the one before it, so the reviewers were not independent.

The operator asked for a different command: a read-only planner that reads the context it needs,
code included, runs the same critique loop as `/v-team` with planning-focused reviewers, stays
proportional to the size of the project, and ends with the work split into sessions, each with a
ready-to-use prompt, the repo it runs in, and whether it waits or can run in parallel. The operator
also made planning refuse to start without operator-stated success criteria, and fixed four default
done lines.

Two premises of the old design no longer held. The planner now reads the code, so the reason it could
not slice is gone. And the failure that motivated the appetite rule — a 15-session up-front roadmap
that ran 2 sessions in 5.5 weeks — came from a tracker no session was made to open. A tracker the
session claims at start and closes at the end avoids that failure without forbidding up-front rows.

## Decision

1. **Read-only planning.** `/v-pm` reads vault and code (Serena, else grep) and writes vault files only.
2. **A parallel planning panel.** `/v-pm` runs §(c) to §(f) of `commands/v-team/steps/03-propose-loop.md`
   with the reviewers of `personas/_shared/planning/`: solution-architect, codebase-fit, lazy-dev,
   future-scope, system-integration, security-architect, harness-engineer, delivery-planner, plus the
   shared `consumer` and `skeptic`. The business-advisor and product-owner seats are dropped.
3. **Evidence-only grounding.** A planning finding blocks only with a repo `path:line`, a vault path or
   a re-runnable command. A URL alone stays advisory and reaches the operator as a sourced proposal.
4. **A scale tier.** Intake counts repos and risky surfaces into `small`, `medium` or `large`, which
   caps reviewers (3, 4, 5) and rounds (1, 2, 2) and limits what each lens may demand.
5. **`/v-pm` decides the sessions.** `plan.md` (`templates/feature-plan.md`) carries the Sessions table
   with the repo path, command, dependencies and `req` ids, and one brief per session — a
   `templates/handoff.md` instance whose `## Next command` is a paste-ready run line.
   `bin/pm-plan.sh check` refuses a plan that is not normalized; `order` prints the run order in
   parallel waves.
6. **Sessions claim and close their rows.** `commands/_shared/feature-pickup.md` is Step 0 of `/v-work`
   and `/v-team`: it refuses a session whose dependencies are not `done`, writes `doing`, and loads the
   brief. Close step 5.1a writes `done` with the code commit after the commit exists. A session may
   correct its own row and append rows.
7. **Success criteria are refused, not defaulted.** `/v-pm` does not plan without at least one operator
   criterion `WHEN <trigger> THE SYSTEM SHALL <observable>`; an explicit yes to a drafted line counts.
   The plan's `## Success criteria` is their single home.
8. **Four default done lines**: planning done, code implemented, code tested, static analysis passed.
   Each references the line of `commands/_shared/definition-of-done.md` that decides it per session.

## Superseded clauses

- ADR-024 decision 3 (appetite, never a task list) and decision 4 (the tracker in the project shard).
- ADR-024 decision 1, for success criteria only: elicitation still never blocks on anything else.
- ADR-013: the sequential pipeline, the clause that `/v-work` load-context stays untouched, and the
  derived-ledger no-race guarantee for session rows. Row writes now race, and `bin/pm-plan.sh set`
  serialises them under `flock`.
- ADR-014: the single-writer shard section `## Business rules to satisfy`. The plan's `req` column,
  written only by `/v-pm`, takes its role.
- ADR-029: the sentence that `/v-method` consumes the appetite `/v-pm` writes. It now reads the
  session count from `plan.md`.

## Consequences

- An operator pastes one line per session and sees which sessions may run at once.
- A row is wrong in detail more often than right; the `deviation` column and appended rows absorb
  that, and `/v-pm reconcile` folds deviations into later briefs.
- A claim stays on one machine until the plan's vault has an upstream; `~/vault/_features` has none
  today.
- 14 existing workspaces keep their legacy readers. Reconcile converts one after the operator confirms
  each row's mapping, because their shard tables differ in shape.
- **Watch for:** plans that grow sessions to look thorough on a small tier, and rows left `doing` by a
  session that died. Both are visible in `/v-pm status`.

## Cross-repo impact

Framework-only. Operator vaults are not rewritten. A session started from a brief writes its row in
the plan's vault through `bin/vault-sync.sh`.
