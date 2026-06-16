---
type: session
project: vault
date: 2026-06-16
topic: v-team-nuxt-flutter-packs
continues: [[2026-06-16-1038-v-team-persona-critique-command]]
files_touched: [personas/nuxt.md, personas/flutter.md, vault/features/v-team.md]
decisions: []
tags: [session, v-team, personas, nuxt, flutter]
---

# v-team-nuxt-flutter-packs

## Goal
Turn the draft `/v-team` nuxt + flutter persona packs into grounded, accurate ones — and decide what
critic lenses each stack actually needs.

## Did
- Fanned out two read-only Explore agents over the real givore repos + givore vault indications to
  ground the packs instead of guessing.
- Confirmed two design calls with the user: (1) keep framework packs **generic + accurate**, lean on
  each repo's `indications/` for specifics (not bake givore in); (2) add a 3rd local lens to each pack.
- Rewrote `[[personas/nuxt]]`: dropped the Pinia assumption (detect state approach), added a
  detect-don't-assume preamble (SSR on/off, i18n vs single-locale, Nuxt UI vs Tailwind, lint/test may
  be absent → advisory), tightened analyzers. New lens **Accessibility & i18n**.
- Rewrote `[[personas/flutter]]`: detect state mgmt (repo is Provider + SafeChangeNotifier/Command/
  Result<T>, not Riverpod/Bloc), flagged shared_preferences-for-secrets, analyzers = `flutter analyze`/
  `flutter test`. New lens **UX & Resilience** (offline, error/loading, a11y, safe-area).
- Updated `[[features/v-team]]` dossier; 8/8 contract tests still green. Committed `bfedb88`.

## Learned
- My original drafts were factually wrong on the load-bearing bits: nuxt is **composables-only, no
  Pinia**; flutter is **Provider + custom SafeChangeNotifier + Command/Result<T>**, not Riverpod/Bloc.
  Lesson: ground stack packs against the real repo before asserting tooling/state libs.
- The givore Nuxt repos diverge hard: app.givore.com = Nuxt 4 + Tailwind + @nuxtjs/i18n + SSR on +
  localStorage-auth hydration guards, **no lint/typecheck/test wired**; dashboard.givore.com = Nuxt UI +
  Zod + OpenAPI-generated types + SSR off + English-only + eslint/vitest/typecheck present. A single
  pack must detect, not assume.
- flutter app stores tokens in `shared_preferences` (not `flutter_secure_storage`) — a real security
  finding the pack should surface.
- The architecture already carries project specifics for free: `/v-team` loads the repo's
  `indications/` into every critic envelope, so givore conventions (SafeChangeNotifier, Result, service
  layer, brand, i18n) don't need to live in the framework pack.

## Next
- Live `/v-team` dry-run on a nuxt repo + the flutter repo — verify critic selection picks the right
  lenses and the overlay analyzer commands actually run.
- Consider whether `shared_preferences`-for-secrets should become a givore mobile indication (it's a
  project finding, not a framework rule).

## Refs
- [[2026-06-16-1038-v-team-persona-critique-command]]
- [[../features/v-team]]
