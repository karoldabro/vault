---
type: plan
project: vault
slug: 2026-09-02-2147-consumer-seat-and-artifact-lifecycles
repos: [vault]
status: executed
process_record: 2026-09-02-2147-consumer-seat-and-artifact-lifecycles.trail.md
session:
tags: [plan]
---

# consumer-seat-and-artifact-lifecycles — plan

## Task

Give the framework a seat and a form that ask whether the receiver of a plan can do the work with
what the plan gives it. Keywords: consumer critic, artifact lifecycle, handoff, dry run, PLAN1,
PLAN2, guaranteed seat, claim word.

## Open & deferred

- **`/v-work` and `/v-do` get no linter coverage.** `templates/plan.md` is instantiated only by
  `commands/v-team/steps/03-propose-loop.md:32`; `/v-work` writes no plan artifact and `/v-do` writes
  nothing at all, so `check_plan` never sees their work. For those two the lite critic in
  `commands/v-work/steps/03-propose.md` §3a.6 is the only thing that asks the four questions, and it
  runs only when the plan spans more than two files.
- **PLAN2 keys off the word `create`, and editing a file can create a handoff too.** Item 7 of this
  plan edits `commands/v-team/steps/03-propose-loop.md` §(c) and creates a handoff by doing it;
  PLAN2 does not notice. The wider trigger — any non-empty work-items table — fires on all 8 plans in
  `vault/plans/` that still carry `status: proposed`, which switches the linter off. Widen it once
  those 8 carry their real status. A work item written as `add` or `new` also escapes. The
  `consumer` critic covers the judgement half.
- **Claim words are not linted.** `wired`, `complete`, `covered`, `integrated` appear legitimately in
  ordinary prose, so a regex over them would fire on correct work and get `bin/doc-lint.sh` switched
  off — the failure `lib/doc-lint-patterns.tsv` warns about in its own header. They are interrogated
  by the `consumer` critic's checklist instead.
- **Two pre-existing test failures remain in `tests/unit/document-standard.bats`,** neither touched
  by this change: test 33 expects the `unknown type` note on a file that produces no other finding,
  and the note is designed to ride along with one; test 39 (`--compare`) expects `VP8X` in output.

## Verified current state

- `templates/plan.md` work-items columns were `action · tool · constraint · verification` — all
  producer-side, no column naming a reader · read 2026-09-02.
- `personas/_resolution.md` §2 seated architect + `correctness` + 1–2 keyword lenses + `skeptic`;
  every one a mechanism lens, and §2.1 and §2.2 carried their own seat lists with no consumer
  entry · read 2026-09-02.
- `templates/plan.md` is instantiated only by `commands/v-team/steps/03-propose-loop.md:32` —
  `grep -rn "templates/plan.md" commands/` returns two lines, both in that file. `/v-work` writes no
  plan artifact · run 2026-09-02.
- `tests/unit/document-standard.bats` "every linter check maps to a written rule" never opened
  `document-standard.md`: it looped over `lib/doc-lint-patterns.tsv` rows and checked only the
  `group` column, so SIZE1, LONG1, DUP1 and INDEX1–3 were mapped to no written rule · read
  2026-09-02.
- `lib/doc-lint-patterns.tsv` group comments named rules 2, 4 and 9 while
  `commands/_shared/document-standard.md` numbers those same rules 5, 7 and 10 · read 2026-09-02.
- `commands/_shared/document-standard.md` is 119 lines against a 120-line instruction cap enforced by
  its own test, so the new rule could not be written into it · `wc -l` 2026-09-02.
- `vault/plans/` holds 24 plans. Before the status gate, PLAN2 fired on two of them —
  `2026-06-19-1106-v-cr-command.md` (16 create rows, `status: executed`) and
  `2026-08-04-vault-git-autosync.md` (2, `status: implemented`) · run 2026-09-02.
- With the status gate, `bin/doc-lint.sh vault/plans/*.md | grep -c PLAN2` returns 0 · run
  2026-09-02.

