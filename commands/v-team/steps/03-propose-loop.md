# Step 3 — PROPOSE (panel loop)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

Draft a plan, then run a **panel → synthesize → re-loop** until it converges. Critics work in parallel,
each through its own tool-grounded lens, and share state **only via the revised plan** (no agent-to-
agent messaging — independence is what makes the panel worth its cost). Do not write source code here.

**Hooks.** `pre_propose` fires once before this loop starts and `post_propose` once after it converges
(before the approval gate) — the internal critic **rounds are non-hookable**. See `vault-guide.md` §1.1.

---

## (a) Draft plan v0

Read `$VAULT_FRAMEWORK_PATH/commands/v-work/steps/03-propose.md` and run **§3a (engineering design) only** —
Serena/graph orientation, impact scope, dependency-ordered implementation steps, test plan. **Skip
§3a.3** (the panel replaces ad-hoc agent dispatch) and **§3a.6** (the panel replaces the lite critic),
and **defer §3b** (vault-write dedupe) until after convergence.

**Run both front gates while drafting v0 — before the panel spawns:** §3a.0a **clarify** (surface the
assumptions the draft rests on and ask any plan-changing questions via `AskUserQuestion` now — cheaper
to resolve direction before three critics review a misunderstood task) and §3a.0b **external research**
(cite how the wild solves this; reconcile any contradicting consensus). Record both in the plan artifact
so critics can see them — an **unresearched design** or an **unsound assumption** is a legitimate
finding for a critic to raise (grounded by the missing citation / the untested assumption).

Instantiate `$VAULT_FRAMEWORK_PATH/templates/plan.md` into
`<project-vault>/plans/YYYY-MM-DD-HHMM-<slug>.md` and `$VAULT_FRAMEWORK_PATH/templates/trail.md` into
the sibling `<same-slug>.trail.md`. **Two files, two classes.** The plan carries the current state of
the design and is rewritten in place each round — it never accumulates a `Round 0` section, a draft
marker or a revision log. The trail carries everything about how the design got there. If `plans/`
doesn't exist, create it (warn once; add `add_folders: [plans]` to `VAULT.md` so it's recognised) —
don't halt.

## (b) Load + select critics

Use the pack + selected critics resolved in the ANALYZE addendum (`personas/_resolution.md`). Read each
selected persona file once (shared base + pack overlay composed). Default ~3 critics (business packs
default 4, per `_resolution.md` §2.2), hard max 5.

**`_shared/consumer.md` holds a guaranteed seat on this panel** (`_resolution.md` §2). Every other
lens reviews the mechanism; this one asks whether the agent, command or operator receiving the plan
can produce one correct output from the exact text the plan hands it. Drop it only when the change
creates no handoff at all, and say so in the trail. When architect + consumer + the triggered lens +
`skeptic` exceed the default 3, raise `team_max_parallel_critics` to 4 for the run rather than
dropping a triggered lens.

## (c) Parallel critic spawn

One message, **multiple `Agent` calls** — one per selected persona, spawned as its `base_agent`
(fallback: `Explore` with the persona block as prompt). Critics are **read-only**. Each critic envelope:

