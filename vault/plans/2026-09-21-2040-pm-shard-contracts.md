---
type: plan
project: vault
slug: pm-shard-contracts
repos: [vault]
status: proposed
process_record: 2026-09-21-2040-pm-shard-contracts.trail.md
arch_spec: 2026-09-21-2040-pm-shard-contracts.arch.md
human_plan: https://claude.ai/artifact/5TgP33LyxdUWEgSVMHvamF
session_of: 2026-09-21-0900-architecture-first-planning.md#S12
session:
tags: [plan, contracts, v-pm]
---

# pm-shard-contracts — plan

## Task
Session S12 of `vault/plans/2026-09-21-0900-architecture-first-planning.md`. Give the `/v-pm` project shard the `depends` column and a `## Cross-session contracts` section. Seed both from `commands/v-pm/steps/04-seed-workspace.md`. Run `bin/gate.sh master` on each shard in `/v-pm status`. Extend the close duty of `commands/v-work/steps/05-commit-capture.md` to a plan that names `session_of`. Contract used: C-11. Keywords: `project-shard`, `depends`, `Cross-session contracts`, `gate.sh master`, `session_of`.

## Open & deferred
- needs the operator: approve decisions PS-1 to PS-5.
- accepted limit: a shard that already exists in an operator vault has no `depends` column. `/v-pm status` prints one `Contract gap` line for it, and the gap clears when that project's next `/v-team` session runs step (f3) item 6 of `commands/v-team/steps/03-propose-loop.md`.
- accepted limit: `/v-pm status` runs the gate on open shards only, so a finished feature is not re-read.
- outside the planned file list: `commands/v-team/steps/03-propose-loop.md` step (f3) item 6 now inserts `depends` only when the header lacks it, since a freshly seeded shard has it.
- accepted limit: a seeded shard that keeps a literal `<N>` appetite or `REQ-NN` line passes the gate. No check reads those placeholders.
- unverified: the seed and status steps are prose that a `/v-pm` session follows. The graders check the text and run the gate on a shard built from the template; no test runs a `/v-pm` session.
- existing defect, not this plan's: `bin/rule-count.sh --assert` fails on `HEAD` (181 rule lines, budget 173). This plan adds none.
- existing defect, not this plan's: 5 unit tests fail on `HEAD` (`document-standard.bats` two, `plugin-install.bats` two, `research-clarify.bats` one).

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Where does the master-plan close duty live? | no | `commands/v-work/steps/05-commit-capture.md`; `commands/_shared/definition-of-done.md` | defaulted | in step 5.0 of `commands/v-work/steps/05-commit-capture.md`, beside the feature-mode bullet, since the row of a master plan is not a feature shard row (PS-4) |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a shard is instantiated from `templates/_features/project-shard.md` THE SYSTEM SHALL carry a `depends` column directly after `status` and a `## Cross-session contracts` section with the five columns of `templates/master-plan.md`, `bin/gate.sh master` SHALL print `master: ok` for the untouched instantiated template, for a header-only copy and for a copy with dependency rows and contract rows, SHALL exit 1 naming the pair when one contract row is deleted, and the `## Consumed contract` section SHALL equal the one at commit `af5f530` | delivery | command | `checks/shard-contracts-SC-1.sh` | exit 0 | MET | `checks/shard-contracts-SC-1.sh` exited 0 |
| SC-2 | WHEN a `/v-pm` session reads `commands/v-pm/steps/04-seed-workspace.md` THE SYSTEM SHALL find the `depends` column and the contracts section seeded with a header and no rows, and the rule that `/v-team` writes every row | functional | command | `checks/shard-contracts-SC-2.sh` | exit 0 | MET | `checks/shard-contracts-SC-2.sh` exited 0 |
| SC-3 | WHEN a `/v-pm` session reads `commands/v-pm/steps/07-status.md` THE SYSTEM SHALL find that each open shard is checked with `gate.sh master` and that a refusal is reported as one exception line and nothing is printed for a clean shard | functional | command | `checks/shard-contracts-SC-3.sh` | exit 0 | MET | `checks/shard-contracts-SC-3.sh` exited 0 |
| SC-4 | WHEN a session reads step 5.0 of `commands/v-work/steps/05-commit-capture.md` THE SYSTEM SHALL find the master-plan close duty naming `session_of` and `gate.sh master`, `bin/rule-count.sh` SHALL print 181 rule lines, and `tests/unit/v-pm.bats` SHALL guard the text of the four files | functional | command | `checks/shard-contracts-SC-4.sh` | exit 0 | MET | `checks/shard-contracts-SC-4.sh` exited 0 |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | change does what the task asked | met | `bin/gate.sh verdict <plan> --run` reports SC-1 to SC-4 MET; scope cut: none |
| B2 | tests covering the change pass | met | `./tests/run.sh tests/unit/v-pm.bats` 46 of 46; the full unit suite fails only the 5 that fail on `HEAD` |
| B3 | lint passes on changed files | met | `./bin/doc-lint.sh --changed` exits 0 |
| B4 | every review finding fixed or recorded | met | every confirmed finding fixed; the rest are recorded in Open & deferred |
| B5 | invalidated docs updated | met | master plan row S12; `templates/_features/project-shard.md`; `commands/v-pm/steps/04-seed-workspace.md`; `commands/v-pm/steps/07-status.md`; `commands/v-work/steps/05-commit-capture.md`; `commands/v-team/steps/03-propose-loop.md` |
| B6 | nothing unrelated in the commit | met | `git status --short` lists this plan's files and two unrelated ones, `output-styles/director.md` and `scripts/completion-hook.sh`, which stay unstaged |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | A shard seeded by `/v-pm` carries the columns the gate reads | HALF-BUILT | the template and `checks/shard-contracts-SC-1.sh` prove the shape; a `/v-pm` session seeds it because `commands/v-pm/steps/04-seed-workspace.md` says so |
| E-2 | `/v-pm status` reports a shard the gate refuses | PROSE | `commands/v-pm/steps/07-status.md` says so and `checks/shard-contracts-SC-3.sh` proves the text; nothing fails if the step is skipped |

