---
type: indication
project: vault
slug: propose-front-gates
scope: repo
tags: [indication]
---

# propose-front-gates

## Rule
PROPOSE `§3a` opens with two front gates before any design: **§3a.0a clarify** (state assumptions,
route open doubts, ask the user via `AskUserQuestion` only for plan-changing doubts with no safe
default, and **hard-block / always wait** for the answer — never guess past real ambiguity) and
**§3a.0b external research** (research the wild before
committing; skip trivial diffs; a contradicting consensus must be adopted or refuted in writing).
Understand and ground the approach before planning it.

## Rationale
Two cheap-to-prevent, expensive-to-carry failures: planning a half-understood task, and asserting a
design from the model's prior instead of how the problem is really solved (hallucination). Both happen
pre-code, so PROPOSE is the seam. `/v-work` and `/v-team` share `§3a`, so the gates land once and both
inherit them; in `/v-team` they run in the v0 draft before the panel spawns.

## Examples
- Do: draft says "use library X"; a search shows the ecosystem defaults to Y → adopt Y, or write the
  constraint that keeps X; cite both sources in the plan.
- Do: task ambiguous on direction/tech with no safe default → batch the questions into one
  `AskUserQuestion` and **wait** — a no-safe-default fork hard-blocks; never fall back to a guess. A
  doubt that *has* a safe default is stated and passes without blocking (flagged at the approval gate).
- Don't: silently pick an approach and skip straight to implementation steps; don't ask questions whose
  answers are already in the vault/code or obvious.

## Applies-to
`commands/v-work/steps/03-propose.md`, `commands/v-team/steps/03-propose-loop.md`,
`commands/v-work/steps/01-analyze.md`, `tool-playbook.md` §7
