---
type: plan
project: vault
slug: 2026-09-01-1930-vcr-coverage-receipts
repos: [vault]
status: executed
process_record: 2026-09-01-1930-vcr-coverage-receipts.trail.md
session:
tags: [plan, v-cr, coverage, critic-panel]
---

# 2026-09-01-1930-vcr-coverage-receipts — plan

## Task
Make `/v-cr` compute which changed files a critic actually read and what it checked in each, so
coverage stops being asserted and a review carrying unread files cannot reach the POST gate silently.
Keywords: `coverage`, `receipt`, `critic-panel`, `cr_coverage`, `cr_diff_stats`, `test-file owner`.

## Open & deferred
- open — **every `! grep` absence assertion in `tests/unit/` is dead.** A command prefixed with `!`
  is exempt from `set -e`, so `! grep -q '<string that is present>'` returns success and the test
  passes. Proved in-container: the negated form passed against a planted violation, the
  `run grep` + `[ "$status" -ne 0 ]` form failed correctly. Fixed in `tests/unit/cr-coverage.bats`
  only. Roughly 24 assertions across `business-personas.bats`, `testing-personas.bats`,
  `setup-autoinstall.bats`, `v-team.bats`, `research-clarify.bats`, `v-pm.bats` and
  `test-design-fanout.bats` are still no-ops — `grep -rn '^\s*!\s*grep' tests/unit/`. Not fixed
  here: outside the approved scope, and each needs its own check that it fails on a planted
  violation.
- open — **a receipt is still the agent's own claim.** The orchestrator can prove a path was omitted
  or invented (it holds the changed-file list) and can reject an anchor that does not match the diff,
  but it cannot prove an agent reasoned about a file it quoted. This raises the floor; it does not
  make coverage provable.
- open — `personas/_resolution.md:75` seats exactly **one** testing critic on a mixed diff. Item 6
  makes that one critic's receipt list every changed test file, but 15 test files still land on one
  agent. Raising the seat count is not in this plan.
- deferred — no receipt for files read outside the changed set, except the subject-under-test that
  item 6 requires. Coverage answers "was every changed file examined", not "was enough context read".
- deferred — the `files_entered_context` → `files_examined` rename has no migration. Sessions written
  before this lands keep the old key; a query across both must accept either.

## Verified current state
- `commands/v-cr/steps/03-review.md` contains exactly **one** `cr_` reference — `cr_fingerprint` at
  line 86 (`grep -n 'cr_' commands/v-cr/steps/03-review.md`, 1 hit). §3.2's large-diff guard names no
  function, so `cr_diff_stats` — written this morning — is never called and the guard still cannot
  fire. This is the defect `vault/indications/enforced-not-just-stated.md` was written to prevent,
  and that indication cites this exact line as a working example at its line 38.
- `commands/_shared/critic-panel.md` §(d) returns findings only, with no per-file output, so no caller
  can compute coverage.
- `commands/v-cr/steps/05-capture.md` requires `files_entered_context` at lines 15, 27 and 86, "every
  field computed, none asserted", with nothing behind it.
- `tests/unit/v-cr.bats:116` asserts `files_entered_context` appears in `05-capture.md` — and passes —
  while no code computes the value.
- The two-bucket coverage wording appears **twice** in `03-review.md`: line 77 (the posted summary
  comment) and line 92 (the terminal output) — `grep -n 'silent (no confirmed'`, 2 hits.
- `vault/indications/cr-delivery-verification.md:20` mandates `files_entered_context`;
  `vault/indications/cr-panel-spawn-and-visibility.md:15` and `:28` mandate the two-bucket line. Both
  bind `05-capture.md` / `03-review.md`, so leaving them unedited keeps the old rule authoritative.
- `commands/_shared/agent-conduct.md:99` already states the fix — "Prove coverage mechanically.
  Require an identifier per input item in the agent's output, then diff that set against the input
  set" — and it is not wired into `critic-panel.md`.
