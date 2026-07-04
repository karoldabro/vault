---
type: plan
project: vault
date: 2026-07-04-1030
topic: v-family-usage-audit-retiering
status: executed
rounds: 1 (analyst panel: command-auditor · usage-analyst · online-researcher, single-pass)
convergence: clean
tags: [plan, meta, tiering, capture, token-economy, observability]
---

# v- family usage audit → framework overhaul

## Evidence base (panel findings)

- **Usage** (all-time transcripts): /v-work 284 · /v-team 194 (40%, rising to **78% of early-July runs**) ·
  /v-ask 18 · /v-capture 9 · /v-do 8 · /v-cr 4; v-migrate/v-resume ≈ 0. v-team costs ~2.1× per run
  (median 1.76 MB vs 0.83 MB parent transcript; 4.9 vs 2.3 agent spawns) with the **same ~79% completion
  rate** as v-work. ~1 in 5 lifecycle runs abandoned before commit/capture, flat across commands.
- **Audit**: two breakages (v-guide `memory_store(content=,tags=)` never existed; v-capture header
  contradicted its own skip-if-down rule); v-capture.md (1,625 w) auto-loaded on all ~478 runs;
  tool-table × 5 + hooks boilerplate × 8 duplicated; do/work/team ladder conflates **trust** (gate) with
  **rigor** (critics) — the only route to any adversarial review was the full panel.
- **Diagnostics**: the "extraction returned 0 memories" noise (77% of sessions) is **OpenViking's** —
  no `vlm` section in `~/.openviking/ov.conf` (16,382 errors); claude-mem separately missing
  `pending_messages.retry_count` (migration bug); observability hook = 12 events × `uv run` subprocess,
  Pre/PostToolUse = 87% of ~9.2k daily spawns; `events.db` 31.6 GB, unbounded.
- **Community (2026)**: consensus is anti-bloat — heavy methodology only when a wrong decision is
  expensive to reverse; single-pass parallel review panels for routine work, convergence loops reserved;
  curated markdown memory "handles 80%"; one capture path; read-only critics with dry-round convergence
  (Sant'Anna). Sources catalogued in the session doc.

## Executed phases (commits on master)

0. `04a6f2f` fix(commands) — both breakages + stale §1.4 ref + §12.1 knob docs
1. `9eabac4` refactor(capture) — `bin/vault-capture.sh` (dedupe/scan-adr/scan-ind/refs/next-adr/index-moc),
   v-capture.md 1,625→~830 w; canonical tool table in tool-playbook; hooks one-liners
2. `c5f9d91` feat(tiering) — lite critic §3a.6, auto fast path (01-analyze §1.4c + dispatcher),
   concrete v-team cost line, research gate narrowed to novel choices
3. `afc17ee` chore(commands) — /v-migrate + /v-resume → `commands/attic/`; install.sh skips attic
   - `7503468` fix(capture-script) — octal guard in next-adr (found dogfooding this capture)
   - Machine-level (outside repo): Pre/PostToolUse observability hooks removed from
     `~/.claude/settings.json`; `events.db` pruned to 60 days + VACUUM; claude-mem `retry_count` column added.

## Open at plan close

- OV `vlm` extraction fix — user deciding local (ollama qwen2.5:7b fits GTX 1070 8GB) vs Anthropic Haiku
  vs leave-as-is (embedding-only recall worked fine for 6 weeks without extraction).
- Deferred to later: effort/model tiers per command; /code-review for GitHub path of /v-cr;
  MCP/skill security vetting cadence; Stop hook `--add-chat` transcript embedding (main residual DB driver).

Refs: [[../sessions/2026-07-04-1115-v-family-usage-audit-retiering]] ·
[[../decisions/ADR-015-retier-lifecycle-lite-critic-fast-path]]
