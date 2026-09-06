---
type: trail
project: vault
plan: 2026-09-06-1053-v-loop-autonomous-campaign
tags: [trail, record]
---

# 2026-09-06-1053-v-loop-autonomous-campaign — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`plans/2026-09-06-1053-v-loop-autonomous-campaign.md`, which carries the current truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| `/v-loop` sits outside the build ladder | a fourth rung above `/v-team` | a rung invites "reach for the next one when unsure", which is how `/v-team` reached 78% of runs; an orthogonal command with a precondition cannot be reached by escalation |
| prose rules, no `bin/campaign.sh` | ship four mechanical checks with the command | the operator observed the rules holding through the source campaign, and a check with no measured false-positive rate risks the 1-in-10 line that switches every gate off |
| ship generic with the stack detected | ship Laravel-shaped and generalise after a second campaign | a Laravel-shaped command fits one repo and a second stack would mean rewriting rather than confirming |
| campaign rules written as requirements | keep the source document's prohibition grammar | `bin/rule-count.sh` records prohibitions falling to 33% compliance by turn 16 while requirements hold, and a campaign runs more turns than anything else the framework ships |
| campaign artifacts in the project vault, `results/` gitignored | keep everything local to the code repo | a resumed campaign on another machine would start from nothing |
| a hard round cap and a per-defect retry cap | the source document's uncapped "loop until no case fails" | an uncapped loop spends a whole session on a defect it cannot fix, and the framework's critique loops already settled that caps are hard |
| the agent that writes a fix does not verify it | let the fixing agent retest, as the source campaign did | an agent grading its own work skews positive; separating generation from evaluation is what the long-running-harness evidence supports |

## Findings & dispositions

### Round 1

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| consumer | consumer-1 | BLOCKER | confirmed | the command file names the caps but nothing requires it to ask the six intake questions or give the caps a number | applied — W-5 constraint and `checks/v-loop-SC-1.sh` |
| consumer | consumer-2 | BLOCKER | confirmed | no file the plan created held a case verdict, so the loop had nothing to read to decide it was done | applied — `templates/campaign/result.md`, W-9 |
| consumer | consumer-3 | MAJOR | confirmed | every case must carry an injection and no template had a field for it | applied — the `injection` field in the ledger, W-8 |
| consumer | consumer-4 | MAJOR | confirmed | the results ignore rule was a decision nobody built | applied — W-5 appends it, W-19 seeds the template |
| consumer | consumer-5 | MAJOR | confirmed | `STATE.md` had a reader and no route to it; the campaign slug format was undefined | applied — the resume branch in W-5 |
| consumer | consumer-6 | MINOR | confirmed | two artifacts reach agents through a spawn envelope no work item required | applied — the envelope is named in W-5 and checked by SC-1 |
| consumer | consumer-7 | NIT | confirmed | one template had no lifecycle row | applied — the table now covers every artifact |
| consumer | consumer-8 | NIT | confirmed | the install question was answerable by reading `install.sh` | applied — recorded as verified state |
| security | security-1 | BLOCKER | confirmed | the safety rules were absent from the plan, and every check still passed without them | applied — SC-5, E-8, `checks/v-loop-SC-5.sh` |
| security | security-2 | BLOCKER | confirmed | campaign evidence would be committed and pushed to the vault remote | applied — W-5 and W-19 |
| security | security-3 | MAJOR | confirmed | the staging guard denies `git add -A` and returns clean on `git commit -am` | applied — W-1 to W-4 |
| security | security-4 | MAJOR | confirmed | the precondition allowed the operator's own working stack | applied — the disposable-stack precondition |
| security | security-5 | MAJOR | confirmed | rollback described undoing the command and not undoing a campaign | applied — the second rollback paragraph |
| security | security-6 | MINOR | confirmed | a connection string pasted into a defect report passes every guard | applied — the pass-the-path rule in SC-5 |
| security | security-7 | MINOR | confirmed | the staging hook is not registered on this machine | applied — W-4 |
| security | security-8 | MINOR | confirmed | `/v-loop` writes into a vault and was not bound to the vault-sync module | applied — W-5 binding list and W-18 |
| skeptic | skeptic-1 | BLOCKER | confirmed | the rollback claim covered the repo and not the command's purpose | applied — see security-5 |
| skeptic | skeptic-2 | MAJOR | confirmed | a resumed campaign restarts its round count, so the cap never fires | applied — `rounds_used`, W-7, E-5 |
| skeptic | skeptic-3 | MAJOR | confirmed | the concurrency cap is the one rule a session cannot check while writing | applied — rewritten to the disjoint-conflict-sets form |
| skeptic | skeptic-4 | MAJOR | confirmed | the stated reason for shipping no checks was that the campaign followed the rules, and the source document is a list of the times it did not | applied — the reason is corrected and the operator re-decided |
| skeptic | skeptic-5 | MAJOR | confirmed | "a running system exists" excludes almost nothing and would drift | applied — see security-4 |
| skeptic | skeptic-6 | MINOR | confirmed | SC-6 needs an operator verdict while the plan said nothing needed the operator | applied — Open & deferred |
| skeptic | skeptic-7 | MINOR | confirmed | the plan cited the rule that a command must say when not to use it, then put it in no work item | applied — W-5 constraint and SC-1 |
| skeptic | skeptic-8 | MINOR | advisory | the cheapest version is a process document with no command at all | rejected — the operator asked for a command, and a second stack already answers the taxonomy doubt this rested on |
| skeptic | skeptic-9 | NIT | confirmed | the install question was already settled | applied — see consumer-8 |
| quality | quality-1 | BLOCKER | confirmed | the duplication rule was checked against four shared modules when seven exist | applied — all seven, plus a refusal on an uncovered module |
| quality | quality-2 | BLOCKER | confirmed | the duplication check matched five of the sixteen rules it exists to catch | applied — 36 owner patterns |
| quality | quality-3 | MAJOR | confirmed | the injection rule is the existing mutation-or-characterization gate in different words | applied — referenced, with only the new half stated |
| quality | quality-4 | MAJOR | confirmed | the defects template rewrote a table `bin/gate.sh recurrence` already grades | applied — W-10 reuses the ledger column set |
| quality | quality-5 | MAJOR | confirmed | the framework is past its own rule budget and the plan added prose without touching it | applied — W-22 records why a campaign is counted apart, rather than raising the budget |
| quality | quality-6 | MINOR | confirmed | "are declared values consumed" is already enforced by `bin/gate.sh readers` | applied — the rule is dropped and the gate is called instead |
| quality | quality-7 | MINOR | confirmed | "separate defects from opinions" restates the severity and grounding split | applied — the existing finding schema is required instead |
| quality | quality-8 | MINOR | confirmed | no `install.sh` change is needed | applied — see consumer-8 |
| quality | quality-9 | MINOR | confirmed | the defects table and the fix log are one record in two files | applied — merged into W-10 |
| quality | quality-10 | MINOR | advisory | the `/v-cr` sandbox helpers are reusable for naming the campaign stack | deferred — the campaign stack is the operator's own build, and reusing a no-network envelope's helpers for it buys a name and nothing else |
| quality | quality-11 | MINOR | confirmed | a state file carrying deferred decisions creates the third home `elicitation.md` forbids | applied — W-7 constraint |
| quality | quality-12 | NIT | confirmed | a reworded duplicate passes the literal-match check | applied — stated in the script and in W-22 |

