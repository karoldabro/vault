---
type: persona-pack
pack: {{stack-slug}}
project_type: {{stack-slug}}
use_shared: [security, performance, quality]
tags: [persona-pack]
---

# {{stack-slug}} persona pack

A **stack pack** composes reusable shared personas (`personas/_shared/*.md`) with stack-local ones, and
binds each persona to stack-specific analyzers. Authoring a new stack = write the 2 local architects +
short overlays; the generic critics are reused untouched.

## use_shared
Listed in frontmatter. Each named persona is loaded from `personas/_shared/<name>.md` and gets the
overlay below (analyzer + extra checklist). Drop one for a project via `VAULT.md` `personas.skip`.

## Overlays for shared personas
Bind the stack's real tooling and add stack checklist items. The shared persona supplies the lens,
rubric, and finding schema; the overlay supplies what to run and what to look at.

```
security:    { analyzer: "<stack SAST / audit cmd>", checklist: [<stack-specific checks>] }
performance: { analyzer: "<stack profiler / static check>", checklist: [<...>] }
quality:     { analyzer: "<stack linter / duplication check>", checklist: [<...>] }
```

## Stack-local personas
The roles unique to this stack (the ones that need project schema / framework knowledge). Each follows
`personas/_persona-template.md`.

## Persona: <Local role>  (base_agent: <agent>)
- analyzer: <stack tool>
- mandate: <...>
- checklist: [<...>]