## Verified current state
- the shard Sessions table has columns `id scope command status REQ covered evidence last touched deviation` and the seed step says `/v-pm` seeds two sections and no others · `sed -n 24,45p templates/_features/project-shard.md`, `sed -n 30,40p commands/v-pm/steps/04-seed-workspace.md` · 2026-09-21
- `/v-pm status` reports three exceptions in `07-status.md` section S.3 and reads shard rows in S.2 · `sed -n 17,40p commands/v-pm/steps/07-status.md` · 2026-09-21
- `tests/unit/v-pm.bats` guards the shard by `grep` on the strings `## Sessions`, `evidence`, `last touched`, `todo | doing | done | dropped`, `NOT /v-ask` and `Consumed contract` · `sed -n 320,335p tests/unit/v-pm.bats` · 2026-09-21
- the feature-mode close duty is the F1 to F6 table in `commands/_shared/definition-of-done.md`; step 5.0 of `commands/v-work/steps/05-commit-capture.md` points to it in a bullet about feature shards · `sed -n 30,37p commands/v-work/steps/05-commit-capture.md` · 2026-09-21
- `bin/gate.sh master` treats any `## Sessions` table as a master plan, so a seeded shard with blank rows prints `master: ok` · `bin/gate.sh master` on a template copy · 2026-09-21
- `bin/rule-count.sh` reads 181 rule lines and counts `commands/v-work/steps/05-commit-capture.md` · `bin/rule-count.sh` · 2026-09-21

## Decisions

