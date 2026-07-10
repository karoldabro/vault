# Persona resolution & critic selection

How `/v-team` decides **which persona pack** to load and **which critics** to spawn for a change. Read
in the ANALYZE addendum (after `01-analyze.md`), so the result is recorded before the propose loop.

---

## 1. Resolve the pack (first hit wins)

1. **`VAULT.md` `personas.use`** — explicit pack name **or list** (`use: [sales, marketing]`) → load
   each `$VAULT_FRAMEWORK_PATH/personas/<name>.md`. A list seats multiple packs for a multi-domain
   project; the **first entry is the primary pack** — its architect takes the single architect seat
   (§2.2). **Dev and business packs must not mix in one list** — a repo that is both runs separate
   sessions per deliverable type (dev §2 and business §2.2 selection have different caps and
   default-ins; no cross-regime precedence is defined, by design).
2. **`VAULT.md` `personas` absent but `project_type` set** → load `personas/<project_type>.md`.
3. **Auto-detect** by repo-root marker (reuse `01-analyze.md` §1.3 stack detection):
   - `composer.json` (+ Laravel deps) → `api-laravel`
   - `nuxt.config.{ts,js}` → `nuxt`
   - `pubspec.yaml` → `flutter`
   - else `package.json` framework deps as a tiebreak.
   Non-dev packs (`marketing`, `sales`, `seo`, `support`, `business`, `startup-eval`) have **no repo
   marker** — they resolve only via `personas.use` / `project_type` (opt-in by design).
4. **Fallback** — nothing resolves → warn once and fall back to v-work's single-shot agent dispatch
   (`03-propose.md` §3a.3) + `deploy-review-panel` at review time. `/v-team` then behaves like
   `/v-work`-with-a-panel rather than failing. **Never halt** (tool-playbook ethos).

Then compose the pack: load each `use_shared` persona from `personas/_shared/<id>.md` — an id may be
**group-qualified** `<group>/<id>`, resolving to `_shared/<group>/<id>.md` (e.g. `business/data-evidence`
→ `_shared/business/data-evidence.md`) — apply the pack's overlay (analyzer + extra checklist), and load
the stack-local personas. Apply `VAULT.md` `personas.add` (merge repo-relative custom persona files) and
`personas.skip` (drop by `id`). Under multi-pack seating a shared critic (skeptic, business/data-evidence)
loads **once**; its effective overlay is the **union** of the seated packs' bindings, each binding running
against its own pack's deliverable surface — never a silent single-pick.

---

## 2. Select critics for THIS change

More personas ≠ more signal (correlated critics collapse to ~2 effective votes). Select the **most
relevant, decorrelated** set, capped by `team_max_parallel_critics` (default 3, hard max 5; **business
packs default 4** — see §2.2):

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

Record the outcome in the ANALYZE output — multi-pack seating joins pack names with `+`:
```
Personas: <pack> → [Software Architect, security, performance]   (skipped: quality, skeptic)
Personas: sales+marketing → [Deal Strategist, Outreach & Sequencing, data-evidence, skeptic]   (skipped: ...)
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

### 2.2 Business-pack critic selection (non-dev packs)
For the business family (`marketing`, `sales`, `seo`, `support`, `business`, `startup-eval`), the dev
keyword table above doesn't apply. Business packs default `team_max_parallel_critics: 4`; multi-pack
seating (N≥2 packs) uses the hard max 5. **Seat priority order (deterministic):**

1. **Primary pack's architect** — ONE architect seat total, even multi-pack (the primary pack is the
   **first `personas.use` entry**; single definition, used only for this seat). Other seated packs'
   architects compete as ordinary relevance picks.
2. **Guaranteed domain lens** — family-wide ≥1, chosen by the trigger table below **across ALL seated
   packs** (it need not belong to the primary pack). Never dropped.
3. **`business/data-evidence`** — when the deliverable carries decision-driving numbers (spend,
   pricing, forecast, funnel, market size). Relevance-gated, not default-in.
4. **`skeptic`** — on high-stakes work (budget/spend commitment, pricing/positioning change,
   market-entry/launch bet, auto-send flows, legal exposure). For `startup-eval`, every go/no-go memo
   and sizing doc IS high-stakes → skeptic default-in there.
5. Remaining seats fill by relevance (other domain lenses, other packs' architects).

Over cap → drop from the bottom of this order (relevance extras first); **never** the guaranteed lens
or the primary architect. Note drops in the critique trail (no silent truncation).

**Trigger table — one trigger selects ONE lens** (cross-pack double-votes are a selection bug):
outreach/sequence → Outreach & Sequencing · proposal-instance/deal → Proposal & Pricing (sales) ·
pricing-model/tiers/discount-policy → Unit Economics & Pricing (business) · ICP/qualification → ICP &
Qualification · go-no-go/sizing/validation-plan → startup-eval lenses · KB/deflection → KB & Deflection ·
escalation/churn-save → Churn & Escalation · reply/macro → Support Quality & Voice · content-brief →
Content & E-E-A-T · technical-audit/migration → Technical SEO · AI-visibility/GEO → AI Visibility (GEO) ·
SOP/process → Ops & Process · contract/privacy → Legal & Compliance · spend/campaign → Paid Media ·
press/community → PR & Community · copy/brand-asset → Brand & Copy · organic-social/content-calendar →
Social & Content · activation/funnel/retention → Conversion & Retention · localization/store-ad-policy →
Market & Compliance. A deliverable matching **no** trigger falls through to a relevance pick — the
guarantee still holds: seat the most relevant domain lens, never zero.

**Cross-pack suppression:** a declared-overlap light lens is suppressed when its deep pack is seated —
e.g. marketing's *SEO & Discoverability* never seats alongside the `seo` pack; sales' *Proposal &
Pricing* cedes pricing-model triggers to business's *Unit Economics & Pricing* when both are seated;
marketing's *Paid Media* cedes the spend-math **recompute** to `business/data-evidence` when a business
pack is co-seated (keeping the paid-specific judgment: bid-strategy adequacy, incrementality-vs-
attribution, creative significance, ad-platform policy).

---

## 3. base_agent fallback
Each persona declares a `base_agent`. If that Claude Code agent is unavailable in the install, spawn a
generic `Explore` agent with the persona block as the prompt overlay. Never skip a selected critic for
want of its preferred base agent.
