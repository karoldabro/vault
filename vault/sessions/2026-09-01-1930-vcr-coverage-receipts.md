---
type: session
project: vault
date: 2026-09-01
topic: /v-cr coverage computed from per-file critic receipts
continues: [[2026-09-01-1000-vcr-delivery-and-coverage]]
files_touched:
  - commands/_shared/critic-panel.md
  - commands/v-cr/steps/02-gather.md
  - commands/v-cr/steps/03-review.md
  - commands/v-cr/steps/04-post.md
  - commands/v-cr/steps/05-capture.md
  - lib/cr-helpers.sh
  - tests/Dockerfile
  - tests/unit/cr-coverage.bats
  - tests/unit/v-cr.bats
  - vault/indications/cr-delivery-verification.md
  - vault/indications/cr-panel-spawn-and-visibility.md
decisions: []
tags: [session, v-cr, code-review, coverage, critic-panel, testing]
---

# /v-cr coverage computed from per-file critic receipts

## Goal
Stop `/v-cr` reporting coverage it has not measured, after two reviews reached the operator with
unread files and only admitted it when asked.

## Did
- Traced the symptom to the panel's finding schema: `commands/_shared/critic-panel.md` §(d) returned
  findings only, so "no comment on this file" meant both "examined and clean" and "never opened", and
  `05-capture.md`'s `files_entered_context` had no source. One run wrote 33 against a true 41 of 48.
- Added `FILES_EXAMINED` to the shared schema — `evidence<TAB>reason<TAB>path`, five evidence classes,
  path last. A `read` row carries an anchor; an examined-clean file states what was checked.
- Wrote `cr_coverage` in `lib/cr-helpers.sh` (three buckets, `unexamined` and `extra` rows, rc 0/1/2)
  and `03-review.md` §3.6, the gate that calls it. `04-post.md` §4.1 now demands fresh confirmation
  when the unexamined set is non-empty.
- Wired `cr_diff_stats` into `03-review.md` §3.2. It shipped in `e9b8bfd` this morning and was never
  called, so the large-diff guard still could not fire.
- Amended `cr-delivery-verification.md` and `cr-panel-spawn-and-visibility.md`, which still mandated
  the replaced field and the two-bucket line; fixed `tests/unit/v-cr.bats:116`, which would have gone
  red; added `zsh` to `tests/Dockerfile`.
- Ran a three-critic panel (architect, skeptic, quality) on the draft plan: 41 findings, 6 confirmed
  blockers, all applied. Commit `62dd9f6` on `fix/v-cr-coverage-receipts`. Suite 428 pass / 7 fail,
  the same 7 by name as the 405/7 baseline.

## Learned
- **`! grep` can never fail a bats test.** A command prefixed with `!` is exempt from `set -e`, so
  `! grep -q '<string that is present>'` returns success. Proved in-container: the negated form
  passed against a planted violation while `run grep` + `[ "$status" -ne 0 ]` failed correctly.
  Roughly 24 assertions across seven test files are dead this way
  (`grep -rn '^\s*!\s*grep' tests/unit/`); only `cr-coverage.bats` is fixed.
- **The June session's diagnosis was wrong and shaped the wording.** It concluded the panel already
  receives the changed-file list, so sparse comments were precision rather than blindness, and wrote
  `N−M silent (no confirmed findings)` — a phrasing that bakes in the assumption a silent file was
  examined.
- **A stated threshold survives review twice.** `cr_diff_stats` and `files_entered_context` were both
  written the same morning as `enforced-not-just-stated`, which forbids exactly this, and both
  shipped with nothing calling them.
- **The panel's reports do not reliably return through the message channel.** All three critics went
  idle twice with nothing delivered; the reports arrived only after each was told to write to a named
  file. `agent-conduct.md` §3 already required that; `critic-panel.md` did not.
- Dispatching a multi-file awk on a first-line counter breaks on an empty file — an empty changed-file
  list never fires `FNR==1`, so every receipt row parses as a changed file and the run reports perfect
  coverage. `FILENAME` dispatch is the fix; found by testing, not by review.

## Behaviors & rules
- A critic returns a finding set → it also returns one `FILES_EXAMINED` row per changed file it was
  given; edge: under chunking it receipts its own chunk and the caller unions across chunks.
- A receipt row claims `read` → its reason carries `L<n>:"<token from that line>"` and the caller
  checks it against the diff; edge: an anchor that does not match counts as not examined.
- A changed file is examined and clean → its reason says what was checked, so the claim is falsifiable
  without reopening the file.
- Only `read` counts toward examined → `diff-only`, `grep-only` and `skipped` report unexamined with
  their reason; edge: `context` marks an out-of-changeset subject-under-test and is never `extra`.
- Two critics report the same path with different evidence → strongest evidence wins.
- The unexamined set is non-empty → the POST gate demands fresh confirmation and the summary names the
  paths; edge: the operator may accept the gap, recorded as `coverage_accepted`.
- A test asserts the absence of a string → it goes through `run` + `[ "$status" -ne 0 ]`, never
  `! grep`, which cannot fail.
- A contract grep asserts a fenced call → it also asserts the function exists in the lib; edge: a bare
  token grep still passes after the invocation is deleted, because the name survives in prose.

## Next
- Fix the remaining ~24 dead `! grep` assertions, each paired with a planted violation. They span
  `business-personas.bats`, `testing-personas.bats`, `setup-autoinstall.bats`, `v-team.bats`,
  `research-clarify.bats`, `v-pm.bats`, `test-design-fanout.bats`.
- Re-run `/v-cr` on a real PR and read `files_examined` against `files_changed` — the first run where
  that number is measured rather than asserted.
- Merge `fix/v-cr-coverage-receipts` to main.
- Decide whether `personas/_resolution.md` §2.1 should seat more than one testing critic on a
  test-heavy diff; today one critic owns every changed test file.
- Investigate the seven pre-existing suite failures, unchanged across both baselines.

## Refs
- [[../plans/2026-09-01-1930-vcr-coverage-receipts]] — the plan this executed, with its open items.
- [[../plans/2026-09-01-1930-vcr-coverage-receipts.trail]] — the panel's findings and dispositions.
- [[2026-09-01-1000-vcr-delivery-and-coverage]] — added the capture field and named reading it back
  as the next step; this is that step, plus the `cr_diff_stats` call it omitted.
- [[../indications/enforced-not-just-stated]] — the rule both defects broke.
- [[../indications/cr-panel-spawn-and-visibility]] — now carries the three-bucket coverage rule.
- [[../indications/cr-delivery-verification]] — the write-side sibling of this read-side check.
- [[../decisions/ADR-008-v-cr-remote-pr-review]] — the precision-first design whose silence this makes
  legible.
