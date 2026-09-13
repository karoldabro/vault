---
type: plan
project: vault
slug: proof-discipline
repos: [vault]
status: proposed
process_record: 2026-09-13-1355-proof-discipline.trail.md
session:
tags: [plan, epistemics, gates, personas]
---

# proof-discipline — plan

## Task

Make every load-bearing statement in a plan carry grounds a later reviewer can re-run and overturn,
and stop a session that cannot reach its own success criteria. Keywords: claim, grounds, warrant,
falsifier, refutation, gate, persona.

## Open & deferred

| item | state |
|------|-------|
| Nine blockers are open on the claim ledger. They are listed as OB-1 to OB-9 in `vault/plans/2026-09-13-1355-proof-discipline.trail.md`. Two review rounds added more blockers than they closed, and the heaviest is OB-1: a claim graded `C` costs one prose line and buys the same work items a resolving anchor buys, so the cheapest compliant plan proves nothing | open, blocks slice 2 |
| The `coverage` subcommand and the failed-session state shipped separately, under `vault/plans/2026-09-13-1447-coverage-and-failed-sessions.md`. What remains here is the claim ledger alone | open — this plan is not started |
| Forcing a checkable proof on every claim buys a measured accuracy cost. In the one setup where it was quantified, a prover trained against a verifier scored about 60% against an 80% correctness-only baseline on grade-school maths. That number is specific to that training setup, not a general rate, but the direction is real: plans drafted under this gate come out narrower and more conservative | open — stated, not mitigated |
| Five claims are graded `C` — unverified assumptions the operator can still correct. C-6: whether an agent skews its own search queries has no primary source. C-7: no second census of maintainer silence was found. C-8: RoB 2's only corroborating tool shares an author. C-10: one preprint, read at abstract level. C-11: the two adoption signals read one registry. Only C-5 carries independent corroboration | open — unverified |
| The `/v-team` read set is 175 rule lines against a budget of 173, at 150 prohibitions to 25 requirements against a 1:1 ceiling. W-4a deletes five re-statements to reach 170 and 145 | open, blocks W-4b |
| `bin/rule-count.sh --assert` stays at exit 1 after those deletions, because its 1:1 prohibition-to-requirement ceiling is missed by 120 lines. Closing that means rewriting 120 prohibitions across twelve files. SC-4 pins the three counts instead and this overrun is not closed here | open — standing overrun |
| `bin/rule-count.sh` counts twelve files. `personas/_shared/proof-auditor.md`, the new indication and both template sections are outside that corpus, so SC-4 budgets three work items and not the rest | open — unbudgeted by design |
| `claim_anchor_check` duplicates 16 lines of anchor parsing from `lib/cr-helpers.sh:452-467` | deferred — see D-4 |
| Building the methodology-designer command. Its design is settled in `vault/plans/2026-09-13-1355-v-method.brief.md` | deferred to a later session |

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Which slice ships this session | yes | `bin/rule-count.sh`; `vault/architecture/session-gates-unbuilt.md`; `git log --oneline -20` | open | |
| Q-2 | Which commands obey the discipline | no | `bin/rule-count.sh`; `vault/decisions/ADR-015-retier-lifecycle-lite-critic-fast-path.md` | answered | all four: `/v-team`, `/v-pm`, `/v-work`, `/v-cr` |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a claim's grounds do not resolve THE SYSTEM SHALL refuse the plan and name the claim | unit | command | `checks/proof-discipline-SC-1.sh` | exit 0 | | |
| SC-3 | WHEN the auditor seat is selected THE SYSTEM SHALL bind five named domains, a bound analyzer, and a rule ceding numbers to `business/data-evidence` | artifact | command | `checks/proof-discipline-SC-3.sh` | exit 0 | | |
| SC-4 | WHEN this change lands THE SYSTEM SHALL hold the counted corpus at or under 170 rule lines and 145 prohibitions, with requirements at or above 25 | unit | command | `checks/proof-discipline-SC-4.sh` | exit 0 | | |
| SC-5 | WHEN a step file states the falsification ratio THE SYSTEM SHALL carry a committed function computing it, invoked inside a code fence, with a planted case proven to fail | unit | command | `checks/proof-discipline-SC-5.sh` | exit 0 | | |
| SC-6 | WHEN the shipped gate runs against this plan THE SYSTEM SHALL exit 0, and exit exactly 1 naming the anchor on a copy whose C-3 anchor token is wrong | delivery | command | `checks/proof-discipline-SC-6.sh` | exit 0 | | |
| SC-7 | WHEN a work item rests on a refuted claim THE SYSTEM SHALL refuse, and WHEN it rests on a claim graded `C` THE SYSTEM SHALL require that claim in `## Open & deferred` | unit | command | `checks/proof-discipline-SC-7.sh` | exit 0 | | |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | The change does what the task asked | | |
| B2 | Tests covering the changed behaviour pass | | |
| B3 | Lint and any format check pass on the changed files | | |
| B4 | Every review finding is fixed or recorded | | |
| B5 | Documentation and vault docs that the change invalidates are updated | | |
| B6 | Nothing unrelated is in the commit | | |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| R-1 | A claim carries a `kind`, grounds, a warrant, a falsifier and five domain answers | OPEN | `bin/gate.sh claims`, refusing an empty cell |
| R-2 | A success criterion no work item covers exits 1; an unparseable table exits 2 | OPEN | `bin/gate.sh coverage` |
| R-3 | A refutation defeats grounds only when its own grounds resolve | OPEN | `bin/gate.sh claims`, refusing a `refuted` row whose `defeated by` cell holds no resolving grounds |
| R-4 | No reviewer audits a claim it asserted | PROSE | the dispatcher writes every row, but it writes some from a reviewer's own recommendation, and nothing excludes that reviewer from auditing it. W-4b must exclude a seat from the claims its round-1 recommendation supplied |
| R-5 | A claim with no falsifier logged is graded `C` and named in `## Open & deferred` | OPEN | `claim_grade`, and `bin/gate.sh claims` cross-checking the section |
| R-6 | The script decides `resolves` and field presence; the auditor decides the other four and may only lower the grade | HALF-BUILT | `claim_grade` computes; the four auditor answers are a reviewer's judgement recorded in the `domains` cell |
| R-7 | A work item may not rest on a refuted claim | OPEN | `bin/gate.sh claims`, reading the work items' `rests on` column |

