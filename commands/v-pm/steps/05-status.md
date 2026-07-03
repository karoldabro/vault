# status mode — `/v-pm status`

The cross-feature inbox. One sweep so nothing orphans. **No writes.**

## S.1 Sweep
For every `~/vault/_features/*/` (skip `_done/`), scan `conversation/` filenames — state is encoded in
the name, so no file needs opening for status:
- `*_OPEN_→<proj>.md` — a question waiting on project `<proj>`.
- `*_OPEN_→pm.md` — a decision waiting on you (`/v-pm reconcile <feature>`).
- `*_ANSWERED_<answerer>.md` — a reply the asking side may not have seen yet.

## S.2 Compute staleness
Age each OPEN thread by the participant's session-open counter in `header.md` (fall back to file mtime).

## S.3 Print one digest
```
FEATURE            WAITING ON   THREAD                                AGE
saved-filters      api          frontend: pagination fields missing   2 opens
saved-filters      pm           contract: enum values?                1 open
team-billing       frontend     api answered: proration rule          — (reply ready)
```
Group by feature; lead with `→pm` (your action) and stale `→<proj>` (needs you to open that session).
If empty: "No open threads across N features." This is the human-out-of-the-bus surface — run it
whenever you want to know what's blocked without opening every session.
