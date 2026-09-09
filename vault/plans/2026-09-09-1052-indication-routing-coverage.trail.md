---
type: trail
project: vault
plan: 2026-09-09-1052-indication-routing-coverage
tags: [trail, record]
---

# 2026-09-09-1052-indication-routing-coverage — process record

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Read the existing `Applies-to`/`scope` cell | Add a dedicated `Routes-to` column and require projects to fill it | It routes nothing on day one in all 14 project indexes, and the plan would ship a column with no data |
| Read the cell without changing it | Rewrite project cells into globs so routing is exact | A glob-shaped cell fails `bin/doc-lint.sh` INDEX3 wherever a project declares `indication_scopes`; the plan's own doc-lint criterion would have contradicted its own work item |
| Three token classes, per-row bucketing | Per-token bucketing | A mixed glob-plus-prose row lands in two buckets and the sum invariant breaks |
| rc 1 only on a routed rule with no anchored verdict | rc 1 on any unroutable row | givore's api index holds 31 permanently unroutable rows, so the gate would fire on 100% of that repo's reviews; `vault/check-budget.md` deletes a check above one wrong firing in ten, and an operator clearing it unread clears the file-coverage gate the same way |
| `n/a` carries the rule's trigger clause, not a code anchor | `n/a` carries a code anchor like the other verdicts | A dry run showed `n/a` plus any line from the hunk is conformant for every routed rule, scoring full coverage — the defect the plan exists to fix, one level up |
| Build `cr_anchor_check` as a shared verifier | Keep the anchor rule as prose in the step file | No code verifies an anchor today; `cr_coverage` switches on the evidence field alone, so `FILES_EXAMINED` has the same hole |
| Defer `/v-work` routing | Ship it in this plan | `commands/v-work/steps/01-analyze.md` emits no path list and the plan is authored one step after LOAD CONTEXT, so the router would have had no input and its output line no reader |

## Findings & dispositions

