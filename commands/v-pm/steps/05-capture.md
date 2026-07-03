# Step 5 — CAPTURE (plan mode; also the tail of reconcile)

Planning is where the cross-project decisions are made — record them, or they evaporate. This is v-pm's
own `/v-capture`, scoped to the feature workspace and cross-project. Runs after SEED WORKSPACE (plan
mode) and at the end of `reconcile`.

## 5.1 Write the planning-session record
Into `~/vault/_features/<feature>/sessions/YYYY-MM-DD-HHMM-<slug>.md` (from
`$VAULT_FRAMEWORK_PATH/templates/_features/planning-session.md`): the necessity, participants, the panel's
**critique trail** (what each critic raised; applied / rejected / deferred), the decisions and trade-offs,
and links to `generic-plan.md` + `contracts.md`. This is the *why* behind the plan — the part the
committed artifacts don't hold.

## 5.2 Extract cross-project ADR candidates
Scan the plan + panel decisions for decision-shaped statements (`chose X over Y`, `going with`, `rejected
… in favor of`, sequencing calls, contract-shape decisions). Present each as a one-line candidate; for
each the user confirms:
- Write `~/vault/_features/<feature>/decisions/ADR-<n>-<slug>.md` (from
  `$VAULT_FRAMEWORK_PATH/templates/decision.md`) — cross-project ADRs live in the **neutral workspace** by
  default, not scattered into one participant's vault.
- **Offer to promote** an ADR into a specific participant's vault (`~/vault/<proj>/decisions/`) when it's
  really that one project's call rather than a shared one.
Don't manufacture ADRs — only genuine decisions the planning actually made.

## 5.3 Push to OpenViking
Probe `memory_health()` first (MCP — never `curl`). If healthy,
`memory_store(role="assistant", text=<plan summary: necessity · participants · key decisions · contract
seam · links>)` so the rationale is recallable — this is exactly what each project's `/v-team`
cross-project LOAD CONTEXT (`02-load-context.md` §2.1) finds via `memory_recall`. If unreachable, note it
and skip (never fail). claude-mem auto-captures on session end — no action.

## 5.4 Commit
Stage + commit the whole `~/vault/_features/<feature>/` (workspace + planning-session record + any ADRs)
with **explicit paths** — `_features/` is its own committed vault; `/v-sync` ingests it.

## Required output
```
Planning session: _features/<feature>/sessions/<file>.md
ADR candidates: <N found, M written>   (promoted to <proj>: [...] | none)
OV: <pushed via memory_store | memory_health unreachable — skipped>
Committed: _features/<feature>/  (<shortsha>)
```
Mark CAPTURE `completed`. Plan mode complete — tell the user the workspace is ready and to run
`/v-team <feature>` in each project.
