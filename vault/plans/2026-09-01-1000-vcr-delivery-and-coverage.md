---
type: plan
project: vault
slug: 2026-09-01-1000-vcr-delivery-and-coverage
repos: [vault]
status: executed
process_record: 2026-09-01-1000-vcr-delivery-and-coverage.trail.md
session:
tags: [plan, v-cr, code-review]
---

# 2026-09-01-1000-vcr-delivery-and-coverage — plan

## Task

Make `/v-cr` deliver a whole review and record what it covered, so the next scope decision rests on a
measurement instead of an assumption. Keywords: `04-post.md` read-back, summary-first gate,
`05-capture.md` coverage fields, `cr_verify_posted`, indication `scope` filter, comment fencing.

## Open & deferred

- **open** — Nobody can tell whether `/v-cr` under-reads big diffs. No run records how many files
  entered model context. Settled only by re-running `/v-cr` on `karoldabro/api.givore.com#190` once
  items 1–6 land.
- **open** — Why the PR #190 summary post failed is unknown. The operator confirms it never reached
  them, so it was not deleted, and `--unpost` was not the cause: it deletes by marker and the 9
  fingerprinted inline comments survive. A run that hit an execution limit mid-post is the leading
  candidate; item 2's read-back turns the next occurrence into a loud failure rather than a diagnosis.
- **open** — Branch type is an unexcluded confound for the whole coverage premise. Both low-yield runs
  reviewed release aggregations of already-reviewed code; the high-yield run reviewed a fresh feature
  branch with an empty suppression set. Test it by running `/v-cr` once on a **large feature branch
  with an empty suppression set**: if yield per changed line matches PR #3237, coverage is not the
  problem.
- **deferred** — The partition-and-fleet redesign (review units × lenses). At 12 units it covers 18.9%
  of PR #190's changed lines using 24 agents; full coverage needs ~128 agents. Not built until the
  instrumentation says scope is the binding constraint.
- **deferred** — `/v-cr` opening pull requests against `git@github.com:karoldabro/vault.git`. Replaced
  by work item 13, a local proposal file the operator turns into a PR from a separate session.
- **blocked** — Item 10d. `~/vault/givore/indications/_index.md` holds 149 rows over the 400-character
  one-line-rule limit and 16,813 words against a 4,000-word cap, so reading it costs more than reading
  the rules it lists. Splitting those rows moves real prose and needs the operator's call on where each
  paragraph belongs. Until then `~/vault/givore/indications/.doc-lint` exempts INDEX1 and INDEX2 with
  that reason; delete those two lines when 10d lands. INDEX3 is **not** exempted.
- **open** — Item 10e. Only givore declares `indication_scopes`; the other 6 project vaults do not, so
  INDEX3 does not run for them and their scope columns are unchecked.
- **open** — Two pre-existing `HIST5` findings in `~/vault/givore/indications/_index.md` (lines 212 and
  228) predate this work and are untouched by it — they are givore's rule prose, not this plan's.

## Verified current state

