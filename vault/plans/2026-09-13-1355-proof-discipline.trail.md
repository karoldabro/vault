---
type: trail
project: vault
plan: 2026-09-13-1355-proof-discipline
tags: [trail, record]
---

# 2026-09-13-1355-proof-discipline — process record

Record class. Its contract document is `plans/2026-09-13-1355-proof-discipline.md`, which carries
the current truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Grade computed from six domain answers, worst domain wins | a critic assigns a grade directly | the grader's discretion is exactly where self-preference bias enters, and averaging rescues a proof with one fatal defect |
| A refutation carries its own grounds | any critique may mark a claim refuted | a self-verifier without an external check rejected 113 of 118 correct solutions (arXiv 2402.08115); an open refutation channel would strip correct claims out of the plan |
| A falsification log as a required field per claim | an instruction to "try to disprove it" | measured incompatible-to-compatible ratios of 0.14-0.77 across 11 models say the instruction alone does not take; the ratio is what proves it did |
| Standing and independence cap the grade | a hard refusal on a deprecation or adoption signal | no published validation links any adoption signal to later failure, and the deprecated `request` package draws 53M downloads a month |
| No confidence field in any schema | a confidence score gating entry to the plan | the recommended confidence signal (log-probability against verbalized) reversed within a year for proprietary models |
| Build `coverage` rather than specify it | add a row to `session-gates-unbuilt.md` | seven specified-and-unbuilt checks already read as active; an eighth makes a session believe it was gated when nothing ran |
| Duplicate the anchor parse in `claim_anchor_check` | extract a shared resolver out of `cr_anchor_check` | `cr_anchor_check` reads diff hunks and carries 37 passing cases; a refactor risks them to save about 20 lines of awk |
| One critic panel over the plan, four seats | five seats, or a second round of research | no compute-matched evidence shows a panel beating a single agent on open-ended engineering work; four is the cap this change's own triggered lenses need |

## Critic selection

No persona pack resolves for this repo: it carries none of the stack markers in
`personas/_resolution.md` §1, so §1 fallback item 4 applies and the panel is the shared lenses
rather than a project pack. Seated: `consumer`, `skeptic`, `quality`, `correctness`. The cap was
raised from 3 to 4 because `correctness` is the lens this change's own keywords trigger — it
specifies four shell helpers and two gate subcommands — and `consumer` and `skeptic` are both
guaranteed here.

## Findings & dispositions

### Round 1

