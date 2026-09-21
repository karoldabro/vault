---
type: research
project: vault
slug: ai-code-slop
status: living
date_researched: 2026-09-21
tags: [research, architecture, code-quality]
---

# Why AI coding agents produce messy code

The best-supported causes are duplication instead of reuse, local correctness without a repository-wide view, and unbounded change volume. Missing conventions and security gaps are measured but vendor-reported. Layer violations, plan-less generation and error handling have no direct measurement, so the plan treats them as reviewer checks.

## Mechanisms

### M1 Duplication instead of reuse
Agents regenerate behaviour that already exists. In 617 crewAI pull requests (Python), agent redundancy scored 0.2867 against 0.1532 for humans, a 1.87x difference with p<0.001, from one repository (https://arxiv.org/html/2601.21276). GitClear reports copy/pasted lines rising from 8.3% to 12.3% between 2021 and 2024 across 211 million changed lines, without an AI/human split (https://www.gitclear.com/ai_assistant_code_quality_2025_research). The plan must contain a reuse map that names existing modules by path.
verified: primary

### M2 Local correctness without a global view
Generated code passes local checks and breaks cross-file contracts. One study found 67 structural failures; 97.0% evade mypy and tsc strict modes and 100% evade test suites and SAST tools. Cross-cutting tasks show a 44.6% failure incidence against 16.1% and 13.4% for simpler tasks. The study covers two models (GPT-4o, Claude 3.5 Sonnet) and 336 generations (https://arxiv.org/html/2607.08981v1). The plan must name every cross-file contract and boundary it touches.
verified: primary

### M3 Unbounded change volume
More generated code carries more architectural decay. Lines of code correlate with architectural smells at rho=0.94 (p<0.001) in one study of open models, and few-shot prompting did not improve hygiene (https://arxiv.org/html/2605.02741v1). Among 33,000 agent pull requests, rejected ones tend to be larger and touch more files (https://arxiv.org/html/2601.15195). The plan must state a size budget in files and lines.
verified: primary

### M4 Missing conventions (naming, readability)
AI-authored pull requests deviate from project style. CodeRabbit compared 320 AI-co-authored with 150 human pull requests: 10.83 against 6.45 issues per pull request, with readability 3x, formatting 2.66x and naming about 2x (https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report). Context files carry instructions that agents follow, although they raised inference cost by over 20% without improving success (https://arxiv.org/abs/2602.11988). CodeRabbit sells a review product, so treat the multipliers as vendor data. The plan should point at convention files and enforce style with linters.
verified: primary

### M5 Layer and boundary violations
No study measures logic placed in the wrong layer by name. Indirect evidence: static analysis of 10 Cursor-built projects (average 16,965 lines, 114 files) found 1,305 CodeScene and 3,193 SonarQube design issues, including framework best-practice violations (https://arxiv.org/abs/2604.06373). The cited counts match the source, but they do not isolate layer violations. The plan must assign each piece of logic to a layer, and a human must check that assignment.
verified: summary-only

### M6 Security blind spots
Models did not improve on security while improving on function. Veracode tested over 100 models: 45% of samples failed security tests, Java failed 72%, and security stayed flat across model sizes (https://www.veracode.com/blog/genai-code-security-report/). CodeRabbit reports up to 2.74x more security issues in AI pull requests (https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report). Both sources are vendors. The plan must list security-sensitive paths for human review and scanning.
verified: primary

### M7 Plan-less generation and scope drift
The effect of skipping a plan is asserted, not measured. Anthropic states that jumping straight to coding can produce code that solves the wrong problem (https://code.claude.com/docs/en/best-practices). Of 600 rejected agent pull requests, 23% duplicated existing work, 4% were unwanted features and 3% were incorrect implementations (https://arxiv.org/html/2601.15195). Another 38% closed without reviewer engagement, so these shares are not purely code causes. No source compares outcomes with and without a plan. The plan should state intent and out-of-scope items.
verified: summary-only

### M8 Error handling and over-engineering
The direction is unclear. CodeRabbit reports nearly 2x more error-handling gaps in AI pull requests (https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report). Anthropic warns that a reviewer prompted to find gaps causes extra abstraction layers and defensive code (https://code.claude.com/docs/en/best-practices). A per-model try/except study (https://arxiv.org/pdf/2604.12311) could not be opened as text, so its figures are omitted. The plan should require a human to confirm each new abstraction has two users.
verified: summary-only

## What a human reviews and what tools check

Tools check what a rule can express. Humans check what needs judgement. Passing CI is not evidence of coherence: in the M2 study, 100% of structural failures passed test suites and SAST tools (https://arxiv.org/html/2607.08981v1).

| Owner | Check |
|---|---|
| Tools | style, formatting, types, tests, security scans, duplication and complexity thresholds, contract diffs, reference resolution |
| Human | right problem, architecture fit, data model, earned abstractions, security-sensitive paths |

Anthropic advises a fresh-context reviewer that flags only gaps affecting correctness or stated requirements. It also states that hooks are deterministic while CLAUDE.md rules are advisory (https://code.claude.com/docs/en/best-practices).

## Artifacts that let a human understand code before it is written

This section is a synthesis, not a finding. No study ranks artifacts by comprehension per reading minute. Choose artifacts that expose decisions a reviewer can reject.

A one-page spec for a single feature, readable in about five minutes:
1. Intent and out-of-scope items, in 3-5 lines.
2. Reuse map: existing modules and utilities to call, by path. Counters M1.
3. Layer map: each piece of logic assigned to a layer, one line each. Counters M5.
4. Data-model delta: entities, fields, constraints and migration, as a table.
5. Contracts: signatures or schema snippets for every new boundary. Counters M2.
6. One sequence for the main path and one for a failure path.
7. Decisions, each with one rejected alternative, only where the design was uncertain.
8. Verification checks that prove done, plus a size budget in files and lines. Counters M3.

Skip the spec when one sentence describes the diff, as Anthropic advises (https://code.claude.com/docs/en/best-practices).

A two-page master plan across repos, with one feature spec per repo:
1. Goal, non-goals and one container-level diagram of the repos touched.
2. Sub-plan table: id, repo, depends-on, produces, done-check.
3. Contracts between repos, written first, each owned by one repo.
4. Shared data structures: owner repo, fields, invariants.
5. Migration order (expand, migrate, contract), each step reversible with a named rollback.
6. Rollout: deploy order, flags and the stop condition per step.

Each sub-plan references the contract instead of restating it. This ordering rests on engineering practice, not a measured result.

## Harness architecture limits

Anthropic publishes these limits. A script can check each one.

| Limit | Value | Source |
|---|---|---|
| CLAUDE.md size | target under 200 lines per file | https://code.claude.com/docs/en/memory |
| MEMORY.md load | first 200 lines or 25KB, whichever comes first | https://code.claude.com/docs/en/memory |
| SKILL.md body | under 500 lines | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices |
| Skill name | at most 64 characters; lowercase letters, numbers, hyphens; reserved words barred | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices |
| Skill description | non-empty, at most 1,024 characters, no XML tags, third person | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices |
| Reference depth | one level deep from SKILL.md | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices |
| Reference file over 100 lines | starts with a table of contents | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices |
| Contradictory rules | Claude may pick one arbitrarily | https://code.claude.com/docs/en/memory |

Counter-finding: context files did not generally improve task success and raised inference cost by over 20% on average. Repository overviews were not helpful, so derivable content has a cost and no measured benefit (https://arxiv.org/abs/2602.11988).

Two properties need an evaluation or judge, not a linter: whether removing a line causes a mistake, and whether two rules contradict.

## Does longer planning reduce rework

The evidence is weak. No controlled study shows that longer plans reduce rework in AI-assisted coding.

- An ablation over four models turned planning off under one configuration (128k context). The smallest model, Nemotron-3 30B, ended 68.6% of SWE-Bench runs before any edit. Larger models ended 15.6%, 1.4% and 2.0% of runs early. Planning cut cost about 30% for the 550B and Mistral 128B models (https://arxiv.org/html/2609.20804).
- The best agent scored 44.4% on SpecBench gap detection in specs, and the paper reports no human baseline (https://arxiv.org/html/2605.30314v1). A human must review the plan.
- Anthropic recommends planning for uncertain, multi-file or unfamiliar changes and skipping it for one-sentence diffs (https://code.claude.com/docs/en/best-practices).

Size the plan to the risk. A plan earns its reading cost when it decides something a reviewer could reject: layer, data model, contract or order.
