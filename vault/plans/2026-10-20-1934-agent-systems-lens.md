---
type: plan
project: vault
slug: 2026-10-20-1934-agent-systems-lens
repos: [vault]
status: executed
process_record: 2026-10-20-1934-agent-systems-lens.trail.md
arch_spec: 2026-10-20-1934-agent-systems-lens.arch.md
human_plan: https://claude.ai/artifact/2CYmTfwXjRSeNTcUreSf3x
session_of:
session:
tags: [plan, persona, skills, agents]
---

# 2026-10-20-1934-agent-systems-lens — plan

## Task

Add a planning critic lens, `planning/agent-systems`, that reviews the design of LLM agents a product runs for its own users. Add eight plugin skills that teach how to build those agents. Store the research behind both as cited records in the framework repo `~/workspace/vault`.
Keywords: agent, LLM, prompt injection, MCP, tool, retrieval, judge, eval, self-improvement, persona, skill.

## Open & deferred

- needs the operator: release a new plugin version by bumping `.claude-plugin/plugin.json`. Sessions read the cached plugin at `~/.claude/plugins/cache/kdabro-vault/vault/1.13.0`, so no session sees the lens or the skills before the release.
- needs the operator: run the follow-up `/v-team` in `~/workspace/recycling-api` that applies this lens to the support drafter. This plan builds the lens and does not diagnose the drafter.
- accepted: the lens cites OWASP Top 10 for LLM Applications 2025 ids (LLM01–LLM10) only. The OWASP agentic ids (T1–T15, ASI01–ASI10) come from secondary summaries and stay out of the lens.
- accepted: `bin/doc-lint.sh` cannot run by hand in this session, because `vault-quality-gates` `guard-bash.sh` refuses the script. The `PostToolUse` doc-lint hook lints each written file.
- accepted: C3 proves the lens finds the known judge defect in the support drafter. It does not prove the lens finds something no other lens would. W2b and W2c remove the overlapping checks from the other lenses instead.
- open: `bin/gate.sh` and `tests/unit/gate.bats` hold another session's uncommitted edits. This work stages only the paths in Work items.

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q1 | Where does the lens live? | yes | `ls personas/_shared personas/_shared/planning` | answered | the framework, as a planning-group lens |
| Q2 | What form do the how-to topics take? | yes | `find . -name SKILL.md` in the framework | answered | Claude Code skills in the plugin's `skills/` folder |
| Q3 | Does this session also diagnose the support drafter? | yes | `~/vault/givore/plans/2026-10-18-1246-api-support-drafts-learning.md` | answered | no; a follow-up run uses the lens on the drafter |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| C1 | WHEN the planning lens contract tests run THE SYSTEM SHALL pass with `agent-systems` among the lenses, its trigger in `personas/_resolution.md` §2.3, and one owner per moved rule | behaviour | command | `checks/agent-systems-lens-C1.sh` | 0 | MET | `checks/agent-systems-lens-C1.sh` exited 0 · ok 11 every planning id in a pack use_shared resolves to a lens file |
| C2 | WHEN the agent skill and C3-parser contract tests run THE SYSTEM SHALL pass, fail fixtures included | behaviour | command | `checks/agent-systems-lens-C2.sh` | 0 | MET | `checks/agent-systems-lens-C2.sh` exited 0 · ok 8 with no argument the script reads the plan's default run file, and exits 2 when it is absent |
| C3 | WHEN the lens reviews `~/vault/givore/plans/2026-10-19-1055-api-support-drafter-one-rulebook.md` against `~/workspace/recycling-api` in one spawn THE SYSTEM SHALL return at least 3 confirmed findings with a command or `path:line` each, one of them citing `judge_model` or `sendable_score` | delivery | command | `checks/agent-systems-lens-C3.sh` | 0 | MET | `checks/agent-systems-lens-C3.sh` exited 0 · 10 confirmed findings with evidence, 1 on the judge |

## Definition of done

