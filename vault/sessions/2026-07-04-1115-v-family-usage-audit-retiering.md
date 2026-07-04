---
type: session
project: vault
date: 2026-07-04-1115
topic: v-family-usage-audit-retiering
files_touched: [commands/v-guide.md, commands/v-capture.md, commands/v-team.md, commands/v-work.md, commands/v-cr.md, commands/v-do.md, commands/v-init.md, commands/v-work/steps/01-analyze.md, commands/v-work/steps/02-load-context.md, commands/v-work/steps/03-propose.md, commands/v-work/steps/04-execute.md, commands/v-team/steps/03-propose-loop.md, commands/v-team/steps/04-execute-loop.md, commands/v-pm/steps/01-intake.md, commands/attic/, bin/vault-capture.sh, tool-playbook.md, vault-guide.md, install.sh, README.md, commands/README.md]
decisions: [ADR-015]
tags: [session, meta, usage-audit, tiering, capture, token-economy, observability, research]
---

# v- family usage audit → re-tiering + capture extraction

## Goal
Audit Karol's Claude usage + the v- command family (panel of command-auditor · usage-analyst ·
online-researcher), then execute the approved 4-phase overhaul.

## Did
- **Audit findings**: /v-team = 40% of 462 lifecycle runs, rising to 78% in early July, at ~2× cost with
  the same ~79% completion rate as /v-work; /v-do starved (8 uses); 2 breakages; v-capture.md (1,625 w)
  auto-loaded every run; "0 memories" noise in 77% of sessions traced to **OpenViking missing its `vlm`
  config** (not claude-mem); `events.db` 31.6 GB unbounded; Pre/PostToolUse = 87% of ~9.2k daily hook spawns.
- **Phase 0** `04a6f2f`: fixed `memory_store(content=,tags=)` → `(text=,role=)` in v-guide; v-capture
  header contradiction; stale `_resolution.md §1.4` ref; documented `team_max_*` knobs (vault-guide §12.1).
- **Phase 1** `9eabac4`: new [[../../bin/vault-capture.sh]] (dedupe / scan-adr / scan-ind / refs /
  next-adr / index-moc); v-capture.md halved; canonical tool table moved to tool-playbook; hooks
  boilerplate one-linered in steps 02/03/04.
- **Phase 2** `c5f9d91`: lite critic §3a.6 (one read-only critic, one pass, /v-work only); auto fast
  path (01-analyze §1.4c + dispatcher); measured cost line in v-team.md; research gate narrowed to
  novel choices. [[../decisions/ADR-015-retier-lifecycle-lite-critic-fast-path]].
- **Phase 3** `afc17ee`: /v-migrate + /v-resume archived to `commands/attic/` (install.sh skips attic;
  stale symlinks removed; v-pm links installed as a side-effect fix). Machine-level: Pre/PostToolUse
  hooks removed from `~/.claude/settings.json`; `events.db` pruned to 60 days + VACUUM; claude-mem
  `pending_messages.retry_count` column added.
- **Dogfooding bonus** `7503468`: this capture found an octal bug in `next-adr` (ADR-014 read as 12).

## Learned
- Transcript archaeology beats intuition: v-team "felt" safer (v-work ESC'd 20% vs v-team 13%) but bought
  zero completion-rate gain — the tiering was a routing problem, not a rigor problem.
- The "extraction returned 0 memories" message names claude-mem in perception but is emitted by the OV
  bridge; OV ran 6 weeks as embedding-only recall and nobody noticed — extraction is enrichment, not
  load-bearing.
- `install.sh` symlinks every commands/ subdir — an attic/ dir would have shipped without the skip.
- Bash arithmetic reads zero-padded numbers as octal; `10#` prefix required when parsing ADR ids.
- Community consensus 2026: single-pass parallel review for routine, loops only for expensive-to-reverse;
  curated markdown memory first; one capture path; keep always-on context minimal (ETH: bloat = −2–3%
  quality, +20% cost).

## Behaviors & rules
- /v-work small-job detection: /v-do guardrail passes → fast path (v-do flow), user "full lifecycle"
  overrides; edge: any doubt about size → normal path. [ADR-015]
- Lite critic: runs when plan >2 files or open trade-offs; exactly 1 read-only critic, 1 pass; edge:
  panel-worthy risk found → suggest /v-team, never loop locally. [ADR-015]
- `vault-capture.sh next-adr` returns max(inventory, files)+1 in base 10; edge: zero-padded ids must
  not be octal-parsed.
- install.sh: `commands/attic/` is never symlinked; stale symlinks pointing into commands/ are pruned.
- v-capture pushes: OV/claude-mem down → surface + skip that push, never halt, never skip silently.

## Next
- **Open**: OV `vlm` fix decision (local qwen2.5:7b on GTX 1070 vs Anthropic Haiku vs leave embedding-only).
- Deferred: effort/model tiers per command; route GitHub PRs to built-in /code-review (keep /v-cr for
  Bitbucket+Jira/Asana); MCP/skill security vetting cadence; Stop hook `--add-chat` transcript embedding.
- Watch: v-team share of lifecycle runs — target <20% by Aug 2026 (ADR-015 consequence).

## Refs
- [[../plans/2026-07-04-1030-v-family-usage-audit-retiering]]
- [[../decisions/ADR-015-retier-lifecycle-lite-critic-fast-path]]
- [[../decisions/ADR-007-light-siblings-guardrail]]
- Key sources: psantanna.com worker-critic loop · ranthebuilder.cloud spec-tool benchmark ·
  support.claude.com power-user tips · mindstudio.ai memory tiering · rywalker.com framework survey
