---
type: process
tags: [process, tools, tokens]
---

# Tool playbook — token-saving tools

This file is the source of truth for the tools every vault command depends on. Each command — `/v-work`,
`/v-team`, and the rest — carries a short inline example at the point of use and links back here.

Token cost is the reason to care. A vault hit costs about 100 to 2000 tokens, a graph slice or symbol
query a few hundred, and reading 40 source files about 20k.

> These are suggestions, not rules: Claude picks the tool that fits the moment, and the cost hierarchy
> below is a default rather than a gate. Safety notes such as Morph's `// ... existing code ...` markers
> stay firm.

**Section numbering starts at 2 and never changes** — a dozen files under `commands/` and `vault/` cite
these sections by number. Section 1 held OpenViking, which the framework dropped;
`docs/removing-openviking.md` takes an old install off a machine.

---

## Cost hierarchy — use in order, stop when you have enough

| Priority | Tool | Cost | Use for |
|----------|------|------|---------|
| 1 | claude-mem `search`→`timeline`→`get_observations` | ~100→300→1000 tok | Project history, progressive disclosure |
| 2 | Graphify `query` / `path` | ~hundreds tok | **Structural questions**: what calls X, where is Y defined, which modules touch Z |
| 3 | Serena `get_symbols_overview` / `find_symbol` | small, real-time | Reading or navigating a file or symbol without dumping the whole file |
| 4 | Grep / Read over `~/vault/` and source | ~1000–20k tok | **Last resort** — after layers 1–3 come up empty, or to verify an exact current line. Grep over the vault is also the standing fallback when claude-mem is absent. |

Query the graph before you grep, and read a symbol before you read a whole file. Grepping source for
"what calls X" or "where is Y" is a graphify query (layer 2).

**Layers 2 and 3 ship only in the `--full` developer install.** A `light` machine lacks them by design,
layer 4 is its whole code path, and nothing reports their absence as a gap. Read
`~/vault/_global/config.md` → `install_mode` before offering to install either one (ADR-021).

---

## Health checks & fallbacks — canonical table

This table is the single source of truth for every vault command, and the dispatchers link here rather
than carrying copies. Use a present tool; health-check one that looks down, warn once, fall back, and
**never halt**.

| Tool | Health check | Fallback if down |
|------|-------------|------------------|
| claude-mem | `search("test", limit=1)` via mcp-search | `Grep` over `~/vault/`; say so once |
| Serena | `check_onboarding_performed()` | graphify → Glob/Grep/LSP |
| MorphLLM | (MCP — no runtime check) | `Edit` / `MultiEdit` |
| graphify | `graphify-out/graph.json` present | grep — offer `graphify hook install` only on a full install |
| PostHog (MCP) | a cheap read query via the MCP (e.g. list insights / `query` skill ping) | metric findings → `advisory`; say so |
| Bright Data | `bdata` CLI auth/status (or a 1-result `search`) | SERP/scrape findings → `advisory`; say so |
| BOE (MCP) | MCP handshake / trivial statute lookup | legal findings → `advisory`; cite "unwired" |

Business-pack persona analyzers that are *agents* (sales-*/seo-*, finance-tracker) need no health row.
They resolve through the base_agent fallback in `personas/_resolution.md` §3.

**Grounding tiers:** a recompute or grep check needs no external tool and can always be `confirmed`. A
finding pulled from a tool is `advisory` unless the wiring check above passes.

---

## 2. claude-mem — project history (progressive disclosure)

A read-only `mcp-search` server with three layers. Climb only as far as you need. It ships with
`setup.sh --full` and `setup.sh --with-claude-mem`; when absent, say so once and grep the vault instead:
`grep -ril "<keyword>" <project-vault>/{decisions,sessions,indications,features}/`.

**When:** "did we already solve this?", "how did we do X last time?", what-changed-when.
**When NOT:** as a write target. It auto-captures through its SessionEnd hook and exposes no write tool.
The durable record is the vault's own `sessions/*.md`, which git tracks and grep reads.

```
# Layer 1 — compact index of IDs (~100 tok). Stop here if nothing relevant.
search(query="permission cache", limit=20)

# Layer 2 — context window around a promising hit (~300 tok).
timeline(anchor="6042")

# Layer 3 — full detail for the few IDs that matter (~1000 tok).
get_observations(ids=["6042", "6051"])
```

Filter by `type` (decision, bugfix, feature, refactor, discovery) and by date when that narrows fast.

---

## 3. Graphify — structural code graph

A post-commit hook rebuilds `graph.json` by AST extraction (`graphify hook install`), so it costs no LLM
tokens and stays fresh. `/v-init` installs the hook per project. **Query the graph; never grep source to
answer a structural question.**

Tools: `graphify query "<q>"`, `graphify path "A" "B"`, `graphify explain "<node>"`.

**When:** what calls X, where X is defined, which modules touch Z, dependency and call chains.
**When NOT:** the exact current line of one known symbol — read that line — or non-structural prose.

