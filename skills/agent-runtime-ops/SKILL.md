---
name: agent-runtime-ops
description: Load when an LLM feature runs in production for users or gains write access. It covers the kill switch, audit log, rate limit, budgets and job limits, a run record with cost and prompt version, resumable runs, and erasure across every AI store.
---

# Agent runtime operations

## When to use

- An LLM feature is about to serve users, call the API with its own token, or write data.
- A feature stores user text for drafts, examples, embeddings, replay cases or logs.
- A review of `personas/_shared/planning/agent-systems.md` raises runtime operations: kill switch, audit, budgets, run records, durable runs or erasure.

Agent identity, the grant list, deny-by-default and the route sweep test live in `skills/agent-trust-boundaries/SKILL.md`.

## Rules

**Kill switch, audit and rate limit:**

- **Provide a write kill switch that an operator flips without a deploy.** A deploy takes too long to stop bad writes during an incident. https://goteleport.com/blog/owasp-top-10-agentic-applications
- **Log every mutating agent request, denials included, with identity, tool, argument hash and outcome.** Denied attempts are the first sign that someone is probing the agent. https://genai.owasp.org/llmrisk/llm062025-excessive-agency/
- **Rate-limit agent actions per identity.** The limit caps how many bad actions happen before someone notices. https://genai.owasp.org/llmrisk/llm062025-excessive-agency/

**Budget and limits:**

- **Check a per-user and a global budget before you dispatch each model call.** Without both, one user or one bug drains the provider account. https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/
- **Cap the input size before the call.** Oversized input raises cost and latency for every request behind it. https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/
- **Set a timeout and a retry count on every queued AI job.** A job without them can run or retry without end. https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/
- **Run AI jobs on a dedicated queue lane.** A spike in slow model calls then cannot starve core work. https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/
- **Alert on spend anomalies as well as on errors.** A runaway loop can succeed on every call and still empty the budget. https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/

**Run record and tracing:**

- **Write one run record per run with prompt version, model, input, output, cached and reasoning tokens, cost, latency and outcome.** Cost spikes and regressions stay invisible without per-run numbers. https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns
- **Version every prompt and store that version on each run.** Without the link you cannot tell which prompt produced a bad output. https://langfuse.com/docs/prompt-management/overview
- **Name trace spans and attributes after the OpenTelemetry GenAI conventions, and expect renames.** These conventions have status Development, so names can still change. https://github.com/open-telemetry/semantic-conventions-genai
- **Redact personal data in logged prompts and outputs, set a retention period, and restrict access to admins.** An unredacted prompt log becomes the data leak. https://genai.owasp.org/llmrisk/llm022025-sensitive-information-disclosure/
- **Pin each model to an exact id, and fail over to another provider only on provider faults.** An alias changes behaviour on a provider release, and failover on a validation error hides a real bug. https://laravel.com/docs/13.x/ai-sdk

**Durable runs:**

- **Persist run state after each step, and resume a failed run from the failed step.** A restart from scratch repeats cost and side effects. https://www.anthropic.com/engineering/multi-agent-research-system
- **Pin each run to the prompt and code version it started with.** A paused run that resumes under a new prompt produces output nobody tested. https://www.anthropic.com/engineering/multi-agent-research-system
- **Save the run and return when it waits for a human, and resume it through an API call.** A worker that blocks while it waits holds state in memory and loses it on restart. https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-07-contact-humans-with-tools.md

**Erasure and retention:**

- **Make user erasure delete or scrub the user's text in every AI store: drafts, example stores, embeddings, replay fixtures, run records and logs.** Erasure rights apply to the inputs and outputs of an AI system. https://datenschutz-hamburg.de/fileadmin/user_upload/HmbBfDI/Datenschutz/Informationen/240715_Discussion_Paper_Hamburg_DPA_KI_Models.pdf
- **Choose provider data retention on purpose and write it down per provider.** Default retention is about 30 days, and stateful provider features keep data longer. https://developers.openai.com/api/docs/guides/your-data

## Steps

1. Add the write kill switch, read at request time. Test it on and off.
2. Add the audit log for allowed and denied requests.
3. Set the per-user budget, the global budget, the input cap, job timeouts and retries. Route AI jobs to their own queue lane.
4. Add a spend alert with a threshold taken from a normal week of spend.
5. Create the run record table with the fields in the run record rule. Write a row on success, failure and cap breach.
6. Add a version column to stored prompts and a foreign key from each run to it.
7. Persist state after each step. On resume, skip completed steps and load the pinned prompt version.
8. List every store that holds user text. Add each one to the erasure routine, and give each a retention period.

