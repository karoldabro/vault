---
type: indication
project: vault
slug: cr-delivery-verification
scope: repo
tags: [indication, v-cr, code-review, delivery]
---

# cr-delivery-verification

## Rule
A review counts as delivered only when the tool **read back** what it wrote and **recorded** what it
covered. Three requirements, all mandatory:

1. **Summary first, verified, then inline.** Post the summary comment, re-list the PR to confirm a body
   containing `<!-- v-cr:summary -->`, and abort the inline set if it is absent.
2. **Read back every post.** After posting, list the PR's comments and diff actual against intended by
   fingerprint (`cr_verify_posted`). A non-zero return is an error: name each missing fingerprint with
   its `file:line` and do not report success.
3. **Record coverage durably.** `files_changed`, `files_entered_context`, `inline_intended`,
   `inline_verified`, `summary_verified` and `dropped_over_cap` go in the captured session file, every
   value computed and none asserted.

Never print a count the run did not verify against the forge.

## Rationale
A run that is the sole witness to its own success cannot detect its own failure. One review posted 9
inline comments, lost its summary, and wrote "10 inline + 1 sticky summary" to the vault with a comment
id that returns 404 — the loss stayed invisible for two months because nothing re-read the PR.

The summary carries the verdict, the coverage line, the severity counts, the test-posture line and the
over-cap note. Inline comments without it are findings with no scope or totals, so the reader cannot
tell a precise review from a truncated one, and a sparse comment set reads as a shallow review.

Instrumenting only the comment body and the terminal output does not work: both die with a failed post
or a closed session. The durable record is the vault file.

## Examples
- Do: `Summary: verified on forge (created, id 12345)` then
  `Posted: 10 intended / 10 verified on forge` and
  `Coverage: read 523 of 523 files (50817 changed lines)`.
- Do: on a mismatch — `Posted: 10 intended / 9 verified on forge — MISSING a6476f225b9f16bb
  (database/migrations/2026_06_25_093000_...php:26)`, and leave POST incomplete.
- Don't: `Posted: <n> inline + summary (created)` asserted from what the run intended to do.
- Don't: post the inline set first, or post it at all when the summary did not land.

## Applies-to
`commands/v-cr/steps/04-post.md`, `commands/v-cr/steps/05-capture.md`, `lib/cr-helpers.sh`
(`cr_verify_posted`, `cr_diff_stats`), and any future command that writes review output to a forge.
