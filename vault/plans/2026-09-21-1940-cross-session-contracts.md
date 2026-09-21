---
type: plan
project: vault
slug: cross-session-contracts
repos: [vault]
status: proposed
process_record: 2026-09-21-1940-cross-session-contracts.trail.md
arch_spec: 2026-09-21-1940-cross-session-contracts.arch.md
human_plan: https://claude.ai/artifact/UPAU45nsGWhtAoir8SbVAM
session_of: 2026-09-21-0900-architecture-first-planning.md#S6
session:
tags: [plan, master-plan, contracts, v-team]
---

# cross-session-contracts — plan

## Task
Session S6 of `vault/plans/2026-09-21-0900-architecture-first-planning.md` (decision D-15, state E-3). Give every master plan a `## Cross-session contracts` table. Add `bin/gate.sh master <plan>`, which exits 1 when two sessions depend on each other without a contract row. Add an ordering check that refuses a session consuming a contract its producer has not produced. Contracts used: C-1, C-7. Keywords: `gate.sh master`, `lib/master-check.sh`, `session_of`, `depends`, `produced by`, `consumed by`.

## Open & deferred
- needs the operator: approve decisions CS-1 to CS-10, and the split below.
- split: this plan touches 20 paths, past the ~15 at which a session drops work. Session S12 takes the `/v-pm` side: `templates/_features/project-shard.md` gains the `depends` column and the contracts section, `commands/v-pm/steps/04-seed-workspace.md` seeds them, `commands/v-pm/steps/07-status.md` runs `bin/gate.sh master` on each shard. `tests/unit/v-pm.bats` guards the text. `commands/v-work/steps/05-commit-capture.md` extends its Sessions close duty to ordinary master plans. Until S12 lands, step (f3) inserts `depends` after `status` in a shard's Sessions table and copies the contracts section from `templates/master-plan.md`.
- accepted limit: a plan that splits its scope into sessions but has no `## Sessions` heading reads as an ordinary plan, and the gate passes it silently. Step (a) and step (f3) say when to add the sections; no code detects the omission, and a misspelled heading such as `## Session` turns the gate off the same way. This is why E-1 is HALF-BUILT.
- accepted limit: a contract whose consumer does not list the producer in `depends` (C-6 lists S7, which depends on S4 only) passes `gate.sh master`. The ordering check refuses it when that consumer's own plan runs.
- accepted limit: `bin/gate.sh` reads no code fences and matches a heading exactly, so a fenced example table under `## Sessions` counts as its header. A trailing space after the heading turns the gate off. The shared table helpers own both.
- accepted limit: a contract whose producer is also a consumer is accepted, and the ordering check ignores the session's own output.
- accepted limit: a master plan whose tables hold only the blank template rows prints `master: ok`, because a row with an empty id is skipped. The gate proves consistency, not that the tables are filled.
- deferred: `master_refuse`, `arch_refuse` and `human_refuse` share one body, and `master_order_check` and `cmd_arch` share the absolute-or-beside path rule. Extract `refuse` and a path helper into `bin/gate.sh` when a fourth library needs them. `bin/gate.sh` has 6 lines of headroom under its 830-line budget, so the next subcommand moves the `all` phase dispatch into a library first.
- deferred: a cycle check over `depends`, and a check that `depends` and the contract rows name the same direction.
- existing defect, not this plan's: the master plan holds a Sessions row for S11 inside its contracts table, and its S7 row has an extra cell. W-15 repairs both because the gate reads those tables.
- existing defect, not this plan's: `tests/fixtures/human/plan.md` has a Sessions table with `depends` and no contracts table, so W-19 adds one; two cases of `tests/unit/human-plan.bats` run `all --phase approve` on it.
- outside the planned file list: `vault/check-budget.md` gains rows for `arch` and `human` beside `master`, because `checks/doc-truth-SC-3.sh` failed on `HEAD` for those two subcommands. `tests/fixtures/human/expected.html` is re-rendered because the fixture plan gained a contracts table.
- existing defect, not this plan's: `bin/rule-count.sh --assert` fails on `HEAD` (181 rule lines, budget 173). This plan adds none.
- existing defect, not this plan's: 5 unit tests fail on `HEAD` (`document-standard.bats` two, `plugin-install.bats` two, `research-clarify.bats` one).

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Does a `/v-pm` shard count as a master plan? | no | `templates/_features/project-shard.md`; `commands/v-team/steps/03-propose-loop.md` (f3) | defaulted | yes, a shard has a `## Sessions` table, so the gate treats it as one; the shard's `depends` column arrives in S12 (CS-7) |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN an operator opens `templates/master-plan.md` THE SYSTEM SHALL show a `## Sessions` table with a `depends` column, a `## Cross-session contracts` table with the columns id, contract, produced by, consumed by and shape, and a copyable artifact-lifecycle row; `templates/plan.md` SHALL carry a `session_of` key; no comment line of the master template SHALL start with `## `; and `bin/doc-lint.sh` SHALL pass both | artifact | command | `checks/master-SC-1.sh` | exit 0 | MET | `checks/master-SC-1.sh` exited 0 |
| SC-2 | WHEN `bin/gate.sh master <plan>` reads a plan with a `## Sessions` table THE SYSTEM SHALL exit 1 naming the dependency when a `depends` entry has no contract row from the depended-on session to the depending one, exit 1 naming the contract when a contract row or a `depends` entry names a session the table lacks, exit 1 when the contracts table, the `depends` column or a row's full cell count is missing, print `master: ok <file>` and exit 0 for a complete plan with LF or CRLF endings, exit 0 silently for a plan with neither a `## Sessions` table nor `session_of` (a `## Sessions` bullet list counts as neither), and exit 2 for an unreadable file | functional | command | `checks/master-SC-2.sh` | exit 0 | MET | `checks/master-SC-2.sh` exited 0 |
| SC-3 | WHEN `bin/gate.sh master <plan>` reads a plan whose frontmatter names `session_of: <master file>#<id>` THE SYSTEM SHALL exit 1 naming the contract, the consumer, the producer and its status when a contract the session consumes has a producer whose Sessions status is not `done`, exit 1 naming `dropped`, `todo` or `doing` in the refusal, exit 1 when the master file or the session id does not exist, and print `master: ok <file>` and exit 0 when every producer is `done` | functional | command | `checks/master-SC-3.sh` | exit 0 | MET | `checks/master-SC-3.sh` exited 0 |
| SC-4 | WHEN the gate runs on the real master plan and on this plan THE SYSTEM SHALL print `master: ok` for `vault/plans/2026-09-21-0900-architecture-first-planning.md`, exit 1 naming the pair when a copy of it loses one contract row, exit 0 for `bin/gate.sh all <this plan> --phase propose` and exit 1 from the same call on a copy of the master plan that lost a contract row | delivery | command | `checks/master-SC-4.sh` | exit 0 | MET | `checks/master-SC-4.sh` exited 0 |
| SC-5 | WHEN a session reads step (a), (f3) and (g) of `commands/v-team/steps/03-propose-loop.md` and Step 4 of `commands/v-team.md` THE SYSTEM SHALL find `gate.sh master` in (f3), (g) and Step 4 and `templates/master-plan.md` in (a) and (f3); `vault/check-budget.md` SHALL list `master`, `bin/gate.sh --help` SHALL list it, `bin/gate.sh` SHALL stay at 830 lines or fewer, `bin/rule-count.sh` SHALL print 181 rule lines, and the master plan's E-3 row SHALL name `HALF-BUILT` | functional | command | `checks/master-SC-5.sh` | exit 0 | MET | `checks/master-SC-5.sh` exited 0 |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | change does what the task asked | met | `bin/gate.sh verdict <plan> --run` reports SC-1 to SC-5 MET; scope cut: the `/v-pm` files go to S12 |
| B2 | tests covering the change pass | met | `./tests/run.sh tests/unit`: 951 tests, 5 fail, the same 5 that fail on `HEAD` (`document-standard.bats` two, `plugin-install.bats` two, `research-clarify.bats` one); 6 seeded mutants of `lib/master-check.sh` each failed a grader |
| B3 | lint passes on changed files | met | `./bin/doc-lint.sh --changed` exits 0 |
| B4 | every review finding fixed or recorded | met | every confirmed finding fixed; the rest are recorded in Open & deferred |
| B5 | invalidated docs updated | met | master plan rows S6, S11, S12, contracts C-9 to C-11 and E-3; `commands/v-team.md`; `commands/v-team/steps/03-propose-loop.md`; `templates/plan.md`; `vault/check-budget.md` |
| B6 | nothing unrelated in the commit | met | `git status --short` lists this plan's files and two unrelated ones, `output-styles/director.md` and `scripts/completion-hook.sh`, which stay unstaged |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | Two sessions of a master plan that depend on each other have a contract row | HALF-BUILT | `bin/gate.sh master`, `tests/unit/gate.bats` master cases and `checks/master-SC-2.sh` exist; `all --phase propose` and `approve` call it, and `checks/coverage-SC-2.sh` and `checks/human-SC-9.sh` already run `all --phase approve` on real plans; a session runs `all` because `commands/v-work/steps/03-propose.md` and `commands/v-team.md` Step 4 say so, and `checks/master-SC-5.sh` proves the text is present, not that a session obeys it |
| E-2 | A session consumes no contract whose producer is not `done` | HALF-BUILT | the same gate reads `session_of`; `checks/master-SC-3.sh` proves it; the check is opt-in, because a plan without `session_of` is not checked and step (a) is the text that adds the key |

