# Step 3 — PROPOSE (panel loop)

Draft a plan, then run a **panel → synthesize → re-loop** until it converges. Critics work in parallel,
each through its own tool-grounded lens, and share state **only via the revised plan** (no agent-to-
agent messaging — independence is what makes the panel worth its cost). Do not write source code here.

**Hooks.** `pre_propose` fires once before this loop starts and `post_propose` once after it converges
(before the approval gate) — the internal critic **rounds are non-hookable**. See `vault-guide.md` §1.1.

---

## (a) Draft plan v0

Read `~/.claude/commands/v-work/steps/03-propose.md` and run **§3a (engineering design) only** —
Serena/graph orientation, impact scope, dependency-ordered implementation steps, test plan. **Skip
§3a.3** (the panel replaces ad-hoc agent dispatch) and **defer §3b** (vault-write dedupe) until after
convergence.

Instantiate `$VAULT_FRAMEWORK_PATH/templates/plan.md` into
`<project-vault>/plans/YYYY-MM-DD-HHMM-<slug>.md` and write the draft as **Round 0**. If `plans/`
doesn't exist, create it (warn once; add `add_folders: [plans]` to `VAULT.md` so it's recognised) —
don't halt.

## (b) Load + select critics

Use the pack + selected critics resolved in the ANALYZE addendum (`personas/_resolution.md`). Read each
selected persona file once (shared base + pack overlay composed). Default ~3 critics, hard max 5.

## (c) Parallel critic spawn

One message, **multiple `Agent` calls** — one per selected persona, spawned as its `base_agent`
(fallback: `Explore` with the persona block as prompt). Critics are **read-only**. Each critic envelope:

- the **current plan** (round R, from the artifact);
- the **task restatement + keywords** (ANALYZE);
- the **LOAD-CONTEXT digest** — indications, ADRs, conventions (so critics respect project rules);
- its **persona block verbatim** (mandate · bound analyzer · rubric · checklist);
- (R ≥ 1) the **prior round's merged findings**, so it sees what changed and whether its concern was
  addressed.

Instruct each critic to **run its bound analyzer first** and cite real signals — the persona interprets
tool output, it does not replace it.

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
   bias); penalize verbose-but-empty findings.
2. **Dedupe / cluster** across personas (same step flagged twice → one cluster).
3. **Resolve conflicts** by surfacing the trade-off **explicitly** in the plan (e.g. perf cache vs
   security freshness). Irreconcilable → escalate to the user at the approval gate; **never silently
   pick a side.**
4. **Revise the plan:** apply confirmed BLOCKER/MAJOR recommendations; record MINOR/NIT and advisory as
   "Open trade-offs / deferrals" with rationale. Bump to v(R+1).
5. **Merge `PROPOSED_TESTS`** into the artifact's **Proposed test backlog** (dedupe overlapping, keep
   provenance; `disposition` stays blank until EXECUTE).
6. **Append** round R to the **Critique trail** with each finding's disposition (applied / deferred /
   rejected + reason) and **metrics**: new confirmed blockers, findings-delta, per-persona overlap,
   confirmed-vs-advisory counts, token cost.

## (f) Convergence — stop on ANY

1. **Round cap** — `team_max_rounds` (default **2**). Hard ceiling.
2. **No-new-blocking-findings** — a full round adds **no new confirmed BLOCKER/MAJOR**
   (`NEW_SINCE_LAST_ROUND` is only advisory / MINOR / NIT).

**Unanimous approval is NOT a stop condition by itself.** Cap hit with open confirmed blockers → stop
and flag the plan `CONVERGENCE: capped with N open blockers` for the approval gate. **Never loop past
the cap.** (Observability note: if round 2 routinely yields no new confirmed blocker on your projects,
set `team_max_rounds: 1` and make round 2 opt-in for high-risk work.)

## (g) Finalise

Mark the plan `status: proposed`, set `rounds` + `convergence` in frontmatter. Then run v-work
`03-propose.md` **§3b dedupe** for the plan artifact and any implied feature/ADR docs.

---

## Required output

```
Personas: <pack> → [selected critics]
Rounds: <n>  ·  Convergence: <clean | capped-with-open-blockers>
Plan artifact: plans/YYYY-MM-DD-HHMM-<slug>.md
Converged plan: [numbered steps — file + action + tool + pattern]
Proposed test backlog: [N tests across M personas]
Open trade-offs / escalations: [...]
Vault writes: [CREATE/UPDATE per §3b dedupe]
```

Mark PROPOSE `completed`, then proceed to the APPROVAL GATE.
