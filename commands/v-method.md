---
description: Design the method for one heavy task. Reads the task, routes it on checkable properties, and writes a staged method file naming each stage's command, seats, tools, exit evidence and kill criterion. Writes the method; runs no stage.
argument-hint: <the task, in a sentence or two>
---

> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`. Every `$VAULT_FRAMEWORK_PATH/...` path below resolves under it.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here.

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs the method file this command writes.

> **Spawning an agent:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/agent-conduct.md` first — it binds any agent spawned here.

# /v-method — design the method, not the plan

`/v-method` takes one heavy task whose approach is unknown and writes a **method file**: an ordered
list of stages, each naming the command that runs it, the seats it spawns, the tools that prove it,
the evidence that lets it exit, and the observation that kills it.

It writes the method and runs no stage. The stages are existing commands with their own gates; a
command that both chose the method and executed it would grade its own choice.

**What it is for.** The operator holds a task that is too large for one session and does not yet know
how to drive the AI on it. `/v-method` answers that and nothing else.

---

## Three refusals

The command shall stop at each of these before it produces a method.

| condition | what the command does |
|-----------|----------------------|
| The task arrives with no **written problem statement** naming who the output is for | ask for one and stop. A method for an unstated problem is the failure this refusal exists to prevent |
| No success criterion is expressible as `WHEN <trigger> THE SYSTEM SHALL <observable>` | ask for one and stop. A campaign with no observable target closes against whatever it produced |
| The task fits one rung of the `/v-ask` → `/v-do` → `/v-work` → `/v-team` ladder | name the rung and stop. A method file costs more than the work. Rules: `$VAULT_FRAMEWORK_PATH/vault/indications/light-command-siblings.md` |

**Honesty the command states up front, once, to the operator.** No study shows that writing a
methodology in advance improves the outcome. What carries evidence is each part it prescribes: a
verifier, a checklist, a named constraint, a kill criterion. This command composes measured parts and
claims nothing for the composition.

---

## Step 1 — INTAKE

Ask everything in one exchange, then work alone. Technique menu and stopping rule:
`$VAULT_FRAMEWORK_PATH/commands/_shared/elicitation.md`.

**One question has no safe default and always waits for the operator:**

> **Is the budget fixed, or are the criteria fixed?** A fixed budget varies the scope; fixed criteria
> vary the time. One task promises one of them, and the method file records which.

Record the answer and what it gave up. A fixed budget means named criteria may be cut and the method
file says which. Fixed criteria mean the session count is open and the method file says so.

Everything else that stays unanswered becomes a **stated default**, written into the method file and
flagged for correction. The run shall proceed with those recorded.

## Step 2 — LOAD CONTEXT

Read `$VAULT_FRAMEWORK_PATH/commands/v-work/steps/02-load-context.md` and run it. Vault first, then
the graph, then source. The method depends on what this project already decided, so an existing
decision record constrains the routing rather than being rediscovered inside a stage.

## Step 3 — ROUTE

Read `$VAULT_FRAMEWORK_PATH/commands/v-method/routing.md` once. It carries four tables: task
property to method, seats per stage, tools that prove an implementation, and tools that prove a
cited claim.

1. **Decide each property against the task in front of you**, and record the answer. A property is a
   fact about the task, so each answer shall be a yes or a no with a reason.
2. **Every property that fires contributes a stage**, in the table's order.
3. **A task that fires no property gets the fixed pipeline**: localise, repair, validate. That is the
   baseline an agent architecture has to beat, and it is the first candidate rather than the last.
4. **Record the properties that did not fire.** The routing is a heuristic, so the method file keeps
   the whole answer set and a later session scores it against what happened.

## Step 4 — WRITE THE METHOD FILE

Instantiate `$VAULT_FRAMEWORK_PATH/templates/method.md`.

**Path.** `_features/<feature>/method.md` when this session has a feature workspace; otherwise
`<project-vault>/plans/YYYY-MM-DD-HHMM-<slug>.method.md`.

**Every stage row shall carry five things.** A row missing any one of them is a stage nobody can run
or close:

| field | what it holds |
|-------|---------------|
| command | the rung that runs this stage — `/v-do`, `/v-work`, `/v-team`, `/v-loop`, or `/v-pm` |
| seats | the personas it spawns, from routing Table 2, each with the affordance it owns |
| tools | the checks that prove it, from routing Tables 3 and 4 |
| exit evidence | what must exist for the stage to be finished, as a path or a command |
| kill criterion | the observation that stops the work, **plus the exact file and field its verdict is read from** |

**A kill criterion shall name its field.** A production gate once flagged none of a hundred cases it
should have caught, because its condition read a field that was always empty. So the criterion names
the file and the field, and the stage's own check re-reads that field rather than trusting the
stage's report.

**Kill criteria shall be written before the stage runs.** A gate whose conditions arrive after the
evidence is a rubber stamp.

**A loop shall name its signal, its interval and its iteration count.** Fewer than one in five published
improvement-cycle projects recorded more than one cycle; a loop without those three is a single pass
wearing a loop's name.

**A script shall produce each stage's verdict.**
`$VAULT_FRAMEWORK_PATH/bin/gate.sh verdict <plan> --run` executes the named check and writes the
verdict and the captured output into the file itself. Contract:
`$VAULT_FRAMEWORK_PATH/vault/architecture/session-gates.md`.

Then run `$VAULT_FRAMEWORK_PATH/bin/doc-lint.sh <method file>` and fix what it reports.

## Step 5 — HAND OFF

Name the method file's path and the first stage's command in one line. The operator runs that
command; `/v-method` stops here.

**The seam with `/v-pm`.** Two commands, two questions. `/v-pm` owns what the product must do — the
`requirements.md` rules, the glossary, the variant tables and an appetite per repo. `/v-method` owns
how to work on it. A task whose business logic is unclear runs `/v-pm` first, because choosing a
method requires a stated problem. A task whose requirements are clear and whose approach is not runs
`/v-method` first.

`/v-method` consumes the appetite `/v-pm` wrote and re-derives none of it. Its stage rows are coarser
than session rows: it orders and sizes the stages, and each stage's own session splits the work
inside one. A method whose stages exceed the appetite cuts scope and records the cut.

---

## Required output — to the user

```
Method: <path to the method file>
Fixed: <budget | criteria>  — given up: <what the other one loses>
Stages: <N>, first is <command> on <scope>
Assumed: [the stated defaults, so they can be corrected]
Open: [anything that could not be routed, and the properties whose answer was a guess]
Next: run <command> on <scope>
```

**Omit any line with nothing to say.** The omit rule cuts good news and keeps every warning: a stated
default, a property answered by guess, a stage whose tools this project lacks, and an appetite the
stages exceed shall all be surfaced, however brief.