## Decisions

- The consumer seat is guaranteed, not a relevance pick — a panel picked for mechanism reproduces one frame.
- The critic simulates rather than reviews — a checklist can approve a handoff that reads complete and is not.
- Lifecycle enforcement is structural (blank cell), not lexical — a claim-word regex would be imprecise.
- `## Artifact lifecycles` must state `none` explicitly when a plan creates no handoff — silence is not a pass.
- PLAN1/PLAN2 apply rule 8 rather than adding rule 11 — rule 6, one rule one place.
- The rule's text lives in `lib/doc-lint-patterns.tsv` and `templates/plan.md` — `document-standard.md` is full.
- A lifecycle row must name a path or a backticked identifier — emptiness alone lets prose pass.

## Scope & non-goals

Covers: the new critic, its guaranteed seat in `/v-team` and `/v-work`, the plan-template section,
the written rule, the linter check, its tests, the indication. Does **not** cover `/v-do`, does not add a
claim-word regex, and does not change `/v-cr` — reviewing an existing diff has its own coverage
contract.

## Artifact lifecycles

| artifact | who asks for it | who writes it | who reads it | absent or malformed |
|---|---|---|---|---|
| `personas/_shared/consumer.md` | `personas/_resolution.md` §2 seats it every run | this plan | `03-propose-loop.md` §(b) loads it, §(c) spawns it | loader finds no file → `_resolution.md` §1 fallback item 4 warns once, panel runs a seat short |
| `## Artifact lifecycles` table in a plan | `templates/plan.md` section comment | the drafting session | the `consumer` critic (§(c) envelope) and the implementing session | `bin/doc-lint.sh` PLAN2 fires: section missing; PLAN1 fires: blank cell |
| PLAN1 / PLAN2 findings | `bin/doc-lint.sh` main loop, per file | `check_plan` | the session running §(g) finalise, which must fix before the gate | dispatch line deleted → the "wired into the main loop" test fails; code unmapped → the code-to-rule test fails |
| `vault/indications/artifact-has-a-named-consumer.md` | `02-load-context.md` indication retrieval | this plan | any future session planning a handoff | not in `vault/indications/_index.md` → never retrieved; the index row is a work item, not a nicety |

## Work items

| id | file (exact path) | action | tool | constraint | verification | status |
|----|-------------------|--------|------|------------|--------------|--------|
| 1 | `personas/_shared/consumer.md` | create | Write | mandate is simulate-then-report; bound analyzer quotes the receiver's real entry point | file exists; `grep -q 'base_agent: requirements-analyst'` | DONE |
| 2 | `personas/_resolution.md` | edit §2 | Edit | consumer is a guaranteed seat, dropped only when the change creates no handoff, and the drop is noted in the trail | §2 bullet list names it above the cap rule | DONE |
| 3 | `templates/plan.md` | add `## Artifact lifecycles` before `## Work items` | Edit | the comment carries the literal passing `none` row; the data row ships blank on purpose so PLAN1 fires until someone fills it | `bin/doc-lint.sh templates/plan.md` exits 0 (templates are exempt), asserted by a test | DONE |
| 4 | `lib/doc-lint-patterns.tsv` | append the structural-code registry | Edit | maps every code `bin/doc-lint.sh` emits to a numbered rule, and states the plan rule; `document-standard.md` is at its 120-line cap and takes no new prose | `grep -q 'PLAN1  -> rule 8' lib/doc-lint-patterns.tsv` | DONE |
| 5 | `bin/doc-lint.sh` | add `check_plan` + dispatch | Edit | one gate, no overlap: PLAN1 only with the section, PLAN2 only without it. PLAN1 fires on a blank cell and on a row carrying no path or backticked identifier, so four cells of prose fail. PLAN2 needs a `create` cell and `status: proposed`/`approved`. Templates exempt | five fixtures behave; `bin/doc-lint.sh vault/plans/*.md \| grep -c PLAN` returns 0 | DONE |
| 6 | `tests/unit/document-standard.bats` | add eight PLAN tests + a new code-to-rule test | Edit | the new test greps `bin/doc-lint.sh` for every emitted code, which the old one never did; one test asserts the dispatch line, not the function definition | 67 of 69 tests pass; the two failures are pre-existing and named in Open & deferred | DONE |
| 7 | `commands/v-team/steps/03-propose-loop.md` | edit §(b) and §(c) | Edit | §(c) envelope tells the consumer critic to write the literal receiver text into `check` | both sections name the seat | DONE |
| 8 | `commands/v-work/steps/03-propose.md` | edit §3a.6 lite critic | Edit | the lite critic asks the four lifecycle questions; `/v-work` is the default command and carries most plans | §3a.6 names the lifecycle questions | DONE |
| 9 | `vault/indications/artifact-has-a-named-consumer.md` | create | Write | ≤80 lines (indication cap) | `bin/doc-lint.sh` clean | DONE |
| 10 | `vault/indications/_index.md` | add row | Edit | row ≤400 chars (INDEX2); it took two passes to fit | `bin/doc-lint.sh vault/indications/_index.md` clean | DONE |

