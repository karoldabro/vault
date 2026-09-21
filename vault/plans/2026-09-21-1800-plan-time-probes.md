---
type: plan
project: vault
slug: plan-time-probes
repos: [vault]
status: executed
process_record: 2026-09-21-1800-plan-time-probes.trail.md
arch_spec: 2026-09-21-1800-plan-time-probes.arch.md
human_plan: https://claude.ai/artifact/UZUDyo6UYBEZMqA5Gw2wDt
session: vault/sessions/2026-09-21-1800-plan-time-probes-s5.md
tags: [plan, probes, architecture, v-team]
---

# plan-time-probes — plan

## Task
Session S5 of `vault/plans/2026-09-21-0900-architecture-first-planning.md`. Add a plan-time stage to `/v-team` PROPOSE. It runs probes on the draft spec and the repo and puts the rows in every critic envelope. Read-only auditors triage the rows. The stage costs at most 50% of a PROPOSE (D-10) and skips itself above that. Contracts used: C-1, C-2, C-3, C-4. Keywords: `plan-probes`, `probe-panel`, `--stage plan`, `spec-symbols`, `auditor`, `tier`, `fresh tokens`.

## Open & deferred
- needs the operator: approve decisions PT-1 to PT-10, and rule on the two review findings this plan does not apply (the two minority lines below).
- minority: the size split. The plan touches 17 paths, past the ~15 at which a session drops work. They are 8 product and test files, 7 graders, the master plan, the rendered page and one owned-rule row. Session S11 takes the SQL probes and two auditors; the rest stays here because the graders are small and only `bin/plan-probes.sh` is large.
- minority: the reuse check stays a probe check and does not become a rule of `lib/arch-check.sh`. The gate is form-only by design, so a check of existence in code has a different owner.
- deferred: session S11 adds the `data-model` and `naming` auditors, the probes `spec-tables` and `spec-naming`, and the spec-reading part of `sql-*`. The `sql-*` probes ignore the spec and cannot fire in this repo, which has no SQL.
- deferred: `similar-symbols` noise beyond the stopword fix of W-10. The reuse auditor triages the rest.
- accepted limit: the 50% limit is a projection. With a block at its 12 KB cap and one auditor it stays under 22% for 1 to 5 critics over 1 to 3 rounds. `tier: skip` fires only on inputs outside those caps, and SC-4 proves the tiers on synthetic inputs.
- accepted limit: the constants come from two one-round PROPOSE runs. The round term is projected, and the `note:` says so. `bin/plan-probes.sh measure` is run by hand with an explicit window to refit them; the stage does not measure itself.
- accepted limit: cost counts fresh tokens (input, cache creation, output). Cache reads are recorded beside them and excluded, because a read costs a tenth of a fresh token.
- accepted limit: the auditor's tool set is stated in its envelope and not enforced. `verify` bounds what it can change: it prints only the block's own rows.
- unverified: the stage has not run inside a real `/v-team` session. SC-6 runs its scripts on two real specs; the spawn of the auditor is described in text and tested only through `verify`.
- existing defect, not this plan's: `bin/rule-count.sh --assert` fails on `HEAD` (181 rule lines, budget 173). This plan adds none.
- existing defect, not this plan's: 5 unit tests fail on `HEAD` (`document-standard.bats` two cases, `plugin-install.bats` two path notes, `research-clarify.bats` the PROPOSE output contract).

## Open questions
| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Does an auditor add rows the block lacks? | no | `bin/probe-panel.sh` block builder; `probes/similar-symbols.sh` `--names` | defaulted | no; it returns block rows with a verdict, because a row a model typed is not tool output (PT-2) |
| Q-2 | What `file` does a `spec-symbols` row carry when the spec lies outside the repo? | no | `lib/probe-run.sh` `probe_check_rows`; `VAULT.md` `vault_path` | defaulted | the spec's base name, since the core rejects an absolute file (PT-9) |