- the **current plan** (its present state, from the artifact — not a diff and not a round history);
- the **task restatement + keywords** (ANALYZE);
- the **LOAD-CONTEXT digest** — indications, ADRs, conventions, **and (feature mode) the feature's
  `requirements.md` — its business rules (`REQ-NN`) + `## Variant & state rules` tables + glossary** (so
  critics and the test-design fan-out reason from the product's business logic, not just code);
- its **persona block verbatim** (mandate · bound analyzer · rubric · checklist);
- (R ≥ 1) the **prior round's merged findings**, so it sees what changed and whether its concern was
  addressed.

Instruct each critic to **run its bound analyzer first** and cite real signals — the persona interprets
tool output, it does not replace it.

**The `consumer` critic's envelope carries one extra instruction:** name the riskiest handoff this
plan creates, write out the **literal text its receiver gets** — not a description of it — then
produce **one real output** from it: one shot, one walk answer, one parsed value, one row. That text
and that output go in the finding's `check` field; they are its grounding. A description of the
handoff is not a dry run and grounds nothing.

Also put `_shared/communication.md` in every critic envelope, scoped to the **free-text** fields
(`issue`, `recommendation`): one sentence, plain words, no restated context. The schema itself is
machine-read and unaffected — but these strings are what §(e).7 may surface to the user, and a
subagent inherits neither the output style nor the dispatcher's binding line.

## (d) Finding schema (each critic returns)

```
PERSONA: <name>
VERDICT: APPROVE | APPROVE_WITH_NITS | REQUEST_CHANGES | BLOCK
FINDINGS:
  - id: <persona>-<n>
    severity: BLOCKER | MAJOR | MINOR | NIT
    grounding: confirmed | advisory      # confirmed = a concrete check backs it
    check: <analyzer output / test / grep / static rule that confirms it — or "none">
    target: <plan step # / area>
    issue: <one sentence>
    recommendation: <concrete plan change>
PROPOSED_TESTS:
  - id: <persona>-t<n>
    kind: unit | feature | integration | e2e | widget | golden
    target: <behavior / endpoint / widget>
    intent: <regression it guards>
    priority: must | should | nice
NEW_SINCE_LAST_ROUND: [<ids>]            # empty in round 0
```

**Grounding rule:** a finding may be `BLOCKER`/`MAJOR` and force a plan change **only if
`grounding: confirmed`**. `advisory` findings are recorded and surfaced but **never block convergence**
(this is the defense against the false-positive trust cliff). Each critic caps `PROPOSED_TESTS` at ~3,
targeting its highest-severity findings.

## (e) Synthesize + revise (inline, main loop — de-biased)

The synthesizer is itself an LLM-judge, so neutralise its known biases:

1. **De-bias:** rank findings **blind to which persona raised them**; randomize finding order (position
   bias); penalize verbose-but-empty findings. `grounding` is **critic-owned**: the synthesizer may not
   re-grade a finding's grounding downward to alter its blocking status.
2. **Dedupe / cluster** across personas (same step flagged twice → one cluster).
3. **Resolve conflicts** by surfacing the trade-off **explicitly** in the plan (e.g. perf cache vs
   security freshness). Irreconcilable → escalate to the user at the approval gate; **never silently
   pick a side.**
4. **Revise the plan:** apply confirmed BLOCKER/MAJOR recommendations; record MINOR/NIT and advisory as
   "Open trade-offs / deferrals" with rationale. Bump to v(R+1).
5. **Demote `PROPOSED_TESTS` to advisory test hints.** Design critics review *design*, not written tests,
   so their `PROPOSED_TESTS` are **not** authoritative — write them to the
   **`## Advisory test hints`** section of the **trail sidecar**, never to the plan. The §(f2) test-design fan-out is the **sole authoritative writer** of
   the Test backlog and reconciles these hints into it. (The §(d) schema still emits
   `PROPOSED_TESTS`; only their consumption changes.)
6. **Append** round R to the **trail sidecar** (`plans/<slug>.trail.md`, `## Findings & dispositions`
   and `## Metrics`), never to the plan: each finding's disposition (applied / deferred / rejected +
   reason) plus new confirmed blockers, findings-delta, per-persona overlap, confirmed-vs-advisory
   counts, previously-confirmed findings dropped this round (sycophancy flag) and token cost. The
   plan itself is **rewritten to the new current state** — a superseded step is deleted, not struck
   through. A critic-assigned `grounding: confirmed` BLOCKER/MAJOR dispositioned anything other than
   **applied** surfaces at the approval gate as a **minority flag** — regardless of relabeling.
