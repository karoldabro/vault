# Step 4 — EXECUTE

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

Implement the approved plan. The **code change is the primary goal**; vault docs are written
alongside it (secondary) so Refs stay accurate — but never let documentation crowd out the
engineering.

**Hooks:** honor carried `pre_execute` before implementing (fires **after** gate approval) /
`post_execute` after — loaded once at step 1 §1.4, never re-read `VAULT.md` (contract: vault-guide §1.1).

## 4.1 Branch

`/v-work` never creates branches. Work on the branch already checked out (captured in §2.8),
including `main`. Record `PROBE_BASE=$(git rev-parse HEAD)` before the first edit; §4.7 and §4.8 read it. If isolation is wanted the user branches manually. Do not run `git checkout -b`.

## 4.2 File editing rules

**`sed`, `awk`, `python`, and shell heredocs are never used for file content modification.**

| Operation | Tool | Never use |
|-----------|------|-----------|
| Targeted single-location change | `Edit` | `sed`, `awk`, `python -c` |
| Multiple changes in one file | `MultiEdit` | shell heredocs |
| Bulk pattern edits across files | `Edit` per location | python scripts |
| New file / complete rewrite | `Write` | `echo >`, `tee`, heredocs |
| Symbol rename (project-wide) | Serena `rename_symbol` when present, else `Edit` per call site | `sed -i` across files |
| Extract method / move function | Serena refactor tools when present, else `Edit` | manual copy-paste |

**Serena** for dependency-tracked renames / extract-method. Without Serena, find every call site with
Grep before the first `Edit`. Full rules: `$VAULT_FRAMEWORK_PATH/tool-playbook.md` §4.

## 4.3 Supporting tools

Framework/library docs → `WebFetch` the version-specific official docs rather than relying on training
guesses. Full reference: `$VAULT_FRAMEWORK_PATH/tool-playbook.md` §7.

## 4.4 Domain mindset

Backend: data integrity, validation at boundaries, consistent error handling, SOLID, follow existing
patterns. Frontend: WCAG accessibility, responsive, reusable components, proper state. Infra:
security-first, environment-aware, no hardcoded secrets.

## 4.5 Per unit of work

1. Make the code change with the right tool from §4.2.
2. Write tests per the Step-3 test plan (AAA; descriptive names; factories not hardcoded data;
   assert behaviour not internals; cover happy + edge + error).
3. Update/create the relevant vault doc and touch its index file(s) — secondary to the code.

Use `TaskCreate` sub-tasks per unit if work spans many files.

## 4.6 Tests after each phase

Run the detected test command (Step 1 / CLAUDE.md; Docker projects use the project's Docker test
aliases) against the changed surface. Fix root cause before proceeding. After all phases, run the
full suite and classify any failures as pre-existing vs newly introduced.

## 4.6a Static check before a unit is done

Before you call a unit of work done, run:

```bash
$VAULT_FRAMEWORK_PATH/bin/vault-check.sh static --repo . --base "$PROBE_BASE"
```

Fix every finding that names a file you changed, then run it once more. A unit is done once no output
line names a changed file, whatever the exit code: under `fallback scope repo` the repo's own linter
checks the whole repo, and findings in files you did not touch are recorded, not fixed. Findings still
open after the second run go to the operator. Exit 2 means nothing could be measured; say so to the
operator once per session, not once per unit. Output lines and exits: the `check` point in
`vault/architecture/plugin-extension-contract.md`.

## 4.7 Delegate verification

- After code lands, spawn `test-writer-fixer` once to write/repair and run tests for the changed
  surface. Every kept test passes the per-test gate of `commands/_shared/testing-loop.md` §2.
- Then run `$VAULT_FRAMEWORK_PATH/bin/vault-check.sh tests --repo . --base "$PROBE_BASE"` once.
  Coverage below the floor of `commands/_shared/testing-loop.md` §1, and every `survivor` line, go to
  the operator as open items, unlabelled. Print `coverage unmeasured: <reason>` whenever the output
  holds an `unmeasured coverage` line or the command exits 2. `/v-work` runs no further pass.
- Run `bin/probe-panel.sh run --posture own --repo . --base "$PROBE_BASE"` for every scope (rules:
  `commands/_shared/critic-panel.md` §(a) Probe stage) and print `operator.txt` to the operator when it exists.
- BIG scope (>15 files or API/schema changes): spawn `deploy-review-panel` once, a single pass, for
  architecture / code / test review before COMMIT, with the probe output in its prompt; run `cited` on each confirmed finding it returns.
- Spawn the domain specialists assigned in §3a.3 when their surface is the one being implemented.

## 4.8 Self-review

Check every changed file before marking complete.

**Code quality (all scopes):** the §4.6a static check owns size, structure and style; do not re-check by
eye what it measured. Check what no tool sees: one responsibility per class or module ·
`sed`/`awk`/`python` not used for edits · pattern compliance · **every `indications/` rule loaded in
§2.3a honored** · input validation at boundaries · an existing symbol or package reused instead of
rewritten · KISS/YAGNI (no premature abstraction). When §4.6a measured nothing (exit 2), also check by
eye for god classes, deep nesting, unused or dead code and copy-pasted blocks.

**Test quality:** happy + edge + error covered · no happy-path-only · no assertions on internals ·
no hardcoded test data · names describe scenario + outcome.

**Probes:** every `[confirmed]` row is fixed or answered in one line.

**Architecture (BIG scope):** breaking changes documented · no new circular deps · separation of
concerns maintained · migrations reversible, indexes on new FKs/query columns.

Issues → fix once and re-run the relevant checks → still failing → present to user. `/v-work` runs no review loop.

Before marking complete, honor any carried `post_execute` hook (surface + apply). Mark EXECUTE
`completed`.
