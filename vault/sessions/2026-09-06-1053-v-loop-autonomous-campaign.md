---
type: session
project: vault
date: 2026-09-06-1053
topic: v-loop-autonomous-campaign
files_touched: [commands/v-loop.md, commands/v-loop/campaign-rules.md, templates/campaign/STATE.md, templates/campaign/ledger.md, templates/campaign/result.md, templates/campaign/defects.md, templates/campaign/TESTER-BRIEF.md, templates/vault.gitignore, scripts/staging-hook.sh, tests/unit/staging-hook.bats, tests/unit/v-loop.bats, tests/unit/vault-sync.bats, checks/v-loop-SC-1.sh, checks/v-loop-SC-2.sh, checks/v-loop-SC-3.sh, checks/v-loop-SC-4.sh, checks/v-loop-SC-5.sh, checks/v-loop-SC-6.sh, install.sh, README.md, vault-guide.md, _moc.md, vault/_moc.md, vault/check-budget.md, vault/defect-ledger.md, vault/decisions/_inventory.md, vault/indications/_index.md]
decisions: [ADR-027]
tags: [session, command, campaign, qa, autonomous, gates]
---

# /v-loop — autonomous test-and-fix campaign command

## Goal
Turn a QA campaign method proven in another repo into a framework command, without repeating the
routing mistake that made `/v-team` 78% of lifecycle runs.

## Did
- Read both source documents in full, then found a second campaign already committed here:
  `prompts/on-device-e2e-campaign.md` (Flutter on a phone, 2026-09-05), which nothing referenced.
- Wrote [[../plans/2026-09-06-1053-v-loop-autonomous-campaign]] and its trail sidecar; four reviewers
  returned 37 findings, 9 of them confirmed blockers. Dispositions are in the sidecar.
- Shipped `commands/v-loop.md` (180 lines) and `commands/v-loop/campaign-rules.md` (161), five
  campaign templates, six check scripts and 27 bats cases.
- Repaired `scripts/staging-hook.sh` and registered it in `~/.claude/settings.json`.
- Corrected `vault/decisions/ADR-027-autonomous-test-fix-loop.md` against this repo's own
  measurement after drafting a claim the measurement contradicts.

## Learned
- **Two contrasting instances tell you which rules are general.** The web and mobile campaigns
  converged on nine rules independently and disagreed on three: the concurrency number, the conflict
  taxonomy, and the campaign's shape. The disagreements are the stack-local parts, and a single
  instance cannot separate them.
- **The mobile campaign refutes the web campaign's architecture.** Hundreds of device cases exceed
  one usage window, so the shape that survives is a host timer firing a fresh session per batch
  rather than one long session dispatching agents. The plan assumed the web shape until this was read.
- **A count-shaped rule can often be reworded into a decidable one rather than given a script.**
  "Three agents at a time" became "one tester unless the conflict sets are disjoint", which a session
  decides from the ledger row it is writing. That removed the only rule needing a counter.
- **16 of the web campaign's 46 rules already had a home** in `commands/_shared/`, and 6 partly did.
  Every duplicate spends the attention the new rules need.
- **`scripts/staging-hook.sh` covered one verb of the action it names.** It denied `git add -A` and
  returned clean on `git commit -am`, which sweeps a sibling agent's edits identically. It was also
  unregistered on this machine, so nothing was guarding it at all.
- **This repo's rule measurements point opposite ways.** `bin/rule-count.sh` cites prohibitions
  falling 73% → 33% by turn 16; `vault/research/rule-compliance.md` measured 89.5% against 76.9% the
  other way. A campaign is the first thing here that reaches turn 16 routinely, and which holds is
  untested.
- **The rule-budget assert already fails**: 175 rule lines against 173, and 150 prohibitions against
  25 where the ceiling is 1:1. Pre-existing, and not repaired here.

## Behaviors & rules
- `/v-loop` invoked with no disposable stack named by the operator → the session stops and names the
  missing precondition; edge: a stack inferred from `docker-compose.yml` does not satisfy it.
- A `campaigns/` directory holding a `STATE.md` with an open retest queue → the session resumes it
  and carries `rounds_used` forward; edge: `rounds_used` reset to zero makes the round cap unfirable.
- Two testers dispatched together → their `conflicts_on` sets are disjoint; edge: `global` runs alone.
- A case whose injected condition produces the same outcome as the normal one → verdict `BLOCKED`.
- A fix landing → its retest verdict comes from an agent other than the one that wrote the fix.
- `rounds_used` reaching `loop_max_rounds` → the session stops, reports every case still failing,
  and escalates rather than continuing.
- A `git commit` carrying `-a`, `-am`, `--amend`, or no pathspec, or a `git reset --hard` → the
  staging hook denies the call with exit 2; edge: `GATE=off` disables it, and a commit naming its
  paths passes.

## Next
- **Open**: SC-6 needs the operator. Run `/v-loop` in this repo and confirm it refuses for want of a
  disposable stack, creating no `campaigns/` directory.
- **Watch**: whether a session ever starts a campaign without a disposable stack being named. That
  would mean the precondition failed the way `/v-team`'s did, and the answer is a check.
- Four pre-existing test failures stay open, none from this change: `document-standard.bats` 194 and
  200, `plugin-install.bats` 340 (`commands/v-reconcile.md` has no frontmatter description), and
  `research-clarify.bats` 386.
- The rule-budget overrun (175/173, 150:25) is unrepaired and is its own piece of work.

## Refs
- [[../decisions/ADR-027-autonomous-test-fix-loop]] — the decision this session landed.
- [[../decisions/ADR-015-retier-lifecycle-lite-critic-fast-path]] — the measurement that shaped the
  precondition and the routing.
- [[../features/v-loop]] — the feature dossier.
- [[../indications/campaign-evidence-from-the-running-system]] — the rule the command carries.
- [[../plans/2026-09-06-1053-v-loop-autonomous-campaign]] — the plan, with its verdicts filled.
- `prompts/on-device-e2e-campaign.md` — the mobile campaign, and the second stack that made the
  converged rules general rather than local.
