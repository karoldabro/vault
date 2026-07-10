---
type: indication
project: vault
slug: confirmed-vs-advisory-findings
scope: repo
tags: [indication, personas, v-team]
---

# confirmed-vs-advisory-findings

## Rule
A critic finding may block (BLOCKER/MAJOR, force a change) **only when a concrete check confirms it** —
analyzer output, a failing test, a grep, a static rule. Unbacked observations are `advisory`: recorded
and surfaced, never blocking. Personas run their bound analyzer first and interpret its output.

**Corollary — verifier asymmetry.** The confirming check must add evidence the drafter didn't already
have: run the test, execute the query, probe the real path. Re-reading the author's prose, or citing a
check the author already ran, confirms nothing — verification pays off exactly where the verifier holds
an affordance the generator lacked.

## Rationale
Personas improve focus/rubric, not detection competence; untuned LLM reviewers produce 40–80% false
positives, and past ~30% FP developers ignore the bot (the trust cliff). Grounding keeps blocking
findings credible and makes "no new confirmed blockers" a meaningful stop condition. Verification is
cheaper than generation, and the gap widens when the verifier holds tools the generator lacked. See
[[ADR-003-tool-grounded-findings]] · [[ADR-017-evidence-based-panel-hardening]].

## Examples
- Do: security critic cites `composer audit` output / a failing authz test before marking a finding
  BLOCKER.
- Don't: block a plan on "this might have an N+1" with no query log or static check — that's advisory.

## Applies-to
`personas/**`, `commands/v-team/steps/**` — any persona-emitted finding.
