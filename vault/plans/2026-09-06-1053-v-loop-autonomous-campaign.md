---
type: plan
project: vault
slug: 2026-09-06-1053-v-loop-autonomous-campaign
repos: [vault]
status: proposed
process_record: 2026-09-06-1053-v-loop-autonomous-campaign.trail.md
session:
tags: [plan, command, autonomous, qa, campaign]
---

# 2026-09-06-1053-v-loop-autonomous-campaign — plan

## Task
Add `/v-loop` to the vault framework: an autonomous test-and-fix campaign command that verifies and
repairs a feature already built and running against a stack the operator has named as disposable.
It carries the rules two campaigns on different stacks converged on, and repairs the staging guard
those campaigns depend on. Keywords: campaign, case, verdict, injection, ledger, defect, falsify,
conflict scope, disposable stack, resume, retest.

## Open & deferred

- **needs the operator**: SC-6 is decided by observation and is the one criterion still open. Invoke
  `/v-loop` in this repo and confirm it refuses for want of a disposable stack, creating no
  `campaigns/` directory.
- **deviation from W-6**: `commands/v-loop/campaign-rules.md` is 161 lines against a stated 150. The
  twelve safety rules and the shared-module deferral table do not fit 150, and `checks/v-loop-SC-5.sh`
  exists to stop a line cap being met by cutting one of them.
- **four pre-existing test failures remain**, none introduced here: `document-standard.bats` cases
  194 and 200, `plugin-install.bats` case 340 (`commands/v-reconcile.md` has no frontmatter
  description), and `research-clarify.bats` case 386. Each fails on a clean checkout.
- **deferred**: the conflict-scope taxonomy (`global`, `store:<id>`, `customer:<id>`, `none`) and the
  browser-review rules appear in the web campaign only; the mobile campaign has no equivalent. They
  ship as the web adapter's rules rather than as general ones.
- **deferred**: `/v-loop` builds the unattended runner and hands the operator the two commands that
  install it. It does not install it: Claude Code's permission classifier refuses `crontab` edits and
  refuses to spawn `claude -p` from Bash, and that guard is not worked around. The first unattended
  tick is unproven whenever a campaign uses the batch shape, and the command says so.
- **pre-existing failure, named not inherited**: `./bin/rule-count.sh --assert` fails today at 175
  rule lines against a budget of 173, and 150 prohibitions against 25 requirements where the ceiling
  is 1:1. Repairing the existing corpus is not in scope. `checks/v-loop-SC-4.sh` holds the two new
  files to the ratio, and W-22 records in `vault/check-budget.md` why a campaign is measured apart
  from the `/v-team` corpus rather than raising the budget to hide the overrun.
