---
type: indication
project: vault
slug: shared-vs-stack-persona-factoring
scope: repo
tags: [indication, personas, v-team]
---

# shared-vs-stack-persona-factoring

## Rule
Generic critics (security, performance, quality, skeptic) live once in `personas/_shared/`. A stack
pack (`personas/<stack>.md`) reuses them via `use_shared` + per-stack overlays (analyzer + checklist)
and only defines the truly stack-specific roles (the architects). Never copy a generic critic into a
stack pack.

## Rationale
Generic lenses are stack-agnostic; duplicating them per stack causes drift and triples maintenance.
Authoring a new stack should cost ~2 local architects + 3 short overlays, not a full critic set.

## Examples
- Do: `personas/api-laravel.md` has `use_shared: [security, performance, quality, skeptic]` + overlays,
  and defines only Software Architect + Integration Architect locally.
- Don't: paste the security persona body into `nuxt.md` and tweak it.

## Applies-to
`personas/**` — authoring or extending `/v-team` persona packs.
