# Step 3 — PLAN PANEL (plan mode)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

> **Spawning an agent:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/agent-conduct.md` first — it binds every agent spawned here.

Draft the plan and its session briefs, then run a parallel review panel over them until it converges.
Every file written here is a vault file in the plan home from Step 1. `/v-pm` holds no opinion of its
own: each decision names the evidence it rests on, and each option it rejects names why.

## (a) Research — on by default
Run `$VAULT_FRAMEWORK_PATH/commands/v-work/steps/03-propose.md` §3a.0b before drafting: how projects of
this size solve this class of problem, which products or packages already do it, which approaches
failed. It is on unless `--no-research` was passed. Cite each source. Sources and rejected options go
to `plan.trail.md`; the plan keeps only the decision and the evidence column.

## (b) Draft the plan, the requirements and the briefs
Instantiate, in the plan home:

1. `plan.md` from `$VAULT_FRAMEWORK_PATH/templates/feature-plan.md`. Fill the Need, the operator's
   success criteria from Step 1, the four default done lines plus the operator's additions, the
   decisions with their evidence, and the solution shape.
2. `requirements.md` from `$VAULT_FRAMEWORK_PATH/templates/_features/requirements.md` (single-repo:
   `<project-vault>/requirements/<feature>.md`): business rules as `REQ-NN`, glossary, variant and state
   tables. Write only the rules the need implies.
3. `contracts.md` from `$VAULT_FRAMEWORK_PATH/templates/_features/contracts.md`, multi-repo only: the
   interface between the repos as tables, never prose.
4. `plan.trail.md` from `$VAULT_FRAMEWORK_PATH/templates/trail.md`.

**Split into sessions.** `/v-pm` decides how many. Apply the sizing rules in
`$VAULT_FRAMEWORK_PATH/personas/_shared/planning/delivery-planner.md` `## Mandate`, and stay
proportional to the tier: a `small` tier is usually one session. For each session:

- a `## Sessions` row: the repo's absolute path, the scope, a command from the ladder, `status: todo`,
  `depends`, and the `REQ-NN` ids it satisfies in `req`;
- a `## Cross-session contracts` row for each dependency, with the exact shape handed over;
- its id in the `sessions` cell of each success criterion it reaches;
- one brief, `briefs/<id>-<slug>.md`, from `$VAULT_FRAMEWORK_PATH/templates/handoff.md`. Set `plan` to
  the plan's absolute path and add `id`. `## Left to do` names the exact files from the code index.
  `## Goal` is one sentence. `## Success criteria` copies the criteria the row reaches. `## Next command`
  holds the run line, and nothing else:

```
cd <repo> && claude --add-dir <plan folder> "<command> <absolute plan path>#<id>"
```

## (c) Seat the panel
Select reviewers with `$VAULT_FRAMEWORK_PATH/personas/_resolution.md` §2.3, capped by the tier
(`personas/_shared/planning/README.md` `## Scale tiers`). Spawn them in parallel, one message, each as
its `base_agent`, read-only. The envelope follows `$VAULT_FRAMEWORK_PATH/commands/v-team/steps/03-propose-loop.md`
§(c), with these inputs: the current `plan.md` and every brief; the need; the tier; the Step 2 digest
and code index; the lens file verbatim; `personas/_shared/planning/README.md`; and, from round 2, the
prior round's merged findings. The `consumer` reviewer dry-runs one brief's run line against the
command it names.

## (d) to (f) The loop
Run §(d) to §(f) of `03-propose-loop.md` unchanged: the finding schema, the de-biased synthesizer, and
the convergence rules. The synthesizer writes to the trail of this plan, `plan.trail.md`. The round cap
is the tier's. `/v-pm` runs no `(f2)` test-design fan-out: test hints stay in the trail, and each
executing session designs its own tests. A revision rewrites `plan.md` and the briefs to the new
current state.

## (g) Finalise
Run, and fix until each exits 0:

```bash
$VAULT_FRAMEWORK_PATH/bin/pm-plan.sh check <plan>
$VAULT_FRAMEWORK_PATH/bin/gate.sh master <plan>
$VAULT_FRAMEWORK_PATH/bin/doc-lint.sh <plan> <plan folder>/briefs/*.md
```

Set `status: proposed`. A plan that `check` refuses never reaches the approval gate.

## Required output
```
Research: [sources + takeaways | --no-research | unavailable]
Panel: <n> reviewers, <n> rounds   (skipped: …)   ·   still open: <n>
Sessions: <n> in <w> waves   ·   first wave: [ids]
Criteria reached: [SC id → session ids]
Check: pm-plan.sh check exit 0 · gate.sh master exit 0
```
Mark PLAN PANEL `completed` → the approval gate.
