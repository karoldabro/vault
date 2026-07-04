# Step 4 — EXECUTE

Implement the approved plan. The **code change is the primary goal**; vault docs are written
alongside it (secondary) so Refs stay accurate — but never let documentation crowd out the
engineering.

**Hooks:** honor carried `pre_execute` before implementing (fires **after** gate approval) /
`post_execute` after — loaded once at step 1 §1.4, never re-read `VAULT.md` (contract: vault-guide §1.1).

## 4.1 Branch

`/v-work` never creates branches. Work on the branch already checked out (captured in §2.8),
including `main`. If isolation is wanted the user branches manually. Do not run `git checkout -b`.

## 4.2 File editing rules

**`sed`, `awk`, `python`, and shell heredocs are never used for file content modification.**

| Operation | Tool | Never use |
|-----------|------|-----------|
| Targeted single-location change | `Edit` | `sed`, `awk`, `python -c` |
| Multiple changes in one file | `MultiEdit` | shell heredocs |
| Bulk pattern edits across files | `MorphLLM morph_edit` | python scripts |
| New file / complete rewrite | `Write` | `echo >`, `tee`, heredocs |
| Symbol rename (project-wide) | Serena `rename_symbol` | `sed -i` across files |
| Extract method / move function | Serena refactor tools | manual copy-paste |

**MorphLLM** for multi-file edits, framework updates, style enforcement, mass replacements:
`morph_edit(target_filepath, instructions, code_edit)` — **always include `// ... existing code ...`
markers at both ends** of `code_edit` (omitting them deletes the rest of the file). **Serena** for
dependency-tracked renames / extract-method. **Best combo:** Serena finds the semantic context →
Morph applies the precise edit. Full rules + worked example: `$VAULT_FRAMEWORK_PATH/tool-playbook.md` §5.

## 4.3 Supporting tools

Framework/library docs → `Context7` (version-specific, not training guesses). 3+ interconnected
components / root-cause analysis → `Sequential`. UI component → `Magic`. Browser E2E (login, forms,
journeys) → `Playwright`. Full reference: `$VAULT_FRAMEWORK_PATH/tool-playbook.md`.

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

## 4.7 Delegate verification

- After code lands, spawn `test-writer-fixer` to write/repair and run tests for the changed surface.
- BIG scope (>15 files or API/schema changes): spawn `deploy-review-panel` for architecture / code /
  test review before COMMIT.
- Spawn the domain specialists assigned in §3a.3 when their surface is the one being implemented.

## 4.8 Self-review

Check every changed file before marking complete.

**Code quality (all scopes):** no god classes (>200 lines / >5 responsibilities) · no deep nesting
(>3 levels) · no magic numbers/strings · no unused imports / dead / commented-out code ·
`sed`/`awk`/`python` not used for edits · pattern compliance · **every `indications/` rule loaded in
§2.3a honored** · input validation at boundaries · no copy-pasted logic (extract shared) · KISS/YAGNI
(no premature abstraction).

**Test quality:** happy + edge + error covered · no happy-path-only · no assertions on internals ·
no hardcoded test data · names describe scenario + outcome.

**Architecture (BIG scope):** breaking changes documented · no new circular deps · separation of
concerns maintained · migrations reversible, indexes on new FKs/query columns.

Review loop: issues → fix, re-run relevant checks (max 3 iterations) → still failing → present to user.

Before marking complete, honor any carried `post_execute` hook (surface + apply). Mark EXECUTE
`completed`.
