# Step 1 — ANALYZE

Restate the task and detect the project stack before any other work. No source reads, no code.

## 1.1 Restate the task

Write one sentence capturing exactly what was asked. This is the anchor for the whole session.

## 1.2 Extract keywords

Pull **3–6 keywords** from the restatement — they drive context load (Step 2) and dedupe (Step 3).
Examples: `api`, `auth`, `queue`, `migration`, `component`, `payment`, `notification`.

**Note any doubts as they surface.** If the task is ambiguous about direction, technology, or scope,
jot the open question now — don't resolve it by guessing. It gets loaded against context in Step 2 and
either answered from the vault or asked of the user at the PROPOSE clarify gate (§3a.0a).

## 1.3 Detect project stack

Check for marker files in the working directory so later steps know the test/build commands:

| Marker | Stack | Default test command |
|--------|-------|----------------------|
| `composer.json` (+ Laravel deps) | PHP/Laravel | `vendor/bin/phpunit` |
| `package.json` + `tsconfig.json` | TypeScript/Node | `npm test` / `npx jest` |
| `package.json` (react/vue/angular) | Frontend SPA | `npm test` / `npx vitest` |
| `pubspec.yaml` | Flutter/Dart | `flutter test` |
| `pyproject.toml` / `requirements.txt` | Python | `pytest` |
| none of the above | Static/Other | manual verification |

Also note: `docker-compose.yml`/`compose.yaml` (commands may need `docker compose exec`),
`package.json` `scripts` (project-specific `test`/`build`/`lint` override defaults), `.claude/`.
CLAUDE.md (read in Step 2) overrides all of these.

## 1.4 Resolve vault path + config

The whole lifecycle runs against a resolved vault — do this before Step 2 loads anything. Per
`vault-guide.md` §1.1:

1. **Framework path** — `$VAULT_FRAMEWORK_PATH` (default `~/workspace/vault`; override in
   `~/vault/_global/config.md` → `framework_path`). Templates, `vault-guide.md`, and
   `tool-playbook.md` resolve under it.
2. **Vault path** — first hit wins: `<repo-root>/VAULT.md` → `vault_path` (relative resolves against
   the repo root, so `./vault` is in-repo) → `~/vault/_global/config.md` → `~/vault/<slug>/`.
3. **Read `VAULT.md`** if present and load **all five sections** into a config you **carry through the
   whole run** — steps 2–6 do not re-read it: `config`, `structure` (extra/renamed/optional folders),
   `behaviour` (`load_context_extra`, `capture_indications`, `suggest_rename`), `hooks` (per-phase
   instructions), and `tools` (task-tracker guidance). Hook phases + precedence: `vault-guide.md` §1.1.

## 1.4b Fire `on_start` + `pre_analyze` hooks

Right after config resolution (§1.4) — i.e. after the restatement/keywords/stack of §§1.1–1.3, so the
restatement is available — if the carried `hooks` config defines `on_start` or `pre_analyze`, surface
each and treat it as a binding instruction now, before proceeding to LOAD CONTEXT — e.g. "this
repo tracks work in Jira; if the task names a ticket, fetch it via the Jira MCP first". A hook that
conflicts with `CLAUDE.md`/`indications` is overridden (surface the conflict); a hook needing a down MCP
falls back and is surfaced — never halt. See `vault-guide.md` §1.1.

## 1.5 Suggest session rename

After the restatement (§1.1), unless carried `behaviour.suggest_rename` is `false` (default: suggest),
compute a short kebab slug from the restatement and surface the exact command **for the user to run**:

```
Suggested session name — paste to apply:  /rename <slug>
```

The model **cannot** invoke `/rename` itself (built-in slash commands run only from user input), so this
is a one-paste manual action — present the line plainly, don't claim the rename happened. Both `/v-work`
and `/v-team` get this (v-team reuses this step verbatim). Skip silently if `suggest_rename: false`.

## Required output

```
Task: <one-sentence restatement>
Keywords: <kw1>, <kw2>, ...
Stack: <detected type + test command>
Docker: <yes | no>
Vault: <resolved vault path> (config: <VAULT.md applied | defaults>)
Hooks: <phases defined in VAULT.md — or "none">
Rename: /rename <slug>  (suggested — paste to apply)  | "skipped (suggest_rename: false)"
Scope: <code-only | vault-only | both>
```

Before marking complete, honor any carried `post_analyze` hook (surface + apply). Mark ANALYZE
`completed`.
