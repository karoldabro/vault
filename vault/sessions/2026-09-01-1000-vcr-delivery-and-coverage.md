---
type: session
project: vault
date: 2026-09-01
topic: /v-cr comment delivery verification, coverage recording, and rule routing
files_touched:
  - commands/v-cr/steps/04-post.md
  - commands/v-cr/steps/05-capture.md
  - commands/v-cr/steps/03-review.md
  - commands/v-cr/steps/02-gather.md
  - commands/v-cr/sandbox.md
  - commands/_shared/critic-panel.md
  - lib/cr-helpers.sh
  - lib/cr-sandbox.sh
  - bin/doc-lint.sh
  - templates/VAULT.md
  - vault/indications/cr-delivery-verification.md
  - tests/unit/cr-coverage.bats
  - ~/vault/givore/VAULT.md
  - ~/vault/givore/indications/_index.md
decisions: []
tags: [session, v-cr, code-review, doc-lint, delivery]
---

# /v-cr comment delivery verification, coverage recording, and rule routing

## Goal
Find why `/v-cr` reviews only a few files of a large PR, and fix what the evidence actually shows.

## Did
- Measured the three recorded `/v-cr`-class runs: digitally-core PR #3237 (21 files, 6 findings incl. a
  cross-tenant IDOR), api.givore.com PR #190 (523 files / 50,817 lines, 9 comments), givore_app
  release/1.12.0 (442 files, 0 MAJOR).
- Queried the forge and found the reported symptom's cause: PR #190 has **9 inline comments and zero
  issue comments**, all 9 review wrappers empty, and the session's recorded summary id 4881350226
  returns 404. The operator confirmed the summary never reached them.
- Traced why commit `efcd7e8` (2026-06-19) did not fix the same complaint: it instrumented the posted
  comment body and the step's terminal output, both of which die with a failed post.
- Implemented delivery verification (`04-post.md` summary-first + read-back, `cr_verify_posted`) and
  durable coverage recording (`05-capture.md` seven-field block).
- Implemented `cr_diff_stats`, the measurement `03-review.md` §3.2's large-diff guard was written
  against and never had, and `cr_vault_leak_check`, the fork/public egress control §3.3 only stated.
- Closed the sandbox recipe hole: `cr_is_recipe_key` strips 22 executable keys from any
  `source: pr-comment` indication.
- Added `INDEX1/INDEX2/INDEX3` to `bin/doc-lint.sh` and declared givore's scope vocabulary.
- Ran a four-reviewer panel (architect, security, root-cause, then a diff reviewer). It found 8
  defects in the work, all fixed. Suite: 405 passing, 7 failing — byte-identical to the pre-change
  baseline. Commits `e9b8bfd` (framework, pushed) and `6e4d64e` (givore vault, local).

## Learned
- **`/v-cr` had no read-back.** `04-post.md`'s `Posted: <n> inline + summary (created|updated)` was a
  self-assertion, so two failed posts were recorded in the vault as delivered and stayed invisible for
  two months.
- **The large-diff guard had no implementation.** `lib/cr-helpers.sh` held four functions, none of
  which measured anything, so §3.2's chunk-or-warn threshold could never fire.
- **`doc-lint.sh` caps by lines, so a table row holding a paragraph is invisible.**
  `~/vault/givore/indications/_index.md` passed at "235 lines, cap 400" while holding 16,813 words
  across 149 rows over 400 characters.
- **The scope column is not at a fixed position.** Of seven project indexes, givore has it first,
  mistflare third, and five have no scope column at all — a hardcoded field number reads the slug
  column and flags every row.
- **An indication outranks every other sandbox recipe source** (`lib/cr-sandbox.sh:116`) and
  `cr_is_envelope_key` never stripped `install`/`test`, so a rule learned from a PR comment could have
  chosen the command run during the networked install phase.
- **A negated-class regex that excludes `-` exempts every bullet.** The anti-git-write test used
  `^[^#|>-]*` and passed against a planted `git push`; nearly every instruction in these files is a
  bullet.
- The evidence cannot yet say whether `/v-cr` under-reads large diffs: no run records
  `files_entered_context`, and branch type is an unexcluded confound — both low-yield runs reviewed
  release aggregations of already-reviewed code.

## Behaviors & rules
- A summary comment fails to post → abort the inline set and report the failure; edge: the summary is
  the only carrier of verdict, coverage and cap notes, so inline comments alone read as a complete
  review.
- Posting finishes → re-list the PR and diff actual against intended by fingerprint; a gap marks POST
  failed, never completed.
- A changed-file list reaches `cr_diff_stats` → counts come from the last two fields; edge: a path
  containing a tab shifts the fields and silently drops the file and its lines.
- A finding is BLOCKER or MAJOR → it posts regardless of the volume cap, but still counts toward
  `--max-comments` so the preview gate fires.
- The target is a fork or public PR → cite a rule by slug only, and reject any comment body carrying a
  40-character run of a loaded rule's prose.
- An indication carries `source: pr-comment` → strip every executable recipe key before merging; edge:
  if nothing survives, treat the source as absent and fall through.
- An index has no `scope` column → load every row and say so; edge: five of seven projects are in this
  state, so a "load nothing" fallback strips all project rules.

## Next
- Re-run `/v-cr` on `karoldabro/api.givore.com#190` and read `files_entered_context` against
  `files_changed` — this is the gate on the deferred partition-and-fleet work.
- Run `/v-cr` once on a large feature branch with an empty suppression set to remove the branch-type
  confound.
- Split givore's 149 over-long index rows, then delete the two exemption lines in
  `~/vault/givore/indications/.doc-lint`.
- Declare `indication_scopes` in the other six project vaults.
- Push `~/vault/givore` commit `6e4d64e` when the concurrent givore session has landed its own work.

## Refs
- [[../plans/2026-09-01-1000-vcr-delivery-and-coverage]] — the plan this executed, with open items.
- [[../plans/2026-09-01-1000-vcr-delivery-and-coverage.trail]] — the reviewer findings and the
  reversed diagnosis.
- [[../indications/cr-delivery-verification]] — the rule this session established.
- [[../indications/cr-panel-spawn-and-visibility]] — the coverage rule `efcd7e8` added, now verifiable.
- [[../decisions/ADR-008-v-cr-remote-pr-review]] — predicted this in its Consequences: "large diffs
  need the chunk-or-warn guard".
- [[../decisions/ADR-009-v-cr-sandboxed-execution]] — the threat model the recipe-key strip amends.
- [[2026-06-19-1605-v-cr-panel-spawn-coverage-brevity]] — the earlier attempt at this same symptom.
