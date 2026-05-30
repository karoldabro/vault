---
description: Vault-aware development lifecycle. Loads context → proposes solution + vault writes (with dedupe) → approval → execute → commit + capture.
---

# /v-work — Vault-aware development lifecycle

Mirrors `/dev` but vault-first: every step considers what knowledge to load and what to write back. Self-contained — no dependencies on `~/.claude/shared-commands/`.

---

## Required tools — verify before starting

All four tools are required. Check each at session start before proceeding.

| Tool | Health check | If missing |
|------|-------------|------------|
| **OpenViking** | `memory_health()` MCP call (OV is a Claude Code plugin — never `curl`) | WARN user — do not silently skip or grep-fallback |
| **Serena** | `check_onboarding_performed()` | Ask user to run `serena init` and onboard the project |
| **MorphLLM Fast Apply** | (MCP tool — no runtime check) | Required for all bulk multi-file edits; confirm server registered |
| **claude-mem** | `search("test", limit=1)` via mcp-search | WARN user if mcp-search server unreachable |

If any required tool is unavailable, surface the issue before proceeding. Do not silently degrade to a lesser path.

---

## On start: create task list

Use `TaskCreate` to add one task per step. Mark `in_progress` when starting, `completed` when done. The task list is the enforcement mechanism — do not skip a step. COMMIT + CAPTURE is only `completed` after `/v-capture` has run — never end the lifecycle without it.

Tasks:
1. ANALYZE
2. LOAD CONTEXT (vault-first)
3. PROPOSE
4. APPROVAL GATE
5. EXECUTE
6. COMMIT + CAPTURE

---

## Step 1 — ANALYZE

Restate the user's task in your own words. Extract **3–6 keywords** from the restatement — they drive context load and dedupe.

Output:
```
Task: <restatement>
Keywords: <kw1>, <kw2>, ...
Scope: <code-only | vault-only | both>
```

Mark ANALYZE `completed`.

---

## Step 2 — LOAD CONTEXT (vault-first)

Stop as soon as you have enough. **Do not read source code in this step.**

Query in priority order — cheapest first. Each layer costs 10–100× less than reading source files.
**Graph before grep, symbol before full-file read.** Full per-tool rules + examples: [`_process/tool-playbook.md`](../tool-playbook.md).

**Fan out with agents.** When scope is uncertain or spans multiple areas, launch up to 3
**Explore** subagents in parallel (single message, multiple `Agent` calls) instead of serial
reads — give each a distinct focus, e.g. vault decisions/guidelines · code structure · tests.
One Explore agent is enough for an isolated task with known files. The agents return
conclusions; you keep the context lean.

### 2.1 — OpenViking (vault memory — always first)

**Required.** Call `memory_recall(query=<keywords>)` MCP. Covers vault: decisions, ADRs, past sessions, feature dossiers, pitfalls, lessons learned.

What to look for:
- Prior decisions affecting this area
- Past gotchas or known pitfalls
- Related features already built
- Coupled projects in `~/vault/_global/coupled-groups.md`

Cost: ~100–2000 tokens.

### 2.2 — claude-mem (project history — 3-layer progressive disclosure)

**Required.** Query project history via the mcp-search server.

```
Layer 1: search(query=<keywords>, limit=20)          → compact index of IDs (~100 tok)
Layer 2: timeline(anchor=<interesting_id>)            → context window (~300 tok)
Layer 3: get_observations(ids=[<filtered_ids>])       → full details (~1000 tok)
```

Stop after Layer 1 if nothing relevant. Progress to Layer 2/3 only for promising hits. Filter by `type` (decision, bugfix, feature, refactor, discovery) and date when helpful.

### 2.3 — Vault MOC + process guide

- Read `<project-vault>/_moc.md`.
- Read `<project-vault>/_process/vault-guide.md` if not already read this session.

### 2.3b — Vault patterns & guidelines (REQUIRED)

Discover guidelines/conventions that constrain this task — **do not skip**. These docs
override generic defaults.

1. Use the Step-1 keywords. Find matching docs:
   ```bash
   grep -ril "<keyword>" <project-vault>/{features,processes,architecture}/ 2>/dev/null
   ```
2. Read every match (conventions, patterns, gotchas).
3. Map common topics to docs you should expect to find:

   | Keywords | Look for |
   |----------|----------|
   | api, endpoint, route | API conventions, openapi guide |
   | queue, job, worker | Queue architecture |
   | model, migration, schema | Model / DB patterns |
   | frontend, component, view | Frontend patterns |
   | auth, permission, policy | Authorization patterns |
   | test, testing | Testing guidelines |

   These live in `features/` · `processes/` · `architecture/` (per `vault-guide.md` §6) —
   **not** Serena memories.
4. If OV §2.1 already surfaced one of these, don't re-read it.

### 2.4 — Graphify (structural orientation — REQUIRED for structural questions)

`graph.json` is kept fresh by the per-project post-commit hook (`graphify hook install`, wired by
`/v-init`) — AST extraction, no LLM, no token cost. For **any** structural question — what calls X,
where is Y defined, which modules touch Z, dependency chains — query the graph **before** Serena or
grep. Never grep source to answer a structural question.