- **accepted, with its cost stated**: no `bin/campaign.sh` ships. The concurrency rule is rewritten
  so a session can decide it from the ledger in front of it, which removes the only rule that
  needed a counter. The remaining prose rules rest on being read, and `vault/check-budget.md` says so.

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | how much of the loop is mechanical vs prose | yes | `vault/research/rule-compliance.md`, `bin/rule-count.sh`, `vault/check-budget.md` | answered | no new script; rewrite the count rule into one a session can decide from the ledger |
| Q-2 | ship generic on one campaign, or wait for a second stack | yes | `vault/decisions/ADR-015-retier-lifecycle-lite-critic-fast-path.md`, `prompts/on-device-e2e-campaign.md` | answered | two campaigns on different stacks already exist; ship the rules they converge on and mark the rest as adapter-local |
| Q-3 | where campaign artifacts live given the vault auto-syncs | yes | `commands/_shared/vault-sync.md`, `bin/vault-sync.sh:150`, `templates/vault.gitignore` | answered | `<project-vault>/campaigns/<slug>/`, with `results/` ignored by a rule the command writes |
| Q-4 | repair the staging guard here or defer it | yes | `scripts/staging-hook.sh`, `~/.claude/settings.json`, `vault/defect-ledger.md` D-006 | answered | repair and register it in this change |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a session reads `commands/v-loop.md` THE SYSTEM SHALL find the disposable-stack precondition, all six intake questions, a numeric default for both caps, the resume branch, the spawn envelope and the cheaper command to use instead | unit | command | `checks/v-loop-SC-1.sh` | exit 0 | MET | `checks/v-loop-SC-1.sh` exited 0 ·   OK  v-loop.md carries the precondition, the intake, both caps, resume and the envelope |
| SC-2 | WHEN `bin/doc-lint.sh` runs over every file this plan writes THE SYSTEM SHALL report no finding | unit | command | `checks/v-loop-SC-2.sh` | exit 0 | MET | `checks/v-loop-SC-2.sh` exited 0 ·   OK  16 files pass doc-lint |
| SC-3 | WHEN `commands/v-loop/campaign-rules.md` is compared against all seven shared modules THE SYSTEM SHALL restate no rule they already own | unit | command | `checks/v-loop-SC-3.sh` | exit 0 | MET | `checks/v-loop-SC-3.sh` exited 0 ·   OK  campaign-rules.md restates no shared-module rule; all _shared modules covered |
| SC-4 | WHEN the two `/v-loop` rule files are counted THE SYSTEM SHALL find requirement-shaped rules outnumbering prohibition-shaped ones in each | unit | command | `checks/v-loop-SC-4.sh` | exit 0 | MET | `checks/v-loop-SC-4.sh` exited 0 ·   OK  commands/v-loop/campaign-rules.md: 5 prohibitions, 20 requirements |
| SC-5 | WHEN `commands/v-loop/campaign-rules.md` is read THE SYSTEM SHALL carry all twelve safety rules the source campaigns paid for, each in requirement form | unit | command | `checks/v-loop-SC-5.sh` | exit 0 | MET | `checks/v-loop-SC-5.sh` exited 0 ·   OK  all twelve safety rules survive in campaign-rules.md |
| SC-7 | WHEN `scripts/staging-hook.sh` receives `git commit -a`, `git commit -am`, a pathspec-less `git commit`, `git commit --amend` or `git reset --hard` THE SYSTEM SHALL deny the call | unit | command | `checks/v-loop-SC-6.sh` | exit 0 | MET | `checks/v-loop-SC-6.sh` exited 0 · ok 22 GATE=off disables the commit refusal too |
| SC-6 | WHEN `/v-loop` is invoked against a repo with no disposable stack THE SYSTEM SHALL refuse and name the missing precondition | delivery | observed | invoke `/v-loop` in this framework repo, which has no runtime; it fails when the session scaffolds a campaign directory or begins intake instead of refusing. `no-command: the precondition is a stack the operator has named as disposable, which no script can assert on the operator's behalf` | a refusal naming the missing stack, and no `campaigns/` directory created | OPEN | needs the operator: invoke `/v-loop` in this repo and confirm the refusal |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| B1 | The change does what the task asked | met | `/v-loop` ships with both rule files, five templates, six checks and the staging repair; SC-6 stays open for the operator |
| B2 | Tests covering the changed behaviour pass | met | `./tests/run.sh tests/unit`: 625 pass, 4 fail. All four fail on a clean checkout too, verified by `git stash -u` and a re-run |
| B3 | Lint and any format check pass on the changed files | met | `./bin/doc-lint.sh --changed` exits 0; the two pre-existing `vault/_moc.md` findings were repaired in W-20 |
| B4 | Every review finding is fixed or recorded | met | 35 of 37 applied, 1 rejected, 1 deferred, all dispositioned in the trail sidecar |
| B5 | Documentation and vault docs that the change invalidates are updated | met | `README.md`, `vault-guide.md` §11.1 and its folder map, both `_moc.md` files, `vault/indications/_index.md`, `vault/decisions/_inventory.md`, `vault/check-budget.md`, `vault/defect-ledger.md` D-006 |
| B6 | Nothing unrelated is in the commit | met | every changed path appears in the work-item table; `~/.claude/settings.json` is outside the repo and is named in Rollback |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| E-1 | a campaign's evidence comes from the running system, never from reading code | PROSE | `commands/v-loop/campaign-rules.md`; nothing fails if it is ignored |
| E-2 | every case carries an injection, designed before the case runs | PROSE | `commands/v-loop/campaign-rules.md`; the ledger has an `injection` field but nothing refuses a blank one |
| E-3 | one tester runs at a time unless the conflict sets are disjoint | PROSE | `commands/v-loop/campaign-rules.md`; a session decides it from the ledger's `conflicts_on` field while writing, so it needs no counter |
| E-4 | the agent that wrote a fix does not produce its retest verdict | PROSE | `commands/v-loop/campaign-rules.md` |
| E-5 | the loop stops at `loop_max_rounds`, and the count survives a resume | HALF-BUILT | `templates/campaign/STATE.md` carries `rounds_used` and `checks/v-loop-SC-1.sh` refuses a command file that never reads it; nothing checks the running count |
| E-6 | `campaign-rules.md` restates no rule a shared module owns | ENFORCED | `checks/v-loop-SC-3.sh` greps 36 owner patterns and refuses a `_shared` module it does not cover |
| E-7 | the campaign's rules are written in requirement form | ENFORCED | `checks/v-loop-SC-4.sh` counts both forms and exits 1 when prohibitions win |
| E-8 | the twelve safety rules survive the line cap | ENFORCED | `checks/v-loop-SC-5.sh` names each one and exits 1 on an omission |
| E-9 | an agent stages each file by name | ENFORCED | `scripts/staging-hook.sh` denies `git add -A`, `git add .`, `git commit -a`, `git commit -am`, a pathspec-less `git commit`, `--amend` and `git reset --hard`, with `tests/unit/staging-hook.bats` proven failing first, registered in `~/.claude/settings.json` |