## Claim grading


**Grounds kinds.** `cmd` a committed executable and its exit code · `repo` `<sha>:<path>:L<n>:"token"`
resolved with `git show` · `src` a URL, an ISO date and a backticked quoted span · `obs` a numbered
operator procedure and the condition that would falsify it. The **first backticked span** in the
cell is the machine-readable part; prose after it is ignored. A `repo` anchor carries the commit it
resolved at, so a later edit to that file cannot silently invalidate the claim. A quoted token may
not contain a double quote, because the closing quote ends the token; pick another token on the same
line. A `|` inside any cell is written `\|`, or the row splits into an extra column and the
`domains` and `grade` cells shift out from under their headers.

**Domains**, in the fixed order of the `domains` cell: `resolves` · `warrant` · `currency` ·
`standing` · `independence`. Each is `+` pass, `-` fail, `n` inapplicable. A script decides
`resolves` and the presence of every required field. The auditor answers the other four.

Which domains apply is fixed by the kind, and `claim_grade` exits 1 on a `+` or `-` where the table
says `n`:

| kind | resolves | warrant | currency | standing | independence |
|------|----------|---------|----------|----------|--------------|
| `cmd` | script | auditor | `n` | `n` | `n` |
| `repo` | script | auditor | `n` | `n` | `n` |
| `src` | script | auditor | auditor | auditor | auditor |
| `obs` | script | auditor | `n` | `n` | `n` |

**Only `resolves` refutes.** A `-` there means the command did not exit as stated, the anchor token
is not on its line at its commit, or a required field is absent — all machine-decided. Every other
`-` caps the grade at `C`. So no reviewer's judgement can delete a work item; it can only mark the
claim unverified. An auditor that answers `-` wrongly costs a recorded assumption, never work.

**Grade**, computed by `claim_grade` and never typed by hand. Start at `A` for `cmd` and `repo`, `B`
for `src`, `C` for `obs`. A `-` on `resolves` gives `refuted`. Any other `-` caps at `C`. An empty
falsifier caps at `C`.

