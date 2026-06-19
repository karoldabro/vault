# Adapter — GitHub (Cloud + Enterprise Server)

API base: Cloud `https://api.github.com`; GHE Server `https://<host>/api/v3`. Auth: `gh` injects its own
token; for raw REST use a fine-grained PAT with **Pull requests: Read+Write** + **Contents: Read** (or
classic `repo`). Token via `gh auth token` / `$GH_TOKEN` env — never on the CLI.

## resolve_pr
```bash
gh pr view --json number,title,baseRefName,headRefName,headRepositoryOwner,isCrossRepository
# isCrossRepository=true → fork PR (is_fork). Repo visibility:
gh repo view --json visibility    # PUBLIC → is_public
```
REST fallback: `GET /repos/{o}/{r}/pulls?head={o}:{branch}&state=open`.

## fetch_diff / fetch_meta
```bash
gh pr diff <n> --patch
gh pr view <n> --json body,closingIssuesReferences   # closingIssuesReferences = linked issues
```
REST: `GET /repos/{o}/{r}/pulls/{n}` with `Accept: application/vnd.github.diff`.

## post_summary / post_inline
`gh pr review` posts a review body but **not** inline comments — use the reviews endpoint for inline:
```bash
gh api --method POST /repos/{o}/{r}/pulls/{n}/reviews --input review.json
```
`review.json`:
```json
{
  "commit_id": "<head sha>",
  "event": "COMMENT",
  "body": "## v-cr review\n…\n<!-- v-cr:summary -->",
  "comments": [
    { "path": "src/app.ts", "line": 42, "side": "RIGHT",
      "body": "Possible null deref.\n<!-- v-cr:fp=<hash> -->" }
  ]
}
```
- `event: COMMENT` → never APPROVE/REQUEST_CHANGES (non-blocking, comment-only — the invariant).
- Multi-line: `start_line` + `start_side` (range start), `line` + `side` (end). `position` is legacy —
  use `line`.

## list_comments / suppression set
```bash
gh api /repos/{o}/{r}/pulls/{n}/comments --paginate    # inline review comments (carry markers)
gh api /repos/{o}/{r}/issues/{n}/comments --paginate   # the summary lives here
```
`is_bot` = author login == the configured bot identity. `has_human_replies`: a non-bot comment
`in_reply_to_id` the bot thread.

## resolve_thread (stale, safe only)
REST has no resolve; use GraphQL `resolveReviewThread(threadId)`. Resolve only bot-authored, zero-human-
reply threads. Outdated threads auto-collapse when lines move (`isOutdated`).

## --unpost
List bot comments, `DELETE /repos/{o}/{r}/pulls/comments/{id}` (inline) +
`PATCH …/issues/comments/{id}` to clear the summary, for those carrying `<!-- v-cr:fp= -->` /
`<!-- v-cr:summary -->`.
