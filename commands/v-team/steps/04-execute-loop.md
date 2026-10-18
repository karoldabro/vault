# Step 5 — EXECUTE (three loops)

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

Three loops, each with one owner. **Implement** writes production code and runs the static check before a
unit is done. The **code-review loop** critiques the design of that code. The **testing loop** writes the
tests and measures them. No loop edits another loop's files: if either side could change the other's
work, a failing test would get "fixed" by weakening it.

**Hooks.** `pre_execute` fires once before implementation (after the gate) and `post_execute` once after
the testing loop stops — the internal rounds are **non-hookable**. See `vault-guide.md` §1.1.

---

## 5.1 Implement

Read `$VAULT_FRAMEWORK_PATH/commands/v-work/steps/04-execute.md` and follow it verbatim: branch rule (§4.1), file-
editing tool table (§4.2), supporting tools (§4.3), domain mindset (§4.4), per-unit loop (§4.5),
tests-after-each-phase (§4.6), and the static check before a unit is done (§4.6a), except that here a
unit gets up to 3 fix-and-rerun tries before its open findings go to the operator. Before the first
edit, record `PROBE_BASE=$(git rev-parse HEAD)`; §5.2 and §5.3 read it. The **converged plan** drives
implementation order; implementers are the architect personas' `base_agent`s (e.g.
`system-architect`/`backend-architect` for api-laravel). The implementer edits production code only.

## 5.2 Code-review loop (panel → synthesize → re-loop, tool-first)

The single-pass panel sub-procedure (ground → select → generate → grounding-gate verify → synthesize) is
defined canonically in `commands/_shared/critic-panel.md` (shared with `/v-cr`). This section **wraps**
that procedure in v-team's own fix-and-reloop control flow — the *apply-fixes-between-rounds* and
*re-spawn* steps below belong to v-team (it owns and mutates the local diff), not to the shared module.

Run after **each phase** for BIG scope (>15 files or API/schema change), or **once at the end** for
small scope (v-work §4.7 heuristic).

**Seats.** The diff-review panel of `personas/_resolution.md` §2: architect, `quality` and `correctness`
by default, plus `performance`, `security` or `skeptic` on their triggers. The panel reviews design only —
reuse, simpler solutions, packages, patterns, the cost of the approach, logic against the business rule.

Each round:
1. **Ground first.** Run `$VAULT_FRAMEWORK_PATH/bin/vault-check.sh static --repo . --base "$PROBE_BASE"` and
   `bin/probe-panel.sh run --posture own --repo . --base "$PROBE_BASE"`, and pass both outputs to every
   critic (rules: `commands/_shared/critic-panel.md` §(a) Probe stage and static output).
2. **Spawn the selected personas** (parallel, read-only) against the **git diff + changed-file list +
   static and probe output + converged plan**. Each checks: was my round-N recommendation honored? any
   new issue in the actual code? `target` is now `file:line`.
3. **Synthesize** (de-biased, as `03-propose-loop.md` §(e)): dedupe, resolve/escalate conflicts, rank.
4. **Apply fixes** between rounds with the §4.2 tools; **re-run the relevant tests** (§4.6) and §4.6a.
5. Re-spawn for the next round.

**Stop on ANY:** `team_max_review_rounds` (default **2**) reached, or no new **confirmed** BLOCKER/MAJOR.
Not on approval alone. Cap hit with open confirmed blockers → **present to user** (mirrors v-work §4.8).
Append each review round + metrics to the **trail sidecar** (`plans/<slug>.trail.md`), never to the
plan. Update the plan's work-item rows in place: a row that shipped flips its `status`, a row that no
longer applies is deleted.

## 5.3 Testing loop

Read `$VAULT_FRAMEWORK_PATH/commands/_shared/testing-loop.md` and run it in full: writers on the plan's
**Test backlog**, `bin/vault-check.sh tests` for tests, coverage and mutation, the testing critic group as
reviewers, and its stop rules. It runs after §5.2 so tests are written against code that has stopped
changing. A production bug a test exposes goes back to §5.1, and its fix gets one §5.2 round, as
`testing-loop.md` §4 caps it.

**Confirm the Test design dossier here (post-impl half of the generate→confirm loop).** When PROPOSE
`(f2)` produced a dossier, the testing reviewers confirm its `advisory` entries against real code —
generators emit pre-impl, critics confirm post-impl. Seat [[system-domain-expert]] whenever `(f2)` ran
(it confirms each [[business-logic-cartographer]] decision-table row maps to a covered branch and each
[[fault-relation-prospector]] metamorphic relation preserves a real rule). Routing:
`personas/_shared/testing/design/README.md`. A `system-domain-expert`/`edge-case-hunter` co-fire on the
same branch is **corroboration**, counted once.

Append each testing round to the trail sidecar. Then run `bin/doc-lint.sh` on the plan before finishing.

## 5.4 Self-review

Run v-work `04-execute.md` §4.8 self-review checklist (code quality, test quality, architecture). The
code-review loop generalises and **supersedes** `deploy-review-panel` here — do **not** additionally
spawn it. (`deploy-review-panel` remains the fallback only when no persona pack resolved.)

## 5.4a Close the requirements id chain (feature mode)
When this feature was planned via `/v-pm` (a `requirements.md` exists, in the workspace or
`<project-vault>/requirements/`), the id-traceability chain closes **at capture**. The **canonical
mechanism is shared** — `/v-capture` **Step 4d** carries each realised requirement's `REQ-NN` id inline
into the established `features/<feature>` dossier `## Behaviors & rules` (built rules only), so the chain
closes identically for `/v-work` and `/v-team`. The session's own row, with its `req` ids, is closed
by step 5.1a of `v-work/steps/05-commit-capture.md` on the tracker that
`commands/_shared/feature-pickup.md` §0.1 resolves. Chain: `requirements.md (REQ-NN)` → backlog `source`
(`03-propose-loop.md` §f2) → **established dossier Behavior** (`/v-capture` §4d).

---

## Required output

```
Implemented: [changed files]
Test triage: [N implemented · N changed · N skipped]
Tests: [only when something FAILED or was skipped — never "all passing"]
Coverage: [only when below the floor, per testing-loop.md §7]
coverage unmeasured: <reason>   [always, whenever the tools could not measure coverage]
Untestable: [each `equivalent` label verbatim]
Still open: [only when a loop ended with something unresolved — say it in plain words,
             e.g. "the reviewers ran out of rounds with 2 things still open"]
Probes: [only when operator.txt exists — print it verbatim]
Vault docs: [written/updated alongside code]
```

**Never print `Review rounds`, `Convergence`, `BLOCKER` or `MAJOR` to the user** — that is process
state and panel vocabulary, both barred by `_shared/communication.md`. It goes to the trail sidecar.
A clean review is the expected outcome and is not reported; an unresolved blocker always is.

Mark EXECUTE `completed`.