## Sequencing & dependencies

Item 4 before item 6 — the mapping test reads the rule text. Item 5 before item 6. Item 9 before
item 10.

## Rollback

`git revert` the commit. Nothing migrates and nothing is stateful.

The one lasting effect is on the 24 plans already in `vault/plans/`, which predate
`## Artifact lifecycles`. `check_plan` has one gate and it is unambiguous: PLAN1 runs only when the
file carries the section, PLAN2 only when it does not. PLAN2 needs both a work-items cell whose text
is exactly `create` and a frontmatter `status` of `proposed` or `approved`, so a plan already built
is never re-linted. Measured after the gate landed:
`bin/doc-lint.sh vault/plans/*.md 2>&1 | grep -c PLAN` returns 0.

## Test plan

`bats` in the container (`./tests/run.sh tests/unit/document-standard.bats`), fixtures written into
`${TMP}` by a new `mkplan` helper. Nine tests: PLAN1 fires on a blank cell and stays silent on a full
row · PLAN2 fires on a file-creating plan with no table, and stays silent on an edit-only plan, on an
executed plan, and on `templates/plan.md` · a `none` row with a reason passes while a bare `none` row
fires · the dispatch line is asserted, not the function definition · every code
`bin/doc-lint.sh` emits resolves to a numbered rule.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| t1 | item 5 | unit | `tests/unit/document-standard.bats` | PLAN1 fires on a lifecycle row with an empty cell | must | |
| t2 | item 5 | unit | `tests/unit/document-standard.bats` | PLAN2 fires on a plan whose work items create files and which has no lifecycle section | must | |
| t3 | item 5 | unit | `tests/unit/document-standard.bats` | PLAN2 stays silent on a plan with no file-creating work items | must | |
| t4 | item 5 | unit | `tests/unit/document-standard.bats` | the `none` row plus its reason passes; a bare `none` row still fires | must | |
| t5 | item 4 | unit | `tests/unit/document-standard.bats` | every code `bin/doc-lint.sh` emits resolves to a numbered rule | must | |
| t6 | item 5 | unit | `tests/unit/document-standard.bats` | a row of four prose cells naming nothing openable fires PLAN1 | must | |
| t7 | item 5 | unit | `tests/unit/document-standard.bats` | `bin/doc-lint.sh templates/plan.md` exits 0 | must | |
| t8 | item 5 | unit | `tests/unit/document-standard.bats` | deleting the `check_plan` dispatch line fails a test | must | |

## Refs

- `vault/indications/enforced-not-just-stated.md` — the rule this obeys: a stated check must name the
  function computing it and ship a test proven to fail without it.
- `commands/_shared/definition-of-done.md` — the three-state rule (met, failed, not-applicable with a
  reason) that `none` in the lifecycle table copies.
- `2026-09-02-2147-consumer-seat-and-artifact-lifecycles.trail.md` — the process record.