## Success criteria
| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN `bin/probe-panel.sh run --stage plan --spec <spec> --repo <repo> --only <id>` runs with no `--posture` and no `--base` THE SYSTEM SHALL print the review block format, tag framework rows `[confirmed]`, run only the named ids without repo code, print ERROR when an id has no row at the stage, exit 2 when `--posture` accompanies `--stage plan`, and WHEN `--stage` is absent THE SYSTEM SHALL behave as before | functional | command | `checks/plan-probe-SC-1.sh` | exit 0 | MET | `checks/plan-probe-SC-1.sh` exited 0 |
| SC-2 | WHEN a Reuse-map row with decision `reuse` or `extend` has a cell whose first path token is absent, or whose later identifier token occurs as no whole word in that file, THE SYSTEM SHALL print a `reuse-path-missing` or `reuse-symbol-missing` `error` row naming the spec and the cell's line, print no row for the cells `bin/probe.sh run plan` and `lib/cr-sandbox.sh cr_sandbox_root, cr_sandbox_path_is_safe` of real specs, and name a spec outside the repo by its base name | functional | command | `checks/plan-probe-SC-2.sh` | exit 0 | MET | `checks/plan-probe-SC-2.sh` exited 0 |
| SC-3 | WHEN `bin/plan-probes.sh verify <out> <rows>` runs THE SYSTEM SHALL exit 1 and print an `open:` line for each `[confirmed]` `error` row of the block, print the block's own copy of every auditor line whose whole row equals a block row and whose verdict is `applies`, `does-not-apply` or `unclear`, drop every other line, keep the exit code whatever the verdicts say, and exit 2 when `<out>/tier.txt` is missing | functional | command | `checks/plan-probe-SC-3.sh` | exit 0 | MET | `checks/plan-probe-SC-3.sh` exited 0 |
| SC-4 | WHEN `bin/plan-probes.sh budget --critics <n> --rounds <r> --block <file> --out <dir>` projects the added cost THE SYSTEM SHALL print `tier: full` when it is at most 50% of the projected baseline, `tier: block-only` when only the block fits, `tier: skip` otherwise, one `note:` line for every tier except full, and write the tier to `<dir>/tier.txt` | functional | command | `checks/plan-probe-SC-4.sh` | exit 0 | MET | `checks/plan-probe-SC-4.sh` exited 0 |
| SC-5 | WHEN `bin/plan-probes.sh measure` reads a transcript with repeated message ids, messages outside the window and a `subagents` directory THE SYSTEM SHALL count each id once, count only the window, include every subagent file, and print `fresh`, `cache_read` and `messages` per file and in total | functional | command | `checks/plan-probe-SC-5.sh` | exit 0 | MET | `checks/plan-probe-SC-5.sh` exited 0 |
| SC-6 | WHEN the stage runs on this repo with the specs of `2026-09-21-1430-v-rule` and `2026-09-21-1600-sandbox-probe` THE SYSTEM SHALL project an added cost of at most 50% of the baseline recorded for each plan in Verified current state, and print the block bytes and both percentages | delivery | command | `checks/plan-probe-SC-6.sh` | exit 0 | MET | `checks/plan-probe-SC-6.sh` exited 0 · baselines re-measured from the transcripts: 769168 and 1018594 |
| SC-7 | WHEN a session reads `commands/v-team/steps/03-propose-loop.md` THE SYSTEM SHALL find step (b2) naming `commands/_shared/plan-probes.md`, whose auditor ids equal `bin/plan-probes.sh auditors`, and `bin/rule-count.sh` SHALL print 181 rule lines with `commands/_shared/critic-panel.md` identical to commit `435a83e` | functional | command | `checks/plan-probe-SC-7.sh` | exit 0 | MET | `checks/plan-probe-SC-7.sh` exited 0 |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | change does what the task asked | met | `bin/gate.sh verdict <plan> --run` reports SC-1 to SC-7 MET; scope cut: `spec-tables`, `spec-naming` and two auditors go to S11 |
| B2 | tests covering the change pass | met | `tests/unit/plan-probes.bats` 15 of 15; the full unit suite passes 929 and fails the 5 that fail on `HEAD` (`document-standard.bats` two, `plugin-install.bats` two, `research-clarify.bats` one); 5 of 5 seeded mutants of `bin/plan-probes.sh` and `probes/similar-symbols.sh` failed a grader |
| B3 | lint passes on changed files | met | `./bin/doc-lint.sh --changed` exits 0 |
| B4 | every review finding fixed or recorded | met | every confirmed finding of both review rounds fixed; the size split and the probe-not-gate-rule ruling recorded in Open & deferred |
| B5 | invalidated docs updated | met | master plan rows S5 and S11; `commands/_shared/probe-kit.md`; `commands/v-team/steps/03-propose-loop.md`; `lib/shared-module-rules.tsv` |
| B6 | nothing unrelated in the commit | met | `git status --short` lists only this plan's files; `output-styles/director.md` and `scripts/completion-hook.sh` stay unstaged |

