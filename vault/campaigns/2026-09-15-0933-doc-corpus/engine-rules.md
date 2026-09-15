---
type: instruction
campaign: 2026-09-15-0933-doc-corpus
tags: [campaign, engine, rules]
---

# Rules the task-agnostic engine must state

The slots a campaign declares are in `slots.md`. This file holds the rules that govern how any
campaign reaches a verdict, each one written because this run tested it against a task that is not
testing.

The consumer is the session that writes the engine. Every rule below replaces or narrows wording the
current `commands/v-loop/campaign-rules.md` states unconditionally.

## The verifier decides the rules

The campaign rules require that the agent writing a fix never produces its own retest verdict,
because an agent grading its own work skews positive.

That rule exists because the verifier is a model. Here the verifier is a command with an exit code,
so the agent that ran the repair can run it without skewing anything. The orchestrator re-runs it
anyway, and the two results must agree.

**For the engine:** the rule is conditional on what fills the verifier slot. State it as — the
verifier must be the most deterministic thing available, and a second agent only when nothing
deterministic exists.

## The backlog must carry the rule's own words

A ledger row's `reason` carries the verifier's own message text, never a code the orchestrator
expands from memory. A campaign that summarises its verifier has stopped being grounded in it.

`LONG1` is the case that proves the cost. The code reads like a length cap and is not: it is emitted
at `bin/doc-lint.sh:489` for one sentence over 30 words, whatever the document's length. A repair
derived from the code alone splits the file and fixes nothing.

The agent working the case reads the verifier's implementation before accepting the brief's account
of it. That is what keeps one such error from reaching ten cases.

**For the engine:** enumeration runs the verifier and stores what it said. The orchestrator's reading
of a rule is not evidence about the rule.

## The verifier under-determines the work

A case is done when the verifier passes **and** when the work the verifier cannot see is finished.
Those are different conditions, and the ledger records only the first.

`bin/doc-lint.sh` reads a document's body. Three frontmatter keys — `personas`, `rounds`,
`convergence` — carry process state that `commands/v-team/steps/03-propose-loop.md:218` rules belongs
in the sidecar, and no finding will ever name them. A plan that keeps all three exits 0.

**For the engine:** a case carries its definition of done, and the verifier is one clause of it, not
the whole. When a clause has no detector, the case says so in the ledger rather than letting a green
verdict imply it. The engine that treats the verifier as the definition of done ships work nobody
checked.

**The same gap reaches the backlog, which is worse.** The backlog was enumerated by running the
verifier, so it holds only what the verifier can see. Two plans carrying the same frontmatter defect
exit 0 and were never cases at all, and one closed case passed before the clause was written down.
A denominator built from the verifier answers "how much can this tool see", not "how much work is
there".

**For the engine:** enumeration runs the verifier and then asks what the definition of done requires
that the verifier cannot detect. A campaign that skips the second question reports a completion
percentage against the wrong denominator.

## A brief is an input to check, not a fact

Every count an orchestrator puts in a case brief carries the command that produced it, and the agent
runs that command rather than accepting the number.

Two briefs in this campaign carried wrong counts, and both were caught because the agent went to the
source. One named a rule as a line cap when it fires on sentence length. One named four process keys
where the file held three.

**For the engine:** the brief is the orchestrator's summary, and a summary is the thing most likely
to be stale. An agent that repairs what the brief describes rather than what the verifier reports is
working from the wrong document.

## A verdict expires when its case changes

A verdict describes the files as they stood when the verifier ran. An agent that reworks its case
after reporting has invalidated that verdict, and the ledger still reads `pass` until someone runs
the verifier again.

This campaign hit it once: a case adopted a shape another case had found, changed both its files,
and the recorded verdict was already stale.

**For the engine:** the ledger is append-only and the last line for an id wins, so a re-verified case
appends a new row rather than editing the old one. Any change to a case's files after its verdict
requires that new row, and an agent that reworks a closed case says so.

## A verifier-invisible repair needs a written ruling

A case may include work the verifier cannot detect, and the campaign then needs a rule for which
invisible work belongs in scope. The rule is that the case points at a written ruling.

Two plans were repaired here for keeping process state in frontmatter, which no finding can name.
Each pointed at `commands/v-team/steps/03-propose-loop.md:218`. Two further sections were left alone:
they pass the verifier, they are arguably the same class, and no ruling names them.

**For the engine:** a case's definition of done holds the verifier plus any clause that cites a
written rule. A clause resting on an agent's judgement is a finding to record, not work to do, and
recording it is how the campaign ends instead of growing.