## Verified current state
- `bin/gate.sh` is 812 lines and routes `arch` and `human` to libraries sourced at the top · `wc -l bin/gate.sh`; `sed -n 55,70p bin/gate.sh` · 2026-09-21
- `bin/gate.sh all --phase propose` runs `criteria` then `arch`; `approve` adds `human` and `coverage` · `sed -n 786,792p bin/gate.sh` · 2026-09-21
- `table_rows` and `table_header` read a table by exact heading and stop at the next `## ` line; a row keeps its own cell count · `bin/gate.sh:96` · 2026-09-21
- the master plan has one `## Sessions` table with columns `id scope command status depends date evidence`, and the shard template has `id scope command status REQ covered evidence last touched deviation` with no `depends` · `templates/_features/project-shard.md` · 2026-09-21
- the master plan holds S11 as a row inside `## Cross-session contracts` and no S11 row in `## Sessions` · `sed -n 181p vault/plans/2026-09-21-0900-architecture-first-planning.md` · 2026-09-21
- the master plan lacks a contract row for S2 on S1, S4 on S1 and S9 on S5 · read of the two tables · 2026-09-21
- no `declare -A` in `bin` or `lib`; the libraries parse with awk and indexed arrays · `grep -rln 'declare -A' bin lib` · 2026-09-21
- every subcommand in the `case "$sub"` block needs a row in `vault/check-budget.md` · `checks/doc-truth-SC-3.sh` · 2026-09-21
- `bin/rule-count.sh` reads 181 rule lines. Its prohibition pattern matches never, do not, don't, must not, cannot, may not and refuses to. Its requirement pattern matches must, shall and always · `sed -n 40,46p bin/rule-count.sh` · 2026-09-21
- `commands/v-work/steps/03-propose.md:262` runs `bin/gate.sh all <plan> --phase approve` before its approval gate · `grep -n 'gate.sh all' commands/v-work/steps/03-propose.md` · 2026-09-21

