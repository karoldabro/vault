---
type: session
project: vault
date: 2026-09-04
topic: session-gates-doc-truth
continues: [[2026-09-04-0900-mechanical-session-gates]]
files_touched:
  - vault/architecture/session-gates.md
  - vault/architecture/session-gates-unbuilt.md
  - vault/check-budget.md
  - vault/defect-ledger.md
  - checks/doc-truth-SC-1.sh
  - checks/doc-truth-SC-2.sh
  - checks/doc-truth-SC-3.sh
decisions: [local]
tags: [session, gates, enforcement]
---

# session-gates-doc-truth

## Goal

Decide what this framework should take from an animation-studio session's two practices, and repair
what applying them exposed in the documents describing `bin/gate.sh`.

## Did

- Established that the studio's first practice — run the real path a user types — is already built
  here as `kind: delivery`, refused at `bin/gate.sh:279` when a plan carries no such row.
- Ran a four-critic panel on the first plan. Three returned BLOCK, one REQUEST_CHANGES. The plan was
  discarded, not revised.
- Repaired [[../architecture/session-gates]]: deleted the seven subcommand rows the dispatcher
  rejects, added `readers`, `budget` and `recurrence`, deleted the `## Open` row stating
  `bin/gate.sh` does not exist, and corrected the `artifact` row to say the operator decides it.
- Wrote [[../architecture/session-gates-unbuilt]] carrying those seven checks, each with an owner
  and the command whose exit code closes it.
- Added `budget` and `recurrence` rows to [[../check-budget]], and `D-008` to
  [[../defect-ledger]].
- Wrote three checks under `checks/`. `doc-truth-SC-1.sh` enumerates the dispatcher's case arms and
  invokes each name; `doc-truth-SC-2.sh` runs the real gate against an `artifact` row over a file
  lacking its pattern; `doc-truth-SC-3.sh` requires every implemented check to carry a budget row.
- Committed `d02fed8`. `bin/gate.sh verdict --run` recorded all three criteria MET.

## Learned

- `bin/gate.sh --help` prints the comment block at lines 2-30 through `usage()`, which the
  dispatcher never consults. Any check reading it cannot see a deleted `case` arm — proven by
  deleting `budget)` from a scratch copy and watching a `--help`-based check pass.
- `cmd_verdict` executes only `how: command` rows. An `artifact` row keeps whatever verdict the
  session typed, so a criterion closes `MET` against an empty file.
- `commands/_shared/elicitation.md:77` already carries the contrasting-example rule for the
  operator-elicitation actor: one example that satisfies and one that violates.
- `/v-team` does reach `commands/_shared/definition-of-done.md`, transitively —
  `commands/v-team.md:118` reads `commands/v-work/steps/05-commit-capture.md`, which reads it at
  line 30. A grep confined to `commands/v-team/` misses it.
- Nothing runs `checks/` on a schedule. `bin/gate.sh:558` executes a check only for the plan handed
  to `verdict --run`, so a check script binds one close and nothing after it.
- `tests/unit` has four pre-existing failures, not two: `document-standard.bats` 194 and 200, plus
  340 and 386.

## Behaviors & rules

- A check that reads a document to decide whether code exists → invoke the code instead; edge: when
  the code's help text is hand-written, reading it proves nothing about the dispatcher.
- A subcommand named in `session-gates.md` → the dispatcher answers to it; edge: when it does not,
  `checks/doc-truth-SC-1.sh` exits 1 naming the side that disagrees.
- A specified check that is not built → a row in `session-gates-unbuilt.md` with an owner and a
  closing command; edge: never a row in the contract document, which is read as active.
- A criterion decided by `how: artifact` → the operator decides it, and the document says so; edge:
  when artifact verification is built, `checks/doc-truth-SC-2.sh` fails until the claim returns.
- An enforcement state claiming `ENFORCED` → a runner executes it outside the plan's own close;
  edge: with no such runner the honest state is `HALF-BUILT`.

## Next

- `U-4` in `session-gates-unbuilt.md`: `bindings` and `readers` refuse on the same condition. Settle
  whether they are one check before the name grows back.
- No recurring runner exists for `checks/`. Until one does, every row in this repo's
  `## Enforcement states` is `HALF-BUILT` at best.
- The second-instance rule from the studio session is undecided: `elicitation.md:77` covers the
  operator-elicitation case; whether authoring a second artifact against a shipped vocabulary is a
  separate rule needs its own session.
- The failing-test prohibition has two candidate homes —
  `commands/_shared/definition-of-done.md` and the testing personas, where
  `vault/research/llm-collaboration-patterns.md:177` already assigns it.

## Refs

- [[../plans/2026-09-04-1640-session-gates-doc-truth]] — the plan this session executed.
- [[../architecture/session-gates]] — the contract repaired here.
- [[../architecture/session-gates-unbuilt]] — the seven checks that remain unbuilt.
- [[../indications/enforced-not-just-stated]] — the rule the document broke.
- [[../defect-ledger]] — `D-008` records the class.
- [[2026-09-04-0900-mechanical-session-gates]] — the session that built `bin/gate.sh`.
