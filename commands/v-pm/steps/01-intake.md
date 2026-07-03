# Step 1 — INTAKE (plan mode)

Capture the business necessity, make sure it's understood, and decide who's in.

## 1.1 Restate + clarify (hard-block)
Write one sentence capturing the business necessity in your own words, plus the assumptions you're
relying on. Then run the **clarify gate** exactly as `v-work/steps/03-propose.md` §3a.0a defines it:
surface open doubts about direction / scope / which products are involved; answer what you can from the
vault; for a genuine plan-fork with **no safe default**, ask via `AskUserQuestion` and **wait** — do not
proceed past an unanswered fork. This is planning-ahead; a wrong assumption here cascades across every
project, so it is the most expensive place to guess.

## 1.2 Resolve participants
Determine which repos the feature spans:
1. If the user named them, use that.
2. Else read `~/vault/_global/coupled-groups.md` — if the necessity clearly maps to a declared group
   (vivi, digitally, givore…), propose its members and confirm.
3. Else ask which projects are in scope.

## 1.3 Break-even gate (skip the ceremony when it doesn't pay)
Count the resolved participants:
- **1 participant** → the workspace + conversation machinery is pure overhead. **Hand off**: tell the
  user to run `/v-team` (or `/v-work`) in that repo directly, and **end the v-pm run** (mark remaining
  tasks `deleted`). Do not seed a workspace.
- **2+ participants** → proceed.

## 1.4 Name + slug
Pick a short kebab-case `<feature>` slug (e.g. `saved-filters`, `team-billing`). This is the workspace
directory name and the `/v-team <feature>` argument. Confirm it isn't already taken under `_features/`.

## Required output
```
Necessity: <one sentence>
Assumptions: [stated defaults] · Clarifications: [asked | none needed]
Participants: [api, frontend, …]   (source: named | coupled-group <g> | asked)
Feature slug: <feature>
```
Mark INTAKE `completed` → Step 2.
