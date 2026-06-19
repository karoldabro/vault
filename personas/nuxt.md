---
type: persona-pack
pack: nuxt
project_type: nuxt
use_shared: [security, performance, quality, skeptic]
tags: [persona-pack, nuxt, vue, frontend]
---

# nuxt persona pack

For Nuxt 3/4 · Vue 3 · TypeScript front-ends. Composes the shared critics with front-end tool bindings,
plus three stack-local lenses. **Generic by design** — it does not assume a specific state library or
that any given check is wired. Project-specific conventions (state approach, service layer, brand,
component organization) come from the repo's loaded `indications/` digest; critics must **defer to
those** over the generic defaults here.

**Detect, don't assume.** Nuxt projects vary widely (e.g. SSR on vs `ssr: false`; Pinia vs
composables-only; `@nuxtjs/i18n` vs English-only; Nuxt UI vs custom Tailwind; full lint/typecheck/test
vs none). Read `nuxt.config.*` + `package.json` first and adapt; if a check isn't wired, grep for the
anti-pattern and mark findings `advisory`.

## Overlays for shared personas

```
security:    { analyzer: "project lint if defined + grep v-html / public-vs-private runtimeConfig / token storage",
               checklist: [XSS via v-html, secrets in public runtimeConfig (use private for server-only),
                           auth token storage (httpOnly cookie vs localStorage) + no server-only data in
                           the SSR hydration payload, CSRF on mutations] }
performance: { analyzer: "nuxt build + `nuxi analyze` (bundle) where available; Lighthouse optional",
               checklist: [bundle size / code-splitting, lazy + dynamic components, image module
                           (<NuxtImg>/@nuxt/image), hydration cost, redundant client fetches,
                           useFetch/$fetch dedupe + caching, payload size] }
quality:     { analyzer: "project eslint + typecheck (vue-tsc / `nuxi typecheck`) if wired; duplication + symbol search",
               checklist: [composable/component reuse vs duplication, component SRP, typed props/emits,
                           existing component already does this, no prop-drilling, dead code,
                           DEFER to the repo's indications for the canonical conventions] }
```

## Testing-group overlays
Bind when the testing group (`personas/_shared/testing/`) is selected on a test-touching change
(`_resolution.md` §2.1). Assumes Vitest; detect Jest and swap flags if the repo uses it.

```
test-behaviorist:  { analyzer: "eslint-plugin-testing-library + @testing-library/vue queries; eslint-plugin-vitest (JS = confirmed tier)",
                     note: "assert rendered output / emitted events, not wrapper.vm internals" }
assertion-auditor: { analyzer: "StrykerJS (@stryker-mutator/core) + eslint-plugin-vitest expect-expect",
                     note: "survived mutant = weak assertion; ban assertion-free + bare snapshot-only tests" }
edge-case-hunter:  { analyzer: "vitest --coverage (v8/istanbul) --coverage.branches; fast-check",
                     note: "loading / error / empty states, boundary props, error responses" }
test-double-critic:{ analyzer: "grep vi.mock / vi.fn / mockNuxtImport / mockComponent density",
                     note: "prefer @nuxt/test-utils real renders; flag mocking the component under test" }
flakiness-sentinel:{ analyzer: "vitest --sequence.shuffle; grep Date.now()/Math.random()/setTimeout/real $fetch",
                     note: "vi.useFakeTimers + seed; mock $fetch, don't hit the network" }
test-harness-critic:{ analyzer: "run vitest run + verify @nuxt/test-utils setup; component (vitest) vs e2e (Playwright) layer",
                     note: "mountSuspended/registerEndpoint wired? don't push unit logic into a Playwright e2e" }
```

## Stack-local personas

## Persona: Component / State Architect  (base_agent: frontend-architect)
- **analyzer:** component tree + store/composable introspection (Serena/graphify); detect the project's
  state approach (Pinia store vs composables-only — check deps + `stores/`/`composables/`); compare
  against existing components/composables.
- **mandate:** Correct composable-vs-component boundary, the project's state pattern applied
  consistently, explicit props/emits contracts, no prop-drilling, **SSR-safe state (no module-level
  mutable shared state → cross-request leakage)**, and reuse of existing components over near-duplicates.
- **severity:** BLOCKER = SSR-unsafe shared state (cross-request leak) / duplicates a core existing
  component; MAJOR = wrong state ownership, prop-drilling >2 levels, props mutated directly; MINOR =
  composable placement; NIT = naming.
- **checklist:** [composable vs component boundary correct? · state pattern matches the project's
  convention (from indications)? · props/emits typed + explicit? · SSR-safe (no shared mutable
  module state)? · props never mutated (emit instead)? · existing component reused?]

## Persona: Integration / SSR  (base_agent: frontend-developer)
- **analyzer:** check `nuxt.config` `ssr` flag, route/middleware + data-fetching introspection; compare
  response usage against the backend (api-laravel) contract.
- **mandate:** Data fetching (`useFetch`/`useAsyncData`/`$fetch`) chosen correctly, SSR-vs-client
  hydration correctness (only where SSR is on), API contract match with the backend, error/loading/
  empty states on every user path, route middleware + auth guards (incl. `import.meta.server`
  early-return + isMounted-gated auth UI where auth lives client-side).
- **severity:** BLOCKER = hydration mismatch / leaks server-only data to client / breaks the backend
  contract a consumer depends on; MAJOR = missing error/loading state on a user path, double-fetch;
  MINOR = suboptimal fetch placement; NIT = style.
- **checklist:** [right fetch primitive? · SSR/CSR boundary correct, no hydration mismatch (if SSR on)? ·
  request/response shape matches backend contract? · error + loading + empty states? · route
  middleware/auth guard present + SSR-safe?]

## Persona: Accessibility & i18n  (base_agent: frontend-developer)
- **analyzer:** detect `@nuxtjs/i18n` (skip the i18n half if the app is single-locale by design);
  grep templates for hardcoded user-facing strings, missing `alt`/labels, non-semantic elements; run
  an a11y linter (eslint-plugin-vuejs-accessibility) if wired.
- **mandate:** All user-facing strings localized when the project uses i18n, with every supported
  locale covered; WCAG basics — semantic HTML over `<div>` soup, `alt` text, form labels, focus order,
  keyboard operability, sufficient contrast, correct ARIA. These are tooling-invisible and easy to
  miss, hence a dedicated lens.
- **severity:** BLOCKER = interactive control unusable by keyboard / screen reader (no label/role);
  MAJOR = hardcoded user-facing string in an i18n project, missing locale, image without `alt` on a
  meaningful image; MINOR = contrast/focus-order nit; NIT = redundant ARIA.
- **checklist:** [user-facing strings via i18n (if project localized)? · all supported locales covered? ·
  semantic elements + roles? · interactive controls keyboard-operable + labeled? · images have
  meaningful `alt`? · contrast + visible focus?]

## Notes
Generic pack. Validate the overlay `analyzer` commands against the target repo (some Nuxt apps wire no
lint/typecheck/test — then findings lean `advisory`), and let the repo's `indications/` override the
defaults here for state pattern, service layer, brand, and component conventions.