| decision | reason | record |
|----------|--------|--------|
| PS-1 The shard Sessions header is `id scope command status depends REQ covered evidence last touched deviation`. The `## Cross-session contracts` section holds the five-column header and delimiter of `templates/master-plan.md` and a comment that points to that file for the column rules, says the section lists hand-offs between sessions and is not the API compared at Step 0, and says `/v-team` writes every row. Both tables keep the header and delimiter and drop the blank example row | `depends` after `status` is the position step (f3) item 6 writes; the rules keep one home in `templates/master-plan.md`; a blank row contradicts "no rows" | local |
| PS-2 `/v-pm` seeds three sections: `## Business rules to satisfy`, `## Sessions` and `## Cross-session contracts`. The seed step says the Sessions header is copied from the template, keeps its short wording, and points to step (f3) item 6 for who writes rows. Its Required output gains a `Shard contracts:` line | v-pm does not read the code, so it cannot know what one session hands another; the step (f3) procedure has one home | local |
| PS-3 Section S.2 of `/v-pm status` runs `$VAULT_FRAMEWORK_PATH/bin/gate.sh master <shard> 2>&1` on each shard it opens. It drops the `master: ok` line and the `gate: N refusal(s)` line, turns each `REFUSED master` line into one `Contract gap` row of the S.5 digest under the `→<proj>` group, prints one line naming the shard on exit 2, and prints nothing for a clean shard. A shard whose header has no `depends` column prints one line: `Contract gap: <feature>/<proj> has no depends column; its /v-team session adds it`. A row with an empty id is not counted as a session | the digest reports exceptions only; the shard's own `/v-team` session is the one that can act, since `/v-pm` writes no session rows | local |
| PS-4 Step 5.0 of `commands/v-work/steps/05-commit-capture.md` gains a bullet worded around `session_of`: open the file named before `#` (beside the plan, or an absolute path), find the Sessions row whose id follows `#`, set `status` to `done` and `date` to today, and fill `evidence` with the result of `gate.sh verdict <plan> --run`; stage the master file in the same commit and confirm with `gate.sh master <master file>`. A commit hash is not offered, since none exists at step 5.0 | the ordering check of a later session reads that status, and nothing else writes it | local |
| PS-5 `## Consumed contract` and `## Business rules to satisfy` are not edited | the Step 0 drift check diffs `## Consumed contract` against `contracts.md` field by field | local |

## Scope & non-goals
Covers the shard template, the seed step, the status step, the close-duty bullet and the tests that guard them. Non-goals: migrating shards that already exist, a change to `commands/_shared/definition-of-done.md`, and any change to contracts C-2, C-3 or C-11.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `depends` column and `## Cross-session contracts` section of `templates/_features/project-shard.md` | `bin/gate.sh master <shard>` | `/v-pm` seeds the header, and the executing `/v-team` session writes rows through step (f3) item 6 | `bin/gate.sh master`, `/v-pm status` | a shard without them exits 1 naming the column or the table |
| the `Contract gap` line of `/v-pm status` | the operator who reads the digest | the `/v-pm status` session, from the REFUSED lines | the operator, and the shard's `/v-team` session that clears it | a skipped step prints nothing, so a refused shard reads as clean |
| the master-plan bullet of step 5.0 in `commands/v-work/steps/05-commit-capture.md` | the ordering check of a later session, which needs `status: done` | the closing session | `bin/gate.sh master` on the plan of a later session | an unmarked producer refuses its consumers with the fix `mark <producer> done` |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `checks/shard-contracts-SC-1.sh` | create | Write | stub exiting 2 until W-5; then instantiates the shard with `sed 's/{{[a-z]*}}/x/g'` and runs the gate on it first, then on a header-only copy, then with rows added, then with one contract row deleted; extracts `## Consumed contract` by `awk` from its heading to the next `## ` and compares it with the same range of `git show af5f530:templates/_features/project-shard.md`, exiting 2 when `git cat-file -e af5f530` fails | SC-1 | exits 2 before W-5, 0 after | DONE |
| W-2 | `checks/shard-contracts-SC-2.sh` | create | Write | greps the seed step for `depends`, `Cross-session contracts`, `no rows` and the `/v-team` writer rule | SC-2 | exits 2 before W-6, 0 after | DONE |
| W-3 | `checks/shard-contracts-SC-3.sh` | create | Write | greps the status step for `gate.sh master`, `Contract gap` and the silent clean case | SC-3 | exits 2 before W-7, 0 after | DONE |
| W-4 | `checks/shard-contracts-SC-4.sh` | create | Write | greps step 5.0 for `session_of` and `gate.sh master`; reads `bin/rule-count.sh`; greps `tests/unit/v-pm.bats` for the four guards | SC-4 | exits 2 before W-8, 0 after | DONE |
| W-5 | `templates/_features/project-shard.md` | edit | Edit | `depends` after `status` in the Sessions header; the blank example row dropped from Sessions; the section `## Cross-session contracts` directly after Sessions with the header, the delimiter and the comment of PS-1; the preamble and the REQ comment say `/v-pm` seeds three sections; `## Consumed contract` untouched | SC-1 | `checks/shard-contracts-SC-1.sh` exits 0 | DONE |
| W-6 | `commands/v-pm/steps/04-seed-workspace.md` | edit | Edit | line 30 says three sections and line 37 says all three; item 3 is the contracts section, header only; the Sessions item says the header is copied from the template with `depends`; one sentence points to step (f3) item 6 for who writes rows; a `Shard contracts:` line in Required output; no never, must, do not, shall, always, cannot, may not | SC-2 | `checks/shard-contracts-SC-2.sh` exits 0 | DONE |
| W-7 | `commands/v-pm/steps/07-status.md` | edit | Edit | S.2 carries the literal command and the filtering of PS-3; S.3 reads four exceptions and adds `Contract gap`; S.5 gains one sample row | SC-3 | `checks/shard-contracts-SC-3.sh` exits 0 | DONE |
| W-8 | `commands/v-work/steps/05-commit-capture.md` | edit | Edit | one bullet in step 5.0 per PS-4, placed after the feature-mode bullet; same word limits as W-6 | SC-4 | `checks/shard-contracts-SC-4.sh` exits 0; `bin/rule-count.sh` prints 181 | DONE |
| W-9 | `tests/unit/v-pm.bats` | edit | Edit | the Test backlog rows | SC-2 to SC-4 | `./tests/run.sh tests/unit/v-pm.bats` | DONE |
| W-10 | `vault/plans/2026-09-21-0900-architecture-first-planning.md` | edit | Edit | S12 row done with evidence | | `bin/gate.sh master <file>` prints `master: ok`; `bin/doc-lint.sh` exits 0 | DONE |
| W-11 | `vault/plans/2026-09-21-0900-architecture-first-planning.human.html` | edit | Bash | `bin/render-human.sh` output; republish to the `human_plan` link | | `bin/gate.sh human <master plan>` exits 0 | DONE |
| W-12 | `vault/plans/2026-09-21-2040-pm-shard-contracts.human.html` | create | Bash | `bin/render-human.sh` output; publish, then set `human_plan` | | `bin/gate.sh human <plan>` exits 0 | DONE |

