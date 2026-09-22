---
type: plan
project: vault
slug: spec-reading-probes
repos: [vault]
status: proposed
process_record: 2026-09-22-1023-spec-reading-probes.trail.md
arch_spec: 2026-09-22-1023-spec-reading-probes.arch.md
human_plan: https://claude.ai/artifact/6QKWtW4FifFKE6rnvcohvs
session_of: 2026-09-21-0900-architecture-first-planning.md#S11
session:
tags: [plan]
---

# spec-reading-probes — plan

<!-- Governed by commands/_shared/document-standard.md. Everything about HOW this plan was reached
     lives in 2026-09-22-1023-spec-reading-probes.trail.md and is never repeated here. -->

## Task

Add the native probes `spec-tables` and `spec-naming` and the auditors `data-model` and `naming` that
`commands/_shared/plan-probes.md` names but does not yet define, so the plan-time probe stage compares
a draft spec's `## Data model` table with the repo's real SQL, the way `spec-symbols` already compares
a draft's Reuse map with real code.

Keywords: probes, spec-tables, spec-naming, data-model, naming, auditors, plan-probes, sql-schema.

## Open & deferred

- deferred: `bin/rule-count.sh` already prints 181 lines against a budget of 173, a pre-existing defect
  the master plan records as not this plan's (`vault/plans/2026-09-21-0900-architecture-first-planning.md`
  line 34). This plan's Auditors rewrite is designed to be rule-line-neutral or negative (SC-8), but it
  does not close the existing 8-line gap.
- deferred: `sql-dup-columns`, `sql-fk-index` and `sql-naming` keep their own registry rows and keep
  reading only real SQL files. `spec-tables`/`spec-naming` are new, separate rows; nothing about the
  existing three rows' `detect` or `run` cells changes.
- accepted: `spec-tables` and `spec-naming` reuse the exact rule ids of `sql-dup-columns`/`sql-fk-index`/
  `sql-naming` (`dup-column-in-table`, `dup-column-set`, `column-drift`, `fk-no-index`,
  `id-column-no-fk`, `naming-snake-case`, `naming-glossary`) rather than minting `spec-`-prefixed ones.
  The `probe` column of a finding row (`spec-tables` vs `sql-dup-columns`) already says whether the row
  came from the spec or from real SQL, so a second rule vocabulary would name the same defect twice.
- accepted: `column-drift` stays name-scoped, not table-scoped — a spec column and any same-named real
  column anywhere in the schema are compared, matching `sql-dup-columns`' existing behaviour on real
  files today (round 1, correctness-2). TB-10 pins this as intended, not a gap.
