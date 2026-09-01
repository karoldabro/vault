# Shared module — how to elicit requirements from the operator

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

Binding on `/v-pm` intake. Available to any command that must understand a need before planning it.
**Not** binding on execution commands: `/v-work` and `/v-team` keep the ask-less clarify gate in
`v-work/steps/03-propose.md` §3a.0a, which is tuned for a task that is already understood.

The operator may not know the domain, the options, or what they actually want. Assume that. Your job
is not to collect a specification they dictate — it is to **find the need, gather the evidence, and
hand back something they can decide on**.

## The one rule that governs the rest

**The operator does not want your opinion. They want analysed evidence.** You are good at gathering
and structuring data; that is what you offer. Every question you ask and every option you present
carries what grounds it. When nothing grounds it, say so in those words — an unsourced preference is
labelled `judgement call, no evidence`, never dressed as a finding.

Question shape — one decision, options that state what the operator gains and gives up, recommended
option first — is owned by `communication.md` "Asking a question". Follow it there.

## What this is not

This is **not** a gate that holds work until every question is answered. A rule that nothing may start
until nothing is unknown is a Definition of Ready, and it stalls work that could have started. You ask
everything worth asking, then you **state a default for whatever is left** and proceed. See "Stopping"
below.

## The technique menu — work down it, cheapest first

Each technique answers a different kind of unknown. Use the one that fits; skip the rest. Record which
you used, so the stopping rule below is checkable.

| # | technique | use it when | what it produces |
|---|---|---|---|
| 1 | **Document analysis** | always first | what the vault, the docs and the code already answer — questions you must not ask |
| 2 | **5 Whys** | the operator hands you a solution instead of a problem | the need behind the request |
| 3 | **External research** | the problem class is one others have solved | how it is normally done, and the option you did not think of |
| 4 | **Scenario walkthrough** | scope or edges are unclear | who does what, in order, and where it breaks |
| 5 | **Example-driven** | a rule is stated abstractly | concrete cases that make the rule testable, and the cases nobody had considered |

### 1. Document analysis — always first

Never ask what the vault already answers. Sweep it before writing a single question: past decisions,
existing feature dossiers, the conventions that constrain this project, prior plans on the same
surface. A question whose answer was already written is a cost with no return, and it teaches the
operator that answering you is wasted effort.

### 2. Five Whys — when handed a solution

An operator usually arrives with a solution, not a problem. "Add a filter dropdown" is a solution;
the need behind it might be "I cannot find last month's orders". Ask why the thing is wanted, then
why *that* matters, until you reach a need that is not itself a mechanism.

Stop the moment the answer stops changing. Three whys is common; five is the ceiling, not the target.
Then state the need back in one sentence and let the operator correct it. If the restated need admits
a cheaper solution than the one requested, present both — that is evidence, not disagreement.

### 3. External research — before proposing an approach

Ground the approach in how this class of problem is actually solved. Your first instinct is a
hypothesis, not a conclusion. Rules, sourcing and the contradicting-consensus duty:
`v-work/steps/03-propose.md` §3a.0b.

### 4. Scenario walkthrough — for scope and edges

Walk one concrete instance end to end, naming the actor at each step: who starts it, what they see,
what the system does, what happens when it fails. Scope questions that are unanswerable in the
abstract answer themselves the moment someone walks the path. Each break you find is either a rule or
an explicit non-goal — never leave it unlabelled.

### 5. Example-driven — to make a rule testable

For every rule the operator states abstractly, ask for one example that satisfies it and one that
violates it. A rule with no violating example is not a rule; it is a preference, and it will not
survive contact with a test. Where behaviour changes by type, variant or flag, enumerate the
combinations and ask which are real — this is where the operator remembers the case they forgot.

## Where the answers live

Two homes, both in the feature's `requirements.md`. Do not invent a third.

| what | home |
|---|---|
| a question still open | `## Open questions` |
| a question you closed with a stated default | `## Assumptions to test` |
| a rule the operator confirmed | `## Business rules`, as `REQ-NN` |
| a term the operator used and you had to pin down | `## Domain glossary` |

An assumption in `## Assumptions to test` carries its importance and the evidence behind it, so the
riskiest guess is visible as the riskiest guess. That is the record the operator scans to catch a
default you got wrong.

## Stopping

Elicitation is finished when **both** hold:

1. **The menu is exhausted** — every technique above has either been used or has been ruled out for a
   stated reason, and document analysis has definitely run.
2. **Every remaining question fails the relevance test** — it does not change what gets built, or you
   can settle it yourself from the vault, the code or research. That test is `communication.md`'s, and
   it is the same one execution uses.

Anything still open after that gets a **stated default**, written to `## Assumptions to test` and
surfaced to the operator at the approval gate where it can still be corrected. Then proceed.

**Never** hold the feature waiting on an answer to a question that fails the relevance test. **Never**
proceed silently past one that passes it — that is the fork that has to be asked.

## Success criteria and what "done" will mean

Two things the operator owns and only they can supply. Elicit both before planning ends:

- **The measurable outcome.** What observable will differ once this ships, and by when. "Users can
  filter orders" is a feature, not an outcome. It belongs in `requirements.md` under
  `## Business context & goals`, which is the single home for the success metric.
- **Anything "done" must include beyond the baseline.** The floor — tests, review, lint, docs, the
  status row — is already fixed in `definition-of-done.md` and is not the operator's to restate. Ask
  only for what this feature adds: a performance bound, a migration that must complete, a third party
  that must confirm receipt.

If the operator cannot name a measurable outcome, that is itself a finding. Say so plainly and record
it as an open question rather than inventing one.

## Required output

```
Techniques used: [1 document analysis · 2 five-whys · …]   (ruled out: <n> — <reason>)
Need: <one sentence, in your words, after the whys>
Asked: <n>   ·   Answered: <n>   ·   Defaulted: <n>   (each default → `## Assumptions to test`)
Still open: [questions carried into `## Open questions`, with why each does not block]
Success metric: <the operator's measurable outcome | not supplied — recorded as open>
Done adds: [what this feature adds to the baseline | nothing beyond the baseline]
```
