---
type: plan
project: vault
slug: 2026-09-09-1052-indication-routing-coverage
repos: [vault]
status: executed
process_record: 2026-09-09-1052-indication-routing-coverage.trail.md
session: 2026-09-09-1052-indication-routing-coverage
tags: [plan]
---

# 2026-09-09-1052-indication-routing-coverage — plan

## Task
Make a review print how many project rules it actually checked, how many it could not reach, and which
ones — instead of citing whichever rules a file happened to remind a critic of. Two mechanisms: a
router that assigns rules to critics from the index, and an anchor verifier that decides whether a
critic's per-rule verdict is real. Keywords: `Applies-to`, `cr_rule_route`, `cr_rule_coverage`,
`cr_anchor_check`, `RULES_CHECKED`, indication index, coverage gate.

## Open & deferred
- **open** — glob routing cannot reach a rule about a contract **between** files or repos, because such
  a rule names no changed path. Measured by the shipped tool:
  `~/vault/givore/indications/cross-repo/_index.md` is 2 routable rows of 44. Those rules route only
  when their cell holds a declared `indication_scopes` value. Where it holds neither, the rule is
  `unroutable` and this plan does not check it — it prints it.
- **open** — `no-match` and `unroutable` are unmeasured, not clean. Nobody verdicts those rules. The
  summary line keeps all four buckets apart for exactly this reason, and `vault/check-budget.md`
  records the limitation under `## What the checks do not cover`.
- **deferred** — no project's `_index.md` is edited. Half the index rows across the estate carry a cell
  that is neither a glob nor a declared surface value: 172 unroutable of 347 rows over 10 project
  indexes, excluding this repo. Repairing them is each project's work; `bin/indication-route-audit.sh`
  is what lets them see the list.
- **deferred** — `/v-work` and `/v-team` keep their current indication load. `commands/v-work/steps/
  01-analyze.md` emits no path list and the plan is authored one step later, so a router at
  LOAD CONTEXT would have no input. Routing at PROPOSE against the Work-items paths is a later plan.
