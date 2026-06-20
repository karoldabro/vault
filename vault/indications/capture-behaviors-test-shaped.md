---
type: indication
project: vault
slug: capture-behaviors-test-shaped
scope: repo
tags: [indication]
---

# capture-behaviors-test-shaped

## Rule
Capture business logic as test-shaped `## Behaviors & rules` bullets — `precondition → expected outcome
[; edge: when X then Y]` — recording only rules the work established or validated. Durable rules go in
the feature dossier; point-in-time deltas in the session. Omit the section entirely when there are no
domain rules (pure infra/refactor/config). Keep each rule in one section (Behaviors, cross-linked from
Gotchas if it is also a trap), ~3–7 bullets.

## Rationale
Sessions/features used to be process-oriented (Did/Learned, Contracts/Gotchas) and carried no assertable
statement of *what the system should do*, so they couldn't seed business/feature/integration/UI tests.
Test-shaped behavior bullets turn capture into source material for those tests without re-reading source.
The "omit when none" + "established, not aspirational" guards keep it modest — empty ceremony in the
infra/refactor majority is exactly what kills capture adoption.

## Examples
- Do: `idempotency key = sha256(file:rule:code); edge: never the LLM message (non-deterministic)`.
- Do: omit the section for a pure dependency bump — no heading written.
- Don't: `we should add rate limiting` (aspirational; the work didn't establish it).
- Don't: list the same rule in both `Behaviors & rules` and `Gotchas`.

## Applies-to
`templates/session.md`, `templates/feature.md`, `commands/v-capture.md` (Steps 3 · 4b · 5b)
