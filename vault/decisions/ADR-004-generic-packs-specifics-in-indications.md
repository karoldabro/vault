---
type: decision
project: vault
id: ADR-004
status: accepted
scope: repo
tags: [adr, v-team, personas]
---

# ADR-004 — Framework persona packs stay generic; project specifics live in indications

## Context
`/v-team`'s stack packs (`personas/<stack>.md`) could either encode a specific project's conventions
(e.g. givore's SafeChangeNotifier + Result<T>, service-layer class pattern, brand rules) or stay
generic per-stack defaults. Grounding the nuxt/flutter packs against the real givore repos surfaced the
tension: those conventions are real and valuable, but baking them into the framework pack would break
reuse for any non-givore Nuxt/Flutter project.

## Decision
Framework packs stay **generic + accurate**: they describe per-stack best-practice lenses and **detect**
the project's choices (state library, tooling, SSR on/off) rather than hardcoding them. Project-specific
conventions live in each repo's `indications/`, which `/v-team` already loads into every critic's
envelope (the LOAD-CONTEXT digest). Critics defer to the loaded indications over the generic pack
defaults. Per-project critic tuning beyond that is done via `VAULT.md` `personas.add` / `skip`.

## Consequences
- Packs are reusable across any project on that stack; givore's richness is not duplicated into the
  framework.
- Requires that project conventions actually be captured as `indications/` (givore's already are) —
  otherwise critics fall back to generic defaults.
- Operationalized by [[shared-vs-stack-persona-factoring]] (generic critics in `_shared/`) and
  [[packs-detect-not-assume]] (detect, don't hardcode).
