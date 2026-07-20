---
type: plan
status: proposed
session: team-presentation-vault-commands
date: 2026-07-20
tags: [presentation, onboarding, v-work, v-team, v-ask, v-do]
---

# Plan — coworker presentation: the vault + /v-ask /v-do /v-work /v-team

Deliverable: a short, simple-language, humanized slide deck introducing the vault memory stack to
coworkers who use Claude Code but haven't seen it.

## Format (v2)

- **7-slide HTML deck**, published as a private Artifact link (presentable + shareable), source
  committed to this repo.
- Voice rules (binding): no source-doc jargon on any slide — lifecycle, capture, approval gate,
  context, tokens, convergence, ADR, dedupe, MOC, orchestration, persona-critique. Use the glossary
  in the critique trail. No AI-marketing words (seamless, empower, supercharge, leverage).

## Outline (v2, converged)

1. **The problem** — every AI chat starts from zero: you re-explain the project, decisions evaporate.
   Closing teaser: *"We gave our AI a memory. Here's how."*
2. **The vault** — a folder of plain-text notes living in the project repo. The AI reads it before
   working and writes to it after. **You never maintain the notes by hand — the AI does.** And because
   it's in the repo, the whole team's AI shares one memory.
3. **See it once** — a single `/v-ask` moment (ask about the repo → answer grounded in the team's
   notes → nothing changed). Grounds the command menu before the menu appears.
4. **Four commands, two questions** —
   *Just asking?* → `/v-ask` (only looks, never changes anything).
   *Making a change?* small → `/v-do` (no fuss; note: doesn't save notes unless you ask) ·
   normal → `/v-work` (asks you before doing anything, saves what it learned after; auto-detects
   small jobs and skips the ceremony itself) ·
   big or risky → `/v-team` (a panel of AI critics argues about the plan first — and drafts the
   test plan; ~2× the cost, for decisions that are expensive to undo).
5. **The memory moment** — worked example across two sessions: Tuesday's session decides X;
   Thursday's session already knows X and builds on it. Recall made visible.
6. **Why bother** — less re-explaining (the AI reads roughly 100× less to find a past decision —
   measured ~96% less on this repo by our memory plugin); decisions survive; a new teammate's AI
   starts already knowing the project.
7. **Start today** — already set up on our repos; nothing to install. One habit swap: *next time
   you'd ask Claude about the repo, type `/v-ask`.*

## Critique trail — round 1 (3 critics, fallback panel: no persona pack resolves for this docs repo)

Panel: accuracy (tool-grounded vs command docs) · audience-clarity · simplicity/humanizer.
Convergence: round 1, **no blocking findings open** — every blocker resolved by direct incorporation;
no inter-critic conflicts, so no round 2 (no-new-blocking-findings guard).

| # | Critic | Sev | Finding | Disposition |
|---|--------|-----|---------|-------------|
| S1 | simplicity | BLOCK | "token savings" meaningless to audience | Accepted — reframed in human terms; word "token" banned from slides (slide 6) |
| S2 | simplicity | BLOCK | source-doc jargon must not reach slides | Accepted — binding voice rule + glossary adopted |
| A1 | audience | BLOCK | "do I maintain the notes?" fear unaddressed | Accepted — slide 2 states the AI writes the notes |
| A2 | audience | BLOCK | payoff arrives too late | Accepted — teaser at end of slide 1 |
| A3 | audience | BLOCK | 96% as headline is abstract/trust-risky | Accepted — human benefit leads, number demoted to support with its source named |
| C1 | accuracy | ADV | 96% unsourced in docs (docs say ~100x / 100–2000 vs 20k tok) | Partially accepted — number IS measured (claude-mem session stats, this repo), not fabricated; slide cites both "~100×" doc framing and "measured here" |
| C2 | accuracy | ADV | /v-do capture-off-by-default omitted | Accepted — parenthetical on slide 4 |
| C3 | accuracy | ADV | /v-work small-job fast-path omitted | Accepted — parenthetical on slide 4 |
| C4 | accuracy | ADV | /v-team also authors test plans | Accepted — added to slide 4's /v-team line |
| A4 | audience | ADV | "pick by size" wrong axis (/v-ask isn't a size) | Accepted — two-question decision tree (slide 4) |
| A5 | audience | ADV | example must show recall across sessions, not a feature tour | Accepted — slide 5 spans two sessions |
| A6 | audience | ADV | 4 new commands before any demo | Accepted — new slide 3 shows one command first |
| A7 | audience | ADV | setup ambiguity on closing slide | Accepted — "already set up; nothing to install" |
| A8 | audience | ADV | vague call to action | Accepted — single habit swap CTA |
| A9 | audience | ADV | shared-team-memory undersold | Accepted — surfaced on slide 2 + slide 6 |
| A10 | audience | ADV | "~10 slides" invites padding | Accepted — committed to 7 |
| S3–S6 | simplicity | ADV | rule-of-three ok; markdown/git wording; "read-only" wording; "no ceremony" | Accepted — "plain-text notes", "only looks, never changes anything", "no fuss" |

Glossary (binding for EXECUTE): lifecycle→show the steps · approval gate→"asks you before doing
anything" · capture→"saves what it learned" · tokens→"how much it reads" · convergence→"until they
agree" · ADR→"why we chose this" · dedupe→"checks it hasn't already written it down" · MOC→"index".

## Critique trail — EXECUTE diff-review round 1 (same 3 critics, review posture)

Deck implemented at `docs/vault-intro-deck.html`, published as private Artifact. Verdicts:
**accuracy APPROVE_WITH_NITS · audience APPROVE_WITH_NITS · simplicity APPROVE_WITH_NITS** —
zero blocking findings → convergence after round 1 (no-new-confirmed-blocker guard).

All round-1 plan recommendations verified honored by their owning critics (citations in transcripts).
Nit dispositions:

| Critic | Nit | Disposition |
|--------|-----|-------------|
| accuracy | "in the repo" glosses global-vault mode | Skipped — acceptable simplification for intro (critic's own assessment) |
| accuracy | slide 2 blanket "reads before/updates after" | Skipped — slide 4 carries the per-command nuance |
| audience + simplicity | slide 6 stacks 100× and 96% (magnitudes don't reconcile) | **Fixed** — single sourced claim: "a fraction of the reading — measured ~96% less on this repo" |
| audience | v-work fast-path aside muddies the decision tree (conflicts w/ accuracy C3 keep) | **Fixed** — reframed as decision aid: "Not sure it's small? Pick this — it spots small jobs…" (keeps the fact, serves the choice) |
| audience | slide 5 Stripe/Adyen sounds /v-team-sized but attributed to /v-work | **Fixed** — example rescaled to CSV-vs-Excel export choice |
| simplicity | "repo/repos" mild jargon | Skipped — audience is developers using Claude Code |

## Test plan (deliverable checks, in place of code tests)

1. Jargon sweep: none of the banned words appear in slide text.
2. Accuracy spot-check: slide 4 claims match commands/v-{ask,do,work}.md + v-team.md.
3. Deck is self-contained (no external assets), renders in light + dark.
4. Slide count = 7; every slide ≤ ~40 words of body text.
