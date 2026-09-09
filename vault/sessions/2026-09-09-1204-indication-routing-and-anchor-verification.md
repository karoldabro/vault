---
type: session
project: vault
date: 2026-09-09
topic: /v-cr routes indications to the diff and verifies every citation
continues: [[2026-09-01-1930-vcr-coverage-receipts]]
files_touched:
  - bin/indication-route-audit.sh
  - checks/indication-routing-SC-1.sh
  - checks/indication-routing-SC-2.sh
  - checks/indication-routing-SC-3.sh
  - checks/indication-routing-SC-4.sh
  - checks/indication-routing-SC-5.sh
  - checks/indication-routing-SC-6.sh
  - commands/_shared/critic-panel.md
  - commands/v-cr/steps/02-gather.md
  - commands/v-cr/steps/03-review.md
  - commands/v-cr/steps/04-post.md
  - commands/v-cr/steps/05-capture.md
  - lib/cr-helpers.sh
  - tests/unit/cr-rule-routing.bats
  - tests/unit/v-cr.bats
  - vault/check-budget.md
  - vault/indications/_index.md
  - vault/indications/rules-routed-not-recalled.md
decisions: []
tags: [session, v-cr, code-review, indications, coverage, critic-panel, testing]
---

# /v-cr routes indications to the diff and verifies every citation

## Goal
Stop a review citing whichever project rules a file happened to bring to mind, after one reported
four rules of a hundred and forty-nine and could not say anything about the rest.

## Did
- Added `cr_rule_route`, `cr_anchor_check` and `cr_rule_coverage` to [[../../lib/cr-helpers.sh]],
  and wired them through `commands/v-cr/steps/02-gather.md` §2.4, `03-review.md` §3.1/§3.5/§3.6 and
  `04-post.md` §4.1.
- Defined the `RULES_CHECKED` receipt and its three verdicts in
  [[../../commands/_shared/critic-panel.md]] §(d), beside `FILES_EXAMINED`.
- Gave `cr_coverage` an optional fourth input, the bad-anchor set, so a fabricated `read` anchor is
  no longer counted examined.
- Wrote `bin/indication-route-audit.sh` and ran it over 11 indexes in 5 projects.
- 37 cases in `tests/unit/cr-rule-routing.bats`, written before the functions and proven red;
  6 criterion scripts under `checks/indication-routing-SC-*.sh`.
- Recorded the rule in [[../indications/rules-routed-not-recalled]] and the unmeasured buckets in
  [[../check-budget]].

## Learned
- The `Applies-to` / `scope` cell already had two consumers — `bin/doc-lint.sh:205-233` (INDEX3) and
  `02-gather.md` §2.4 rule 2 — so it could not be redefined as a glob column. INDEX3 is inert on 13
  of 14 indexes anyway, because it matches only a header literally spelled `scope` while the header
  is `Applies-to` in 3 and `applies-to` in 7.
- Half the estate cannot be routed: 175 routable of 347 rows across 10 project indexes.
  `~/vault/givore/indications/cross-repo/_index.md` is 2 of 44, because a rule about a contract
  between repos names no changed path.
- An index often holds several markdown tables. Parsing a later table's header as data invents a
  rule named `slug` and reports it unroutable.
- `awk` here is mawk 1.3.4 with no gawk, so `gensub()` is unavailable and a glob must be translated
  character by character.
- An apostrophe inside a comment in a single-quoted awk program terminates the program. It cost one
  debugging cycle and `bash -n` catches it.
- Fetching the routed bodies is cheap: 37 rules against a 130-row index is roughly 17k tokens,
  under a tenth of the review ceiling. The cost is the verdicts, not the fetch.

## Behaviors & rules
- An index row whose glob matches a changed path → `applies`, carrying that path; glob-shaped and
  matching nothing → `no-match`; naming neither a glob nor a declared surface → `unroutable`; edge:
  a row is counted in exactly one bucket, so the three sum to the row count.
- A `breaks` or `holds` verdict names a line in the diff and quotes a token really on it → counted
  checked; edge: the anchor is compared as written, so a whitespace-only anchor is rejected like an
  empty one.
- An `n/a` verdict carries the rule body's trigger clause and no code anchor → counted in its own
  column, never in `checked`; edge: a receipt that answers `n/a` to everything reports `checked 0`.
- A routed rule with no usable verdict → exit 1 and one operator confirmation shared with the
  file-coverage gate; edge: `no-match` and `unroutable` print and never gate, however large.
- A `read` row whose anchor does not resolve → not counted examined, once the bad-anchor set is
  passed to `cr_coverage`.

## Next
- Reconcile each index cell against its own rule body's `## Applies-to`: `installer-dry-run-seam`
  reads `tests/**` in `vault/indications/_index.md` and a narrower set in its body, so it routes
  onto every test-touching change and every reviewer must answer `n/a`.
- `templates/indication.md` still teaches a prose `Applies-to`, so the unroutable bucket grows with
  each new rule.
- Route indications in `/v-work` at PROPOSE, where the plan's Work-items table supplies real paths.
  `01-analyze.md` emits no path list, so LOAD CONTEXT is the wrong step.
- Four pre-existing unit failures remain, untouched by this work:
  `tests/unit/document-standard.bats` (2), `plugin-install.bats` (`commands/v-reconcile.md` has no
  frontmatter description), `research-clarify.bats`.

## Refs
- [[../plans/2026-09-09-1052-indication-routing-coverage]] — the plan this session executed.
- [[../plans/2026-09-09-1052-indication-routing-coverage.trail]] — findings and rejected options.
- [[../indications/rules-routed-not-recalled]] — the rule this work established.
- [[../indications/enforced-not-just-stated]] — why each criterion names a committed script.
- [[../indications/cr-delivery-verification]] — the sibling rule on never printing an unverified count.
- [[../indications/cr-panel-spawn-and-visibility]] — the receipt discipline this extends.
- [[2026-09-01-1930-vcr-coverage-receipts]] — the file-coverage receipt this builds on.
