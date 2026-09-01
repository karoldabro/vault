---
type: trail
project: vault
plan: 2026-09-01-1930-vcr-coverage-receipts
tags: [trail, record]
---

# 2026-09-01-1930-vcr-coverage-receipts — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`plans/2026-09-01-1930-vcr-coverage-receipts.md`, which carries the current truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| A `read` receipt row must carry a line number and a token quoted from that line | a bare `read` flag per path | a critic echoing the supplied file list back with `read` on every path scores perfect coverage and both gates fall silent |
| Each `examined-clean` file carries a one-line disposition of what was checked | three buckets with no per-file text | the reported run's five non-credible silences would all report `read` and land in `examined-clean`, so the output would not have changed at all |
| Only `read` counts toward examined | counting `diff-only` as examined | the stated rule that a grep is not a read has to reach the number the gate reads, or it is decoration |
| Receipt row ordered `evidence<TAB>reason<TAB>path` | `path<TAB>evidence<TAB>reason` | the reason is variable-length, so no last-field trick protects a tabbed path unless the path itself is last |
| No new indication; the one new sentence folds into `cr-panel-spawn-and-visibility.md` | a new `cr-coverage-receipts.md` | receipt-and-diff already lives in `agent-conduct.md` Fan-out and computed-not-asserted already lives in `enforced-not-just-stated` |
| `FILES_EXAMINED` shared, rendered wording per caller | rendering the three-bucket line inside the shared module | `/v-team`'s execute loop bars panel vocabulary from user output and has nowhere to print it |
| Wire `cr_diff_stats` into §3.2 in this same change | leave it for a later session | landing a second uncalled helper beside the first repeats the exact failure the plan documents |
| One testing critic owns every changed test file | assigning each test file its own critic | `personas/_resolution.md:75` seats exactly one on a mixed diff, so per-file assignment cannot hold |
| Revise once and take the plan to the gate | a second critic round | the three critics produced no conflicting recommendations and every blocker closed with a named file edit |

## Findings & dispositions

