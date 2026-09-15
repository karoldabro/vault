# v-loop adapters — interface contract

The thin contract every campaign adapter implements. `/v-loop` holds the loop: enumerate a backlog,
dispatch an actor per case, take a verdict from a verifier, repair, re-verify, stop at a cap. What
the loop is made of — what a case is, who works it, what decides it — is the adapter's answer.

Per-task mechanics live in `adapters/<name>.md`, loaded **on demand** once step 1 picks the adapter,
so a run pays for the one campaign in play.

**Two adapters exist, and that is the floor.** One adapter is indistinguishable from no adapter
layer, so `checks/v-loop-adapter-slots.sh` refuses below two and refuses any adapter missing a slot.

## The six slots (each adapter fills all of them, under these exact headings)

| slot | what it answers | refused when |
|------|-----------------|--------------|
| `## Unit of work` | what one case is, and every path it writes | it names one file where the work writes two |
| `## Backlog` | the command that enumerates every case, and what the count means | the denominator is an estimate rather than a command's output |
| `## Actor` | who does the work, and what it reads before starting | the actor is named without the contract it works against |
| `## Verifier` | what produces the verdict, and whether it is a command or a model | a model is named where a command exists |
| `## Caps` | rounds, and attempts per case | either is absent |
| `## Stop rule` | the observable condition that ends the campaign | it reads "when the work is done" |

## The discriminator belongs to the adapter

Every campaign must be able to fail. How it proves that is the adapter's answer, not a shared field.

A test carries its contrary condition on the case row: the same case, a hostile input, a different
outcome. A document rewrite cannot — its contrary condition is a **different input file**, so it is a
different case. `adapters/document-corpus.md` uses **control rows**: units that already pass, which
must come back unchanged, checked by a hash recorded at enumeration.

An adapter states which shape it uses under its `## Verifier` slot. A campaign that can only pass
proves nothing.

## The verifier decides which rules apply

The engine requires that an agent never grades its own work, because a model grading itself skews
positive. That rule is conditional on this slot.

- **The verifier is a command.** The agent that did the work may run it; the orchestrator re-runs it
  and the two results must agree. No second agent is spawned.
- **The verifier is a model.** Verification is a separate spawn, always, with the case and the change.

The verifier must be the most deterministic thing available. A model is the answer only when nothing
deterministic exists.

## What the verifier cannot see

A case is done when the verifier passes **and** when the work the verifier cannot detect is
finished. An adapter names any such clause under `## Unit of work`, and each clause **cites a written
rule**. A clause resting on judgement is a finding to record, not work to do.

This also binds enumeration: the backlog runs the verifier, then asks what the definition of done
requires that the verifier cannot detect. A denominator built from the verifier alone answers how
much the tool can see, not how much work there is.

## Writing a third adapter

Copy the six headings, fill each with a command rather than a description, and add a row to the
table in `commands/v-loop.md` step 1. The check reads the headings, so their wording is the contract.