**What a grade permits.** `A` and `B` carry work items. `C` is an unverified assumption: it stays in
the plan and is named in `## Open & deferred`. `refuted` keeps its row so the defeat is auditable,
and every work item resting on it is deleted.

The rows live in `## Claims`, which holds that one table and nothing else. `bin/gate.sh` reads the
first table under a heading and stops at the next heading. A second table beside the rows would be
read as more rows.

## Claims

| id | claim | kind | grounds | warrant | falsifier | domains | grade | defeated by |
|----|-------|------|---------|---------|-----------|---------|-------|-------------|
| C-1 | The counted corpus exceeds its own rule budget, so a line added is paid for by a deletion | cmd | `bin/rule-count.sh --assert` exits 1 printing `OVER: 175 rule lines, budget 173` | The counter reads the twelve files one run is told to obey, so its verdict is the budget | `bin/rule-count.sh` with no argument exits 0, which would have shown the budget unenforced; it prints the same 175 against 173 | `++nnn` | A |  |
| C-2 | Nothing parses the template's `## Verified current state`, so it can be replaced | cmd | `grep -rl "Verified current state" bin lib checks scripts tests` returns no file | Those five directories hold every executable that reads a plan | The same grep over `commands templates` returns hits, so the pattern matches where the string exists | `++nnn` | A |  |
| C-3 | `bin/gate.sh` dispatches no `coverage` subcommand | repo | `0599b18:bin/gate.sh:L614:"criteria)"` | Line 614 is the first arm of the subcommand `case` at line 613; a subcommand absent from it is unreachable | `bin/gate.sh coverage x` exits 2 with an unknown-subcommand message | `++nnn` | A |  |
| C-4 | `coverage` is already specified and unbuilt, so building it closes recorded debt | repo | `0599b18:vault/architecture/session-gates-unbuilt.md:L24:"coverage <plan>"` | The row names the exit codes that close it, so the specification is the acceptance test | `grep -c '^\| U-' vault/architecture/session-gates-unbuilt.md` returns 7, so the row is one of a standing list and not an isolated note | `++nnn` | A |  |
| C-5 | A critique carrying no external check rejects correct answers more often than it catches wrong ones, so an ungrounded refutation must never defeat grounds | src | arXiv 2402.08115 (ICLR 2025) · 2026-09-13 · `95.8% (113/118)` self-verifier false-negative rate on Graph Colouring; corroborated by arXiv 2310.01798 (ICLR 2024), different authors and corpus | Measured on GPT-4 over formal planning and colouring tasks, 100 instances per domain, 2024-25; the transferred quantity is the direction of the error, not its rate | The same paper's Blocksworld row shows self-critique helping, 40% to 55%, which would have contradicted a universal claim; the claim is stated as domain-dependent | `+++++` | B |  |
| C-6 | Models propose confirming tests over falsifying ones in interactive rule discovery, transferred here by analogy | src | arXiv 2604.02485 (2026) · 2026-09-13 · incompatible-to-compatible ratio `0.14-0.77` across 11 model variants on 80 episodes against `1.79` for humans who solved the task | Measured on one synthetic rule-discovery family, not on a research pass; whether an agent skews its own search queries has no primary source | A search of the literature for self-directed query bias returned no measurement, which is recorded rather than hidden | `+++n-` | C |  |
| C-7 | The absence of a deprecation notice is not evidence an approach is alive, so `standing` requires a dated positive signal | src | arXiv 2408.10327 (2024) · 2026-09-13 · explicitly deprecated packages were `1% of inactive packages` across all 415,151 PyPI packages, and `2.9%` of announcements state a rationale | Census-scale denominator plus a developer survey; the mechanism is maintainer silence, which is not language-specific | The `request` example cited here previously proves the converse — a package that does carry a notice — so it was removed rather than counted as support; no second census of maintainer silence was found | `+++n-` | C |  |
| C-8 | A verdict computed from fixed signalling questions, taking the worst domain rather than an average, removes the grader's discretion where bias enters | src | `BMJ 2019;366:l4898` (RoB 2) · 2026-09-13 · five domains, signalling questions feeding an algorithm, study-level judgement normally the worst domain | Fifteen years of adversarial use in guideline bodies; the transferred part is the aggregation rule, which carries no clinical content | ROBIS was checked as a second source and shares an author with RoB 2, so it does not corroborate independently; GRADE, the neighbouring standard, folds additively rather than by worst domain | `+++n-` | C |  |
| C-9 | `cr_anchor_check` resolves anchors against diff hunks, so a working-tree resolver is a second function and not a reuse | repo | `0599b18:lib/cr-helpers.sh:L438:"local diff="` | Its only content source is the diff it parses, so it cannot grade a claim about a file no diff touches | It returns 2 when the diff argument is unreadable rather than falling back to the file, which would have shown it reads the tree | `++nnn` | A |  |
| C-10 | A reviewer told which side to argue produces weaker arguments, so the new seat answers factual questions instead of attacking | src | arXiv 2510.13912 (2025) · 2026-09-13 · debaters were more persuasive arguing in alignment with their own stated beliefs | Read at abstract level only; it bounds the new seat's design and is not a reason to change `personas/_shared/skeptic.md` | No second source measuring the same effect was found, which caps this claim rather than removing it | `+++n-` | C |  |
| C-11 | No adoption signal predicts whether an approach is sound, so `standing` and `independence` cap a grade and never refute | src | `https://api.npmjs.org/downloads/point/last-month/request` · 2026-09-13 · the deprecated `request` package returned `53,122,520` downloads | A package its own maintainer marked deprecated carries a top-percentile download count, so volume and currency are independent quantities | The second signal checked, `packages.ecosyste.ms`, reads the same npm registry, so it is one source queried twice and not corroboration; no published validation of any adoption signal against later failure was found | `+++n-` | C |  |
| C-12 | Sharing the anchor parse would force both programs into awk `-f` files, which is the cost that keeps the duplication | cmd | `sed -n '452,467p' lib/cr-helpers.sh` is the 16 shared lines; `grep -c '^@test' tests/unit/cr-rule-routing.bats` returns 37 across three functions, of which 15 of 76 blocks in that file and `tests/unit/v-cr.bats` call `cr_anchor_check` | awk has no portable include, so one shared function cannot be sourced the way a shell function is | `gawk` provides `@include` and `mawk` and POSIX awk do not, so a portable include would have defeated this claim; the test count naming `cr_anchor_check` is 15 of 76, not the 37 of the whole file | `++nnn` | A |  |
| C-13 | A `repo` anchor into a file its own plan modifies stops resolving when the plan lands, so an anchor carries the commit it resolved at | repo | `0599b18:bin/gate.sh:L608:"case"` is the first of the two dispatch statements, and W-2b inserts functions above both | The anchor's line number is positional, so any insertion above it invalidates the citation without changing the fact it cites | Resolving the same token against `0599b18` with `git show` succeeds regardless of later edits, which is why the sha is part of the anchor | `++nnn` | A |  |

