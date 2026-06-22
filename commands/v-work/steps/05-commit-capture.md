# Step 5 — COMMIT + CAPTURE

Finalise: stage, commit, push to OpenViking, capture the session. This task stays `in_progress`
until `/v-capture` has actually run — never close out `/v-work` without it.

## 5.1 Code commit

Honor any carried `pre_commit` hook before staging.

```bash
git status
git diff --stat
```

Stage **specific files only** — never `git add -A` / `git add .` (avoids `.env`, credentials,
generated or unrelated files). Commit with a conventional message (`feat`/`fix`/`refactor`/`test`/
`docs`/`chore`, subject ≤50 chars, body only when the "why" isn't obvious). Do not auto-push.

After the commit lands (before `/v-capture`), honor any carried `post_commit` hook — e.g. "remind to
move the Jira ticket to In Review" (it never transitions anything itself; instruction-only). See
`vault-guide.md` §1.1.

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

Honor any carried `pre_capture` hook, then invoke `/v-capture` to write the session log — it dedupes vs
recent sessions, updates indexes, extracts ADR candidates, cross-links Refs. This is part of the
lifecycle already approved at the gate; it needs no fresh prompt.

`/v-capture` also runs two gates this step depends on — make sure they actually fire:

- **Feature dossier gate** — for every feature this session touched, capture decides CREATE (new
  domain, no dossier), UPDATE (contracts/gotchas/coupling changed), or SKIP (no durable knowledge),
  and reconciles `_feature-index.md`. Don't let it silently no-op.
- **Indication scan** — if a reusable working rule / pattern / standard surfaced, capture offers to
  promote it to `indications/` (gated by `behaviour.capture_indications`). Confirm the candidates.

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

After `/v-capture` completes, honor any carried `post_capture` hook, then the `on_end` hook (also fired
on early termination — gate rejection or abort). Mark COMMIT + CAPTURE `completed` — only after
`/v-capture` has run.
