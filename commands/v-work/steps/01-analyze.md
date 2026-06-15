# Step 1 — ANALYZE

Restate the task and detect the project stack before any other work. No source reads, no code.

## 1.1 Restate the task

Write one sentence capturing exactly what was asked. This is the anchor for the whole session.

## 1.2 Extract keywords

Pull **3–6 keywords** from the restatement — they drive context load (Step 2) and dedupe (Step 3).
Examples: `api`, `auth`, `queue`, `migration`, `component`, `payment`, `notification`.

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
3. **Read `VAULT.md`** if present and apply its `structure` (extra/renamed/optional folders) and
   `behaviour` (`load_context_extra`, `capture_indications`) keys. Carry them through the run.

## Required output

```
Task: <one-sentence restatement>
Keywords: <kw1>, <kw2>, ...
Stack: <detected type + test command>
Docker: <yes | no>
Vault: <resolved vault path> (config: <VAULT.md applied | defaults>)
Scope: <code-only | vault-only | both>
```

Mark ANALYZE `completed`.
