---
type: decision
project: vault
id: ADR-008
status: accepted
scope: repo
tags: [adr, code-review, v-cr]
---

# ADR-008 — /v-cr reviews remote PRs by reusing the panel, single-pass, precision-first, treating PR input as untrusted

## Context
We want an automated code-review command that auto-detects the forge (GitHub / GitLab / Atlassian),
deploys an agent swarm, and posts review comments back — context-aware from the vault and the task in
the PR description. Research into the 2026 state of the art (CodeRabbit, Greptile, Qodo Merge / PR-Agent,
GitHub Copilot review, Graphite, Cursor Bugbot, Sourcery, Bito, Ellipsis, Korbit, Codacy, Gemini) shows
a converged reference design: webhook/CLI trigger → deterministic linters as a precision floor →
multi-step / multi-agent generate-then-verify pipeline grounded on repo context + config-as-code rules +
linked-issue context → precision-first output (confidence/severity gates, "say nothing when unsure") →
inline comments + a sticky summary, learned suppression of repeat nits.

That generate-then-verify panel is essentially what `/v-team`'s diff-review loop already does — **but**
v-team's loop *fixes code and re-rounds*, which is incoherent against a static remote PR the reviewer
does not own. A 3-critic design panel (Architect, Skeptic, Security) reviewed the v-cr design; Security
returned BLOCK with three confirmed blockers (prompt injection, secret leakage into the committed +
OV-indexed session, SSRF/credential-harvest), and Architect+Skeptic returned REQUEST_CHANGES (false loop
reuse, local-checkout assumption, message-keyed fingerprint, task-regex false positives, single coarse
gate). See `vault/plans/2026-06-19-1106-v-cr-command.md` for the full critique trail.

## Decision
Build `/v-cr` as a thin dispatcher + 5 steps (DETECT → GATHER → REVIEW → POST → CAPTURE):

1. **Reuse the panel sub-procedure, not the v-team lifecycle.** Extract the single-pass
   *ground → select → generate → grounding-gate verify → synthesize* into `commands/_shared/critic-panel.md`,
   shared by `/v-cr` (runs it once) and `/v-team` §5.3 (wraps it in its own fix-and-reloop). No
   between-round fixes, no re-rounds in v-cr.
2. **Single-pass, precision-first.** The grounding gate is the confidence filter: only `confirmed`
   findings ≥ `min_severity` post as inline comments; advisory is summary-only or dropped. Hard volume
   cap (v0 ≤10 inline + 1 summary). Output = sticky summary comment + deduplicated inline comments.
3. **Treat the diff / PR description / linked task as UNTRUSTED.** Fence them as labelled data, never
   instructions; the verdict and post/no-post decision come from the machine-checked grounding gate,
   never agent prose.
4. **Secret redaction at both boundaries.** Scan + redact the diff before it enters any model context,
   and comment bodies + the captured session before write/OV-push. Never persist tokens, headers, or raw
   diff hunks.
5. **Host-scoped credentials.** A token goes only to an exact-match-allowlisted host (self-hosted needs
   one-time confirmation); Jira/Asana base config comes from user/global config, never repo files.
6. **Non-bypassable first-post gate.** The first post to any `host/owner/repo#PR` always previews exact
   bodies + target and requires confirmation; `--post` only skips re-confirmation thereafter. `--unpost`
   is a first-class cleanup path.
7. **Stable idempotency.** Fingerprint = `sha256(file:rule:code_hash)` (never message text, never line
   number); resolve stale threads only when bot-authored with zero human replies.
8. **Decouple PR identity from the local checkout.** Resolve the PR + the vault/persona pack from the
   forge's base-repo identity; run local-only context layers (graph/Serena/CLAUDE.md) only when local
   HEAD matches; fail loudly (not silently) when no pack resolves.
9. **INVARIANT: never commit, push, or apply code.** Comments only; suggested fixes are advisory text.

v0 scope: forges GitHub + Bitbucket (Cloud + Server); task sources PR description + Jira + Asana + native
issues. GitLab, webhook/CI triggers, whole-repo RAG, and auto-suppression are deferred (the adapter
contract is forge-agnostic so GitLab slots in later).

## Consequences
- **Easier:** one panel definition serves both authoring (v-team) and review (v-cr); adding a forge =
  one `adapters/<forge>.md`; the security posture is explicit and testable (`tests/unit/forge-detect.bats`,
  `tests/unit/v-cr.bats`).
- **Harder / watch for:** prompt injection can never be fully prevented — the mandatory human POST gate
  is the backstop, keep it. No whole-repo RAG yet, so grounding is diff + vault + (optional) graphify;
  don't claim parity with hosted tools. Learned suppression is manual (vault `indications/`), not a
  hosted DB. Large diffs need the chunk-or-warn guard to keep precision and cost bounded.
- **Coupling:** `/v-cr` depends on `_shared/critic-panel.md`, `personas/_resolution.md`, and the vault
  context loader — pinned here as the contract, not on the v-work/v-team lifecycles.

## Cross-repo impact
None (framework-internal). Consumers gain a new `/v-cr` slash command after the next `install.sh` run.
Relates to [[ADR-001-panel-loop-over-peer-debate]] (panel > debate), [[ADR-002-no-stop-on-approval-alone]],
and [[ADR-003-tool-grounded-findings]] (the grounding gate this reuses as its confidence filter).