## Verified current state

- Two campaigns on different stacks exist, not one. The web campaign is
  `~/vault/digitally-core/processes/autonomous-test-fix-loop.md` (159 lines) plus its invocation
  `autonomous-test-fix-loop-prompt.md` (73 lines), against Laravel with Playwright and PHPUnit. The
  mobile campaign is `prompts/on-device-e2e-campaign.md` (213 lines) in this repo, committed
  2026-09-05 as `d3e46aa`, against a Flutter app on a real phone over adb. Both read in full
  2026-09-06.
- The two converge independently on nine rules: durable state as the only session handoff; an
  injection per case; a blocked case is not a failed one; the backlog enumerated first as the
  denominator for "done"; a test is never weakened to turn a red green; a defect verified before it
  is filed; evidence only from the running system; a bounded batch so a kill costs only the batch;
  and lead the report with what is unresolved. Convergence across two stacks is what makes these
  general rather than local.
- The two disagree on the campaign's shape, and the disagreement is load-bearing. The web campaign
  runs one long session dispatching three agents. The mobile campaign runs a host-level timer firing
  a fresh session per batch of four, because hundreds of device cases exceed one usage window. The
  second shape is the one that survives a limit, so `/v-loop` carries both.
- 16 of the web campaign's rules are already owned by a shared module, 6 partly, and 24 are new.
  Owners include `agent-conduct.md` (artifact-to-disk, numbers carry their command, the source can
  be wrong), `communication.md` (report exceptions), `document-standard.md` (current truth only),
  `definition-of-done.md` and `v-team/steps/04-execute-loop.md` (the mutation-or-characterization
  gate, which is the injection rule in different words), `critic-panel.md` (severity and grounding,
  which is defects-versus-opinions), `elicitation.md` (ask everything up front) and `vault-sync.md`
  (commit with a pathspec). Enumerated 2026-09-06 against all seven files in `commands/_shared/`.
- `scripts/staging-hook.sh` denies `git add -A` and `git add .` and returns clean on
  `git commit -am "x"`, `git commit -a`, `git commit --amend` and `git reset --hard`. Checked
  2026-09-06 by piping each command into the hook and reading its exit code.
- The staging hook is not registered on this machine. `~/.claude/settings.json` `PreToolUse` holds
  two entries — `~/.claude/hooks/block-keys.sh` and the observability sender — and neither is the
  staging hook. Checked 2026-09-06 by reading lines 95-109 of that file.
- `prompts/on-device-e2e-campaign.md` is referenced by nothing, not even `vault/_moc.md`, which
  lists its sibling. Checked 2026-09-06 with `grep -rn "on-device-e2e-campaign" --include='*.md' .`,
  which returns only the file itself. It is a proven method with no consumer.
- `install.sh` needs no change: `link_tree` at `install.sh:106-127` globs every `*.md` in `commands/`
  and every immediate subdirectory of it, so `commands/v-loop.md` and `commands/v-loop/` are both
  linked. Checked 2026-09-06.
- `templates/vault.gitignore` is copied once at `bin/vault-init.sh:124` and never re-applied, so an
  existing vault gains nothing from editing the template. `/v-pm` already handles this by appending
  its own path at seed time, and `/v-loop` follows that precedent. `bin/vault-init.sh:117` scaffolds
  six folders and `campaigns/` is not among them.
