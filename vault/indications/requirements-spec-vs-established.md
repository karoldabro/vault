---
type: indication
project: vault
slug: requirements-spec-vs-established
scope: repo
tags: [indication, v-pm, requirements, testing]
---

# requirements-spec-vs-established

## Rule
Plan-time business logic is a **spec** and lives in `requirements/` (single-repo) or
`_features/<f>/requirements.md` (2+ repos): test-shaped business rules (`precondition → expected [; edge]`)
with stable `REQ-NN` ids + `[authz]/[error]/[nfr]` axis tags, plus glossary + optional decision/state
tables. It is **aspirational by design**. The *established* form lives in the `features/` dossier,
written at `/v-capture` Step 5b (shared by `/v-work` + `/v-team`), which promotes only **built** rules and
carries each `REQ-NN` id inline. Never write aspirational rules into `features/` (the
[[capture-behaviors-test-shaped]] "established, not aspirational" rule still governs it); never collapse
spec into established. `/v-pm` authors the spec for **any** feature (1+ repos) — only the `_features/`
coordination workspace is gated at 2+ repos.

## Rationale
A feature's business logic evaporated into plan prose, so the user re-explained it every session and
neither rich tests nor AI product understanding had a durable source. Separating spec (`requirements/`)
from established (`features/`) captures it once at plan time without violating the established-only
invariant that keeps `features/` trustworthy. The `REQ-NN` id chain
(`requirements.md → (f2) backlog source → established dossier Behavior`) is what makes the spec actually
*ground* tests rather than just describe intent — and placing the carry in shared `/v-capture` (not one
lifecycle's step) is what keeps it closing for both `/v-work` and `/v-team`.

## Examples
- Do: `requirements/checkout.md` → `**REQ-03** [error] upstream times out → fail closed; edge: retry after
  timeout is idempotent`. After shipping, `features/checkout.md` `## Behaviors & rules` gets
  `[REQ-03] upstream times out → fail closed …` (established, id carried).
- Do: for a single-repo feature, `/v-pm` writes `requirements/<feature>.md` then hands off — it does not
  seed a `_features/` workspace.
- Don't: write a `REQ` rule into `features/` before it's built (aspirational-in-established).
- Don't: seed a `status: stub` dossier into a *participant* vault `/v-pm` doesn't own (cross-repo footgun).

## Applies-to
`commands/v-pm/steps/**`, `commands/v-capture.md` (Step 5b), `commands/v-team/steps/{00,03,04}-*.md`,
`templates/_features/requirements.md`, `vault-guide.md` §13