- deferred: no grader enforces any arch-spec's `## Size budgets` table today (round 1, quality-2
  confirmed `lib/arch-check.sh` has no line-count logic) — a pre-existing, repo-wide gap this plan's
  own arch spec inherits but does not introduce; out of scope here.

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN `bin/probe.sh list --repo <repo>` runs after the registry change THE SYSTEM SHALL print a `spec-tables` and a `spec-naming` line, both `stage` `plan`, both ending `ok`, and leave the `sql-dup-columns`, `sql-fk-index` and `sql-naming` lines unchanged | functional | command | `checks/spec-probes-SC-1.sh` | exit 0 | MET | `checks/spec-probes-SC-1.sh` exited 0 |
| SC-2 | WHEN `probes/sql-schema.sh --check spec-tables --spec <spec>` runs on a spec whose Data model table duplicates a real table's column set, drifts a column's type against a same-named real table's column, and declares an FK column with no matching index THE SYSTEM SHALL print one `dup-column-set`, one `column-drift` and one `fk-no-index` row, each citing the spec file and line; print no `id-column-no-fk` row even for an unreferenced `_id` column; print nothing on a spec that breaks none of them; and print nothing WHEN the spec has no Data model table even if the real schema alone already trips these rules | functional | command | `checks/spec-probes-SC-2.sh` | exit 0 | MET | `checks/spec-probes-SC-2.sh` exited 0 |
| SC-3 | WHEN `probes/sql-schema.sh --check spec-naming --spec <spec>` runs on a spec whose Data model table names a table in PascalCase and a column that the glossary bans THE SYSTEM SHALL print one `naming-snake-case` and one `naming-glossary` row citing the spec file and line, and print nothing on a spec that breaks neither | functional | command | `checks/spec-probes-SC-3.sh` | exit 0 | MET | `checks/spec-probes-SC-3.sh` exited 0 |
| SC-4 | WHEN `commands/_shared/plan-probes.md` is read THE SYSTEM SHALL show one `## Auditors` section holding one shared envelope template and a three-row table naming `reuse`, `data-model` and `naming`, each row stating its exact `reads` set and one-sentence question (this plan's `## Auditor content` table, verbatim) and distinct from the other two rows' questions, and THE SYSTEM SHALL keep the `reuse` auditor's existing behaviour: started only when the block holds a `similar-symbols` or `spec-symbols` row, only at tier `full` | functional | command | `checks/spec-probes-SC-4.sh` | exit 0 | MET | `checks/spec-probes-SC-4.sh` exited 0 |
| SC-5 | WHEN `bin/plan-probes.sh budget` runs on a block holding rows from two different auditors' probes THE SYSTEM SHALL project `auditors × 36000` counting each distinct triggered auditor once, not a fixed `36000` regardless of how many auditors would run | functional | command | `checks/spec-probes-SC-5.sh` | exit 0 | MET | `checks/spec-probes-SC-5.sh` exited 0 |
| SC-6 | WHEN `bin/plan-probes.sh verify <out> <rows-1> <rows-2> <rows-3>` runs with more than one auditor-rows file THE SYSTEM SHALL apply the byte-for-byte block-row-plus-verdict-list keep rule to each file independently and print every kept line, and WHEN called with zero rows files THE SYSTEM SHALL behave exactly as before | functional | command | `checks/spec-probes-SC-6.sh` | exit 0 | MET | `checks/spec-probes-SC-6.sh` exited 0 |
| SC-7 | WHEN `bin/probe-panel.sh run --stage plan --spec vault/plans/2026-09-22-1023-spec-reading-probes.arch.md --repo . --only spec-tables --only spec-naming` runs on this live repo, which has no real SQL, THE SYSTEM SHALL print a block of findings sourced only from this plan's own Data model table (none — the table above breaks no rule of its own), print one `probe-status: complete` line, and `./tests/run.sh tests/unit/probe.bats tests/unit/plan-probes.bats` SHALL pass every test | delivery | command | `checks/spec-probes-SC-7.sh` | exit 0 | MET | `checks/spec-probes-SC-7.sh` exited 0 |
| SC-8 | WHEN `commands/_shared/plan-probes.md`'s `## Auditors` section is measured by line count after this change THE SYSTEM SHALL show no net growth over its pre-change line count (a table plus one shared template covering three auditors, not three prose blocks) | functional | command | `checks/spec-probes-SC-8.sh` | exit 0 | MET | `checks/spec-probes-SC-8.sh` exited 0 |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| test_command | `./tests/run.sh tests/unit` | | |
| lint_command | `./bin/doc-lint.sh --changed` | | |
| delivery_command | `./bin/gate.sh verdict <plan> --run && ./bin/gate.sh all <plan> --phase close` | | |
| arch_profile | harness — `bin/gate.sh arch` reads `vault/plans/2026-09-22-1023-spec-reading-probes.arch.md` | | |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | a draft spec's Data model table is checked against the real schema before the plan is approved | ENFORCED — WI-1/WI-2 landed, `tests/unit/probe.bats` covers both checks (T-46–T-54), SC-7 recorded one real run on this plan's own spec | code + test + one real run |
| E-2 | `data-model` and `naming` findings reach a triage auditor exactly like `reuse` findings do | ENFORCED — WI-4/WI-5 landed, SC-4/SC-5/SC-6 hold (SC-4's grader checks the literal reads/question content, not just presence) | code + test |

## Verified current state

- `bin/plan-probes.sh` today declares `PLAN_PROBES="similar-symbols spec-symbols"` and
  `AUDITORS="reuse\tsimilar-symbols spec-symbols"` — checked by reading the file, 2026-09-22.
- `pp_budget`'s `aud` variable is a binary flag (`aud=1` if any `PLAN_PROBES` id has a block row), not a
  count — checked by reading `pp_budget`, 2026-09-22. It already undercounts the moment a second,
  independently-triggerable auditor exists, which this plan introduces.
- `pp_verify` takes exactly one optional `<auditor-rows-file>` argument — checked by reading `pp_verify`
  and `tests/unit/plan-probes.bats`, 2026-09-22.
- `tests/unit/plan-probes.bats` pins `probes` to `similar-symbols\nspec-symbols` and `auditors` to
  `reuse\tsimilar-symbols spec-symbols` — checked by reading the file, 2026-09-22.
- `arch-profiles/code.tsv`'s `Data model` section already has `pk-per-table`/`fk-index` rules, enforced
  by `bin/gate.sh arch` against the spec's own internal consistency, not against real code — checked by
  reading `commands/_shared/architecture-spec.md` and `arch-profiles/code.tsv`, 2026-09-22. This plan
  adds a different check: the spec against the repo's real SQL, the same relationship `spec-symbols` has
  to `arch-profiles/code.tsv`'s `reuse-decision` rule.
- `bin/rule-count.sh` prints `rule lines 181 (budget 173)` on `HEAD`, a pre-existing gap the master plan
  already records as not this plan's — checked by running it, 2026-09-22.

## Decisions

| decision | reason | record |
|----------|--------|--------|
| Extend `probes/sql-schema.sh` with `--check spec-tables\|spec-naming` rather than a new probe file | the master plan's own Open & deferred names this "the spec-reading part of `sql-*`"; the fact format and the three awk programs already exist and need no change, only a second fact source | local |
| A spec-fact extractor turns the Data model table's rows into `T`/`C`/`K` lines tagged with their origin (`spec` or `real`). `sql-dup-columns` and `sql-fk-index` gain one boolean, `spec_mode`, set only when `A_CHECK` is `spec-tables` — never for the plain `sql-dup-columns`/`sql-fk-index` checks. When `spec_mode` is unset, every keyed structure (`have`, `cols`/`ncol`, `nty`/`tys`) keys by `(table,column)` exactly as today, with no origin component and no output gating — the plain checks are structurally untouched, not byte-identical by accident (round 2, correctness-6). When `spec_mode` is set (`spec-tables` only), the same structures key by `(table,column,origin)` instead — so a spec table sharing a real table's name gets its own first-occurrence-per-origin counted for both the drift check and the `cols`/`ncol` overlap-set used by `dup-column-set` (round 2, architect-4 confirmed the original fix covered `have`/`nty` but not `cols`/`ncol`) — and a finding is emitted only when at least one contributing fact is spec-derived, so a spec with no Data model table produces nothing even when the real schema alone already trips these rules. `spec-naming` runs the unchanged `sql-naming` program over spec-origin facts only (WI-2) | round 1 (architect-1, correctness-1) confirmed the original "zero changes" design drops genuine drift on a same-named table and lets pre-existing real-SQL defects leak into `spec-tables` output when the spec itself contributes nothing; round 2 (correctness-6, architect-4) confirmed the round-1 fix left the plain-vs-spec_mode boundary and the `cols`/`ncol` structures unspecified — reuse stays the shape, `spec_mode` is the single flag that keeps the plain checks untouched while widening `spec-tables`' keys | trail round 1, round 2 |
| The `## Auditors` rewrite states each new auditor's exact `reads` set and one-sentence question inline in the plan, not left to implementation: `data-model` reads `spec-tables` only, `naming` reads `spec-naming` only — mirroring `reuse`, which reads exactly the two probes it triages | round 1 (architect-3, consumer-2) confirmed two sessions implementing WI-4 from the prior draft would invent different envelope text, since `reads` was ambiguous between "the two new probes" and "the two new probes plus the three pre-existing `sql-*` ones" | trail round 1 |
| Factor the Reuse-map heading-locate-and-column-split routine `probes/similar-symbols.sh` already has into a shared function, and call it from the new Data-model-table extractor too | round 1 (quality-3) confirmed the new extractor would otherwise be a second from-scratch implementation of markdown-table parsing `similar-symbols.sh` already does, including its CRLF-strip and escaped-pipe handling (round 1, correctness-5) | trail round 1 |
| `spec-tables`/`spec-naming` registry rows are `stack: any`, not `stack: sql`, gated by `detect: test -n "$PROBE_SPEC"` (identical to `spec-symbols`) | they must fire from the spec alone with no real SQL present — this repo is the proof case, per the master plan's own note that "the `sql-\*` probes ignore the spec and cannot fire in this repo, which has no SQL" | local |
| `commands/_shared/plan-probes.md`'s `## Auditors` section becomes one shared envelope template plus a three-row table (`reuse`, `data-model`, `naming`), replacing the current one-auditor prose block | three near-identical prose blocks is exactly the duplication the master plan's own deferred note flags for `lib/arch-check.sh`'s row-loop skeleton "when a later profile adds tables" (line 35); a table plus one template holds three auditors in fewer net lines than one auditor's current prose | local |
| `pp_budget`'s `aud` becomes a count of distinct triggered auditors (iterate the `AUDITORS` table, mark an auditor triggered when any of its listed probe ids has a block row, sum), not a 0/1 flag | PT-3 already states the intent ("counts the auditors itself from the rows in the block ... `auditors × 36000`"); the flag reads as a bug the moment a second auditor exists, which this plan adds two of | local |
| `pp_verify` takes zero or more `<rows-file>` arguments instead of exactly one | three auditors can each write `<out>/auditor-<id>.tsv`; step (g) of `03-propose-loop.md` must be able to pass every file that ran, not just `reuse`'s | local |

## Auditor content (data-model, naming)

Literal content for WI-4's table rows, so implementation invents nothing — mirrors `reuse`'s existing
row shape exactly:

| id | reads | question |
|----|-------|----------|
| data-model | spec-tables | Does the spec's Data model table describe a schema that matches, or safely extends, the repo's real SQL — or does a row conflict with what already exists? |
| naming | spec-naming | Does the spec's Data model table use names that fit this repo's snake_case and glossary conventions, or does a row need renaming before it becomes real SQL? |

## Scope & non-goals

Covers: `spec-tables`, `spec-naming`, the `data-model` and `naming` auditors, the registry rows, the
budget/verify changes those auditors require, and tests/fixtures for all of it.

Does not cover: `arch-profiles/code.tsv`'s `pk-per-table`/`fk-index` rules (a different, already-shipped
mechanism); the S9 stack-pack `stack_packs` gating (already shipped, unaffected — `spec-tables`/
`spec-naming` are `stack: any` so the gate never applies to them); reducing the pre-existing 181-vs-173
rule-count gap below its current size (SC-8 only bounds this plan's own contribution).

On a spec with no real SQL, `gate.sh arch`'s `fk-index` rule (spec-internal: does a `references` cell
have a non-empty `index` cell in the same row) and `spec-tables`' reused `sql-fk-index` logic (does a
`K`-kind fact exist for that column) can both fire on the same declared-but-unindexed FK — this is
accepted double-reporting, not a defect: `gate.sh arch` gates plan approval outright, `spec-tables`
only informs the `data-model` auditor's triage, and the two serve different readers (round 2,
architect-3).

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `probes/registry.tsv` rows `spec-tables`, `spec-naming` | `bin/probe.sh list\|run\|detect` and `bin/probe-panel.sh` iterate the registry to find a row by id | this session | `bin/probe.sh`, `bin/probe-panel.sh`, `commands/v-team/steps/03-propose-loop.md` step (b2) | a missing row makes `--only spec-tables` exit 2 ("id has no row at the stage"); a malformed row (wrong field count) makes the whole registry load exit 2 |
| `<out>/auditor-data-model.tsv`, `<out>/auditor-naming.tsv` | `bin/plan-probes.sh verify` reads them to print kept auditor lines in the approval block's `Open` field | the `data-model`/`naming` Explore auditors, spawned by step (b2) at tier `full` | `bin/plan-probes.sh verify`, then the operator via the approval gate's `Open` field | a missing file means that auditor did not run (tier below `full`, or its probe had no rows) and `verify` simply has nothing to keep from it — no error, no line |
| `bin/plan-probes.sh probes`/`auditors` output | `tests/unit/plan-probes.bats`'s pinned-string test reads it to prove the lists are stable | `bin/plan-probes.sh` | the bats test, and any session that adds a fourth probe or auditor later | a silently changed list breaks the pinned test with no message pointing at why; the test failure itself is the signal |
| `commands/_shared/plan-probes.md`'s `## Auditors` template + table (this plan's `## Auditor content`) | step (b2)/(c) of `03-propose-loop.md` reads it to build the literal envelope sent to each triggered auditor subagent | this session, WI-4 | the session running step (b2) when a `data-model`/`naming`-triggering probe row exists in the block | a wrong `reads` cell starts the wrong auditor for a probe's rows; a wrong `question` cell sends an auditor an envelope it cannot answer from, and its `.tsv` output then has nothing `verify` recognises |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| WI-1 | probes/sql-schema.sh | add a spec-fact extractor (Data model table → `T`/`C`/`K` lines matching `lib/probe-sql.awk`'s format, tagged by origin) using the shared table-parse function from WI-14 (CRLF-strip + escaped-pipe handling included); add the `spec_mode` boolean (set only for `A_CHECK=spec-tables`) to `sql-dup-columns`/`sql-fk-index`; under `spec_mode`, widen `have`/`cols`/`ncol`/`nty` from `(table,column)` to `(table,column,origin)` and gate output to rows with ≥1 spec-derived contributing fact; when unset, every structure and print site is unchanged | Edit | reuse the existing `facts`/`glossary` temp-file plumbing; the plain `sql-dup-columns`/`sql-fk-index` checks never set `spec_mode`, so their code path is untouched, not merely output-compatible | SC-2 | `tests/unit/probe.bats` new cases; TB-2, TB-3, TB-4, TB-10, TB-11, TB-13, TB-14, TB-16, TB-18, TB-19 | DONE |
| WI-2 | probes/sql-schema.sh | add a `spec-naming` check that filters the merged fact stream to spec-origin facts (the fact-population loop scans real SQL unconditionally, round 2 quality-1) then runs the existing `sql-naming` awk program over that subset only | Edit | same file as WI-1, one PR-sized change | SC-3 | `tests/unit/probe.bats` new cases; TB-15 | DONE |
| WI-14 | lib/probe-md-table.sh (new — `lib/probe-sql.sh` is documented SQL-specific, round 2 quality-5) | factor `probes/similar-symbols.sh`'s Reuse-map heading-locate-and-column-split awk into a shared function taking a section heading and a column-name list; call it from `similar-symbols.sh`'s existing Reuse-map parser and from WI-1's Data-model-table extractor | Edit + Edit | no behaviour change to the Reuse-map parser; same CRLF/escaped-pipe handling both callers need | SC-2, SC-3 | `tests/unit/probe.bats` (Reuse-map parsing cases still pass unchanged) | DONE |
| WI-3 | probes/registry.tsv | add the `spec-tables` and `spec-naming` rows (`any`, `plan`, `test -n "$PROBE_SPEC"`, native, `S`, `no`, `none`) | Edit | nine tab-separated fields, id+stage unique | SC-1 | `bin/probe.sh list` | DONE |
| WI-4 | commands/_shared/plan-probes.md | rewrite `## Auditors` to one shared envelope template plus this plan's `## Auditor content` table (`reuse`, `data-model`, `naming` rows, verbatim); update step 1's `--only` list to include `spec-tables`/`spec-naming`; update the Order section's step-4 `verify` line to name every `<out>/auditor-<id>.tsv` that ran, not only `reuse`'s; update the Cost section's probe/auditor references | Edit | keep the `reuse` row's `reads`/`question` cells matching its current prose exactly (verify by diff), so its behaviour does not change | SC-4, SC-8 | `bin/doc-lint.sh`, `tests/unit/plan-probes.bats`, `checks/spec-probes-SC-8.sh` | DONE |
| WI-5 | commands/_shared/probe-kit.md | add `spec-tables` and `spec-naming` rows to the Checks and rules table, reusing the existing rule ids | Edit | table row only, no prose change elsewhere | SC-1 | `bin/doc-lint.sh` | DONE |
| WI-6 | bin/plan-probes.sh | extend `PLAN_PROBES` to include `spec-tables spec-naming`; rewrite `AUDITORS` as three lines (`reuse`, `data-model`, `naming`, each with its probe ids); change `pp_budget`'s `aud` from a flag to a count over the auditor table | Edit | keep `pp_budget`'s public flags and exit codes unchanged | SC-5 | `tests/unit/plan-probes.bats` | DONE |
| WI-7 | bin/plan-probes.sh | change `pp_verify` to accept zero or more `<rows-file>` positional arguments instead of exactly one, applying the same keep rule to each; compare the rows-files it received against which auditors' probes have rows in `tier.txt`'s block, and print a `note:` line for any triggered auditor with no matching rows-file passed, instead of silently producing nothing for it | Edit | same function, same exit-code contract (0/1/2); a real dry run (round 2, consumer-1) proved extra positional args are silently dropped by bash today with zero error — the self-check is the fix, not just widening the signature | SC-6 | `tests/unit/plan-probes.bats`, TB-17 | DONE |
| WI-8 | commands/v-team/steps/03-propose-loop.md | step (b2)'s `probe-panel.sh run` line gains `--only spec-tables --only spec-naming`; step (g)'s `plan-probes.sh verify` line lists every `<out>/auditor-<id>.tsv` that ran, not just `reuse`'s | Edit | text-only change, no new section | SC-4, SC-7 | `bin/doc-lint.sh` | DONE |
| WI-9 | tests/fixtures/probe/spec-data-model-bad.arch.md | new harness-profile spec fixture whose Data model table trips `dup-column-set`, `column-drift` against a same-named real table (TB-10), `column-drift` against a differently-named real table sharing one column name (name-scoping, pinned per the Test design dossier), `fk-no-index`, `naming-snake-case` and `naming-glossary` against `tests/fixtures/probe/schema-clean.sql` | Write | mirror `schema-bad.sql`'s one-defect-per-rule comment convention; include CRLF line endings and one escaped-pipe cell to exercise WI-14's shared parser (TB-12) | SC-2, SC-3 | `tests/unit/probe.bats` | DONE |
| WI-10 | tests/fixtures/probe/spec-data-model-clean.arch.md | new harness-profile spec fixture whose Data model table breaks nothing | Write | mirror `schema-clean.sql` | SC-2, SC-3 | `tests/unit/probe.bats` | DONE |
| WI-15 | tests/fixtures/probe/spec-no-data-model.arch.md | new harness-profile spec fixture with `n/a: no data model in this change` for `## Data model`, paired with a real `schema.sql` fixture that already trips `sql-dup-columns` on its own | Write | proves `spec-tables` prints nothing when the spec contributes zero facts, even though the real schema alone would trip the same rule under `sql-dup-columns` | SC-2 | `tests/unit/probe.bats` (TB-11) | DONE |
| WI-11 | tests/unit/probe.bats | add `spec-tables`/`spec-naming` cases against the two new fixtures, covering both the spec-only clean run and the spec-vs-real-schema-conflict run | Edit | follow the existing sql-schema.bats case shape | SC-2, SC-3 | `./tests/run.sh tests/unit/probe.bats` | DONE |
| WI-12 | tests/unit/plan-probes.bats | update the pinned `probes`/`auditors` strings; add a budget case with two triggered auditors proving the projected cost scales by count; add a verify case with three rows files | Edit | keep existing T-numbered cases intact, append new ones | SC-5, SC-6 | `./tests/run.sh tests/unit/plan-probes.bats` | DONE |
| WI-13 | checks/spec-probes-SC-1.sh … checks/spec-probes-SC-8.sh | eight grader scripts, one per Success-criteria row | Write | follow the `checks/plan-probe-SC-*.sh` shape | SC-1–SC-8 | `bin/gate.sh verdict <plan> --run` | DONE |

