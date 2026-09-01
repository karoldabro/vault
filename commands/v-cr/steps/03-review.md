# Step 3 — REVIEW (panel)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

Run the critic panel **once** over the gathered changeset and produce the comment set. Single pass — no
fixing (we don't own the code), no re-rounds (the PR is static). This step is a thin wrapper around the
shared module.

## 3.1 Run the shared panel
Read `$VAULT_FRAMEWORK_PATH/commands/_shared/critic-panel.md` and execute it with these inputs:
- **changeset**: the secret-redacted diff + changed-file list (step 2.1–2.2);
- **analyzer output**: whatever the pack's analyzers produced (the module re-runs ground-first too);
- **acceptance criteria**: the fetched task (step 2.3) — critics check *does the diff satisfy the ticket*;
- **vault rules digest**: ADRs / indications / conventions (step 2.4) — critics respect project rules;
- **suppression set**: the prior `v-cr` fingerprints (step 2.5).

The module handles the untrusted-input fencing, critic selection (`_resolution.md`, incl. the
`correctness` bug-hunter lens + `skeptic` on high-risk diffs), parallel read-only spawn, the
grounding-gate verify (generate-then-verify), and de-biased synthesis. **The verdict and what is
postable come from that gate — never from a critic's prose.**

**Under `--sandbox`**, also pass the **dynamic-evidence bundle** from step 2.6 as the panel's optional
input (static analyzers = deterministic precision floor; diff-coverage; test results; runtime
reproduction). Two specifics:
- If the test gate returned **`new-failure` (blocking)**, the headline finding is the failing test —
  emit that as the summary verdict and **skip the deep panel** (the user's "tests fail → fail"); a
  `red-unattributed` gate is an **advisory** summary note, not a block.
- A **runtime/repro finding** is postable only when reproduced N times (default 2); tag it
  `runtime-observed` so step 4 ages it correctly. Static-analyzer findings are confirmed as usual.

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

**Cite a project rule by slug, never by its text.** Critics hold indication rows and rule bodies from
§2.4, so the natural way to justify a finding is to quote the rule it breaks — which publishes private
vault content to a public PR. On a `Fork/public: yes` target write `violates <indication-slug>`, and put
the reasoning in your own words about the changed lines. On a private target the rule text may appear.

## 3.4 Volume cap (skeptic-5)
Cap the actionable inline set: **v0 default ≤10 inline comments + 1 summary**, with one exemption and
one scope rule.

- **BLOCKER and MAJOR findings are exempt from the cap.** Every confirmed one posts. The cap applies to
  MINOR and NIT only. A cap that can silently withhold a must-fix finding is a defect, not a budget:
  the reader has no way to tell "nothing serious found" from "the serious one ranked eleventh".
  **The exemption does not bypass the gate.** Exempt findings still count toward `--max-comments`, so a
  changeset with more must-fix findings than that limit still triggers §4.1's fresh confirmation before
  anything is written. The exemption decides what may be *dropped*; the gate decides what may be
  *posted*, and the operator's preview stays the injection backstop either way.
- **The cap applies to the merged post-synthesis set for the whole review — never per critic, per file,
  or per review unit.** One review produces one capped set and one gate. A per-unit cap multiplies into
  a preview no operator can read, and the preview is the only injection backstop `/v-cr` has (ADR-008).
- Over the cap on MINOR/NIT: keep the highest-severity N and state the dropped count in the summary
  (no silent truncation). `--max-comments <n>` raises it but requires re-confirmation at the gate.

## 3.5 Build the comment set
Assemble what step 4 will preview/post. **Be short, concise, precise** — brevity is a hard rule, not a
preference.

> This rule is **deliberately local and is not superseded** by `_shared/communication.md`. These
> comments are posted to the forge and read by the PR author and reviewers — a different audience
> with a different reader model. The shared contract's "outward-facing text" section defers here.
> Do not delete this as a duplicate.
- **1 summary comment**, terse, in this order:
  - `verdict`;
  - **coverage line (mandatory)** — `Reviewed <N> files · inline on <M> · <N−M> silent (no confirmed
    findings)`, so sparse comments read as *deliberate precision*, not missed files;
  - **test-posture line (mandatory)** — without `--sandbox`: `Tests: not executed (static review only —
    re-run with --sandbox to gate on tests)`; with `--sandbox`: `Tests: <pass | new-failure | red-unattributed>`;
  - counts by severity + a files-changed table;
  - task-alignment note (satisfied / gaps vs the ticket);
  - ≤3 advisory (summary-only) bullets — drop the rest, don't pad.
- **≤N inline comments**, each **≤3 lines**: `file:line` + severity + `issue` (one sentence) +
  `recommendation` (one sentence, advisory). Never restate the diff or re-explain the surrounding code.
  Each tagged with its fingerprint `cr_fingerprint <file> <rule> <code_hash>` (step 4 attaches the marker).

## Required output
```
Panel: <pack> → [critics]   (or GENERIC FALLBACK)
Spawned: [<persona> → <base_agent>, …]   # actual Agent calls — MUST match [critics]; if empty, the panel did not run
Coverage: reviewed <N> files · inline on <M> · <N−M> silent (no confirmed findings)
Tests: <not executed (static review only) | pass | new-failure | red-unattributed>
Confirmed actionable: <n> inline   ·   Advisory (summary-only): <m>
Suppressed (already posted): <k>
Task alignment: <satisfied | gaps: …>
Capped/chunked: <none | dropped j over cap | chunked into c>
```
Mark REVIEW `completed`, then proceed to the POST gate.
