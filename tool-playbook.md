---
type: process
tags: [process, tools, tokens]
---

# Tool playbook — token-saving tools

This file is the source of truth for the tools every vault command depends on. Each command — `/v-work`,
`/v-team`, and the rest — carries a short inline example at the point of use and links back here.

Token cost is the reason to care. A vault hit costs about 100 to 2000 tokens, a symbol query a few
hundred, and reading 40 source files about 20k.

> These are suggestions, not rules: Claude picks the tool that fits the moment, and the cost hierarchy
> below is a default rather than a gate. The safety notes stay firm.

**Section numbers never change** — files under `commands/` and `vault/` cite these sections by number.
The numbered sections are 4, 6 and 7.

---

## Cost hierarchy — use in order, stop when you have enough

| Priority | Tool | Cost | Use for |
|----------|------|------|---------|
| 1 | Grep over the project vault | ~100–2000 tok | Project history: `grep -ril "<keyword>" <project-vault>/{decisions,sessions,indications,features}/` |
| 2 | Serena `get_symbols_overview` / `find_symbol` / `find_referencing_symbols` | small, real-time | Structural questions and reading a symbol without dumping the whole file |
| 3 | Grep / Glob / Read over source | ~1000–20k tok | **Last resort** — after layers 1–2 come up empty, or to verify an exact current line |

Read a symbol before you read a whole file. When Serena is absent, layer 3 is the whole code path.

---

## Health checks & fallbacks — canonical table

This table is the single source of truth for every vault command, and the dispatchers link here rather
than carrying copies. Use a present tool; health-check one that looks down, warn once, fall back, and
**never halt**.

| Tool | Health check | Fallback if down |
|------|-------------|------------------|
| Serena | `check_onboarding_performed()` | Glob/Grep/LSP |
| PostHog (MCP) | a cheap read query via the MCP (e.g. list insights / `query` skill ping) | metric findings → `advisory`; say so |
| Bright Data | `bdata` CLI auth/status (or a 1-result `search`) | SERP/scrape findings → `advisory`; say so |
| BOE (MCP) | MCP handshake / trivial statute lookup | legal findings → `advisory`; cite "unwired" |

Business-pack persona analyzers that are *agents* (sales-*/seo-*, finance-tracker) need no health row.
They resolve through the base_agent fallback in `personas/_resolution.md` §3.

**Grounding tiers:** a recompute or grep check needs no external tool and can always be `confirmed`. A
finding pulled from a tool is `advisory` unless the wiring check above passes.

---

## 4. Serena — symbol-aware navigation & editing

Serena is LSP-backed. It reads and edits by symbol, so you never dump a whole file into context.

**Serena is optional.** Only `setup.sh --full` installs it. When Serena is absent, use Read and Grep and
say nothing about it (ADR-021).

Navigation: `get_symbols_overview`, `find_symbol`, `find_referencing_symbols`, `find_implementations`.
Editing: `replace_symbol_body`, `insert_after_symbol`, `insert_before_symbol`, `rename_symbol`.
Session: `check_onboarding_performed`, `activate_project`, `list_memories`, `read_memory`, `write_memory`.

**When:** orient in a file, locate a symbol, find every call site before a refactor, run a
dependency-tracked rename or extract.
**When NOT:** a file under about 200 lines you will read whole anyway, or a generic name needing grep.
**On failure:** when Serena is installed but the project is not onboarded, surface that and offer to
run `serena init` rather than silently reading whole files.

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

## Anti-patterns (usually avoid)

- Reading a whole 800-line file to understand structure → `get_symbols_overview` (§4) when Serena is
  present.
- Rewriting an entire file to change 10 lines → `Edit`.
- Editing file content with `sed`, `awk`, `python` or heredocs → use Edit, MultiEdit or Serena.
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
`post_commit` to remind. The cost hierarchy and §4 above own the layer-picking rules.

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