## Rollback

Every changed file is additive or a small, isolated edit (a new check branch, two registry rows, a
rewritten but equivalent Auditors section, a widened function signature, a dedup-key widening TB-13
proves is a no-op on real-SQL-only input). `git revert` the commit; no migration, no data written
anywhere, no other session depends on `spec-tables`/`spec-naming` existing yet (S9 is done and does not
read them; nothing else names them). Reverting drops the two probe ids and `probe.sh list` simply stops
listing them; `similar-symbols.sh`'s Reuse-map parsing (WI-14) reverts to its own inline copy with no
behaviour change (TB-12 pins the two callers identical before the revert).

## Test plan

Harness: `./tests/run.sh tests/unit/probe.bats tests/unit/plan-probes.bats`, native bats-core in the
project's Docker container (per this repo's testing convention).

- unit — `probes/sql-schema.sh --check spec-tables`: clean fixture → exit 0, no rows. Bad fixture →
  exactly one row of each of `dup-column-set`, `column-drift`, `fk-no-index`.
- unit — `probes/sql-schema.sh --check spec-naming`: clean fixture → exit 0. Bad fixture → one
  `naming-snake-case`, one `naming-glossary`.
- unit — `probes/sql-schema.sh --check spec-tables` with no `--spec` → exit 0, no rows (mirrors
  `spec-symbols`'s `[ -n "$A_SPEC" ] || exit 0`).
- unit — `pp_budget` with a block holding one `spec-tables` row and one `similar-symbols` row →
  projects `auditors=2` worth of cost, not 1.
- unit — `pp_verify` with three rows files, one holding a line that is not a block row → that line is
  dropped and counted, the other two files' valid lines are kept.
- feature — `bin/probe.sh list` after the registry change lists both new ids as `ok`.
- delivery — SC-7: the stage runs on this repo's own spec end to end.

## Test design dossier

Decision table — `spec-tables` check outcome by input shape:

| spec has Data model rows | real SQL files present | rows overlap/drift/lack an index | expected |
|---|---|---|---|
| no | any | n/a | exit 0, no rows (mirrors `spec-symbols` on a spec with no Reuse map: nothing to check) |
| yes | no | spec rows only, no drift within the spec | exit 0, no rows |
| yes | no | two spec tables share ≥80% of columns | one `dup-column-set` row |
| yes | yes | a spec column name matches a real column with a different type | one `column-drift` row |
| yes | yes | a spec FK column has no spec or real index on it | one `fk-no-index` row |
| yes | yes | a spec table exactly matches a real table (no new columns) | no `dup-column-set` row — same-named tables from any origin merge into one table entry before the overlap check ever compares two entries, same as real-SQL `sql-dup-columns` today (round 2, correctness-1 corrected the original dossier's stated reason) |
| yes | yes | a spec table shares its **name** with a real table, and one spec column's type differs from that real column | one `column-drift` row (round-1 fix: the dedup gate no longer drops the second origin's declaration) |
| yes | yes | a spec column's **name** matches a real column in an unrelated, differently-named table | one `column-drift` row — name-scoped, not table-scoped, matching real-SQL `sql-dup-columns`'s existing behaviour (round-1, correctness-2; explicitly accepted, not a bug) |
| no (n/a) | yes, and the real schema alone already trips `sql-dup-columns` | n/a | exit 0, no `spec-tables` rows — a finding requires ≥1 spec-derived contributing fact (round-1 fix for correctness-1) |

Fault hypothesis: the spec-fact extractor mis-assigns a Data model table's declaration line (used as
`decl` for every column, since a spec table has no separate ALTER statement) — a wrong line number would
make findings cite the wrong row of the markdown table. Metamorphic relation: reordering the Data model
table's rows must not change which rules fire, only which line each finding cites.

