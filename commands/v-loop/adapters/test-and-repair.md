# test-and-repair — verify and fix a feature that is already built and running

Turns each interactive element and state of a running feature into an executable test, runs it
against the real system, files what fails, fixes it, and retests. The rules below were paid for by
two campaigns on different stacks: a Laravel feature under Playwright and PHPUnit, and a Flutter app
on a real phone over adb.

A campaign against a phone or a device also reads `prompts/on-device-e2e-campaign.md`, which carries
the traps that adapter has already paid for.

**What this file leaves to others.** The slots it fills and the verification rule it inherits are
defined in `commands/v-loop/adapters.md`. Everything binding on every campaign agent whatever the
adapter — evidence, dispatch, the file fence, the safety list — is in
`commands/v-loop/campaign-rules.md` and is not repeated here. The test-quality gate, that a test must
fail when the code is broken, is owned by `commands/_shared/definition-of-done.md`.

## Unit of work

One case: one interactive element or state, stated as an outcome the user sees. "Tapping Save shows
the new title in the feed" is a case; "test the save button" is a label.

Every case must become an **executable test in the project's own framework**. A case that stays prose has
not been run.

## Backlog

Built from the route or endpoint table. Every row must trace to an entry there, and all of them
must exist before anything runs. A surface that issues no requests still gets rows; its faults are hostile content or a
device-level condition rather than a response code it has no way to receive.

Every exclusion must be recorded with its reason: a placeholder route, a redirect sharing one expression,
an option absent from the interface. An unexplained gap reads as an oversight forever.

## Actor

One tester agent per case, spawned with the campaign's `AGENT-BRIEF.md`, its ledger row, and its file
fence. It authors the test, runs it against the real system, and writes `results/<case-id>.md`.

**A fix and its verdict must come from different agents** — see `## Verifier`.

## Verifier

A run of the executable test against the running system. Reading code forms a hypothesis and closes
no case.

The test is a command, but **the judgement of whether a red case means a broken test or a broken app
is a model's**, so verification of a fix is a separate spawn with the failing case and the fix commit.

**Discriminator: an injection per case** — a contrary condition that must produce a *different*
outcome, written before the case runs. When the injected condition gives the same result as the
normal one, the case proves nothing and its verdict is `BLOCKED`.

An injection case must prove the app degrades correctly: it stays on the right screen, it tells the user,
and it leaves the control usable. Surviving without a crash is not a passing bar.

**Baselines must be read from the live system at run time.** A literal count goes stale the moment
another case seeds a row. An assertion must keep the discrimination its case exists for — turning an
exact count into "greater than zero" destroys it.

## Caps

3 rounds. 3 fix attempts per defect, after which it is deferred with what was tried.

## Stop rule

Every ledger row terminal and none reading `fail`. Unanimous green from the agents is not a stop
condition; the ledger decides it.

## Arena

A stack the operator named as disposable, with the command that rebuilds it.

1. **Prove the environment is pinned before every suite run.** `artisan test` destroyed a working
   database twice in one campaign, through `variables_order` leaving `$_SERVER` carrying the
   container's real connection.
2. **Rebuild through the stack's own restore script.** That is the sanctioned path to a clean
   database and the only one.
3. **Restart the queue workers after a code change**, or a correct fix reads as broken.
4. **Tear down on the full case id** (`LIKE 'QA <case-id>%'`). One truncated wildcard destroyed two
   other cases' fixtures and turned passing cases red.
5. **An asset rebuild waits until no tester is running.** A spec failing against a half-written
   bundle wastes the round.

## When a case goes red

Correct the case when the case is wrong, and file the defect when the app is wrong.

| the test is wrong | the app is wrong |
|-------------------|------------------|
| It asserts something the product did not promise — a widget absent by design, a count the seeded data does not guarantee, a precondition the shipped data makes impossible. | It asserts the outcome a user is entitled to, and the app fails to deliver it. |
| Correct the case, run the corrected version, and state the correction. | Record `fail`, write the finding, move on. |

**When the answer is unclear, you must record `fail` and say so.** A wrongly-filed defect costs someone five
minutes; a softened assertion costs the campaign its meaning.

**App source must stay untouched by anything whose purpose is turning a case green.**

## In a browser

Applies to any surface a user looks at.

**Findings must come from a real browser at real data volume.** A missing stylesheet, a raw translation
key as a column header and an empty tab are all invisible to a suite asserting structure.

**Assertions must read computed style.** A class-name assertion passes against unstyled markup.

**Text must be read with `textContent`.** `innerText` applies CSS transforms, so an uppercased element
defeats both positive and negative assertions.

**A new surface must be judged as a guest** on the page it was added to. A section that saves differently
from the page around it is a fault rather than a preference.

**The whole journey must be walked** — mail, click, confirmation, action, destination — naming every point
where a user could lose the thread. Integration failures live at the seams.

**The visual language is prescribed.** You must read the project's own architecture documents before judging
colour, spacing or type, and cite them when a finding contradicts one.

## What the screen and the truth disagree about

The defects that matter most live here. Look for them deliberately.

- **Does every surface state the same quantity?** A headline count, a row list, an admin queue and an
  email can each read a different field for the same thing.
- **Is the audience right?** A list keyed to the viewer rather than the subject shows an empty screen
  to someone entitled to see it. Ask what the list is *of*.
- **What does the default state show?** Count what a real user would actually see. When moderation
  holds 768 of 793, the feature is empty for almost everyone, and that is a launch decision.
- **Does the action reach the engine?** A setting written through a cache with no expiry changes
  nothing. Prove the write moves behaviour rather than the row.