| fact | how it was checked | date |
|---|---|---|
| `karoldabro/api.givore.com#190` carries 9 inline comments, all with `v-cr:fp` markers, and **0 issue comments** | `gh api repos/karoldabro/api.givore.com/issues/190/comments` → length 0; `pulls/190/comments` → 9, all `body` matching `v-cr:fp` | 2026-09-01 |
| The summary comment id the session records does not exist | `gh api repos/karoldabro/api.givore.com/issues/comments/4881350226` → 404 | 2026-09-01 |
| All 9 review wrappers have empty bodies | `gh api repos/karoldabro/api.givore.com/pulls/190/reviews` → 9 rows, `body` length 0 | 2026-09-01 |
| `04-post.md` never reads back what it wrote | `commands/v-cr/steps/04-post.md:68` — `Posted: <n inline …> + summary (created\|updated)` is a self-assertion | 2026-09-01 |
| `05-capture.md` records no coverage | §5.1 lists target, adapter, task ref, per-finding metadata; §5.4 report has no coverage field | 2026-09-01 |
| The large-diff guard has no implementation | `lib/cr-helpers.sh` defines only `cr_code_hash`, `cr_fingerprint`, `cr_jira_keys`, `cr_asana_gids`; nothing measures diff size or `VCR_MAX_TOKENS` | 2026-09-01 |
| PR #190 is 523 files / 50,817 changed lines against a ~1500-line guard threshold | `gh api repos/karoldabro/api.givore.com/pulls/190/files --paginate`, summed | 2026-09-01 |
| `~/vault/givore/indications/` is 225 files / 83,245 words (~111k tokens) | `find … ! -name _index.md \| wc -l`; `cat … \| wc -w` | 2026-09-01 |
| §2.4 names `indications` with **no retrieval rule**, so the subsetting each run performs is undefined and unrecorded — not wholesale loading | `commands/v-cr/steps/02-gather.md:44` reads "decisions (ADRs), indications, the feature dossier for the touched area", with no cardinality or ordering contract | 2026-09-01 |
| Vault rules did reach the PR #190 critics | Two posted comments cite project decisions — `config/ads.php:16` cites ADR-232, `config/resources.php:14` cites deny-by-default authz | 2026-09-01 |
| `bin/doc-lint.sh` caps documents by **lines**, so a table row holding a paragraph is invisible | `bin/doc-lint.sh:55-68`; `~/vault/givore/indications/_index.md` passes at "235 lines, cap 400" while holding 16,813 words, 149 rows over 400 characters, longest 1,520 | 2026-09-01 |
| A `/v-cr` cron run has previously hit an execution limit mid-run, leaving unrecoverable partial results | claude-mem observation 22377, 2026-07-05, project `recycling_mobile_app` | 2026-09-01 |
| The givore indication index `scope` column holds 13 distinct values for 7 real surfaces | `grep '^\| ' _index.md \| awk -F'\|' '{print $2}' \| sort \| uniq -c` — includes `cross-repo` vs `cross-cutting`, `api.givore.com` vs `api`, `givore_app` vs `mobile`, and one row whose scope cell holds a slug | 2026-09-01 |
| An indication is the **highest-precedence** sandbox recipe source, and `install`/`test` are not stripped | `lib/cr-sandbox.sh:116` precedence order; `cr_is_envelope_key` (`lib/cr-sandbox.sh:95`) covers network/caps/mounts/env only | 2026-09-01 |
| Commit `efcd7e8` (2026-06-19) already added the mandatory coverage and `Spawned:` lines | `git log -1 --format=%ci efcd7e8`; both failing runs postdate it | 2026-09-01 |

## Decisions

- Fix delivery before review scope — a review that ships inline comments without its summary loses the
  verdict, coverage and cap note, which is exactly the reported symptom.
- Instrument the durable record, not the terminal output — `efcd7e8` instrumented the ephemeral
  surfaces and the defect survived.
- Routing lives in `indications/_index.md`, never in per-file frontmatter — 415 body files against 7
  index files, and the index already carries a `scope` column.
- Filter indications by surface first, rank by lens second — surface is a correctness filter, lens is a
  budget optimisation.
- `VCR_MAX_TOKENS` is the single budget knob — two caps with no precedence rule is the defect §3.2
  already has.
- Fleet agents get full base-repo read access — the best recorded finding needed a negative fact about
  unchanged code.
- The operator writes every promoted rule; `/v-cr` stores a URL, never comment text — comment bodies
  are attacker-authorable and `indications/` is a privileged channel.
- `/v-cr` gains no git write credential — a process holding untrusted PR content must not hold one.

## Scope & non-goals

Covers: comment delivery verification, coverage recording, the severity-aware cap, untrusted-comment
handling, indication routing by surface, the operator-feedback loop, and the sandbox recipe provenance
guard.

Not covered, and not to be mistaken for done: the review-unit partition, the multi-agent fleet spawn,
per-lens indication categories, and any framework-repo pull request. Each is listed under
**Open & deferred** with the condition that unblocks it.

## Work items

