# What makes a posted review comment worth its cost

Binding on `/v-cr`. Each rule below is a check the review must pass before a comment is posted. A
comment that fails one is either rewritten or dropped.

A review comment costs the author's attention whether or not it is right. The rules split into two
groups: conventions that already earn that cost and must stay, and gaps that let a wrong or
mis-aimed comment through.

## Open work

| item | file | status |
|---|---|---|
| Add the novelty check to the review step | `commands/v-cr/steps/03-review.md` | PENDING |
| Add the mutation gate for "untested" and "cannot fail" claims | `commands/v-cr/steps/03-review.md` | PENDING |
| Make the critic read existing PR comments before writing findings | `commands/v-cr/steps/02-gather.md` | PENDING |
| Require a named check beside every "verified correct" item | `commands/v-cr/steps/04-post.md` | PENDING |
| Drop the "N findings were dropped" line from the summary template | `commands/v-cr/steps/04-post.md` | PENDING |

## Rules to add

### N1 — Novelty check: a shape with no precedent in the repo is a finding

For every new public shape the diff introduces — a method on a framework base class, a new service
seam, a new response envelope — grep the repository for another instance. Zero other instances makes
it a finding, even when the code is correct.

**Check:** `grep -rn "<shape>" app/` returns only the diff's own file.

**Why it fires:** correctness review and rule-violation review both pass code that is simply unlike
the rest of the codebase. The author reads that code as a new pattern they now have to maintain, and
raises it themselves. A reviewer that never raises it is reviewing lines, not the codebase.

**Cost:** the check produces false positives on the first instance of a deliberate new pattern. Post
it as a question about precedent, never as a defect.

### N2 — Blast radius: name the effect on the pre-existing caller

When a defect sits in code that a new surface and an existing caller both reach, the finding states
what happens to the existing caller. A finding written only against the new surface understates the
severity and lets the author schedule it behind the release.

**Check:** for the file and line of every must-fix finding, list the callers. If any caller predates
the diff, the finding text names it.

### N3 — Symptom against cause: the finding is the defect, not the display

When a wrong value on a screen is produced by a behavioural defect underneath, the defect is the
finding and the screen is its consequence. A recommendation that changes only the label leaves the
behaviour in production and closes the thread.

**Check:** a finding about rendered output states whether the underlying value is correct. If it is
not, the finding is filed against the code that produces it.

### N4 — Prove untestedness by mutation

A claim that a gate is untested, or that an assertion cannot fail, is posted only after the mutation
was run: delete the gate or flip the asserted value, run the affected test file, and quote the
result. Without that run the claim is an advisory labelled unverified.

**Check:** the comment carries the command and its output line, for example
`removed ->can() from both routes; 13/13 still green`.

**Why it fires:** these two claims read as facts and are acted on directly — the author deletes an
assertion or writes a test. Both are cheap to prove and expensive to get wrong.

### N5 — Read the existing comments first

Fetch the PR's existing comments before writing findings. A finding that duplicates a bot or a human
comment already on the diff is dropped, and the summary states the overlap.

**Check:** the review's gather step stores the existing comment list, and no posted finding shares
an anchor line with an existing comment.

### N6 — Review the authorization design, not only its implementation

When a diff adds an access-controlled surface, check three things separately: the gate is present on
every entry point, the gate cannot be granted by the people it excludes, and the gate is the
mechanism the project uses elsewhere for that class of surface. An implementation can pass the first
check and fail the other two.

**Check:** for each permission or role the diff relies on, find the endpoint that grants it and
confirm the grant is scoped to the caller's own tenant.

### N7 — Verify the security claims in the PR description

A PR description that explains why an authorization design is safe is a claim to test, not context
to inherit. Re-derive each claim from the source before repeating it in the summary or in the
verified list.

## Conventions to keep

### K1 — One anchor, one mechanism

Every inline comment carries a file path, a line, the mechanism that produces the failure, and the
edit that fixes it. A finding that names a category without a mechanism cannot be acted on or
disputed.

### K2 — Severity tiers with a count per tier

The summary opens with the count at each tier, and each inline comment repeats its own tier. The
author decides what to fix before reading any of them.

**Cost:** a tier is a place to hide. A defect that reaches production must not be filed as small
because the must-fix count is already high. Tier on consequence, never on effort.

### K3 — A verified-correct list, with the check beside each item

List what was examined and found sound, so the next reviewer does not re-raise it. Each item names
the check that settled it. Without the check the list suppresses a real re-review on the reviewer's
word alone.

### K4 — A coverage ledger in the summary

State how many changed files were reviewed, how many carried findings, and which were not examined
and why. This is the only line that lets the author judge whether silence on a file means anything.

Keep the ledger in the summary only. Repeating it per comment costs tokens and tells the author
nothing new.

### K5 — Declare what was not run

Say plainly when tests, static analysis or the application itself were not executed. Every finding
in that review is then read as static reasoning, which is what it is.

### K6 — Label an unverified claim as unverified

A finding the reviewer could not trace end to end is posted as an advisory that says so, or not at
all. Labelling costs one clause and preserves the credibility of every other finding.

### K7 — Cite the project rule by name

When a finding is a violation of a project rule, name the rule file. The author checks the rule
rather than the reviewer's paraphrase, and a rule that no longer holds gets deleted instead of
enforced.

### K8 — One fingerprint per comment

Each posted comment carries a stable hash of its anchor and claim, so a later run on the same PR
recognises its own comments and does not repost them.

## Conventions to remove

**The dropped-findings count.** A line saying that further small points were dropped is an
unverifiable claim that invites the author to ask for them. Post the finding or say nothing about it.

**Recommendations that restate the diff's own comments.** When the code already documents the
trade-off in a docblock, a comment repeating it as a finding adds nothing. Check the surrounding
comments before filing.
