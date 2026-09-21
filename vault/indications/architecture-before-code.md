---
type: indication
project: vault
slug: architecture-before-code
scope: repo
tags: [indication, planning, architecture, gates]
---

# architecture-before-code

## Rule
In a repo whose `VAULT.md` declares an `arch_profile` other than `none`, write no work item until
`bin/gate.sh arch <plan>` exits 0. The spec states the structure; the work items follow from it.

Recognition test: the plan's `arch_spec` key names a file, and that file passes the gate.

## Rationale
A green pipeline does not show that a design is coherent. In one study 97.0% of structural failures
evaded type checking and 100% evaded tests and static security scans (`vault/research/ai-code-slop.md`,
mechanism M2). Structure is checked before code exists, because after that only a reviewer can find it.

## Examples
- Do: draft `plans/<slug>.arch.md` from the starting text of the repo's profile (`arch-profiles/<arch_profile>.md`), fix each refusal, then write work items.
- Do: write `n/a: <reason>` under Data model for a feature with no database.
- Don't: write work items first and reconstruct the spec from them.
- Don't: add a `status` key to a spec; `scripts/completion-hook.sh` lists plans by that key.

## Applies-to
`commands/v-team/steps/03-propose-loop.md`, `commands/v-team.md`, `commands/_shared/architecture-spec.md`,
`bin/gate.sh`