Run record attributes from the OpenTelemetry GenAI conventions:

| attribute | holds |
|---|---|
| `gen_ai.operation.name` | `chat`, `invoke_agent` or `execute_tool` |
| `gen_ai.provider.name` | the model provider |
| `gen_ai.request.model` | the pinned model id |
| `gen_ai.agent.name`, `gen_ai.agent.version` | the agent and its prompt version |
| `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens` | token counts; store cached and reasoning tokens in your own columns |

Content capture is opt-in under the conventions. Leave it off unless the content is redacted.

## Checks

- A test asserts 403 on a write with the kill switch off and success with it on.
- A test sends a forbidden request and asserts an audit row with outcome `denied`.
- A test exhausts the budget and asserts the fake model received zero calls.
- A listing of AI job classes that lack a timeout prints nothing.
- A test runs one faked call and asserts a run record row with every field from the run record rule filled.
- A test fails step 2 of a run, re-dispatches it, and asserts the step 1 model call count stayed at one.
- An erasure test seeds the user's text in each AI store, runs erasure, and asserts no store still contains it.
- `grep -rn 'gen_ai\.' <source dir>` finds the attributes on the tracing wrapper.

## Laravel

Detect the stack before you apply anything here: `composer show prism-php/prism laravel/ai laravel/mcp laravel/horizon laravel/sanctum 2>/dev/null`.

- **Kill switch:** after `php artisan config:cache`, an `.env` change needs a re-cache before it takes effect. A database setting flips without that step.
- **Budgets and rate limits:** define `RateLimiter::for('ai', ...)` keyed by user, and call `RateLimiter::attempt()` before dispatch for the budget.
- **Queues and Horizon:** put AI jobs on their own queue with `onQueue('ai')`, and give it its own Horizon supervisor and process count. Set `$timeout`, `$tries` and `$maxExceptions` on each job. Keep `retry_after` in `config/queue.php` above the longest job `$timeout`, or a second worker picks up a running job.
- **Usage:** laravel/ai exposes `$response->usage->inputTokens`, `cacheReadInputTokens` and `reasoningTokens`. For Prism, read the field names from `grep -rn 'class Usage' vendor/prism-php/prism/src`.
- **Failover:** laravel/ai fails over on `FailoverableException`. Keep validation errors out of that path.
- **Retention:** add the `Prunable` trait to run, draft and log models, and schedule `model:prune`.
- **Tests:** fake the model with `Prism::fake([...])` or `Agent::fake()->preventStrayPrompts()`, then assert call counts.

## Sources

- OWASP Top 10 for Agentic Applications 2026, summary (Teleport): https://goteleport.com/blog/owasp-top-10-agentic-applications
- OWASP LLM06 Excessive Agency: https://genai.owasp.org/llmrisk/llm062025-excessive-agency/
- OWASP LLM10 Unbounded Consumption: https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/
- OWASP LLM02 Sensitive Information Disclosure: https://genai.owasp.org/llmrisk/llm022025-sensitive-information-disclosure/
- AI agent orchestration patterns (Microsoft): https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns
- Langfuse prompt management: https://langfuse.com/docs/prompt-management/overview
- OpenTelemetry GenAI semantic conventions: https://github.com/open-telemetry/semantic-conventions-genai
- How we built our multi-agent research system (Anthropic): https://www.anthropic.com/engineering/multi-agent-research-system
- 12-factor agents, factor 7, contact humans with tools: https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-07-contact-humans-with-tools.md
- Hamburg DPA discussion paper on LLMs: https://datenschutz-hamburg.de/fileadmin/user_upload/HmbBfDI/Datenschutz/Informationen/240715_Discussion_Paper_Hamburg_DPA_KI_Models.pdf
- EDPB Opinion 28/2024, summary (CMS): https://cms.law/en/int/legal-updates/edpb-opinion-28-2024-key-takeaways-on-processing-personal-data-in-the-context-of-ai-models
- OpenAI data controls: https://developers.openai.com/api/docs/guides/your-data
- Anthropic data retention: https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data
- Laravel AI SDK: https://laravel.com/docs/13.x/ai-sdk