| id | line | state | evidence |
|----|------|-------|----------|
| D1 | `./tests/run.sh tests/unit` passes for every touched bats file | met | `planning-personas` (11), `agent-skills` (6), `agent-systems-c3` (8), `install` (26) and `plugin-install` (28) bats files pass; `commands/v-reconcile.md` gained its description and `commands/v-loop/adapters/test-and-repair.md` its path note |
| D2 | `./bin/doc-lint.sh --changed` reports no finding on the new and changed Markdown files | absent: `guard-bash.sh` refuses `bin/doc-lint.sh` in this session | the `PostToolUse` doc-lint hook reported no finding on the last write of each changed Markdown file; it skips `skills/` files |
| D3 | `./bin/gate.sh verdict <plan> --run` exits 0 | met | the installed `bin/gate.sh verdict --run` exited 0 with C1, C2 and C3 MET |
| D4 | `make release-check` fails only on the unbumped `.claude-plugin/plugin.json` version, which the operator bumps under ADR-020 | met | `make release-check` reports only `the plugin version is still 1.13.0` |

## Enforcement states

| id | ruling | state | mechanism |
|----|--------|-------|-----------|
| R1 | A plan whose product makes an LLM call at runtime for its users seats `planning/agent-systems` | PROSE | `personas/_resolution.md` §2 and §2.3 trigger lines; `tests/unit/planning-personas.bats` asserts the text; no code selects critics |
| R2 | Every agent-systems checklist item names exactly one existing skill | ENFORCED | `tests/unit/agent-skills.bats` checks each item, with a fail fixture |
| R3 | The trust-boundary rule and judge calibration for product agents have one owner, `planning/agent-systems`; `harness-engineer` keeps the three-part check for harness agents only | ENFORCED | `tests/unit/planning-personas.bats` fails when another planning lens names `trifecta` or `TPR`, or restates the three-part rule outside `harness-engineer` |
| R4 | A missing deterministic control can block; a missing probabilistic control is at most MINOR; an unmeasured gating judge is MAJOR | PROSE | the lens severity rubric |

## Verified current state

- The framework ships no `skills/` folder and no `SKILL.md` · `find /home/kdabrow/workspace/vault -name SKILL.md` · 2026-10-20
- Planning lenses hold six sections in order, at most 150 lines, and 10–12 checklist items linking the group README · `tests/unit/planning-personas.bats` · 2026-10-20
- `/v-pm` hands a planning lens to its critic verbatim, with no pack overlay; `/v-team` composes overlays only for `use_shared` ids · `commands/v-pm/steps/03-plan-panel.md:53-55`, `personas/_resolution.md:28-30` · 2026-10-20
- `security-architect.md` holds the trust-boundary rule in its LLM-risks bullet, its exfiltration paragraph, its severity rubric and two checklist items. `harness-engineer.md` holds the judge and trifecta rules in its Mandate, severity rubric, checklist and Scale table · `grep -nEi 'judge|trifecta|untrusted' personas/_shared/planning/*.md` · 2026-10-20
- Lens research lives in `vault/research/v-pm-planning-lenses/`, mostly one file per lens and without frontmatter. Flat records such as `vault/research/subagent-token-economics.md` carry `type: research` frontmatter · `ls vault/research/v-pm-planning-lenses` · 2026-10-20
- The recycling-api support drafter uses `claude-opus-5-5` as writer and judge, scores sendability 1–5 with a cut at 4, and has no judge calibration · `config/support.php:144,155,193`, `config/ai.php:55` · 2026-10-20

## Decisions

| decision | reason | record |
|----------|--------|--------|
| The lens joins the planning group as `planning/agent-systems` | it reviews architecture before code, and the planning contract and tests exist | local |
| `harness-engineer` keeps developer tooling; `agent-systems` owns agents a product runs for its users | they fail in different places: a developer session, or in front of customers | local |
| `security-architect` keeps auth, data, secrets and attack surface; `agent-systems` owns the trust boundary of a product agent run | prompt injection needs agent-specific patterns | local |
| Stack tools appear in the lens Bound analyzer as detection examples, with no pack overlay | `/v-pm` never loads a pack overlay for a planning lens | local |
| `api-laravel` lists `planning/agent-systems` in `use_shared` | `/v-team` panels in Laravel repos can then seat it through the existing pack mechanism | local |
| Each checklist item names one skill as `skill: skills/agent-<name>/SKILL.md` on its own indented line | one fixed format lets the test parse it | local |
| Eight skills with a 12000-byte cap and a 300-character description each | a skill loads whole, and every session pays for the descriptions | local |
| `planning/agent-systems` sits first in the §2.3 trigger list, and the harness trigger narrows to developer tooling | at medium tier one trigger seat exists, and a product prompt must not give it to the developer-harness lens | local |
| The agent-systems trigger lives once, in §2.3; §2 links to it for the PROPOSE panel only | one home per trigger; diff review keeps its fixed seats | local |
| The research stays three files for one lens | 127 sources in three topics exceed the 66–114 line sibling records | local |

