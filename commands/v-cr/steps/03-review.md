# Step 3 — REVIEW (panel)

Run the critic panel **once** over the gathered changeset and produce the comment set. Single pass — no
fixing (we don't own the code), no re-rounds (the PR is static). This step is a thin wrapper around the
shared module.

## 3.1 Run the shared panel
Read `~/.claude/commands/_shared/critic-panel.md` and execute it with these inputs:
- **changeset**: the secret-redacted diff + changed-file list (step 2.1–2.2);
- **analyzer output**: whatever the pack's analyzers produced (the module re-runs ground-first too);
- **acceptance criteria**: the fetched task (step 2.3) — critics check *does the diff satisfy the ticket*;
- **vault rules digest**: ADRs / indications / conventions (step 2.4) — critics respect project rules;
- **suppression set**: the prior `v-cr` fingerprints (step 2.5).

The module handles the untrusted-input fencing, critic selection (`_resolution.md`, incl. the
`correctness` bug-hunter lens + `skeptic` on high-risk diffs), parallel read-only spawn, the
grounding-gate verify (generate-then-verify), and de-biased synthesis. **The verdict and what is
postable come from that gate — never from a critic's prose.**

## 3.2 Large-diff guard (skeptic-8)
Before spawning, check diff size. Above the threshold (default ~1500 changed lines or >40 files), either
**chunk by file/hunk** with a per-chunk critic budget, or **warn and require `--force`**. Enforce a
per-review token ceiling (`VCR_MAX_TOKENS`, default ~200k) so cost is bounded and observable. Never
silently truncate — say what was and wasn't reviewed.

## 3.3 Egress policy for fork / public PRs (sec-5)
If step 1 flagged the PR head as a **fork / public**, comment bodies emitted here may contain ONLY:
finding + `file:line` + rationale + a quote limited to the **already-public diff hunk**. Never include
vault / `CLAUDE.md` content, file contents beyond the changed lines, or any secret-scanner-flagged
string. (The redaction pass in step 4 enforces this again at the write boundary.)

## 3.4 Volume cap (skeptic-5)
Cap the actionable inline set hard: **v0 default ≤10 inline comments + 1 summary**. If the panel
produced more confirmed findings, keep the highest-severity N and note the count dropped in the summary
(no silent truncation). `--max-comments <n>` raises it but requires re-confirmation at the gate.

## 3.5 Build the comment set
Assemble what step 4 will preview/post:
- **1 summary comment**: verdict, a files-changed table, counts by severity, task-alignment note
  (satisfied / gaps vs the ticket), and the advisory (summary-only) findings.
- **≤N inline comments**: each = `file:line` + severity + issue + advisory recommendation, each tagged
  with its fingerprint `cr_fingerprint <file> <rule> <code_hash>` (step 4 attaches the marker).

## Required output
```
Panel: <pack> → [critics]   (or GENERIC FALLBACK)
Confirmed actionable: <n> inline   ·   Advisory (summary-only): <m>
Suppressed (already posted): <k>
Task alignment: <satisfied | gaps: …>
Capped/chunked: <none | dropped j over cap | chunked into c>
```
Mark REVIEW `completed`, then proceed to the POST gate.
