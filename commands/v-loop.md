---
description: Autonomous test-and-fix campaign against a feature already built and running. Takes every decision in one opening exchange, then works alone until every case has a verdict. Requires a stack you have named as disposable.
---

> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`. Every `$VAULT_FRAMEWORK_PATH/...` path below resolves under it.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here.

> **Spawning an agent:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/agent-conduct.md` first — it binds every agent spawned here, and `commands/v-loop/campaign-rules.md` adds only what it does not already own.

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first.

> **Touching a vault:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/vault-sync.md` first — every git call against a vault goes through `bin/vault-sync.sh`.

# /v-loop — autonomous test-and-fix campaign

`/v-loop` verifies and repairs a feature that is **already built and running**. It plans a case per
interactive element and state, turns each into an executable test in the project's own framework,
runs it against the real system, files what fails, fixes it, and retests — until every case has a
verdict and none fails, or a cap stops it.

It is not a rung on the `/v-do` → `/v-work` → `/v-team` ladder. That ladder **builds**; this
**verifies and repairs what is already built**, so neither escalates into the other.

---

## Precondition — refuse without it

`/v-loop` requires a **disposable stack**: one the operator is willing to lose, separate from
anything they work on. **The operator names the stack**, in words, and the session stops until it
has that name. A stack the session inferred from a config file is not a stack anyone agreed to lose.

A session that finds no such stack **must** say so and stop, naming what is missing. This is the
line that keeps a campaign's destructive commands away from a working database.

**Use something cheaper instead when:**

| situation | use |
|-----------|-----|
| the feature is not built yet | `/v-work`, or `/v-team` when a wrong design decision is expensive to reverse |
| one screen, a handful of cases, and you will watch it | `/v-do` |
| you want a second opinion on a design rather than evidence from a running system | `/v-team` |
| there is no disposable stack and you are not willing to build one | none of these; build the stack first |

A campaign costs far more than a lifecycle run: it runs for hours, spawns testers repeatedly, and
exercises a real system. That cost is what buys evidence a review cannot produce.

---

## Tools

claude-mem, Serena, MorphLLM and graphify are preferred and never gating. Present → use it; down →
health-check, warn once, fall back. Full rules: `$VAULT_FRAMEWORK_PATH/tool-playbook.md`.

---

## Step 1 — RESUME, or INTAKE

**Resume first.** Scan `<project-vault>/campaigns/` for a `STATE.md` whose retest queue or never-run
list is non-empty. Finding one, read it, read `rounds_used` from its frontmatter, and continue that
campaign. The campaign directory is named `YYYY-MM-DD-HHMM-<feature-slug>`, matching the plan
filenames. A resumed session **must** carry the round count forward rather than starting at zero.

**Otherwise run intake.** Ask everything the operator decides, **in one exchange**, and work alone
afterwards. Elicitation rules: `$VAULT_FRAMEWORK_PATH/commands/_shared/elicitation.md`.

| # | question | why it must be settled first |
|---|----------|------------------------------|
| 1 | which **feature**, and its **branch** | every later choice depends on it, and it is settled by asking rather than by reading the branch name |
| 2 | where its **specification** lives | the case list is built from it |
| 3 | the **disposable stack**, and the command that rebuilds it | a destructive mistake must stay away from a working database |
| 4 | which **data** to load | fixture-scale data hides the defects that matter; realistic imported data finds them |
| 5 | the commit and **push cadence** | it decides whether work survives a session ending |
| 6 | what is **already known broken** | otherwise the run rediscovers it at full cost |

Caps carry defaults the operator may change in the same exchange:

| cap | default | what happens at it |
|-----|---------|--------------------|
| `loop_max_rounds` | 3 | the session stops, reports every case still failing, and escalates to the operator |
| per-defect **retry cap** (`max_fix_attempts`) | 3 | the defect is recorded as deferred with what was tried, and the loop moves on |

**Then scaffold.** Create `<project-vault>/campaigns/<slug>/` from `$VAULT_FRAMEWORK_PATH/templates/campaign/`:
`templates/campaign/STATE.md`, `templates/campaign/ledger.md`, `templates/campaign/result.md`,
`templates/campaign/defects.md` and `templates/campaign/TESTER-BRIEF.md`. Create `campaigns/` and
warn once when it is absent.

**Append the ignore rule before the first result file is written.** When the project vault's
`.gitignore` lacks `campaigns/*/results/`, add it. Result files carry evidence drawn from real data
and must stay out of the vault remote.

A campaign against a phone or a device also reads `$VAULT_FRAMEWORK_PATH/prompts/on-device-e2e-campaign.md`,
which carries the traps that adapter has already paid for.

---

## Step 2 — GROUND, then enumerate

**Verify every environment fact with a command and keep what it returned.** Credentials, the token's
real permission surface, the device or stack being reachable, and one existing test running end to
end. A cheap check ahead of an expensive one is the whole point: a curl costs a second and a full
run costs ten minutes.

**Enumerate the backlog before running anything.** Build it from the route or endpoint table rather
than from intuition, and write one ledger row per case. The backlog is the denominator that gives
"done" a meaning.

Every case row **must** carry an `injection` — a contrary condition that must produce a *different*
outcome — and a `conflicts_on` scope. Both are fields in `templates/campaign/ledger.md`.

---

## Step 3 — RUN

**One tester runs at a time unless the conflict sets are disjoint.** A session decides this from the
`conflicts_on` values it just wrote. A `global` scope always runs alone. A read-only planning or
review agent is not a tester and may run beside one.

**The spawn envelope** every campaign agent receives carries, in full:

- `$VAULT_FRAMEWORK_PATH/commands/v-loop/campaign-rules.md` — the operating rules;
- the campaign's `TESTER-BRIEF.md` — the traps found so far;
- `$VAULT_FRAMEWORK_PATH/commands/_shared/agent-conduct.md` — how a spawned agent works and reports;
- the case's ledger row, including its `conflicts_on` scope;
- the **file fence**: what this agent owns, and what other agents hold right now.

Each case becomes an executable test in the project's own framework and is run against the real
system. Each writes `results/<case-id>.md` from `templates/campaign/result.md`, ending in the
literal line `VERDICT: PASS | FAIL | BLOCKED`. Any other final line reads as no verdict, and the
case is run again.

---

## Step 4 — FIX, then RETEST

**A defect is filed only after it survives a check against current source.** Disproving a filing is
worth as much as fixing one.

**The agent that writes a fix must not produce its retest verdict.** An agent grading its own work
skews positive, so verification is a separate spawn with the failing case and the fix commit.

Every fix is recorded in the campaign's `defects.md` with the test that failed before it, the
verification output, and the exact revert.

---

## Step 5 — STOP

The loop ends on the first of these:

1. **Done** — every ledger row is terminal, and none reads `fail`.
2. **Round cap** — `rounds_used` reaches `loop_max_rounds`. The session stops and reports every case
   still failing. It always escalates rather than continuing.
3. **Retry cap** — a single defect reaches `max_fix_attempts`. That defect is deferred with what was
   tried; the rest of the loop continues.

Unanimous green from the agents is not a stop condition on its own; the ledger decides it.

---

## Step 6 — REPORT + CAPTURE

Report **exceptions**: what failed, what changed, what needs a decision. State plainly how many
cases **ran** against how many are **planned** — a backlog of 800 rows and 9 executed tests are
different achievements. Put every deferred mid-loop decision in front of the operator here.

Then run `/v-capture` for the session record.

---

## The two shapes

| shape | when | how |
|-------|------|-----|
| **one session** | the backlog fits inside one usage window | this session orchestrates testers directly and resumes from `STATE.md` after an interruption |
| **batched** | the backlog is larger than one usage window | a host timer starts a fresh session per batch; each reads the ledger, takes four cases, records, commits and exits |

**The unattended runner is built and handed over, and this session installs none of it.** Claude
Code's permission classifier refuses `crontab` edits and refuses to spawn `claude -p` from Bash, and
that guard stands. Build every part, prove what can be proven, and give the operator the two
commands. Say plainly that the first unattended tick is unproven and what to watch.