- Rules a session can decide from the text in front of it average 92.0% compliance here; rules
  needing a count average 64.3%, across the eight rules that were scorable. Recorded in
  `vault/research/rule-compliance.md`, which finds that grammatical form is not the lever —
  self-checkability is. That is a separate finding from the turn-decay measurement `bin/rule-count.sh`
  cites, and the two are not combined.

## Decisions

| decision | reason | record |
|----------|--------|--------|
| `/v-loop` sits outside the `/v-do` → `/v-work` → `/v-team` ladder | that ladder builds; this verifies and repairs what is already built and running | ADR-027 |
| the precondition is a stack the operator names as disposable, not merely a running one | "a running system exists" excludes only greenfield repos, which is how the last soft precondition drifted to 78% of runs | ADR-027 |
| the concurrency rule is "one tester unless the conflict sets are disjoint" | a session can decide that from the ledger it is writing; "three at a time" is a count nobody keeps, and the two campaigns disagree on the number anyway | ADR-027 |
| the loop carries a hard round cap and a per-defect retry cap, and the count survives a resume | an uncapped loop spends a session on a defect it cannot fix, and a cap reset by a usage limit never fires | ADR-002, ADR-027 |
| the agent that writes a fix does not verify it | an agent grading its own work skews positive | ADR-027 |
| every campaign rule is written as a requirement naming the sanctioned action | a prohibition falls to 33% compliance by turn 16 and a campaign runs more turns than anything else the framework does | ADR-027 |
| campaign rules restate no rule a shared module already owns | 16 of the source rules already have a home, and every duplicate spends attention the new rules need | ADR-027 |
| the case ledger is append-only JSONL; state and defects stay markdown | the ledger is written constantly under kill risk, where a truncated last line costs one case and a rewritten file costs the campaign | ADR-027 |
| `/v-loop` carries both campaign shapes and picks by whether the backlog fits one usage window | hundreds of device cases cannot live inside one session, and a short campaign gains nothing from a host timer | ADR-027 |
| campaign artifacts live in the project vault with `results/` ignored | a resumed campaign on another machine would otherwise start from nothing, and evidence drawn from a real data dump must not reach a vault remote | ADR-027 |
| the staging guard is extended and registered in this change | a campaign commits unattended, and the guard covers one verb of the action it names | ADR-027 |

## Scope & non-goals

Covers: the command, its operating rules, the campaign templates, the staging-guard repair and its
registration, the ADR, the indication, the feature dossier, the checks, the tests and the
documentation rows.

