---
type: plan
status: executed
session: team-presentation-vault-commands
process_record: 2026-07-20-1030-team-presentation-vault-commands.trail.md
date: 2026-07-20
tags: [presentation, onboarding, v-work, v-team, v-ask, v-do]
---

# Plan — coworker presentation: the vault + /v-ask /v-do /v-work /v-team

Deliverable: a short, simple-language, humanized slide deck introducing the vault memory stack to
coworkers who use Claude Code but haven't seen it. It is implemented at
`docs/vault-intro-deck.html` and published as a private Artifact link.

## Format

- **8-slide HTML deck**, published as a private Artifact link (presentable + shareable), source
  committed to this repo at `docs/vault-intro-deck.html`.
- Voice rules (binding): no source-doc jargon on any slide — lifecycle, capture, approval gate,
  context, tokens, convergence, ADR, dedupe, MOC, orchestration, persona-critique. Use the glossary
  under `## Glossary (binding for EXECUTE)`. No AI-marketing words (seamless, empower, supercharge,
  leverage).

## Outline

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
   normal → `/v-work` (asks you before doing anything, saves what it learned after; "not sure the
   job is small? pick this one" — it spots small jobs and skips the ceremony itself) ·
   big or risky → `/v-team` (a panel of AI critics argues about the plan first — and drafts the
   test plan; ~2× the cost, for decisions that are expensive to undo).
5. **The memory moment** — worked example across two sessions: Tuesday's `/v-work` on exports
   settles CSV over Excel and the AI writes down why; Thursday a colleague's `/v-ask why CSV?`
   answers in seconds. Recall made visible.
6. **Why bother** — less re-explaining: one sourced claim only, "about 96% less reading on this
   repo", measured by our memory plugin. Two magnitudes on one slide do not reconcile, so never
   pair this figure with the ~100× framing. Decisions survive; a new teammate's AI starts already
   knowing the project.
7. **Start today** — already set up on our repos; nothing to install. One habit swap: *next time
   you'd ask Claude about the repo, type `/v-ask`.*

## Glossary (binding for EXECUTE)

lifecycle→show the steps · approval gate→"asks you before doing anything" · capture→"saves what it
learned" · tokens→"how much it reads" · convergence→"until they agree" · ADR→"why we chose this" ·
dedupe→"checks it hasn't already written it down" · MOC→"index".

## Test plan (deliverable checks, in place of code tests)

1. Jargon sweep: none of the banned words appear in slide text.
2. Accuracy spot-check: slide 4 claims match commands/v-{ask,do,work}.md + v-team.md.
3. Deck is self-contained (no external assets), renders in light + dark.
4. Slide count = 8; every slide ≤ ~40 words of body text.

## Refs

- Process record: `vault/plans/2026-07-20-1030-team-presentation-vault-commands.trail.md` — the
  findings, dispositions and rejected examples behind this deck.
- `docs/vault-intro-deck.html` — the deliverable this plan specifies.
- `commands/v-ask.md`, `commands/v-do.md`, `commands/v-work.md`, `commands/v-team.md` — the command
  docs that Test-plan check 2 verifies slide 4 against.