- **deferred** — `/v-pm` and `/v-do`. `/v-do` is deliberately vault-lite; `/v-pm` has no changed-file
  list to route against.

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | Does an unchecked rule block the post, or only report? | no | `sed -n '20,30p' commands/v-cr/steps/04-post.md` — a non-empty unexamined set already requires its own fresh confirmation; `vault/check-budget.md` refuses a check that fires wrongly above one run in ten | defaulted | Only a **routed rule with no anchored verdict** returns rc 1 and asks for confirmation. `unroutable` and `no-match` print and never gate. A gate that fired on every review of a 31-unroutable index would be cleared unread within four runs, and would take the file-coverage gate down with it. |
| Q-2 | Route on the existing `Applies-to`/`scope` cell, or add a new column? | no | `sed -n '205,233p' bin/doc-lint.sh` (INDEX3 reads it); `commands/v-cr/steps/02-gather.md` §2.4 rule 2 (surface filter reads it); `grep -m1 '^\|' ` over 14 project indexes — 3 `Applies-to`, 7 `applies-to`, 1 `scope` | defaulted | Existing cell, read-only, **composed with** the two consumers it already has. A new column would route nothing until every project filled it; rewriting cells to globs would break `bin/doc-lint.sh` INDEX3 wherever a project declares `indication_scopes`. |
| Q-3 | Should `/v-work` get the same router in this plan? | no | `commands/v-work/steps/01-analyze.md` Required output — emits `Scope: <code-only\|vault-only\|both>`, no path list; step order 01→02→03 puts the plan after LOAD CONTEXT | defaulted | No. There is no path list at LOAD CONTEXT, so the router would have no input and its output line no reader. Deferred above rather than shipped as a field nothing produces. |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN `cr_rule_route`, `cr_rule_coverage` and `cr_anchor_check` are exercised over the fixture indexes THE SYSTEM SHALL pass every routing, bucketing, merge and anchor case | unit | command | `checks/indication-routing-SC-1.sh` | exit 0 | MET | `checks/indication-routing-SC-1.sh` exited 0 · 30 tests in `tests/unit/cr-rule-routing.bats`, all passing |
| SC-2 | WHEN a critic emits a verdict row whose anchor names a line outside the diff, a path outside its assignment, or a token absent from the named line THE SYSTEM SHALL count that rule unchecked | unit | command | `checks/indication-routing-SC-2.sh` | exit 0 | MET | `checks/indication-routing-SC-2.sh` exited 0 · OK every unresolvable anchor counts its rule unchecked |
| SC-3 | WHEN the step files are read THE SYSTEM SHALL find the fenced call to each new function and its definition in `lib/cr-helpers.sh` — not a prose mention | unit | command | `checks/indication-routing-SC-3.sh` | exit 0 | MET | `checks/indication-routing-SC-3.sh` exited 0 · OK every new function is called from a step file and defined in the library |
| SC-4 | WHEN `bin/rule-count.sh` runs after this plan lands THE SYSTEM SHALL report no more rule lines than the count pinned before it | unit | command | `checks/indication-routing-SC-4.sh` | exit 0 | MET | `checks/indication-routing-SC-4.sh` exited 0 · OK 175 rule lines, at or under the pinned 175 |
| SC-5 | WHEN the router runs against this repo's index and against both real givore indexes THE SYSTEM SHALL produce the recorded bucket counts, including a non-empty `unroutable` bucket and a non-empty `no-match` bucket | delivery | command | `checks/indication-routing-SC-5.sh` | exit 0 | MET | `checks/indication-routing-SC-5.sh` exited 0 · this repo 0 unroutable, givore api 32, givore cross-repo 42 |
| SC-6 | WHEN `bin/doc-lint.sh` runs over every file this plan writes THE SYSTEM SHALL report no finding | unit | command | `checks/indication-routing-SC-6.sh` | exit 0 | MET | `checks/indication-routing-SC-6.sh` exited 0 · OK 9 files pass doc-lint |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| D-1 | tests pass — `./tests/run.sh tests/unit` | met | 659 passing; 4 failures pre-existing in `tests/unit/{document-standard,plugin-install,research-clarify}.bats`, none in a file this plan touches |
| D-2 | docs lint — `./bin/doc-lint.sh --changed` | met | `checks/indication-routing-SC-6.sh` exited 0 over all 9 files |
| D-3 | delivery run — SC-5 executed against the two real givore indexes, not only this repo's | met | `bin/indication-route-audit.sh` run against 11 indexes across 5 projects; counts in Verified current state |
| D-4 | duplication detector | absent: no duplication detector in this repo | |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | Every rule routed to a changed path is assigned to a critic and carries a verdict | ENFORCED | `cr_rule_route` + `cr_rule_coverage` in `lib/cr-helpers.sh`, `tests/unit/cr-rule-routing.bats`, gate wired at `commands/v-cr/steps/03-review.md` §3.6 |
| E-2 | A verdict whose anchor does not resolve against the diff counts as unchecked | ENFORCED | `cr_anchor_check` in `lib/cr-helpers.sh`; anchor cases in `tests/unit/cr-rule-routing.bats`; `checks/indication-routing-SC-2.sh` |
| E-3 | Every `read` row in `FILES_EXAMINED` is anchor-verified too | ENFORCED | the same `cr_anchor_check`, plus `cr_coverage`'s fourth argument (the bad-anchor file), which drops a rejected `read` row before ranking it; before this the check ran and nothing consumed its result |
| E-4 | A rule nobody could route is printed, never silently dropped and never a gate failure | ENFORCED | `unroutable` bucket in `cr_rule_route`; summary line in `commands/v-cr/steps/03-review.md` §3.5; `bin/indication-route-audit.sh` |
| E-5 | A critic cannot reach full rule coverage by answering `n/a` to everything | ENFORCED | `n/a` requires the rule body's trigger clause and no code anchor; `cr_rule_coverage` counts `n/a` in its own column and flags a critic above the `n/a` share threshold |

## Verified current state
- The `Applies-to` / `scope` cell **already has two consumers**, so it is not free to redefine.
  `bin/doc-lint.sh:205-233` (`index_scope_column`, `index_scope_vocabulary`) raises INDEX3 when the
  cell is not one of the project's declared `indication_scopes`; `commands/v-cr/steps/02-gather.md`
  §2.4 rule 2 filters rows by the same cell. Checked 2026-09-09.
- INDEX3 is silently inert on 13 of 14 project indexes: `bin/doc-lint.sh:211` matches only a header
  spelled `scope`, and the header is `Applies-to` in 3 indexes, `applies-to` in 7, `scope` in 1.
