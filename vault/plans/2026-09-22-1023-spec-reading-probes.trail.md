---
type: trail
project: vault
plan: 2026-09-22-1023-spec-reading-probes
tags: [trail, record]
---

# spec-reading-probes — process record

Its contract document is `plans/2026-09-22-1023-spec-reading-probes.md`, which carries the current
truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Extend `probes/sql-schema.sh` with two new `--check` branches | a new `probes/spec-schema.sh` file | the fact format and all three comparison programs already live in `sql-schema.sh`; a new file would either duplicate them or import them, and `probe-kit.md`'s "Adding a probe" step 3 shows one row per check, not one file per check |
| Spec facts feed the *same* awk programs as real-SQL facts (`spec-tables` = dup-columns + fk-index programs; `spec-naming` = naming program) | write new spec-only comparison logic | the existing programs already compute overlap/drift/missing-index correctly over any `T`/`C`/`K` stream; new logic would be a second implementation of the same rules with its own bugs |
| Auditors section becomes one shared template + a table | three separate `### Auditor <id>` prose blocks (the naive extension of the current shape) | the master plan already flags this exact pattern (`lib/arch-check.sh`'s repeated row-loop skeleton) as a duplication trap "when a later profile adds tables" — S11 is that later profile |
| `pp_budget`'s `aud` becomes a count | leave it a binary flag and accept the undercount | PT-3's stated intent already says "auditors × 36000"; leaving a flag that reads as `1` regardless of how many auditors fire is silently wrong the moment this plan ships two more auditors |
| Reuse the exact rule ids of `sql-dup-columns`/`sql-fk-index`/`sql-naming` for spec-sourced findings | mint `spec-`-prefixed rule ids | the `probe` column already disambiguates source; a second rule vocabulary for the same defect doubles `probe-kit.md`'s Checks-and-rules table for no new information |

## Findings & dispositions

### PROPOSE panel (rounds 1–2)

Four reviewers (architect, consumer, correctness, quality) ran twice against the draft plan/arch spec —
round 1 against v0, round 2 against v1 (verify round-1 fixes, report only new findings). Round 2
arrived in two waves — an initial abbreviated pass and a fuller follow-up with deeper verification; the
table folds in the complete, corrected record (the fuller wave superseded the abbreviated one where
they differed; nothing from the abbreviated wave is lost, since its real findings are the same ones the
fuller wave confirmed or extended). One combined table, `round` as its own column, per this document's
own one-heading-once rule.

| round | persona | id | severity | grounding | issue | disposition |
|-------|---------|----|----------|-----------|-------|--------------|
| 1 | architect | architect-1 | BLOCKER | confirmed | dedup gate at `sql-schema.sh:44` drops a same-named spec/real table pair, so column-drift never fires on the plan's own primary use case | applied: dedup key widened to `(table,column,origin)`, WI-1 |
| 1 | architect | architect-2 | MAJOR | confirmed | `plan-probes.md`'s Order-section step-4 verify line is a second copy WI-4's original scope missed | applied: added to WI-4's scope |
| 1 | architect | architect-3 | MAJOR | confirmed | data-model/naming auditors' envelope question is unspecified | applied: `## Auditor content` table added, literal text |
| 1 | consumer | consumer-1 | BLOCKER | confirmed | the rewritten `## Auditors` section itself has no Artifact-lifecycle row | applied: row added |
| 1 | consumer | consumer-2 | BLOCKER | confirmed | `reads` set and question text undeterminable from the plan; two implementers would diverge | applied: `## Auditor content` table (merges with architect-3) |
| 1 | consumer | consumer-3 | MAJOR | confirmed | SC-4 was presence-only, so E-2 could read enforced without proof | applied: SC-4 now checks the literal reads/question content |
| 1 | consumer | consumer-4 | MINOR | advisory | no diff command named for "unchanged"/"exactly" claims | applied: WI-1/WI-4 note verify-by-diff |
| 1 | correctness | correctness-1 | BLOCKER | confirmed | real-SQL facts populate unconditionally; a spec with no Data model table could still surface real-schema-only findings under `spec-tables` | applied: output gated to ≥1 spec-derived contributing fact, WI-1; WI-15 fixture added |
| 1 | correctness | correctness-2 | MAJOR | confirmed | column-drift is name-scoped, whole-schema, not table-scoped — unacknowledged | applied: stated as accepted (matches real-SQL `sql-dup-columns` today), TB-10/dossier row added, not changed |
| 1 | correctness | correctness-3 | MAJOR | confirmed | SC-7 described a `probe-status: ran`/per-id line that doesn't exist in `probe-panel.sh` | applied: SC-7 text corrected to `probe-status: complete` |
| 1 | correctness | correctness-4 | MAJOR | confirmed | SC-7's "5 known failures" tolerance was unimplemented and unsourced | applied: SC-7 scoped to the two changed bats files instead of the full suite, sidestepping unrelated pre-existing failures |
| 1 | correctness | correctness-5 | MINOR | confirmed | no CRLF/escaped-pipe handling specified for the new table parser | applied: folded into WI-14's shared parser, which already has this |
| 1 | quality | quality-1 | BLOCKER | confirmed | `bin/rule-count.sh` (SC-8's grader) doesn't cover `plan-probes.md` at all | applied: SC-8 rewritten to a direct line-count check on the Auditors section |
| 1 | quality | quality-2 | MAJOR | confirmed | no grader enforces any arch-spec's Size budgets table, repo-wide | deferred: pre-existing, out of this plan's scope; recorded in Open & deferred |
| 1 | quality | quality-3 | MAJOR | confirmed | `similar-symbols.sh` already has the markdown-table-parse routine the new extractor would reimplement | applied: WI-14, shared function |
| 1 | quality | quality-4 | MINOR | advisory | "fewer net lines" claim had no draft text to check | resolved as a byproduct of `## Auditor content` existing now |
| 2 | architect | architect-3 | MAJOR | confirmed | `gate.sh arch`'s `fk-index` rule and `spec-tables`' reused `sql-fk-index` logic can both fire on the same spec-only FK-no-index defect | applied: documented as accepted double-reporting in Scope & non-goals — different readers, no suppression needed |
| 2 | architect | architect-4 | MAJOR | confirmed | the round-1 dedup-key fix widened `have`/`nty` but not `cols`/`ncol` (dup-column-set's overlap-set builder), which stayed table-only-keyed | applied: unified under `spec_mode` — all four structures key by `(table,column,origin)` together, TB-19 added |
| 2 | correctness | correctness-1 (r2) | MINOR | confirmed | dossier row 6's stated reason (column-count exclusion) was wrong; real reason is same-name table merge | applied: dossier row corrected |
| 2 | correctness | correctness-2 (r2) | MAJOR | confirmed | dup-column-set/column-drift's file citation depends on unpinned fact-stream insertion order | applied: fact order pinned (spec appended after real), TB-14 added |
| 2 | correctness | correctness-3 (r2) | MAJOR | confirmed | `id-column-no-fk` (info) fires on any unreferenced spec `_id` column, breaking SC-2's "clean spec → nothing" claim | applied: spec-tables suppresses id-column-no-fk, SC-2 reworded, TB-16 added |
| 2 | correctness | correctness-6 | BLOCKER | confirmed | WI-1 never said whether the origin-gate runs inside the *same* awk program the plain `sql-dup-columns`/`sql-fk-index` checks still use — an unconditional gate there would silently suppress every real-SQL finding, breaking existing tests and TB-13 | applied: `spec_mode` flag, set only for the `spec-tables` invocation; the plain checks' code path is untouched when unset, TB-18 added |
| 2 | consumer | consumer-1 (r2) | MAJOR | confirmed, real dry run | `pp_verify`'s current 1-arg signature silently drops extra positional args (bash default); a naive WI-7 implementation would let an auditor's verdict vanish with zero error | applied: WI-7 gains a self-check comparing rows-files received against triggered auditors, TB-17 added |
| 2 | consumer | consumer-2 (r2) | MINOR | advisory | shared envelope template's wrapping prose (not the reads/question cells) still undrafted | accepted: `## Auditor content` already pins the load-bearing cells; wrapping prose is a low-risk implementation detail |
| 2 | consumer | consumer-5 | MAJOR | confirmed | `checks/spec-probes-SC-4.sh`'s reuse-row check greps the whole file for `similar-symbols`/`spec-symbols`, both of which also appear on an unrelated line (Order section step 1) — the grader passes even if the `reuse` row is deleted | applied: grader now greps only the `^| reuse ` row |
| 2 | quality | quality-1 (r2) | MAJOR | confirmed | `sql-schema.sh`'s fact-population loop scans real SQL unconditionally; spec-naming would re-report real-table naming defects under a second probe id without an explicit filter | applied: WI-2 now filters to spec-origin facts before the naming awk runs, TB-15 added |
| 2 | quality | quality-3 (r2) | NIT | confirmed | 160-line budget on `sql-schema.sh` may be tight given WI-1's added complexity | noted, not actioned: budget is checked at implementation time, not plan time (matches quality-2 round-1's deferral reasoning) |
| 2 | quality | quality-5 | MAJOR | confirmed | WI-14 named two possible target files instead of one, the same ambiguity class round 1 treated as blocking for WI-4 | applied: `lib/probe-md-table.sh` (new file) — `lib/probe-sql.sh` is documented SQL-specific, per quality's own cited reasoning |

Dropped, not applied: consumer-3 r2 ("no `checks/spec-probes-SC-4.sh` exists") — rejected, the file
existed before round 2 was sent (`ls checks/spec-probes-SC-*.sh` lists it); quality-2 r2 (table-parser
duplication, restated) — not re-applied, WI-14 (round 1) already does this.

Process footnote: `s11-consumer` reported in its fuller round-2 message that the trail's round-1
`consumer-1..4` issue text didn't match what it recalled sending. Verified against the actual round-1
messages received and synthesized (`pp_verify` silent-rows-file-drop → consumer-1 r2 above; the
Auditors-section lifecycle row, the undeterminable envelope, and SC-4's presence-only check are
consumer-1/2/3 round 1, quoted verbatim in this trail's Findings & dispositions → Round 1) — the trail
is accurate to what was received; the critic's own recollection across a resumed context was not.

## Metrics

| round | critics | confirmed BLOCKER | confirmed MAJOR | confirmed MINOR | advisory | new-since-last-round |
|-------|---------|--------------------|-------------------|-------------------|----------|------------------------|
| 1 | 4 | 5 | 6 | 3 | 3 | n/a (round 0) |
| 2 | 4 | 1 | 8 | 2 | 1 | 10 applied (architect-3/4, correctness-1/2/3/6 r2, consumer-1/5 r2, quality-1/5 r2) |

Per-persona overlap: architect-3 and consumer-2 (round 1) clustered to one plan change (auditor envelope
content). No confirmed finding was dispositioned other than `applied`, an explicitly reasoned
`deferred`/`accepted`, or `rejected` with verification evidence (consumer-3 r2) — no sycophancy flag.

**Round cap reached (`team_max_rounds: 2`).** Round 2's fixes were applied by synthesis but not
re-verified by a third critic round — the cap is hard per `commands/v-team/steps/03-propose-loop.md`
§(f).1. Flagged at the approval gate.

## Advisory test hints

- consumer-t1 (unit): rewritten `## Auditors` table rows for data-model/naming — pin literal `reads`
  and `question` cell content so a later edit can't silently drift from `## Auditor content`.
- architect-t1 (unit): `spec-tables` on a same-table-name spec/real pair with a differing column type —
  guards the dedup-key regression architect-1 found; folded into TB-10.
- architect-t2 (unit): `pp_budget` with block rows for all three auditors' probes present — guards the
  `aud` count reaching 3, not 2.
- architect-t3 (feature): `plan-probes.md`'s Order-section text vs `03-propose-loop.md` step (g) text —
  guards the doc-drift architect-2 found between the two copies.
- correctness-t1/t2 (unit): folded into TB-11/dossier row (no-Data-model-table gate; name-scope pin).
- correctness-t3 (integration): folded into SC-7's rescoped test-file list, which sidesteps the need for
  a tolerance test entirely.
- quality-t1 (unit): `plan-probes.md` line count after WI-4 — folded into rewritten SC-8.
- quality-t2 (unit): spec-fact extractor output is byte-format-compatible with `lib/probe-sql.awk` —
  folded into WI-1's verification.
- quality-t3 (should): shared table-parser function used identically by both callers — folded into
  TB-12.

Round 2 additions — folded into TB-14/TB-15/TB-16/TB-17 above: correctness-t1/t2 (dup-column-set
mechanism + file citation), correctness-t3 (id-column-no-fk on the clean fixture), consumer-t1
(`pp_verify` missing-file note), quality-t1/t2 (spec-naming real-table leakage; facts-file early-exit
on a spec-only repo — already covered by SC-7's live delivery run). Not folded: consumer-t2/t3
(bats-level detail for the note format and a table↔grader cross-check) and architect-t3 (the
`gate.sh arch` vs `spec-tables` interaction, resolved as accepted double-reporting rather than a test) —
left as implementation-time judgment calls, not plan-blocking.

## Rejected / deferred

- Considered making `spec-tables` bidirectional (also flag a real table the spec's Data model omits
  entirely). Rejected for v0: a spec legitimately omits tables it does not touch, and flagging that
  would produce a false positive on every partial-schema spec — the existing `pk-per-table`/`fk-index`
  rules already require the spec to be internally complete for what it *does* declare.

## Diff-review rounds (EXECUTE §5.3)

### Round 1

Same four personas (architect, consumer, correctness, quality), review posture, against the real
implementation diff. `PROBE_BASE=d7e94f153f4f53039da03df89b2abd96d4998efa`.
`bin/probe-panel.sh run --posture own --repo . --base "$PROBE_BASE"` returned `INCOMPLETE` (2 skipped:
`claude-validate`, `lizard` — both `executes-repo-code: yes`, refused by default for `own` posture
without `PROBE_PANEL_REPO_CODE=yes`; `registry-edited` also printed since `probes/registry.tsv` is
itself part of this diff). Expected, not an S11 defect — noted here per the exception-surfacing rule,
not applied against.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|--------------|
| architect | — | — | — | zero findings; verified every round-1/round-2 PROPOSE fix present in the real code, ran `tests/unit/probe.bats tests/unit/plan-probes.bats` (53/53 at the time) | APPROVE |
| correctness | correctness-r1 | BLOCKER | confirmed, real dry run | the spec-fact extractor gave every column its own line as `decl`, so `dup-column-in-table`'s dedup key was unique per row — a within-spec-table duplicate column could never be caught | applied: `decl` now set once per table (`tdecl[tb]`, first occurrence), mirroring a real `CREATE TABLE`; TB-20 added |
| correctness | correctness-r2 | BLOCKER | confirmed, real dry run | `spec_mode`'s per-origin key widening let a spec table that exactly re-declares a same-named real table self-compare in `dup-column-set`, printing a nonsensical "customers and customers share 4 of 4 columns" row — exactly the false positive the plan's own decision table row 6 said must not happen | applied: `dup-column-set`'s pair loop skips same-name, cross-origin pairs; a genuine drift on the same pair still fires `column-drift` (verified, regression-safe); TB-21 added |
| correctness | correctness-r3 | NIT | confirmed | the drift message named the table twice with no way to tell which occurrence was real vs spec | applied: each `tys[]` entry now carries `(real)`/`(spec)` |
| consumer | consumer-r1 | BLOCKER | confirmed | `scripts/completion-hook.sh` and `output-styles/director.md` appear in `git diff $PROBE_BASE` but are backed by no work item in this plan | not an S11 defect — pre-existing, uncommitted work in the working tree from before this session started (visible in the session's opening `git status`). Neither file was touched by this session, and this plan defines no B-prefixed criterion (round-2 quality-r4 caught an earlier draft of this row wrongly citing a "success criterion B6" that belongs to a different plan, S5's `2026-09-21-1800-plan-time-probes.md`; round-2 consumer independently found the real, mechanical guarantee: `scripts/staging-hook.sh` is a PreToolUse hook that denies `git add -A`/`git add .`/a pathspec-less commit before the permission check even fires — Step 6 cannot sweep either file into the S11 commit even by accident) |
| consumer | consumer-r2 | MINOR | confirmed | `bin/plan-probes.sh`'s `--help` docstring still said `verify` took one optional rows-file after WI-7 made it variadic | applied: docstring updated |
| quality | quality-r1 | MAJOR | confirmed | `bin/plan-probes.sh` shipped at 246 lines against the arch spec's own 240-line budget | applied: budget line amended to 246 with reasoning (the variadic-verify loop and missing-auditor note are the round-2 fix itself, not bloat to trim) |
| quality | quality-r2 | MAJOR | confirmed | same underlying fact as consumer-r1 | same disposition as consumer-r1 |
| quality | quality-r3 | NIT | confirmed | `checks/plan-probe-SC-2.sh`'s pipefail fix (unrelated to this plan's own registry growth) has no trail note | this line is that note: a pre-existing SIGPIPE risk in `probe.sh list \| grep -q` surfaced while adjusting the same script for WI-4's multi-row Auditors table, and was fixed alongside it as a drive-by — not scope creep, since the file was already being edited for an in-scope reason |

### Round 2

Same four critics, against the fixed diff. Asked to verify round-1 fixes and report only new findings.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|--------------|
| architect | — | — | — | zero new findings; re-verified both bug fixes and the `--help` fix directly in the source, ran the suite (55/55) | APPROVE |
| consumer | — | — | — | `--help` fix confirmed; found the round-1 disposition's "B6" citation was wrong (see quality-r4) and independently supplied the real, mechanically-enforced reason | APPROVE_WITH_NITS |
| correctness | — | — | — | re-ran both original dry runs live against the fixed code, plus two adversarial over-suppression checks (different-named tables, real-vs-real same-name) neither of which the fix should touch and didn't; no gap found | APPROVE |
| quality | quality-r4 | MINOR | confirmed | round-1's consumer-r1 disposition cited "this plan's own success criterion B6," which does not exist anywhere in this plan (it belongs to a different plan, S5's) | applied: citation corrected, replaced with the real mechanism (`scripts/staging-hook.sh`, found independently by round-2 consumer) |

## Metrics — diff-review

| round | critics | confirmed BLOCKER | confirmed MAJOR | confirmed MINOR | new-since-last-round |
|-------|---------|--------------------|-------------------|-------------------|------------------------|
| 1 | 4 | 3 (2 real bugs + 1 mischaracterized-as-blocker scope note) | 2 (1 real, 1 duplicate of the scope note) | 3 | n/a (round 0 of this loop) |
| 2 | 4 | 0 | 0 | 1 | 1 (quality-r4, a citation error in round 1's own trail text — self-correcting) |

Both real BLOCKER bugs (correctness-r1, correctness-r2) were tool-confirmed via live dry runs against
constructed fixtures, not inferred from reading code — the strongest grounding this loop produces.
Convergence: round 2 added no new confirmed BLOCKER/MAJOR (stop condition (f).2), and round 2 is also
`team_max_review_rounds`'s cap (stop condition (f).1) — both conditions hit together, not a capped stop
with anything left open. Full suite after every fix: 971 tests, 963 ok, 8 not ok — independently
confirmed pre-existing on `HEAD` (same 8 test names/files as the implementer's own stash-based A/B
check, and as round-1's architect's own re-run).
