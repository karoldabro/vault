---
type: trail
project: vault
slug: vpm-pm-discipline
date: 2026-09-01
tags: [trail, v-pm]
---

# vpm-pm-discipline — process record

The findings, the corrections and the rejected options behind
`2026-09-01-0900-vpm-pm-discipline.md`. The plan holds current truth; this file holds how it got there.

## The count that was wrong

The first draft opened on "9 of 12 features planned by `/v-pm` were never executed" and used it to
justify capping the planner's output. The number came from reading `header.md` `status:` on each
feature under `~/vault/_features/`.

A reviewer challenged it and a direct recount settled it: only **3 of 12** features have never started
(`abuse-observability`, `pickup-scheduling`, `public-events` — every shard `todo`). The other nine
carry shards at `in-progress`, `built` or `done`.

The reason the first count was wrong became the plan's strongest finding. `header.md` says `planning`
on nine features whose own shards say otherwise, because no command writes that field after seeding.
The metric used to diagnose the problem was itself an instance of the problem.

Consequence: the output cap lost its motivation. The appetite survived on separate evidence — one
stalled roadmap — and is flagged in the plan's `## Open & deferred` as needing the operator's
confirmation.

## Rejected options

- **Cap `/v-pm`'s output on backlog grounds.** Rejected: the backlog was an artifact of the stale
  field. The appetite mechanism was kept, its justification replaced.
- **Add a `## Success criteria` section to `requirements.md`.** Rejected: `## Business context & goals`
  already demands the success metric. Two acceptance-shaped homes in one file breaks the one-rule-one-
  place standard. The existing section's instruction was sharpened instead.
- **Record REQ coverage in both the `## Sessions` table and `## Business rules to satisfy`.** Rejected
  for the same reason. Coverage now lives only in the session table.
- **Place the Definition-of-Done gate in the capture step §5.4.** Rejected: §5.1 has already committed
  by then, so the gate blocks nothing. Moved ahead of staging as §5.0.
- **A single Definition of Done for all sessions.** Rejected: it required a mutation tool and an
  end-to-end harness this repo does not have, and feature-mode fields a plain session has no source
  for. Split into a baseline plus a feature-mode extension, each line recordable as
  `not-applicable (reason)`.
- **Ground the decomposition decision in "up-front splits decay".** Rejected as an overreach: the
  cited `ask-digitally` tracker shipped 10 of 10 sessions and recorded every deviation in the row that
  deviated. Re-grounded on where the tracker lives, which is what separated it from the roadmap that
  stalled at 2 of 15.

## Findings applied

Three reviewers ran against the draft — a requirements lens, an architecture lens and a skeptic. Every
blocking finding was confirmed against a file before it was applied.

| finding | disposition |
|---|---|
| The headline count read a stale field | applied — recounted; motivation replaced |
| `## Success criteria` duplicates the existing success metric | applied — section dropped, W8 rewritten |
| Coverage recorded in two places in one file | applied — one home, W10 |
| Definition-of-Done gate sits after the commit | applied — moved to §5.0, W13 |
| Baseline requires tooling this repo lacks | applied — split baseline/extension, W2 |
| §5.2's characterization-check alternative was dropped | applied — reproduced verbatim, W2 |
| "Ask everything then flag" is not a stopping rule | applied — stopping rule is menu exhaustion plus the relevance test |
| The question ledger had no home on disk | applied — it is `requirements.md` `## Open questions` |
| `/v-do` and `/v-ask` rows could never close | applied — W14 adds the gate to `/v-do`; `/v-ask` removed from the column |
| `## Sessions` needs an evidence column | applied — `done` without evidence is invalid |
| `## Sessions` needs a date column | applied — `last touched` |
| `## Sessions` needs the drift-check exclusion | applied — W6 and W10 |
| §3a.0a already restates the question rules | **not applied** — `tests/unit/research-clarify.bats` pins those strings to that file, so a prior session put them there deliberately. Collapsing them would delete a pinned contract without a decision. `elicitation.md` references instead, so no third home is created |
| Session 1 emitted an appetite nothing decomposed | applied — W11 moved into session 1 |
| ADR-012 would state a contradicting truth | applied — W19 amends its scope for `/v-pm` only |
| `bin/doc-lint.sh` does not cover `commands/_shared/` | applied — line caps asserted in bats instead |
| Test contracts split across the wrong files | applied — W18 places each beside its gate |
| Status warning fired off the wrong field | applied — W7 derives from shard rows; W15 rolls the field up |
| The plan mandated success criteria it did not have | applied — the plan now carries its own, with a review date |
| Splitting this plan into two sessions is self-contradictory | not applied — the reviewer withdrew it; this is the executing session splitting its own work |

Three features under two weeks old sit in the twelve. The plan states the age distribution rather than
excluding them, so the reader can discount them.

## Found while executing

- `bin/doc-lint.sh` flagged the first attempt to record the reverted item, because a work-item row
  carrying what an earlier version got wrong is history inside a contract document. The reversal lives
  here; the plan states only what is true now.
- The suite's canary `the Required-output file set is exactly N` was pinned at 15 while the tree already
  held 16 — a prior addition never repointed it. Now 17 and passing, so the tripwire works again.
- The baseline at `HEAD` fails 21 tests, not the 8 recorded in
  `vault/sessions/2026-08-24-1214-docs-writing-standard-pass.md`. Bats numbers tests positionally, so
  adding tests renumbers them; the comparison has to be by name.

## Not settled

Whether the three unstarted features indicate over-planning or the operator's priorities. Nothing here
separates the two, and the plan says so rather than assuming.

## Refs

- `2026-09-01-0900-vpm-pm-discipline.md` — the plan this record belongs to.
