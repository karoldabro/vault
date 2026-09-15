---
type: trail
project: vault
plan: team-presentation-vault-commands
personas: [fallback panel: accuracy, audience-clarity, simplicity/humanizer]
rounds: 1
convergence: clean
tags: [trail, record]
---

# team-presentation-vault-commands — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`vault/plans/2026-07-20-1030-team-presentation-vault-commands.md`, which carries the current truth
only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| a single sourced reading claim on the payoff slide — "measured ~96% less on this repo" | stacking the ~100× doc framing next to the measured 96% | the two magnitudes do not reconcile in front of an audience, and the pair reads as a trust risk |
| the human benefit leads and the number supports it | the 96% figure as the slide headline | an abstract percentage as a headline invites disbelief before the benefit lands |
| a two-question decision tree for the commands | picking a command by job size | `/v-ask` is not a size, so the size axis mis-sorts it |
| one demo slide before the command menu | four commands introduced before any demo | four new names with nothing to anchor them do not survive the slide |
| a worked example spanning two sessions | a feature tour of the commands | recall across sessions is the claim; a tour does not show it |
| deck committed to this repo as HTML and published as a private Artifact link | a slide tool | the source stays reviewable in git and the link stays shareable |
| the closing slide states "already set up; nothing to install" | leaving setup unstated | the unstated version leaves the audience assuming an install step |

## Findings & dispositions

Round 1 panel: accuracy (tool-grounded against the command docs) · audience-clarity ·
simplicity/humanizer. No blocking finding stayed open — each was resolved by direct incorporation —
and no inter-critic conflict arose, so the no-new-blocking-findings guard stopped the loop at one
round.

The diff-review round ran the same three lenses in review posture against the implemented deck.
Verdicts: accuracy APPROVE_WITH_NITS · audience APPROVE_WITH_NITS · simplicity APPROVE_WITH_NITS.
Zero blocking findings, so the no-new-confirmed-blocker guard stopped it after one round. All
round-1 plan recommendations were verified honored by their owning critics, with citations in the
transcripts.

| round | id | critic | sev | finding | disposition |
|---|---|--------|-----|---------|-------------|
| 1 | S1 | simplicity | BLOCK | "token savings" meaningless to audience | Accepted — reframed in human terms; word "token" banned from slides (slide 6) |
| 1 | S2 | simplicity | BLOCK | source-doc jargon must not reach slides | Accepted — binding voice rule + glossary adopted |
| 1 | A1 | audience | BLOCK | "do I maintain the notes?" fear unaddressed | Accepted — slide 2 states the AI writes the notes |
| 1 | A2 | audience | BLOCK | payoff arrives too late | Accepted — teaser at end of slide 1 |
| 1 | A3 | audience | BLOCK | 96% as headline is abstract/trust-risky | Accepted — human benefit leads, number demoted to support with its source named |
| 1 | C1 | accuracy | ADV | 96% unsourced in docs (docs say ~100x / 100–2000 vs 20k tok) | Partially accepted — the number IS measured (claude-mem session stats, this repo), not fabricated |
| 1 | C2 | accuracy | ADV | /v-do capture-off-by-default omitted | Accepted — parenthetical on slide 4 |
| 1 | C3 | accuracy | ADV | /v-work small-job fast-path omitted | Accepted — parenthetical on slide 4 |
| 1 | C4 | accuracy | ADV | /v-team also authors test plans | Accepted — added to slide 4's /v-team line |
| 1 | A4 | audience | ADV | "pick by size" wrong axis (/v-ask isn't a size) | Accepted — two-question decision tree (slide 4) |
| 1 | A5 | audience | ADV | example must show recall across sessions, not a feature tour | Accepted — slide 5 spans two sessions |
| 1 | A6 | audience | ADV | 4 new commands before any demo | Accepted — new slide 3 shows one command first |
| 1 | A7 | audience | ADV | setup ambiguity on closing slide | Accepted — "already set up; nothing to install" |
| 1 | A8 | audience | ADV | vague call to action | Accepted — single habit swap CTA |
| 1 | A9 | audience | ADV | shared-team-memory undersold | Accepted — surfaced on slide 2 + slide 6 |
| 1 | A10 | audience | ADV | "~10 slides" invites padding | Accepted — committed to 7 |
| 1 | S3–S6 | simplicity | ADV | rule-of-three ok; markdown/git wording; "read-only" wording; "no ceremony" | Accepted — "plain-text notes", "only looks, never changes anything", "no fuss" |
| diff | D1 | accuracy | NIT | "in the repo" glosses global-vault mode | Skipped — acceptable simplification for an intro, by that critic's own assessment |
| diff | D2 | accuracy | NIT | slide 2 blanket "reads before/updates after" | Skipped — the per-command nuance is carried on slide 4 |
| diff | D3 | audience + simplicity | NIT | slide 6 stacks 100× and 96%, and the magnitudes do not reconcile | **Fixed** — single sourced claim: "a fraction of the reading — measured ~96% less on this repo" |
| diff | D4 | audience | NIT | the v-work fast-path aside muddies the decision tree, conflicting with keeping accuracy C3 | **Fixed** — reframed as a decision aid: "Not sure it's small? Pick this — it spots small jobs…", which keeps the fact and serves the choice |
| diff | D5 | audience | NIT | slide 5 Stripe/Adyen sounds /v-team-sized but is attributed to /v-work | **Fixed** — example rescaled to the CSV-vs-Excel export choice |
| diff | D6 | simplicity | NIT | "repo/repos" is mild jargon | Skipped — the audience is developers using Claude Code |

## Metrics

| round | findings | blocking | disposition split | convergence |
|---|---|---|---|---|
| 1 | 17 rows (S3–S6 counted as one) | 5 | all accepted, one partially | clean — every blocking finding resolved by direct incorporation, no inter-critic conflict |
| diff | 6 | 0 | 3 fixed, 3 skipped with reason | clean — zero blocking findings |

## Advisory test hints

The panel proposed no test artifacts. The deliverable is a slide deck, so the plan carries
deliverable checks in place of code tests.

## Rejected / deferred

The draft outline was sized at "~10 slides" and the deck was committed to 7 instead, to stop the
padding that an open-ended count invites.

An earlier slide-5 example used a Stripe-to-Adyen migration. It was dropped because a migration of
that size reads as `/v-team` work while the slide attributes it to `/v-work`.
