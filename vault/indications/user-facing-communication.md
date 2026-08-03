---
type: indication
project: vault
slug: user-facing-communication
scope: repo
tags: [indication]
---

# user-facing-communication

## Rule

Every line a command puts in front of the **user** is governed by
`commands/_shared/communication.md` — one shared module, bound by the resolvable installed path
`~/.claude/commands/_shared/communication.md` at the top of every `v-*.md` and every step file that
owns a `## Required output` block. Never duplicate the rules into a command; bind the module.

Four rules bind the *authoring* of any new command or step:

1. **Two layers, and the split is a deletion.** Design, research, critic trails and test plans go to
   the artifact. Only the decision reaches the terminal: `Recommendation · Impact · Options ·
   Assumed · Open · Ask`, ≤15 lines. Adding a summary layer *above* an unchanged dump is the failure
   mode — check that your change removes fields, not that it adds a header.
2. **`Impact` is never optional at an approval gate.** Approving authorizes a blast radius.
3. **Omit-when-empty cuts green, never amber.** Kill "skipped" / "not available" / "0 findings"; keep
   every skip note, fallback, `research: unavailable`, stated safe default, minority flag and open
   blocker. A rule that suppresses warnings alongside noise is a defect, not a simplification.
4. **Subagent text needs its own control.** A Claude Code output style reaches the main conversation
   only. Any command that spawns agents must cap what their output surfaces (the pattern is
   `v-team/steps/03-propose-loop.md` §(e).7) and carry the contract in the critic envelope for
   free-text fields. Otherwise that text is ungoverned.

**Out of scope, deliberately:** machine-read schemas, vault document contents, commit messages, and
your own reasoning. Length limits apply to prose the user reads — never to how much thinking happens
underneath; terse reasoning costs accuracy, terse prose does not. Text with a **different reader**
(forge comments in `/v-cr`, customer replies) keeps its own local rule and is exempt — do not delete
those as duplicates.

## Rationale

The framework's own `## Required output` templates were the mechanical cause of the overload: they
mandated always-on fields that reported normality, printed the design to the terminal, and handed
over panel vocabulary. Nothing governed prose, so a second brevity rule drifted into `v-ask.md` and a
third into `/v-cr`.

Grounded in [[decision-communication]]: repeating what the reader knows is *negative*-value, not
neutral; defining jargon does not repair it; a badly framed question yields a confident wrong answer
rather than "I don't know"; more explanation buys agreement, not accuracy. See
[[ADR-018-decision-communication-contract]] for the decision and its accepted costs.

## Applies to

`commands/_shared/communication.md` · `output-styles/director.md` · all `commands/v-*.md` · every
step file with a `## Required output` block · `install.sh` (links `output-styles/` as a second tree)

## Guard

`tests/unit/communication-contract.bats` (contract shape, binding coverage, the 15-file set, style
self-containment, no duplicate brevity rule) and `tests/unit/propose-golden.bats` (output-template
drift). **Both are file contracts** — they prove the rules exist, not that output obeys them. Do not
read a green suite as evidence the output is short.

## Refs

[[ADR-018-decision-communication-contract]] · [[decision-communication]] ·
[[ADR-004-generic-packs-specifics-in-indications]] · [[propose-front-gates]]
