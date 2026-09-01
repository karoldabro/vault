# Step 4 — POST (dry-run gate)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

Write the comment set back to the forge — behind a non-bypassable preview gate, idempotently, leak-safe.

**INVARIANT: `/v-cr` never commits, pushes, or applies code.** It posts and resolves *comments* only.
Suggested fixes are advisory text. Any future committable-fix feature must re-enter the threat model
with its own gate (sec-6).

## 4.1 The dry-run gate — non-bypassable for the first post to a target (sec-4)
Render the **full comment set with exact bodies and exact targets**, not just counts. Echo the resolved
target `host/owner/repo#PR` and ask the user to confirm **this is the intended repo** (not a fork's
upstream, not a re-pointed remote). 

- The **first** post to any `host/owner/repo#PR` this session **always** prompts, even with `--post`.
- `--post` only skips *re-confirmation* for a target already confirmed this session.
- Refuse to exceed `--max-comments` without a fresh confirmation. **Severity buys no exemption here:**
  the BLOCKER/MAJOR findings that §3.4 exempts from the volume cap still count toward this limit, so a
  changeset carrying more must-fix findings than `--max-comments` prompts rather than posting silently.

If the user declines → stop; nothing is written. (The review is still captured in step 5.)

## 4.2 Redact at the write boundary (sec-2 / sec-5)
Run the secret-scan/redaction pass over **every comment body** immediately before posting. Enforce the
fork/public egress policy (step 3.3) here again. A bearer token, header, or flagged secret must never
leave in a comment.

**Vault-text check (`Fork/public: yes` only).** Step 3.3 states the slug-only rule as an instruction,
and an instruction is not a control — this is the check that catches a critic that quoted the rule
anyway:
```bash
source "$VAULT_FRAMEWORK_PATH/lib/cr-helpers.sh"
cr_vault_leak_check "$comment_body" $loaded_indication_files   # rc 0 clean · 1 leaked · 2 bad input
```
It reports `leak <rule file> <matched text>` when any 40-character run of a loaded rule's prose
appears verbatim in the body, matching across re-wrapped lines. **Drop or rewrite every flagged
comment; never post it.**

## 4.3 Fingerprint + idempotency (skeptic-2)
Each inline comment carries an HTML-comment marker the next run reads:
```
<!-- v-cr:fp=<cr_fingerprint file rule code_hash> -->
```
where the fingerprint is keyed on `sha256(file:rule:code_hash)` — **never the message text, never the
line number** — so it is stable across re-runs (LLM non-determinism) and survives rebases. Generate
comment text at temperature 0 for extra stability. The summary comment carries `<!-- v-cr:summary -->`.

On re-review (using the step-2.5 suppression set):
- **Skip** any finding whose fingerprint is already posted.
- **Update** the single sticky summary comment in place (find it by author == bot AND body contains
  `<!-- v-cr:summary -->`), don't add a second.

**Dynamic-finding exception (`--sandbox`, skeptic-5).** A finding tagged `runtime-observed` is
non-deterministic (it depends on the sandbox env), so the post-once-suppress-forever rule is relaxed for
**that class only**: mark its comment `<!-- v-cr:fp=… class=runtime -->` and, on a later run where it no
longer reproduces, **re-resolve** the thread (per §4.4's safe-resolve rules) instead of leaving a stale
"bug" comment. Static + LLM-class fingerprints (`sha256(file:rule:code_hash)`) are unchanged.

## 4.4 Resolve stale — only safe threads (skeptic-3)
A previously-posted finding that is no longer in the current set may be resolved — **only** when the
thread's first comment is bot-authored, carries a `v-cr` fingerprint, **and has zero human replies**.
If a human replied, leave it open and note "no longer flagged" in the summary instead. **Prefer resolve
over delete** (preserves the audit trail). Never touch a thread with non-bot participation.

## 4.5 Post via the adapter — summary FIRST, then the inline set
Use the adapter (`commands/v-cr/adapters/<platform>.md`): `gh` fast path for GitHub; REST for Bitbucket
(Cloud `inline:{path,to/from}`, Server `anchor:{path,line,lineType,fileType}`). Tokens via env / stdin /
`--netrc`, **never as a CLI argument** (process list / shell history; sec-8). Record each posted
comment's id + fingerprint for the capture step and for `--unpost`.

**Order is mandatory: post the summary comment first, read it back, and only then post the inline set.**

1. Post (or update) the summary comment.
2. Re-list the PR's comments and confirm one body contains `<!-- v-cr:summary -->`.
3. **If it is absent, abort — post no inline comments** and report the failure to the user.

**Why the order is fixed, not a preference:** the summary is the only carrier of the verdict, the
coverage line, the severity counts, the test-posture line and the over-cap note. Inline comments
without it are findings with no scope, no totals and no statement of what went unreviewed — the reader
cannot tell a precise review from a truncated one. A review that ships inline comments without its
summary is worse than no review, because it looks complete.

## 4.5a Read back what was written (delivery verification)
A post can fail — a rate limit, a dropped connection, a run that hits an execution limit mid-step. The
run must not be the witness to its own success.

After the inline set is posted:
```bash
source "$VAULT_FRAMEWORK_PATH/lib/cr-helpers.sh"
# intended: one fingerprint per line, the set this run meant to post
# actual:   fingerprints parsed from re-listing the PR's comments via the adapter
cr_verify_posted "$intended" "$actual"      # rc 0 = match; rc 1 = discrepancy; rc 2 = unreadable input
```
- `missing <fp>` — the run intended it and the forge does not have it. **Report it as a failure**, name
  each missing fingerprint and its `file:line`, and offer to retry those posts.
- `extra <fp>` — on the forge but not intended this run. Usually a prior run's comment; note it, never
  delete it.
- **rc 1 is an error, never a warning.** Never print a success line over a non-zero return.

Carry `intended`, `actual`, the missing set and the summary-verified flag into step 5 — they are the
fields `05-capture.md` §5.1 records.

## 4.6 `--unpost` (the undo / blast-radius net; skeptic-5)
`/v-cr --unpost` deletes/resolves every comment on the target carrying this tool's marker (matched by
`<!-- v-cr:fp= -->` / `<!-- v-cr:summary -->` and bot authorship). The first-class cleanup path when a
run posted noise.

## Required output
Every count below comes from the §4.5a read-back, never from what the run intended.
```
Target: <host/owner/repo#PR>   (confirmed: yes)
Summary: verified on forge (<created|updated>, id <n>)
Posted: <i> intended / <v> verified on forge   (k new, j skipped-as-duplicate)
Resolved stale: <r>   (left open due to human replies: <h>)
Secrets redacted in comments: <s>
```
**When `v` < `i`, or the summary is absent, this block is a failure report:** name each missing
fingerprint with its `file:line` and say the review was not fully delivered. Never print
`Summary: verified` without having re-listed the PR.

Mark POST `completed` **only when the summary was verified and `v` equals `i`.** Otherwise leave POST
open, report the gap, and offer to retry the missing posts — a step marked done on a short delivery is
the same self-asserted success §4.5a exists to stop.