## Scope & non-goals

Covers: the lens, ownership edits in two lenses and the group README, seating rules, eight skills, symlink install of skills, three research records, and contract tests. Not covered: any change in `~/workspace/recycling-api`, the diagnosis of the support drafter, and the plugin release.

## Artifact lifecycles

| artifact | what requires it | who writes it | who reads it | missing or wrong |
|---|---|---|---|---|
| `personas/_shared/planning/agent-systems.md` | `personas/_resolution.md` §2.3 and `personas/api-laravel.md` `use_shared` name `planning/agent-systems` | W1 | `/v-pm` and `/v-team` critic spawns | the loader cannot resolve the id and drops the seat; `tests/unit/planning-personas.bats` fails first |
| checklist `skill:` lines | `tests/unit/agent-skills.bats` link test | W1 | a session fixing a finding; the test | a missing or dangling line fails the test |
| `skills/agent-*/SKILL.md` frontmatter `name`, `description` | Claude Code skill discovery in the plugin root; `install.sh` links for symlink installs | W5–W12, W19 | the Skill tool | a skill with no `description` never surfaces; the test fails |
| `vault/plans/2026-10-20-1934-agent-systems-lens.c3-run.md` | `checks/agent-systems-lens-C3.sh` | W18 | `bin/gate.sh verdict --run` | a missing file exits 2; too few confirmed findings, or no judge finding, exits 1 |

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W1 | personas/_shared/planning/agent-systems.md | create the lens with the six sections; Checklist holds exactly the 12 items in `## Lens checklist` below, each followed by one indented line `skill: skills/agent-<name>/SKILL.md · <url>`; Severity rubric copies `## Lens severity` below verbatim; Mandate copies `## Lens review rules` below verbatim; Bound analyzer gives stack detection commands for Prism, `laravel/ai` and `laravel/mcp` as examples | Write | at most 150 lines; links `personas/_shared/planning/README.md` | C1, C3 | `checks/agent-systems-lens-C1.sh` | DONE |
| W2a | personas/_shared/planning/README.md | add the `[[agent-systems]]` row; rewrite the intro at lines 14–17 to name three kinds: software, developer harness, product agent; point the `harness-engineer` and `security-architect` rows at it | Edit | one rule, one home | C1 | same as W1 | DONE |
| W2b | personas/_shared/planning/security-architect.md | replace the Mandate bullet `LLM risks: prompt injection, tool permissions, and the exfiltration path.` and the paragraph after it with one line handing product agent runs to `planning/agent-systems`; rewrite the severity lines on an agent with write or send tools and on authorization delegated to the model so they hand product agents over; drop the checklist item starting `Where untrusted content, private data and an outbound sink meet`; scope the item starting `Does each service and AI agent hold only the tools` to services | Edit | 11 checklist items remain; the words `trifecta`, `untrusted content` and `TPR` no longer appear | C1 | same as W1 | DONE |
| W2c | personas/_shared/planning/harness-engineer.md | scope the opening paragraph to developer harnesses and name `planning/agent-systems` for product agents; reword the judge items as a critic or gate judge inside the harness; reword the trifecta lines as a harness agent with private data, untrusted input and an outbound channel, without the word `trifecta` | Edit | 12 checklist items remain; the words `trifecta` and `TPR` no longer appear | C1 | same as W1 | DONE |
| W3 | personas/_resolution.md | §2.3: add `planning/agent-systems` first in the trigger list, seated when the product makes an LLM call at runtime for its users; narrow the `harness-engineer` trigger to developer tooling (commands, step files, hooks, critic prompts, `arch_profile: harness`); cut `or an AI agent with tools` from the `security-architect` trigger; §2: one line stating that a PROPOSE panel seats `planning/agent-systems` by the §2.3 condition when the pack's `use_shared` lists it | Edit | the trigger condition is written once, in §2.3 | C1 | `checks/agent-systems-lens-C1.sh` | DONE |
| W4 | personas/api-laravel.md | append `planning/agent-systems` to `use_shared` | Edit | no overlay block | C1 | read line 5 | DONE |
| W5 | skills/agent-shape/SKILL.md | create: rung ladder, three conditions for an agent, single writer, caps and exits, Laravel section | Write | ≤160 lines, ≤12000 bytes, description ≤300 characters | C2 | `checks/agent-systems-lens-C2.sh` | DONE |
| W6 | skills/agent-trust-boundaries/SKILL.md | create: Rule-of-Two table per run, six injection patterns, agent identity, approval bound to the exact action, injection regression tests with a fake model that obeys the attacker | Write | same as W5 | C2 | same as W5 | DONE |
| W7 | skills/agent-tools-mcp/SKILL.md | create: tool contract rules, exposing an API as MCP, consuming external MCP servers | Write | same as W5 | C2 | same as W5 | DONE |
| W8 | skills/agent-output-validation/SKILL.md | create: schema plus code validation, deterministic content checks, fail-closed retry rules, safe rendering | Write | same as W5 | C2 | same as W5 | DONE |
| W9 | skills/agent-knowledge-context/SKILL.md | create: entity card, whole knowledge base versus retrieval, recall@k, relevance threshold, example store selection, abstain and escalate | Write | same as W5 | C2 | same as W5 | DONE |
| W10 | skills/agent-evals/SKILL.md | create: error analysis, binary judges, TPR and TNR calibration, intervals and power, pass^k, low-acceptance triage | Write | same as W5 | C2 | same as W5 | DONE |
| W11 | skills/agent-self-improvement/SKILL.md | create: learning from operator sends, promotion gate with held-out set and power, online confirmation, rollback, poisoning control, optimizer limits | Write | same as W5 | C2 | same as W5 | DONE |
| W12 | skills/agent-runtime-ops/SKILL.md | create: agent identity and kill switch, budgets and caps, run record, resumable runs, erasure across AI stores | Write | same as W5 | C2 | same as W5 | DONE |
| W13 | vault/research/v-pm-planning-lenses/agent-systems-architecture.md | copy the architecture research record with `type: research` frontmatter, as in `vault/research/subagent-token-economics.md` | Write | record class; findings unedited | C3 | file exists | DONE |
| W14 | vault/research/v-pm-planning-lenses/agent-systems-security.md | copy the security research record with `type: research` frontmatter | Write | same as W13 | C3 | file exists | DONE |
| W15 | vault/research/v-pm-planning-lenses/agent-systems-quality.md | copy the quality research record with `type: research` frontmatter | Write | same as W13 | C3 | file exists | DONE |
| W16 | vault/_moc.md | add one research line for the `vault/research/v-pm-planning-lenses/` folder, naming the agent-systems records | Edit | one line | C1 | grep | DONE |
| W17 | checks/agent-systems-lens-C3.sh | rewrite to `## C3 parser rules` below; the run file is an optional first argument with default `vault/plans/2026-10-20-1934-agent-systems-lens.c3-run.md` | Write | bash, grep and sed only | C3 | `tests/unit/agent-systems-c3.bats` | DONE |
| W18 | vault/plans/2026-10-20-1934-agent-systems-lens.c3-run.md | spawn the finished lens once, tier medium, on the drafter plan and `~/workspace/recycling-api`; save the raw output with the agent run id | Agent | one spawn, no hand edits; read-only on recycling-api | C3 | `checks/agent-systems-lens-C3.sh` | DONE |
| W19 | install.sh | link `skills/` into `~/.claude/skills/` with the existing `link_tree` helper; run `prune_stale` for skills unconditionally, as for `output-styles/`; update the header comment at lines 2–3 | Edit | plugin installs unaffected | C2 | `tests/unit/install.bats` | DONE |
| W20 | vault-guide.md | §11: name `skills/` beside `commands/` and `output-styles/` in both install modes | Edit | one sentence | C1 | grep | DONE |
| W20b | INSTALL.md | name `~/.claude/skills/` where the file lists what `install.sh` never overwrites; add `ln -s ~/.claude/skills "$W/skills"` to the second-home recipe | Edit | two lines | C2 | grep | DONE |
| W27 | tests/unit/install.bats | add the count of `skills/*/` folders to the idempotence `expected`; test that a fresh install links `~/.claude/skills/agent-shape`; test that a dangling `~/.claude/skills/agent-ghost` link into `skills/` is pruned while a user's own link stays | Edit | existing tests keep passing | C2 | `./tests/run.sh tests/unit/install.bats` | DONE |
| W21 | tests/unit/planning-personas.bats | add `agent-systems` to `LENSES`; assert `planning/agent-systems` precedes `planning/harness-engineer` in §2.3; assert the words `trifecta` and `TPR` occur in no planning lens file except `agent-systems.md`; assert every `planning/<id>` in a pack `use_shared` resolves to a file; assert the `security-architect` trigger no longer names an AI agent with tools | Edit | existing tests unchanged | C1 | `checks/agent-systems-lens-C1.sh` | DONE |
| W22 | tests/unit/agent-skills.bats | create: every `skills/agent-*/SKILL.md` has `name` equal to its folder, a description ≤300 characters, ≤160 lines, ≤12000 bytes; every lens checklist item has exactly one existing `skill:` path; every skill is named by the lens; run the same checks on `tests/fixtures/agent-skills/` and expect each fail fixture to fail | Write | runs in the existing bats image | C2 | `checks/agent-systems-lens-C2.sh` | DONE |
| W23 | tests/fixtures/agent-skills/ | create fail fixtures: wrong `name`, no description, 161 lines, oversize bytes, checklist item with no `skill:` line, dangling skill path | Write | fixtures only | C2 | used by W22 | DONE |
| W24 | tests/unit/agent-systems-c3.bats and tests/fixtures/agent-systems-c3/ | create: a pass fixture with a multi-line check and a `path:141-143` range; fail fixtures for `check: none, could not run`, prose mentions of the grounding phrase, wrong PERSONA, no judge finding, and a check of backticked identifiers only; a no-argument run with no default file exits 2 | Write | fixtures only | C2 | `checks/agent-systems-lens-C2.sh` | DONE |
| W25 | tests/unit/plugin-install.bats | assert `skills/` sits at the plugin root | Edit | one line | C2 | same as W22 | DONE |
| W26 | checks/agent-systems-lens-C2.sh | run `tests/unit/agent-skills.bats` and `tests/unit/agent-systems-c3.bats` | Edit | exit 0, 1 or 2 | C2 | run it | DONE |

