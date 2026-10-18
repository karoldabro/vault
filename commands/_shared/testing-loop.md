# Shared module — the testing loop

> Path note: `$VAULT_FRAMEWORK_PATH` is `${CLAUDE_PLUGIN_ROOT}` when that reads as an absolute path (plugin install), otherwise resolved per `vault-guide.md` §1.1.

Binding on `/v-team` EXECUTE §5.3 (`commands/v-team/steps/04-execute-loop.md`), which runs the whole
loop, and on `/v-work` EXECUTE §4.7 (`commands/v-work/steps/04-execute.md`), which reads only
§1 The floor and §2 The per-test gate and runs one pass. The tools come from `bin/vault-check.sh tests`;
its contract is the `check` point in `vault/architecture/plugin-extension-contract.md`.

## 1. The floor

Changed-line coverage must be at least **max(80, floor)**, where `floor` is the plugin's own configured
floor. `bin/vault-check.sh` is the only judge: it exits 1 below that line and prints
`floor-below <floor> 80` when a plugin sets less than 80. `coverage none` (no coverable changed lines)
meets the floor. No session restates or loosens the number.

There is no fixed mutation score. Every surviving mutant on the diff is either killed by a new or
stronger test, or labelled `equivalent: <reason>` because no test can observe it.

## 2. The per-test gate

Every test a writer keeps passes all four before it counts:

1. it builds or compiles;
2. it runs green 3 times in a row, which catches order-dependent flakiness;
3. it strictly increases coverage of the behaviour it targets;
4. it kills ≥1 seeded mutant — or, equivalently, a characterization check: temporarily break the code
   and confirm the test fails. Coverage without fault-detection is tautological, so reject the test.

A writer never weakens an assertion to make a test pass. A test that fails against correct-looking
code is a finding for the execution loop (§4), not a test to loosen.

## 3. Seats

| seat | who | edits | runs |
|---|---|---|---|
| writer | `test-writer-fixer`, one per group of Test-backlog rows sharing a target file | test files only | the per-test gate |
| tools | `bin/vault-check.sh tests --repo . --base "$PROBE_BASE"` | nothing | tests, coverage, mutation |
| reviewers | the testing critic group (`personas/_shared/testing/`), selected per `personas/_resolution.md` §2.1 | nothing | their bound analyzers on the written tests |

Writers are capped by `team_max_test_writers` in `VAULT.md` (default 2, hard max 3). Groups beyond the cap
queue for the next round. A writer never labels its own survivors; reviewers do.

## 4. Ownership — tests only

A writer edits **test files only**. After each writer finishes, run
`git diff --name-only` on its change. Any path outside the repo's test directories goes back: revert it
and hand the reason to the execution loop.

When a new test exposes a production bug, the writer stops on that test and returns the bug to the
execution loop with the failing test as evidence. The implementer fixes the production code; that fix
then gets one code-review round (`04-execute-loop.md` §5.2). At most 1 return per testing round and 3
per run, and these review rounds count against neither `team_max_review_rounds` nor
`team_max_test_rounds`. Past the cap, the bug goes to the operator.

## 5. One round

1. **Write.** Writers take the Test backlog rows still open and stamp each row's `disposition` in the
   plan (`implement`, `change` + what changed, or `skip` + why), in the row itself. Each kept test passes
   §2.
2. **Measure.** Run `bin/vault-check.sh tests --repo . --base "$PROBE_BASE"` once.
3. **Review.** Spawn the selected reviewers in parallel, read-only, with the diff of the test files, the
   `vault-check` output and the Test design dossier. They confirm the dossier against real code (routing:
   `personas/_shared/testing/design/README.md`), and label each `survivor` line: `missing-test`,
   `weak-test` or `equivalent: <reason>`. Findings follow `commands/_shared/critic-panel.md` §(d).
4. **Act.** The next round's writers take every `missing-test`, `weak-test`, uncovered changed line
   and confirmed reviewer finding.

## 6. Stop rules

Stop on the first that holds:

- coverage meets §1 and every survivor is killed or labelled `equivalent`;
- coverage and mutation are `unmeasured`, `test_command` exited 0, and every kept test passed §2 —
  this stops after round 1;
- `bin/vault-check.sh tests` exited 2 — stop at once, since no test can be measured;
- `team_max_test_rounds` (default 3) is reached. The open items — survivors still labelled
  `missing-test` or `weak-test`, uncovered lines, unconfirmed dossier rows — go to the operator.

Unanimous reviewer approval alone never stops the loop.

## 7. What the operator sees

Only exceptions, in plain words, per `commands/_shared/communication.md`:

```
Tests: [failing tests by name — only when something failed]
Coverage: [<pct>% of changed lines, below the <n>% floor — only when below]
coverage unmeasured: <reason>      # always, whenever the tools could not measure coverage
Untestable: [each `equivalent` label verbatim, with its file:line]
Still open: [what the round cap left, e.g. "2 surviving mutants still need a test"]
```

A run that met the floor with no survivors prints none of these lines.