- Routability across the estate, measured 2026-09-09 by `bin/indication-route-audit.sh` itself, one
  invocation per index: this repo 33 of 33; givore api 98 of 130; givore cross-repo 2 of 44; givore
  mobile 9 of 48; givore web 8 of 28; givore dashboard 4 of 27; givore shop 2 of 2; givore
  marketing-site 6 of 8; magic 25 of 32; studio 21 of 22; mistflare 0 of 6. Excluding this repo:
  **175 routable of 347 rows**.
- The `Applies-to` cell in `vault/indications/_index.md` is broader than several rule bodies' own
  `## Applies-to` section — `installer-dry-run-seam` reads `tests/**` in the index and
  `tests/unit/setup-autoinstall.bats`, `tests/e2e/**` in the body, so it routes onto every
  test-touching change and every reviewer must answer `n/a`. The router reads the index, by design;
  reconciling the two is index-repair work, deferred above.
- A project index often holds more than one markdown table, and a later table repeats the header row.
  Parsing that header as data invents a rule named `slug` and reports it unroutable — an unreachable
  rule that does not exist. `cr_rule_route` skips a row whose first cell is `slug`, `rule`, `name` or
  `id` and re-reads the applies-to column from it.
- Fetching routed rule bodies does not threaten the token ceiling: 37 routed rules × ~340 words each
  ≈ 17k tokens against the ~200k `VCR_MAX_TOKENS` at `commands/v-cr/steps/03-review.md:54-55`. No cap
  is needed and none is specified.
- No code verifies an anchor today. `cr_coverage` (`lib/cr-helpers.sh:170`) switches on the evidence
  field alone; the anchor requirement at `commands/v-cr/steps/03-review.md:120` is prose nothing runs.
- `awk` here is `mawk 1.3.4 20240123`; `gawk` is not installed, so `gensub()` is unavailable.
- `vault/indications/plan-appetite-not-tasks.md` exists as a rule file with no row in
  `vault/indications/_index.md`, so an index-only router cannot see it.
- `./bin/rule-count.sh --assert` already exits 1 (175 rule lines against a budget of 173), and
  `tests/unit/rule-count.bats:29-31` asserts that exit 1, so the unit suite cannot notice a rise.
- CodeRabbit ships the same primitive as `path_instructions` — a glob paired with the rules to apply
  to matching files — so glob-to-rule routing is the standard mechanism, not a novel one. Checked
  2026-09-09 against `https://docs.coderabbit.ai/configuration/path-instructions`.

## Decisions

| decision | reason | record |
|----------|--------|--------|
| Read the existing `Applies-to`/`scope` cell; never require a project to rewrite it | A new column routes nothing until every project fills it; a glob written into that cell fails `bin/doc-lint.sh` INDEX3 | local |
| A cell yields three token classes — glob, declared surface value, neither — and the third is `unroutable` | Composes with the two consumers the cell already has instead of overriding them | local |
| `breaks` and `holds` need a code anchor; `n/a` needs the rule's own trigger clause instead | Without this, `n/a` plus any line from the hunk scores full coverage and reproduces the defect one level up | local |
| Only a routed rule with no anchored verdict returns rc 1 | An `unroutable` gate would fire on every review of a real index, and a gate cleared unread costs every other gate | local |
| `cr_anchor_check` verifies `FILES_EXAMINED` rows as well as `RULES_CHECKED` rows | The existing anchor rule is prose nothing executes; one verifier closes both holes | local |
| `/v-work` routing is deferred, not shipped | `01-analyze.md` emits no path list, so the router would have no input at LOAD CONTEXT | local |

## Scope & non-goals
Covers: three shell functions and their tests, the `RULES_CHECKED` receipt and verdict vocabulary in the
shared panel schema, the wiring in `/v-cr` steps 2–4, an audit script, one indication, and the
check-budget rows for the new gates.