Four seats, 5 confirmed BLOCKER and 22 confirmed MAJOR. Verdicts: consumer BLOCK, correctness BLOCK,
skeptic REQUEST_CHANGES, quality REQUEST_CHANGES.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| consumer | consumer-1 | BLOCKER | confirmed | the receipt every reviewer must write has no slot in the schema PROPOSE reviewers return | applied — W-4b puts `AUDITED_CLAIMS` in `03-propose-loop.md` §(d); W-6 keeps `critic-panel.md` for /v-cr and EXECUTE |
| consumer | consumer-2 | BLOCKER | confirmed | the domain answers that compute every grade are written nowhere | applied — a `domains` cell of five characters, and the starting grade stated per kind |
| correctness | correctness-3 | BLOCKER | confirmed | same defect, plus no defined starting grade and no meaning for an inapplicable domain | applied — `n` defined, and a `+` on an inapplicable domain exits 1 |
| correctness | correctness-1 | BLOCKER | confirmed | C-4's anchor is the exact row W-14 deletes | applied — a `repo` anchor carries the commit it resolved at and is read with `git show` |
| correctness | correctness-2 | BLOCKER | confirmed | C-3's anchor is line 614, which W-2b moves | applied — same fix; C-13 records the general defect |
| correctness | correctness-4 | BLOCKER | confirmed | two rules rest on a claim-to-work-item edge the schema does not contain | applied — `rests on` column on `## Work items` |
| skeptic | skeptic-5 | MAJOR | confirmed | same missing edge | applied — same column |
| correctness | correctness-5 | BLOCKER | confirmed | SC-5's grep passes on a prose mention and fails on a real zero-argument call | applied — fence-aware awk match |
| correctness | correctness-6 | BLOCKER | confirmed | deleting a refuted row makes the grade unreachable, so R-3 has no mechanism | applied — a refuted row stays; its dependent work items go |
| skeptic | skeptic-1 | BLOCKER | confirmed | the gate cannot recompute a grade it is required to refuse | applied — `claim_grade` reads the `domains` cell |
| skeptic | skeptic-2 | BLOCKER | confirmed | four of six domains are a model's judgement while the gate claims to be mechanical | applied — R-6 is HALF-BUILT; the script owns `resolves` and field presence, the auditor may only lower |
| skeptic | skeptic-9 | MAJOR | confirmed | nothing partitions claims across seats, so the default is unaudited, which blocks every work item | applied — §(c) partitions ids, the union is diffed, and an unaudited claim is graded `C` rather than banned |
| correctness | correctness-13 | MAJOR | confirmed | /v-work has no auditor, so every claim caps and no work item may rest on one | applied — D-8 changed what a `C` grade permits |
| skeptic | skeptic-10 | MINOR | confirmed | /v-work's only auditor is optional | applied — W-10 makes §3a.6 mandatory whenever the table has rows |
| skeptic | skeptic-3 | MAJOR | confirmed | `obs` is a prose escape hatch nothing checks | applied — `obs` must name a numbered procedure and a falsifying condition, with a gate case |
| skeptic | skeptic-6 | MAJOR | confirmed | deleting a refuted claim orphans the rows citing it | applied — the gate refuses a plan citing an absent claim id |
| skeptic | skeptic-7 | MAJOR | confirmed | C-6's warrant asserts a transfer the plan's own evidence records as unmeasured | applied — C-6 regraded `C`, warrant narrowed, and named in `## Open & deferred` |
| skeptic | skeptic-8 | MAJOR | confirmed | the measured accuracy cost of forcing checkable proofs is never stated | applied — it is an `## Open & deferred` row |
| skeptic | skeptic-4 | MAJOR | confirmed | SC-4 pins a corpus covering three of the work items | applied as a stated gap — the persona, indication and template rules are outside the counter's twelve files |
| quality | quality-1 | MAJOR | confirmed | `due_criteria` at `bin/gate.sh:449-478` already parses the `covers` column | applied — W-2a extracts one map both read, and the inverted default is recorded |
| quality | quality-2 | MAJOR | confirmed | the new persona has no `## Bound analyzer`, and its tool table sits in a file Scope excludes | applied — W-3 carries both, and SC-3 greps for the section |
| quality | quality-3 | MAJOR | confirmed | one evidence set has three homes and W-20 opened a fourth | applied — W-20a extends the existing catalog, W-20b takes only the evidence-quality rows |
| quality | quality-4 | MAJOR | confirmed | SC-3 is a catch-all: nine work items claim a criterion whose check reads two files | applied — every work item re-pointed at a criterion whose check can see it |
| quality | quality-5 | MAJOR | confirmed | the plan cannot meet SC-4: the counter scores `must` and `shall`, so requirement form still raises it | applied — W-4a deletes five named re-statements, measured 175 to 170 and 145 prohibitions |
| quality | quality-6 | MAJOR | confirmed | `claim_auditor_disjoint` has two declared inputs and no work item builds either | applied — the helper is dropped and R-4 is structural |
| consumer | consumer-4 | MAJOR | confirmed | the gate arms never source the file defining the helpers | applied — W-2b sources it as `bin/indication-route-audit.sh` does |
| consumer | consumer-6 | MAJOR | confirmed | a fifth never-droppable seat with no stated displacement under a cap of five | applied — W-5 takes the seat `correctness` holds optionally for plan critique |
| consumer | consumer-7 | MAJOR | confirmed | the drafter is told to exist and never told what it receives | applied by removal — D-5 drops the separate drafter |
| correctness | correctness-7 | MAJOR | confirmed | SC-6 accepts any nonzero exit and corrupts the prose legend | applied — exactly exit 1, the refusal must name C-3, and only the C-3 row is corrupted |
| correctness | correctness-8 | MAJOR | confirmed | reusing the receipt parser swallows trailing prose into the token | applied — the anchor is the cell's first backticked span |
| correctness | correctness-9 | MAJOR | confirmed | SC-4 pins the total, so prohibitions can rise unnoticed | applied — all three numbers pinned |
| correctness | correctness-10 | MAJOR | confirmed | `resolves` is undefined for `src` and would need the network at gate time | applied — for `src` it checks field presence only; span verification is the auditor's soft answer |
| correctness | correctness-11 | MAJOR | confirmed | the defeater's grounds never reach the plan the gate reads | applied — the grade set carries `refuted` and the row keeps its defeater grounds |
| correctness | correctness-14 | MAJOR | confirmed | a parse error would fail the session | applied — D-10 splits exit 1 from exit 2 |
| quality | quality-D4 | MAJOR | confirmed | D-4's conclusion holds and its stated reason was false | applied — C-12 states the true reason and pins the shared block at 16 lines |
| consumer | consumer-3 | MAJOR | confirmed | `refuted` carried three incompatible meanings | applied — one meaning, stated in the `## Claims` preamble |
| consumer | consumer-5 | MAJOR | confirmed | the disjointness helper pointed at a file declared unread | applied by removal |
| correctness | correctness-12 | MAJOR | confirmed | the trail columns are written after dispositions are applied | applied — W-8 moves the transcription to §(e).2 |
| consumer | consumer-8 | MINOR | confirmed | the /v-cr seat audits claim ids /v-cr has no table to hold | applied — at /v-cr the target is a code anchor and the auditor reads a finding's own `check` |
| correctness | correctness-15 | MINOR | confirmed | SC-3 passed on six bare words anywhere in the file | applied — five domains required in one table or list block |
| correctness | correctness-16 | MINOR | confirmed | SC-1 passed on any green bats file and read a missing Docker as a failure | applied — named cases asserted, Docker absence exits 2 |
| skeptic | skeptic-11 | MINOR | confirmed | SC-5's receipt for a proven-red test was a word count | applied — three named planted cases required, one per helper |
| skeptic | skeptic-12 | MINOR | confirmed | SC-3's comment claimed more than its code checked | applied — the comment now states what the code asserts |
| correctness | correctness-17 | MINOR | confirmed | C-3's warrant called the dispatch the only `case` when there are two | applied — reworded, and W-2b names the second `case` |
| skeptic | skeptic-14 | MINOR | advisory | the widest judgement surface sits behind the switch that disables every check | applied — `claims` warns for five sessions before it refuses |
| skeptic | skeptic-15 | MINOR | advisory | the ledger may be a second mechanism for a job one already does | applied — the delta is the refutation channel and the falsifier column, recorded in D-6 and D-8 |
| quality | quality-scope | MAJOR | confirmed | the plan answers two questions, and six items ship alone | applied — `## Sequencing` names slice 1, and Q-1 puts the choice to the operator |
| quality | quality-yagni | MINOR | confirmed | `subject` was named twice and defined nowhere | applied — D-9 folds it into `warrant`; `standing` is kept because the operator asked for it and caps rather than refutes |
| consumer | consumer-9 | MINOR | advisory | C-10's warrant named no reachable thing | applied — it now names the seat's no-side property |
| correctness | correctness-18 | NIT | confirmed | both pins were environment-overridable and the anchor cases omitted CRLF and `L0` | applied — SC-4's pins are fixed and the test plan carries both cases |
| quality | quality-5b | MAJOR | confirmed | SC-4 should run `--assert` | **rejected** — verified on a corpus copy with the five deletions applied: `bin/rule-count.sh --assert` still exits 1 on the 1:1 prohibition ceiling, which the corpus misses by 120 lines, so an `--assert` gate could never pass. SC-4 pins the three counts and the overrun is recorded as open |

