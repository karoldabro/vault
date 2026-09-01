---
type: process
topic: v-cr-review-quality
tags: [process, v-cr, code-review, quality, critic-panel]
---

# What `/v-cr` gets right, and the eight defects to fix

A `/v-cr` review of a 41-file, 3,269-insertion pull request produced 20 inline comments and one
summary. Independent re-verification against the same code confirmed 16 outright, found one wrong
sub-claim in each of the other four, and found no invented defect. Precision was the strength.
Eight mechanical defects cost accuracy or trust, and each has a fix at a named framework file.

## Fix list

| # | defect | fix at | status |
|---|---|---|---|
| 1 | The analyzer command passes the whole changed-file list as one shell word, so the tool errors and the "ground first" stage produces nothing | `commands/_shared/critic-panel.md` §(a) | PENDING |
| 2 | A critic reports a finding without reading the comment directly above the line, and recommends the change that comment forbids | `commands/_shared/critic-panel.md` §(d) | PENDING |
| 3 | Inline anchors are posted without checking the line exists in the file | `commands/v-cr/steps/04-post.md` | PENDING |
| 4 | A negative claim (`X has no callers`) posts on a grep the author never inverted | `commands/_shared/critic-panel.md` §(e) | PENDING |
| 5 | A hypothetical divergence posts as a live defect because no case was instantiated | `commands/_shared/critic-panel.md` §(e) | PENDING |
| 6 | Findings the critics rated MAJOR are filed in the summary as MINOR/NIT | `commands/v-cr/steps/03-review.md` §3.4 | PENDING |
| 7 | A confirmed project-rule violation is dropped while a documentation nit posts | `commands/v-cr/steps/03-review.md` §3.4 | PENDING |
| 8 | Posted comments run five to eight lines against a stated three-line ceiling | `commands/v-cr/steps/03-review.md` §3.5 | PENDING |
| 9 | A finding that names a contradiction between code and documentation picks a side, and picks the wrong one | `commands/_shared/critic-panel.md` §(d) | PENDING |

## What worked, and why to keep it

**The grounding gate suppressed a real false positive.** A critic reported that
`'App\\Http\\V2\\Requests\\'` differs from `'App\Http\V2\Requests\\'` and breaks class resolution. In a
PHP single-quoted string both spellings produce the same namespace. The gate dropped it, and no
comment was posted. This is the single most valuable behaviour in the command: an author who reads one
wrong comment discounts every later one.

**Every finding carried the command that produced it.** The finding schema in
`commands/_shared/critic-panel.md` §(d) requires a `check:` field, and re-verification could replay each
one. A count that states its denominator and its command is checkable by the reader; a count without one
is a claim.

**The summary named what was checked and found sound.** Listing the tenancy chain, the `$fillable`
absences and the `finally`-wrapped reset as verified told the author which surfaces need no second
look. Silence on a file is ambiguous; a named clearance is not.

**Blockers were separated by consequence, not by severity label.** All three led with what happens on
deploy — data loss — rather than with a category. The author can rank them without opening a file.

**Prior bot comments were adjudicated, not duplicated.** Two existing comments were evaluated, confirmed
in the summary, and left in their own threads. This is what keeps a second reviewer from doubling the
thread count.

**Exceptions were reported.** The summary and the session record both stated that no test ran and no
static analyser ran. A reader who does not know that will over-trust the result.

## Defect 1 — the analyzer stage silently produced nothing

The recorded analyzer output is a single error: the tool received the entire space-separated file list
as one path and reported it unreadable. No linter, type-checker or SAST signal entered the review. Every
finding was a human-style read of source.

`commands/_shared/critic-panel.md` §(a) calls analyzer output "the deterministic precision floor". A
stage that fails open removes the floor without removing the claim.

Fix: in §(a), require each analyzer to receive one file per argument or one file per invocation, and
require the step to record the analyzer's exit code. A non-zero exit is an exception the summary must
carry, phrased as *the analyser could not run*, never as *the analyser found nothing*.

## Defect 2 — the recommendation contradicted the code comment above the line

Two write sites omit a timestamp column. The comment three lines above each states that writing it would
invalidate work already queued on every client device. The finding described the omission accurately and
recommended writing the column.

The observation was worth posting; the recommendation would have caused the harm the author had already
avoided.

Fix: add to the finding schema in `commands/_shared/critic-panel.md` §(d):

```
counter_evidence: <the comment, test, or doc adjacent to the target that argues the current
                   behaviour is intentional — or "none found, searched <what>">
```

A finding whose `counter_evidence` is unread cannot carry a `recommendation`. It posts as an
observation.

