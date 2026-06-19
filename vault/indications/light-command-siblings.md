---
type: indication
project: vault
slug: light-command-siblings
scope: repo
tags: [indication, commands, lifecycle]
---

# light-command-siblings

## Rule
Light command variants are **single-file** (no `steps/` subdir — the whole body loads at once) and
carry **no approval gate**. `/v-ask` is hard read-only (never `Edit`/`Write`/`Morph`/`git`/capture);
`/v-do` edits but has no propose/approve loop, guarded instead by a scope check. Treat the four as one
escalation ladder — `/v-ask` → `/v-do` → `/v-work` → `/v-team` — and hand off up the ladder the moment
scope or risk grows, rather than stretching a light command past its band.

## Rationale
The gated lifecycle's value (sign-off, panel critique, on-demand step loading) is dead weight for a
quick answer or a one-file fix. Keeping light commands single-file and gate-free is what makes them
cheap; the escalation ladder is what keeps them *safe* without a gate. Collapsing the distinction
(e.g. giving a light command step files, or letting `/v-do` swallow an architecture change) defeats
both purposes.

## Examples
- Do: `/v-ask "where is the persona pack resolved?"` → answer from OV/graph, cite `personas/_resolution.md`, stop.
- Do: `/v-do "rename this flag"` → edit, run tests on the changed surface, offer capture if notable.
- Don't: use `/v-do` for a schema migration or cross-repo contract change — escalate to `/v-team`.
- Don't: add a `commands/v-ask/steps/` subdir — light commands stay single-file.

## Applies-to
`commands/v-ask.md`, `commands/v-do.md`, and any future light command variant.