## Enforcement states
| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | A tool-confirmed `error` row stops PROPOSE from finalising the plan unless the operator accepts it at the gate | HALF-BUILT | `bin/plan-probes.sh verify` exits 1 and `checks/plan-probe-SC-3.sh` proves it; step (g) runs it, and it exits 2 without the `tier.txt` that `budget` writes, so a session that skipped step (b2) is refused there |
| E-2 | The stage adds at most 50% to a PROPOSE | HALF-BUILT | `bin/plan-probes.sh budget` prints the tier and `checks/plan-probe-SC-4.sh` proves it; a session obeys the tier because step (b2) says so |

## Verified current state
- `bin/probe-panel.sh run` calls `probe.sh diff` only and needs `--base`; no plan-time call exists · `sed -n 96,110p bin/probe-panel.sh` · 2026-09-21
- `probe.sh run plan --spec <file> --only <id>` exists; only `probes/similar-symbols.sh` reads the spec · `grep -n PROBE_SPEC lib/probe-emit.sh probes/*.sh` · 2026-09-21
- the registry holds 10 probes and 8 of them have stage `plan`: the hygiene four (`md-links`, `dead-files`, `token-size`, `claude-validate`), three SQL probes and `similar-symbols` · `awk -F'\t' '!/^#/ && $3=="plan"' probes/registry.tsv` · 2026-09-21
- `bin/probe.sh run plan --spec vault/plans/2026-09-21-1600-sandbox-probe.arch.md --only similar-symbols` prints 14 rows in 1.8 s and about 2.6 KB · run on `HEAD` · 2026-09-21
- the v-rule plan (S8) PROPOSE window cost 769,168 fresh tokens. The main thread took 367,286 and three critics took 106,325, 132,078 and 163,479. The window runs 2026-09-21T12:16:00Z to 12:46:27Z. Cache reads add 12,299,524 · `bin/plan-probes.sh measure ~/.claude/projects/-home-kdabrow-workspace-vault/addebe05-74e1-4854-9d29-9a12da7a8fa2.jsonl --from 2026-09-21T12:16:00Z --to 2026-09-21T12:46:27Z` · 2026-09-21
- the sandbox-probe plan (S10) PROPOSE window cost 1,018,594 fresh tokens. The main thread took 421,390 and four critics took 164,223, 177,842, 105,342 and 149,797. The window runs 2026-09-21T13:56:00Z to 14:44:49Z. Cache reads add 17,767,514 · `bin/plan-probes.sh measure ~/.claude/projects/-home-kdabrow-workspace-vault/357c4e40-91b3-4514-b2ae-dd335bda31aa.jsonl --from 2026-09-21T13:56:00Z --to 2026-09-21T14:44:49Z` · 2026-09-21
- both windows ran one critic round; both used a generic pack, since no persona pack resolves for this repo · trails of both plans · 2026-09-21
- one trial auditor (haiku, 8 rows, 6 messages) cost 35,593 fresh tokens and 120,912 cache-read tokens · `bin/plan-probes.sh measure` on its subagent file · 2026-09-21
- the two baselines fit `390000 + 140000 × critics`: it predicts 810,000 for S8 (actual 769,168) and 950,000 for S10 (actual 1,018,594) · arithmetic on the rows above · 2026-09-21
- the built stage adds a projected 37,868 tokens on the v-rule spec and 38,985 on the sandbox-probe spec. That is 4% and 3% of the recorded baselines. The blocks were 1,868 and 2,386 bytes, each with one auditor · `checks/plan-probe-SC-6.sh` · 2026-09-21
- `bin/plan-probes.sh measure` reproduces both recorded baselines from the transcripts · `checks/plan-probe-SC-6.sh` · 2026-09-21
- the rule-count corpus includes `commands/v-team/steps/03-propose-loop.md` and `commands/_shared/critic-panel.md`; it reads 181 rule lines · `bin/rule-count.sh` · 2026-09-21

