# Step 4 — POST (dry-run gate)

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
- Refuse to exceed `--max-comments` without a fresh confirmation.

If the user declines → stop; nothing is written. (The review is still captured in step 5.)

## 4.2 Redact at the write boundary (sec-2 / sec-5)
Run the secret-scan/redaction pass over **every comment body** immediately before posting. Enforce the
fork/public egress policy (step 3.3) here again. A bearer token, header, or flagged secret must never
leave in a comment.

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

## 4.4 Resolve stale — only safe threads (skeptic-3)
A previously-posted finding that is no longer in the current set may be resolved — **only** when the
thread's first comment is bot-authored, carries a `v-cr` fingerprint, **and has zero human replies**.
If a human replied, leave it open and note "no longer flagged" in the summary instead. **Prefer resolve
over delete** (preserves the audit trail). Never touch a thread with non-bot participation.

## 4.5 Post via the adapter
Use the adapter (`commands/v-cr/adapters/<platform>.md`): `gh` fast path for GitHub; REST for Bitbucket
(Cloud `inline:{path,to/from}`, Server `anchor:{path,line,lineType,fileType}`). Tokens via env / stdin /
`--netrc`, **never as a CLI argument** (process list / shell history; sec-8). Record each posted
comment's id + fingerprint for the capture step and for `--unpost`.

## 4.6 `--unpost` (the undo / blast-radius net; skeptic-5)
`/v-cr --unpost` deletes/resolves every comment on the target carrying this tool's marker (matched by
`<!-- v-cr:fp= -->` / `<!-- v-cr:summary -->` and bot authorship). The first-class cleanup path when a
run posted noise.

## Required output
```
Target: <host/owner/repo#PR>   (confirmed: yes)
Posted: <n inline (k new, j skipped-as-duplicate)> + summary (created|updated)
Resolved stale: <r>   (left open due to human replies: <h>)
Secrets redacted in comments: <s>
```
Mark POST `completed`.