### Round 1 — generic fallback panel (no persona pack resolves for this repo)

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| skeptic | skeptic-1 | BLOCKER | confirmed | a `read` row carries no evidence, so a forged receipt passes | applied — anchor required, unverifiable anchor counts as not examined |
| skeptic | skeptic-2 | BLOCKER | confirmed | the reported run's non-credible silences all land in `examined-clean`, so output is unchanged | applied — per-file disposition on clean files |
| architect | arch-1 | BLOCKER | confirmed | `tests/unit/v-cr.bats:116` asserts the field the rename deletes; no work item touched it | applied — item 10 |
| quality | quality-1 | BLOCKER | confirmed | same, reached independently via the test backlog | applied — item 10 |
| quality | quality-2 | BLOCKER | confirmed | nothing computes the middle bucket; the helper never sees findings | applied — third argument, per-bucket counts |
| quality | quality-3 | BLOCKER | confirmed | per-test-file assignment contradicts the one-testing-critic cap | applied — item 6 states the one-owner rule instead |
| skeptic | skeptic-4 | MAJOR | confirmed | `cr_diff_stats` shipped this morning is never called from §3.2 | applied — item 4; this is the finding that changed the plan's scope |
| architect | arch-2 | MAJOR | confirmed | `cr-delivery-verification.md:20` still mandates the old field | applied — item 11 |
| architect | arch-3 | MAJOR | confirmed | `cr-panel-spawn-and-visibility.md:15,28` still mandates the two-bucket line | applied — item 12 |
| quality | quality-15 | MAJOR | confirmed | both indications stale, reached independently | applied — items 11, 12 |
| architect | arch-4 | MAJOR | confirmed | the proposed new indication restates two existing rules | applied — new indication dropped |
| architect | arch-5 | MAJOR | confirmed | three taxonomies coexist with no mapping between them | applied — mapping stated once in Decisions |
| quality | quality-11 | MAJOR | confirmed | same gap, reached independently | applied — same |
| architect | arch-6 | MAJOR | advisory | the rendered coverage line does not belong in the shared module | applied — item 2 returns a machine set only |
| skeptic | skeptic-3 | MAJOR | confirmed | nothing writes the two files the helper takes as arguments | applied — item 7 plus item 5's materialise step |
| skeptic | skeptic-5 | MAJOR | confirmed | the draft called item 6 a gate and then removed any failing state | applied — item 8 requires fresh confirmation |
| quality | quality-14 | MAJOR | confirmed | the two-bucket wording appears twice in `03-review.md`, only one was edited | applied — item 5 edits lines 77 and 92 |
| quality | quality-5 | MAJOR | confirmed | the signature has no row type for a receipt path outside the list | applied — `extra` row |
| quality | quality-6 | MAJOR | confirmed | the zsh portability guard skips on every containerised run | applied — item 13 |
| quality | quality-7 | MAJOR | confirmed | no CRLF case; a `\r` row reports 100% unexamined and the gate gets switched off | applied — t4 |
| quality | quality-8 | MAJOR | confirmed | unreadable receipt indistinguishable from examined-nothing | applied — rc 2, t5 |
| quality | quality-9 | MAJOR | confirmed | the tabbed-path constraint is unsatisfiable with a trailing variable-length reason | applied — row order changed |
| quality | quality-10 | MAJOR | confirmed | item 3's tool was `Write` on a 146-line file holding 7 helpers | applied — `Edit` |
| quality | quality-12 | MAJOR | confirmed | t5 passed against a function that was never written | applied — t12 greps the lib too |
| quality | quality-13 | MAJOR | confirmed | a planted violation against a positive grep is vacuous | applied — item 14 constraint rewritten |
| quality | quality-16 | MAJOR | confirmed | one wrong-reason class needs the subject under test, which the plan deferred | applied — `context` evidence class, item 6 |
| skeptic | skeptic-6 | MAJOR | confirmed | `tests/unit/v-cr.bats` absent from the file list | applied — item 10 |
| architect | arch-7 | MINOR | confirmed | `/v-team` sources nothing from `cr-helpers.sh` | applied — exemption recorded in item 12 |
| architect | arch-8 | MINOR | confirmed | item 5's only check was a grep for a sentence | applied — item 6 verified through the receipt count |
| architect | arch-9 | MINOR | advisory | field order for the changed-file list unstated | applied — stated in item 3 |
| architect | arch-10 | MINOR | advisory | one receipt row per file per critic returns the index once per agent | applied — per-chunk receipt, unioned by the caller |
| architect | arch-11 | NIT | confirmed | the old field appears at three places, item 7 named one | applied — item 9 names all three |
| skeptic | skeptic-7 | MINOR | confirmed | the enum had no bucket for grep-scanned, the class that produced the symptom | applied — `grep-only` added |
| skeptic | skeptic-8 | MINOR | confirmed | above 40 files the panel chunks and nobody unions across chunks | applied — item 5 unions across chunks |
| skeptic | skeptic-9 | MINOR | confirmed | "15 of the 17 unreviewed files" carried no denominator or command | applied — the number is deleted, item 6 rests on the two defective tests |
| skeptic | skeptic-10 | NIT | confirmed | an accepted coverage limit left no trace | applied — `coverage_accepted` field |
| quality | quality-17 | MINOR | confirmed | the test guarding the highest-yield decision was priority `should` | applied — t14 is `must` |
| quality | quality-18 | MINOR | confirmed | empty-list and empty-receipt return codes unstated | applied — t6 |
| quality | quality-19 | MINOR | advisory | duplicate receipt rows across critics undefined | applied — strongest-evidence-wins, t7 |
| quality | quality-20 | MINOR | confirmed | nothing tests the schema-to-parser round trip | applied — t9 |

## Metrics

Round 1: 3 critics, 41 findings, 6 confirmed BLOCKERs, 0 rejected, 0 deferred. Persona overlap: 4
findings reached independently by two critics (the `v-cr.bats` breakage, the stale indications, the
evidence-to-bucket gap). Confirmed 37 / advisory 4. No previously-confirmed finding was dropped.
Panel delivery failed twice through the message channel and succeeded only when each critic was told
to write its report to a named file.

## Advisory test hints

The design critics' proposed tests were folded directly into the plan's Test backlog rather than kept
separate — this plan's deliverable is largely test coverage, so the two lists would have been one.

## Rejected / deferred

- **A new `cr-coverage-receipts.md` indication.** Dropped: receipt-and-diff is already
  `agent-conduct.md`'s Fan-out bullet and computed-not-asserted is already `enforced-not-just-stated`,
  leaving one genuinely new sentence that has a home already.
- **Per-test-file critic assignment.** Dropped: `personas/_resolution.md:75` seats one testing critic
  on a mixed diff, so the rule could not have held. Raising the seat count stays open.
- **Rendering the three-bucket coverage line inside the shared panel module.** Dropped: `/v-team`
  consumes the same module and bars panel vocabulary from user-facing output.
- **A second critic round.** Not run: no two critics recommended conflicting changes, and every
  blocker closed with a named file edit rather than a redesign.