## Decisions

| decision | reason | record |
|----------|--------|--------|
| CS-1 A master plan is any plan file whose `## Sessions` section holds a table, and its contracts table is `## Cross-session contracts` in the same file. A plan with no such table (a bullet list under that heading is not one) and no `session_of` key is ordinary: the gate exits 0 and prints nothing. A plan with `session_of` is a session's own plan and gets the ordering check only | the table is the fact that makes a plan a master, so detection needs no flag that can disagree with the file; silence for ordinary plans matches `arch` with no profile | local |
| CS-2 A dependency is an id in the `depends` column of `## Sessions`. The prose of `## Sequencing & dependencies` is not read. A dependency needs one contract row whose `produced by` holds the depended-on id and whose `consumed by` holds the depending id. The refusal is `REFUSED master <plan>: S5 depends on S3 and no contract row is produced by S3 and consumed by S5; add a row naming what S3 hands S5 and its shape, or drop S3 from depends if S5 needs nothing from S3 [S5]` | the column already holds the fact in structured form, and prose that repeats it is a second home for one rule; a regex over prose fails on any rewording | local |
| CS-3 `bin/gate.sh all --phase propose` and `--phase approve` call `cmd_master` after `arch`. Step (g) of `commands/v-team/steps/03-propose-loop.md` and Step 4 of `commands/v-team.md` call it beside `arch`. Step (f3) calls it on the shard after it writes the rows. `cmd_master` takes one plan argument, and `all` calls it without `--repo`. The `close` phase does not call it | propose and approve are where a plan is still editable; at close the Sessions table has changed status and the contract check has done its work | local |
| CS-4 The operator sees one `REFUSED master <path>: <problem> [<row>]` line per defect on standard error, followed by the footer that `bin/gate.sh` prints. Each problem names the fix. Success prints `master: ok <file>`. `master_refuse` copies `human_refuse` on purpose, since each library prints its own name | the same shape as `arch`, so a session that handles one handles the other; naming the fix in the line means the session needs no document to act | local |
| CS-5 The two sections live in the sibling `templates/master-plan.md`, not in `templates/plan.md`. Step (a) instantiates them after `## Sequencing & dependencies` when the scope splits into two or more sessions that each write a plan | most plans are ordinary, and `templates/plan.md` is 182 lines against a 300-line cap; a sibling keeps every ordinary plan free of about 40 comment lines it never uses | local |
| CS-6 A session's own plan names its master in frontmatter as `session_of: <master file>#<id>`, the file beside the plan or an absolute path. For each contract whose `consumed by` holds `<id>`, each session in `produced by` other than `<id>` has status `done`; any other status refuses, naming the contract, the consumer, the producer and the status, with the fix `mark <producer> done in the master plan if it shipped`. The master file named by `session_of` is the authoritative copy | the sub-plan is the place a session first meets the contracts it consumes, and `done` is the status a closed session row carries | local |
| CS-7 `/v-pm` shard support goes to session S12, and step (f3) adds `depends` after `status` in a shard's Sessions header and rows, then copies only the contracts section from `templates/master-plan.md`, and only then runs the gate | 18 paths past ~15; the shard template, the seed step, the status step and their test form one reviewable unit | local |
| CS-8 E-3 of the master plan becomes HALF-BUILT | the gate and its route in `all` exist and are tested, and nothing runs `all` except text a session may skip; ENFORCED needs a hook that fails without a document, and none exists | local |
| CS-9 Edge contracts. Exit 2: the plan or a `session_of` master cannot be read. Exit 1 with a named row: a `## Sessions` table with no `id`, `status` or `depends` column, a session that depends on itself, a missing contracts table, a duplicate session id (the first row wins in the ordering check), a duplicate contract id, a `depends`, `produced by` or `consumed by` token that is no session id, an empty `shape`, `produced by` or `consumed by` cell, a `session_of` with no `#<id>`, a master file with no `## Sessions` table, an id the master lacks. A row whose cell count differs from its header is refused, which also refuses a second table or a stray row under a heading. A row with an empty id cell is skipped. Tokens split on commas and spaces. CR is removed before each read, and `cmd_master` never exits 2 once the plan has been read. A `## Sessions` table with no `depends` entries and a contracts table with a header and no rows passes | each is a way a hand-edited table breaks, and a test pins only a stated value | local |
| CS-10 Master plan repairs land in W-15: S11 moves into `## Sessions` with `depends` S5, the S7 row loses its extra cell, rows C-9 (S1 to S2, S4), C-10 (S5 to S9, S11) and C-11 (S6 to S12) join the contracts table, the S6 row closes, S12 is added, and `## Sequencing & dependencies` drops the `X needs Y` sentences and keeps the Order line and the within-session precedence | the gate must pass on the real plan, and one rule needs one home (CS-2) | local |