- `tests/Dockerfile:4-11` installs bash, git, grep, findutils, coreutils, curl, jq — **no zsh**, so
  `tests/unit/cr-coverage.bats`'s only shell-portability guard skips on every containerised run.
- Baseline suite: 405 pass, 7 fail (`./tests/run.sh tests/unit`, 2026-09-01) — the same 7 the previous
  session recorded, so they are pre-existing.

## Decisions
- Coverage is computed from per-critic file receipts — a finding list cannot distinguish clean from
  unread.
- **A `read` row carries an anchor** — a line number plus a token quoted from that line — and the
  orchestrator rejects any anchor that does not match the diff it already holds. Without this, a
  critic echoing the file list back scores perfect coverage.
- **An `examined-clean` file carries a one-line disposition** — what was checked. This is the only
  change that alters the output for the reported run where assigned reviewers came back empty.
- Only `read` counts as examined; `diff-only`, `grep-only` and `skipped` report unexamined with their
  reason — the stated rule that a grep is not a read must reach the number the gate reads.
- The receipt row is `evidence<TAB>reason<TAB>path` — the path is unbounded and must be the last
  field, the same reason `cr_diff_stats` puts its counts last.
- `FILES_EXAMINED` goes in the shared schema; the rendered three-bucket wording stays in `/v-cr`'s
  step file — `/v-team` has nowhere to print one and is exempt, recorded in the indication.
- No new indication — receipt-and-diff already lives in `agent-conduct.md` and "computed, not
  asserted" already lives in `enforced-not-just-stated`; only "silence is never read as clean" is new
  and it belongs where the coverage line already lives.
- `cr_diff_stats` is wired into §3.2 in this change — landing a second uncalled helper beside the
  first would repeat the exact failure this plan documents.

## Scope & non-goals
Covers: the shared panel schema, `/v-cr` steps 3–5, two helpers, the test Dockerfile, two existing
indications, two test files. Non-goals: raising the testing-critic seat count; `/v-team`'s own
coverage reporting (exempt, recorded); anything in `sandbox.md`.

## Work items

