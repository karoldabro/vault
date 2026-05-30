# Step 2 — LOAD CONTEXT (vault-first)

Load all relevant context **before touching source code**. Query cheapest-first; stop as soon as
you have enough. Each layer costs 10–100× less than reading source. **Graph before grep, symbol
before full-file read.** Full per-tool rules + examples: `_process/tool-playbook.md`.

**Tools are preferred, not gating.** When a token-saving tool is present, use it — do not hand-roll
grep / full-file reads in its place. When one is genuinely unavailable, confirm via its health check,
warn once, then proceed with the documented fallback (OV→Grep over `~/vault`, graphify→grep,
Serena→Glob/Grep/LSP). Never halt the lifecycle for a missing tool.

**Fan out with agents.** When scope is uncertain or spans multiple areas, launch up to 3 **Explore**
subagents in parallel (single message, multiple `Agent` calls) instead of serial reads — give each a
distinct focus (vault decisions/guidelines · code structure · tests). One Explore agent is enough for
an isolated task with known files. Agents return conclusions; you keep the context lean.

### 2.1 — OpenViking (vault memory — always first)

Call `memory_recall(query=<keywords>)`. Covers the vault: decisions, ADRs, past sessions, feature
dossiers, pitfalls, lessons. Look for: prior decisions in this area, known gotchas, related features
already built, coupled projects (`~/vault/_global/coupled-groups.md`). Cost: ~100–2000 tok.

### 2.2 — claude-mem (project history — progressive disclosure)

`search(query=<keywords>, limit=20)` → compact ID index (~100 tok). Climb to `timeline(anchor=<id>)`
(~300 tok) then `get_observations(ids=[...])` (~1000 tok) only for promising hits. Filter by `type`
(decision, bugfix, feature, refactor, discovery) and date when it narrows fast.

### 2.3 — Vault MOC + process guide

Read `<project-vault>/_moc.md`. Read `<project-vault>/_process/vault-guide.md` if not already read
this session.

### 2.3b — Vault patterns & guidelines (do not skip)

Discover guidelines/conventions that constrain this task — they override generic defaults.

1. With the Step-1 keywords: `grep -ril "<keyword>" <project-vault>/{features,processes,architecture}/ 2>/dev/null`
2. Read every match (conventions, patterns, gotchas).
3. Expected docs by topic: api/endpoint→API conventions · queue/job→queue architecture ·
   model/migration→model/DB patterns · frontend/component→frontend patterns ·
   auth/permission→authorization patterns · test→testing guidelines.
   These live in `features/·processes/·architecture/` (per `vault-guide.md` §6) — **not** Serena.
4. If OV §2.1 already surfaced one, don't re-read it.

### 2.4 — Graphify (structural orientation)

`graph.json` is kept fresh by the per-project post-commit hook. For **any** structural question —
what calls X, where is Y defined, which modules touch Z, dependency chains — query the graph before
Serena or grep: `graphify query "<q>"`, `graphify path "A" "B"`. If `graphify-out/graph.json` is
missing the hook isn't installed: surface it and offer `graphify hook install` + an initial
`graphify .` build before falling back to grep. Full rules: `_process/tool-playbook.md` §3.

### 2.5 — Serena (semantic navigation — if code change implied)

`get_symbols_overview(<file>)` for a file outline, `find_symbol(<name>)` to locate, and
`find_referencing_symbols(<symbol>)` for impact. Orient before reading whole files. §4 of the
playbook for full rules.

### 2.6 — Recent sessions + decisions

Last 3 sessions by mtime: `ls -t <project-vault>/sessions/*.md | head -3`. ADRs touching the topic.

### 2.7 — CLAUDE.md

Read project `CLAUDE.md` if present. Its instructions override all defaults.

### 2.8 — Git context

```bash
git status && git branch --show-current && git log --oneline -5
```

### 2.9 — Grep / Read (last resort)

Only after the layers above come up empty, or to verify a specific line. Reading 40 source files
costs ~20k tokens; a vault hit costs ~100–2000. Wrong default wastes 100×.

### Required output

```
OV: [results — decisions, sessions, pitfalls — or "nothing relevant" / "unavailable, fell back to grep"]
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
