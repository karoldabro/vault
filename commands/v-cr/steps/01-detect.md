# Step 1 — DETECT

Resolve **which forge**, **which repo**, and **which PR/MR** to review — and decide whether the host is
trusted enough to send credentials to. No code reads, no model context yet.

Pure parsing lives in `lib/forge-detect.sh` (sourced; offline-tested) — this step is the policy around it.

## 1.1 Resolve the remote URL
```bash
source "$VAULT_FRAMEWORK_PATH/lib/forge-detect.sh"
remote="$(git config --get "branch.$(git branch --show-current).remote" 2>/dev/null || echo origin)"
url="$(git ls-remote --get-url "$remote")"   # expands url.<base>.insteadOf rewrites
```
If `git branch --show-current` is empty (detached HEAD) or there is no PR yet, stop and ask the user for
an explicit `/v-cr <url|number>`.

## 1.2 Parse + map (with SSH-alias resolution)
```bash
read -r host path <<<"$(forge_parse_url "$url" | tr '\t' ' ')"
```
If the parsed `host` maps to `unknown` (`forge_platform`), it may be a `~/.ssh/config` Host alias
(common for multi-account setups). Resolve the real hostname before giving up:
```bash
real="$(ssh -G "$host" 2>/dev/null | awk '/^hostname /{print $2; exit}')"
```
Re-map with `real`. Honour an explicit `/v-cr <url>` override at any point — it is the escape hatch and
must be named in any failure message.

## 1.3 Host trust gate (SSRF / credential-harvest defense — sec-3)
Before any credentialed call:
- **Exact-match allowlist only.** `github.com`, `bitbucket.org`, and `bitbucket.<host>` self-hosted
  entries come from `forge_platform` (which matches exactly — a look-alike like `github.com.evil.test`
  resolves to `unknown`, not GitHub). Reject `forge_validate_host` failures (IP-literals, empty).
- **Self-hosted hosts** (resolved only via the **user/global** `VCR_HOST_MAP`, never repo-controlled
  files) require explicit one-time user confirmation before first use. Show the host and ask.
- Reject non-TLS (`http://`) hosts for credentialed calls.
- A token is bound to its host: never send a GitHub/Bitbucket/Jira/Asana credential to any host not on
  the allowlist for that service.

## 1.4 Resolve the PR/MR — from the forge, not the local tree (arch-2 / skeptic-6)
The local checkout may be a stale branch, a shallow clone, or a different repo than the PR (esp. fork
PRs where head owner ≠ base). Resolve PR identity from the forge API:

| Platform | CLI fast path | REST fallback |
|----------|---------------|---------------|
| github | `gh pr view --json number,headRefName,headRepositoryOwner,isCrossRepository,baseRefName` | `GET /repos/{o}/{r}/pulls?head={o}:{branch}&state=open` |
| bitbucket-cloud | — | `GET /repositories/{ws}/{repo}/pullrequests?q=source.branch.name="{b}"&state=OPEN` |
| bitbucket-server | — | `GET /rest/.../pull-requests?at=refs/heads/{b}&direction=OUTGOING&state=OPEN` |

(Adapter specifics: `commands/v-cr/adapters/<platform>.md`.)

## 1.5 Record the resolved target
Emit and carry forward:
```
Adapter:   github | bitbucket-cloud | bitbucket-server
Target:    <host>/<owner>/<repo>#<PR>        # the string echoed at the POST gate
Base repo: <owner>/<repo>                     # vault/pack resolution key (step 2)
Fork/public: <yes|no>                         # drives the egress policy (steps 3–4)
Local match: <local HEAD == PR repo/branch? yes|no>   # gates local-only context (step 2)
```

## 1.6 Resolve the fetchable ref — only under `--sandbox`
The isolated-execution path (`commands/v-cr/sandbox.md`) needs a **fetchable git ref** for the PR head.
Resolve it through the adapter `fetch_ref` op (forge-agnostic; see `adapters.md`), never hard-coded here:
- **GitHub** → `refs/pull/<n>/head` (guaranteed, incl. fork heads).
- **Bitbucket Cloud/Server** → capability-probed (`git ls-remote`); PR refs are admin-gated and a fork is
  a separate repo, so the op may return **`unsupported`**.

If `fetch_ref` returns `unsupported` (or the host trust gate would forbid the fetch), **refuse
`--sandbox`, fall back to API-only review, and state the reason** — never materialize/run a tree that is
not provably the PR's. (Without `--sandbox`, skip this section entirely.)

## Required output
```
Forge: <adapter> @ <host>  (trust: allowlisted | self-hosted-confirmed | REJECTED)
PR/MR: #<n> "<title>"  ·  base <owner>/<repo>  ·  fork/public: <y/n>  ·  local-match: <y/n>
Sandbox: <off | on — fetch ref <ref> | on-requested → DOWNGRADED to API-only: <reason>>
```
If trust is REJECTED or no PR resolves, **stop** with a clear message naming the `/v-cr <url>` override.
Mark DETECT `completed`.
