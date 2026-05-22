---
description: Re-ingest a project's curated knowledge (shared/, .serena/memories, auto-memory) into OpenViking. Run after committing new ADRs, updating memory files, or onboarding a sibling repo.
argument-hint: "[project-slug | 'all']"
---

Refresh OpenViking's index for a project after content changes. Drop-and-re-add by source, idempotent. Cheap (Ollama embeddings, local).

## Resolve scope

Argument `$ARGUMENTS`:

- **No argument** → resolve from `$PWD` against `~/vault/_global/coupled-groups.md`. If the current dir is inside a coupled group, sync the whole group.
- **A project slug** (e.g. `vivi`, `vivi/api`, `digitally-core`) → sync that one.
- **`all`** → sync every project listed in `~/vault/_global/coupled-groups.md`.

If you can't resolve a slug, stop and tell the user the known slugs.

## Discover sources per project

For each project slug, look for and ingest these source paths if they exist:

| Source | Target URI | Notes |
|---|---|---|
| `<repo>/shared/` (all `*.md`) | `viking://resources/<slug>/repository` | The `shared/decisions/`, `contracts/`, `migration/`, etc. content. |
| `<repo>/.serena/memories/` | `viking://resources/<slug>/serena` | Serena-curated memory files. Often the highest-signal source. |
| `~/.claude/projects/<encoded-repo-path>/memory/` | `viking://resources/<slug>/memory` | Claude-mem auto-memory observations. Encoded path: `/` → `-`, leading `-`. |
| `~/vault/<slug>/_moc.md` | `viking://resources/<slug>/moc` | Map-of-contents. |
| `~/vault/<slug>/decisions/` if NOT a symlink | `viking://resources/<slug>/decisions` | Only for vault-canonical projects (e.g. digitally-core). |
| `~/vault/<slug>/features/` if NOT a symlink | `viking://resources/<slug>/features` | Same. |

For coupled groups with sub-projects (e.g. vivi = api + admin + contracts), the parent slug's resources cover shared/. Each sub-project gets its own `.serena/memories` and auto-memory under e.g. `viking://resources/vivi/serena-api`, `viking://resources/vivi/memory-api`.

Resolve coupled-group members by reading `~/vault/_global/coupled-groups.md`.

## Drop-and-re-add per source

For each source to (re-)ingest:

```bash
ov rm <target-uri> 2>/dev/null  # ignore failures; URI may not exist
ov add-resource <source-path> --to <target-uri> --include "*.md" --wait --timeout 180
```

Skip a source silently if the path doesn't exist (e.g. repo has no `.serena/memories/` yet).

Track counts for the report.

## Output

```
Sync: <slug>
  shared/: <N> files → viking://resources/<slug>/repository
  serena: <N> files → viking://resources/<slug>/serena
  memory: <N> files → viking://resources/<slug>/memory
  moc: 1 file
  Total ingested: <T> files, <E> embeddings.
```

If multiple slugs in a group, print one block per slug + a "Group total" footer.

## Safety

- Never `ov rm viking://resources` (the root). Always operate on a specific sub-URI.
- Confirm OV server is up before starting: `curl -sf http://127.0.0.1:1933/health`. If not, stop and say "OV server not running — `systemctl --user start openviking.service`" — do not attempt to start it from this command.
- This command is for re-ingest of *current* state. For raw chat backfill see `/v-backfill`.