**If `graphify-out/graph.json` is missing**, read `~/vault/_global/config.md` → `install_mode` first. On
`full` the hook is simply not installed for this repo: surface that and offer `graphify hook install`
plus an initial `graphify .` build rather than grepping silently. On `light` or `minimal` the tool was
never installed, so fall back to grep **without comment** (ADR-021).

```
# "What calls validateUserToken?"  — ~200 tok vs ~10k for recursive grep + reads
graphify query "validateUserToken callers"

# "How does the auth module reach the database?"  — shortest path with intermediate nodes
graphify path "AuthModule" "DatabaseConnection"

# "Explain this node" — all edges (calls, refs, rationale) with confidence + source_location
graphify explain "PaymentProcessor"
```

Edges carry a confidence (`EXTRACTED` certain → `INFERRED` → `AMBIGUOUS`) and a `source_location`. Cite
the location when you answer.

---

## 4. Serena — symbol-aware navigation & editing

Serena is LSP-backed. It reads and edits by symbol, so you never dump a whole file into context.

Navigation: `get_symbols_overview`, `find_symbol`, `find_referencing_symbols`, `find_implementations`.
Editing: `replace_symbol_body`, `insert_after_symbol`, `insert_before_symbol`, `rename_symbol`.
Session: `check_onboarding_performed`, `activate_project`, `list_memories`, `read_memory`, `write_memory`.

**When:** orient in a file, locate a symbol, find every call site before a refactor, run a
dependency-tracked rename or extract.
**When NOT:** a file under about 200 lines you will read whole anyway, or a generic name needing grep.
**On failure:** when the project is not onboarded, surface that and offer to run `serena init` rather
than silently reading whole files. When Serena is not installed at all, read `install_mode`: on `light`
or `minimal` it was never meant to be there, so read the file and say nothing (ADR-021).

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

A TypeScript rename costs about 38k tokens through grep plus 15 file reads, and about 4k through Serena.

---

## 5. MorphLLM Fast Apply — targeted multi-line / multi-file edits

A fast-apply model merges an edit *snippet* into a file, so you transmit only the changed lines. That
costs about 30 to 50% of a full-file rewrite, and less on large files. MCP:
`morph_edit(target_filepath, instructions, code_edit)`.

**When:** files of about 50 to 1000 lines changing a fraction; bulk edits; style or framework sweeps.
**When NOT:** files under about 30 lines — just `Write` — or rewrites above about 60%, where the
cost-benefit inverts back to `Write`.
**Hard rule: always include `// ... existing code ...` markers at both ends of `code_edit`.** Omitting
them tells the model to delete everything else.

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

For a project-wide symbol rename or an extract-method, prefer Serena, which tracks references. The best
combination is Serena finding the semantic context and Morph applying the precise edit.

---

## Anti-patterns (usually avoid)

- Grepping source to answer "what calls X" or "where is Y defined" → usually a graphify query (§3).
- Reading a whole 800-line file to understand structure → `get_symbols_overview` (§4).
- Rewriting an entire file to change 10 lines → `morph_edit` with markers (§5).
- Editing file content with `sed`, `awk`, `python` or heredocs → use Edit, MultiEdit, Morph or Serena.
- Falling back to grep silently when a tool looks unavailable → confirm it is down, then say so. Grep
  over the vault is a legitimate destination; the unannounced fallback is the defect.

---

## 6. Project tools (task trackers & team MCPs)

A repo may use **project-specific MCPs** beyond the backbone above, most often a task tracker such as
Jira, Asana, Linear or GitHub Issues. The framework hard-wires none. A repo declares its own in
`VAULT.md` → `tools` (see `vault-guide.md` §1.1) and the lifecycle picks it up.

**Suggestion, not a rule:** when the task references a ticket such as `VAULT-123` or `#42`, and the repo
declares a `task_tracker` and a `task_tracker_mcp`, reach for that MCP before grep or the web. With none
declared, ask which tracker or skip. With the MCP down, fall back to web or grep and say so. Never halt.

```
# VAULT.md
## tools
task_tracker: jira
task_tracker_mcp: <jira mcp server>
task_tracker_key: VAULT
guidance: "Fetch the ticket's description + acceptance criteria before proposing."
```

`VAULT.md` `hooks` (§1.1) express the per-step *when*: `on_start` or `pre_load_context` to fetch,
`post_commit` to remind. Sections 1 to 5 above own the layer-picking rules.

---

## 7. Web research — grounding against hallucination

Web research saves correctness rather than tokens. Everything above answers **what this codebase does**;
the web answers **how this class of problem is usually solved**. Reach for it in PROPOSE §3a.0b before
committing to a non-trivial approach, and any time you are about to assert a fact from memory.

- `WebSearch` — the problem, the common solutions, the pitfalls, the community-default library.
- `WebFetch <url>` — a specific doc, RFC, issue or benchmark.
- Agents for depth: `deep-research` for a multi-source cited report, `tool-evaluator` for a library
  comparison, `trend-researcher` for what the ecosystem adopted.

**Treat your first-instinct approach as a hypothesis, not a conclusion.** Cite the sources in the plan
artifact, and reconcile a contradicting consensus **explicitly**: adopt it, or write down the constraint
that justifies keeping your approach. Never override the internet with your prior in silence.
