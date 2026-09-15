# Campaign operating rules

Binding on every agent `/v-loop` spawns, whatever the adapter. Each rule below was paid for by a run
that went wrong without it.

**What this file leaves to others.** Only rules with no home elsewhere are written here. The rest are
already binding and are named once:

| already owned by | what it governs |
|------------------|-----------------|
| `commands/v-loop/adapters.md` | the six slots an adapter fills, which verification rule applies, and how a campaign proves it can fail |
| `commands/v-loop/adapters/<name>.md` | what a case is for this campaign, who works it, and what decides it |
| `commands/_shared/agent-conduct.md` | writing to disk as you work, the order of a report, counts that carry their command, reading a whole source, treating a premise as possibly mistaken, and the orchestrator's half of a fan-out |
| `commands/_shared/communication.md` | what reaches the operator, and in what order |
| `commands/_shared/document-standard.md` | every file an agent writes |
| `commands/_shared/definition-of-done.md` and `commands/v-team/steps/04-execute-loop.md` | the test-quality gate: a test must fail when the code is broken |
| `commands/_shared/critic-panel.md` | the finding schema, severity, and the grounding split that separates a fault from an opinion |
| `commands/_shared/elicitation.md` | when an operator is asked something, and where the answer lives |
| `commands/_shared/vault-sync.md` | git against a vault |

---

## Evidence

**Every verdict must rest on the running system.** The adapter names what produces it — a command's
exit code, a request, a click, a query. Reading source is how you form a hypothesis, and it is the one
thing that closes no case.

**A defect must survive a check against current source before it is filed.** In one campaign six of
seventy-three filings were disproved this way, several written by the orchestrator itself.

**Every fix must be proven by the means that would catch its failure.** A fix proven by unit tests and
never exercised in a browser is recorded that way.

**Every count you are given must be re-derived from the command that produced it.** Three case briefs
in one campaign carried a wrong number, and each was caught only because the agent went to the source.
A brief is the orchestrator's summary, and a summary is the thing most likely to be stale.

---

## Cases

**Every case must state what it proves as an outcome someone can observe.** "Tapping Save shows the
new title in the feed" is a case; "test the save button" is a label.

**Every case must carry the adapter's failure shape**, so that a case which proves nothing is visible
as such. What that shape is — a contrary condition on the row, or a control case that must come back
unchanged — is the adapter's answer.

**Every exclusion must be recorded with its reason.** A placeholder route, a redirect sharing one
expression, an option absent from the interface. An unexplained gap reads as an oversight forever.

**Every baseline must be read from the live system at run time.** A literal recorded at planning time
goes stale the moment another case changes the system; one campaign corrected eight specs for this.

**An assertion must keep the discrimination its case exists for.** Turning an exact count into
"greater than zero" destroys it.

---

## Dispatch

**Two agents run together only when their `conflicts_on` sets are disjoint.** A `global` scope runs
alone. A session decides this from the ledger rows it wrote, so it needs no counter.

**A conflict scope must name every path the unit of work touches.** Thirteen cases in one campaign
each wrote two files, and a scope naming only the first would have let a second agent take the other.

**Every brief must fence its agent's files**: what this agent owns, and what other agents hold right
now. Two agents once built the same fix in parallel because the fence was unstated.

**The orchestrator must add a trap to the campaign's `AGENT-BRIEF.md` the moment it costs a run**, so
the next agent does not pay for it twice.

---

## Safety

Each rule names the sanctioned action, because that is the form that holds across a long run.

1. **Run the restore command once at intake and re-read the arena.** A restore nobody has run is a
   guess, and the commonest guess leaves every untracked file in place.
2. **Name each file in every commit.** `scripts/staging-hook.sh` denies a pathspec-less commit, a
   `-a` sweep, an amend and a hard reset before they run.
3. **Rewrite history only on a branch nobody else holds.** On a shared branch, add a new commit.
4. **Pass the path to a credential.** A connection string, key or password stays in the file it lives
   in, and the campaign records where to find it.
5. **Read every restoration back.** Restoring a value and proving it restored are different acts.
6. **Disarm every fault the case armed**, in a teardown registered by the arming helper, so a case
   cannot forget and poison the next one.
7. **Check the ignore rules before a finding cites evidence.** A repo-wide `*.log` rule once excluded
   every file the findings pointed at, and evidence a gate must read on a clean checkout belongs in a
   tracked file.
8. **Keep a campaign inside its own directory and its arena.** Anything outside stays the operator's,
   including the checkout another session is working in.
9. **Ask before any irreversible act the operator did not already sanction.**
