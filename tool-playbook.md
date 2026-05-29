---
type: process
tags: [process, tools, tokens]
---

# Tool playbook — token-saving tools

Canonical rules + worked examples for the tools every vault command depends on. The commands
(`/v-work`, `/v-resume`, …) carry a short inline example at the point of use and link back here for
the full ruleset. **This file is the source of truth.**

The whole point is cost. A vault hit costs ~100–2000 tokens. A graph slice costs ~hundreds. A
symbol query costs ~hundreds. Reading 40 source files costs ~20k. **Picking the wrong default
wastes 100×.** Default to the cheap path; reach for grep / full-file reads only when the cheap
layers genuinely come up empty.

---

## Cost hierarchy — use in order, stop when you have enough

| Priority | Tool | Cost | Use for |
|----------|------|------|---------|
| 1 | OpenViking `memory_recall` | ~100–2000 tok | Vault decisions, ADRs, past sessions, pitfalls |
| 2 | claude-mem `search`→`timeline`→`get_observations` | ~100→300→1000 tok | Project history, progressive disclosure |
| 3 | Graphify `query` / `path` | ~hundreds tok | **Structural questions**: what calls X, where is Y defined, which modules touch Z |
| 4 | Serena `get_symbols_overview` / `find_symbol` | small, real-time | Reading/navigating a specific file or symbol without dumping the whole file |
| 5 | Grep / Read | ~1000–20k tok | **Last resort** — only after layers 1–4 come up empty, or to verify an exact current line |

Rule of thumb: **graph before grep, symbol before full-file read.** If you're about to `Grep`
across source to answer "what calls X" or "where is Y" — stop, that's a graphify query (layer 3).

---

## 1. OpenViking (OV) — semantic vault memory

MCP plugin (no `curl`, no HTTP). Tools: `memory_recall`, `memory_store`, `memory_health`,
`memory_forget`.

**When:** first thing, every task. Prior decisions, ADRs, past sessions, known pitfalls.
**When NOT:** structural code questions (use graphify) or current line-level behavior (read source).
**On failure:** call `memory_health()` to confirm it's down. Only then fall back to `Grep` over
`~/vault/`. Never silently skip it.

```
memory_recall(query="bouncer tenancy permission cache")
→ top hits: ADR-042 (permission cache invalidation), session 2026-03-11 (tenancy gotcha), …
```

```
# after work is done — persist a summary (role: "assistant")
memory_store(text="Refactored permission cache to per-tenant keys; see session 2026-05-29-...", role="assistant")
```

---

## 2. claude-mem — project history (progressive disclosure)

Read-only `mcp-search` server. Three layers — climb only as far as you need.

**When:** "did we already solve this?", "how did we do X last time?", what-changed-when.
**When NOT:** as a write target — it auto-captures via its SessionEnd hook; there is no write tool.

```
# Layer 1 — compact index of IDs (~100 tok). Stop here if nothing relevant.
search(query="permission cache", limit=20)

# Layer 2 — context window around a promising hit (~300 tok).
timeline(anchor="6042")

# Layer 3 — full detail for the few IDs that matter (~1000 tok).
get_observations(ids=["6042", "6051"])
```

Filter by `type` (decision, bugfix, feature, refactor, discovery) and date when it narrows fast.

---

## 3. Graphify — structural code graph

`graph.json` is **auto-rebuilt by a post-commit hook** (`graphify hook install`) using AST
extraction — **no LLM, no token cost** for code. `/v-init` installs the hook per project, so the
graph is always fresh. **Query the graph; never grep source to answer a structural question.**

Tools: `graphify query "<q>"`, `graphify path "A" "B"`, `graphify explain "<node>"`.

**When:** what calls X, where is X defined, which modules touch Z, dependency/call chains.
**When NOT:** exact current line of one known symbol (read that line) or non-structural prose.
**If `graphify-out/graph.json` is missing:** the hook isn't installed. Surface it and offer
`graphify hook install` + an initial `graphify .` build. Do **not** silently grep instead.

```
# "What calls validateUserToken?"  — ~200 tok vs ~10k for recursive grep + reads
graphify query "validateUserToken callers"

# "How does the auth module reach the database?"  — shortest path with intermediate nodes
graphify path "AuthModule" "DatabaseConnection"

# "Explain this node" — all edges (calls, refs, rationale) with confidence + source_location
graphify explain "PaymentProcessor"
```

Edges carry confidence (`EXTRACTED` certain → `INFERRED` → `AMBIGUOUS`) and `source_location` —
cite the location when you answer.

---

## 4. Serena — symbol-aware navigation & editing

LSP-backed. Reads/edits by symbol so you never dump a whole file into context.

Navigation: `get_symbols_overview`, `find_symbol`, `find_referencing_symbols`, `find_implementations`.
Editing: `replace_symbol_body`, `insert_after_symbol`, `insert_before_symbol`, `rename_symbol`.
Session: `check_onboarding_performed`, `activate_project`, `list_memories`, `read_memory`, `write_memory`.

**When:** orient in a file, locate a symbol, find all call sites before a refactor, do a
dependency-tracked rename / extract.
**When NOT:** a file <~200 lines you'll read whole anyway; generic symbol names that need grep to
disambiguate.
**On failure:** if Serena is unavailable or the project isn't onboarded, surface it and offer to run
`serena init` / onboarding. Do **not** silently fall back to reading whole files.

```
# Understand a file WITHOUT reading it whole (~500 tok vs ~2-3k for the full file)
get_symbols_overview(relative_path="src/services/PaymentProcessor.ts")
→ class PaymentProcessor { process(), refund(), validateCard() }

# Locate a symbol without pulling its body
find_symbol(name_path="PaymentProcessor/process", include_body=false)

# Before any rename/refactor — find every call site (no grep)
find_referencing_symbols(name_path="fetchUser", relative_path="src/api/users.ts")
→ 14 references across 9 files

# Atomic, dependency-tracked rename (all 14 sites updated by the language server)
rename_symbol(name_path="fetchUser", new_name="getUserProfile", relative_path="src/api/users.ts")
```

Token math: a TypeScript rename via grep + 15 file reads ≈ 38k tokens; via Serena symbols ≈ 4k.

---

## 5. MorphLLM Fast Apply — targeted multi-line / multi-file edits

Fast-apply model merges an edit *snippet* into a file — you transmit only changed lines, never the
whole file. MCP: `morph_edit(target_filepath, instructions, code_edit)`.

**When:** edits to files ~50–1000 lines changing a fraction of them; bulk edits across many files;
style/framework sweeps.
**When NOT:** files <~30 lines (just `Write`); >~60% rewrites (cost/benefit inverts — `Write`).
**Hard rule:** **always include `// ... existing code ...` markers at both ends** of `code_edit`.
Omitting them tells the model to delete everything else.

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

Token math: you transmit only changed lines, so a partial edit costs ~30–50% of a full-file rewrite
(more on large files); high merge accuracy.

For project-wide symbol renames / extract-method, prefer Serena (it tracks references). Best combo:
**Serena finds the semantic context → Morph applies the precise edit.**

---

## Anti-patterns (don't do these)

- Grepping source to answer "what calls X / where is Y defined" → that's a graphify query (§3).
- Reading a whole 800-line file to understand structure → `get_symbols_overview` (§4).
- Rewriting an entire file to change 10 lines → `edit_file` with markers (§5).
- `sed`/`awk`/`python`/heredocs to edit file content → use Edit / MultiEdit / Morph / Serena.
- Silently falling back to grep when a required tool is "unavailable" → confirm it's down first,
  then say so. Don't degrade quietly.