## Decisions

| decision | reason | record |
|----------|--------|--------|
| PT-1 The stage runs the probes `similar-symbols` and `spec-symbols`, with no path filter and the panel's 40-row cap. S5 adds `spec-symbols`. Session S11 adds `spec-tables`, `spec-naming` and the spec-reading part of `sql-*`; session S9 owns stack packs | these two compare the draft with existing code, and their useful rows point at code the spec does not list, so a filter by listed files would drop them. The `sql-*` probes ignore the spec and cannot fire in this repo. The hygiene probes (`md-links`, `dead-files`, `token-size`, `claude-validate`) describe the repo, not the draft | local |
| PT-2 An `error` row of a `[confirmed]` probe blocks the plan at step (g); every other row informs. The operator may accept a named open row at the gate, so a wrong probe never traps a session. An auditor returns lines of the form verdict, tab, the six fields of a block row. `verify` prints the block's own copy of a matching row and drops any other line. A verdict changes no exit code and no severity | D-6: only a tool run blocks, and a row a model typed is not tool output | vault/decisions/ADR-003-tool-grounded-findings.md |
| PT-3 Cost is fresh tokens: input, cache creation and output, once per message id. `bin/plan-probes.sh measure` produces it. Baselines live in Verified current state and the constants in `bin/plan-probes.sh` settings. `budget` reads the critic count (personas selected at step (b)), the round count (`team_max_rounds`) and the block file; it counts the auditors itself from the rows in the block, then projects `block_tokens × (critics × rounds + 1) + auditors × 36000` against 50% of `390000 + 140000 × critics × rounds`, and picks `full`, `block-only` or `skip` | PROPOSE cost is unknown when the stage starts, so the stage projects it from constants measured on two real runs | local |
| PT-4 The approval block shows one line per exception and nothing on a clean run. The exceptions are: the stage skipped, run without the auditor, a tool absent, an open tool-confirmed defect. `budget` prints the first two notes; `verify` prints the other two, reading `<out>/operator.txt` for an absent tool. The lines go in the block's `Open` field | a clean run is normal and the operator's output contract reports exceptions only | local |
| PT-5 One auditor exists now: `reuse`, which reads the rows of `similar-symbols` and `spec-symbols`. It is an `Explore` subagent on `haiku`, starts only when the block holds one of those rows, and reads code with Read and Grep only | its output is checkable against the block, so it goes to the cheaper model; with no rows it has nothing to triage. `data-model` and `naming` belong to S11 with the probes that read the spec | local |
| PT-6 A tool that is absent prints `absent: <id>: <install>` in the block status. Its auditor is not started, the note names the id and the install command, and an absent tool never reads as clean. No plan-time probe has an install command today, so the rule waits for the S9 stack packs | D-5: a probe never installs a tool, and silence about a missing check reads as a pass | local |
| PT-7 The stage runs only when the plan names an `arch_spec`; a repo without `arch_profile` gets no stage and no note | the auditor compares a draft spec with code; without a spec there is nothing to compare | local |
| PT-8 `commands/_shared/plan-probes.md` owns the tier, the auditor, `verify` and the notes, and references `commands/_shared/critic-panel.md` section (a) for the block rules. `03-propose-loop.md` calls it, `probe-kit.md` owns the panel flags and probe rules, and `critic-panel.md` is not edited | one home per rule, and D-7 keeps the review panels separate commands | local |
| PT-9 `spec-symbols` splits a Reuse-map cell on whitespace and commas. The first token that contains `/` is the path. Each later token that is an identifier is a symbol, checked as a whole word in that file. A cell with no path token is skipped. A spec outside the repo is named by its base name, since the core rejects an absolute file. The check runs before the symbol scan and needs `PROBE_SPEC` | real cells hold `path sym, sym` and `path word word`; a per-token check gives no false row on them, and a repo with the vault elsewhere still gets rows | local |
| PT-10 Edge contracts. `budget`: critics and rounds are integers of at least 1, block bytes convert to tokens rounded up, a projection equal to the limit is `full`, a number above 1000000000 exits 2, a setting that is not a number or `PLAN_PROBE_BYTES_PER_TOKEN` of 0 exits 2 naming it, an empty block is valid, a missing block exits 2, a missing `--out` directory is created. `measure`: both window ends are inclusive and compared as instants, a missing bound or `from` after `to` exits 2, a non-JSON line is skipped and counted on stderr, a missing usage field counts 0, a repeated id counts once at its largest `output_tokens`. `verify`: `tier.txt` holds `full`, `block-only` or `skip` or `verify` exits 2, a repeated auditor line prints once, a line with CRLF is dropped. `spec-symbols`: backticks and a trailing `.` or `,` are stripped from a token, the decision compares lower-case and trimmed, a non-ASCII symbol is skipped | the plan otherwise leaves each point to the implementer, and a test can pin only a stated value | local |