## Decisions

| decision | reason | record |
|----------|--------|--------|
| D-1 | The grade is computed from `kind`, five domain answers and the falsifier, never typed | a grader choosing a number reintroduces the bias the rubric removes (C-8) | `vault/decisions/ADR-028-proof-discipline.md` |
| D-2 | A refutation carries its own grounds in a `defeated by` cell and is audited before it counts | an ungrounded critique's dominant error is rejecting correct claims (C-5) | `vault/decisions/ADR-028-proof-discipline.md` |
| D-3 | No schema field holds a reviewer's stated confidence | the recommended confidence signal reversed within a year, so a gate reading one is built on sand | `vault/decisions/ADR-028-proof-discipline.md` |
| D-4 | `claim_anchor_check` duplicates 16 lines rather than sharing them | awk has no portable include, so sharing forces both programs into `-f` files (C-12) | local |
| D-5 | The dispatcher drafts every claim row; no reviewer writes one | it makes R-4 structural instead of a check, and a separate drafter seat owns no affordance the dispatcher lacks | `vault/decisions/ADR-028-proof-discipline.md` |
| D-6 | The claim ledger replaces `## Verified current state` | two tables for one question is duplication, and nothing reads the old section (C-2) | local |
| D-7 | `standing` and `independence` cap; only `resolves`, `warrant` and `currency` refute | no adoption signal has published validation against later failure, so a hard gate on one rejects correct work (C-11) | `vault/decisions/ADR-028-proof-discipline.md` |
| D-8 | A claim graded `C` stays in the plan and is named in `## Open & deferred` | deleting it hides an unverified assumption the operator could still correct, and banning its work items stalls the session on its own mechanism | `vault/decisions/ADR-028-proof-discipline.md` |
| D-9 | `subject` folds into `warrant` rather than being its own domain | the scope mismatch and the licence are one judgement, which is how the source standard treats indirectness | local |
| D-10 | `claims` and `coverage` exit 1 for a substantive refusal and 2 for a parse error | the dispatcher sets `status: failed` on 1 only, so a malformed table stops the run as an error instead of declaring the work impossible | `vault/decisions/ADR-028-proof-discipline.md` |

