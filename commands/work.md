---
description: Vault-aware development lifecycle. Loads context → proposes solution + vault writes (with dedupe) → approval → execute → commit + capture.
---

# /work — Vault-aware development lifecycle

Mirrors `/dev` but vault-first: every step considers what knowledge to load and what to write back. Self-contained — no dependencies on `~/.claude/shared-commands/`.

OV-optional throughout: every search has a grep fallback if OpenViking is down.

## On start: create task list

Use `TaskCreate` to add one task per step. Mark `in_progress` when starting, `completed` when done. The task list is the enforcement mechanism — do not skip a step.

Tasks:
1. ANALYZE
2. LOAD CONTEXT (vault-first)
3. PROPOSE
4. APPROVAL GATE
5. EXECUTE
6. COMMIT + CAPTURE

---

## Step 1 — ANALYZE

Restate the user's task in your own words. Extract **3–6 keywords** from the restatement — they drive context load and dedupe.

Output:
```
Task: <restatement>
Keywords: <kw1>, <kw2>, ...
Scope: <code-only | vault-only | both>
```

Mark ANALYZE `completed`.

---

## Step 2 — LOAD CONTEXT (vault-first)

Stop as soon as you have enough. Do not read source code in this step.

### 2.1 — Vault MOC + process guide

- Read `<project-vault>/_moc.md`.
- Read `<project-vault>/_process/vault-guide.md` if you haven't already this session (process rules).

### 2.2 — Semantic search (OV) OR grep fallback

```bash
curl -sf --max-time 1 http://127.0.0.1:1933/health
```

If OK → call `search_memory` MCP with the keywords. Read top 5 results.

If not OK → grep fallback:
```bash
for kw in <keywords>; do
  grep -ril "$kw" <project-vault>/{decisions,features,sessions,processes,architecture} 2>/dev/null
done | sort -u | head -10
```

Read the top 3 most relevant hits.

### 2.3 — Recent sessions + decisions

- Last 3 sessions by mtime: `ls -t <project-vault>/sessions/*.md | head -3`.
- ADRs touching the topic from §2.2.

### 2.4 — Code graph (if code change implied)

If `graphify-out/graph.json` exists in the project root:
- `graphify query "<question>"` for orientation. Don't grep yet.

### 2.5 — CLAUDE.md

Read project `CLAUDE.md` if present. Its instructions override defaults.

### Required output

```
MOC: [skimmed]
OV/grep: [N results, top hits listed]
Sessions: [top 3 mtime, brief topic each]
ADRs: [relevant IDs]
Graph: [used | not applicable | not present]
CLAUDE.md: [key overrides | none]
```

Mark LOAD CONTEXT `completed`.

---

## Step 3 — PROPOSE

Present the solution outline **and** the proposed vault writes. Run dedupe for every new vault file before listing it.

### Dedupe per proposed write

For each candidate vault file:
1. Extract slug + keywords.
2. Grep (same as 2.2 fallback). If OV available, also `search_memory`.
3. Compute overlap with existing docs. If `>60%` → mark `UPDATE existing` instead of `CREATE`.

### Output format

```
Code changes:
  - <file1>: <one-line change>
  - <file2>: ...

Vault writes:
  - CREATE features/<slug>.md (dedupe: 0 matches)
  - UPDATE decisions/ADR-042-<slug>.md (dedupe: 80% overlap — existing covers most of topic)
  - CREATE sessions/YYYY-MM-DD-HHMM-<slug>.md (always new per session)

Index updates:
  - _moc.md: link new feature
  - _feature-index.md: row for <slug>
  - decisions/_inventory.md: append ADR-NNN
```

Mark PROPOSE `completed`.

---

## Step 4 — APPROVAL GATE

**STOP.** Present the proposal. Do not proceed until the user explicitly approves.

- Approval ("looks good", "go", "yes", "approved") → Step 5
- Feedback → revise proposal, present again
- Rejection ("no", "cancel") → end; mark remaining tasks `deleted`

---

## Step 5 — EXECUTE

Implement code **and** vault docs in lockstep. Do not batch vault writes for the end — they go in as the work happens. This keeps Refs accurate and avoids forgetting.

For each unit of work:
1. Make the code change (or content change).
2. Update or create the relevant vault doc.
3. Touch the index file(s) listed in the proposal.

Use `TaskCreate` sub-tasks per unit if the work spans many files.

Mark EXECUTE `completed`.

---

## Step 6 — COMMIT + CAPTURE

### 6.1 — Code commit

If the project repo has uncommitted changes:
```bash
git status
git diff --stat
```

Stage and commit the code changes with a conventional commit message. Do not auto-push.

### 6.2 — Vault commit (if applicable)

If `<project-vault>/` is a separate git repo (most project vaults are), commit vault changes there too:
```bash
cd <project-vault>
git add <touched files>
git commit -m "docs(vault): <what changed>"
```

### 6.3 — Capture session

Invoke `/m-capture` to write the session log. It will dedupe vs recent sessions, update indexes, extract ADR candidates, and cross-link Refs.

Mark COMMIT + CAPTURE `completed`.

---

## Notes

- Never write source code in Step 2. The whole point of vault-first is to avoid premature source reads.
- If dedupe returns conflicting results (grep finds doc X, OV finds doc Y), read both. The vault may have parallel docs that need merging — flag it to the user.
- If `_process/vault-guide.md` is missing, the framework submodule is not initialized. Run `git submodule update --init` in the project vault.