## Lens checklist

Each item names its concern and its skill. W1 writes them in this order, worded as yes or no questions.

| # | concern | question | skill |
|---|---------|----------|-------|
| 1 | shape | Does the design use the lowest rung its eval shows is enough, with one component writing state and the final output? | agent-shape |
| 2 | shape | Does every model loop, retry, tool call and run have a numeric cap, a deadline and a named exit? | agent-shape |
| 3 | trust | Does any run hold untrusted input, private data and an outbound or write channel without a human approving the exact action? | agent-trust-boundaries |
| 4 | trust | Is authorization enforced in code at each tool, deny by default, under the agent's own revocable identity? | agent-trust-boundaries |
| 5 | trust | Does each tool or MCP surface state its contract, bound its output, return actionable errors, and apply the same visibility rules as the REST API? | agent-tools-mcp |
| 6 | trust | Is every model output validated in code before use, failing closed, with checks for other users' personal data, forbidden phrases and links? | agent-output-validation |
| 7 | knowledge | Does the agent get a compact entity card and tools for live state, with whole knowledge base versus retrieval decided by size and measured by recall@k? | agent-knowledge-context |
| 8 | knowledge | Does the agent abstain or escalate when no knowledge supports an answer, using a relevance threshold in code? A threshold is a minimum score or overlap below which the tool returns nothing; a bare any-term match is not one. | agent-knowledge-context |
| 9 | quality | Has a human coded at least 50 real traces into a counted failure list before the metrics were chosen? | agent-evals |
| 10 | quality | Is every judge that gates work binary per failure mode and measured against the human who acts on the output, with TPR and TNR? | agent-evals |
| 11 | learning | Does a learned change ship only after a held-out set sized by power analysis, an online confirmation, a rollback path and a guard against poisoned examples? | agent-self-improvement |
| 12 | operations | Does each run leave a record of prompt version, model, tokens, cost and outcome inside a budget, and does user erasure reach every AI store? | agent-runtime-ops |