### Round 2

Same four seats against the revised plan. Verdicts: consumer BLOCK, correctness BLOCK, skeptic
REQUEST_CHANGES, quality REQUEST_CHANGES. 34 of 46 round-1 findings closed. 9 new confirmed
BLOCKER and 24 new confirmed MAJOR.

**CONVERGENCE: capped at round 2 with 14 open blockers.** The round cap is hard. What follows is the
state handed to the approval gate, not a further revision.

Applied in this round:

| id | severity | issue | disposition |
|----|----------|-------|-------------|
| consumer-r2 | BLOCKER | C-4's falsifier held an unescaped `\|`, so the shipped parser read prose as the `domains` cell and the gate exited 2 on the plan it must pass | applied — escaped, and the convention is stated where the schema is defined; all thirteen rows now parse to nine cells |
| consumer-r2 | BLOCKER | SC-7's fixtures typed grades its own fold contradicts, so its passing case could never pass | applied — each fixture's `domains` cell now folds to its `grade` cell, and a fourth case proves the gate recomputes rather than reads |
| consumer-r2 | BLOCKER | slice 1 documented a subcommand slice 2 builds, turning `checks/doc-truth-SC-1.sh` red, and reached no failed-session state | applied — W-13 split into W-13a and W-13b, and W-9 carries the `coverage` invocation |
| consumer-r2 | MAJOR | `personas/_resolution.md:44` already gives `consumer` the seat W-5 handed the auditor | applied — the auditor is an added seat at a cap of 4, displacing `skeptic` over 5 because it declares no analyzer |
| skeptic-r2 | MAJOR | a model's `-` on `warrant` still produced `refuted`, so "may only lower" was false for the one outcome that destroys work | applied — only `resolves`, the script-decided domain, refutes; every other `-` caps at `C` |
| skeptic-r2 | MAJOR | the warn mode had no builder and its promotion condition could never be met, since no script writes `vault/check-budget.md` | applied by removal — `claims` refuses from the first run and the narrow refusal surface is the mitigation |
| correctness-r2 | BLOCKER | R-3, D-2, W-7 and the test plan all read a `defeated by` column the schema did not contain | applied — the column exists; the table is nine columns |
| correctness-r2 | MAJOR | the rule that a `+` on an inapplicable domain exits 1 had no kind-to-domain map | applied — `## Claim grading` carries the map, and `currency`, `standing` and `independence` apply to `src` only |
| correctness-r2 | MAJOR | SC-3 banned the string `averag`, so a persona stating the contrast the plan uses would fail | applied — the fold is asserted positively as worst-domain |
| correctness-r2 | MINOR | SC-6 read its target plan from the environment | applied — fixed path |
| self | BLOCKER | two tables under `## Claims` parsed as one, so the gate would read four rows of the grading map as claims | applied — `## Claim grading` is its own section and `## Claims` holds one table |
| self | MAJOR | four `domains` cells carried a zero-width character, making them six characters | applied — scrubbed; every cell is five of `+-n` |
| self | MAJOR | C-13's anchor token contained a double quote, which ends the token early | applied — quote-free token, and the format now forbids it |