Boundary: a Data model table with exactly one row (one table, one column, no key) must not crash the
awk programs that assume at least a PK row exists elsewhere in the fact stream — `sql-fk-index`'s `END`
block already handles zero-FK inputs (empty loop), so this is a property to hold, not new logic to add.

Round-1 addition: the widened dedup gate (keep both origins of a same `(table,column)` pair) must not
regress the existing real-SQL-only behaviour of `sql-dup-columns`/`sql-fk-index` when `spec-tables` never
runs — those two registry rows are untouched (WI-3's scope), but WI-1 edits the same awk programs they
call, so a real-SQL-only run (no `--spec`) must produce byte-identical output before and after WI-1.

Round-2 additions:
- Fact order: spec facts are appended to the merged stream **after** real-SQL facts. A `dup-column-set`/
  `column-drift` row comparing a spec table against a real table must cite the spec's file — WI-1 must
  verify this holds structurally (the awk's citation follows insertion order, not an explicit "prefer
  spec" rule), not merely as an accident of append order (round 2, correctness-2).
- `spec-tables` suppresses `id-column-no-fk` (severity `info`) — a heuristic meaningful for committed
  real SQL, noisy on an in-progress spec whose `key`/`references` cells may legitimately be filled in
  later (round 2, correctness-3). `fk-no-index` (severity `error`) is unaffected.
- `spec-naming` filters the merged fact stream to spec-origin facts before running the naming awk — the
  existing fact-population loop in `probes/sql-schema.sh` scans real SQL unconditionally, so without an
  explicit filter `spec-naming` would re-report a real-only table's naming defects under a second probe
  id, duplicating `sql-naming`'s job (round 2, quality-1).

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| TB-1 | decision table row 1 | unit | probes/sql-schema.sh | a spec with no Data model table produces no spec-tables/spec-naming rows | must | implement |
| TB-2 | decision table row 3 | unit | probes/sql-schema.sh | two spec tables sharing most columns produce dup-column-set | must | implement |
| TB-3 | decision table row 4 | unit | probes/sql-schema.sh | a spec column typed differently from a real column produces column-drift | must | implement |
| TB-4 | decision table row 5 | unit | probes/sql-schema.sh | a spec FK column with no index produces fk-no-index | must | implement |
| TB-5 | fault hypothesis | unit | probes/sql-schema.sh | reordered Data model rows change only the cited line, not which rules fire | should | implement |
| TB-6 | boundary | unit | probes/sql-schema.sh | a one-row Data model table does not crash either check | should | implement |
| TB-7 | SC-5 | unit | bin/plan-probes.sh | budget counts two distinct triggered auditors, not one | must | implement |
| TB-8 | SC-6 | unit | bin/plan-probes.sh | verify keeps valid lines from each of three rows files independently | must | implement |
| TB-9 | SC-7 | delivery | (live repo) | the stage runs end to end on this plan's own spec with zero real SQL | must | implement |
| TB-10 | round-1 architect-1 | unit | probes/sql-schema.sh | a spec table sharing a real table's name still produces column-drift (dedup-key widening didn't drop it) | must | implement |
| TB-11 | round-1 correctness-1 | unit | probes/sql-schema.sh | a spec with no Data model table produces no spec-tables rows even when the real schema alone already trips sql-dup-columns | must | implement |
| TB-12 | round-1 quality-3, correctness-5 | unit | probes/sql-schema.sh, probes/similar-symbols.sh | the shared table-parse function (WI-14) handles CRLF and an escaped-pipe cell identically for both callers | should | implement |
| TB-13 | round-1 architect-1 | unit | probes/sql-schema.sh | `sql-dup-columns`/`sql-fk-index` run with no `--spec` produce byte-identical output before and after WI-1's dedup-key widening | must | implement |
| TB-14 | round-2 correctness-2 | unit | probes/sql-schema.sh | a dup-column-set/column-drift row comparing a spec table against a real table cites the spec's file, not the real file | must | implement |
| TB-15 | round-2 quality-1 | unit | probes/sql-schema.sh | spec-naming run in a repo with real SQL present reports nothing for the real-only tables | must | implement |
| TB-16 | round-2 correctness-3 | unit | probes/sql-schema.sh | a spec `_id` column with no declared key/references produces no id-column-no-fk row under spec-tables | must | implement |
| TB-17 | round-2 consumer-1 | unit | bin/plan-probes.sh | `pp_verify` prints a note when a triggered auditor's rows-file is missing from its arguments, instead of silently producing nothing | must | implement |
| TB-18 | round-2 correctness-6 | unit | probes/sql-schema.sh | `--check sql-dup-columns`/`--check sql-fk-index` with no `--spec` against `schema-bad.sql` still produce their existing rows after WI-1 lands (proves `spec_mode` truly gates only the `spec-tables` path) | must | implement |
| TB-19 | round-2 architect-4 | unit | probes/sql-schema.sh | a spec table sharing a real table's name does not have its columns merged into that real table's `cols`/`ncol` set for `dup-column-set`'s overlap check against an unrelated third table | must | implement |
| TB-20 | diff-review round-1 correctness-r1 | unit | probes/sql-schema.sh | a spec table declaring the same column twice fires `dup-column-in-table` (the spec extractor gives every column of one table the same `decl`, mirroring a real `CREATE TABLE`) | must | implement |
| TB-21 | diff-review round-1 correctness-r2 | unit | probes/sql-schema.sh | a spec table that exactly re-declares a same-named real table produces no `dup-column-set` false positive; the same pair with one drifted column still produces `column-drift`, now disclosing origin per entry (correctness-r3) | must | implement |

## Refs

- `commands/_shared/plan-probes.md` — the stage this plan extends; PT-1 and PT-5 there already name this
  work as S11's.
- `vault/plans/2026-09-21-1800-plan-time-probes.md` — S5, the session that shipped the stage and the
  `reuse` auditor this plan's auditors mirror.
- `vault/plans/2026-09-21-0900-architecture-first-planning.md#S11` — the master-plan row this session
  closes.
- `probes/similar-symbols.sh` — the `spec-symbols` precedent this plan's `spec-tables`/`spec-naming`
  follow.
- `2026-09-22-1023-spec-reading-probes.trail.md` — process record.
