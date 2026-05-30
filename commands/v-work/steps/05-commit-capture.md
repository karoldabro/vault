# Step 5 — COMMIT + CAPTURE

Finalise: stage, commit, push to OpenViking, capture the session. This task stays `in_progress`
until `/v-capture` has actually run — never close out `/v-work` without it.

## 5.1 Code commit

```bash
git status
git diff --stat
```

Stage **specific files only** — never `git add -A` / `git add .` (avoids `.env`, credentials,
generated or unrelated files). Commit with a conventional message (`feat`/`fix`/`refactor`/`test`/
`docs`/`chore`, subject ≤50 chars, body only when the "why" isn't obvious). Do not auto-push.

## 5.2 Vault commit (if applicable)

If `<project-vault>/` is a separate git repo:

```bash
cd <project-vault>
git add <touched files>
git commit -m "docs(vault): <what changed>"
```

## 5.3 Push to OpenViking

Probe `memory_health()` first. If unreachable, surface and skip — don't fail silently. Otherwise call
`memory_store(text=<summary + link to session file>, role="assistant")`. OV exposes only
`memory_store`, `memory_recall`, `memory_health`, `memory_forget` — there is no `add_episode`.

## 5.4 claude-mem

No action — claude-mem auto-captures via its SessionEnd hook. `mcp-search` is read-only.

## 5.5 Capture session (mandatory)

Invoke `/v-capture` to write the session log — it dedupes vs recent sessions, updates indexes,
extracts ADR candidates, cross-links Refs. This is part of the lifecycle already approved at the
gate; it needs no fresh prompt. If you learned any generic, reusable patterns, capture those too.

## 5.6 Completion report

```
Summary: [what was implemented — 1–2 sentences]
Files: [N created, N modified — list]
Tests: [N added — all passing / N failing]
Review: [PASS / PASS WITH WARNINGS — list warnings]
Vault: [docs written/updated, session file path]
Branch: [name] @ [short commit hash]
Follow-up: [deferred items, open threads]
```

Mark COMMIT + CAPTURE `completed` — only after `/v-capture` has run.
