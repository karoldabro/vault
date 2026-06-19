# v-cr forge adapters — interface contract

The thin contract every forge adapter implements. Per-forge mechanics (auth, exact endpoints, inline
shapes) live in `adapters/<platform>.md`, loaded **on demand** once step 1 picks the platform — so a run
only pays for the one forge in play. Task sources have a parallel contract in `tasks/<source>.md`.

## Operations (each adapter provides)

| Op | Used by | Contract |
|----|---------|----------|
| `resolve_pr` | step 1 | branch → `{number, base owner/repo, head, is_fork, is_public}` from the forge API (not the local tree) |
| `fetch_diff` | step 2 | PR → unified diff / patch |
| `fetch_meta` | step 2 | PR → `{title, body, base/head branch, linked_issues[]}` |
| `list_comments` | step 2/4 | PR → existing comments with `{id, author, body, is_bot, has_human_replies}` (for the suppression set + safe-resolve) |
| `post_summary` | step 4 | upsert the single sticky `<!-- v-cr:summary -->` comment |
| `post_inline` | step 4 | post an inline comment at `file:line` with the `<!-- v-cr:fp=… -->` marker |
| `resolve_thread` | step 4 | resolve (preferred) or delete a stale bot-only, zero-human-reply thread |

## Host → platform (lib/forge-detect.sh)
`forge_detect <url>` → `platform<TAB>host<TAB>owner/repo`. Public hosts are exact-match
(`github.com` / `bitbucket.org`); self-hosted via the **user/global** `VCR_HOST_MAP`
(`host=github|gitlab|bitbucket;…`), never read from repo files. Look-alikes resolve to `unknown`.

## Auth — least privilege, host-scoped (sec-3 / sec-7 / sec-8)
- Minimum scopes: **PR/MR read + comment, contents:read. No admin.** Warn if the detected token looks
  over-scoped.
- Tokens via env / stdin / `--netrc` — **never a CLI argument**, never a literal in these docs
  (placeholders only: `$GH_TOKEN`, `$BB_TOKEN`, `$JIRA_TOKEN`, `$ASANA_TOKEN`).
- A token is sent only to its allowlisted host (step 1 gate).

## Idempotency markers (all forges)
Inline: `<!-- v-cr:fp=<sha256(file:rule:code_hash)> -->` · Summary: `<!-- v-cr:summary -->`. HTML
comments are hidden in rendered Markdown on all three forges. Re-review skips posted fingerprints and
upserts the one summary. See `lib/cr-helpers.sh` (`cr_fingerprint`, `cr_code_hash`).

## v0 adapters
- `adapters/github.md` · `adapters/bitbucket-cloud.md` · `adapters/bitbucket-server.md`
- Task sources: `tasks/jira.md` · `tasks/asana.md` · `tasks/forge-issue.md`
- **GitLab** is deferred to v1; the contract is forge-agnostic, so `adapters/gitlab.md` (glab + REST
  discussions API with the `position{}` object) drops in without touching the steps.
