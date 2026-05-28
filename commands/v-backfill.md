---
description: Extract past Claude Code sessions for a project and ingest them into OpenViking. Use for targeted historical context (specific topic or date range), not wholesale backfill.
argument-hint: "<project-slug> [--days N | --search 'term']"
---

Extract Claude Code chat transcripts for a project and ingest into OpenViking as resources. **Targeted use only** — wholesale backfill on 3000+ sessions is noisy and expensive. Use this when you remember a specific past episode worth indexing.

## Parse $ARGUMENTS

Required: a project slug (e.g. `vivi`, `vivi/api`, `digitally-core`).

Optional filters:
- `--days N` — only sessions modified in the last N days (default 30 if no other filter).
- `--search "term"` — only sessions matching the search term (`claude-extract --search`).
- Combine: `--days 60 --search "Bouncer"`.

If no slug → stop, tell user the syntax + list known slugs from `~/vault/_global/coupled-groups.md`.

## Resolve paths

1. **Repo path** for the slug — from `coupled-groups.md`. e.g. `vivi/api` → `/home/kdabrow/workspace/vivi/api`.
2. **Encoded auto-memory dir name** — repo path with `/` replaced by `-`, leading `-`. e.g. `-home-kdabrow-workspace-vivi-api`. Verify `~/.claude/projects/<encoded>/` exists.
3. **Backfill output dir** — `~/vault/<slug>/sessions/_backfill/<YYYY-MM-DD-HHMM>-<filter-tag>/` where filter-tag = `days<N>` or `search-<slug>`.

## Pre-flight check

- OV reachable: call `memory_health()` MCP. If unreachable, stop with the same instruction as `/v-sync`.
- `claude-extract` on PATH. If not, stop with `pipx install claude-conversation-extractor`.

## Extract sessions

Use `claude-extract`. Two modes depending on filters:

**Date filter only (`--days N`)**:
```bash
mkdir -p <backfill-dir>
claude-extract --recent <N*5> --output <backfill-dir> --format markdown 2>&1
# Then prune to project: rm any extracted file whose `📁 home kdabrow workspace ...` doesn't match the repo path.
```

(claude-extract `--recent` is global; we over-fetch then filter by repo. The 5x multiplier is a rough heuristic — adjust if the project is high-activity.)

**Search filter (`--search`)**:
```bash
mkdir -p <backfill-dir>
claude-extract --search "<term>" --search-date-from $(date -d "<N> days ago" +%Y-%m-%d) --output <backfill-dir> --format markdown 2>&1
```

After extraction:
- Walk the output dir.
- Drop any file whose first ~10 lines don't mention the target repo path. claude-extract embeds the dir as `📁 home kdabrow workspace <repo>`.
- Report kept / dropped counts.

## Ingest into OV

```bash
ov add-resource <backfill-dir> --to viking://resources/<slug>/sessions/<timestamp>-<filter-tag> --include "*.md" --wait --timeout 240
```

Use a date-tagged URI under `sessions/` so multiple backfills don't collide.

## Output

```
Backfill: <slug>
  filter: --days <N>  (or --search "<term>")
  extracted: <X> files
  kept (project-match): <K> files
  dropped (off-project): <X-K> files
  ingested: <K> files → viking://resources/<slug>/sessions/<timestamp>-<tag>
  embeddings: <E>
  output dir: <backfill-dir>   (markdown preserved for human review)
```

## Cleanup

Backfill markdown stays under `~/vault/<slug>/sessions/_backfill/` (human-readable, not git-tracked). If the user wants to remove a batch:

```bash
ov rm viking://resources/<slug>/sessions/<timestamp>-<tag>
rm -rf ~/vault/<slug>/sessions/_backfill/<timestamp>-<filter-tag>
```

Don't auto-delete.

## When NOT to use this

- For curated knowledge (ADRs, Serena memories, auto-memory): use `/v-sync` instead — those sources are higher signal.
- For broad time-windowed recall: targeted `--search` queries beat date-only filters. Date-only on busy projects pulls in tons of noise.