## Scope & non-goals
Covers the stage, its block, one auditor, one new probe, the tier decision and the token measurement. It does not build stack packs (S9), the SQL comparison probes (S11) or a change to the C-2 row shape or the C-3 registry columns. It does not run pull-request code: plan-time runs read the operator's own repo and the panel passes `--no-repo-code`. It does not claim that longer planning cuts rework.

## Artifact lifecycles
| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `tier:` and `note:` lines and `<out>/tier.txt` of `bin/plan-probes.sh budget` | step (b2) of `commands/v-team/steps/03-propose-loop.md`; `verify` at step (g) | `bin/plan-probes.sh` | the PROPOSE session and the approval block | a bad number or unreadable block exits 2 and the session skips the stage with a note; a missing `tier.txt` makes `verify` exit 2 |
| the probe block, saved as `<out>/block.txt` by redirecting `bin/probe-panel.sh run --stage plan` | `budget` and the critic envelope of step (c) | the PROPOSE session | each critic, the auditor and `budget` | INCOMPLETE reads as a lower bound; ERROR leaves the envelope without rows and the note says so |
| the auditor envelope: spec path, the reuse question, the block rows, the line format, the tools allowed | the reuse auditor | the PROPOSE session from `commands/_shared/plan-probes.md` | the auditor | an envelope with no rows is not sent |
| `<out>/auditor-reuse.tsv`: the auditor's reply, one line per row: verdict, tab, six fields | `bin/plan-probes.sh verify` | the PROPOSE session, from the auditor's reply | `bin/plan-probes.sh verify` | a line that does not equal a block row, or names another verdict, is dropped and counted in a `note:` |
| the `spec-symbols` row of `probes/registry.tsv` | `bin/probe.sh run plan` | this plan | `bin/probe.sh`, `bin/probe-panel.sh` | a missing row exits 2 with `no probe named spec-symbols runs at this stage` |
| `PLAN_PROBE_*` settings in `bin/plan-probes.sh` | `bin/plan-probes.sh budget` | this plan | `budget` | a non-number exits 2 naming the variable |