Does not cover: any `bin/campaign.sh`; any persona pack for campaign agents; any change to `/v-work`,
`/v-team` or `/v-cr`; installing an unattended runner; running an actual campaign; repairing the
framework's pre-existing rule-budget overrun; rewriting `prompts/on-device-e2e-campaign.md`, which
stays as the mobile adapter and is only linked.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `commands/v-loop.md` | the `/v-loop` slash-command dispatch, and `link_tree` at `install.sh:106` | this session | the orchestrating session at invocation | `/v-loop` resolves to nothing and the user gets an unknown-command error |
| `commands/v-loop/campaign-rules.md` | the spawn envelope defined in `commands/v-loop.md` step 3 | this session | every campaign agent, in its envelope | agents run without the injection, falsification and safety rules, and the campaign produces verdicts nothing backs |
| `templates/campaign/STATE.md` | `commands/v-loop.md` step 1, which instantiates it and reads `rounds_used` back on resume | this session | the next session resuming an interrupted campaign | a resumed session restarts its round count from zero and the cap never fires |
| `templates/campaign/ledger.md` | `commands/v-loop.md` step 2, which requires a ledger before any tester spawns | this session | the orchestrator choosing which testers may run together, and the next session resuming | a session killed mid-write loses the whole record instead of one truncated line, and no field holds the injection a case must carry |
| `templates/campaign/result.md` | `commands/v-loop.md` step 4, which reads the final line to decide whether the loop ends | this session | the orchestrator, once per case | no file holds a verdict, so nothing can answer whether the campaign is done |
| `templates/campaign/defects.md` | `commands/v-loop.md` step 5, and `bin/gate.sh recurrence`, which parses the same columns | this session | the fix agent, the verifying agent, and the operator at the close | a defect is repaired with no test that failed before it, and a recurrence reads as new |
| `templates/campaign/TESTER-BRIEF.md` | the spawn envelope in `commands/v-loop.md` step 3 | this session | every campaign agent, before it starts | each agent pays again for a trap the campaign already discovered |
| the `campaigns/*/results/` rule in the project vault's `.gitignore` | `bin/vault-sync.sh:150`, which stages the vault dir and would otherwise commit every result file | `commands/v-loop.md` step 1, appending it when absent | git, at every campaign write | evidence drawn from a real data dump is committed and pushed to the vault remote |
| `scripts/staging-hook.sh` | the `PreToolUse` entry this change adds to `~/.claude/settings.json` | this session | the Claude Code harness, before every Bash call | an unattended campaign agent sweeps a sibling agent's edits into its commit, which is the one defect class in the ledger that has already recurred |
| `prompts/on-device-e2e-campaign.md` | the mobile-adapter reference in `commands/v-loop.md` step 1 | already committed at `d3e46aa`; this session only links it | a session running a campaign against a phone | the phone-specific traps stay unreachable and each campaign pays for them again |
| `vault/indications/campaign-evidence-from-the-running-system.md` | the row this change adds to `vault/indications/_index.md` | this session | a future session changing `/v-loop` or writing a sibling command | the rule that a verdict needs a real request behind it exists only inside one command file |
| `tests/unit/v-loop.bats` | `./tests/run.sh tests/unit`, which globs the directory | this session | CI and the close gate | E-6 through E-9 have no mechanism and the duplication they forbid returns silently |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | `tests/unit/staging-hook.bats` | modify | Edit | add one case each for `git commit -a`, `git commit -am`, a pathspec-less `git commit`, `git commit --amend` and `git reset --hard`, each asserting exit 2; run before W-2 and confirm all five fail | SC-7 | `./tests/run.sh tests/unit/staging-hook.bats` exits 1 | DONE |
| W-2 | `scripts/staging-hook.sh` | modify | Edit | deny the five commands W-1 adds; keep every existing allow path passing; exit 0 on every path that is not a denial, per `vault/indications/hooks-never-fail-their-host.md` | SC-7 | `./tests/run.sh tests/unit/staging-hook.bats` exits 0 | DONE |
| W-3 | `checks/v-loop-SC-6.sh` | create | Write | wrap `./tests/run.sh tests/unit/staging-hook.bats` so `bin/gate.sh verdict --run` can grade SC-7 from a committed script | SC-7 | run it | DONE |
| W-4 | `~/.claude/settings.json` | modify | Edit | add one `PreToolUse` command entry for `~/.claude/hooks/staging-hook.sh` beside `block-keys.sh`; change nothing else in the file | SC-7 | pipe `git commit -am x` through a live Bash call and confirm the denial | DONE |
| W-5 | `commands/v-loop.md` | create | Write | dispatcher, the disposable-stack precondition, the six intake questions answered in one exchange, the resume branch that scans `<project-vault>/campaigns/` for a `STATE.md` with an open queue, both campaign shapes and the rule that picks between them, the spawn envelope contents, `loop_max_rounds` and the per-defect retry cap each with a number, the cheaper command to use instead and when, the step that appends the results ignore rule, and the statement that the unattended runner is handed over rather than installed; binds `communication.md`, `agent-conduct.md`, `document-standard.md`, `vault-sync.md` and `elicitation.md` by reference; at or under 200 lines | SC-1, SC-4 | `./checks/v-loop-SC-1.sh` and `./checks/v-loop-SC-4.sh` | DONE |
| W-6 | `commands/v-loop/campaign-rules.md` | create | Write | only the 24 rules no shared module owns, plus one reference line per owned rule; all twelve safety rules in requirement form; the two-column table deciding whether the test is wrong or the app is wrong; at or under 150 lines | SC-3, SC-4, SC-5 | `./checks/v-loop-SC-3.sh`, `./checks/v-loop-SC-4.sh`, `./checks/v-loop-SC-5.sh` | DONE |
| W-7 | `templates/campaign/STATE.md` | create | Write | the resume point, the retest queue, cases never run, `rounds_used`, and the disposable stack's name; no deferred operator decisions, which belong where `commands/_shared/elicitation.md` already puts them | SC-1, SC-2 | `./bin/doc-lint.sh` on the file | DONE |
| W-8 | `templates/campaign/ledger.md` | create | Write | the append-only JSONL contract: one object per line carrying `id`, `surface`, `kind`, `title`, `file`, `injection`, `conflicts_on`, `status`, `reason`, `run_at`, `evidence`; last line per id wins; terminal statuses `pass`, `fail`, `blocked`; a `blocked` row carries the exact unblock action | SC-1, SC-2 | `./bin/doc-lint.sh` on the file | DONE |
| W-9 | `templates/campaign/result.md` | create | Write | the per-case report shape, ending in the literal line `VERDICT: PASS \| FAIL \| BLOCKED`; state that any other final line is read as no verdict and the case is rerun | SC-1, SC-2 | `./bin/doc-lint.sh` on the file | DONE |
| W-10 | `templates/campaign/defects.md` | create | Write | the `vault/defect-ledger.md` column set — id, defect, repair, test, recurrences — plus verification output, rollback and fix commit, so one record covers the defect and its fix and `bin/gate.sh recurrence` can grade a campaign | SC-2 | `./bin/gate.sh recurrence templates/campaign/defects.md` | DONE |
| W-11 | `templates/campaign/TESTER-BRIEF.md` | create | Write | the traps discovered so far, current truth only; one line saying a trap is added the moment it costs a run | SC-2 | `./bin/doc-lint.sh` on the file | DONE |
| W-12 | `vault/decisions/ADR-027-autonomous-test-fix-loop.md` | create | Write | context names both campaigns and the `/v-team` tiering measurement; consequences name what is adapter-local rather than general, and the watch condition that would overturn it | SC-2 | `./bin/doc-lint.sh` on the file | DONE |
| W-13 | `vault/indications/campaign-evidence-from-the-running-system.md` | create | Write | the rule, its applies-to globs, and a contrasting pair showing what passes and what fails it | SC-2 | `./bin/doc-lint.sh` on the file | DONE |
| W-14 | `vault/indications/_index.md` | modify | Edit | one row for W-13 | SC-2 | `./bin/doc-lint.sh` on the file | DONE |
| W-15 | `vault/features/v-loop.md` | create | Write | scope, contracts, coupling, gotchas; established form only, no aspirational rules | SC-2 | `./bin/doc-lint.sh` on the file | DONE |
| W-16 | `vault/defect-ledger.md` | modify | Edit | extend D-006's repair and test cells to name the five newly denied commands and the registration; add no recurrence, because the gap was found by inspection and not by a repeat | SC-2 | `./bin/gate.sh recurrence` | DONE |
| W-17 | `tests/unit/v-loop.bats` | create | Write | one case per enforcement row E-1 to E-9; one case asserting every `commands/_shared/*.md` module appears as an owner in `checks/v-loop-SC-3.sh`; one case asserting every template `commands/v-loop.md` names exists | SC-1, SC-3, SC-5 | `./tests/run.sh tests/unit` | DONE |
| W-18 | `tests/unit/vault-sync.bats` | modify | Edit | add `commands/v-loop.md` to the enumerated path list, so a hand-rolled git call against a vault fails the suite | SC-7 | `./tests/run.sh tests/unit/vault-sync.bats` | DONE |
| W-19 | `templates/vault.gitignore` | modify | Edit | one rule `campaigns/*/results/` with a comment saying `/v-loop` step 1 appends it to an existing vault, following the `features/*/` precedent above it | SC-2 | `grep -n campaigns templates/vault.gitignore` | DONE |
| W-20 | `vault/_moc.md` | modify | Edit | one row for `/v-loop` under Features; one row for `prompts/on-device-e2e-campaign.md` beside its sibling, naming `/v-loop` as what reads it; split the two sentences at lines 29 and 41 that `bin/doc-lint.sh` already reports as over 30 words | SC-2 | `./bin/doc-lint.sh vault/_moc.md` | DONE |
| W-21 | `README.md` | modify | Edit | one row for `/v-loop` in the command table, naming the precondition | SC-2 | `./bin/doc-lint.sh` on the file | DONE |
| W-22 | `vault/check-budget.md` | modify | Edit | one row in "Rules kept as prose" for the campaign operating rules with why no check exists; one line recording that `checks/v-loop-SC-3.sh` matches literal wording only, so a reworded duplicate passes; one line saying a campaign's rules are counted apart from the `/v-team` corpus and why | SC-2 | `./bin/gate.sh budget` | DONE |
| W-23 | `vault-guide.md` | modify | Edit | one section naming when `/v-loop` applies, what it refuses without, and where campaign artifacts live | SC-2 | `./bin/doc-lint.sh` on the file | DONE |