## Scope & non-goals
Covers the template, the gate, the ordering check, and the text of step (a), (f3), (g) and Step 4. Non-goals: the `/v-pm` shard files (S12), a hook that runs the gate on a plan write and cycle detection. This plan leaves the C-2 row shape, the C-3 registry columns and every other contract row unchanged.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `templates/master-plan.md` | the sentence of step (a) that fires when the scope splits into two or more sessions that each write their own plan file, and step (f3) | framework | PROPOSE session | a plan built without it has no `## Sessions` table, reads as ordinary, and passes silently |
| `## Cross-session contracts` table of a master plan | `bin/gate.sh master` | PROPOSE session at step (a) or (f3) | `bin/gate.sh master`, each later session's PROPOSE | a dependency without a row exits 1 naming the pair; a missing table exits 1 |
| `depends` column of `## Sessions` | `bin/gate.sh master` | PROPOSE session | `bin/gate.sh master` | a missing column exits 1; a token that is no id exits 1 |
| `session_of` key in `templates/plan.md` | step (a), which reads the master path from the operator's task or the Sessions row that launched the session | PROPOSE session of a later session | `bin/gate.sh master` | a master file that does not exist or lacks the id exits 1 naming it |
| `status` and `evidence` cells of a producer's `## Sessions` row | the ordering check of a later session | the closing session, by hand until S12 | `bin/gate.sh master` | a shipped producer still marked `todo` refuses its consumers with the fix `mark <producer> done` |
| `master:` lines of `bin/gate.sh master` | step (f3), step (g), Step 4, `all --phase propose` and `approve` | `lib/master-check.sh` | the session and the operator | exit 1 stops the step; exit 2 stops it as an error |
| row `master` of `vault/check-budget.md` | `checks/doc-truth-SC-3.sh` | this plan | `checks/doc-truth-SC-3.sh` | a missing row fails that grader |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `checks/master-SC-1.sh` | create | Write | stub exiting 2 until W-7 and W-8 land; then greps the two templates, runs `bin/doc-lint.sh` on both | SC-1 | exits 2 before W-7, 0 after | DONE |
| W-2 | `checks/master-SC-2.sh` | create | Write | builds each defect of CS-9 from `tests/fixtures/master/complete.md` with sed and awk; includes CRLF and the ordinary plan | SC-2 | exits 2 before W-9, 0 after | DONE |
| W-3 | `checks/master-SC-3.sh` | create | Write | derives sub-plans from `tests/fixtures/master/session-plan.md` with a producer `done`, `todo`, `doing`, `dropped`, a missing master and a missing id | SC-3 | exits 2 before W-9, 0 after | DONE |
| W-4 | `checks/master-SC-4.sh` | create | Write | runs the gate on the real master plan and on this plan; copies the master plan to a temp folder and deletes one contract row | SC-4 | exits 2 before W-15, 0 after | DONE |
| W-5 | `checks/master-SC-5.sh` | create | Write | greps step (a), (f3), (g) and Step 4; reads `vault/check-budget.md`, the help text, the line count of `bin/gate.sh`, `bin/rule-count.sh` and the E-3 row | SC-5 | exits 2 before W-11, 0 after | DONE |
| W-6 | `tests/fixtures/master/complete.md` | create | Write | a master plan of 4 sessions with dependencies and one contract row per dependency, frontmatter `type: plan`, LF endings | SC-2 | `bin/gate.sh master` prints `master: ok` | DONE |
| W-7 | `templates/master-plan.md` | create | Write | `## Sessions` (columns `id scope command status depends date evidence`, status words `todo doing done dropped`) and `## Cross-session contracts` (columns `id contract produced by consumed by shape`) with the rules of CS-1, CS-2, CS-6 in comments, one row to copy into `## Artifact lifecycles`, the `session_of` rule and the producer's `done` duty; a row's shape is copied from the producer's scope cell and is never a placeholder; no comment line starts with `## ` | SC-1 | `checks/master-SC-1.sh`; `bin/doc-lint.sh templates/master-plan.md` exits 0 | DONE |
| W-8 | `templates/plan.md` | edit | Edit | frontmatter key `session_of` with a one-line comment | SC-1 | `bin/doc-lint.sh templates/plan.md` exits 0 | DONE |
| W-9 | `lib/master-check.sh` | create | Write | `cmd_master <plan>` taking one argument, `master_refuse` and two awk programs (table check, ordering check); reads with `table_rows`, `table_header`, `arch_fm_value`, each call on a fresh `<(tr -d '\r' < plan)`; no temp file and no trap; a row-width check; at most 170 lines; refusal text per CS-2 and CS-6 | SC-2, SC-3 | `checks/master-SC-2.sh` and `-3.sh` exit 0 | DONE |
| W-10 | `bin/gate.sh` | edit | Edit | source `lib/master-check.sh` beside the other libraries; route `master` to `cmd_master`; call `cmd_master "$plan"` in `propose` and `approve` after `cmd_arch`, without the `--repo` arguments; add `master` to the usage text and widen the usage window; at most 830 lines | SC-4, SC-5 | `bin/gate.sh --help \| grep -c 'gate.sh master'` is 1 | DONE |
| W-11 | `vault/check-budget.md` | edit | Edit | one row `master` in the `## Check budget` table, in the format of the `arch` row; outside the planned file list because `checks/doc-truth-SC-3.sh` requires it | SC-5 | `checks/doc-truth-SC-3.sh` exits 0 | DONE |
| W-12 | `commands/v-team/steps/03-propose-loop.md` | edit | Edit | (a): one sentence adding the two sections of `templates/master-plan.md` when the scope splits into two or more sessions that each write their own plan file, and one that reads the master path from the task and writes `session_of`; (f3): insert `depends` after `status`, write contract rows, then run `gate.sh master <shard>`; (g): `gate.sh master <plan>` beside `arch`; imperative lines with none of never, must, do not, shall, always, cannot, may not | SC-5 | `checks/master-SC-5.sh`; `bin/rule-count.sh` prints 181 | DONE |
| W-13 | `commands/v-team.md` | edit | Edit | Step 4 runs `gate.sh master <plan>` beside `arch`; exit 1 stops the gate; same word limits as W-12 | SC-5 | `checks/master-SC-5.sh`; `bin/rule-count.sh` prints 181 | DONE |
| W-14 | `tests/fixtures/master/session-plan.md` | create | Write | an ordinary plan with `session_of: complete.md#S3`, a copy of the file beside it | SC-3 | `bin/gate.sh master` prints `master: ok` | DONE |
| W-15 | `vault/plans/2026-09-21-0900-architecture-first-planning.md` | edit | Edit | the repairs of CS-10; S6 row done with evidence; E-3 row HALF-BUILT with its mechanism; lands in the same commit as W-10, since the gate refuses the unrepaired plan | SC-4, SC-5 | `bin/gate.sh master <file>` prints `master: ok`; `bin/doc-lint.sh` exits 0 | DONE |
| W-16 | `tests/unit/gate.bats` | edit | Edit | the master rows of the Test backlog, defects derived inline from the two fixtures, plus `all --repo` on a master plan | SC-2 to SC-4 | `./tests/run.sh tests/unit/gate.bats` | DONE |
| W-17 | `tests/unit/v-team.bats` | edit | Edit | guard the text of (a), (f3), (g) and Step 4 as the `gate.sh arch` cases do | SC-5 | `./tests/run.sh tests/unit/v-team.bats` no new failure | DONE |
| W-19 | `tests/fixtures/human/plan.md` | edit | Edit | add a `## Cross-session contracts` table with one row per `depends` entry, since the fixture reads as a master plan | SC-4 | `./tests/run.sh tests/unit/human-plan.bats` no new failure | DONE |
| W-20 | `vault/plans/2026-09-21-0900-architecture-first-planning.human.html` | edit | Bash | `bin/render-human.sh` output of the repaired master plan, so the page equals a fresh render | SC-4 | `checks/human-SC-9.sh` exits 0 | DONE |
| W-18 | `vault/plans/2026-09-21-1940-cross-session-contracts.human.html` | create | Bash | `bin/render-human.sh` output; publish, then set `human_plan` | | `bin/gate.sh human <plan>` exits 0 | DONE |