Does not cover: editing any project's `_index.md` or `templates/indication.md`; `/v-work`, `/v-team`,
`/v-pm`, `/v-do`; reaching a rule that names no changed path and no declared surface; changing how
findings are ranked, capped or posted.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `$CR_RULE_ROUTES` — `applies`/`no-match`/`unroutable` rows, `applies` rows carrying the matched path | `commands/v-cr/steps/02-gather.md` §2.4 must name a path for §3.1 to build the critic assignment from | `cr_rule_route` in `lib/cr-helpers.sh` | `commands/v-cr/steps/03-review.md` §3.1 (assignment) and §3.6 (`cr_rule_coverage`) | Absent or rc 2: §3.6 prints `Rules: not measured` and names the reason; it must never print a zero, because zero routed and zero measured read identically to the operator |
| `RULES_CHECKED` receipt rows — `<verdict><TAB><anchor-or-trigger><TAB><slug>` | `commands/_shared/critic-panel.md` §(d) schema; `cr_rule_coverage` has no numerator without it | each spawned critic, into its own findings file | `commands/v-cr/steps/03-review.md` §3.6, after `cr_anchor_check` | Absent, anchorless, or anchored outside the critic's assigned paths: that rule counts unchecked, rc 1, and its slug is named in the summary comment |
| `routed-unchecked` — the summary-comment rule line `Rules: <c> checked · <a> n/a · <n> routed-unchecked · <m> no-match · <u> unroutable` | `commands/v-cr/steps/03-review.md` §3.5's mandatory summary ordering, beside the existing coverage and test-posture lines | step 3 synthesis | the PR author on the forge | Absent at review time the author reads a verdict with no idea which rules were consulted — the state this plan exists to end; `checks/indication-routing-SC-3.sh` fails the build when §3.5 stops requiring it |
| `bin/indication-route-audit.sh` — the routable / unroutable split for one index | SC-5; and a project cannot repair cells it cannot list | this plan | the operator, run against their own index | Absent, the unroutable list is visible only inside a review run, so nobody ever repairs an index cell and the bucket grows |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `tests/unit/cr-rule-routing.bats` | create | Write | written first and proven red against the current `lib/cr-helpers.sh`; fixtures include the verbatim brace-group row and the verbatim escaped-pipe row from `vault/indications/_index.md` | SC-1, SC-2 | `./tests/run.sh tests/unit/cr-rule-routing.bats` fails before W-2 | DONE |
| W-2 | `lib/cr-helpers.sh` | add `cr_rule_route <index> <changed_files> [scopes]` | Edit | POSIX awk / mawk 1.3.4 — no `gensub`, no GNU extensions; locate the column by case-insensitive header match on `applies-to`, `applies to` or `scope` and exit 2 naming the reason when absent, never fall through to a position; take the cell as `$(NF-1)` so the escaped pipe on `_index.md:37` cannot shift it; expand `{a,b,c}` brace groups before splitting on `[ ,;]+`; glob translation pinned as `**`→`.*`, `*`→`[^/]*`, `?`→`[^/]`, `.` literal; a token equal to a declared scope value is `surface`, not `unroutable`; rc 0 all rows classified · 1 any `unroutable` row · 2 bad input | SC-1, SC-5 | W-1 | DONE |
| W-3 | `lib/cr-helpers.sh` | add `cr_anchor_check <diff> <receipt>...` | Edit | variadic in the receipts — the panel produces two, and verifying only the first leaves every rule verdict unchecked and the gate permanently green; the path must be in the diff, the line inside a hunk (`@@` and combined `@@@`), and the quoted token on that line; emits `bad-anchor<TAB><slug-or-path><TAB><anchor as written><TAB><reason>`, the anchor raw so a whitespace-only one still matches the rejection key | SC-2, E-2, E-3 | W-1 | DONE |
| W-4 | `lib/cr-helpers.sh` | add `cr_rule_coverage <routes> <rules_checked> <bad_anchors>` | Edit | identify by slug, never by row number; strip CR; a `bad-anchor` row disqualifies the row that carried it, keyed on (slug, anchor-as-written), not every row for that slug; duplicate slugs across critics resolve `breaks` > `holds` > `n/a`, and an anchorless `breaks` loses to an anchored `holds`; emit `checked`, `routed-unchecked`, `n-a`, `no-match`, `unroutable` counts plus the unchecked slugs; rc 1 **only** when `routed-unchecked` is above zero | SC-1, Q-1 | W-1 | DONE |
| W-5 | `commands/_shared/critic-panel.md` | add `RULES_CHECKED` to §(d) and to §Output | Edit | define the three verdicts once, here: `breaks` and `holds` carry `<path>:L<n>:"<token>"` from a line in the critic's own assignment, `holds` also naming the rule condition the line satisfies; `n/a` carries no code anchor and instead quotes the rule body's trigger clause and the path shape that would have fired it; slug is the last field; state the added rule-line count in the commit message so SC-4 can be read against it | SC-3, E-5 | `checks/indication-routing-SC-3.sh` | DONE |
| W-6 | `commands/v-cr/steps/02-gather.md` | replace §2.4 retrieval rule 3 and extend the Required output | Edit | rule 2 (surface filter) is left intact and named as the other channel; bodies for the routed set are fetched before the panel spawns, not on demand; routes written to `$CR_RULE_ROUTES`; output gains `<a> routed · <m> no-match · <u> unroutable` | SC-3 | `checks/indication-routing-SC-3.sh` | DONE |
| W-7 | `commands/v-cr/steps/03-review.md` | build the rule assignment in §3.1, add the rule line to §3.5, call `cr_anchor_check` then `cr_rule_coverage` in §3.6 | Edit | assignment maps a routed slug to the critic that holds its matched path, and a slug whose path no critic holds goes to the architect seat; §3.6 replaces the prose anchor instruction at line 120 with the fenced call; the summary rule line carries four counts and names the routed-unchecked and unroutable slugs | SC-3, E-3 | `checks/indication-routing-SC-3.sh` | DONE |
| W-8 | `commands/v-cr/steps/04-post.md` | treat `cr_rule_coverage` rc 1 like `cr_coverage` rc 1 | Edit | one fresh confirmation covers both coverage gaps, never two prompts in one review | Q-1 | `checks/indication-routing-SC-3.sh` | DONE |
| W-9 | `bin/indication-route-audit.sh` | create | Write | `--help`; takes an index and an optional changed-file list; prints routable and unroutable slugs; exit 1 when any row is unroutable; named for indications, not for the framework rules `bin/rule-audit.sh` and `bin/rule-count.sh` already measure | SC-5 | `checks/indication-routing-SC-5.sh` | DONE |
| W-10 | `checks/indication-routing-SC-1.sh` … `SC-6.sh` | create | Write | one script per criterion, each exiting nonzero today; SC-3 greps the fenced call plus `^cr_<fn>\(\)` in `lib/cr-helpers.sh`, never a bare token | SC-1, SC-2, SC-3, SC-4, SC-5, SC-6 | run each before W-2 lands | DONE |
| W-11 | `vault/indications/rules-routed-not-recalled.md` | create | Write | follow `templates/indication.md`; the `Applies-to` cell stays in this project's existing style so INDEX3 is not provoked | E-1 | `checks/indication-routing-SC-6.sh` | DONE |
| W-12 | `vault/indications/_index.md` | append the W-11 row | Edit | same cell style as its neighbours | E-1 | `checks/indication-routing-SC-6.sh` | DONE |
| W-13 | `vault/check-budget.md` | add `rule-coverage` and `anchor-check` rows, and a `## What the checks do not cover` paragraph | Edit | the paragraph states plainly that `no-match` and `unroutable` are unmeasured buckets, not clean ones | E-4 | read-back | DONE |