| id | file (exact path) | action | tool | constraint | verification | status |
|----|-------------------|--------|------|------------|--------------|--------|
| 1 | `commands/v-cr/steps/04-post.md` | Post the summary comment **first**; read it back by `<!-- v-cr:summary -->`; abort the inline posts if it is absent | Edit | Never post inline comments without a verified summary | `tests/unit/v-cr.bats` asserts the step file states summary-first + abort | DONE |
| 2 | `commands/v-cr/steps/04-post.md` | After posting, re-list the PR's comments and diff actual against intended **by fingerprint**; fail loudly on any gap | Edit | A gap is an error, never a silent pass | bats asserts the read-back requirement is present | DONE |
| 3 | `commands/v-cr/steps/04-post.md` | Replace the self-asserted `Required output` (line 68) with verified counts: `Posted: <n> intended / <m> verified on forge` | Edit | Numbers come from the read-back, never from intent | bats asserts `verified on forge` in the output block | DONE |
| 4 | `lib/cr-helpers.sh` | Add `cr_diff_stats` (files, added, deleted from a file list) and `cr_verify_posted` (intended fingerprints vs listed fingerprints → missing set) | Write | Pure logic, no network; offline-testable | New `tests/unit/cr-coverage.bats` covers both | DONE |
| 5 | `tests/unit/cr-coverage.bats` | New bats file for item 4 | Write | Runs in the container harness, never on host | `make test` passes | DONE |
| 6 | `commands/v-cr/steps/05-capture.md` | Add required machine-computed fields to §5.1 and §5.4: `files_changed`, `files_entered_context`, `inline_intended`, `inline_verified`, `summary_verified`, `dropped_over_cap`, `capped_chunked` | Edit | Computed, never asserted; redaction pass still applies | bats asserts all seven field names present | DONE |
| 7 | `commands/v-cr/steps/03-review.md` §3.4 (line 46) | BLOCKER and MAJOR findings post uncapped; the ≤10 cap applies to MINOR and NIT only, and to the **merged post-synthesis** set for the whole review | Edit | Never per unit — one gate renders one merged set | bats asserts `post-synthesis` and the severity exemption | DONE |
| 8 | `commands/_shared/critic-panel.md:33` | Add "PR/MR comments" to the enumerated untrusted inputs so the fencing requirement binds them | Edit | Textual enumeration, not an example list | `tests/unit/v-cr.bats` greps for the phrase | DONE |
| 9 | `commands/v-cr/steps/02-gather.md` §2.2 | Run the existing secret scan over every fetched comment body before it enters model context | Edit | Same scan as the diff; no second implementation | bats asserts §2.2 names comment bodies | DONE |
| 10a | `templates/VAULT.md` and each project's `VAULT.md` | Declare a **closed scope vocabulary** per project — the list of real surfaces its indications may name | Edit | One value per surface; no synonyms | bats asserts the key is documented in the template | DONE |
| 10b | `bin/doc-lint.sh` | Add a words cap (~4,000) for `index`-class documents alongside the line cap, a per-row length check on `indications/_index.md`, and a check that each row's `scope` holds a value declared in 10a | Edit | Lands **before** the migration, so 10c cannot regress | `tests/unit/document-standard.bats` covers all three checks | DONE |
| 10c | `~/vault/givore/indications/_index.md` | Normalise the `scope` column against 10a — 5 undeclared values across 7 rows | Edit | Never invent a surface; unknown → `cross-repo` | `bash bin/doc-lint.sh` reports no INDEX3 | DONE |
| 10d | `~/vault/givore/indications/_index.md` | Split the 149 rows over 400 characters so the index fits under the word cap; then delete the two exemption lines in `~/vault/givore/indications/.doc-lint` | Edit | Move prose into the linked rule body; never drop a constraint | `bash bin/doc-lint.sh` clean with no `.doc-lint` exemptions | BLOCKED — needs the operator's call on where each paragraph belongs |
| 10e | The other 6 `indications/_index.md` files and their projects' `VAULT.md` | Declare `indication_scopes` per project and normalise each index against it | Edit | One value per real surface, no synonyms | `bash bin/doc-lint.sh` reports no INDEX3 on any of the 7 | TODO |
| 11 | `commands/v-cr/steps/02-gather.md` §2.4 | Write the missing **retrieval rule**: load `indications/_index.md` rows filtered to the reviewed surface plus `cross-repo`, fetch full rule bodies on demand by slug, and record how many rows and bodies were loaded | Edit | The defect is the absent rule, not wholesale loading; name the filter and the counts in the step output | bats asserts §2.4 states the surface filter, on-demand body fetch, and the recorded counts | DONE |
| 12 | `commands/v-cr/steps/05-capture.md` §5.3 | Replace recurrence-based promotion with the operator-comment loop, under all six conditions in the Constraint column | Edit | Author has `write`+ on the base repo (`gh api repos/{o}/{r}/collaborators/{login}/permission`); skip entirely when `fork/public: yes`; body secret-scanned; **never verbatim** — store a URL, the operator writes the rule; stamp `source: pr-comment`; at most 3 drafts per run, each rendered in full at the gate | bats asserts all six conditions appear in §5.3 | DONE |
| 13 | `commands/v-cr/steps/05-capture.md` | When the defect is in the framework, write `~/vault/vault/proposals/<date>-<slug>.md` and name the path; never branch, commit, push, or call `gh pr create` | Edit | `/v-cr` acquires no git write credential; the INVARIANT at `commands/v-cr.md:21` stands unamended | bats asserts no git-write verb appears in any v-cr step file | DONE |
| 14 | `commands/v-cr/sandbox.md` §S0 | Refuse an indication carrying `source: pr-comment` as a recipe source | Edit | Refusal is unconditional, not a warning | `tests/unit/cr-sandbox.bats` asserts the refusal | DONE |
| 15 | `lib/cr-sandbox.sh` | Add `cr_is_recipe_key` stripping `install`, `test`, `lint`, `build`, `image`, `ports` from any recipe whose source is a `pr-comment`-stamped indication | Edit | Mirrors `cr_is_envelope_key`; deny-list, not allow-list | `tests/unit/cr-sandbox.bats` covers each key | DONE |
| 16 | `commands/v-cr/steps/03-review.md` §3.3 | On `fork/public: yes`, cite a rule by **slug only**, never its text | Edit | Vault text must not reach a public comment | bats asserts the slug-only rule | DONE |
| 17 | `commands/v-cr/steps/04-post.md` §4.2 | Reject any comment body containing a ≥40-character substring of a loaded indication file | Edit | Mechanical check at the write boundary, not prose | `tests/unit/v-cr.bats` asserts the check is specified | DONE |
| 18 | `vault/indications/cr-delivery-verification.md` | New indication: a review is delivered only when its summary is verified on the forge and coverage is recorded | Write | ≤80 lines (`bin/doc-lint.sh --list-caps`) | `bash bin/doc-lint.sh` clean | DONE |