## Sequencing & dependencies
Order: W-1 to W-5 first (graders, exit 2 until their subject exists). Then W-6 to W-14 in id order, then W-15 to W-17, W-19 and W-20, and W-18 last. W-15 follows the gate, which must exist to pass on the repaired master plan. W-9 reads helpers from `bin/gate.sh` and `lib/arch-check.sh`, so it lands with W-10 in one commit. S12 needs the gate and `templates/master-plan.md` of this plan.

## Rollback
Every change is additive except the W-15 repairs to the master plan. Revert the session commit. A plan with no `## Sessions` table and no `session_of` key exits 0 silently, so no existing plan is refused.

## Test plan
Bats cases in `tests/unit/gate.bats`, run in Docker with `./tests/run.sh tests/unit/gate.bats`. Each case derives one defect from `tests/fixtures/master/complete.md` or `session-plan.md` with `sed` or `awk`, and asserts the exit code and that standard error names the row. Graders decide the criteria; bats cases cover the edges of CS-9.

## Test design dossier
Resolution matrix for `gate.sh master` (plan shape, result):

| plan shape | result |
|------------|--------|
| no `## Sessions` table, no `session_of` | silent, exit 0 |
| `## Sessions` as a bullet list | silent, exit 0 |
| Sessions table, every `depends` entry has a contract row, all tokens are session ids | `master: ok`, exit 0 |
| a `depends` entry with no matching row | exit 1, names the pair |
| a `produced by`, `consumed by` or `depends` token that is no session id | exit 1, names the token and row |
| Sessions table without a `depends` or `status` column | exit 1, names the column |
| Sessions table and no contracts table | exit 1 |
| a row whose cell count differs from its header | exit 1, names the row |
| duplicate session id or contract id | exit 1, names it |
| `session_of` and every consumed producer `done` | `master: ok`, exit 0 |
| `session_of` and a consumed producer `todo`, `doing` or `dropped` | exit 1, names contract, consumer, producer, status |
| `session_of` with no `#<id>`, a missing master file, a master without a Sessions table, or an id the master lacks | exit 1 |
| unreadable plan | exit 2 |

