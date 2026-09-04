---
type: session
project: vault
date: 2026-09-04
topic: rule-compliance-study
files_touched: [bin/rule-audit.sh, tests/unit/rule-audit.bats, vault/research/rule-inventory.md, vault/research/rule-compliance.md, checks/rule-compliance-SC-1.sh, checks/rule-compliance-SC-2.sh, checks/rule-compliance-SC-3.sh, vault/plans/2026-09-04-1100-rule-compliance-study.md, vault/plans/2026-09-04-0900-mechanical-session-gates.md]
decisions: [drop D-02, narrow D-03]
tags: [session, compliance, measurement, rules, enforcement]
---

# rule-compliance-study

## Goal

Measure which property predicts whether a framework rule is followed — its grammar, its position in
a file, or whether the model can check itself against it while writing.

## Did

- Wrote [[../research/rule-inventory]]: ten rules with a mechanical trace, each classified on form,
  self-checkability and enforcement. `bin/rule-audit.sh` parses that table; the script holds no rule
  list of its own.
- Wrote `bin/rule-audit.sh`, scoring four corpora: 155 commit subjects, 299,105 shell commands really
  run, 14,912 main-loop replies, and 332 committed versions of documents under `vault/`.
- Wrote `tests/unit/rule-audit.bats` — 12 cases covering prose mentions, quoted grep arguments,
  heredoc bodies, command chains, UNSCORABLE, determinism and a malformed transcript line.
- Wrote [[../research/rule-compliance]] with the rates, the three-axis comparison, and five stated
  limits.
- Recorded the result in [[../plans/2026-09-04-0900-mechanical-session-gates]]: D-02 dropped, D-03
  narrowed, O-1 closed.
- Added `checks/rule-compliance-SC-1.sh` and two siblings after `bin/gate.sh` began refusing a
  criterion whose check is typed into the plan.

## Learned

- **Self-checkability predicts compliance; grammar does not.** Rules decidable from the text being
  written average 92.0%; rules needing a count average 64.3%. Among unenforced rules the split is
  88.6% against 46.5%.
- **Prohibitions score higher than requirements here** — 89.5% against 76.9%. That is the opposite
  ordering to `https://arxiv.org/abs/2604.20911`, the paper D-02 rested on.
- **The pair at `commands/v-work/steps/05-commit-capture.md:57-58` holds everything constant but
  one thing.** Conventional prefix 92.9% (144/155), 50-character subject 18.1% (28/155). Same file,
  same sentence, same grammar, same age, neither enforced. Only the cost of checking differs.
- **A check substitutes for self-checkability.** The 300-line plan cap scores 50 of 50 despite being
  uncountable at write time, because `scripts/doc-lint-hook.sh` counts the lines after every write.
- **The transcript corpus spans only 2026-08 and 2026-09**, not May to September. 1,709 files, but
  every assistant turn carries an August or September timestamp.
- **Raw grep overcounts even after the tool_use filter.** A Bash command can carry the forbidden text
  inside a quoted argument or a heredoc body. Scoring needs the command split into simple commands
  with quotes and heredocs removed, not just `tool_use` extraction.
- **`jq` aborts a whole file on one malformed line.** `jq -Rrc 'fromjson? // empty'` reads line by
  line and skips the bad ones; without it, one corrupt record silently drops every later record in
  that transcript.
- **Awk emitted multi-line records from quoted strings**, so a continuation line became its own row
  and its text became a month label. Collapsing newlines inside a simple command fixed it.
- **`checks/` is flat and keyed by criterion id**, so two plans cannot both own `SC-2.sh`. This
  session prefixed its scripts with the plan slug to work around it.
- **A concurrent session swept this session's in-progress files into its own commits** (`960d6f8`,
  `691a630`) while both ran in this repo.

## Behaviors & rules

- A rule is scored from a real invocation → only `tool_use` blocks named `Bash`, split into simple
  commands; edge: text inside a quoted argument or a heredoc body is never an invocation.
- A rule that cannot be scored → prints `UNSCORABLE` with its reason and no rate; edge: a denominator
  below the floor of 10 is UNSCORABLE, not a percentage.
- Two runs over the same corpus → identical output; edge: the corpus grows during a session, so the
  cache is what makes the re-run reproducible and `--refresh` is explicit.
- Every rate in a report → carries the command that produced it and its denominator.
- The inventory is missing or unparseable → `bin/rule-audit.sh` exits 2; edge: never exit 0 with no
  rules scored.
- A rate is printed → under `LC_ALL=C`, because a decimal comma is a different number.

## Next

- D-03 is the open work: give a check to the 50-character subject clause at
  `commands/v-work/steps/05-commit-capture.md:58` or delete it. It scores 18.1%.
- S-5 stays open: eight scored rules cannot separate self-checkability from enforcement, because all
  three enforced rules were enforced from the day they were written.
- `checks/` needs a namespacing rule before a third plan collides on a criterion id.
- `bin/rule-audit.sh --refresh` takes about four minutes on a cold cache. If it becomes a CI check,
  the corpus build needs to be incremental.
- No feature dossier covers the enforcement machinery, though ADR-025, ADR-026, `bin/gate.sh`,
  `bin/doc-lint.sh`, `bin/output-lint.sh`, `bin/rule-audit.sh` and four hooks all belong to it.
  Writing `features/rule-enforcement.md` waits until the gates work stops moving.

## Refs

[[../plans/2026-09-04-1100-rule-compliance-study]]
[[../plans/2026-09-04-0900-mechanical-session-gates]]
[[../research/rule-compliance]]
[[../research/rule-inventory]]
[[../research/document-writing]]
[[../indications/rules-the-model-can-check]]
[[../decisions/ADR-026-mechanical-session-gates]]