## Defect 3 — an anchor pointed past the end of the file

One of 20 inline comments anchored to line 174 of a 162-line file. The forge accepted it, so the comment
landed detached from any code.

Fix: in `commands/v-cr/steps/04-post.md`, validate every anchor before the post gate renders. For each
comment, assert the path exists at the reviewed commit and the line number is within the file's length.
An anchor that fails becomes a file-level comment and the preview says so.

## Defects 4 and 5 — two claim shapes that need a stronger check

Both defects are the same mistake in different clothes: a claim was reasoned to, not instantiated.

**The negative-existence claim.** A comment stated a method has no callers. It has five, one of them a
repository the same review had already read. The grep that produced the claim searched a narrower term
than the claim asserted.

**The divergence claim.** A comment stated two code paths derive the same configuration key differently
and a model can therefore miss the registry. Both derivations produce identical keys for all three
tables the change touches. The mismatch is reachable only by a table name that does not exist.

Fix: extend the grounding gate in `commands/_shared/critic-panel.md` §(e) with two rules.

- A claim of the form *X has no callers / no tests / no usages* is `confirmed` only when the check
  searched the bare symbol name across the whole repository. Report the command and its hit count. A
  search narrower than the claim demotes the finding to `advisory`.
- A claim that two derivations diverge is `confirmed` only when the check names one existing input that
  produces two different outputs. Enumerate the real inputs. If every one agrees, the finding is
  `advisory` and must be worded as a latent risk.

## Defects 6 and 7 — severity is assigned twice and the second pass is unaccountable

The summary reported "19 smaller ones not posted" and labelled them MINOR/NIT. At least two carried
MAJOR from the critic that raised them: an API response contract missing two declared fields, and one
response field emitting two different datetime formats. Relabelling a finding downward at synthesis, with
no record, is indistinguishable from dropping it.

A confirmed violation of a named project rule was also dropped: a new authenticated write path records no
actor, no model event and no activity-log entry, against a rule the review had loaded. A documentation
inconsistency posted instead.

Fix: in `commands/v-cr/steps/03-review.md` §3.4, add two constraints.

- A finding keeps the severity its critic assigned. Synthesis may raise it; lowering it requires a
  one-line reason recorded beside the finding in the comment-set file.
- A `confirmed` finding that cites a project-rule slug is exempt from the volume cap, on the same footing
  as BLOCKER and MAJOR. Loading the rules and then dropping their violations wastes the load.

## Defect 8 — the length ceiling is stated and not enforced

`commands/v-cr/steps/03-review.md` §3.5 caps an inline comment at three lines: `file:line`, one sentence
of issue, one sentence of recommendation. The posted comments ran five to eight lines. They were
readable, and the extra lines carried the evidence that made them checkable.

The ceiling is wrong, not the comments. A three-line comment cannot hold a finding, its grounding command
and a recommendation, and a reader who cannot check the grounding discounts the finding.

Fix: rewrite the §3.5 inline template as four parts with a six-line ceiling — severity and `file:line`;
the issue in one sentence; the grounding check as a command or a quoted line; the recommendation in one
sentence. State that a comment exceeding six lines splits into a summary bullet and one inline comment.

## Defect 9 — a contradiction was resolved toward the document, not the design

One finding reported that a design document and a constant's docblock both say a certain input is
rejected, while no code path rejects it. It recommended adding the rejection. That rejection fails
fifteen tests, because the input is how every client expresses the endpoint's most common operation.
The document is the side that needs changing, and the full repair reaches further than either side of
the contradiction: a second field the code ignored has to be made load-bearing.

A code-versus-documentation contradiction is real and worth posting. Which side is wrong is a design
question the reviewer usually cannot settle from the diff.

Fix: in `commands/_shared/critic-panel.md` §(d), require a finding of this shape to state the
contradiction and the cost of each resolution, and to stop there. A `recommendation` that names one
side is permitted only when the check field shows the reviewer established which side the callers
depend on — for instance by counting the tests and call sites that assume each.

## Two figures worth reusing

**Twenty inline comments on 41 files was the right volume.** Sixteen held outright and none was invented.
The cap in `commands/v-cr/steps/03-review.md` §3.4 is 10 plus a BLOCKER/MAJOR exemption; this review
doubled it through the exemption and stayed accurate. The cap is not the control that matters. The
grounding gate is.

**A count in a comment must state its denominator.** "27 repositories use this trait" was literally true
and misleading: 23 of them call the affected method. The critic-panel schema already demands the command
behind a count. Extend it in `commands/_shared/critic-panel.md` §(d) to demand the population the count is
drawn from, whenever the count appears in an argument about blast radius.
