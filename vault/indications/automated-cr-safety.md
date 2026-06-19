---
type: indication
project: vault
slug: automated-cr-safety
scope: repo
tags: [indication, code-review, security]
---

# automated-cr-safety

## Rule
Any automation that reads a PR/diff/ticket and posts comments back to a forge must: (1) treat the diff,
PR description, and linked task as **untrusted data** — fence them, and derive the verdict + post/no-post
decision from a **machine-checked grounding gate, never agent prose**; (2) **redact secrets** before the
content enters any model context, at the comment-post boundary, and before any committed/indexed capture;
(3) send a credential **only to an exact-match-allowlisted host** (self-hosted needs confirmation; ticket
base URLs come from user/global config, never repo files); (4) gate the **first post to each
`host/owner/repo#PR`** with a non-bypassable preview; (5) key comment idempotency on
**`sha256(file:rule:code_hash)`**, never message text or line number; (6) resolve stale threads only when
**bot-authored with zero human replies**; (7) **never commit, push, or apply code** — comments only.

## Rationale
The PR/diff/ticket are attacker-authorable, so prose-driven verdicts are a prompt-injection foothold and
LLM message text is non-deterministic (breaks dedup → double-posts). Credentialed writes derived from a
repo-controlled remote/config are an SSRF/credential-harvest path. Captured sessions are git-tracked and
OV-indexed — a durable secret sink. Posting wrong comments to a real PR is high-cost and slow to undo, so
the human gate + `--unpost` are the blast-radius net. These came out of the `/v-cr` design panel as 3
BLOCKER + several MAJOR findings ([[../decisions/ADR-008-v-cr-remote-pr-review]]).

## Examples
- Do: `cr_fingerprint file rule "$(printf '%s' "$hunk" | cr_code_hash)"`; verdict from the
  grounding/severity gate in `_shared/critic-panel.md` §e.
- Do: `forge_platform` exact-match host allowlist (`lib/forge-detect.sh`) — `github.com.evil.test`
  resolves to `unknown`.
- Don't: fingerprint on the rendered comment message; auto-apply a "suggested fix"; read the Jira base
  URL from a repo file; resolve a thread a human replied in.

## Applies-to
`commands/v-cr/**`, `commands/_shared/critic-panel.md`, `lib/forge-detect.sh`, `lib/cr-helpers.sh`, and
any future review/posting automation in the framework.