## Lens severity

- Deterministic controls are code validators, caps, relevance thresholds, authorization checks and approvals bound to the exact action. A missing deterministic control is MAJOR, unless a BLOCKER line below names it.
- Probabilistic controls are detectors, classifiers, prompt rules and delimiters. A missing probabilistic control is at most MINOR.
- A judge or promotion gate that gates work and was never measured against the human who acts on the output is MAJOR.
- A missing measurement or release step is MAJOR when it gates shipping or a learned change, and MINOR otherwise. These steps are recall@k, coded traces, a power-sized held-out set, an online confirmation and a rollback path.
- BLOCKER: one run holds all three trust parts, and no human approves the exact action.
- BLOCKER: authorization lives in a prompt or in tool visibility.
- BLOCKER: a user-reachable loop or spend has no cap.
- BLOCKER: another user's personal data can reach output, and no code check stops it.

## Lens review rules

- Raise one finding per missing part of a checklist item.
- Review the agent code the product runs today, even where the plan under review lists it as a non-goal. Target the finding at that code path.

## C3 parser rules

- A finding block starts at a line `- id:` and ends before the next `- id:` or a top-level key.
- The check field is the `check:` line plus every following line indented deeper than `- id:`, up to the next key of the block.
- A command is a backticked span whose content starts with a lowercase letter and contains a space.
- A `path:line` matches `[A-Za-z0-9_./~-]+\.[A-Za-z0-9]+:[0-9]+([-,][0-9]+)*`, with or without backticks.
- A block counts when its own `grounding:` is `confirmed` and its check field holds a command or a `path:line`.
- A block cites the judge when `judge_model` or `sendable_score` appears in its check or issue field.
- The file must hold `PERSONA: agent-systems`. Exit 0 needs 3 counted blocks, one of them citing the judge. A missing file exits 2.

