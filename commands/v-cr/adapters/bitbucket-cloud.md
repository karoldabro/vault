# Adapter — Bitbucket Cloud

API base: `https://api.bitbucket.org/2.0`. No first-party inline CLI → REST only. Auth: **API token**
(Basic auth, username = Atlassian email, password = `$BB_TOKEN`) — the replacement for the deprecated
app passwords; or a repo/workspace **access token** as `Authorization: Bearer $BB_TOKEN`. Scopes:
`pullrequest` (read) + `pullrequest:write` (comment). Never put the token on the CLI.

## resolve_pr
```
GET /repositories/{ws}/{repo}/pullrequests?q=source.branch.name="{branch}"&state=OPEN
```
Returns `{id, source.branch.name, destination.branch.name}`. Fork: `source.repository.uuid` !=
`destination.repository.uuid`. Public: `GET /repositories/{ws}/{repo}` → `is_private=false`.

## fetch_diff / fetch_meta
```
GET /repositories/{ws}/{repo}/pullrequests/{id}/diff
GET /repositories/{ws}/{repo}/pullrequests/{id}        # .description, .title, .source/.destination
```
Pagination: follow the `next` URL, `pagelen`.

## post_summary / post_inline
```
POST /repositories/{ws}/{repo}/pullrequests/{id}/comments
```
```json
{ "content": { "raw": "Possible null deref.\n<!-- v-cr:fp=<hash> -->" },
  "inline":  { "path": "src/app.py", "to": 42 } }
```
- `inline.to` = line in the **new** file (added/context); `inline.from` = line in the **old** file
  (removed). **Send only one of `from`/`to` per anchor.** `start_to`/`start_from` for ranges.
- Summary = a top-level comment (no `inline`), body carrying `<!-- v-cr:summary -->`.

## list_comments / suppression set
```
GET /repositories/{ws}/{repo}/pullrequests/{id}/comments
```
`is_bot` = `user.uuid`/`account_id` == the bot identity. `has_human_replies`: a child comment
(`parent.id`) by a non-bot. Markers in `content.raw`.

## resolve_thread (stale, safe only)
`PUT …/comments/{id}` with the resolution field, or delete. Resolve only bot-authored, zero-human-reply
threads; Bitbucket marks moved-line comments "outdated" automatically.

## --unpost
`GET …/comments` → for each carrying a `v-cr` marker and bot authorship,
`DELETE …/pullrequests/{id}/comments/{commentId}`.