## Scope & non-goals

Covers the claim ledger, five audit domains, the auditor seat, the refutation rule, two gate
subcommands and the failed-session state, across `/v-team`, `/v-pm`, `/v-work` and `/v-cr`.

Excluded: building the methodology-designer command; rewording `personas/_shared/skeptic.md`;
extracting a shared anchor resolver; any auto-reject on an adoption signal.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `## Claims` table | `bin/gate.sh claims`, which parses `kind`, `grounds`, `warrant`, `falsifier`, `domains` and `grade` | the dispatcher at `commands/v-team/steps/03-propose-loop.md` §(a) | `personas/_shared/proof-auditor.md` re-runs each row; `bin/gate.sh claims` recomputes each grade | `gate.sh claims` exits 2 naming the missing table and the run stops as an error |
| `domains` cell | `claim_grade` in `lib/claim-helpers.sh`, which folds the five characters | the auditor's answers, transcribed by the dispatcher at §(e).2 | `bin/gate.sh claims`, which refuses a `grade` disagreeing with `claim_grade` | a cell that is not five of `+-n` exits 2; a `+` on a domain inapplicable to the kind exits 1 |
| `falsifier` cell | `claim_grade`, which caps an empty one at `C` | the dispatcher, from the contradicting check it ran | `bin/gate.sh claims`, which then requires the claim in `## Open & deferred` | the claim is graded `C` and refused unless `## Open & deferred` names it |
| `rests on` cell of `## Work items` | `bin/gate.sh claims`, which refuses a work item resting on a refuted or absent claim | the dispatcher, when it writes the work item | `bin/gate.sh claims` | a work item citing an absent claim id exits 1 naming the id |
| `AUDITED_CLAIMS` block | `commands/v-team/steps/03-propose-loop.md` §(d), which defines it as a returned section | each seated reviewer, in its own findings file | the dispatcher, which diffs the union of ids against the `## Claims` ids before applying anything | a claim in no reviewer's block is reported unaudited and graded `C` |
| `lib/claim-helpers.sh` | `bin/gate.sh`, which sources it before dispatch | this plan | `bin/gate.sh` and `tests/unit/proof-discipline.bats` | `bin/gate.sh` exits 2 at startup naming the unreadable library |
| `status: failed` in plan frontmatter | `commands/v-team.md` Step 4, which opens no approval gate on it | the dispatcher, on `coverage` exit 1 | the operator, and `/v-capture` | a session with no reachable criterion still asks for approval to build |

## Work items

