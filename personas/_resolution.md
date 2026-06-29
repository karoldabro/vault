# Persona resolution & critic selection

How `/v-team` decides **which persona pack** to load and **which critics** to spawn for a change. Read
in the ANALYZE addendum (after `01-analyze.md`), so the result is recorded before the propose loop.

---

## 1. Resolve the pack (first hit wins)

1. **`VAULT.md` `personas.use`** — explicit pack name → load `$VAULT_FRAMEWORK_PATH/personas/<name>.md`.
2. **`VAULT.md` `personas` absent but `project_type` set** → load `personas/<project_type>.md`.
3. **Auto-detect** by repo-root marker (reuse `01-analyze.md` §1.3 stack detection):
   - `composer.json` (+ Laravel deps) → `api-laravel`
   - `nuxt.config.{ts,js}` → `nuxt`
   - `pubspec.yaml` → `flutter`
   - else `package.json` framework deps as a tiebreak.
4. **Fallback** — nothing resolves → warn once and fall back to v-work's single-shot agent dispatch
   (`03-propose.md` §3a.3) + `deploy-review-panel` at review time. `/v-team` then behaves like
   `/v-work`-with-a-panel rather than failing. **Never halt** (tool-playbook ethos).

Then compose the pack: load each `use_shared` persona from `personas/_shared/<id>.md`, apply the pack's
overlay (analyzer + extra checklist), and load the stack-local personas. Apply `VAULT.md`
`personas.add` (merge repo-relative custom persona files) and `personas.skip` (drop by `id`).

---

## 2. Select critics for THIS change

More personas ≠ more signal (correlated critics collapse to ~2 effective votes). Select the **most
relevant, decorrelated** set, capped by `team_max_parallel_critics` (default 3, hard max 5):

- **Architect persona(s): always in** — they own structure and reuse.
- **`correctness` (bug-hunter): default-in for diff review** — `/v-cr` and `/v-team`'s diff-review loop
  review *existing code's behaviour*, where logic/edge/null/race bugs are the highest-value findings
  (`_shared/correctness.md`). For pure plan critique (no diff yet) it is optional. Decorrelated from
  `skeptic` (assumptions) and `quality` (cleanliness) — see that file's Output note.
- **Add the 1–2 lenses the change most implicates** — derive from the Step-1 keywords / impact scope:
  auth·tenant·permission·upload → `security`; query·index·list·job·report → `performance`;
  refactor·duplication·new-module → `quality`; contract·endpoint·filter·response → integration architect.
- **`skeptic`: add only on high-risk changes** — auth, billing/payments, migrations, multi-tenant
  boundaries, deletion/data-loss paths, or anything touching a coupled-repo contract.
- If selection would exceed the cap, keep architect + the highest-relevance lenses; note the dropped
  ones in the critique trail (no silent truncation).

Record the outcome in the ANALYZE output:
```
Personas: <pack> → [Software Architect, security, performance]   (skipped: quality, skeptic)
```

### 2.1 Testing-critic group (test-touching changes)
When the change **adds or modifies test files** — path globs `*test*`, `*spec*`, `tests/`, `__tests__/`,
`*.test.*`, `*_test.*` (stack-appropriate) — or the task itself is test-writing, select critics from the
**testing group** at `personas/_shared/testing/` (loader resolves `_shared/testing/<id>.md`, not the flat
`_shared/`). The same cap applies (`team_max_parallel_critics`, default 3).

- **Default pick:** `test-behaviorist` + `assertion-auditor` + the one lens the diff most implicates —
  collaborators/mocks → `test-double-critic`; stateful/async/time → `flakiness-sentinel`; new branches →
  `edge-case-hunter`; new or failing harness/framework code → `test-harness-critic`.
- **Drop `test-double-critic`** if its mandatory mock-density metric can't be produced on the stack
  (grounding rule — a metric-less double-critic is advisory-only, so it doesn't earn a panel seat).
- Mixed diffs (production + test code): keep the production-code critics for the source change and add
  **one** testing critic for the test change, still within the cap; note the trade-off in the trail.
- See `personas/_shared/testing/README.md` for the lens table, decorrelation boundaries, and per-stack
  analyzer overlays.

#### 2.1a Test-design generators (PROPOSE) + the system-domain-expert seat (EXECUTE)
- **Generators** (`personas/_shared/testing/design/`) are **not critics** and are **never selected into a
  panel**. They fan out in the PROPOSE sub-phase `(f2)` to author the test plan; see that group's
  `README.md` for the generator↔critic contract.
- **`system-domain-expert`** is a critic seat for the EXECUTE diff-review loop, grounded in the repo's own
  `indications/`+`features/` rules. **Seat it whenever the PROPOSE `(f2)` fan-out ran** (i.e. a business-
  logic-touching change) — **regardless of the test-file glob above**, because new untested business logic
  has no test files in the diff at selection time yet is exactly the case this seat exists to catch. It is
  a **priority pick** within the cap for business-logic-heavy changes (variant/type params, state
  machines, billing/permission rules).

---

## 3. base_agent fallback
Each persona declares a `base_agent`. If that Claude Code agent is unavailable in the install, spawn a
generic `Explore` agent with the persona block as the prompt overlay. Never skip a selected critic for
want of its preferred base agent.
