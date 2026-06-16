---
type: indication
project: vault
slug: packs-detect-not-assume
scope: repo
tags: [indication, personas, v-team]
---

# packs-detect-not-assume

## Rule
A `/v-team` stack persona pack **detects** the project's stack, tooling, and state approach from the
repo (`pubspec.yaml`, `package.json`, `nuxt.config.*`, `lib/` layout) — it never hardcodes a specific
library or assumes a check is wired. It defers to the repo's `indications/` for canonical conventions,
and downgrades a finding to `advisory` when the backing analyzer/check isn't available.

## Rationale
Projects on the same stack diverge hard (Nuxt: Pinia vs composables-only, SSR on/off, i18n vs
single-locale, lint/test present or not; Flutter: Riverpod vs Bloc vs Provider). Hardcoded assumptions
produce false findings and break reuse. Detection + deferral keeps one pack correct across many repos.
See [[ADR-004-generic-packs-specifics-in-indications]].

## Examples
- Do: "detect the project's state approach (check deps + `stores/`/`composables/`)"; "run the project's
  lint if defined, else grep + mark advisory".
- Don't: "ViewModels must use Riverpod" or "all strings via Pinia store" in a framework pack.

## Applies-to
`personas/<stack>.md` packs and their overlays.
