# Adapter — Bitbucket Server / Data Center

API base: `https://<host>/rest/api/1.0`. Distinct from Cloud — different base, path (`pull-requests`
with a hyphen), inline model (`anchor`), text field (`text`), and pagination. Detected via the `/scm/`
clone-path hint (lib/forge-detect.sh). Auth: HTTP access token as `Authorization: Bearer $BB_TOKEN`
(project/repo tokens are Bearer-only). Scope: PR read + write (REPO_WRITE on the repo). Never on the CLI.

## resolve_pr
```
GET /rest/api/1.0/projects/{proj}/repos/{repo}/pull-requests?at=refs/heads/{branch}&direction=OUTGOING&state=OPEN
```
`direction` defaults to `INCOMING` — you **must** pass `OUTGOING` to find the PR whose *source* is this
branch, and `at` must be the fully-qualified ref `refs/heads/<branch>`. Fork: `fromRef.repository.id` !=
`toRef.repository.id`.

## fetch_diff / fetch_meta
```
GET …/pull-requests/{id}/diff
GET …/pull-requests/{id}              # .description, .title, .fromRef/.toRef
```
Pagination: `start`/`limit`, follow `nextPageStart` until `isLastPage`.

## post_summary / post_inline
```
POST …/pull-requests/{id}/comments
```
```json
{ "text": "Possible null deref.\n<!-- v-cr:fp=<hash> -->",
  "anchor": { "diffType": "EFFECTIVE", "line": 42, "lineType": "ADDED",
              "fileType": "TO", "path": "src/app.java" } }
```
- `lineType` = `ADDED` / `REMOVED` / `CONTEXT`; `fileType` = `TO` (new) / `FROM` (old) — pair
  `ADDED`+`TO`, `REMOVED`+`FROM`. `diffType: EFFECTIVE` is simplest for PR review. `srcPath` only for
  moves.
- Summary = a comment with **no `anchor`**, `text` carrying `<!-- v-cr:summary -->`.

## list_comments / suppression set
```
GET …/pull-requests/{id}/activities    # comment activities; filter to comment-add
```
`is_bot` = `comment.author.name` == bot. `has_human_replies`: `comment.comments[]` contains a non-bot.

## resolve_thread (stale, safe only)
`PUT …/comments/{id}` with `{ "state": "RESOLVED", "version": <v> }` (optimistic-lock `version`
required), or delete with the `version` query param. Bot-authored, zero-human-reply only.

## --unpost
`GET …/activities` → for each bot comment carrying a `v-cr` marker, `DELETE …/comments/{id}?version=<v>`.
