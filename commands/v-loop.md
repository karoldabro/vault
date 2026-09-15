---
description: Autonomous campaign against a real system. Picks an adapter, enumerates a backlog, works each case alone until every one has a verdict. Takes every decision in one opening exchange. Requires an arena you have named as disposable.
---

> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`. Every `$VAULT_FRAMEWORK_PATH/...` path below resolves under it.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here.

> **Spawning an agent:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/agent-conduct.md` first — it binds every agent spawned here, and `commands/v-loop/campaign-rules.md` adds only what it does not already own.

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first.

> **Touching a vault:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/vault-sync.md` first — every git call against a vault goes through `bin/vault-sync.sh`.

# /v-loop — autonomous campaign engine

`/v-loop` runs one loop against a **real system**: enumerate a backlog, work a case, take a verdict
from a verifier, repair what failed, verify again, stop at a cap. It runs for hours and decides
everything in one opening exchange.

**The loop is the command; the task is an adapter.** What a case is, who works it, and what decides
it are answered by `commands/v-loop/adapters/<name>.md`. Two adapters ship:

| adapter | the campaign it runs |
|---------|----------------------|
| `adapters/test-and-repair.md` | verify and fix a feature already built and running, by exercising it |
| `adapters/document-corpus.md` | rewrite a body of documents until each passes the project's document check |

Contract for writing a third: `commands/v-loop/adapters.md`.

It is not a rung on the `/v-do` → `/v-work` → `/v-team` ladder. That ladder decides and builds; this
works a backlog against something that already runs.

---

## Precondition — refuse without it

`/v-loop` requires an **arena**: a copy of the system the operator is willing to lose, separate from
anything they work on. The session stops until it has **two facts**, and refuses on each separately:

1. **the arena's name**, in words, from the operator. A stack the session inferred from a config file
   is not one anyone agreed to lose.
2. **the command that restores it**, which the session **runs once at intake and then re-reads the
   arena**. A restore command nobody has run is a guess. `git checkout -- <path>` restores tracked
   files and leaves every untracked file behind; the arena still carries the last run's output.

Neither is a judgement the session can reason its way past, which is the point. "Is this
destructive?" is a question a session talks itself out of at hour four.

A session that finds no arena **must** say so and stop, naming which of the two is missing.

**Use something cheaper instead when:**

| situation | use |
|-----------|-----|
| the work is one decision and one change | `/v-do` |
| the thing is not built yet | `/v-work`, or `/v-team` when a wrong design decision is expensive to reverse |
| you want an opinion on a design rather than evidence from a running system | `/v-team` |
| the backlog is under ~10 cases and you will watch it | `/v-do`, case by case |
| no adapter fits and you are not willing to write one | none of these; write the adapter first |
| there is no arena and you are not willing to build one | none of these; build the arena first |

A campaign costs far more than a lifecycle run: it runs for hours, spawns agents repeatedly, and
exercises a real system. That cost is what buys evidence a review cannot produce.

---

## Tools

claude-mem, Serena, MorphLLM and graphify are preferred and never gating. Present → use it; down →
health-check, warn once, fall back. Full rules: `$VAULT_FRAMEWORK_PATH/tool-playbook.md`.

---

## Step 1 — RESUME, or INTAKE

**Resume first.** Scan `<project-vault>/campaigns/` for a `STATE.md` whose retest queue or never-run
list is non-empty. Finding one, read it, read `rounds_used` from its frontmatter, and continue that
campaign. The campaign directory is named `YYYY-MM-DD-HHMM-<slug>`. A resumed session **must** carry
the round count forward rather than starting at zero.

**Otherwise run intake.** Ask everything the operator decides, **in one exchange**, and work alone
afterwards. Elicitation rules: `$VAULT_FRAMEWORK_PATH/commands/_shared/elicitation.md`.

| # | question | why it must be settled first |
|---|----------|------------------------------|
| 1 | which **adapter**, and the **target** it works on | it decides every slot below, and the target is settled by asking rather than by reading a branch name |
| 2 | where the **specification** lives | the backlog is built from it |
| 3 | the **arena**, and the command that restores it | both refusals above; the restore is run here, not just recorded |
| 4 | which **data** to load | fixture-scale data hides the defects that matter |
| 5 | the commit and **push cadence** | it decides whether work survives a session ending |
| 6 | what is **already known broken** | otherwise the run rediscovers it at full cost |

Caps carry defaults the operator may change in the same exchange:

| cap | default | what happens at it |
|-----|---------|--------------------|
| `loop_max_rounds` | 3 | the session stops, reports every case still open, and escalates |
| per-case **retry cap** (`max_fix_attempts`) | 3 | the case is recorded as deferred with what was tried, and the loop moves on |

**Then read the adapter** at `commands/v-loop/adapters/<name>.md` and record its six slots in
`STATE.md`. An adapter missing a slot is a defect in the adapter, not a gap for the session to fill
from memory.

**Then scaffold.** Create `<project-vault>/campaigns/<slug>/` from `$VAULT_FRAMEWORK_PATH/templates/campaign/`:
`STATE.md`, `ledger.md`, `result.md`, `defects.md` and `AGENT-BRIEF.md`. Create `campaigns/` and warn
once when it is absent.

**Append the ignore rule before the first result file is written.** When the project vault's
`.gitignore` lacks `campaigns/*/results/`, add it. Result files carry evidence drawn from real data
and must stay out of the vault remote. Anything a success criterion must read on a clean checkout
belongs in `ledger.jsonl`, which is tracked.

---

## Step 2 — GROUND, then enumerate

**Verify every environment fact with a command and keep what it returned.** Credentials, a token's
real permission surface, the arena being reachable, and the verifier running end to end on one case.
A cheap check ahead of an expensive one is the whole point.

**Enumerate the backlog before running anything**, using the adapter's `## Backlog` command. One
ledger row per case. The backlog is the denominator that gives "done" a meaning.

**Then ask what the definition of done requires that the verifier cannot detect.** A backlog built
from the verifier alone answers how much the tool can see, not how much work there is. Each such
clause **cites a written rule**; a clause resting on judgement is recorded as a finding, not worked.

**Every row's `reason` carries the verifier's own message text**, never a rule code the orchestrator
expands from memory. A campaign that summarises its verifier has stopped being grounded in it.

Every row carries a `conflicts_on` scope naming **every path the unit of work touches**, not just the
one the case is named for. Both are fields in `templates/campaign/ledger.md`.

---

## Step 3 — RUN

**Two agents run together only when their `conflicts_on` sets are disjoint.** A session decides this
from the values it just wrote. A `global` scope always runs alone. A read-only planning or review
agent is not an actor and may run beside one.

**The spawn envelope** every campaign agent receives carries, in full:

- `$VAULT_FRAMEWORK_PATH/commands/v-loop/campaign-rules.md` — the operating rules;
- the chosen `commands/v-loop/adapters/<name>.md` — how this campaign's work is done;
- the campaign's `AGENT-BRIEF.md` — the traps found so far;
- `$VAULT_FRAMEWORK_PATH/commands/_shared/agent-conduct.md` — how a spawned agent works and reports;
- the case's ledger row, including its `conflicts_on` scope;
- the **file fence**: what this agent owns, and what other agents hold right now.

**Every count in the envelope carries the command that produced it**, and the agent runs that command
rather than accepting the number. An orchestrator's summary is the thing most likely to be stale, and
an agent repairing what the brief describes rather than what the verifier reports is working from the
wrong document. Never put a line number in a brief where a `grep` would find it.

Each case writes `results/<case-id>.md` from `templates/campaign/result.md`, ending in the literal
line `VERDICT: PASS | FAIL | BLOCKED`. Any other final line reads as no verdict, and the case runs
again.

**A trap is added to `AGENT-BRIEF.md` the moment it costs a run**, by the orchestrator, so the next
agent does not pay for it twice.

---

## Step 4 — REPAIR, then RE-VERIFY

**A defect is filed only after it survives a check against current source.** Disproving a filing is
worth as much as fixing one.

**Who verifies depends on what the verifier is** — `commands/v-loop/adapters.md`, "The verifier
decides which rules apply". A command may be re-run by the agent that did the work, and the
orchestrator re-runs it too; the two must agree. A model always verifies in a separate spawn.

**A verdict expires when its case changes.** The ledger is append-only and the last line for an id
wins, so a re-verified case appends a row rather than editing one. An agent that reworks a case after
reporting says so, and the orchestrator re-runs the verifier before the row stands.

Every repair is recorded in the campaign's `defects.md` with the check that failed before it, the
verification output, and the exact revert.

---

## Step 5 — STOP

The loop ends on the first of these:

1. **Done** — the adapter's `## Stop rule` is met.
2. **Round cap** — `rounds_used` reaches `loop_max_rounds`. The session stops and reports every case
   still open. It always escalates rather than continuing.
3. **Retry cap** — a single case reaches `max_fix_attempts`. That case is deferred with what was
   tried; the rest of the loop continues.

---

## Step 6 — REPORT + CAPTURE

Report **exceptions**: what failed, what changed, what needs a decision. State plainly how many cases
**ran** against how many are **planned** — a backlog of 800 rows and 9 executed cases are different
achievements. Say which clauses of the definition of done had no detector. Put every deferred
mid-loop decision in front of the operator here.

Then run `/v-capture` for the session record.

---

## The two shapes

| shape | when | how |
|-------|------|-----|
| **one session** | the backlog fits inside one usage window | this session orchestrates agents directly and resumes from `STATE.md` after an interruption |
| **batched** | the backlog is larger than one usage window | a host timer starts a fresh session per batch; each reads the ledger, takes four cases, records, commits and exits |

**The unattended runner is built and handed over, and this session installs none of it.** Claude
Code's permission classifier refuses `crontab` edits and refuses to spawn `claude -p` from Bash, and
that guard stands. Build every part, prove what can be proven, and give the operator the two
commands. Say plainly that the first unattended tick is unproven and what to watch.
