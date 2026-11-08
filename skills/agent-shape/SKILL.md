---
name: agent-shape
description: Load when you design or change an LLM feature a product runs for its users. It picks the simplest design that passes its eval, assigns one writer, and sets caps, deadlines and exits for every loop, retry and tool call.
---

# Agent shape

## When to use

- You add an LLM call to a product feature: a support reply drafter, a content moderator, an MCP server over the API, or a write-capable agent token.
- You add a loop, a tool, a second agent, a judge or a retry to an existing LLM feature.
- A review of `personas/_shared/planning/agent-systems.md` raises the design shape, the writer count or the caps.

## Rules

- **Start at rung 1 and climb one rung only when an eval shows the lower rung fails.** Each rung adds cost, latency and compounding errors. https://www.anthropic.com/engineering/building-effective-agents
- **Build an autonomous agent only when the task needs nuanced judgement, has rules too complex to maintain, or reads heavy unstructured input.** Outside these three conditions, code or a fixed chain does the job for less. https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf
- **Keep deterministic code around the model and let the model choose only the next step.** A prompt with a bag of tools in a loop rarely gets past demo quality. https://github.com/humanlayer/12-factor-agents
- **Let exactly one component write state and the final output.** Two writers make conflicting implicit decisions that nobody reconciles. https://cognition.com/blog/multi-agents-working
- **Run reads in parallel only when each branch returns to the single writer or writes to its own key.** Parallel branches that share a key overwrite each other. https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/
- **Give a judge or reviewer the output and the rules, and withhold the author's reasoning.** A judge that reads the author's context inherits the author's blind spots. https://cognition.com/blog/multi-agents-working
- **Give each agent one job of 3 to 10 steps, and 20 steps at most.** A longer agent grows its context and loses focus. https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-10-small-focused-agents.md
- **Give each agent the fewest tools it needs, with no two tools covering the same action.** If an engineer cannot say which tool applies, the model cannot either. https://www.anthropic.com/engineering/writing-tools-for-agents
- **Split one agent into several only for overlapping tools, a prompt full of if-then branches, or separate security boundaries.** Every extra agent adds coordination cost and inter-agent failure modes. https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns
- **Set a numeric cap on steps, tokens, wall-clock time and cost for every loop, retry, tool call and run.** Step repetition and unknown stop conditions are two of the most frequent multi-agent failure modes. https://arxiv.org/html/2503.13657
- **Name the exit for every cap: escalate to a human, return a flagged result, or fail closed with no side effect.** A cap without a defined exit leaves the run in an unknown state. https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns
- **Set each cap from measured run lengths, and log every breach.** A cap chosen before analysis cuts the longest legitimate sessions, which are often the most valuable. https://www.elastic.co/blog/building-ai-agents-elasticsearch-platform
- **Make every side effect idempotent, or run it after the last point that can retry or resume.** A queue retry or a resume re-runs the step and sends or writes twice. https://docs.langchain.com/oss/python/langgraph/interrupts
- **End every multi-step pipeline with a check of the output against the task objective.** Missing or wrong verification is a frequent cause of failed multi-agent runs. https://arxiv.org/html/2503.13657

## Steps

A rung is one level of design complexity. Each rung below adds autonomy over the one above it.

| rung | shape | fits when |
|---|---|---|
| 1 | single model call | one input maps to one output |
| 2 | fixed chain | the steps are known in advance; code checks the result between steps |
| 3 | router | inputs fall into distinct classes; each class gets its own prompt and tools |
| 4 | evaluator-optimizer | written acceptance criteria exist and revision measurably helps; it has a round cap and a fallback |
| 5 | orchestrator-workers | subtasks depend on the input and cannot be listed in advance |
| 6 | autonomous agent | the model picks each next step from its tools until a stop condition fires |