### Open blockers at the cap

These are the reason the plan is not recommended as it stands.

| id | issue |
|----|-------|
| OB-1 | `C` costs one prose falsifier and one line in `## Open & deferred`, and buys the same work items a resolving anchor buys. The cheapest compliant plan therefore proves nothing, which defeats the mechanism's purpose rather than a detail of it |
| OB-2 | Five of the six `src` rows cite an arXiv id or a journal locator and no URL. Under field-presence on `resolves` they answer `-`, and only-`resolves`-refutes then marks them `refuted` — the fix for one blocker created this one |
| OB-3 | C-1's grounds assert a line printed by `bin/rule-count.sh` that its own W-4a deletes. A `cmd` ground is evaluated live, so the sha-pinning that fixed `repo` anchors does not reach it, and the plan's own rule would then delete W-4a, W-4b and W-12 |
| OB-4 | CLOSED by regrading. C-7's corroboration proved the converse of its own claim, C-8's shares an author with RoB 2, and C-11's reads one registry twice. All three now answer `independence: -` and grade `C` |
| OB-5 | The five domain answers are stored in the reviewer's receipt and again in the plan cell, with no check comparing them, so "the auditor may only lower" has no mechanism |
| OB-6 | Exit 2 means both "unknown subcommand" and "unparseable table", so every exit-2 assertion in the checks is satisfied by the subcommand not being built |
| OB-7 | The `AUDITED_CLAIMS` field set is still named and never stated, and four of five seats are handed domains to answer without the rubric defining them |
| OB-8 | `W-1` rejects a grounds cell whose first backticked span is not a repo anchor, which is nine of the thirteen rows |
| OB-9 | 8 of 23 work items still name a success criterion whose check never opens the file they edit |
| OB-10 | R-4 was claimed `ENFORCED` and is `PROSE`. This plan already violates it: C-6's claim text, its `C` grade and its open row are a reviewer's own round-1 recommendation, transcribed by the dispatcher and then audited by that same reviewer |
| OB-11 | Run on itself, the ledger graded 7 of 13 claims `A` — every one a fact about this repo, checked by a command or an anchor — 1 `B`, and 5 `C`. It refuted nothing, the falsifier column changed no grade, and `warrant` answered `+` on 13 of 13. The measured delta over the existing `## Verified current state` section is the `rests on` edge, the commit-pinned anchor, and `coverage` |
| OB-12 | `PIN_RULES=170` leaves no headroom against the counter's own budget of 173, while W-6 and W-9 edit counted files and name no SC-4 |
| OB-13 | `die()` already exits 2 for an unknown subcommand, so two of SC-2's four assertions pass today against a gate with no `coverage` arm |
| OB-14 | SC-2 and SC-7 build fixture plans in shell that `tests/unit/gate.bats:381-399` already builds as `mkplan_scoped` |
| OB-15 | `obs` is the kind of 0 of 13 claims and costs a preamble clause, a starting grade, a gate case and a `claim_grade` branch. `claim_falsification_ratio` is computed, printed, and read by no enforcement row |

## Metrics

