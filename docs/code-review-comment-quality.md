# What makes a posted review comment worth its cost

Binding on `/v-cr`. Each rule below is a check the review must pass before a comment is posted. A
comment that fails one is either rewritten or dropped.

A review comment costs the author's attention whether or not it is right. The rules split into two
groups: conventions that already earn that cost and must stay, and gaps that let a wrong or
mis-aimed comment through.

## Open work

Nothing in this file is enforced yet. `grep -c "novelty\|mutation\|Blast" commands/v-cr/steps/*.md`
returns 0 on all five step files, so every rule below is a document a reviewer never reads.

| item | file | status |
|---|---|---|
| Add N1–N14 as a pre-post checklist the review step must run per finding | `commands/v-cr/steps/03-review.md` | PENDING |
| Make the critic read existing PR comments before writing findings (N5) | `commands/v-cr/steps/02-gather.md` | PENDING |
| Reject a finding whose claim-type check (N8–N14) produced no citation | `commands/_shared/critic-panel.md` §(e) | PENDING |
| Require a named check beside every "verified correct" item (K3) | `commands/v-cr/steps/04-post.md` | PENDING |
| Drop the "N findings were dropped" line from the summary template | `commands/v-cr/steps/04-post.md` | PENDING |
| Re-render the sticky summary after any post that follows it (K9) | `commands/v-cr/steps/04-post.md` | PENDING |
| Fold the six rules in `~/vault/digitally-core/processes/code-review-comment-quality.md` into this file and reduce that one to project-specific evidence | both files | PENDING |

**Failure mode this table records:** a rule set with two homes and no enforcement point grows every
review and changes no review. `grounding: confirmed` in `commands/_shared/critic-panel.md` §(e) is
self-declared by the critic that raised the finding, so no independent check runs. That field is the
one place a claim-type gate can bite.

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
the diff, the finding text names it. Run `git diff <merge-base>..HEAD -- <file>`: an empty result
means the defect is pre-existing and the finding says so.

**Why it keeps firing:** on PR 3514 three findings prescribed a repair for one call site of a defect
that shape-repeats. A JSON-shape finding anchored `app/Services/Api/Batch/Actions/SaveMany.php`,
whose diff against the merge base is empty, and the same two lines sit in `UpdateMany.php:20-21` and
`DeleteMany.php:20-21`. A soft-delete finding on `app/Rules/SourceIdConflict.php` left the identical
blindness in the pre-existing `app/Rules/SourceIdNotExists.php:40-43`, and an id-disclosure finding
on the same file left `SourceIdNotExists.php:54` publishing the same id inside a message string for
every other v2 resource. Applied as written, each fix leaves the other resources exposed.

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

**Check:** enumerate every factual claim in the description and record a verdict for each. A claim
with no verdict is a coverage gap and belongs in the summary as one.

**Why it keeps firing:** on PR 3514 the summary adjudicated two of the description's three claims and
skipped the third — that the ported list carries "the store, deleted-row, stocktake, location,
department and delta filters". Deleting `app/Http/V2/Filters/StocktakeDetailFilter.php` removed the
named `filterStocktake`, `filterLocation` and `filterDepartment` methods with no replacement in
`app/Http/V2/Filters/Filter.php`; those columns survive only through the generic `f[]` shape, whose
allow-list `app/Services/Api/Filter/Filter.php:94` builds from `getFillable()`. A client sending the
named parameter is silently ignored.

### N8 — A framework or engine behaviour claim cites installed code or a pinned version

When a finding turns on what Laravel, the database, or a vendor package does, cite the installed
source or the pinned version. General knowledge of the platform is not evidence, because the
installed version decides the answer.

**Check:** the finding carries a `vendor/<pkg>/…:<line>` citation, or the version from
`composer.lock`, `docker-compose.yml` or `config/`.

**Why it fires:** it decides the verdict in both directions. A bulk-insert finding held only because
`vendor/laravel/framework/src/Illuminate/Database/Query/Grammars/Grammar.php:1197` takes the column
list from the first row and nothing normalizes the rest. A migration finding was wrong because the
reviewer applied pre-10.4 MariaDB rules to a project pinned at `mariadb:10.6.13` in
`docker-compose.yml:38`, where a column is added instantly in any position.

### N9 — A cost claim names the predicates already on the query

Before citing a table's row count, list every predicate the query already carries and say which are
indexed. The row count bounds the cost only when nothing narrows the scan.

**Check:** the finding names the scoping method and the index behind it, or states that none exists.