## Work items
| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `checks/plan-probe-SC-1.sh` | create | Write | builds a fixture git repo; the plan-stage call has no `--posture` and no `--base`; adds the cases ERROR for an unknown id and exit 2 for `--posture` with `--stage plan`; runs `checks/probe-panel-SC-1.sh` to `-6.sh` for the unchanged path | SC-1 | exits 2 before W-9, 0 after | DONE |
| W-2 | `checks/plan-probe-SC-2.sh` | create | Write | Reuse-map rows: existing path and symbol, absent path, absent symbol, path with `..`, no path token, decision `new`, the two real cells of SC-2, a spec outside the repo | SC-2 | exits 2 before W-10, 0 after | DONE |
| W-3 | `checks/plan-probe-SC-3.sh` | create | Write | a block with a confirmed error, a confirmed warn and an advisory error; auditor lines with a forged severity, a forged message, line `012`, a tab in the verdict and an unknown verdict; a missing `tier.txt` | SC-3 | exits 2 before W-8, 0 after | DONE |
| W-4 | `checks/plan-probe-SC-4.sh` | create | Write | table of critics, rounds, block bytes against the expected tier, with the exact boundary, a missing block and critics 0 | SC-4 | exits 2 before W-8, 0 after | DONE |
| W-5 | `checks/plan-probe-SC-5.sh` | create | Write | builds a transcript directory with jq: duplicate ids, two windows, two subagent files | SC-5 | exits 2 before W-8, 0 after | DONE |
| W-6 | `checks/plan-probe-SC-6.sh` | create | Write | runs the panel on both real arch specs, feeds `budget`, compares with the recorded baselines; when the real transcripts exist it re-runs `measure` and the jq expression of the recorded baseline and compares; it prints that it did not when they are absent | SC-6 | exits 2 before W-8, 0 after | DONE |
| W-7 | `checks/plan-probe-SC-7.sh` | create | Write | greps step (b2), compares auditor ids, runs `bin/rule-count.sh`, runs `git diff --quiet 435a83e -- commands/_shared/critic-panel.md` | SC-7 | exits 2 before W-12, 0 after | DONE |
| W-8 | `bin/plan-probes.sh` | create | Write | subcommands `budget`, `verify`, `measure`, `probes`, `auditors` with named flags `--critics`, `--rounds`, `--block`, `--out`; settings from PT-3; `verify` reads `<out>/confirmed.tsv` and `advisory.tsv` and compares whole lines, and strips tabs and newlines from every note; the `budget` note marks the round term as projected; at most 260 lines | SC-3, SC-4, SC-5, SC-6 | `checks/plan-probe-SC-3.sh`, `-4.sh`, `-5.sh` exit 0 | DONE |
| W-9 | `bin/probe-panel.sh` | edit | Edit | add `--stage diff\|plan`, `--spec <file>` and repeatable `--only <id>`. `--stage plan` implies posture `own` without repo code, needs no `--posture` or `--base`, rejects `--posture`, skips `probe_changed` and the registry-edited demotion, calls `probe.sh run plan` once per `--only` id, merges rows and status, takes the largest exit code with 1 counted as 0, and states ERROR when any call prints a `probe:` line; the diff path stays as is | SC-1 | `checks/plan-probe-SC-1.sh` exits 0 | DONE |
| W-10 | `probes/similar-symbols.sh` | edit | Edit | check `spec-symbols` follows PT-9 and runs before the symbol scan; the stopword list gains `in on by at from`; the check `similar-symbols` prints what it printed before apart from the stopwords | SC-2 | `checks/plan-probe-SC-2.sh` exits 0; `./tests/run.sh tests/unit/probe.bats` | DONE |
| W-11 | `probes/registry.tsv` | edit | Edit | one row `spec-symbols`, stack `any`, stage `plan`, detect `test -n "$PROBE_SPEC"`, cost `S`, executes-repo-code `no`, install `none`, run `"$PROBE_FRAMEWORK/probes/similar-symbols.sh" --check spec-symbols` | SC-2 | `bin/probe.sh list \| grep -c '^spec-symbols'` is 1 | DONE |
| W-12 | `commands/_shared/plan-probes.md` | create | Write | PT-2 to PT-8 stated once; the reuse question; the auditor envelope with its return line and tools; the order: panel, `budget`, then envelopes; the four notes; references section (a) of `commands/_shared/critic-panel.md` for the block rules; at most 120 lines | SC-7 | `bin/doc-lint.sh` exits 0; `checks/plan-probe-SC-7.sh` exits 0 | DONE |
| W-13 | `commands/v-team/steps/03-propose-loop.md` | edit | Edit | step (b2) after (b) and before (c); one bullet in the (c) envelope; the notes in the `Open` field of Layer 1; step (g) runs `verify`; no `never`, `must` or `do not` in the new lines; keep the literal `plans/YYYY-MM-DD-HHMM` | SC-7 | `./tests/run.sh tests/unit/v-team.bats` no new failure; `bin/rule-count.sh` prints 181 | DONE |
| W-14 | `commands/_shared/probe-kit.md` | edit | Edit | document `probe-panel.sh --stage plan`, `--spec`, `--only` and the two `spec-symbols` rules in the Checks table | SC-1, SC-2 | `bin/doc-lint.sh commands/_shared/probe-kit.md` exits 0 | DONE |
| W-15 | `tests/unit/plan-probes.bats` | create | Write | rows of the Test backlog; runs the graders; at most 220 lines | SC-1 to SC-7 | `./tests/run.sh tests/unit/plan-probes.bats` | DONE |
| W-16 | `vault/plans/2026-09-21-0900-architecture-first-planning.md` | edit | Edit | row S5 done with its evidence; new row S11; Open & deferred line for S11 | | `bin/gate.sh verdict` on this plan; `bin/doc-lint.sh` exits 0 | DONE |
| W-18 | `lib/shared-module-rules.tsv` | edit | Edit | one owned-rule row naming `plan-probes.md`, which two tests require of every module under `commands/_shared`; recorded here because it is outside the planned file list | | `./tests/run.sh tests/unit/v-loop.bats` | DONE |
| W-17 | `vault/plans/2026-09-21-1800-plan-time-probes.human.html` | create | Bash | `bin/render-human.sh` output; publish, then set `human_plan` | | `bin/gate.sh human <plan>` exits 0 | DONE |