## Rollback

Revert the branch commits. Every change is additive or a small edit to a lens, a test or `install.sh`. A symlink install that ran the new `install.sh` keeps dangling `~/.claude/skills/agent-*` links after the revert; re-running `install.sh` prunes them. No repo outside `~/workspace/vault` changes.

## Test plan

Bats contract tests in the existing Docker image (`./tests/run.sh`), unit level only. Fail fixtures live under `tests/fixtures/`. The lens itself is tested by one live review of a real plan (C3).

## Test design dossier

| partition | target | expected |
|---|---|---|
| skill `name` equals its folder | `tests/unit/agent-skills.bats` | pass |
| `name` differs from its folder, no description, 161 lines, over 12000 bytes, description over 300 characters | `tests/unit/agent-skills.bats` | fail |
| checklist item with no `skill:` line, or a path that does not exist | `tests/unit/agent-skills.bats` | fail |
| three confirmed findings with commands, one citing `judge_model` | `tests/unit/agent-systems-c3.bats` | pass |
| `check: none, could not run`; prose mentions of the grounding phrase; wrong PERSONA; no judge finding | `tests/unit/agent-systems-c3.bats` | fail |
| a trifecta item left in `security-architect.md` | `tests/unit/planning-personas.bats` | fail |

## Test backlog

| id | source | kind | target (exact path) | intent | priority | disposition |
|----|--------|------|---------------------|--------|----------|-------------|
| T1 | W21 | unit | tests/unit/planning-personas.bats | the new lens meets every planning lens contract | must | |
| T2 | W21 | unit | tests/unit/planning-personas.bats | `personas/_resolution.md` §2.3 seats `planning/agent-systems` | must | |
| T3 | W21 | unit | tests/unit/planning-personas.bats | only agent-systems holds the product-agent trifecta and judge checks | must | |
| T4 | W22 | unit | tests/unit/agent-skills.bats | skill frontmatter, line, byte and description caps hold, fail fixtures fail | must | |
| T5 | W22 | unit | tests/unit/agent-skills.bats | every checklist item names exactly one existing skill, and every skill is named | must | |
| T6 | W24 | unit | tests/unit/agent-systems-c3.bats | the C3 parser rejects each fail fixture and accepts the pass fixture | must | |
| T7 | W27 | unit | tests/unit/install.bats | a symlink install links each skill folder, prunes a removed one, and stays idempotent | must | |
| T8 | W25 | unit | tests/unit/plugin-install.bats | `skills/` sits at the plugin root | should | |

## Refs

- `personas/_shared/planning/README.md` — the lens contract, scale tiers and grounding rule this lens follows.
- `personas/_shared/planning/harness-engineer.md` — keeps developer harnesses; hands product agents to this lens.
- `vault/plans/2026-10-20-1934-agent-systems-lens.trail.md` — the process record for this plan.
- `vault/research/v-pm-planning-lenses/agent-systems-quality.md` — the source of the judge and learning checks the support drafter fails.
