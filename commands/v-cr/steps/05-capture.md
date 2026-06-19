# Step 5 — CAPTURE

Record the review and let the vault learn from it — leak-safe.

## 5.1 What to record (and what NEVER to record) — sec-2
Capture **only finding metadata + posted comment ids**:
- target `host/owner/repo#PR`, adapter, task ref;
- per finding: `file:line`, severity, rule, grounding, disposition (posted / suppressed-duplicate /
  advisory-summary-only), and the posted comment id + fingerprint.

**Never write**: bearer tokens, request/response headers, raw diff hunks, or any secret-scanner-flagged
string. Run the redaction pass over the capture artifact **before** the session write **and** before the
mandatory OpenViking push — `vault/sessions/*.md` are git-tracked and OV-indexed, a durable shared sink.

## 5.2 Capture the session
Invoke `/v-capture` to write the session log (dedupe, index update, ADR-candidate extraction, Refs
cross-linking). The review record above is the session body.

## 5.3 Learned-convention promotion (the vault analogue of "org memory")
Hosted reviewers persist a learned DB that suppresses repeated nits. Our analogue is manual + auditable:
if the same finding recurs across reviews, or a reviewer-rule surfaced that should hold project-wide,
offer to promote it to the reviewed repo's `indications/` (gated by `behaviour.capture_indications`).
Future reviews load it via step 2.4 and the panel respects it — closing the loop without a hosted DB.

## 5.4 Completion report
```
Review: <host/owner/repo#PR>  ·  verdict: <…>
Findings: <n posted · m advisory · k suppressed>   ·   task alignment: <…>
Comments: <created/updated/resolved>
Vault: <session path>  ·  indications offered: <…>
Secrets: <none | N redacted from diff/comments/capture>
```
Mark CAPTURE `completed`.
