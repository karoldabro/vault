---
type: decision
project: vault
id: ADR-029
slug: methodology-command
status: accepted
scope: repo
date: 2026-09-13
tags: [adr, command, methodology, orchestration]
---

# ADR-029 — /v-method writes the method and runs no stage

## Context

The operator holds tasks that are too large for one session and does not know which way to drive
the AI on them. The existing ladder answers how much ceremony a change deserves — `/v-ask`, `/v-do`,
`/v-work`, `/v-team` — and `/v-pm` answers what a feature must do. Neither answers which stages a
heavy task needs, which seats each stage should hold, which tools prove it, or what should stop it.

A three-strand research sweep over orchestration topologies, evidence-grading rubrics and
independent verification tooling produced `vault/plans/2026-09-13-1355-v-method.brief.md`. Three of
its findings bound every decision below.

**No study measures whether writing a methodology in advance improves the outcome.** The parts such
a document prescribes each carry evidence on their own — a verifier, a checklist, a named
constraint, a kill criterion — and the composition carries none.

**No validated instrument turns a task description into a process.** Every candidate is practitioner
doctrine. The complexity-domain classifier most often proposed has no validity proof and a
subjective domain assignment; the predictability two-by-two was repudiated by its own author for
process selection.

**A fixed budget and guaranteed criteria are exclusive.** One approach fixes the time and varies the
scope; the other fixes the criteria and varies the time. A command that implies both produces a plan
that silently breaks one.

## Decision

**`/v-method` writes a method file and runs no stage.** Each stage names an existing command, which
carries its own gates. A command that both chose the method and executed it would grade its own
choice.

**It is one command file plus one reference file**, not a dispatcher with a steps directory. The
command runs one interactive pass and writes one artifact, so a six-file read set costs attention
and buys no structure.

**The routing keys on checkable task properties, never on a complexity classification.** Fourteen
rows in `commands/v-method/routing.md`, each a property a session decides from the task in front of
it, and each carrying its method, that method's artifact and its stopping rule.
`checks/v-method-SC-3.sh` refuses a blank cell, a shifted row, a row count under eight and a
property phrased as a judgement.

**The routing is recorded as a heuristic and every answer is kept**, including the properties that
did not fire, so a later session can score the record against what happened. That record is the only
route to evidence this command will ever have.

**A task that fires no property gets the fixed localise-repair-validate pipeline.** That is the
baseline an agent architecture has to beat, so it is the first candidate rather than the last.

**Intake asks which of budget and criteria is fixed, and the method file records what the other one
lost.** That question has no safe default and always waits for the operator. Every other unanswered
question becomes a stated default, written down and flagged for correction.

**Every stage row carries five filled fields**: the command, the seats with the affordance each owns,
the tools that prove it, the exit evidence as a path or command, and the kill criterion **naming the
exact file and field its verdict is read from**. A production gate once flagged none of a hundred
cases it should have caught because its condition read a field that was always empty.

**Kill criteria are written before the stage runs**, and each stage's verdict is produced by
`bin/gate.sh verdict --run` rather than judged.

**A seat enters a stage only when it owns an affordance or a context slice one worker lacks.** Three
by default, five the ceiling, sized by a pilot at five or fewer — at an equalised thinking budget one
worker matches or beats a team on multi-hop work, so a fan-out buys context isolation and tool
asymmetry rather than headcount.

**The seam with `/v-pm` is by question, not by phase.** `/v-pm` owns what the product must do and
writes the appetite; `/v-method` owns how to work on it and consumes that appetite without
re-deriving it. A task whose business logic is unclear runs `/v-pm` first, and stage rows stay
coarser than session rows: each stage's own session splits the work inside it.

## Consequences

- The command tells the operator once, in its own output, that the composition is unevidenced.
- `bin/rule-count.sh` reads an explicit twelve-file corpus, so `/v-method` sits outside the `/v-team`
  budget; `checks/v-method-SC-4.sh` holds both its files to requirement form instead.
- The owned-rule pattern list moved out of `checks/v-loop-SC-3.sh` into
  `lib/shared-module-rules.tsv`, read by that check and by `checks/v-method-SC-5.sh`. A command
  whose subject is how to work is the one most likely to grow a second copy of `agent-conduct.md`.
- Four claim-audit signals ship nothing, and the routing reference says so rather than implying a
  check exists: source independence for documentation, machine-generated-source scoring, one
  consultancy's technology radar, and a fact-check API that refuses unregistered callers.
- No check reads a written method file, because none exists yet to read. The per-stage field rules
  are prose until one does, and `vault/check-budget.md` records that.
- The delivery criterion is operator-observed. Whether a problem statement names its reader is a
  judgement about prose, and every proxy tried accepts a one-line restatement of the task title.

## Alternatives considered

- **A mode of `/v-pm`** (`/v-pm method <task>`) — rejected. `/v-pm` already carries three modes, and
  its deliverable is what the product must do. Two questions in one file is the defect the document
  standard exists to prevent.
- **A skill rather than a command** — rejected. Skills have no approval gate and no success-criteria
  check, so nothing would force the method's own suggestions to be grounded.
- **A complexity-domain or predictability router** — rejected on the evidence. No classifier has been
  validated, and one was repudiated by its author for this use.
- **An observe-orient-decide-act framing** — rejected: it yields nothing checkable.
- **A competing-hypotheses matrix as a stage gate** — rejected. Randomised against fifty analysts it
  did not beat working without it, evidence on reducing confirmation bias was mixed, and the trained
  group skipped its steps.
- **`/v-method` executing its own first stage** — rejected. It would grade the choice it made.

## Refs

[[2026-09-13-1355-v-method.brief]] · [[2026-09-13-1530-v-method-command]] ·
[[ADR-026-mechanical-session-gates]] · [[ADR-017-evidence-based-panel-hardening]] ·
[[ADR-013-v-pm-cross-project-planning]] · [[ADR-024-vpm-pm-discipline]] ·
[[ADR-027-autonomous-test-fix-loop]] · [[llm-collaboration-patterns]]
