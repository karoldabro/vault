# Step 0 — FEATURE PICKUP (only when `/v-team` is invoked with a `<feature>`)

Fires **only** when `/v-team` gets a feature argument (or the cwd's project vault has a
`features/<feature>` symlink into `_features/`). It connects this project session to the shared feature
workspace: pick up threads addressed here, surface replies, and check the contract hasn't drifted —
before ANALYZE. No feature → skip this step entirely (ordinary `/v-team` run).

## 0.1 Resolve the feature
- `<feature>` arg given → resolve `~/vault/_features/<feature>/`. **If it doesn't exist, warn loudly**
  ("no feature workspace `<feature>` — proceeding as a plain /v-team run") and skip Step 0. Do not
  silently find nothing.
- No arg → check the current project vault for a `features/<feature>` symlink; if present, use it.

Identify `<this>` — the current repo's vault slug.

## 0.2 Load the shared context
Read `generic-plan.md`, `contracts.md`, this project's `projects/<this>/plan.md` shard, and scan
`conversation/` filenames for open / answered threads.

## 0.3 Auto-pickup — threads addressed here
For each `*_OPEN_→<this>.md`: read it, **answer or act** on it (it's grounded in this project's code, so
resolve it as part of the session), then rename it `*_ANSWERED_<this>.md` with the reply appended. If
answering needs a decision above this project (a contract / generic-plan change), raise a
`*_OPEN_→pm.md` thread instead of guessing.

## 0.4 Surface replies to our questions
For each `*_ANSWERED_*.md` on a thread **this** project opened: surface the reply to the session (and the
user) so the answer lands where the question came from. Rename `…_RESOLVED.md` once consumed.

## 0.5 Deterministic contracts-drift check
Diff this project's **Consumed contract** (in its shard) against the structured `contracts.md` — a
mechanical field-by-field compare of the tables / typed blocks, **not** an LLM prose read. On a mismatch,
cite the exact drifted field and raise a `*_OPEN_→pm.md` thread (or `→<other>` if it's their side). Use
the LLM only to phrase the rationale, never to decide whether drift exists — that keeps false positives
cheap and false negatives rare. The broad prose consistency-pass is deliberately **not** done here.

## 0.6 New doubts during the session
Whenever this session hits a cross-project doubt mid-flight, **write a thread** instead of pinging the
user: `conversation/THREAD_<n>_OPEN_→<target>.md` from `templates/_features/THREAD.md` (`from: <this>`,
`to: <target>`, `asks: …`). Bump this project's session-open counter in `header.md`.

## Required output
```
Feature: <feature>  ·  This project: <this>
Picked up: [threads answered / acted]  ·  Replies surfaced: [answers to our questions]
Contract drift: [none | field X drifted → thread raised]
Raised: [new threads → target]
```
Then continue into Step 1 (ANALYZE) normally.