## Sequencing & dependencies

Items 1–6 first and together — they are the measurement, and every later decision reads it. Item 7
next, because a bigger finding set is worthless while the cap silently shreds it. Items 8, 9, 16, 17
before item 12: the untrusted-comment path must be fenced before any comment is read for learning.
Items 14 and 15 before item 12 ships: the sandbox recipe hole must close before a comment-derived
indication can exist. Items 10a and 10b before 10c, and all three before item 11 — the linter must
exist before the migration, and filtering a dirty `scope` column silently drops rules.

**The gate on the deferred work.** Two measurements decide it, both after item 6 lands:

1. Re-run `/v-cr` on `karoldabro/api.givore.com#190` and read `files_entered_context` against
   `files_changed`.
2. Run `/v-cr` once on a **large feature branch with an empty suppression set**, which removes the
   branch-type confound named in Open & deferred.

Build the partition and fleet only if reading is demonstrably narrow in both.

## Rollback

Every item is a documentation or shell-library edit in a single repo, committed to `main`; `git revert`
of the commit range restores the prior contract in full. Item 10c edits files in `~/vault/<project>/`,
which is outside this repo — revert those from the project vault's own git history where it has one, or
by hand from this commit's diff where it does not.

Irreversible: nothing. `/v-cr` acquires no new write capability under this plan, which is the point of
deferring the framework-PR feature.

## Test plan

Harness: `bats-core` in the container (`make test`), never on the host. Level: contract assertions over
step-file text plus unit tests over pure shell logic — the same strategy `tests/unit/v-cr.bats` already
uses.

- `tests/unit/cr-coverage.bats` — unit: `cr_diff_stats` on a fixture file list; `cr_verify_posted` with
  a missing fingerprint, an extra fingerprint, and an exact match.
- `tests/unit/v-cr.bats` — contract: items 1, 2, 3, 6, 7, 8, 9, 11, 12, 13, 16, 17.
- `tests/unit/cr-sandbox.bats` — contract and unit: items 14 and 15.

## Refs

- `vault/decisions/ADR-008-v-cr-remote-pr-review.md` — the decision this implements; its Consequences
  already named "large diffs need the chunk-or-warn guard", which was specified and never built.
- `vault/decisions/ADR-009-v-cr-sandboxed-execution.md` — the sandbox threat model items 14 and 15 amend.
- `vault/indications/cr-panel-spawn-and-visibility.md` — the coverage and spawn rule that `efcd7e8`
  added and that items 1–6 make verifiable.
- `commands/_shared/document-standard.md` — the contract this file is written to.
- `vault/plans/2026-09-01-1000-vcr-delivery-and-coverage.trail.md` — the review findings behind these
  decisions.