### Round 1 — design panel (consumer · skeptic · correctness), generic fallback pack

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| consumer | 1 | BLOCKER | confirmed | `holds`/`breaks`/`n/a` never defined; an `n/a` row plus any hunk line scores full coverage | applied — verdict vocabulary defined in W-5, `n/a` counted separately, E-5 added |
| consumer | 2 | BLOCKER | confirmed | "assignment by matched path" contradicts `03-review.md:25`, which states per-file assignment is unavailable | applied — W-7 builds an explicit slug-to-critic map and sends an unowned path's rules to the architect seat |
| consumer | 3 | MAJOR | confirmed | the audit script had no caller; `/v-capture`'s `scan-ind` takes a different input | applied — the operator is named as the reader; no `/v-capture` seam claimed |
| consumer | 4 | MAJOR | confirmed | the rule anchor had no referent and no verifier | applied — `cr_anchor_check` (W-3) |
| consumer | 5 | MAJOR | confirmed | `RULES_CHECKED` lands in the shared module but `/v-team`'s execute loop is handed no routed set | applied — `/v-team` named in Scope & non-goals as out of scope |
| consumer | 6 | MAJOR | confirmed | one artifact row described build-time CI, not receiver-time behaviour | applied — the rule-line row now states what the PR author sees |
| consumer | 7 | MAJOR | confirmed | SC-5 had no floor; both changed paths sat under `vault/` and 0 of 32 globs are rooted there | applied — SC-5 requires non-empty `unroutable` and `no-match` buckets against the real givore indexes |
| consumer | 8 | MINOR | confirmed | `n/a` had no rank in the merge | applied — W-4 pins `breaks` > `holds` > `n/a` and the anchorless-loses rule |
| skeptic | 1 | BLOCKER | confirmed | W-11's glob-shaped index cell fails `bin/doc-lint.sh` INDEX3 in any project declaring `indication_scopes` | applied — no project index cell is rewritten; the new row follows this repo's existing style |
| skeptic | 2 | BLOCKER | confirmed | the plan was designed against this repo's index, the only 100%-routable one in the estate; 132 of 302 rows elsewhere are unroutable | applied — the numbers are in Verified current state and the first two Open bullets; SC-5 measures the real indexes |
| skeptic | 3 | BLOCKER | confirmed | "nothing reads the column" is false — `bin/doc-lint.sh` INDEX3 and `02-gather.md` §2.4 rule 2 both read it | applied — the false bullet is deleted; the design composes with both consumers |
| skeptic | 4 | MAJOR | confirmed | rc 1 on `unroutable` fires on every givore review and costs the file-coverage gate its credibility | applied — Q-1 narrowed the gate |
| skeptic | 5 | MAJOR | confirmed | the `/v-work` work item was BOUND-UNREAD, not PROSE | applied — dropped to a deferred bullet with the reason |
| skeptic | 6 | MAJOR | confirmed | two edited files sit in an already-over rule budget, and `tests/unit/rule-count.bats` asserts the failing exit code | applied — SC-4 pins the count; T-14 fixes the test |
| skeptic | 7 | MAJOR | confirmed | SC-5 accepted every exit code the script can produce | applied — SC-5 rewritten with one accepted outcome per fixture |
| skeptic | 8 | MAJOR | confirmed | 48% of rows land in `no-match`, which nothing verdicts; cross-repo contract rules are structurally unreachable by path globs | applied — both Open bullets, with the counts; W-13 records it in check-budget |
| skeptic | 9 | MINOR | confirmed | SC-4's bare-token grep is the defect `enforced-not-just-stated` §5 describes | applied — SC-3 greps the fenced call plus the definition |
| skeptic | 10 | MINOR | confirmed | `gensub()` is unavailable; awk here is mawk 1.3.4 | applied — W-2 constraint |
| skeptic | 11 | MINOR | confirmed | the header is spelled three ways across 14 indexes | applied — W-2 locates the column by case-insensitive header match and exits 2 when absent |
| skeptic | 12 | MINOR | confirmed | five states, three summary slots | applied — the summary line carries four counts |
| skeptic | 13 | NIT | confirmed | a third `bin/rule-*.sh` measuring an unrelated thing | applied — renamed `bin/indication-route-audit.sh` |
| correctness | 1 | BLOCKER | confirmed | glob semantics unspecified; `commands/v-cr/**` matches 2 files or 0 depending on the translation | applied — W-2 pins the translation |
| correctness | 2 | BLOCKER | confirmed | comma-splitting shreds the brace group at `_index.md:14` | applied — W-2 expands brace groups first; T-2 uses the verbatim row |
| correctness | 3 | BLOCKER | confirmed | the escaped pipe at `_index.md:37` shifts the column | applied — W-2 takes `$(NF-1)`; T-3 uses the verbatim row |
| correctness | 4 | BLOCKER | confirmed | E-2 claimed parity with an anchor discipline no code executes | applied — `cr_anchor_check` built, E-3 added for the pre-existing `FILES_EXAMINED` hole |
| correctness | 5 | MAJOR | confirmed | the sum invariant fails under per-token accounting | applied — per-row bucketing stated in the dossier |
| correctness | 6 | MAJOR | confirmed | the merge is monotone upward, so one echoed `holds` ratchets coverage to 100% | applied — anchor verification gates the merge; anchorless `breaks` loses to anchored `holds` |
| correctness | 7 | MAJOR | confirmed | `vault/indications/plan-appetite-not-tasks.md` has no index row, so the denominator is undefined | applied — recorded in Verified current state |
| correctness | 8 | MINOR | confirmed | `templates/indication.md` teaches prose `Applies-to`, so the unroutable bucket is designed to grow | deferred — naming it out of scope keeps this plan from editing a template every project inherits; it belongs with the index-repair work |

