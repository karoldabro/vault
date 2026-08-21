> **Framework root:** `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` whenever that reads as an absolute path (plugin install). Otherwise take it from the repo's `VAULT.md` `framework_path` key, then `~/vault/_global/config.md`, then the default `~/workspace/vault`.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

> **Writing a document:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/document-standard.md` first — it governs every file written here (one file one question, current truth only, no process inside a contract document; `bin/doc-lint.sh` enforces it).

# /v-reconcile — bring an existing document up to the standard

`/v-work` and `/v-team` write new documents to the standard. This rewrites the ones that already
exist: the 1,500-line plan, the 2,000-line brief, the feature dossier that grew a changelog.

**It understands before it edits.** A shortening pass that has not read the domain deletes
constraints it did not recognise. So this command loads context first, extracts the load-bearing set
second, and only then rewrites — with a machine check at the end proving nothing load-bearing left.

```
/v-reconcile <path>              one document
/v-reconcile <dir>               every document under it, worst first
/v-reconcile <path> --dry-run    report only, write nothing
```

**Never destructive.** Every rewrite is verified by `--compare` and gated on your approval. On a file
git does not track, the original is copied to `<name>.orig` before anything is written.

---

## On start: create task list

`TaskCreate`, one task per step. Mark `in_progress` when starting, `completed` when done.

1. SELECT
2. UNDERSTAND
3. EXTRACT
4. REWRITE
5. VERIFY
6. APPROVAL GATE
7. WRITE + CAPTURE

---

## Step 1 — SELECT

Resolve the vault (`vault-guide.md` §1.1). Then run the linter over the target and rank:

```bash
bin/doc-lint.sh <target>            # a directory: pass every *.md under it
```

Rank by how much a rewrite would return: line count over cap first, then finding count. Report the
list to the user as one line per file — path, lines, cap, the two worst findings. Nothing else.

**Skip and say so:** record-class documents (`session`, `research`, `trail`, `changelog`) — their
history is the payload; and any file the linter reports clean.

**One document per run by default.** A directory target processes them one at a time, each through
its own gate. Never batch-rewrite behind a single approval: a bad rewrite of ten files is ten
regressions you have to find by reading.

## Step 2 — UNDERSTAND

Read the document **and the domain it describes**, cheapest-first per `vault-guide.md` search
precedence. You are about to decide which sentences are load-bearing, and you cannot do that from
the file alone.

1. **Read the whole document.** Not a slice — a constraint buried at line 1,200 is exactly what gets
   lost.
2. **Vault:** `decisions/`, `indications/`, `features/` for the same slug and keywords. A rule this
   document states may be owned by an ADR, in which case the document should reference it, not
   restate it.
3. **Graph / code:** for every source path the document names, confirm the path still exists. A path
   that has moved is a finding for the user, not something to quietly drop.
4. **Sibling documents:** does a plan, trail or session already hold the history this file carries?
   If so, the history moves there rather than being deleted.

Write nothing yet. Produce, in working memory: what this document is for, who acts on it, which
class it belongs to, and which of its sections answer a different question from the rest.

## Step 3 — EXTRACT the load-bearing set

**Before any edit**, list what must survive. This list is the acceptance criterion for Step 5.

- every **prohibition** — never, must not, do not, cannot;
- every **requirement** and threshold, with its number and unit;
- every **exact file path, symbol, config key and command**;
- every **failure mode, rollback path and open blocker**;
- every **assumption stated as unverified**.

`bin/doc-lint.sh --compare` derives the mechanical half of this automatically in Step 5. Your list
covers what a regex cannot see: a constraint stated in prose, a warning phrased as a story.

**A `must not` you cannot map to a current rule is not deleted — it is surfaced.** "IPTC does not
work here and must not be attempted" saves a wasted session and belongs in the rewrite even when
nothing else from its paragraph survives.

## Step 4 — REWRITE

Apply `_shared/document-standard.md` — the edit pass, in order, as deletions:

1. **Split by class first.** Everything that is a record — revision log, critique trail, superseded
   approach, research diary, discovery story — moves to a sibling record file
   (`<slug>.trail.md`, from `templates/trail.md`), not to the bin. Link it from the contract
   document's frontmatter in one line. Splitting is the only step that must happen before the rest.
2. **Delete narrative, keep the table.** Prose that surrounds a work item goes; the item's file
   path, action, constraint and verification become a row. Where the document has no table, build
   one — this is usually where most of the length was.
3. **Collapse duplicated rules** to their most specific home, and reference from the rest. Where an
   ADR or indication already owns the rule, reference that instead and delete the local copy.
4. **Invert each surviving paragraph** — conclusion first, evidence after — then cut every reason
   longer than the rule it explains.
5. **Rewrite headings** so each states its own rule in words the reader already has.

Write to a **temporary path**, never over the original yet.

**Do not improve the content.** Reconciling is a format change. A constraint you believe is wrong is
reported at the gate, never silently corrected — the user decides whether the document is also
wrong.

## Step 5 — VERIFY

Both checks must pass before the gate. This is the step that makes shortening safe.

```bash
bin/doc-lint.sh <new>                      # the rewrite obeys the standard
bin/doc-lint.sh --compare <old> <new>      # nothing load-bearing was dropped
```

Then reconcile `--compare`'s output against your Step-3 list by hand. Every item it names is one of:

- **restored** — it belongs in the rewrite and you put it back;
- **moved** — it is in the record sidecar now; say which file;
- **deliberately cut** — you can name why in one line, and it goes to the gate as such.

**An item you cannot classify is a failure, not a judgement call.** Restore it and move on.

If `--compare` reports paths dropped that Step 2 found no longer exist, that is a **finding for the
user** — the document is stale, and stale is a content problem, not a formatting one.

## Step 6 — APPROVAL GATE

**STOP. Do not overwrite anything until the user approves.** Present, per
`_shared/communication.md`, at most 15 lines:

```
File: <path>  <old> lines → <new> lines
Moved to <slug>.trail.md: [what kind of content, one line]
Deliberately cut: [each with its one-line reason — omit the line if nothing was cut]
Restored after the check caught it: [only when the check caught something]
Stale: [paths the document names that no longer exist — always surfaced]
Ask: apply, show me the diff, or skip this file?
```

**Always surface**, however brief: anything deliberately cut, anything the `--compare` check caught,
any stale path, and any constraint you think is wrong. These are exceptions and are never trimmed to
fit the cap.

Approval → Step 7. "Show me the diff" → print it, then ask again. "Skip" → leave the file untouched
and move to the next.

## Step 7 — WRITE + CAPTURE

1. **Protect the original.** If git does not track the file, copy it to `<name>.orig` first. If git
   does, say so in one line — the diff is the backup.
2. Move the temporary file into place; write the record sidecar beside it.
3. Re-run `bin/doc-lint.sh` on the final path. A finding here means the write went wrong; fix it
   before reporting done.
4. For a directory target, return to Step 2 with the next file.
5. When the run ends, offer `/v-capture` — a reconcile that surfaced stale paths or wrong
   constraints has produced knowledge worth keeping.

---

## Required output

```
Reconciled: [path — old → new lines, one row each]
Sidecars written: [paths]
Stale references found: [path → what no longer exists]
Skipped: [file — why, only when you chose to skip]
```

A file that shortened without incident needs one row. Do not narrate the passes.

## Notes

- **Record documents are never reconciled.** A session log, a research doc and a trail exist to hold
  chronology. Shortening them destroys their only purpose.
- **The cap is a smell, not a target.** A 900-line requirements document that answers one question
  with one table is fine. Report it and move on rather than cutting to hit a number.
- **Reconciling is not migration.** It changes how a document is written, never what it decides. If
  the work described is obsolete, that is a `/v-work` task, not this one.
