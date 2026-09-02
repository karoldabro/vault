---
type: indication
project: vault
slug: artifact-has-a-named-consumer
scope: repo
tags: [indication, planning, personas, doc-lint]
---

# artifact-has-a-named-consumer

## Rule
Every artifact a plan creates carries four answers before the plan is approved: **what requires it,
who writes it, who reads it, and what happens when it is missing or wrong.** An artifact is a file, a
field, a marker, a report, a prompt, a flag, or a row on a choice surface, and the table carries one
row per receiver-facing contract rather than one per file. Five obligations:

1. **Answer both ends, not just the middle.** A plan records who writes a thing by habit. It fails
   at the ends — a binding nothing requires, a report no seat is obliged to read.
2. **Read the two ends narrowly.** "What requires it" is the surface that would carry a blank without
   the artifact, not whoever asked for the work. "Missing or wrong" is what happens when the receiver
   reaches for it, not at build time.
3. **Simulate, do not review.** To show a handoff works, write out the literal text its receiver
   gets and produce one real output from it. A checklist can approve a handoff that reads complete
   and is not.
4. **Break the panel's frame by construction.** `consumer` holds a guaranteed seat on the PROPOSE
   panel (`personas/_resolution.md` §2, §2.1, §2.2), never a relevance pick. Critics chosen for
   mechanism by one mind all inherit that mind's blind spot.
5. **Interrogate claim words.** `wired`, `complete`, `covered`, `integrated`, `end to end`. If the
   claim has no falsifier, replace it with the specific reachable thing it means. These are not
   linted — a regex over them fires on legitimate prose and gets the linter switched off — so the
   `consumer` critic's checklist is the only thing that asks.

## Rationale
A plan can be structurally sound, bug-free and fast, and still hand its receiver a blank nobody
fills. The failure is invisible from the plan, because the plan describes the system rather than
simulating the agent that has to use it. Four instances shipped together in one approved plan: a
channel bound a device set that no step of the operator walk collected; a new script marker was
specified with no regex and no refusal, so an unrecognised bracket would have been read aloud by a
paid voice; a census reported to no seat obliged to read it; and one binding was called "wired" when
it meant only that a verb reached an allowlist.

The panel that reviewed that plan raised fourteen real defects and none of these four. Its three
critics were architect, skeptic and correctness — every one a mechanism lens, all chosen by the
author.

## Examples
- Do: `templates/plan.md` `## Artifact lifecycles` — one row per receiver-facing contract, four
  filled cells, or a single `none` row plus the reason.
- Do: `personas/_shared/consumer.md` — the dry run's literal receiver text and produced output go in
  the finding's `check` field, because that text is the grounding.
- Do: name the parser and the refusal for every new marker or field, the way `[gap: N]` has one
  strict regex and a loud refusal on a malformed value.
- Don't: write "a channel binds its device set" without a row on the surface that collects it.
- Don't: fill "what requires it" with the person who asked for the work — that cell is a surface.
- Don't: write that an artifact "reports rather than fails" and name no seat obliged to read it.
- Don't: describe the handoff instead of writing the receiver's input — a description grounds nothing.

## Applies-to
`templates/plan.md`, `personas/_shared/consumer.md`, `personas/_resolution.md`,
`commands/v-team/steps/03-propose-loop.md` §(b) and §(c), `commands/v-work/steps/03-propose.md`
§3a.6, `bin/doc-lint.sh` (`check_plan`, PLAN1/PLAN2), `lib/doc-lint-patterns.tsv` (the code
registry), and `tests/unit/document-standard.bats`.