## Metrics

Round 1: four reviewers, 37 findings, 9 confirmed blockers. 35 applied, 1 rejected (skeptic-8),
1 deferred (quality-10). No previously-confirmed finding was dropped. One reviewer premise was
independently re-verified before being applied: the staging-hook gap and its non-registration were
each reproduced by running the hook and reading `~/.claude/settings.json`.

One input reached the plan after the reviewers were briefed and none of them saw it:
`prompts/on-device-e2e-campaign.md`, the second campaign, committed to this repo the previous day.
It changed the proof standard, the ledger format and the campaign shape.

## Advisory test hints

## Rejected / deferred

- **A `/v-loop` persona pack.** Campaign agents are testers and fixers, not critics, so the persona
  machinery adds a resolution step and a config surface for no vote. Dropped before drafting.
- **Reusing `/v-cr`'s sandbox for campaign isolation.** `lib/cr-sandbox.sh` isolates untrusted code
  from a pull request; a campaign runs the operator's own code against a stack the operator built,
  and its isolation question is which database the suite reaches, not whether the code is hostile.
- **Research that did not survive:** external sources on hybrid Redis-plus-vector state persistence
  for long-running agents. The campaign's resume point is a handful of markdown files a session
  reads directly, and the vault already syncs them.

## Sources consulted

- shiplight.ai/blog/agent-native-autonomous-qa — autonomous QA that runs and heals without a human
  at each step.
- indium.tech/blog/7-state-persistence-strategies-ai-agents-2026 — agents running past four hours
  without state persistence carry a much higher total-failure risk.
- dev.to/maximsaplin/long-horizon-agents-are-here-full-autopilot-isnt-5bo7 — long-horizon loops
  drift subtly rather than failing loudly, which is the argument for a hard cap.
- martinfowler.com/articles/harness-engineering.html and addyosmani.com/blog/agent-harness-engineering
  — the build-verify loop as a control-flow requirement rather than a prompt suggestion.
- arxiv.org/pdf/2606.01770 — separating generation from evaluation into distinct agents outperforms
  self-evaluation, because an agent grading its own work skews positive.