| id | file (exact path) | action | tool | constraint | rests on | covers | verification | status |
|----|-------------------|--------|------|------------|----------|--------|--------------|--------|
| W-1 | `lib/claim-helpers.sh` | create | Write | `claim_grade` and `claim_anchor_check` and `claim_falsification_ratio`; the anchor is the cell's first backticked span, rejected unless exactly `<sha>:<path>:L<n>:"token"`, resolved with `git show` | C-9 C-12 C-13 | SC-1 SC-5 | `tests/unit/proof-discipline.bats` | TODO |
| W-2b | `bin/gate.sh` | modify | Edit | source `lib/claim-helpers.sh` near the top as `bin/indication-route-audit.sh` does; add the `claims` arm to the `case` at L613, never the one at L608 which bypasses the refusal count | C-13 | SC-1 SC-6 SC-7 | `checks/proof-discipline-SC-6.sh` | TODO |
| W-3 | `personas/_shared/proof-auditor.md` | create | Write | five domains in one table; a `## Bound analyzer` section naming the fetch, execute and registry commands; worst domain wins; `standing` and `independence` cap and never refute; no source-credibility or AI-origin scoring; cedes numbers to `business/data-evidence` | C-7 C-8 C-10 C-11 | SC-3 | `checks/proof-discipline-SC-3.sh` | TODO |
| W-4a | `commands/v-team/steps/03-propose-loop.md` | modify | Edit | delete the five re-statements at L234, L238-239, L252 and L258, each owned by `commands/_shared/communication.md` or `document-standard.md` | C-1 | SC-4 | `checks/proof-discipline-SC-4.sh` | TODO |
| W-4b | `commands/v-team/steps/03-propose-loop.md` | modify | Edit | §(d) gains an `AUDITED_CLAIMS` block with its column order and answer vocabulary, plus `direction` and `target_claim` on a finding; §(c) partitions claim ids across the seated reviewers; §(g) fences `claim_falsification_ratio` and runs `gate.sh claims` and `coverage` | C-1 C-5 | SC-4 SC-5 | `checks/proof-discipline-SC-5.sh` | TODO |
| W-5 | `personas/_resolution.md` | modify | Edit | seat `proof-auditor` as guaranteed on PROPOSE — `consumer` already holds the seat `correctness` would take, so the auditor is an added seat and the cap rises to 4; over 5 it displaces `skeptic`, which declares no fixed analyzer while the auditor holds fetch, execute and registry lookups; state the suppression against `business/data-evidence` | C-11 | SC-3 | `checks/proof-discipline-SC-3.sh` | TODO |
| W-6 | `commands/_shared/critic-panel.md` | modify | Edit | §(d) gains `direction` and `target_claim`; a refutation with no target is rejected; at `/v-cr` the target is a `path:L<n>:"token"` anchor, not a claim id, and the auditor audits a finding's own `check` field | C-5 | SC-1 | `tests/unit/v-cr.bats` | TODO |
| W-7 | `templates/plan.md` | modify | Edit | replace `## Verified current state` with `## Claims` carrying the nine columns; add `rests on` to `## Work items`; add `failed` to the `status` values | C-2 | SC-6 SC-7 | `checks/proof-discipline-SC-6.sh` | TODO |
| W-8 | `templates/trail.md` | modify | Edit | add the per-round auditor transcription, written at §(e).2 before dispositions | C-5 | SC-1 | `tests/unit/proof-discipline.bats` | TODO |
| W-10 | `commands/v-work/steps/03-propose.md` | modify | Edit | the plan carries `## Claims`; §3a.6 asks the five domain questions and is mandatory whenever the table has rows | C-2 | SC-3 | `tests/unit/propose-golden.bats` | TODO |
| W-11 | `commands/v-pm/steps/03-plan-panel.md` | modify | Edit | seat the auditor; a `REQ-NN` rule carries grounds | C-11 | SC-3 | `tests/unit/v-pm.bats` | TODO |
| W-12 | `tests/unit/proof-discipline.bats` | create | Write | one planted violation per helper, proven red before green; absence asserted with `run grep` and a status check, never `! grep` | C-1 | SC-1 SC-5 SC-7 | `tests/run.sh tests/unit/proof-discipline.bats` | TODO |
| W-13 | `vault/architecture/session-gates.md` | modify | Edit | add the `claims` row, in the same commit as W-2b, naming the field it reads and both exit codes | C-3 | SC-1 | `checks/proof-discipline-SC-6.sh` | TODO |
| W-15 | `vault/check-budget.md` | modify | Edit | one row for `claims`, at 0 and 0, named for the function it reads | C-11 | SC-3 | `bin/gate.sh budget` | TODO |
| W-16 | `vault/decisions/ADR-028-proof-discipline.md` | create | Write | records D-1, D-2, D-3, D-5, D-7, D-8, D-10 and the rejected alternatives | C-5 C-8 | SC-3 | `bin/doc-lint.sh` | TODO |
| W-17 | `vault/decisions/_inventory.md` | modify | Edit | register ADR-028 in the same commit as W-16 | C-4 | SC-3 | `tests/unit/v-team.bats` | TODO |
| W-18 | `vault/indications/claims-carry-grounds.md` | create | Write | the rule, its rationale from C-5 C-7 C-8 C-11, and its applies-to | C-5 C-7 C-8 C-11 | SC-3 | `bin/doc-lint.sh` | TODO |
| W-19 | `vault/indications/_index.md` | modify | Edit | one row for the new indication | C-4 | SC-3 | `bin/indication-route-audit.sh` | TODO |
| W-20a | `vault/research/llm-collaboration-patterns.md` | modify | Edit | add the rows behind C-5, C-6 and C-10 beside the existing self-correction findings, each with its denominator and date | C-5 C-6 C-10 | SC-3 | `bin/doc-lint.sh` | TODO |
| W-20b | `vault/research/evidence-quality.md` | create | Write | the rows behind C-7, C-8 and C-11 — the evidence-grading and source-signal findings that the collaboration catalog does not cover | C-7 C-8 C-11 | SC-3 | `bin/doc-lint.sh` | TODO |

