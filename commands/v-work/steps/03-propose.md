# Step 3 — PROPOSE

Two parts, **engineering first**: design the change (3a), then list the vault writes it produces
(3b). Design before implementing — do not write code in this step.

**Hooks:** honor carried `pre_propose` before designing / `post_propose` after (fires **before** the
approval gate) — loaded once at step 1 §1.4, never re-read `VAULT.md` (contract: vault-guide §1.1).

---

## 3a — Engineering design

### 3a.0a Understand & clarify (before designing)

Do not design until the task is unambiguous — jumping to a plan on a half-understood task is the most
expensive mistake in the lifecycle. Before §3a.1:

1. **State it back.** Write your understanding of the goal in your own words, plus the **assumptions**
   you are relying on (data shape, scope boundaries, who the user is, explicit non-goals).
2. **List open doubts.** Direction, technology/library choice, scope edges, data model, UX, backward-
   compat — anything the ANALYZE restatement + LOAD CONTEXT did not settle.
3. **Route each doubt:**
   - Answerable from vault / code / §3a.0b research → **answer it yourself**; don't ask.
   - Would change the design **and** has no safe default → **ask the user** via `AskUserQuestion` and
     **wait for the answer** (batch all such questions into one call; lead each with a recommended
     option). Do not design, draft, or proceed past an unanswered fork.
   - Has an obvious safe default → state the default explicitly and proceed.
4. Do **not** paper over real ambiguity by guessing. When a direction or technology choice is genuinely
   open, ask — a question is cheaper than a wrong plan. Equally, don't manufacture questions whose
   answers are already in context or obvious; only genuine, plan-changing doubts warrant one.

**A plan-changing question with no safe default halts the lifecycle** — the clarify gate **always waits**
for the user; never fall back to a guess on a fork that by definition has no safe default. (Doubts that
*did* have a safe default never reach this gate — they were stated and passed in step 3.) Those stated
safe defaults are still **flagged at the approval gate** so they can be corrected there.

### 3a.0b External research (ground the design; reduce hallucination)

Before committing to an approach, research how this problem is solved in the wild. **Your prior is
weaker than the accumulated experience of practitioners who already solved this** — treat your first
instinct as a hypothesis to test against the internet, not a conclusion.

**Gate — run for genuinely novel choices only:** a new library/tool/framework selection, a new
architecture or schema design, an unfamiliar problem domain, or an external integration this repo
hasn't done before. **Skip for:** work following established repo/vault patterns (most feature work
on a familiar stack), refactors, docs, formatting, mechanical renames — note the skip in one line.
If a novel choice surfaces mid-design after you skipped, run the gate then for that choice.

1. **Search** (`WebSearch` / `WebFetch`; for big or open questions spawn `deep-research`,
   `tool-evaluator`, or `trend-researcher`): the same/similar problem, common solutions and reference
   implementations, known pitfalls and anti-patterns, and the community-default library or tool.
2. **Take contradiction seriously.** If credible sources converge on a **different** tool or approach
   than your draft, that outweighs your instinct. Either **adopt it**, or record a **written reason**
   for keeping your approach (a constraint the sources don't know about). Silently ignoring a strong
   contradicting consensus is not allowed — surface the reconciliation at the approval gate.
3. **Cite.** Record the key sources (title + URL + one-line takeaway) so the design is auditable, not
   asserted.
4. **Fallback.** `WebSearch` unavailable → note it, proceed on vault + reasoning, and flag the design
   `research: unavailable` at the approval gate (weaker, not blocked). Full rules:
   `$VAULT_FRAMEWORK_PATH/tool-playbook.md` §7.

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

Two design moves keep this off the happy path (the heavyweight generative version is `/v-team`'s PROPOSE
`(f2)` fan-out — here it is a checklist):
- **Variant/type-dependent logic → a decision table.** When behaviour or required params change by a
  type/variant/flag (e.g. `post.type` = text|poll|link), enumerate the conditions × values and write one
  test per rule, not just the default path.
- **Name the fault for each happy path.** For every pass-case, name one fault that would break it (bad
  input, missing precondition, partial failure) and add the negative/error case it reveals.

### 3a.6 Lite critic (single-pass, read-only — `/v-work` only)

One adversarial pass on the draft plan, **without** `/v-team`'s panel loop. This is the middle rung:
a second opinion should not require the full critic panel. (`/v-team` skips this section — its panel
loop replaces it.)

**Run when** the plan spans >2 files, carries open trade-offs or stated-default assumptions, or the
user asked for a second opinion. **Skip** (one-line note) for single-file or mechanical changes.

1. Spawn **exactly one read-only critic** (single `Agent` call): if a persona pack resolves
   (`personas/_resolution.md` §2), pick the single most relevant lens for this change; else a generic
   `Plan`/`Explore` agent with critic instructions. Envelope: draft plan + task restatement +
   LOAD-CONTEXT digest. Findings use `/v-team`'s schema (severity + `confirmed`/`advisory` grounding).
2. Apply `confirmed` BLOCKER/MAJOR recommendations to the plan; record everything else as open
   trade-offs for the approval gate. **One pass — never re-loop here.**
3. If the critique surfaces panel-worthy risk (architecture, schema, auth, billing, cross-repo
   contract), don't loop — say so and suggest escalating to `/v-team`.

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
Assumptions: [stated defaults the design rests on — from §3a.0a]
Clarifications: [questions asked via AskUserQuestion | none needed — task unambiguous]
Research: [key sources + one-line takeaways | skipped (trivial) | unavailable — from §3a.0b]
Serena rules: [memory files read — or "not available"]
Lite critic: [<persona/agent> — N findings, M applied | skipped (single-file/mechanical)]
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

Before marking complete, honor any carried `post_propose` hook (surface + apply). Mark PROPOSE
`completed`.
