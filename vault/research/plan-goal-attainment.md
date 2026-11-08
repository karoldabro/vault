---
type: research
project: vault
slug: plan-goal-attainment
status: living
date_researched: 2026-11-08
tags: [research, planning]
---

# How planning frameworks make finished tasks add up to the goal

## Findings

Every surveyed framework with a goal mechanism checks it with a model, not with code. None publishes a measured goal-attainment rate.

1. Goal-backward verification after execution is common practice. GSD's verifier states "Task completion ≠ Goal achievement" and checks truths, then artifacts, then wiring ([gsd-verifier.md](https://github.com/gsd-build/get-shit-done/blob/main/agents/gsd-verifier.md)).
2. Goal-backward review of the plan before execution also exists. GSD's plan-checker verifies plans "WILL achieve the phase goal" across twelve dimensions ([gsd-plan-checker.md](https://github.com/gsd-build/get-shit-done/blob/main/agents/gsd-plan-checker.md)).
3. Silent scope reduction is the named, recurring failure. GSD calls it "the most insidious failure mode" and makes it an automatic blocker ([gsd-plan-checker.md](https://github.com/gsd-build/get-shit-done/blob/main/agents/gsd-plan-checker.md)).
4. Our "wire five cases; append rows for the rest" matches GSD's blocked phrases: "basic version", "skip for now", "will be wired later" ([gsd-plan-checker.md](https://github.com/gsd-build/get-shit-done/blob/main/agents/gsd-plan-checker.md)).
5. Model-written coverage reports hide skipped items. A spec-kit bug shows `/converge` reported "converged" after checking 4 of 16 acceptance scenarios ([spec-kit #3752](https://github.com/github/spec-kit/issues/3752)).
6. A failing goal check should create new work, not only a report. GSD `--gaps`, spec-kit `/converge` and OpenHands `run_goal` all turn missing items into tasks ([planner-gap-closure.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/planner-gap-closure.md), [converge.md](https://github.com/github/spec-kit/blob/main/templates/commands/converge.md), [OpenHands goal loop](https://docs.openhands.dev/sdk/guides/convo-goal.md)).
7. A self-stated "chance of success" is unreliable. Agents that succeed 22% of the time predicted 77% ([arXiv 2602.06948](https://arxiv.org/abs/2602.06948)).
8. The same study found bug-finding framing gave the best calibration ([arXiv 2602.06948](https://arxiv.org/abs/2602.06948)).
9. Anthropic's harness enumerates the whole scope up front and freezes it. Over 200 features start `passes: false`; coding agents may change only that field ([effective harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)).
10. Anthropic's later harness agrees "done" before each sprint. A generator and a skeptical evaluator negotiate testable criteria; sprint 3 had 27 ([harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps)).

Evidence quality is weak across the field:

- Anthropic reports a qualitative win at 20x cost: $200 and 6 hours against $9 and 20 minutes solo ([harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps)).
- Devin's green confidence gave twice the merged-PR rate of red ([Devin 2.1](https://cognition.ai/blog/devin-2-1)).
- MetaGPT's executable-feedback loop added 4.2% Pass@1 on HumanEval ([arXiv 2308.00352](https://arxiv.org/abs/2308.00352)). That measures function-level tasks, not multi-session plans.

## Our five mechanisms against practice

| # | Our mechanism | Status | Closest prior art |
|---|---|---|---|
| 1 | One success criterion is the goal, decidable by a command | Common in parts; a single designated goal command is unusual | Anthropic per-feature `steps`; OpenHands objective "should be verifiable"; ATDD acceptance test |
| 2 | Goal-fit reviewer: premortem, chance, runtime, unowned work | Premortem and goal-backward review are common; a numeric chance is risky | GSD plan-checker; Devin confidence; GSD check 8b command latency |
| 3 | Goal tracer names an owning session per prerequisite | Common as a model check; novel only if checked by script | GSD requirement coverage and ORPHANED flag; spec-kit `/analyze` coverage table |
| 4 | Goal command runs at plan close | Common; ours is stronger because it runs a command, not a model | GSD `/audit-milestone`; spec-kit `/converge`; superpowers whole-branch review |
| 5 | Re-check goal when a session changes scope | Common as a failure lesson; GSD added it after an exploit | [GSD #1418](https://github.com/gsd-build/get-shit-done/issues/1418); Kiro re-analysis after edits |

## Framework table

| Name | Mechanism tying tasks to goal | Checked by | When | Evidence | Source URL |
|---|---|---|---|---|---|
| GSD verifier | Goal-backward: truths, then artifacts, then key links. Roadmap criteria cannot be reduced by plan `must_haves`. Runs 2-4 behavioural spot-check commands. | Model, with `gsd-sdk` queries | After each phase | None published; failures in [#1245](https://github.com/gsd-build/get-shit-done/issues/1245), [#1381](https://github.com/gsd-build/get-shit-done/issues/1381) | https://github.com/gsd-build/get-shit-done/blob/main/agents/gsd-verifier.md |
| GSD plan-checker | Twelve dimensions: requirement coverage, key links planned, scope-reduction phrase scan (blocker), automated verify per task, latency. Max 3 revision loops. | Model | Before execution | None published | https://github.com/gsd-build/get-shit-done/blob/main/agents/gsd-plan-checker.md |
| GSD milestone audit | Three-source cross-reference: requirements table, phase verifications, summary frontmatter. Orphans count as unsatisfied. Integration checker assumes every cross-phase link is broken. | Model | Milestone close | None published | https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/workflows/audit-milestone.md |
| GSD gap closure | Verification `gaps` become new plans, each with `<verify>` and `<done>`. | Model | After failed verification | None published | https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/references/planner-gap-closure.md |
| spec-kit `/analyze` | Inventory of FR-### and SC-###. Maps tasks to requirements. Zero-coverage requirement is CRITICAL. Read-only. | Model | After `/tasks`, before `/implement` | None published | https://github.com/github/spec-kit/blob/main/templates/commands/analyze.md |
| spec-kit `/converge` | Assesses code against spec, plan and tasks. "Completion claims are not evidence." Appends unbuilt work as tasks. | Model | After `/implement` | Bug: under-counted scenarios ([#3752](https://github.com/github/spec-kit/issues/3752)) | https://github.com/github/spec-kit/blob/main/templates/commands/converge.md |
| spec-kit checklists | "Unit tests for English": test requirement quality, not implementation. | Model | Before planning | None published | https://github.com/github/spec-kit/blob/main/templates/commands/checklist.md |
| superpowers | Plan self-review: point each spec requirement to a task. Per-task spec-compliance review, then a final whole-branch review. | Model | Plan write; each task; end | None published | https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md |
| superpowers verification | "No completion claims without fresh verification evidence." Name the command, run it, read output. | Model discipline | Before any done claim | None published | https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md |
| BMAD retrospective | Epic verdict against Requirements and Done-when. Any unfinished ticket forces Rejected, from `tickets.py status`. | Model verdict; script for ticket state | Epic close | None published | https://github.com/bmad-code-org/BMAD-METHOD/blob/main/skills/bmad-retrospective/references/acceptance-verdict.md |
| claude-task-master | Parse-PRD prompt says "do not discard" explicit requirements. Each task carries a `testStrategy`. No end-goal check found. | Model | Task generation | None published | https://github.com/eyaltoledano/claude-task-master/blob/main/src/prompts/parse-prd.json |
| Agent OS v3 | Retired implementation and verification phases; defers specs to plan mode. No goal mechanism. | None | None | Changelog only | https://github.com/buildermethods/agent-os/blob/main/CHANGELOG.md |
| Kiro analyze requirements | Cross-requirement reasoning finds conflicts, vague terms, missing boundaries. Method undisclosed. | Undisclosed | After requirements; after edits | None published (docs only) | https://kiro.dev/docs/specs/analyze-requirements/ |
| Kiro correctness | Properties derived from EARS requirements; property-based tests trace to requirement and task. Optional, IDE-only. | Code (generated tests) | On user request | None; "not formal verification" (docs only) | https://kiro.dev/docs/specs/correctness/ |
| Tessl spec-as-source tile | Spec carries file `targets` and `[@test]` links; rebuild regenerates code then runs spec-verify. | Script plus model | After regeneration | Review calls regeneration non-deterministic | https://tessl.io/registry/spec-driven-devlopment/spec-as-source/files/skills/spec-rebuild/SKILL.md |
| Factory Specification Mode | Spec with acceptance criteria and plan; user approves before code. No post-run goal check documented. | Human | Before code | None (docs only) | https://docs.factory.ai/cli/user-guides/specification-mode |
| Devin | Confidence score at session start and after the plan; asks questions below green. | Model | Planning | Green gives 2x merged-PR rate | https://cognition.ai/blog/devin-2-1 |
| OpenHands `run_goal` | Separate judge LLM returns `score`, `complete`, `missing`; loop re-prompts with `missing`, cap 10. | Model (independent) | After each inner run | None published | https://docs.openhands.dev/sdk/guides/convo-goal.md |
| OpenHands critic | 4B classifier scores trajectory success during the run; low score triggers refinement. Experimental. | Trained model | During run | Model card only | https://huggingface.co/OpenHands/openhands-critic-4b-v1.0 |
| MetaGPT | SOP roles; QA engineer writes tests and retries up to 3 times. | Code (tests) | Per task | +4.2% Pass@1 HumanEval | https://arxiv.org/abs/2308.00352 |
| GPT-Pilot | Tech Lead states how a human checks each task; human reviews each task. | Human | Per task | None (README only) | https://github.com/Pythagora-io/gpt-pilot |
| Anthropic harness 1 | Initializer writes 200+ end-to-end features as JSON, all `passes: false`. Agents may only flip `passes`. | Model with browser tests | Per session | Qualitative only | https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents |
| Anthropic harness 2 | Planner writes high-level spec. Sprint contracts agreed before code. Evaluator tests via Playwright with hard thresholds; later one pass at end. | Model (separate, tuned skeptical) | Before and after each sprint | 20x cost, better output; no solo baseline for DAW | https://www.anthropic.com/engineering/harness-design-long-running-apps |
| ATDD | Acceptance tests written before the functionality, from the user's view. | Code | Before build | None on the page | https://www.agilealliance.org/glossary/atdd/ |
| Walking skeleton | Tiny end-to-end implementation linking main components, built first. | Code | Project start | Secondary sources only | https://learnagilepractices.substack.com/p/first-steps-in-code-the-significance |
| Shape Up | Fixed appetite, variable scope. Circuit breaker kills overruns. Scopes tracked on hill charts. Scope hammering cuts deliberately. | Human | Shaping; build; end | Practitioner book | https://basecamp.com/shapeup/1.2-chapter-03#setting-the-appetite |
| Premortem | Imagine the project failed; list causes. | Human | Planning | About 30% more reasons; secondary sources only | https://comprobo24.github.io/assignments/performing_a_project_premortem.pdf |
| Agentic calibration | Agents overestimate their own success; bug-finding framing calibrates best. | Study | Pre and post execution | 77% predicted vs 22% actual | https://arxiv.org/abs/2602.06948 |

Supporting Shape Up chapters: [circuit breaker](https://basecamp.com/shapeup/2.2-chapter-08#the-circuit-breaker), [map the scopes](https://basecamp.com/shapeup/3.3-chapter-12), [hill charts](https://basecamp.com/shapeup/3.4-chapter-13), [scope hammering](https://basecamp.com/shapeup/3.5-chapter-14#scope-hammering).

### Failure reports

- [GSD #1418](https://github.com/gsd-build/get-shit-done/issues/1418): the model moved roadmap criteria into a `<deferred>` section. The checker compared model-written context to model-written plans, so phases closed COMPLETE.
- [GSD #1245](https://github.com/gsd-build/get-shit-done/issues/1245): verification checked structure only. Hardcoded-empty props and placeholder tabs passed.
- [GSD #1381](https://github.com/gsd-build/get-shit-done/issues/1381): verification passed in three projects while the database schema was never pushed.
- [GSD #1495](https://github.com/gsd-build/get-shit-done/issues/1495): plans created functionality no path could reach.
- [GSD #2092](https://github.com/gsd-build/get-shit-done/issues/2092): the planner used "too complex" and time framing to justify cutting features.
- [spec-kit #3752](https://github.com/github/spec-kit/issues/3752): `/converge` declared convergence without per-scenario denominators. A second pass found a HIGH gap.

## What we lack

Open work, in priority order. Each item names the mechanism it changes.

1. **Run the goal command red at plan open.** Add to #1 and #4.
   - Action: the first session writes the goal command and records it failing. The last session records it passing.
   - Source: ATDD tests precede functionality ([Agile Alliance](https://www.agilealliance.org/glossary/atdd/)); GSD "Wave 0" creates tests first ([gsd-plan-checker.md](https://github.com/gsd-build/get-shit-done/blob/main/agents/gsd-plan-checker.md)).
   - Verification: the plan holds a red run log before session 2 starts.
2. **Scope-reduction phrase scan as a script.** Add to #2 and #5.
   - Action: grep session briefs for "for the rest", "append rows", "later", "basic", "v1", "placeholder", "stub". Block on any match without an owner.
   - Source: GSD Dimension 7b ([gsd-plan-checker.md](https://github.com/gsd-build/get-shit-done/blob/main/agents/gsd-plan-checker.md)).
   - Verification: the scan flags the tablet plan's "append rows for the rest".
3. **Script-checked ownership table with denominators.** Replace the model-only part of #3.
   - Action: the tracer emits rows of prerequisite, owning session, check command. A script fails on any row without an owner.
   - Action: the script prints `owned/total` computed from the enumerated case list, not from the model.
   - Source: spec-kit asks for artifact-derived `checked/total` ([#3752](https://github.com/github/spec-kit/issues/3752)); GSD flags ORPHANED requirements ([audit-milestone.md](https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/workflows/audit-milestone.md)).
   - Verification: 580 unowned of 600 tablet cases yields a non-zero exit.
4. **Enumerate and freeze the goal's case list.** Add to #5.
   - Action: write every case as a row with a pass field; sessions may flip only that field.
   - Source: Anthropic's JSON feature list ([effective harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)).
   - Verification: a diff check rejects edits to any field except `passes`.
5. **Gap-closure loop at plan close.** Add to #4.
   - Action: a failing goal command emits new sessions from the failing cases. Cap the loop, then escalate to the operator.
   - Source: GSD `--gaps`; spec-kit `/converge`; OpenHands `run_goal` cap of 10 (URLs above).
   - Verification: a forced failure produces a new session brief.
6. **Replace the numeric "chance" with a bug-hunt.** Change #2.
   - Action: the goal-fit reviewer lists ways the goal command still fails after all sessions pass. Report a chance only alongside that list.
   - Source: agents predicted 77% against 22% actual; bug-finding framing calibrated best ([arXiv 2602.06948](https://arxiv.org/abs/2602.06948)).
   - Source: Anthropic tuned its evaluator to stop approving issues it had found ([harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps)).
   - Verification: compare stated chance to goal-command outcome over closed plans.
7. **Runtime as an appetite with a circuit breaker.** Add to #2.
   - Action: the operator sets a maximum goal-command runtime. The reviewer measures a sample and extrapolates; exceeding the budget forces an explicit cut.
   - Source: Shape Up appetite and circuit breaker ([chapter 3](https://basecamp.com/shapeup/1.2-chapter-03#setting-the-appetite), [chapter 8](https://basecamp.com/shapeup/2.2-chapter-08#the-circuit-breaker)); GSD warns on checks over 30 seconds.
   - Verification: the plan states measured seconds per case times case count.
8. **Cross-session integration check.** Add to #4.
   - Action: before close, a reviewer assumes every session-to-session link is broken until traced end to end.
   - Source: GSD integration checker ([gsd-integration-checker.md](https://github.com/gsd-build/get-shit-done/blob/main/agents/gsd-integration-checker.md)).
   - Verification: the report lists each producer-consumer pair with evidence.

## Unresolved

- No source measures plan-level goal attainment for any framework. All effectiveness claims above are qualitative or function-level.
- Kiro, Devin, Factory and Tessl internals are closed. Their rows rest on docs or vendor posts, not prompt files.
- Factory's post-approval verification is undocumented ([specification mode](https://docs.factory.ai/cli/user-guides/specification-mode)).
- Kiro does not disclose whether requirement analysis uses a model or formal reasoning ([analyze requirements](https://kiro.dev/docs/specs/analyze-requirements/)).
- BMAD's current repo replaced earlier readiness and trace workflows. Older versions were not examined ([BMAD tree](https://github.com/bmad-code-org/BMAD-METHOD)).
- The GSD issues are closed. Whether each fix works was not tested; only the current prompt text was read.
- The premortem 30% figure and Cockburn's walking-skeleton wording come from secondary sources ([premortem PDF](https://comprobo24.github.io/assignments/performing_a_project_premortem.pdf)).
- GPT-Pilot details come from the README alone ([gpt-pilot](https://github.com/Pythagora-io/gpt-pilot)).
