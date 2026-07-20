---
type: session
project: vault
date: 2026-07-20
topic: team-presentation-vault-commands
files_touched: [docs/vault-intro-deck.html, vault/plans/2026-07-20-1030-team-presentation-vault-commands.md]
decisions: []
tags: [session, presentation, onboarding]
---

# team-presentation-vault-commands

## Goal
Build a short, simple-language, humanized presentation introducing the vault memory stack and
/v-ask, /v-do, /v-work, /v-team to the user's coworkers.

## Did
- Ran /v-team on a non-dev deliverable; no persona pack resolves for this docs repo, so used the
  graceful fallback with a 3-critic ad-hoc panel: accuracy (tool-grounded vs command docs),
  audience-clarity, simplicity/humanizer.
- Plan converged in 1 round (5 blockers, all incorporated); trail in
  [[../plans/2026-07-20-1030-team-presentation-vault-commands]].
- Built a 7-slide HTML deck ([[../../docs/vault-intro-deck.html]]) — field-notes visual direction
  (Charter serif + mono commands, spruce accent, light+dark), scroll-snap + arrow-key navigation —
  and published it as a private Claude artifact.
- Diff-review round 1: all three critics APPROVE_WITH_NITS, zero blockers; applied 3 nits (single
  sourced reading-savings claim, fast-path aside reframed as a decision aid, worked example rescaled
  to CSV-vs-Excel).
- Committed deck + plan as 7ae69b9; pushed session summary to OV.

## Learned
- The critic-panel pattern transfers cleanly to non-code deliverables: the accuracy critic verified
  slide claims against command docs with file:line citations, exactly as it would a diff.
- Two findings independently flagged by different lenses (the stacked 100×/96% sentence) were the
  strongest fix signals — corroboration works for prose too.
- Presentation framings that survived critique: two-question command picker ("Just asking? / Making
  a change?") instead of a size axis; a cross-session example ("Tuesday decides. Thursday remembers.")
  to make recall visible; one habit-swap CTA ("next time, type /v-ask").
- OV memory_store still returns 0 extractions on dense summaries (embedding-only mode persists);
  recall stays routed via `ov find`.

## Behaviors & rules
- Coworker-facing vault material → no source-doc jargon on slides (tokens, lifecycle, approval gate,
  capture, ADR, dedupe, MOC…); use the plain-language glossary in the plan's critique trail.
- Quoting the memory-savings number → cite it as measured (~96% less reading on this repo, per the
  memory plugin), never as a doc-sourced constant; don't stack it with the ~100× doc framing in one
  sentence.
- Explaining the command family → lead with "Just asking? vs Making a change?", not command size;
  /v-ask is not a smaller change, it is no change.

## Next
- Present the deck; iterate wording after real audience questions.
- Optional: /v-sync to re-ingest this session + plan into OV.

## Refs
- [[../plans/2026-07-20-1030-team-presentation-vault-commands]]
- [[../../docs/vault-intro-deck.html]]
- [[2026-06-29-1233-humanize-docs]]
- [[../features/v-team]]
