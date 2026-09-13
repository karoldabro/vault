---
type: session
project: vault
date: 2026-09-13
topic: coverage-gate-and-failed-sessions
continues: [[2026-09-04-0900-mechanical-session-gates]]
files_touched:
  - bin/gate.sh
  - commands/v-team.md
  - tests/unit/gate.bats
  - checks/coverage-SC-1.sh
  - checks/coverage-SC-2.sh
  - vault/architecture/session-gates.md
  - vault/architecture/session-gates-unbuilt.md
  - vault/check-budget.md
  - .claude-plugin/plugin.json
  - vault/plans/2026-09-13-1447-coverage-and-failed-sessions.md
  - vault/plans/2026-09-13-1355-proof-discipline.md
  - vault/plans/2026-09-13-1355-proof-discipline.trail.md
  - vault/plans/2026-09-13-1355-v-method.brief.md
decisions: [local]
tags: [session, gates, enforcement, epistemics]
---

# coverage-gate-and-failed-sessions

## Goal

Make a session fail when it cannot reach the success criteria the operator set, and decide how much
of a claim-and-proof discipline the framework should carry.

## Did

- Built `coverage` in [[../../bin/gate.sh]], closing row U-2 of
  [[../architecture/session-gates-unbuilt]] which had been specified and unbuilt since 2026-09-04.
  Extracted `covers_pairs` out of `due_criteria`, which already parsed the same column.
- Wired it into [[../../commands/v-team]] Step 4 as a kill criterion that runs before the decision
  is written, and gave `status: failed` its one code reader — `coverage` refuses a plan already
  carrying it.
- Added 11 cases to [[../../tests/unit/gate.bats]], including both exit codes, the phase wiring, a
  planted-violation pair, and a guard on the close-phase absence.
- Planned a claim ledger — proof, warrant, falsifier and refutation per plan statement — across
  [[../plans/2026-09-13-1355-proof-discipline]]. Two rounds of four reviewers; it did not converge
  and is deferred with 14 open blockers in its trail sidecar.
- Designed the methodology command into [[../plans/2026-09-13-1355-v-method.brief]], grounded in a
  three-agent research sweep over orchestration topologies, evidence-grading rubrics and
  independent verification tooling.
- Bumped the plugin to 1.5.0, since marketplace installs cache by version string.

## Learned

- `due_criteria` and `coverage` read the same `covers` column and need **opposite** defaults when it
  is absent. A close gate that refuses an unsayable question becomes unusable; a coverage gate that
  assumes all-covered reports thoroughness it never had. One parser, two callers, each choosing.
- `coverage` cannot run at close. `/v-do` writes a plan with no `## Work items` table, so a
  close-phase run exits 2 on every `/v-do` session. A test caught it.
- `bin/rule-count.sh --assert` can never pass: beyond the rule-line budget it enforces a 1:1
  prohibition-to-requirement ceiling that the twelve-file corpus misses by 120 lines. A check built
  on `--assert` would be permanently red, so pin the three counts instead.
- The plan's own claim table, graded by the mechanism it proposed, marked 7 of 13 claims proven —
  every one a fact about this repo, checked by a command or a line anchor. Of six claims resting on
  outside evidence it corroborated one and marked five unverified, and it refuted nothing. The
  falsifier column changed no grade.
- A citation pinned to `path:L<n>` breaks when the plan that cites it edits that file. Pinning the
  anchor to a commit and resolving with `git show` survives it; a `cmd` ground has no equivalent pin
  and stays live.
- Two of the eight evidence pitfalls the operator named have no primary source anywhere: an agent
  skewing its own search queries toward confirmation, and measuring that a community rejected an
  approach. Adjacent measurements exist for neither.
- No adoption signal has published validation against later failure. The deprecated `request`
  package draws 53,122,520 npm downloads in 30 days and last released 2020-02-11, so volume and
  currency are independent quantities.

## Behaviors & rules

- A success criterion named in no work item's `covers` cell → `bin/gate.sh coverage` exits 1 and
  names the criterion; edge: an unfinished work item still covers it, because coverage asks whether
  the work exists and `verdict` owns whether it finished.
- A plan with no `## Work items` table, no rows, or no `covers` column → `coverage` exits 2, not 1;
  edge: the caller turns exit 1 into a failed session, so an unreadable table must never declare the
  work impossible.
- A plan whose frontmatter reads `status: failed` → `coverage` refuses it; edge: this is the only
  code reader of that marker, so without it a failed plan passes the approval gate on a re-run.
- `/v-team` Step 4 runs the gate before the decision is written → exit 1 sets `status: failed`,
  reports which criterion nothing reaches, and opens no approval gate.
- The `approve` phase runs `coverage`; the `close` phase does not → `verdict` already requires every
  criterion MET at close, and a close-phase run would exit 2 on every `/v-do` plan.

## Next

- Build the methodology command from [[../plans/2026-09-13-1355-v-method.brief]]. Designed,
  unblocked, roughly twelve files.
- Redesign the claim ledger small rather than reimplementing it. The measured delta was three cheap
  parts: the commit-pinned anchor, the `rests on` edge, and the `coverage` check that shipped. Settle
  OB-1 first — a claim graded `C` costs one prose line and buys the same work items a resolving
  anchor buys, so the cheapest compliant plan proves nothing.
- Four unit tests fail on the committed baseline and predate this session: an unrecognised document
  type getting the loosest line cap, `doc-lint --compare` not naming a dropped constraint, a command
  missing its frontmatter description, and the `/v-team` output-contract case.
- Close the rule-budget overrun. Five duplicated lines in
  [[../../commands/v-team/steps/03-propose-loop]] take the corpus from 175 to 170 and 150
  prohibitions to 145; the 1:1 ratio needs roughly 120 lines rewritten.
- Add `.serena/` to `.gitignore`. Untracked, flagged earlier, and it can ship inside the plugin.

## Refs

- [[../decisions/ADR-026-mechanical-session-gates]] — established that a check is a committed script and no model decides whether work is done; `coverage` is the tenth such check.
- [[../decisions/ADR-003-tool-grounded-findings]] — the confirmed-versus-advisory rule the deferred claim ledger extends from findings to plan statements.
- [[../architecture/session-gates]] — the contract this session extended by one row.
- [[../architecture/session-gates-unbuilt]] — held `coverage` as row U-2 from 2026-09-04 until now; six checks remain.
- [[../plans/2026-09-13-1447-coverage-and-failed-sessions]] — the plan this session executed.
- [[../plans/2026-09-13-1355-proof-discipline]] — the claim ledger, planned and deferred.
- [[../plans/2026-09-13-1355-v-method.brief]] — the methodology command, designed and unbuilt.
- [[2026-09-04-0900-mechanical-session-gates]] — built `bin/gate.sh` and wrote the U-2 row closed here.
