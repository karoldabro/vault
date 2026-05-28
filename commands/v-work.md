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

Use `TaskCreate` to add one task per step. Mark `in_progress` when starting, `completed` when done. The task list is the enforcement mechanism — do not skip a step.

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

### 2.4 — Graphify (structural orientation)

If `graphify-out/graph.json` exists in the project root:
- `graphify query "<question>"` — where is X defined, what calls Y, which modules touch Z
- `graphify path "A" "B"` — dependency chain

Cost: ~hundreds of tokens vs thousands for recursive grep. Use this before opening any source files.

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

Read selectively based on task keywords:

| Keywords | Memories to read |
|----------|-----------------|
| api, endpoint, controller, route | API conventions, openapi guide |
| queue, job, async, worker | Queue architecture |
| model, database, migration, schema | Model patterns, DB conventions |
| frontend, component, view | Frontend patterns |
| auth, permission, policy, role | Authorization patterns |
| test, testing | Testing guidelines |

Use `find_symbol()`, `get_symbols_overview()`, `find_referencing_symbols()` to locate relevant code before listing files in the proposal.

If Serena unavailable or project not onboarded, surface that to the user and proceed with Glob/Grep/Read.

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

- Approval ("looks good", "go", "yes", "approved") → Step 5
- Feedback → revise proposal, present again
- Rejection ("no", "cancel") → end; mark remaining tasks `deleted`

---

## Step 5 — EXECUTE

Implement code **and** vault docs in lockstep. Do not batch vault writes for the end — write as the work happens to keep Refs accurate.

### 5.1 — Branch

If not already on a feature branch:
```bash
git checkout -b feature/<descriptive-task-name>
```

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

**MorphLLM triggers:** multi-file edits, framework updates, style enforcement, mass replacements. Parameters: `morph_edit(target_filepath, instructions, code_edit)` using `// ... existing code ...` markers. Token efficiency gain: 30–50%.

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

### 6.5 — Capture session

Invoke `/v-capture` to write the session log. It will dedupe vs recent sessions, update indexes, extract ADR candidates, and cross-link Refs.

Mark COMMIT + CAPTURE `completed`.

---

## Notes

- Never write source code in Step 2. Vault-first means no premature source reads.
- If dedupe returns conflicting results (OV finds doc X, claude-mem finds doc Y), read both. The vault may have parallel docs that need merging — flag it to the user.
- If `_process/vault-guide.md` is missing, the framework submodule is not initialized. Run `git submodule update --init` in the project vault.
- If any required tool is down at start, surface it and wait for user action rather than silently degrading.
