# Step 2 — GATHER CONTEXT

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

> **Writing to the user:** Read `$VAULT_FRAMEWORK_PATH/commands/_shared/communication.md` first — it governs every user-facing line produced here (answer first, no jargon, options carry their consequences, report exceptions not normality).

Assemble everything the panel reviews against: the diff (secret-scanned), the linked task, the project's
vault knowledge, and the set of comments already posted. This is the "context-aware" requirement.

## 2.1 Fetch the changeset + PR metadata
Via the resolved adapter (`commands/v-cr/adapters/<platform>.md`):
- the **diff / patch**;
- PR/MR **title**, **body/description**, **head/base branch**, **linked issues**
  (`closingIssuesReferences` / `closes_issues` / native links).

## 2.2 Secret-scan the diff AND every comment body BEFORE they enter any model context (sec-2)
Run a secret scan (gitleaks/trufflehog rules if present; always the token-shape regex fallback:
`gh[pousr]_`, `glpat-`, `Bearer `, `ATATT`, `xox[abpr]-`, AWS `AKIA…`). Replace matches with redaction
placeholders in the copy that will be sent to critics and **warn the user** that the diff contains
apparent secrets (that itself is a finding worth a comment). The raw secret never enters a prompt, a
comment, or the captured session.

**The same scan runs over every PR/MR comment body fetched in §2.5**, with no second implementation.
People paste tokens into review threads, and a comment body now reaches both a critic prompt and — via
§5.3's learning loop — a git-tracked vault file. An unscanned comment is the shortest path from a
pasted token to a committed one.

## 2.3 Extract + fetch the linked task (skeptic-4)
```bash
source "$VAULT_FRAMEWORK_PATH/lib/cr-helpers.sh"
ctx="$(printf '%s\n%s\n' "$BRANCH" "$PR_TITLE")"   # branch + title ONLY — never body/diff for Jira keys
keys="$(cr_jira_keys "$ctx")"                       # gated by VCR_JIRA_PROJECTS allowlist
asana="$(cr_asana_gids "$PR_BODY")"                 # explicit URLs, so body is allowed
```
- **Jira** keys are emitted only when their project prefix is in `VCR_JIRA_PROJECTS` — this is what stops
  `UTF-8` / `SHA-256` / `RELEASE-2` linking the wrong ticket. Fetch via `commands/v-cr/tasks/jira.md`
  (base URL from user/global config only). A 404 / archived issue = "no task context", not an error.
- **Asana** task GIDs → fetch via `commands/v-cr/tasks/asana.md` (Asana MCP).
- **Native forge issues** (`#\d+` in branch/title) → fetch via `commands/v-cr/tasks/forge-issue.md`;
  validate by the fetch (a 404 means it was a false positive like `#404`, drop it).

The fetched task becomes the **acceptance criteria** the panel checks the diff against ("does this change
do what the ticket asked?").

## 2.4 Load the reviewed repo's vault — by base-repo slug (skeptic-6)
Resolve the vault for the **base repo** (`<owner>/<repo>` from step 1), not by assuming cwd is the repo.
Reuse the v-work context loader's **vault-only layer**: claude-mem `search` + `~/vault/<slug>/`
decisions (ADRs), indications, and the feature dossier for the touched area. These give the panel the
project's rules and conventions to check the diff against.

### The indication retrieval rule (mandatory, in this order)
Naming `indications` without saying how many or which leaves every run to invent its own subsetting and
record none of it — one project's rule set is 225 files and ~111k tokens, several times the whole review
budget, so a run cannot have loaded them all and cannot say what it did load.

1. **Read `indications/_index.md` only.** Never read rule bodies to decide relevance.
2. **Filter rows by `scope`** — only when the index has a `scope` column. Keep the reviewed surface
   plus `cross-repo`; the surface is the base repo resolved in step 1, and the project's valid values
   are its `VAULT.md` `indication_scopes`. A row naming another surface **cannot** apply — a mobile
   rule against an API diff is a wrong finding, not a noisy one.
   **Most indexes have no `scope` column** (a single-surface project does not need one). There, load
   every row and say `scope filter: n/a (single-surface index)`. Never skip the load for want of a
   column — an unrouted index is smaller than a routed one, not more dangerous.
3. **Fetch a full rule body only on demand, by slug**, when a critic is about to cite that rule.
4. **Record both counts** — rows loaded after the filter, bodies fetched — in the step output and in
   the capture block (`05-capture.md` §5.1).

If the index file itself is missing, say so and fall back to reading rule bodies directly, capped at
the token budget and with the count recorded. An unrecorded partial load is what this rule prevents;
loading nothing is not the safe default, it is a silent hole in the review.

**Local-only layers run only if `Local match: yes` from step 1** (local HEAD == the PR's repo/branch):
graphify `graph.json`, Serena symbols, the project `CLAUDE.md`. Otherwise **skip them and say so** — do
not load a different checkout's structure and pass it off as the PR's.

**If no persona pack resolves** for the base repo, FAIL LOUDLY now: tell the user the review will run the
generic fallback (single lens), not the project panel. Never silently degrade.

## 2.5 Fetch the existing-comment suppression set (arch-6)
List the PR's existing comments via the adapter; collect every `<!-- v-cr:fp=… -->` fingerprint already
posted. Carry this set into step 3 so the panel **suppresses findings already raised** rather than
re-deriving and re-posting them. Note which bot threads have **human replies** (step 4 must not resolve
those).

## 2.6 Provision + test gate — only under `--sandbox` (delegated)
When `--sandbox` is on and step 1 resolved a fetch ref, **invoke `commands/v-cr/sandbox.md`** here — this
step does NOT itself clone, build, or run code; it delegates and carries back the result. The contract
provisions the throwaway clone + locked-down sandbox (S0–S4), runs the **attribution-aware test gate**
(S5), and assembles the **dynamic-evidence bundle** (S6 — static analyzers, diff-coverage, test results,
runtime reproduction), all `cr_redact_runtime`-scrubbed and fenced as untrusted data. Teardown is armed
at provision (S7), so it fires even if a later step throws.

Carry forward to step 3:
- the **dynamic-evidence bundle** (becomes the panel's `confirmed` analyzer input — see
  `_shared/critic-panel.md` Inputs);
- the **test-gate verdict**: `pass` · `new-failure (blocking → skip deep panel)` · `red-unattributed
  (advisory)` · `could-not-provision (infra, NOT a code finding)`.
Because the real PR tree is now materialized, the local-only layers (graph/Serena) MAY run against the
clone even when step-1 `local-match` was no — note that they ran against the sandbox clone.

## Required output
```
Diff: <n files, +a/-b, c changed lines>  ·  secrets: <none | N redacted (warned)>
Task: <JIRA-KEY / asana:GID / #N "summary"> | none
Vault: <pack resolved | GENERIC FALLBACK>  ·  layers: [vault-only | + graph/serena/CLAUDE.md]
Rules: <r> index rows (<scope <surface>+cross-repo | scope filter: n/a>)  ·  <b> bodies fetched
Suppression set: <n prior v-cr fingerprints>  (<m> threads have human replies)
Sandbox: <off | recipe <source> · test-gate <pass|new-failure|red-unattributed|could-not-provision> · evidence [analyzers/coverage/repro]>
```
Mark GATHER CONTEXT `completed`.
