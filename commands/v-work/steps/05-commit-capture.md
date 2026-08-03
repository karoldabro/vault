# Step 5 — COMMIT + CAPTURE

> **Writing to the user:** Read `~/.claude/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

Finalise: stage, commit, capture the session. This task stays `in_progress` until `/v-capture` has
actually run — never close out `/v-work` without it.

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

## 5.3 claude-mem

No action — claude-mem auto-captures via its SessionEnd hook. `mcp-search` is read-only.

## 5.4 Capture session (mandatory)

Honor any carried `pre_capture` hook, then invoke `/v-capture` to write the session log — it dedupes vs
recent sessions, updates indexes, extracts ADR candidates, cross-links Refs. This is part of the
lifecycle already approved at the gate; it needs no fresh prompt.

`/v-capture` also runs two gates this step depends on — make sure they actually fire:

- **Feature dossier gate** — for every feature this session touched, capture decides CREATE (new
  domain, no dossier), UPDATE (contracts/gotchas/coupling changed), or SKIP (no durable knowledge),
  and reconciles `_feature-index.md`. Don't let it silently no-op.
- **Indication scan** — if a reusable working rule / pattern / standard surfaced, capture offers to
  promote it to `indications/` (gated by `behaviour.capture_indications`). Confirm the candidates.

## 5.5 Completion report

The last thing the user reads. Governed by `_shared/communication.md` — report **what changed and
what still needs them**, not that the normal things were normal.

**Always print:**

```
Summary: [what was implemented — 1–2 sentences]
Files: [N created, N modified — list]
Branch: [name] @ [short commit hash]
Vault: [docs written/updated, session file path]
```

**Print only when there is something to say** — omit the line entirely otherwise:

```
Tests: [only when something FAILED or was skipped — never "all passing"]
Review: [only when there are warnings — never "PASS"]
Follow-up: [deferred items, open threads — omit when there are none]
```

A green test run and a clean review are the expected outcome; saying so costs the user attention and
buys nothing. A **failure, a skip, a warning, or a deferred item is an exception and is always
reported**, however brief. If the whole run was clean, the report is four lines.

After `/v-capture` completes, honor any carried `post_capture` hook, then the `on_end` hook (also fired
on early termination — gate rejection or abort). Mark COMMIT + CAPTURE `completed` — only after
`/v-capture` has run.