7. **Cap what reaches the user.** The trail is written **to the sidecar**; the panel's own
   output is the single largest block of text this command can put in front of the user, and the
   Claude Code output style does **not** reach spawned subagents — so this step is the only place it
   is controlled. To the user, surface **only**: confirmed findings that changed the plan, one plain
   line each; plus every item §(e).3, §(e).6 and §(f) mark as escalation, minority flag, or capped
   convergence. Everything else — approvals, nits, advisory findings, per-round metrics, token
   costs — goes to the artifact and is never printed. Critics' free-text `issue` and `recommendation`
   fields are **user-facing prose** when surfaced: rewrite them per `_shared/communication.md` rather
   than pasting the schema.

## (f) Convergence — stop on ANY

1. **Round cap** — `team_max_rounds` (default **2**). Hard ceiling.
2. **No-new-blocking-findings** — a full round adds **no new confirmed BLOCKER/MAJOR**
   (`NEW_SINCE_LAST_ROUND` is only advisory / MINOR / NIT).

**Unanimous approval is NOT a stop condition by itself.** Cap hit with open confirmed blockers → stop
and flag the plan `CONVERGENCE: capped with N open blockers` for the approval gate. **Never loop past
the cap.** (Observability note: if round 2 routinely yields no new confirmed blocker on your projects,
set `team_max_rounds: 1` and make round 2 opt-in for high-risk work.)

## (f2) Test-design fan-out (generation only)

After the *design* plan converges (f) and before finalise (g), design the tests as a **first-class
generative activity** — split out of solution design. This sub-phase performs **no confirmation**: it
**only generates** (all confirmation is post-impl in EXECUTE §5.3 — the generators bind no analyzer and
never seat on the critique panel). It is the **sole authoritative writer** of the Test backlog.

**Gating — fail open.** Run `(f2)` by default for any diff touching endpoints/handlers/migrations/business
logic. **Skip only** pure refactor/docs/formatting diffs, with a one-line note surfaced at the approval
gate (the happy-path bias this counters must not gate its own activation).

1. **Spawn the generators** (parallel, one message — reuse only the spawn-and-merge skeleton of (c)+(e),
   not the grounding-gate/de-bias prose). Default all three from `personas/_shared/testing/design/`,
   capped by `team_max_test_designers` (default 3): [[fault-relation-prospector]] (fault hypotheses +
   metamorphic relations), [[business-logic-cartographer]] (decision-table / state-transition / variant
   rules — the post-`type` case), [[boundary-property-explorer]] (BVA/EP + property invariants). Each
   envelope: the converged design plan + LOAD-CONTEXT digest (**incl. the feature's `requirements.md` in
   feature mode — the `## Variant & state rules` decision/state tables are `business-logic-cartographer`'s
   primary input**) + the **advisory test hints** (the demoted design-critic `PROPOSED_TESTS`, read from
   the trail sidecar — see §(e) item 5) + its persona block.
2. **Merge dossiers with cross-generator dedup.** Collapse same-branch error/partition intents emitted by
   more than one generator into a single backlog row (horizontal decorrelation is by intent, not output).
3. **Write the Test design dossier** into the plan artifact (decision tables, fault hypotheses,
   metamorphic relations, property invariants) and **populate the Test backlog** from it.
   **Traceability (mandatory):** every dossier artifact maps to ≥1 backlog row; generator entries are
   `advisory` until a bound critic confirms them in EXECUTE (routing table: `design/README.md`). **In
   feature mode, a backlog row grounded in a `requirements.md` rule echoes its `REQ-NN` in the `source`
   column** — this is the spec→backlog half of the id chain (the dossier half is written at capture,
   `04-execute-loop.md` §5.4a).

## (f3) Decompose into sessions — feature mode only

Runs when this session has a feature workspace (Step 0 resolved one). Skip entirely otherwise; an
ordinary `/v-team` run has no shard to write.

`/v-pm` gave this repo an **appetite** — a session budget in `generic-plan.md` — and named the **first
slice**. It did not enumerate the work, because it does not read this code. Splitting is this session's
job, and the rows it writes are this session's to maintain.

1. **Read the appetite. Do not re-derive it.** It is a ceiling, not an estimate. If the converged plan
   does not fit, cut scope — `[could]` rules first, then `[should]` — and record what you cut. Never
   quietly exceed the budget; if only `[must]` rules remain and it still does not fit, say so at the
   approval gate and let the operator re-size.