Fault hypotheses: CRLF endings read a table once and miss the second (T-2). A second table under a heading reads as rows (T-6). The real master plan has an S11 row in the contracts table and an 8-cell S7 row (T-9). A bullet-list `## Sessions` may read as a master (T-3). The human fixture reads as a master (T-15). Metamorphic relations: reordering rows keeps the verdict; adding a contract row for an unrelated pair keeps a refusal.

## Test backlog
All rows target `tests/unit/gate.bats` unless stated; defects are derived inline from the two fixtures.

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | matrix rows 1, 4 | unit | `tests/unit/gate.bats` | complete fixture prints `master: ok`; deleting one contract row exits 1 naming the pair; an ordinary plan is silent | must | |
| T-2 | CRLF | unit | `tests/unit/gate.bats` | CRLF copy of the complete fixture exits 0, and a CRLF copy with a row deleted still exits 1 | must | |
| T-3 | bullet list | unit | `tests/unit/gate.bats` | a `## Sessions` bullet list exits 0 silently | must | |
| T-4 | tokens | unit | `tests/unit/gate.bats` | unknown id in `depends`, `produced by` and `consumed by` each exit 1 naming the token; a duplicate session id and a duplicate contract id exit 1 | must | |
| T-5 | columns | unit | `tests/unit/gate.bats` | no `depends`, no `status`, no contracts table each exit 1 naming what is missing; empty `shape` exits 1 | must | |
| T-6 | row width | unit | `tests/unit/gate.bats` | an 8-cell row and a second table under the contracts heading each exit 1 naming the row | must | |
| T-7 | ordering | unit | `tests/unit/gate.bats` | producer `done` passes; `todo`, `doing`, `dropped` each exit 1 with the status in the message and the fix `mark`; a session that consumes nothing passes | must | |
| T-8 | session_of | unit | `tests/unit/gate.bats` | no `#<id>`, missing master, master without a table, unknown id each exit 1; absolute path form works; plan without `session_of` is not checked | must | |
| T-9 | real plan | integration | `tests/unit/gate.bats` | `gate.sh master` on the repaired master plan prints `master: ok` | must | |
| T-10 | routing | integration | `tests/unit/gate.bats` | `all --phase propose` and `approve` run the check; `all --repo <dir>` on a master plan exits by the check and never dies on an unknown option | must | |
| T-11 | exit 2 | unit | `tests/unit/gate.bats` | unreadable plan exits 2 and prints nothing to standard output | should | |
| T-12 | output contract | unit | `tests/unit/gate.bats` | every refusal line matches `^REFUSED master <path>: .* \[<row>\]$`; two runs are byte-identical | should | |
| T-13 | usage | unit | `tests/unit/gate.bats` | `--help` lists `gate.sh master` | should | |
| T-14 | step text | unit | `tests/unit/v-team.bats` | (a), (f3), (g) and Step 4 name `gate.sh master`, and (a) and (f3) name `templates/master-plan.md` | must | |
| T-15 | human fixture | integration | `tests/unit/human-plan.bats` | the two `all --phase approve` cases still pass on the fixture with its contracts table | must | |

## Refs
- `vault/plans/2026-09-21-0900-architecture-first-planning.md`: the master plan; rows S6 and S12, decision D-15, state E-3 and contracts C-1 to C-11.
- `lib/arch-check.sh`: the pattern for a check that lives outside `bin/gate.sh`.
- `commands/v-team/steps/03-propose-loop.md`: steps (a), (f3) and (g) that call the gate.
- `vault/plans/2026-09-21-1800-plan-time-probes.md`: the latest plan and its layout.