| round | seats | confirmed BLOCKER | confirmed MAJOR | applied | overlap |
|---|---|---|---|---|---|
| 1 | consumer, skeptic, quality, correctness | 5 | 22 | 49 of 52 findings | three seats independently found the missing domain-answer home; two found the missing claim-to-work-item edge; two found the disjointness helper's phantom input |
| 2 | the same four | 9 | 24 | 13 of 33; 9 blockers open at the cap | three seats independently found the unescaped pipe; two found SC-7's self-contradicting fixtures; two found the warn mode's unreachable promotion |

Round 2 added more confirmed blockers than round 1. The loop did not converge, and the cap stopped
it rather than a clean round. Two of round 2's blockers were created by round 1's own fixes: pinning
a `repo` anchor to a commit left `cmd` grounds evaluated live, and confining refutation to
`resolves` turned a missing URL from a capped grade into a deleted claim.

Two of the plan's own claims were refuted by its own mechanism: C-6's warrant asserted a transfer
the research base records as unmeasured, and D-4's stated reason was false while its conclusion
held. Both were the dogfooding working as designed.

## Process exceptions

| exception | what happened |
|-----------|---------------|
| The plan was edited twice while reviewers were reading it | round 1's `correctness` and round 2's `consumer` both report findings against a superseded file. Neither set was invalidated in substance, but a review of a moving document is not a review. The plan is frozen between rounds from here |
| One reviewer broke its read-only instruction | round 2's `consumer` inserted a row into `vault/architecture/session-gates.md` to ground a finding, ran the check, and restored the file. Verified independently: `git diff --stat HEAD` reports no tracked change |
| Two reviewers measured different operations on the rule counter and reported different numbers | round 1 `quality` measured five deletions, round 1 `correctness` measured the additions. Both were reproduced. Deleting the five lines gives 170 rule lines and 145 prohibitions; adding the schema text pushes prohibitions to 153 and requirements to 22, which is why SC-4 pins all three numbers |

## Advisory test hints

## Rejected / deferred

| approach | what killed it |
|---|---|
| A premortem or red-team seat of its own | a seat sharing another's evidence sources adds correlated noise that aggregation amplifies; prospective hindsight stays a prompt on the existing skeptic seat |
| An agent that verifies whether the implementation meets the criteria | across 9,876 trajectories, false success was 44-52% of failures where the agent assessed itself and 3% where an independent process read the state; judges reached at most 0.65 AUROC |
| A Cynefin or Stacey 2x2 router mapping a task to a method | no validated instrument takes a task description and returns a process, and the Stacey matrix's own author repudiated its agile adaptation |
| An OODA loop framing for the staged-session design | it contributes nothing checkable |
| Scoring a source for AI-generated content | all fourteen detectors tested scored below 80% accuracy, so a false positive rejects a correct human source |
| A ThoughtWorks Radar Hold-ring check | `https://www.thoughtworks.com/radar/api/volume` returns the single-page-app HTML shell, so no machine-readable dataset exists |
| A Wayback availability-API freshness check | the availability endpoint returned HTTP 429 on repeated attempts; the CDX endpoint on the same host answered |
| A GitHub dependents count as an adoption signal | `api.github.com/repos/<owner>/<repo>/dependents` returns HTTP 404; deps.dev carries the count instead |
| A Google Fact Check Tools lookup | the API returns HTTP 403 to unregistered callers, so nothing can ship pre-wired |
| A separate drafter seat writing the v0 plan | it owns no affordance the dispatcher lacks, it needs an envelope the rule budget has no room for, and in the one budget-matched measurement the planner and reviewer seats contributed nothing while the executor carried the value |
| `claim_auditor_disjoint` | both its declared inputs were phantom, and making the dispatcher the sole writer of claim rows turns the rule it enforced into a structural property |
| A `subject` audit domain of its own | the scope mismatch and the licence are one judgement, which is how the source standard treats indirectness |
| Banning a work item from resting on a claim graded `C` | every claim starts unaudited, so the rule stalled a session on its own mechanism; the claim is recorded as an unverified assumption instead |
| Adding the new persona and the resolution file to the counted corpus | it re-baselines a measured budget, which is its own change; the gap is recorded rather than hidden |
| A warning mode for `claims` before it refuses | no script in this repo writes `vault/check-budget.md`, so the promotion condition could never be met and the check would warn forever; two of the plan's own criteria also require it to exit 1 |
| Letting a reviewer's judgement refute a claim | a self-verifier's dominant error is rejecting correct work, so only the script-decided domain deletes anything |