## Sequencing & dependencies
W-10 and W-1 land first and are proven red. W-2 through W-4 follow in that order — W-4 consumes both
other functions' output. W-5 precedes W-6 through W-8, which consume the schema it defines. W-9 needs
W-2. W-11 through W-13 may land last.

## Rollback
`git revert` the commit. `lib/cr-helpers.sh` gains three functions nothing else calls, but the step
files will name them, so reverting the library alone leaves fenced calls to absent functions — revert
the whole commit, never one file. Nothing here writes to a forge, a vault or a database; the change is
fully reversible.

## Test plan
Harness: bats-core in the repo container (`./tests/run.sh tests/unit`).
- `cr_rule_route` · unit · glob match, declared-surface token, prose-only cell, mixed cell, brace
  group, escaped pipe, absent header, CRLF, path containing a tab, empty index, empty changed-file
  list · `tests/unit/cr-rule-routing.bats`
- `cr_anchor_check` · unit · token absent from the named line, line outside every hunk, path outside
  the critic's assignment, well-formed anchor · `tests/unit/cr-rule-routing.bats`
- `cr_rule_coverage` · unit · all verdicted, missing slug, bad-anchor slug, duplicate slug across
  critics, anchorless `breaks` against anchored `holds`, `unroutable` present and rc still 0 ·
  `tests/unit/cr-rule-routing.bats`
- step-file contract · unit · the fenced calls and the function definitions exist as a pair ·
  `checks/indication-routing-SC-3.sh`

## Test design dossier
**Decision table — `cr_rule_route` per index row**