### Round 2 — implementation review (library · scripts · contracts), against the diff

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| lib | 1 | BLOCKER | confirmed | a whitespace-only anchor was reported with an empty anchor field, so the rejection key never matched and one space defeated the gate | applied — `bad()` emits the anchor as written; regression test added |
| cmd | 1 | BLOCKER | confirmed | six `$CR_*` variables used and never defined by any step | applied — §2.4 and §3.6 establish each one the way §2.1 establishes `$CR_CHANGED_FILES` |
| cmd | 2 | BLOCKER | confirmed | `cr_anchor_check` never received the rule receipt, so no rule anchor was ever verified and the gate was permanently green | applied — the function is variadic and §3.6 passes both receipts; test asserts the two-receipt call |
| lib | 2 | MAJOR | confirmed | `cr_coverage` never consumed the bad-anchor set, so a fabricated `read` anchor was flagged and still counted examined | applied — optional fourth argument |
| lib | 3 | MAJOR | confirmed | the tab-in-path test asserted a prefix a truncating implementation also produces | applied — asserts the whole reassembled path |
| lib | 4 | MAJOR | confirmed | the contract grep pinned only the first argument of the `cr_anchor_check` call | applied — pins both receipts |
| cmd | 3 | MAJOR | confirmed | the out-of-assignment anchor rule rested on a path-to-critic map no step builds | applied — the claim is dropped; the step states what the tool actually decides |
| cmd | 4 | MAJOR | confirmed | the rule line omitted `n/a`, so an all-`n/a` review printed zeros and stayed green | applied — five buckets, first three sum to the routed count |
| cmd | 5 | MAJOR | confirmed | the check-budget number did not reproduce against the repo's own audit script | applied — 42 of 44, with the command |
| cmd | 6 | MAJOR | confirmed | "mandatory whenever the caller assigns rules" is undecidable for `/v-team` | applied — the callers are named instead |
| bin | 1 | MAJOR | confirmed | only one YAML spelling of `indication_scopes` parsed; a block list silently gave an empty scope set | applied — both spellings, with a delivery fixture for each |
| bin | 2 | MAJOR | confirmed | SC-5 could not see the surface channel at all | applied — fixture 4 exercises it in both spellings |
| bin | 3 | MAJOR | confirmed | SC-4 graded OK with a non-numeric pin and with a counter that exited nonzero | applied — the pin is validated and the counter's status is evidence |
| lib | 5 | MINOR | confirmed | `expand()` handled only the first brace group | applied |
| lib | 6 | MINOR | confirmed | an unterminated `{` swallowed every later token in the cell | applied — falls back to a depth-ignoring split |
| lib | 7 | MINOR | confirmed | `/^@@ /` missed a combined merge diff, rejecting every citation | applied — `/^@@+ /`, last new-file range |
| lib | 8 | MINOR | confirmed | `! grep` asserts only as a body's last statement | applied — `run grep` plus a status check |
| lib | 9 | MINOR | confirmed | the panel-schema test grepped bare tokens; `holds` occurs in the file's prose | applied — table-row greps plus function-definition pairs |
| cmd | 7 | MINOR | confirmed | `05-capture.md` gained no fields for the counts §2.4 says to record | applied — six fields added |
| cmd | 8 | MINOR | confirmed | nothing tells the operator to increment the new `fires` rows | applied — one line in `04-post.md` §4.1 |
| cmd | 9 | MINOR | confirmed | the rule line published a slug roster and index health to a public PR | applied — counts only on a fork/public target |
| lib | 10 | MINOR | confirmed | the index cell is broader than several rule bodies' own Applies-to | deferred — recorded in Verified current state; reconciling belongs to index repair |
| cmd | 10 | NIT | confirmed | one justification written in three files with two different numbers | applied — stated once in the indication, referenced twice |
| lib | 11 | NIT | confirmed | the monotonicity test had no lower bound | applied |
| lib | 12 | NIT | confirmed | a quoted token containing a tab garbles into a bogus slug | deferred — no fixture produces one outside a test file quoting `\t` literals |

## Metrics

Round 1: 3 critics, 30 findings, all `grounding: confirmed`, 9 BLOCKER.
Round 2: 3 reviewers over the diff, 25 findings, all `grounding: confirmed`, 3 BLOCKER, 23 applied
and 2 deferred with the reason recorded. New confirmed blockers in
round 1: 9. Findings dropped between rounds: none — one round ran, and the revision above answers
every finding rather than re-spawning the panel on a design the findings had already refuted. Persona
overlap: consumer-4 and correctness-4 are the same defect from two lenses; consumer-1 and
correctness-6 are the same defect at two stages.

## Advisory test hints

The panel proposed nine tests. Seven are reconciled into the plan's Test backlog as T-2, T-3, T-4,
T-6, T-7, T-8 and T-14. Two are not, and are recorded here rather than dropped:
- a `tests/unit/document-standard.bats` case asserting `bin/doc-lint.sh` returns 0 on an index holding
  both a glob-shaped routing cell and a declared `indication_scopes` vocabulary — it belongs to the
  index-repair work, since no cell is rewritten here;
- a case feeding the mistflare index, which is 0 of 6 routable, as the all-unroutable boundary — T-12
  covers the empty case and the boundary is already asserted by SC-5's givore fixtures.

## Rejected / deferred

- **A dedicated `Routes-to` column.** Clean semantics, no collision with INDEX3 or the surface filter,
  and it routes zero rules until 14 projects each edit an index. Killed by having no data on day one.
- **Rewriting project index cells to globs.** Killed by `bin/doc-lint.sh` INDEX3, which refuses a cell
  that is not a declared `indication_scopes` value.
- **Capping the number of rule bodies fetched.** Investigated and unnecessary: 37 routed rules against
  a real 130-row index cost about 17k tokens, roughly 8% of the ~200k review ceiling. The plan caps
  nothing deliberately.
- **A pre-mortem the panel wrote and the revision answers:** the gate fired on every givore review,
  the operator cleared it unread by the fourth run, and the file-coverage confirmation went the same
  way. Q-1's narrowed rc semantics exist because of it.
- **Shipping the `/v-work` router in this plan.** Live until the panel showed step 1 emits no path
  list; deferred rather than rejected, and it belongs at PROPOSE where the Work-items table has paths.