**Why it fires:** "two full passes over ~8.5M rows" described a query that
`Repository::applyCustomerScope` had already narrowed to one customer through a foreign-key index.
The missing index was worth fixing; the number attached to it was not the cost.

### N10 — A count is posted with every item enumerated

A finding that asserts N of anything — fields, callers, call sites, tests — lists all N with a
citation each. A collective count without the enumeration is not postable.

**Check:** item count in the finding text equals the citation count.

**Why it fires:** five separate findings miscounted. "Five fields state a floor and no ceiling" was
four, because `net_weight` carries `lte:full_weight`. "All three callers" was two. "Six `modules()`
call sites" was four, and understated the real reach. Two more named a colliding call site that used
a different method, and cited a line two off. Each error is what the author checks first.

### N11 — A NULL claim cites the column definition

A finding about NULL in a database column quotes that column's migration line before reasoning about
it. A `NOT NULL DEFAULT` column has no NULL rows to mishandle.

**Check:** `grep -rn "<column>" database/migrations/` and quote the definition.

**Why it fires:** the review's only outright wrong claim was that
`where('is_wastable', '=', false)` skips NULL rows.
`database/migrations/2022_07_02_151537_create_products_table.php:29` is
`$table->boolean('is_wastable')->default(0)` — not nullable, so the precondition does not exist.

### N12 — Separate "does not execute" from "does not assert"

Before claiming a path is unexercised, resolve what would suppress it: the queue driver, an event
fake, a mocked collaborator. Then say whether the gap is execution or assertion. They need different
repairs and carry different severity.

**Check:** name the `QUEUE_CONNECTION` value in `phpunit.xml`, and every `Event::fake` /
`Bus::fake` / `Queue::fake` in the test directory, before writing the claim.

**Why it fires:** "nothing anywhere exercises POST → SaveMany → FireEvent → listener" was wrong.
Eight `postJson` calls run that chain inline, because `phpunit.xml:19` sets `QUEUE_CONNECTION=sync`
and none of them fakes the event. What was missing was an assertion on the side effect.

### N13 — The prescribed fix is re-read against the code it lands in

Apply the recommendation in your head at the exact lines it names, then say what still fails. A fix
that trades one defect for another is worse than the finding alone, because the author acts on it.

**Check:** the finding names the call sites its fix changes and the case that survives it.

**Why it fires:** two recommendations would not have worked. Narrowing a `catch (\Throwable)` to
`SelectorException` breaks the request-less path the method's own docblock protects, because a
console run fails with a `TypeError` from a non-nullable constructor argument. Calling
`forgetCachedUserPermissions()` before `can()` clears the static for the checked user and then leaves
it holding that user's permissions for the rest of the request. The most severe case: a tenancy
finding offered two fixes, and both scoped a lookup to a customer id the attacker supplies in the
same payload, because the rule reads its customer from the request body rather than from the caller.

### N14 — A baseline must be an ancestor of HEAD

Any "unchanged on the base" or "pre-existing" comparison runs against the PR's merge base. Assert
it, do not assume it.

**Check:** `git merge-base --is-ancestor <baseline> HEAD` exits 0, and the baseline equals
`git merge-base HEAD <target-branch>`.

**Why it fires:** a Pint comparison cited `ac66ba6bbdc4`, a real commit on the target branch but
*ahead* of the branch point, so `--is-ancestor` fails against both HEAD and the merge base. The
"nothing new" conclusion rested on a tree the branch never contained.

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

### K9 — Re-render the summary after any post that follows it

When a later pass posts another thread, rewrite the sticky summary. Its coverage line and severity
counts are claims about the whole review, and a stale one misstates them.

**Check:** the summary's file and thread counts equal the posted set at the moment posting finishes.

**Cost:** one extra write per review. On PR 3514 a second pass added a thread on a thirteenth file
and the summary still read "inline on 12 · 36 silent".

### K10 — The severity table names its unit

The counts say what they count — threads, or points inside the summary. A table totalling more items
than there are comments reads as an error even when it reconciles.

**Why it fires:** PR 3514's table read `4 / 16 / 9`, totalling 29 against 21 posted comments. It is
correct: 20 threads plus 9 bullets that live in the summary body. Nothing said so.

## Conventions to remove

**The dropped-findings count.** A line saying that further small points were dropped is an
unverifiable claim that invites the author to ask for them. Post the finding or say nothing about it.

**Recommendations that restate the diff's own comments.** When the code already documents the
trade-off in a docblock, a comment repeating it as a finding adds nothing. Check the surrounding
comments before filing.
