# Step 5 — EXECUTE (review loop)

Implement the approved plan, triage the proposed tests, then run a **diff-review panel loop** — the same
personas in review posture, tool-first, fixing between rounds until convergence.

---

## 5.1 Implement

Read `~/.claude/commands/v-work/steps/04-execute.md` and follow it verbatim: branch rule (§4.1), file-
editing tool table (§4.2), supporting tools (§4.3), domain mindset (§4.4), per-unit loop (§4.5), and
tests-after-each-phase (§4.6). The **converged plan** drives implementation order; implementers are the
architect personas' `base_agent`s (e.g. `system-architect`/`backend-architect` for api-laravel).

## 5.2 Test triage (mutation-aware)

Spawn `test-writer-fixer` to work the plan's **Proposed test backlog**. LLM-proposed tests over-produce
(~1:5–1:20 keep ratio is normal) and coverage alone passes tautological tests — so triage strictly. Per
proposed test, decide:

- **implement** — write it as proposed;
- **change** — adjust scope/kind, then write (record what changed);
- **skip** — drop it (record why: redundant, out of scope, low value).

For every test it **keeps**, enforce the gate before counting it done:
1. **builds / compiles**;
2. **runs green ≥3×** (kills order-dependent flakiness);
3. **strictly increases coverage** of the target behaviour;
4. **kills ≥1 seeded mutant** — or, equivalently, a characterization check: temporarily break the code
   and confirm the test fails. (Coverage without fault-detection = tautological → reject.)

Stamp each backlog row's `disposition` (implement | change | skip) + reason in the plan artifact.

## 5.3 Diff-review loop (panel → synthesize → re-loop, tool-first)

The single-pass panel sub-procedure (ground → select → generate → grounding-gate verify → synthesize) is
defined canonically in `commands/_shared/critic-panel.md` (shared with `/v-cr`). This section **wraps**
that procedure in v-team's own fix-and-reloop control flow — the *apply-fixes-between-rounds* and
*re-spawn* steps below belong to v-team (it owns and mutates the local diff), not to the shared module.

Run after **each phase** for BIG scope (>15 files or API/schema change), or **once at the end** for
small scope (v-work §4.7 heuristic).

Each round:
1. **Analyzers first.** Run the personas' bound analyzers + the test suite on the **diff** before any
   critic opines (compiler, linter, SAST, query/N+1 probe, etc.). Findings on real code are the
   strongest `confirmed` evidence — this is where grounding matters most.
2. **Spawn the same selected personas** (parallel, read-only) against the **git diff + changed-file
   list + analyzer output + converged plan**. Each checks: was my round-N recommendation honored? do my
   `must` tests exist? any new issue in the actual code? `target` is now `file:line`.
3. **Synthesize** (de-biased, as §3e): dedupe, resolve/escalate conflicts, rank.
4. **Apply fixes** between rounds with the §4.2 tools; **re-run the relevant tests** (§4.6).
5. Re-spawn for the next round.

**Stop on ANY:** `team_max_review_rounds` (default **2**) reached, or no new **confirmed** BLOCKER/MAJOR.
Not on approval alone. Cap hit with open confirmed blockers → **present to user** (mirrors v-work §4.8).
Append each review round + metrics to the plan's Critique trail.

## 5.4 Self-review

Run v-work `04-execute.md` §4.8 self-review checklist (code quality, test quality, architecture). The
diff-review loop generalises and **supersedes** `deploy-review-panel` here — do **not** additionally
spawn it. (`deploy-review-panel` remains the fallback only when no persona pack resolved.)

---

## Required output

```
Implemented: [changed files]
Test triage: [N implemented · N changed · N skipped] (dispositions stamped in the plan)
Review rounds: <n>  ·  Convergence: <clean | capped-with-open-blockers>
Tests: [pass/fail — pre-existing vs newly introduced]
Vault docs: [written/updated alongside code]
```

Mark EXECUTE `completed`.