## Sequencing & dependencies

W-1 before W-2: the five cases are proven failing before the hook changes. W-2 before W-4: the hook
is correct before it is registered. W-5 and W-6 before W-17, which greps both. W-13 before W-14,
which links it. W-6 before W-3's sibling checks can pass. Everything else is independent.

## Rollback

**Reverting this change** removes the command, the templates and the vault documents; the one commit
touches only new files plus single-row edits to nine existing ones. Two changes sit outside the repo
and `git revert` does not reach them: the `PreToolUse` entry added to `~/.claude/settings.json`
(W-4), which is removed by deleting that one entry, and any `campaigns/*/results/` rule `/v-loop`
appended to a project vault's `.gitignore`.

**Reverting a campaign run is a different problem, and mostly impossible.** A campaign applies code
fixes, commits them, runs the project's own test suite against a live stack, and creates and deletes
rows through the project's API. Reverting `/v-loop` undoes none of it. A dropped or truncated
project database is restored only from the operator's own backup or the stack's restore script; a
commit already pushed to a shared branch is the operator's to reverse; rows written through the API
are removed by the campaign's own teardown or by hand. This is what the disposable-stack
precondition exists to bound, and it is what the approval gate is approving.

## Test plan

`tests/unit/v-loop.bats` and the extended `tests/unit/staging-hook.bats`, both under
`./tests/run.sh tests/unit`, which runs bats in the repo's container. The staging-hook cases are
written and proven failing before the hook changes. The `/v-loop` cases are token greps that assert
each enforcement row's mechanism exists in the file that must carry it, following the
`tests/unit/v-team.bats` convention, plus a coverage case that fails when a new `commands/_shared/`
module is added without extending `checks/v-loop-SC-3.sh`.

