---
type: decision
project: vault
id: ADR-024
status: accepted
scope: repo
tags: [adr, v-pm, elicitation, definition-of-done, tracking]
---

# ADR-024 — /v-pm elicits, budgets, and tracks; amends ADR-012's research gate for /v-pm only

## Context
`/v-pm` planned features but did not manage them. Four gaps, each confirmed against the vault:

- **It clarified instead of eliciting.** `01-intake.md` §1.1 borrowed `/v-work`'s §3a.0a gate, which is
  tuned to ask *less* ("don't manufacture questions"). Correct for a task already understood; wrong for
  an operator who may not know the domain.
- **It had no Definition of Done.** `grep -rin "definition of done" commands/ templates/` returned
  nothing. The per-test quality gate existed in `v-team/steps/04-execute-loop.md` §5.2 but was never
  named, collected, or checked before a commit.
- **It split work only to one shard per repo**, with nothing below that.
- **Its plans were not trackable.** Nine of twelve features under `~/vault/_features/` read
  `status: planning` in `header.md` while their own shards read `in-progress` or `done`, because no
  command wrote that field after seeding. Shard status used seven different values against a template
  offering three.

The last point is the sharpest: the metric first used to diagnose over-planning ("9 of 12 features
never executed") was itself reading that stale field. The true figure is **3 of 12** never started. The
measurement error and the tracking defect were the same defect.

A second confirmed failure shaped the Definition of Done: four sessions in `ask-digitally` were closed
as done against a code path that could never run, because nothing asked for evidence.

## Decision

1. **Elicitation gets its own module** — `commands/_shared/elicitation.md`: a technique menu worked
   cheapest-first (document analysis → five whys when handed a solution → research → scenario
   walkthrough → example-driven), and a **checkable stopping rule** — the menu is exhausted and every
   remaining question fails the existing relevance test. Whatever is still open becomes a **stated
   default** in `requirements.md` `## Assumptions to test`, surfaced at the approval gate. It never
   blocks: a rule that nothing may start until nothing is unknown is a Definition of Ready, which
   stalls work that could have started.
2. **Definition of Done gets its own module** — `commands/_shared/definition-of-done.md`, in two tiers.
   A **baseline** every session can meet, and a **feature extension** that applies only where a
   `## Sessions` row exists. Every line is `met`, `failed`, or `not-applicable **with a reason**`; a
   line that cannot be honestly asserted is recorded, never ticked. The gate runs at
   `v-work/steps/05-commit-capture.md` **§5.0, before staging** — placed after the commit it would
   block nothing. `/v-do` carries its own reference, because it never reads that step.
3. **`/v-pm` emits a budget, not a task list** — an `## Appetite` per repo and a `## First slice`
   through the hardest part. Each repo's own `/v-team` session decomposes at propose-time `(f3)`,
   sizing against the measured local median (~9 files for a session that landed cleanly; ~49 for ones
   that dropped work). `/v-pm` does not read the code it would be slicing.
4. **The tracker lives in the shard the working session already opens**, and status is **derived**.
   `## Sessions` rows carry `evidence` and `last touched`; `/v-capture` Step 4e rolls the feature's
   `header.md` status up from those rows; `/v-pm status` reads the rows and flags a header that
   disagrees.
5. **Research runs by default in `/v-pm`.** This **amends `ADR-012`'s research-gate scope for `/v-pm`
   only**. `/v-work` and `/v-team` keep the novel-choices-only gate unchanged.

## Consequences
- The operator stops re-explaining the same feature, and a guess made on their behalf is visible as a
  guess rather than buried in prose.
- A "done" that cannot be substantiated now has to say so. The cost is a longer close on sessions where
  a line genuinely does not apply.
- `ADR-015` gated research to novel choices to control cost; that measurement was of `/v-team` at 78% of
  lifecycle runs. `/v-pm` has 12 lifetime runs, so the flip does not reopen the problem that ADR fixed.
- **Watch for:** the two-tier Definition of Done degenerating into blanket `not-applicable` on
  documentation work, and appetite being treated as an estimate to exceed rather than a ceiling to cut
  against. Both are visible in the session rows.
- **Not settled:** whether the three never-started features indicate over-planning or simply the
  operator's priorities. Nothing measured here separates them, so the appetite rests on one stalled
  roadmap rather than a systemic finding.

## Cross-repo impact
Framework-only. At runtime the new sections are additive and optional, so a workspace seeded before this
change reads without error; `header.md` status begins self-correcting at the next capture of each
feature.