| id | file (exact path) | action | tool | constraint | verification | status |
|----|-------------------|--------|------|------------|--------------|--------|
| 1 | `commands/_shared/critic-panel.md` | add `FILES_EXAMINED:` to the §(d) schema — rows `evidence<TAB>reason<TAB>path`, evidence one of `read \| context \| diff-only \| grep-only \| skipped`; a `read` row's reason field carries `L<n>:"<token quoted from that line>"`; an `examined-clean` file's reason states what was checked | Edit | paths come from the caller's changed-file list, never invented; duplicate paths across critics resolve strongest-evidence-wins; under §3.2 chunking each critic receipts its chunk only | `tests/unit/cr-coverage.bats` asserts the schema block and the row order | done |
| 2 | `commands/_shared/critic-panel.md` | §(f) + Output: return the machine set `Unexamined: [paths]` and the merged receipt — **not** rendered prose | Edit | no three-bucket wording here; `/v-team` consumes the set or ignores it | test asserts the module emits no `silent (no confirmed` wording | done |
| 3 | `lib/cr-helpers.sh` | add `cr_coverage <changed_file_list> <receipt_file> <findings_paths_file>` — prints `with_findings<TAB>n`, `clean<TAB>n`, `unexamined<TAB>n`, then one `unexamined<TAB><path>` per missed file and one `extra<TAB><path>` per receipt path outside the list; rc 0 all examined, 1 any unexamined or extra, 2 unreadable input | **Edit** (the file holds 7 existing functions — never Write) | path is the last field; strip `\r`; empty changed-file list is rc 0; non-empty list with empty receipt is rc 1 with one row per file | new `cr_coverage` cases in `tests/unit/cr-coverage.bats` | done |
| 4 | `commands/v-cr/steps/03-review.md` | §3.2: wire the existing `cr_diff_stats` into the large-diff guard as a fenced call | Edit | the guard's threshold is unusable without it; this is a shipped defect, not new work | `tests/unit/v-cr.bats` asserts §3.2 names `cr_diff_stats` **and** that `^cr_diff_stats()` exists in the lib | done |
| 5 | `commands/v-cr/steps/03-review.md` | add §3.6 the coverage gate — materialise each critic's `FILES_EXAMINED` to a path, union **across chunks**, call `cr_coverage`, render the three buckets; replace the two-bucket wording at **both** line 77 and line 92 | Edit | §3.6 names `cr_coverage` in a fenced call; the denominator is the whole changed-file list, never one chunk | test asserts `silent (no confirmed` is absent from the whole file and §3.6 names the function | done |
| 6 | `commands/v-cr/steps/03-review.md` | §3.1: the one testing critic seated by `personas/_resolution.md:75` **owns every changed test file** and its receipt must list each one; it reads the subject-under-test and records it `context`; its lens checks the pass-for-the-wrong-reason class (asserts current-broken behaviour, fixture that dodges the gate under test, test reimplements its subject) | Edit | states the honest one-owner rule — it does not raise the seat count | §3.6 reports unexamined **test** files as their own count; test asserts that count exists | done |
| 7 | `commands/v-cr/steps/02-gather.md` | §2.1: emit the changed-file list to a named path so §3.6 has an input | Edit | the same list `cr_diff_stats` reads | test asserts the path is named | done |
| 8 | `commands/v-cr/steps/04-post.md` | §4.1: the preview shows the coverage line, and a non-empty unexamined set requires **fresh confirmation**, the way `--max-comments` does at line 20 | Edit | resolves the draft's contradiction — it is a gate or it is not | test asserts §4.1 names the unexamined set as a confirmation trigger | done |
| 9 | `commands/v-cr/steps/05-capture.md` | replace `files_entered_context` at §5.1 (line 15), its rationale paragraph (line 27) **and** §5.4's `Coverage:` line (line 86) with `files_examined` / `files_unexamined` / `unexamined_paths` / `coverage_accepted`, each carrying its command | Edit | keep "every field computed, none asserted" and give it a source | test asserts the new names present and `files_entered_context` absent | done |
| 10 | `tests/unit/v-cr.bats` | line 116: swap `files_entered_context` for the new field names | Edit | **without this the suite goes red on landing** | `./tests/run.sh tests/unit/v-cr.bats` | done |
| 11 | `vault/indications/cr-delivery-verification.md` | line 20: rename the mandated field to the new names | Edit | the rule binds `05-capture.md`; leaving it stale keeps the old field authoritative | `bin/doc-lint.sh` clean; test asserts the old name is gone | done |
| 12 | `vault/indications/cr-panel-spawn-and-visibility.md` | lines 14-17 and the line-28 example: three-bucket form, plus the one new sentence (silence is never read as clean) and `/v-team`'s exemption; cite `agent-conduct.md` Fan-out rather than restating it | Edit | no new indication file — this rule has a home already | `bin/doc-lint.sh` clean; test asserts the old wording is gone | done |
| 13 | `tests/Dockerfile` | add `zsh` to the `apk add` list (line 4-11) | Edit | the existing zsh guard skips on every containerised run today | `./tests/run.sh tests/unit/cr-coverage.bats` shows the zsh case running, not skipped | done |
| 14 | `tests/unit/cr-coverage.bats` | add the `cr_coverage` cases and contract greps below | Edit | a positive-presence grep must also assert the superseded wording is **gone** — deleting a string to watch a grep fail proves only that the grep is spelled right | `./tests/run.sh tests/unit` — 405 pass / 7 fail baseline must not worsen | done |

## Sequencing & dependencies
Item 3 before items 5 and 14 — the step file and the tests name the function, so it must exist. Item 7
before item 5 — §3.6 needs the changed-file list path. Items 1–2 before 9 — the capture field has no
source until the schema emits one. Item 10 lands in the same commit as item 9 or the suite goes red.
Item 13 before item 14's zsh case. Item 14 last.