| cell tokens | a glob matches a changed path | emitted bucket |
|---|---|---|
| at least one glob | yes | `applies`, with the matched path |
| at least one glob, no declared-surface token | no | `no-match` |
| at least one glob plus a declared-surface token | no | `applies`, on the surface channel |
| declared-surface token only | n/a | `applies`, on the surface channel |
| neither | n/a | `unroutable` |

Accounting is **per row, one bucket per row**, so `|applies| + |no-match| + |unroutable|` equals the row
count exactly. Per-token accounting would put a mixed row in two buckets and break the invariant.

**Fault hypotheses**
- A `Rule` cell containing an escaped pipe (`_index.md:37`) shifts the column and routes the wrong globs.
- A brace group (`_index.md:14`, `personas/{sales,seo,…}.md`) is comma-split into fragments that match
  nothing and are miscounted as unroutable.
- A path containing a tab shifts a changed-file row — the fault `cr_diff_stats` already guards.
- A critic answers `n/a` to its whole assignment and scores full coverage.
- A critic anchors every verdict to one line of one file it was not assigned.
- Two critics verdict one slug differently, and the unanchored one wins.

**Metamorphic relations.** Adding an unrelated changed file never shrinks `applies`. Adding an index
row never lowers `checked`.

**Boundary partitions.** Zero rows · zero changed files · every row unroutable (mistflare, 0 of 6) ·
every row routable (this repo, 32 of 32) · one row matching every changed file.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | SC-1 | unit | `tests/unit/cr-rule-routing.bats` | a glob cell matching a changed path emits `applies` with that path | high | |
| T-2 | SC-1 | unit | `tests/unit/cr-rule-routing.bats` | the verbatim `_index.md:14` brace-group row routes as one row, not six fragments | high | |
| T-3 | SC-1 | unit | `tests/unit/cr-rule-routing.bats` | the verbatim `_index.md:37` escaped-pipe row keeps its four globs | high | |
| T-4 | SC-1 | unit | `tests/unit/cr-rule-routing.bats` | a cell holding a declared `indication_scopes` value emits `applies` on the surface channel, never `unroutable` | high | |
| T-5 | SC-1 | unit | `tests/unit/cr-rule-routing.bats` | an index with no recognised header exits 2 and names the reason | high | |
| T-6 | SC-2 | unit | `tests/unit/cr-rule-routing.bats` | a verdict whose quoted token is absent from the named line emits `bad-anchor` | high | |
| T-7 | SC-2 | unit | `tests/unit/cr-rule-routing.bats` | a verdict anchored outside the critic's assigned paths emits `bad-anchor` | high | |
| T-8 | E-5 | unit | `tests/unit/cr-rule-routing.bats` | an all-`n/a` receipt does not reach full `checked` — `n/a` is its own count | high | |
| T-9 | SC-1 | unit | `tests/unit/cr-rule-routing.bats` | an anchorless `breaks` loses to an anchored `holds` on the same slug | medium | |
| T-10 | Q-1 | unit | `tests/unit/cr-rule-routing.bats` | `unroutable` rows present, every routed rule verdicted → rc 0 | high | |
| T-11 | E-3 | unit | `tests/unit/cr-rule-routing.bats` | a `read` row whose anchor does not resolve is not counted examined | medium | |
| T-12 | boundary | unit | `tests/unit/cr-rule-routing.bats` | empty index and empty changed-file list exit cleanly with zero counts | medium | |
| T-13 | property | unit | `tests/unit/cr-rule-routing.bats` | the three route buckets sum to the index row count | medium | |
| T-14 | SC-4 | unit | `tests/unit/rule-count.bats` | the corpus rule-line count is pinned as a number and fails when an edit raises it | medium | |

## Refs
- `commands/v-cr/steps/02-gather.md` — §2.4 rule 2 is the surface channel this plan composes with;
  rule 3 is what it replaces.
- `commands/_shared/critic-panel.md` — §(d) is where `RULES_CHECKED` joins `FILES_EXAMINED`.
- `lib/cr-helpers.sh` — `cr_coverage` at line 170 is the awk idiom all three functions copy.
- `bin/doc-lint.sh` — lines 205-233 are the INDEX3 consumer of the cell this plan reads.
- `vault/check-budget.md` — the one-in-ten rule that decides Q-1's gate semantics.
- `vault/indications/enforced-not-just-stated.md` — §5's fenced-call-not-bare-token rule binds SC-3.
- `vault/indications/rules-the-model-can-check.md` — why a rule needing a count gets a hook.
- `2026-09-09-1052-indication-routing-coverage.trail.md` — the process record.
