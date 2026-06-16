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

---

## 3. base_agent fallback
Each persona declares a `base_agent`. If that Claude Code agent is unavailable in the install, spawn a
generic `Explore` agent with the persona block as the prompt overlay. Never skip a selected critic for
want of its preferred base agent.