## Rollback
`git revert` of the single commit. No data migration and no state outside the repo. The one lasting
effect is the renamed capture field in any session written between landing and revert; those files
stay readable either way.

## Test plan
`bats` inside the project container, never on host: `./tests/run.sh tests/unit/cr-coverage.bats` for
the file, `make test-unit` for the suite. Baseline to beat: 405 pass, 7 fail. Two levels — unit cases
for `cr_coverage`, and contract greps that assert each step file states its rule, every positive grep
paired with an assertion that the superseded wording is absent.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| t1 | item 3 | unit | `tests/unit/cr-coverage.bats` | rc 1 and one `unexamined` row per missed path | must | |
| t2 | item 3 | unit | `tests/unit/cr-coverage.bats` | a receipt path containing a tab is not dropped (path is last field) | must | |
| t3 | item 3 | unit | `tests/unit/cr-coverage.bats` | a receipt path outside the changed-file list emits `extra` and sets rc 1 | must | |
| t4 | item 3 | unit | `tests/unit/cr-coverage.bats` | a CRLF receipt row does not report 100% unexamined | must | |
| t5 | item 3 | unit | `tests/unit/cr-coverage.bats` | rc 2 on unreadable input, distinct from "examined nothing" | must | |
| t6 | item 3 | unit | `tests/unit/cr-coverage.bats` | empty list → rc 0; non-empty list with empty receipt → rc 1, one row per file | must | |
| t7 | item 3 | unit | `tests/unit/cr-coverage.bats` | duplicate paths across critics resolve strongest-evidence-wins | must | |
| t8 | item 3 | unit | `tests/unit/cr-coverage.bats` | the three buckets are counted separately, one case per bucket | must | |
| t9 | items 1+3 | unit | `tests/unit/cr-coverage.bats` | round trip — a receipt built literally in item 1's row format parses, so schema and parser cannot drift | must | |
| t10 | item 3 | unit | `tests/unit/cr-coverage.bats` | behaves identically under zsh (requires item 13) | must | |
| t11 | item 4 | unit | `tests/unit/v-cr.bats` | §3.2 names `cr_diff_stats` **and** `^cr_diff_stats()` exists in the lib | must | |
| t12 | item 5 | unit | `tests/unit/cr-coverage.bats` | §3.6 names `cr_coverage` **and** `^cr_coverage()` exists in the lib | must | |
| t13 | items 5+12 | unit | `tests/unit/cr-coverage.bats` | `silent (no confirmed` is absent from `03-review.md` and from the indication | must | |
| t14 | item 6 | unit | `tests/unit/cr-coverage.bats` | §3.6 reports unexamined test files as their own count | must | |
| t15 | items 9+10+11 | unit | `tests/unit/v-cr.bats` | new field names present; `files_entered_context` absent from the step file and the indication | must | |
| t16 | item 8 | unit | `tests/unit/v-cr.bats` | §4.1 names a non-empty unexamined set as a fresh-confirmation trigger | must | |

## Refs
- `vault/indications/enforced-not-just-stated.md` — the rule this defect breaks twice: the coverage
  field and the large-diff threshold both state a number with no call behind it.
- `vault/indications/cr-delivery-verification.md` — the write-side sibling; item 11 amends it.
- `vault/indications/cr-panel-spawn-and-visibility.md` — added the two-bucket line item 12 replaces.
- `commands/_shared/agent-conduct.md` — its Fan-out section states "prove coverage mechanically";
  this plan wires it into the panel it was written for.
- `vault/sessions/2026-09-01-1000-vcr-delivery-and-coverage.md` — added the capture field and named
  reading it back as the next step; this is that step, plus the `cr_diff_stats` call it omitted.
- `vault/sessions/2026-06-19-1605-v-cr-panel-spawn-coverage-brevity.md` — the session that added the
  coverage line; read it before touching the wording, since it records what that line was for.
- `vault/decisions/ADR-008-v-cr-remote-pr-review.md` — the precision-first design whose silence this
  plan makes legible.