```
graphify query "validateUserToken callers"      # ~200 tok vs ~10k for recursive grep + reads
graphify path "AuthModule" "DatabaseConnection"  # dependency chain with intermediate nodes
```

If `graphify-out/graph.json` is missing, the hook isn't installed: surface it and offer
`graphify hook install` + an initial `graphify .` build. Do **not** silently grep instead. Full
rules: [`_process/tool-playbook.md`](../tool-playbook.md) §3.

### 2.5 — Serena (semantic navigation — if code change implied)

If the task involves code changes:
- `get_symbols_overview(<relevant_file>)` — file outline
- `find_symbol(<name>)` — locate a specific symbol
- `find_referencing_symbols(<symbol>)` — understand impact

Use to orient before reading whole files.

### 2.6 — Recent sessions + decisions

- Last 3 sessions by mtime: `ls -t <project-vault>/sessions/*.md | head -3`.
- ADRs touching the topic from §2.1.

### 2.7 — CLAUDE.md

Read project `CLAUDE.md` if present. Its instructions override all defaults.

### 2.8 — Git context

```bash
git status && git branch --show-current && git log --oneline -5
```

### 2.9 — Grep / Read (last resort only)

Use only after all above layers come up empty, or to verify a specific line.

Reading 40 source files costs ~20k tokens. A vault hit costs ~100–2000. Wrong default wastes 100×.

### Required output

```
OV: [N results — decisions, sessions, pitfalls — or "nothing relevant"]
claude-mem: [layers used — key findings — or "nothing relevant"]
MOC: [skimmed]
Guidelines: [docs read from features/·processes/·architecture/ — or "none matched"]
Sessions: [top 3 mtime, brief topic each]
ADRs: [relevant IDs]
Graph: [used — key findings — or "not available"]
Serena: [used — symbols found — or "not applicable"]
CLAUDE.md: [key overrides | none]
Branch: [name] [clean / dirty]
```

Mark LOAD CONTEXT `completed`.

---

## Step 3 — PROPOSE

Present the solution outline **and** the proposed vault writes. Run dedupe for every new vault file before listing it.

### 3.1 — Activate Serena (if code changes)

If scope includes code changes:

```
activate_project()
list_memories()
```

Read Serena memories relevant to the task keywords (project-specific code conventions).
Vault guidelines from `features/·processes/·architecture/` were already loaded in §2.3b —
don't duplicate that here.

Use `find_symbol()`, `get_symbols_overview()`, `find_referencing_symbols()` to locate relevant code
before listing files — read symbols, not whole files:

```
get_symbols_overview(relative_path="src/services/PaymentProcessor.ts")   # outline, ~500 tok vs ~2-3k full file
find_symbol(name_path="PaymentProcessor/process", include_body=false)    # locate without pulling the body
find_referencing_symbols(name_path="fetchUser", relative_path="src/api/users.ts")  # all call sites, no grep
```

If Serena is unavailable or the project isn't onboarded, surface it and offer to run `serena init` /
onboarding. Do **not** silently fall back to reading whole files with Glob/Grep/Read. Full rules:
[`_process/tool-playbook.md`](../tool-playbook.md) §4.

### 3.2 — Dedupe per proposed write

For each candidate vault file:
1. Extract slug + keywords.
2. `search()` via claude-mem + `memory_recall()` via OV.
3. Grep `decisions/`, `features/`, `sessions/`, `processes/`, `architecture/` for slug.
4. Compute overlap with existing docs. If `>60%` → mark `UPDATE existing` instead of `CREATE`.

### 3.3 — Output format

```
Code changes:
  - <file1>: <one-line change>
  - <file2>: ...

Vault writes:
  - CREATE features/<slug>.md (dedupe: 0 matches)
  - UPDATE decisions/ADR-042-<slug>.md (dedupe: 80% overlap — existing covers most of topic)
  - CREATE sessions/YYYY-MM-DD-HHMM-<slug>.md (always new per session)

Index updates:
  - _moc.md: link new feature
  - _feature-index.md: row for <slug>
  - decisions/_inventory.md: append ADR-NNN
```

Mark PROPOSE `completed`.

---

## Step 4 — APPROVAL GATE

**STOP.** Present the proposal. Do not proceed until the user explicitly approves.
Approval covers the whole lifecycle **through capture** (Step 6, including `/v-capture`) —
not just code execution. Don't re-ask for permission to commit or capture later.

- Approval ("looks good", "go", "yes", "approved") → Step 5
- Feedback → revise proposal, present again
- Rejection ("no", "cancel") → end; mark remaining tasks `deleted`

---

## Step 5 — EXECUTE

Implement code **and** vault docs in lockstep. Do not batch vault writes for the end — write as the work happens to keep Refs accurate.

### 5.1 — Branch

`/v-work` never creates branches. Work on the branch already checked out
(captured in §2.8 — Git context), including `main`. If isolation is wanted,
the user branches manually before invoking or asks mid-session. Do not run
`git checkout -b`.