1. Write the task as input, output and acceptance criteria in the design document.
2. Build rung 1 and run it on 20 to 50 real cases; `skills/agent-evals/SKILL.md` gives the method.
3. If rung 1 fails, name the failing case class, climb one rung, and rerun the same cases.
4. Record each rung tried and its eval result in the design document.
5. Before rung 6, write which of the three autonomous-agent conditions in the rules holds. If none holds, stop at rung 5 or lower.
6. List every component with its job, its tools, and whether it reads or writes. Confirm one writer of state and of the final output.
7. Fill the cap table below for every loop, retry, tool call and run.
8. For every side effect, name its idempotency key, or show that it runs after the last retry point.
9. Write one test per cap that forces the breach and asserts the named exit.

| component | max steps | max tokens | wall clock | max cost | on breach |
|---|---|---|---|---|---|
| `<loop, retry, tool call or run>` | `<n>` | `<n>` | `<seconds>` | `<currency>` | escalate · flag · fail closed |

## Checks

- A test with a fake model that always requests another tool call asserts the loop stops at the step cap and takes the named exit.
- A test with a judge that always fails asserts escalation or a warning flag after the round cap, and no further model call.
- A test dispatches the same job twice and asserts one side effect.
- A test asserts the exact tool name list per agent, so an added tool fails until someone reviews it.
- A grep for write calls in reader or worker components returns nothing, for example `grep -rnE -- '->save\(|::create\(|->update\(' <worker dirs>`.
- Every model call site sets a step, token and time limit: list the call sites and compare them against the cap table.

## Laravel

Detect the stack before you apply anything here: `composer show prism-php/prism laravel/ai laravel/mcp 2>/dev/null`. Then list call sites with `grep -rnE 'Prism::|Agent::|Mcp::' app routes`.

- **Prism PHP:** a call with tools needs `withMaxSteps(n)`. Add `withMaxTokens(n)` and `withClientOptions(['timeout' => s])` on the same chain. Check: `grep -rn 'Prism::text()' app` and confirm all three on each chain.
- **laravel/ai:** cap an agent with `#[MaxSteps]` and `#[Timeout]`. Stop on tokens with per-step middleware, for example `Stop::unless(fn ($step) => $step->usage->inputTokens < 50_000)`.
- **laravel/mcp:** each tool `handle()` serves one call, and the client owns the loop. Keep every write behind one service class that all tools call.
- **Queues and Horizon:** job limits and `retry_after` live in `skills/agent-runtime-ops/SKILL.md`.
- **Idempotency:** use `ShouldBeUnique` with a `uniqueId()`, or a unique idempotency key column checked inside the same transaction as the write.
- **Tests:** fake the model with `Prism::fake([...])` or `Agent::fake()->preventStrayPrompts()`. Never call a live provider from the suite.

## Sources

- Building effective agents (Anthropic): https://www.anthropic.com/engineering/building-effective-agents
- A practical guide to building agents (OpenAI): https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf
- 12-factor agents (HumanLayer): https://github.com/humanlayer/12-factor-agents
- 12-factor agents, factor 10, small focused agents: https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-10-small-focused-agents.md
- Multi-agents: what's actually working (Cognition): https://cognition.com/blog/multi-agents-working
- How and when to build multi-agent systems (LangChain): https://www.langchain.com/blog/how-and-when-to-build-multi-agent-systems
- Developer's guide to multi-agent patterns in ADK (Google): https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/
- Writing effective tools for agents (Anthropic): https://www.anthropic.com/engineering/writing-tools-for-agents
- AI agent orchestration patterns (Microsoft): https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns
- Why do multi-agent LLM systems fail? (MAST): https://arxiv.org/html/2503.13657
- 1 year and 1 million messages (Elastic): https://www.elastic.co/blog/building-ai-agents-elasticsearch-platform
- LangGraph interrupts: https://docs.langchain.com/oss/python/langgraph/interrupts
- Laravel AI SDK: https://laravel.com/docs/13.x/ai-sdk
- Laravel MCP: https://laravel.com/docs/12.x/mcp
- Prism tools and function calling: https://prismphp.com/core-concepts/tools-function-calling.html