## Sequencing & dependencies
Order: W-1 to W-4 first (graders, exit 2 until their subject exists), then W-5 to W-8, then W-9, W-10 and W-11, and W-12 last. W-9 needs the text of W-5 to W-8.

## Rollback
Every change is additive. Revert the session commit. A shard without the new column is refused by `gate.sh master` only when a session runs the gate on it, so no existing shard breaks on its own.

## Test plan
Bats cases in `tests/unit/v-pm.bats`, run in Docker with `./tests/run.sh tests/unit/v-pm.bats`. Graders decide the criteria; the bats cases guard the strings the way the existing shard cases do.

## Test design dossier
The gate is unchanged, so its matrix stays in `vault/plans/2026-09-21-1940-cross-session-contracts.md`. This session's faults are text drift and shape drift. The shard template loses the column. The seed step stops naming it. The status step loses the exception. The drift-checked section changes.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | shape drift | unit | `tests/unit/v-pm.bats` | the shard header has `depends` after `status`, and the section `## Cross-session contracts` has the five columns | must | |
| T-2 | seed text | unit | `tests/unit/v-pm.bats` | the seed step names the contracts section with no rows and says `/v-team` writes the rows | must | |
| T-3 | status text | unit | `tests/unit/v-pm.bats` | the status step names `gate.sh master` and `Contract gap` | must | |
| T-4 | close duty | unit | `tests/unit/v-pm.bats` | step 5.0 names `session_of` and `gate.sh master` | must | |
| T-5 | gate on shard | integration | `tests/unit/v-pm.bats` | the untouched instantiated template and a header-only copy print `master: ok`; a copy with rows and contracts prints it; one deleted contract row exits 1 | must | |
| T-6 | seed text | unit | `tests/unit/v-pm.bats` | the seed step says three sections and carries a `Shard contracts:` output line | should | |

## Refs
- `vault/plans/2026-09-21-0900-architecture-first-planning.md`: the master plan; row S12 and contract C-11.
- `vault/plans/2026-09-21-1940-cross-session-contracts.md`: S6, which built the gate and left the shard side to this session (CS-7).
- `templates/master-plan.md`: the owner of the table rules the shard copies.
