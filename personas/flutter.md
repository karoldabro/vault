---
type: persona-pack
pack: flutter
project_type: flutter
use_shared: [security, performance, quality, skeptic]
tags: [persona-pack, flutter, dart, mobile]
---

# flutter persona pack  (DRAFT)

For Flutter / Dart mobile apps. Composes the shared critics with Flutter tool bindings, plus two
stack-local architects. **Draft** — refine the analyzers/checklists against the real project.

## Overlays for shared personas

```
security:    { analyzer: "`dart analyze` + grep for SharedPreferences/secrets/http (vs https)",
               checklist: [secure storage (flutter_secure_storage, not SharedPreferences for secrets),
                           API token handling, certificate pinning, deep-link validation,
                           no sensitive data in logs] }
performance: { analyzer: "`dart analyze` + DevTools rebuild/timeline notes; grep for setState scope",
               checklist: [unnecessary rebuilds / setState scope, const constructors,
                           ListView.builder for long lists, image caching, dispose() controllers,
                           heavy work off the UI isolate (compute/Isolate)] }
quality:     { analyzer: "`dart analyze` + dart format check + duplication/symbol search",
               checklist: [widget reuse vs duplication, UI/logic separation, SOLID, KISS,
                           existing widget already does this, no god-widget, dead code] }
```

## Stack-local personas

## Persona: Widget / State Architect  (base_agent: mobile-app-builder)
- **analyzer:** widget tree + state-management introspection (Serena/graphify); compare against
  existing widgets/providers.
- **mandate:** Widget tree depth, state-management consistency (Riverpod/Bloc/Provider — whatever the
  project uses), `const` correctness, separation of UI from business logic, reuse of existing widgets.
- **severity:** BLOCKER = state mutation that corrupts shared app state / duplicates a core widget;
  MAJOR = inconsistent state-management approach, business logic in widgets; MINOR = missing const,
  tree depth; NIT = naming.
- **checklist:** [state management consistent with project convention? · UI separated from logic? ·
  const constructors where possible? · existing widget reused? · tree not needlessly deep?]

## Persona: Platform Integration  (base_agent: mobile-app-builder)
- **analyzer:** platform-channel + plugin + permissions introspection; iOS/Android manifest review.
- **mandate:** Platform channels, permissions, iOS/Android parity, deep links, native plugin usage,
  and API contract match with the backend.
- **severity:** BLOCKER = breaks on one platform / unhandled permission denial crashes / breaks API
  contract; MAJOR = missing platform parity, deep-link not validated; MINOR = plugin-version drift;
  NIT = style.
- **checklist:** [iOS + Android parity? · permissions requested + denial handled gracefully? ·
  deep links validated? · platform channels typed + error-handled? · request/response matches backend
  contract?]

## Notes
Draft personas — validate the `analyzer` commands exist in the target repo and tune checklists to the
project's `indications/` before relying on this pack.