## Sequencing & dependencies
Order: W-1 to W-7 first (graders, exit 2 until their subject exists), then W-8 to W-11, then W-12 to W-14, then W-15 to W-17. W-9 needs W-11 for SC-1's plan-stage case. Session S11 needs the tier and verify contracts of W-8.

## Rollback
Every change is additive. Revert the session commit. A repo without `arch_profile` gets no stage, and `bin/probe-panel.sh` without `--stage` behaves as before.

## Test plan
Bats cases in `tests/unit/plan-probes.bats`, run in Docker with `./tests/run.sh tests/unit/plan-probes.bats`. Each case builds a fixture repo or transcript in a temp directory and asserts exit codes and lines. Graders are the criteria; bats cases cover edges the graders do not.

## Test design dossier
Decision table for `bin/plan-probes.sh budget` (P is the projected added cost, L is 50% of the projected baseline):

| case | inputs | tier | notes | `tier.txt` | exit |
|------|--------|------|-------|-----------|------|
| D-1 | P at most L | full | none | full | 0 |
| D-2 | P over L, block alone at most L | block-only | one, round term marked projected | block-only | 0 |
| D-3 | block alone over L | skip | one | skip | 0 |
| D-4 | block holds no reuse row | auditor term 0, tier by block alone | as tier | as tier | 0 |
| D-5 | bad number, critics or rounds below 1, missing block | none | none | not written | 2 |

Decision table for `bin/plan-probes.sh verify`:

| case | block row | auditor line | output | exit |
|------|-----------|--------------|--------|------|
| V-1 | confirmed error | any verdict or none | `open:` line, verdict beside the block's row | 1 |
| V-2 | confirmed warn, advisory error, advisory warn | any | the row with its verdict, no `open:` | 0 |
| V-3 | any | whole row equals a block row, verdict in the list | the block's own copy | as block |
| V-4 | any | forged severity or message, line `012`, unknown verdict, tab in the verdict, row not in the block, CRLF | dropped, one `note:` with the count | as block |
| V-5 | any | `tier.txt` missing or invalid | none | 2 |

Operator notes: `budget` prints the skip and block-only notes. `verify` prints the notes for an absent tool (from `<out>/operator.txt`), an open defect and dropped auditor lines. A clean run prints nothing.

Fault hypotheses:
- `verify` matches three fields like `cited` and echoes a forged row.
- `verify` takes an `error` row from `advisory.tsv`.
- The `budget` comparison uses `<`.
- `budget` skips validation and writes `tier.txt` on a bad input.
- The plan stage still calls `probe_changed` and demotes every row.
- The panel loses a `probe:` line from one of several calls, or lets exit 1 through.
- `spec-symbols` accepts `..` or an absolute path, or emits an absolute file.
- `measure` sums repeated ids or adds cache reads to `fresh`.

Metamorphic relations:
- Shuffling Reuse-map rows leaves the other rows' results unchanged.
- Adding an unrelated row leaves them unchanged.
- Two runs give identical output.
- A CRLF spec gives the same rows.
- More block bytes or more auditors never improve the tier.
- Critics 2 with rounds 3 and critics 3 with rounds 2 give one tier.

Boundary partitions:
- `budget`: the limit, one token either side, with and without the auditor, and the edge of the 12 KB cap.
- `measure`: both window ends, and `.500Z` stamps.
- `verify`: 0, 1 and 40 rows, and a 1 MB line.
- `spec-symbols`: a trailing comma, a backtick, a `..` path, an absolute path, and a prefix symbol (`foo` against `foobar`).