### 5.2 — File editing rules

**`sed`, `awk`, `python`, and shell heredocs are never used for file content modification.**

| Operation | Tool | Never use |
|-----------|------|-----------|
| Targeted single-location change | `Edit` | `sed`, `awk`, `python -c` |
| Multiple changes in one file | `MultiEdit` | shell heredocs |
| Bulk pattern edits across multiple files | `MorphLLM morph_edit` | python scripts |
| New file or complete rewrite | `Write` | `echo >`, `tee`, heredocs |
| Symbol rename (project-wide) | Serena `rename()` | `sed -i` across files |
| Extract method / move function | Serena refactor tools | manual copy-paste |

**MorphLLM triggers:** multi-file edits, framework updates, style enforcement, mass replacements.
`morph_edit(target_filepath, instructions, code_edit)`. **Always include `// ... existing code ...`
markers at both ends** of `code_edit` — omitting them deletes the rest of the file. You transmit only
changed lines, so a partial edit costs ~30–50% of a full-file rewrite.

```
morph_edit(
  target_filepath="src/auth.ts",
  instructions="Add validation for missing/short tokens to validateToken",
  code_edit="""// ... existing code ...
  function validateToken(token) {
    if (!token) throw new Error("Token is required");
    if (token.length < 20) throw new Error("Token too short");
    return decode(token);
  }
  // ... existing code ..."""
)
```

Full rules: [`_process/tool-playbook.md`](../tool-playbook.md) §5.

**Serena triggers:** rename with dependency tracking, extract method, move function, project-wide symbol operations. Not for text replacements.

**Best combination:** Serena analyses semantic context → MorphLLM executes the precise edits.

### 5.3 — Per unit of work

For each unit:
1. Make the code change using the right tool from §5.2.
2. Update or create the relevant vault doc.
3. Touch the index file(s) listed in the proposal.

Use `TaskCreate` sub-tasks per unit if work spans many files.

### 5.4 — Tests

Run tests after each phase using the project's detected test command (from CLAUDE.md or framework detection). Fix failures before proceeding. After all phases, run the full suite.

### 5.4b — Delegate verification

- After code changes land, spawn `test-writer-fixer` (via the `Agent` tool) to write/repair
  and run tests for the changed surface.
- BIG scope (>15 files or API/schema changes): spawn `deploy-review-panel` for
  architecture / code / test review before COMMIT.

Keep delegation to these two agents — no domain-agent spawning in `/v-work`.

### 5.5 — Self-review

Before marking complete, check every changed file.

**Code quality (all scopes):**
- [ ] No god classes (>200 lines or >5 responsibilities)
- [ ] No deep nesting (>3 levels)
- [ ] No magic numbers/strings without constants
- [ ] No unused imports, dead code, commented-out code
- [ ] `sed`/`awk`/`python` not used for file edits ← explicit check
- [ ] Pattern compliance with project conventions
- [ ] Input validation at system boundaries

**Architecture (BIG scope: >15 files or API/schema changes):**
- [ ] No breaking changes undocumented
- [ ] No circular dependencies
- [ ] Separation of concerns maintained

Mark EXECUTE `completed`.

---

## Step 6 — COMMIT + CAPTURE

### 6.1 — Code commit

```bash
git status
git diff --stat
```

Stage specific files (never `git add -A`). Commit with a conventional commit message. Do not auto-push.

### 6.2 — Vault commit (if applicable)

If `<project-vault>/` is a separate git repo:
```bash
cd <project-vault>
git add <touched files>
git commit -m "docs(vault): <what changed>"
```

### 6.3 — Push to OpenViking

Probe `memory_health()` first. If unreachable, surface to user and skip — do not fail silently.

Call the OV `memory_store` MCP tool with:
- `text`: summary of what was done (link to session file written by `/v-capture`)
- `role`: `"assistant"`

OV is a Claude Code MCP plugin — only `memory_store`, `memory_recall`, `memory_health`, `memory_forget` are available. There is no `add_episode` tool.

### 6.4 — claude-mem

No action needed. claude-mem auto-captures this session via its SessionEnd hook. The `mcp-search` server is read-only (search/timeline/get_observations only) — there is no write tool.

### 6.5 — Capture session (mandatory)

Invoke `/v-capture` to write the session log. It will dedupe vs recent sessions, update indexes, extract ADR candidates, and cross-link Refs.

This is **not optional and needs no user prompt** — it is part of the lifecycle the user
already approved (Step 4). The COMMIT + CAPTURE task stays `in_progress` until `/v-capture`
has actually run. Never close out `/v-work` without it.

Mark COMMIT + CAPTURE `completed` — only after `/v-capture` has run.

---

## Notes

- Never write source code in Step 2. Vault-first means no premature source reads.
- If dedupe returns conflicting results (OV finds doc X, claude-mem finds doc Y), read both. The vault may have parallel docs that need merging — flag it to the user.
- If `_process/vault-guide.md` is missing, the framework submodule is not initialized. Run `git submodule update --init` in the project vault.
- If any required tool is down at start, surface it and wait for user action rather than silently degrading.
