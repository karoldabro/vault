# Step 3 — PROPOSE

Two parts, **engineering first**: design the change (3a), then list the vault writes it produces
(3b). Design before implementing — do not write code in this step.

---

## 3a — Engineering design

### 3a.1 Activate Serena + locate code (if code changes)

```
check_onboarding_performed() → activate_project()
list_memories()
```

Read Serena memories matching the Step-1 keywords (project-specific *code* conventions). Vault
guidelines from `features/·processes/·architecture/` were already loaded in §2.3b — don't duplicate.

Locate relevant code by symbol, not whole file — `get_symbols_overview()`, `find_symbol(...,
include_body=false)`, `find_referencing_symbols()`. Understand existing patterns before proposing:
how are similar classes/components structured, what base classes/traits/utilities are reused, what
naming conventions and test layouts apply. If Serena is unavailable, surface it and fall back to
graphify → Glob/Grep/LSP (don't silently read whole files). Playbook §4.

### 3a.2 Impact scope

Determine: files to create vs modify · tests affected · DB migrations / schema changes · queue jobs,
events, listeners involved · API docs to update · config changes · coupled projects (from §2.1)
affected.

### 3a.3 Assign agents — architecture first

Design at the right level before writing code. Spawn specialists whose domain matches the work;
architecture agents before implementation agents. Independent sections → spawn in one message so they
run concurrently; serialise only on hard dependencies (schema before service layer).

| Work type | Agent | When |
|-----------|-------|------|
| System/DB/service design | `system-architect` | First for any new module |
| API, backend logic, validation | `backend-architect` | Backend implementation |
| Components, state, layout | `frontend-developer` / `frontend-architect` | UI work |
| Mobile features | `mobile-app-builder` | iOS/Android/React Native |
| LLM / ML integration | `ai-engineer` | AI features |
| Auth, permissions, input handling | `security-engineer` | Security-sensitive surfaces |
| Profiling, bottlenecks | `performance-engineer` | Performance work |
| Large refactors, tech debt | `refactoring-expert` | Restructuring |
| Complex bug diagnosis | `root-cause-analyst` | Evidence-based investigation |
| Writing/fixing tests | `test-writer-fixer` | All test work (also Step 4) |
| Pre-commit review | `deploy-review-panel` | BIG scope, before COMMIT |

### 3a.4 Implementation steps (dependency-ordered)

Numbered, ordered **schema/models → services/logic → controllers/routes → views/components → tests**.
Each step specifies: **File** (exact path), **Action** (class/method/logic summary), **Tool** (from
`$VAULT_FRAMEWORK_PATH/tool-playbook.md` §5), **Pattern** (which existing pattern it follows, from 3a.1).

### 3a.5 Test plan

For each new/changed unit: **type** (unit = pure logic; feature/integration = endpoints, jobs, DB,
middleware; e2e = critical journeys), **scenarios** (happy path + edge cases + error paths + data
integrity), **file location** (project's test conventions). List the concrete test cases.

---

## 3b — Vault writes

Run dedupe for each candidate vault file **before** listing it:

1. Extract slug + keywords.
2. `search()` via claude-mem + `memory_recall()` via OV.
3. Grep `decisions/`, `features/`, `sessions/`, `processes/`, `architecture/` for the slug.
4. Overlap with an existing doc `>60%` → mark `UPDATE existing` instead of `CREATE`.

Heavy dedupe-vs-recent-sessions and index reconciliation is handled at capture time by `/v-capture` —
here just name what will be written.

---

## Required output

```
Serena rules: [memory files read — or "not available"]
Impact: [files create/modify/delete · migrations · API changes · coupled projects]
Implementation steps: [numbered — file + action + tool + pattern]
Test plan: [per unit — type + scenarios + file location]

Vault writes:
  - CREATE features/<slug>.md (dedupe: N matches)
  - UPDATE decisions/ADR-NNN-<slug>.md (dedupe: 80% overlap)
  - CREATE sessions/YYYY-MM-DD-HHMM-<slug>.md (always new)
Index updates:
  - _moc.md / _feature-index.md / decisions/_inventory.md as needed
```

Mark PROPOSE `completed`.