Property invariants:
- The printed tier equals `tier.txt`.
- `verify` output is a subset of the block's rows, and its exit ignores verdicts.
- `measure` is additive over files and idempotent over repeated lines.
- A `spec-symbols` row depends on its own cell only.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | D-1 to D-4, PT-10 | unit | `tests/unit/plan-probes.bats` | `budget` over a grid computed from the settings: the limit exactly, one token either side, with and without the auditor, rounding up; the tier equals `tier.txt` | must | |
| T-2 | D-5, PT-10 | unit | `tests/unit/plan-probes.bats` | `budget` exits 2 and writes no `tier.txt` for a non-number, `08`, critics 0, a number above 1000000000, a missing block and a zero `PLAN_PROBE_BYTES_PER_TOKEN`; an empty block gives a tier | must | |
| T-3 | monotone relation | unit | `tests/unit/plan-probes.bats` | the tier never improves as block bytes or auditors grow, and critics 2 with rounds 3 equals critics 3 with rounds 2 | should | |
| T-4 | V-1, V-2 | unit | `tests/unit/plan-probes.bats` | one `open:` per confirmed error and exit 1; exit 0 for confirmed warn and advisory error, whatever the verdicts | must | |
| T-5 | V-3, V-4, verify subset | unit | `tests/unit/plan-probes.bats` | forged severity, forged message, `012`, a tab, an unknown verdict, CRLF and an absent row are dropped and counted; output rows equal block rows byte for byte; a repeated line prints once | must | |
| T-6 | V-5 | unit | `tests/unit/plan-probes.bats` | `verify` exits 2 for a missing, empty or invalid `tier.txt` and for an unreadable directory | must | |
| T-7 | notes, PT-4 | unit | `tests/unit/plan-probes.bats` | `budget` prints a note for skip and block-only and none for full; a clean `verify` prints no `open:` or `note:`; `operator.txt` naming an absent tool gives a note with the id and install command | must | |
| T-8 | measure boundaries | unit | `tests/unit/plan-probes.bats` | window ends inclusive, `.500Z` stamps by instant, `from` after `to` exits 2, a bad JSON line skipped, a missing field counts 0, an empty file gives zeros | must | |
| T-9 | measure duplicates | unit | `tests/unit/plan-probes.bats` | a repeated id with output 5, 50, 500 counts once at 500; cache reads stay out of `fresh`; two files sum | must | |
| T-10 | fault hypotheses | integration | `checks/plan-probe-SC-1.sh` | on a fixture repo with no base ref: rows `[confirmed]`, `--posture` exits 2, an unknown `--only` id gives ERROR, a run with findings exits 0, a repeated run is identical | must | |
| T-11 | grammar partitions | integration | `checks/plan-probe-SC-2.sh` | one Reuse-map row per grammar case gives the stated row or none: trailing comma, backtick, `..`, absolute path, prefix symbol, `-`, decision `New ` | must | |
| T-12 | metamorphic | integration | `checks/plan-probe-SC-2.sh` | shuffling rows, adding an unrelated row and a CRLF copy leave the other rows' results unchanged | should | |
| T-13 | unlisted-file row | unit | `tests/unit/plan-probes.bats` | a `similar-symbols` row for a file the spec does not list stays in the plan block; the stopwords `in on by at from` remove only noise rows | should | |
| T-14 | stage-runs decision | unit | `tests/unit/plan-probes.bats` | `commands/v-team/steps/03-propose-loop.md` names step (b2) before step (c) and after step (b), and `commands/_shared/plan-probes.md` states the panel-then-budget order | should | |

## Refs
- `vault/plans/2026-09-21-0900-architecture-first-planning.md`: master plan, decisions D-4 to D-10 and contracts C-1 to C-4.
- `commands/_shared/probe-kit.md`: registry, cells, exit codes and the checks table this plan extends.
- `commands/_shared/architecture-spec.md`: the spec format the probes read.
- `vault/decisions/ADR-003-tool-grounded-findings.md`: a finding blocks only when a tool confirms it.
- `vault/plans/2026-09-21-1130-probe-kit-core.md`: S4, which built the kit and deferred the cost measurement to this plan.