2. **Size each unit against what actually lands here.** Units are **session-sized**, not edit-sized. In this framework a session that finished
   cleanly touched a median of ~9 files; sessions that reached ~49 dropped work permanently and needed
   a follow-up. Treat ~9 as the target and anything past ~15 as a unit that wants splitting.
3. **Cut vertically, hardest part first.** Start with `/v-pm`'s first slice. Each later unit should
   deliver something observable on its own, not one architectural layer of something.
4. **Pick each unit's command** off the existing ladder — `/v-do` for a contained edit, `/v-work` for
   ordinary work, `/v-team` where a wrong decision is expensive to reverse. `/v-ask` is not eligible: it
   writes nothing, so it can never close a row. Rules:
   `$VAULT_FRAMEWORK_PATH/vault/indications/light-command-siblings.md`.
5. **Write the rows** into `projects/<this>/plan.md` `## Sessions`, one per unit: id, scope, command,
   `status: todo`, the `REQ-NN` ids it covers, and today's date. Leave `evidence` empty — it is filled
   when the row closes, and a `done` row without it is invalid.

**Expect these rows to be wrong in detail.** The tracker that worked here shipped all ten of its
sessions and rewrote nearly every row on the way — scope cut, work added, one session inserted that no
plan predicted. That is the tracker doing its job. Write the rows so the executing session can correct
them, and never treat a recorded deviation as a failure.

## (g) Finalise

Mark the plan `status: proposed` and set `process_record` to the sidecar filename. **`rounds` and
`convergence` are process state and live in the sidecar, not in the plan's frontmatter.** Then run
v-work `03-propose.md` **§3b dedupe** for the plan artifact and any implied feature/ADR docs, and run
`bin/doc-lint.sh <plan>` — a finding here means the plan is carrying something that belongs in the
sidecar. Fix it before the approval gate.

---

## Required output — two layers

The converged plan and the test backlog are written **to the plan artifact**, the critique trail to
its **sidecar**. Only the decision is written **to the user**. Do not print either file to the
terminal.

### Layer 1 — to the user (≤15 lines, governed by `_shared/communication.md`)

Same shape as v-work `03-propose.md` — `Recommendation · Impact · Options · Assumed · Open · Ask` —
with the same omit-when-empty rule and the same **cuts good news, never warnings** carve-out.

Panel-specific rules for this layer:

- **Translate, never transcribe.** The user gets outcomes in plain words, not the panel's vocabulary.
  Never print `BLOCKER`, `MAJOR`, `advisory`, `grounding`, `persona`, `convergence`, `rounds`,
  `dedupe`, `fan-out` or `disposition` to the user. Say "must fix before this ships", "worth fixing",
  "verified", "a judgement call", "reviewer" — or describe the outcome and drop the term.
- **These always surface** (they are exceptions, not status): `CONVERGENCE: capped with N open
  blockers` — stated plainly, e.g. "the reviewers ran out of rounds with N things still open"; any
  **minority flag** (§(e) item 6); any irreconcilable trade-off the synthesizer escalated (§(e) item
  3); and the `(f2)` skip note (§f2 gating) when test design was skipped.
- **Say the reviewing happened; do not narrate it.** One line at most — how many reviewers, whether
  anything is still open. Never a round-by-round account.

### Layer 2 — to the plan artifact (not printed)

`plans/YYYY-MM-DD-HHMM-<slug>.md` — the converged plan: work items one row per **exact file path**
(never "the resources"), decisions, verified state, open work, Test design dossier, proposed test
backlog, vault writes per §3b dedupe.

`plans/YYYY-MM-DD-HHMM-<slug>.trail.md` — the critique trail, per-round metrics, rejected
alternatives, and research that did not survive into the plan.

Name the plan path to the user in one line. Never require them to open it to decide. Do not name the
sidecar unless they ask why something was decided.

Mark PROPOSE `completed`, then proceed to the APPROVAL GATE.
