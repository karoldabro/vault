# Shared module — what "done" means

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

Binding on every command that closes work: `/v-do`, `/v-work`, `/v-team`. Checked **before** anything
is staged or committed, never after — a check that runs past the commit blocks nothing.

Two tiers. The **baseline** applies to every session. The **feature extension** applies only when the
session is working a feature workspace and has a `## Sessions` row to close. A plain session is never
blocked by a line it has no source for.

## The rule that makes this worth having

A line is **met**, **failed**, or **not-applicable with a reason**. Those are the only three. There is
no fourth state, and silence is not a pass.

Ticking a line you cannot honestly assert is the failure this module exists to prevent. It has already
happened here: four sessions in one feature were recorded done against a code path that could never
run, because nothing asked for the evidence. `not-applicable (docs-only change, no runtime)` is a good
answer. A tick that is not true is not.

## Baseline — every session

| # | line | how it is met |
|---|---|---|
| B1 | The change does what the task asked | state it in one sentence; if scope was cut, say what was cut |
| B2 | Tests covering the changed behaviour pass | run them and quote the result; see "Tests" below |
| B3 | Lint and any format check pass on the changed files | run them; a pre-existing failure is named, not silently inherited |
| B4 | Every review finding is fixed or recorded | a finding you chose not to fix is written down with why — never dropped |
| B5 | Documentation and vault docs that the change invalidates are updated | name which, or `not-applicable` |
| B6 | Nothing unrelated is in the commit | `git diff --stat` matches the work item list |

### Tests (B2)

The per-test quality gate is owned by `v-team/steps/04-execute-loop.md` §5.2 and is not restated here.
One clause matters enough to quote, because dropping half of it makes the gate unsatisfiable in a repo
with no mutation tool:

> kills ≥1 seeded mutant — or, equivalently, a characterization check: temporarily break the code and
> confirm the test fails. (Coverage without fault-detection = tautological → reject.)

The characterization check is a full alternative, not a fallback of lesser standing. Use it wherever
mutation tooling does not exist.

**When the change has no runtime to exercise** — documentation, command specifications, configuration —
B2 is met by the closest real check the repo has: the linter, the file-contract tests, or an actual
invocation of the thing that was edited. Record which one. Do not mark B2 `met` on the strength of
having read the diff.

## Feature extension — only when a `## Sessions` row exists

| # | line | how it is met |
|---|---|---|
| F1 | Every `REQ-NN` this row claimed is covered | name the test or dossier entry covering each |
| F2 | The row's `status` is updated | one of `todo`, `doing`, `done`, `dropped` — no other value |
| F3 | The row carries evidence | a commit hash or session-record path; a `done` row without evidence is invalid |
| F4 | The row's `last touched` date is today | this is what makes a stale row visible as stale |
| F5 | Any deviation is written into the row | scope cut, work added, an item not built — the note is the point, not an apology |
| F6 | A `dropped` row says why | one line |

F5 is where the value is. A row that deviated and says so is a working tracker; a row that deviated
silently is how a plan and its work stop matching without anyone noticing.

## Reporting

Report only what is **failed** or **not-applicable**, plus anything cut or deferred. A baseline that
was fully met needs no line — saying every normal thing was normal costs the operator attention and
buys nothing. This follows `communication.md` "Report exceptions, not normality".

```
DoD: [B2 not-applicable — docs-only, met by doc-lint + bats instead]
     [B4 failed — one reviewer finding deferred: <what> · <why>]
```

If nothing failed and nothing was waived, print nothing.

## Where each command applies it

| command | applies | when |
|---|---|---|
| `/v-do` | baseline | in self-review, before the edit is committed |
| `/v-work` | baseline, plus the extension in feature mode | `steps/05-commit-capture.md` §5.0, before staging |
| `/v-team` | baseline, plus the extension in feature mode | same step, which it also reads |
| `/v-ask` | never | it writes nothing, so it closes nothing |
