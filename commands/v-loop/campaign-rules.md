# Campaign operating rules

Binding on every agent `/v-loop` spawns. Each rule below was paid for by a run that went wrong
without it, in one of two campaigns on different stacks.

**What this file leaves to others.** Only rules with no home elsewhere are written here. The rest
are already binding and are named once:

| already owned by | what it governs |
|------------------|-----------------|
| `commands/_shared/agent-conduct.md` | writing to disk as you work, the order of a report, counts that carry their command, reading a whole source, treating a premise as possibly mistaken, and the orchestrator's half of a fan-out |
| `commands/_shared/communication.md` | what reaches the operator, and in what order |
| `commands/_shared/document-standard.md` | every file an agent writes |
| `commands/_shared/definition-of-done.md` and `commands/v-team/steps/04-execute-loop.md` | the test-quality gate: a test must fail when the code is broken |
| `commands/_shared/critic-panel.md` | the finding schema, severity, and the grounding split that separates a fault from an opinion |
| `commands/_shared/elicitation.md` | when an operator is asked something, and where the answer lives |
| `commands/_shared/vault-sync.md` | git against a vault |

---

## Evidence

**Every verdict must rest on the running system.** A request, a click or a query demonstrates a
defect, and the same demonstration reversing proves the fix. Reading code is how you form a
hypothesis, and it is the one thing that closes no case.

**Every case must become an executable test** in the project's own framework. A case that stays
prose has not been run.

**A defect must survive a check against the shipped code before it is filed.** In one campaign six
of seventy-three filings were disproved this way, several written by the orchestrator itself.

**The agent that wrote a fix must hand its retest to a different agent.** An agent grading its own
work skews positive, so verification is always a separate spawn.

**Every fix must be proven by the means that would catch its failure.** A fix proven by unit tests
and never exercised in a browser is recorded that way.

---

## Cases

**Every case must carry an injection**: a contrary condition that must produce a *different*
outcome. The existing test-quality gate asks afterwards whether a test discriminates; this asks it
**before the case runs**, as part of designing it. When the injected condition gives the same result
as the normal one, the case proves nothing and its verdict is `BLOCKED`.

**Every case must state what it proves as an outcome the user sees.** "Tapping Save shows the new
title in the feed" is a case; "test the save button" is a label.

**An injection case must prove the app degrades correctly**: it stays on the right screen, it tells
the user, and it leaves the control usable. Surviving without a crash is not a passing bar.

**A surface that issues no requests gets a different fault.** Hostile content or a device-level
condition, rather than a response code it can never receive.

**Baselines must be read from the live system at run time.** A literal count goes stale the moment
another case seeds a row; one campaign corrected eight specs for this.

**An assertion must keep the discrimination its case exists for.** Turning an exact count into
"greater than zero" destroys it.

**Every exclusion must be recorded with its reason.** A placeholder route, a redirect sharing one
expression, an option absent from the interface. An unexplained gap reads as an oversight forever.

---

## Dispatch

**Two testers run together only when their `conflicts_on` sets are disjoint.** A `global` scope runs
alone. A session decides this from the ledger rows it wrote, so it needs no counter.

**Every brief must fence its agent's files**: what this agent owns, and what other agents hold right
now. Two agents once built the same fix in parallel because the fence was unstated.

**An asset rebuild must wait until no tester is running.** A spec failing against a half-written
bundle wastes the round. The builder asks, and the orchestrator answers when the stack is clear.

---

## What the screen and the truth disagree about

The defects that matter most live here. Look for them deliberately.

- **Does every surface state the same quantity?** A headline count, a row list, an admin queue and
  an email can each read a different field for the same thing.
- **Is the audience right?** A list keyed to the viewer rather than the subject shows an empty
  screen to someone entitled to see it. Ask what the list is *of*.
- **What does the default state show?** Count what a real user would actually see. When moderation
  holds 768 of 793, the feature is empty for almost everyone, and that is a launch decision.
- **Does the action reach the engine?** A setting written through a cache with no expiry changes
  nothing. Prove the write moves behaviour rather than the row.
- **Are declared values read?** Run `bin/gate.sh readers` rather than judging it by eye.

---

## In a browser

Applies to any surface a user looks at.

**Findings must come from a real browser at real data volume.** A missing stylesheet, a raw
translation key as a column header and an empty tab are all invisible to a suite asserting
structure.

**Assertions must read computed style.** A class-name assertion passes against unstyled markup.

**Text must be read with `textContent`.** `innerText` applies CSS transforms, so an uppercased
element defeats both positive and negative assertions.

**A new surface must be judged as a guest** on the page it was added to. A section that saves
differently from the page around it is a fault rather than a preference.

**The whole journey must be walked** — mail, click, confirmation, action, destination — naming every
point where a user could lose the thread. Integration failures live at the seams.

**The visual language is prescribed.** Read the project's own architecture documents before judging
colour, spacing or type, and cite them when a finding contradicts one.

---

## Safety

Each rule names the sanctioned action, because that is the form that holds across a long run.

1. **Prove the environment is pinned before every suite run.** `artisan test` destroyed a working
   database twice in one campaign, through `variables_order` leaving `$_SERVER` carrying the
   container's real connection.
2. **Rebuild the stack through its own restore script.** That is the sanctioned path back to a clean
   database, and it is the only one.
3. **Name each file in every commit.** `scripts/staging-hook.sh` denies a pathspec-less commit, a
   `-a` sweep, an amend and a hard reset before they run.
4. **Rewrite history only on a branch nobody else holds.** On a shared branch, add a new commit.
5. **Pass the path to a credential.** A connection string, key or password stays in the file it
   lives in, and the campaign records where to find it.
6. **Restart the queue workers after a code change**, or a correct fix reads as broken.
7. **Tear down on the full case id** (`LIKE 'QA <case-id>%'`). One truncated wildcard destroyed two
   other cases' fixtures and turned passing cases red.
8. **Read every restoration back.** Restoring a value and proving it restored are different acts.
9. **Disarm every fault the case armed**, in a teardown registered by the arming helper, so a case
   cannot forget and poison the next one.
10. **Check the ignore rules before a finding cites evidence.** A repo-wide `*.log` rule once
    excluded every file the findings pointed at.
11. **Keep a campaign inside its own directory and its disposable stack.** Anything outside stays
    the operator's.
12. **Ask before any irreversible act the operator did not already sanction.**

---

## When a case goes red

Correct the case when the case is wrong, and file the defect when the app is wrong.

| the test is wrong | the app is wrong |
|-------------------|------------------|
| It asserts something the product never promised — a widget absent by design, a count the seeded data does not guarantee, a precondition the shipped data makes impossible. | It asserts the outcome a user is entitled to, and the app fails to deliver it. |
| Correct the case, run the corrected version, and state the correction. | Record `fail`, write the finding, move on. |

**When you cannot tell, record `fail` and say so.** A wrongly-filed defect costs someone five
minutes; a softened assertion costs the campaign its meaning.

**App source stays untouched by anything whose purpose is turning a case green.**
