# {{feature}} — requirements (business knowledge center)

The durable **what-the-product-must-do-and-why** for this feature — the single source of business logic,
authored by `/v-pm`. It exists to (1) ground rich tests and (2) let humans **and** AI understand the
product without re-deriving it from code. Only `/v-pm` (plan / reconcile) writes it.

> **This is a SPEC — aspirational by design.** The *established* form of a rule lives in each project's
> `features/` dossier (written by `/v-team`+`/v-capture` after the code exists, carrying the rule's
> `REQ-NN` id). Do not confuse the two: this file states intent; the dossier states what was built.
>
> **Home** — project-agnostic in `_features/<feature>/requirements.md` (2+ repos); single-project in
> `<project-vault>/requirements/<feature>.md` (1 repo). Body is identical either way.

## Business context & goals
<!-- The why · the real user need behind the ask · the success metric. This is the SINGLE source of
     "why" AND of the success metric — generic-plan.md back-references this instead of restating it,
     and there is no separate success-criteria section anywhere.
     The metric must be MEASURABLE and dated: name the observable that will differ once this ships, and
     by when. "Users can filter orders" is a feature, not a metric. If the operator could not supply
     one, say so here in those words and carry it in `## Open questions` — never invent one. -->

## Actors
<!-- Who uses / is affected by this feature (roles, systems, external parties). -->

## User stories
<!-- `As a <role>, I want <capability>, so that <benefit>`. Each story lists the `REQ-NN` ids below that
     constitute its acceptance — no separate Given/When/Then shape; acceptance IS the referenced rules. -->
- As a <role>, I want <capability>, so that <benefit>.  _(acceptance: REQ-01, REQ-02)_

## Business rules
<!-- The canonical test-shaped layer (reuses the `capture-behaviors-test-shaped` idiom verbatim):
     `precondition → expected outcome [; edge: when X then Y]`. Each rule gets a STABLE id `REQ-NN`, a
     PRIORITY tag ([must] · [should] · [could]) and, where relevant, an axis tag: [authz] · [error] ·
     [nfr]. THIS is the single source for rules / acceptance — contracts.md and project feature dossiers
     reference by id, they never copy the text.
     Priority is what lets a session cut scope to fit its appetite without asking. If nearly every rule
     is [must], nothing has been prioritised — go back and sort them.
     Omit this section only for a feature with no domain rules (pure infra/config). -->
- **REQ-01** `[must] <precondition> → <expected outcome>`
- **REQ-02** `[authz] <role X> requests <resource> they don't own → 403, no state change`
- **REQ-03** `[error] upstream times out → request fails closed; edge: when a retry lands after timeout, it is idempotent (no double charge)`   <!-- example encoding an explicit action-trigger ("when …"), preserving the BDD "When" where it matters -->

## Variant & state rules
<!-- OPTIONAL — omit when none. The direct seam to the business-logic-cartographer test generator.
     Use a decision table for variant/type rules and/or a state-transition table for stateful flows. -->

<!-- Decision table (conditions × values → required rule):
| condition A | condition B | → required outcome | rule id |
|-------------|-------------|--------------------|---------|
|             |             |                    |         |
-->
<!-- State-transition table:
| state | event | → next state | action / guard | rule id |
|-------|-------|--------------|----------------|---------|
|       |       |              |                |         |
-->

## Domain glossary
<!-- Ubiquitous language: the terms this product's rules are written in. term → definition. This is what
     lets AI (and a new engineer) reason about the product consistently. -->
| term | definition |
|------|------------|
|      |            |

## Invariants & edge cases
<!-- OPTIONAL — omit when none. What must ALWAYS / NEVER hold regardless of flow. -->

## Assumptions to test
<!-- OPTIONAL — omit when none. Every question elicitation closed with a STATED DEFAULT rather than an
     operator answer. This is the list the operator scans to catch a guess that went the wrong way, so
     order it by risk: importance × how little evidence backs it.
     `assumption · why it was assumed · what it rests on (vault doc / source / judgement call, no
     evidence) · what breaks if it is wrong`. Protocol: commands/_shared/elicitation.md. -->

## Open questions
<!-- OPTIONAL — omit when none. Questions still genuinely open — the elicitation ledger's home. Each
     says why it does NOT block (if it blocked, the feature would not have got here). In multi-repo mode
     these seed `conversation/` threads. -->