## Test design dossier

Not applicable: this change writes documents plus one shell edit with a direct behavioural test, and
adds no runtime behaviour for a generative test-design pass to model.

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T-1 | SC-7 | unit | `tests/unit/staging-hook.bats` | the hook denies `git commit -a`, `-am`, a pathspec-less commit, `--amend` and `git reset --hard` | must | |
| T-2 | SC-1 | unit | `tests/unit/v-loop.bats` | `commands/v-loop.md` names the disposable-stack precondition and all six intake questions | must | |
| T-3 | SC-1 | unit | `tests/unit/v-loop.bats` | both caps carry a number, and `rounds_used` is read back on resume | must | |
| T-4 | SC-5 | unit | `tests/unit/v-loop.bats` | all twelve safety rules survive in `campaign-rules.md` | must | |
| T-5 | SC-3 | unit | `tests/unit/v-loop.bats` | every `commands/_shared/*.md` module appears as an owner in `checks/v-loop-SC-3.sh` | must | |
| T-6 | SC-1 | unit | `tests/unit/v-loop.bats` | every template `commands/v-loop.md` names exists on disk | must | |
| T-7 | SC-4 | unit | `tests/unit/v-loop.bats` | prohibitions do not outnumber requirements in either rule file | must | |
| T-8 | SC-2 | unit | `tests/unit/v-loop.bats` | `vault/indications/_index.md` carries the W-13 row | should | |
| T-9 | SC-7 | unit | `tests/unit/vault-sync.bats` | `commands/v-loop.md` is in the enumerated path list | should | |

## Refs

- `vault/decisions/ADR-015-retier-lifecycle-lite-critic-fast-path.md` — the measurement that says a
  new command must name what it competes with and when not to use it.
- `vault/decisions/ADR-002-no-stop-on-approval-alone.md` — the loop-cap discipline `/v-loop` reuses.
- `vault/research/rule-compliance.md` — why the prose-rule count is a cost rather than a neutral
  choice, and why self-checkability rather than grammar is the lever.
- `vault/research/subagent-token-economics.md` — the fan-out economics the campaign spawn obeys.
- `vault/defect-ledger.md` — D-006 is the staging defect W-1 to W-4 finish repairing.
- `commands/_shared/agent-conduct.md` — the rules `campaign-rules.md` defers to instead of restating.
- `prompts/on-device-e2e-campaign.md` — the mobile campaign, and the second stack that makes the
  converged rules general rather than local.
- `~/vault/digitally-core/processes/autonomous-test-fix-loop.md` — the web campaign's operating rules.
- `2026-09-06-1053-v-loop-autonomous-campaign.trail.md` — the process record for this plan.