## Sequencing & dependencies

W-1 and W-2b land before every check that runs them. W-4a lands before W-4b, because the rule
budget has no room until the deletions are in. W-3 lands before W-5. W-7 lands before W-4b, because
the dispatcher writes the section the template defines. W-13 ships in the same commit as W-2b, or
`checks/doc-truth-SC-1.sh` refuses a documented subcommand that does not exist.

## Rollback

Revert the commit. Both subcommands are additive arms on the `case` at `bin/gate.sh:L613`, and no
existing plan carries a `## Claims` table, so `claims` is reached only by a plan written after this
lands. `GATE=off` suppresses every check for a whole run.

**`claims` refuses from the first run.** A warning mode was specified and removed: no script in
this repo writes `vault/check-budget.md`, so a promotion condition keyed to its `fires` column would
never be met and the check would warn forever. The false-positive risk is held down instead by the
narrow refusal surface — only `resolves`, which a script decides — and the row added to
`vault/check-budget.md` by W-15, which the operator increments by hand as every other row is.

## Test plan

`tests/unit/proof-discipline.bats`, run through `tests/run.sh` inside Docker. Per helper: the happy
path, one planted violation proven red before it is trusted green, and absence asserted with `run
grep` plus a status check.

| unit | scenarios |
|------|-----------|
| `claim_grade` | each kind's starting grade; one hard `-` gives `refuted`; one soft `-` caps at `C`; five clean domains do not rescue one hard failure; an empty falsifier caps at `C`; a `+` on a domain inapplicable to the kind exits 1; a `domains` cell that is not five of `+-n` exits 2 |
| `claim_anchor_check` | token on the named line at the named sha; token absent; an anchor followed by prose; a line past end of file; `L0` and a leading-zero line number; a path outside the repo; a symlink; a CRLF file; a token containing a double quote; a path containing a colon; an unknown sha |
| `claim_falsification_ratio` | an empty falsifier caps the grade at `C`; one logged raises it; the ratio prints with its denominator |
| `bin/gate.sh claims` | missing table exits 2; empty `warrant` exits 1; unknown kind exits 1; `cmd` naming a non-executable exits 1; `src` with no ISO date exits 1; `obs` with no falsifying condition exits 1; a `grade` disagreeing with `claim_grade` exits 1; a `refuted` row whose `defeated by` grounds do not resolve exits 1; a work item resting on an absent or refuted claim exits 1; a `C` claim absent from `## Open & deferred` exits 1 |
| `bin/gate.sh coverage` | an uncovered criterion exits 1 and names it; all covered exits 0; a missing `## Work items` table exits 2; a missing `covers` column exits 2, the opposite of `due_criteria`'s all-due default |

## Refs

- `vault/decisions/ADR-003-tool-grounded-findings.md` — a finding blocks only when a check confirms it; this extends that from findings to plan statements.
- `vault/decisions/ADR-017-evidence-based-panel-hardening.md` — verifier tool-asymmetry and reviewer-owned grounding; the auditor seat applies both to evidence.
- `vault/decisions/ADR-026-mechanical-session-gates.md` — a check is a committed script and no model decides whether work is done.
- `vault/indications/enforced-not-just-stated.md` — why every threshold here names the function computing it and ships a test proven to fail.
- `vault/architecture/session-gates-unbuilt.md` — the U-2 row this plan deletes by building it.
- `vault/plans/2026-09-13-1355-v-method.brief.md` — the methodology-designer design this ledger will govern.
- `2026-09-13-1355-proof-discipline.trail.md` — the process record.
