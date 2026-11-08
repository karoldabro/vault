---
type: research
project: vault
slug: agent-systems-architecture
status: snapshot
date_researched: 2026-10-20
tags: [research, agents]
---

# Architecture and scoping of API-embedded LLM agents

Scope: product agents that run inside a Laravel API (support drafter, idea generator, moderator, MCP server, write-capable agent token). Not developer tooling. Research date 2026-10-20.

## Open questions / contradictions

1. **Multi-agent: helps or hurts.** Anthropic reports a lead+subagent research system beat a single agent by 90.2% at about 15x chat tokens (https://www.anthropic.com/engineering/multi-agent-research-system). Cognition said in 2025 that multi-agent "only results in fragile systems" (https://cognition.com/blog/dont-build-multi-agents). Reconciliation, now shared by LangChain and Cognition's own 2026 follow-up: parallel **reads** are fine, **writes stay single-threaded**, and one agent writes the final output (https://www.langchain.com/blog/how-and-when-to-build-multi-agent-systems, https://cognition.com/blog/multi-agents-working). Still unresolved: whether a reviewer should share context with the writer. Cognition says its reviewer works best with **no** shared context. Cognition 2025 says always share full traces. Both are Cognition. The difference is role: share context between agents that both act; isolate an agent that judges.
2. **When to split one agent into several.** OpenAI says split when tools overlap or the prompt fills with if-then-else branches. It notes ">15 distinct tools" can work while "<10 overlapping tools" can fail (https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf, p.16). Microsoft adds a third reason: separate security boundaries (https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns). 12-factor says keep each agent at 3-10 steps, 20 at most (https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-10-small-focused-agents.md). No source gives a measured threshold. A reviewer needs a project rule.
3. **Declarative graph vs code-first control flow.** OpenAI argues declarative graphs "become cumbersome" (guide p.20). LangGraph and Google ADK build on explicit graphs and workflow agents. 12-factor says own your control flow in plain code. For a Laravel API the code-first position wins by default: jobs, pipelines and state machines already exist.
4. **Retrieval: pre-load vs just-in-time.** Anthropic recommends a hybrid (https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents). 12-factor factor 13 says pre-fetch what you will likely need. Elastic measured that tangential retrieval (8.15/10) scores worse than **no** retrieval (9.18/10) (https://www.elastic.co/blog/building-ai-agents-elasticsearch-platform). Open: no source says where the relevance threshold should sit. It needs a replay eval per agent.
5. **Prompts in code vs prompt registry.** Langfuse argues prompts should deploy without engineering (https://langfuse.com/docs/prompt-management/overview). 12-factor factor 2 says own your prompts as code. Both agree on versioning and linking each run to a prompt version. They disagree on who may change a prompt without review. The project must decide; a DB-stored prompt row (as `ai_prompts` already is) needs a version column and a trace link either way.
6. **Guardrail classifiers vs architectural limits.** OpenAI recommends layered classifiers (relevance, jailbreak, PII) (guide p.25-27). Simon Willison calls a 95% catch rate "a failing grade" for injection (https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/). Meta's Rule of Two says pick at most two of: untrusted input, sensitive data, external effect (https://ai.meta.com/blog/practical-ai-agent-security/). Consensus: classifiers reduce noise; only capability removal or a human gate stops injection.
7. **OpenTelemetry GenAI conventions are not stable.** Agent spans (`create_agent`, `invoke_agent`, `execute_tool`) are marked Development and have moved to a separate repo (https://github.com/open-telemetry/semantic-conventions-genai). Adopt the attribute names; expect renames.
8. **Laravel AI SDK vs Prism.** Both are maintained. `laravel/ai` now covers agents, tool approvals, failover, conversation storage and fakes (https://laravel.com/docs/13.x/ai-sdk). This project uses Prism. Open: whether to migrate, run both, or copy the SDK's patterns (approvals, per-step middleware) onto Prism.

## Patterns

Each item: rule. When. Prevents. Source.

### Choosing the shape

- **P1 Start at the lowest rung.** Use one model call, then a fixed chain, then routing, then an agent loop; climb only when evals show the lower rung fails. When: every new LLM feature. Prevents: cost, latency and compounding errors from autonomy nobody needed. https://www.anthropic.com/engineering/building-effective-agents ; Microsoft's table names "direct model call" as the first level (https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns).
- **P2 Build an agent only when one of three conditions holds.** The conditions: nuanced judgement, rules too complex to maintain, or heavy unstructured input. When: before approving an "agent" design. Prevents: an LLM loop where a rule engine suffices. https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf (p.6).
- **P3 Mostly software, LLM at specific steps.** Put deterministic code around the model and let the model choose only the next step. When: customer-facing agents. Prevents: "prompt + bag of tools + loop" that fails beyond demo quality. https://github.com/humanlayer/12-factor-agents
- **P4 Routing.** Classify the input first, then send each class to its own prompt and tool set. When: distinct input categories, e.g. support questions about accounts vs listings vs bans. Prevents: tuning for one category degrading others. Anthropic building-effective-agents; ADK "Coordinator/Dispatcher" (https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/).
- **P5 Evaluator-optimizer (maker-checker) with a cap and a fallback.** One call drafts. A second judges against explicit criteria. Loop until pass or N iterations. On cap, escalate to a human or attach a quality warning. When: clear acceptance criteria exist and revision measurably helps (support drafts fit). Prevents: shipping first drafts. Prevents: infinite refinement. Anthropic building-effective-agents; Microsoft maker-checker section.
- **P6 Orchestrator-workers only for unpredictable subtasks.** When: the subtasks depend on the input and cannot be listed in advance. Prevents: a fixed chain that misses cases. Anthropic building-effective-agents.

### Multi-agent

- **P7 Single agent first, add tools before agents.** When: always. Prevents: coordination overhead. OpenAI guide p.14-16; Microsoft "single agent with tools ... often the right default".
- **P8 Parallel reads, single-threaded writes.** Subagents may search and summarise; one agent owns every state change and the final output. When: any multi-agent design. Prevents: conflicting implicit decisions (Cognition's Flappy Bird example). https://cognition.com/blog/multi-agents-working ; https://www.langchain.com/blog/how-and-when-to-build-multi-agent-systems
- **P9 Full brief per subagent.** Give each subagent an objective, an output format, the tools and sources to use, and task boundaries. When: delegating. Prevents: duplicated or missing work. Anthropic multi-agent research system.
- **P10 Condensed returns.** A subagent returns 1-2k tokens, or writes its artefact to storage and returns a reference. When: subagents. Prevents: context bloat and "game of telephone". Anthropic context engineering; Anthropic multi-agent research system.
- **P11 Isolate the judge.** A reviewer or grader agent gets the output and the rules, not the author's reasoning. When: evaluator-optimizer, moderation review. Prevents: the judge inheriting the author's blind spots. Cognition multi-agents-working.
- **P12 Unique state keys for parallel agents.** When: fan-out writing to shared session state. Prevents: overwrites between parallel branches. ADK guide.
- **P13 Add verification at the end.** When: any multi-step or multi-agent pipeline. Prevents: MAST FC3 failures (premature termination 6.2%, no/incomplete verification 8.2%, incorrect verification 9.1%). A top-level objective check gave +15.6% on ChatDev. https://arxiv.org/html/2503.13657

### Scoping and permissions

- **P14 One job per agent, 3-10 steps.** When: designing scope. Prevents: context growth and lost focus. 12-factor factor 10.
- **P15 Minimal, non-overlapping tools.** If an engineer cannot say which tool applies, the model cannot either. When: tool list review. Prevents: wrong tool choice. Anthropic context engineering; Anthropic writing tools; OWASP LLM06 "minimize extensions".
- **P16 Least privilege per agent, enforced outside the model.** Authorisation lives in the downstream system ("complete mediation"), not in the prompt. When: every tool with data or side effects. Prevents: excessive permissions and prompt-injection escalation. https://genai.owasp.org/llmrisk/llm062025-excessive-agency/
- **P17 Choose agent-auth or user-auth per tool, and log attribution.** Agent-auth (service identity) needs logs that tie each action to the triggering user. User-auth (on-behalf-of) caps the agent at the user's rights but scopes are often too broad. When: every credential. Prevents: anonymous actions; privilege beyond the user. https://adk.dev/safety/ ; Microsoft "security trimming must be implemented in every agent".
- **P18 Rule of Two per session.** An agent session holds at most two of: untrusted input, sensitive data/systems, ability to change state or communicate out. If all three are needed, require a human approval. When: support drafter (reads untrusted user messages + private user data -> must not send), MCP server, write agent. Prevents: injection-driven exfiltration. https://ai.meta.com/blog/practical-ai-agent-security/ ; https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/
- **P19 Risk-rate every tool.** Rate low/medium/high by read vs write, reversibility, permissions and financial impact; high-risk tools pause for a guardrail check or a human. When: tool registry. Prevents: irreversible actions without oversight. OpenAI guide p.26.
- **P20 Human approval per tool call, not per run.** Gate only sensitive calls; let low-risk calls run. Persist state at the gate so resume does not replay work. When: write-capable agents. Prevents: approval fatigue and blind confirms. Microsoft "Human participation"; Laravel AI SDK `Approvable` + `needsApproval()` returns `Approval::required('reason')` (https://laravel.com/docs/13.x/ai-sdk).
- **P21 Escalate on failure thresholds.** Set retry and action limits; on breach hand off to a human. When: customer-facing agents. Prevents: loops that annoy users. OpenAI guide p.31.
- **P22 Stop conditions are mandatory.** Max iterations, max tokens, timeout; a stop on budget breach. When: every loop. Prevents: runaway cost (MAST FM-1.5 "unaware of termination conditions" 12.4%, FM-1.3 step repetition 15.7%). Anthropic building-effective-agents; OpenAI guide p.14; Laravel AI SDK `#[MaxSteps]`, `#[Timeout]`, and per-step middleware `Stop::unless(fn ($step) => $step->usage->inputTokens < 50_000)`.
- **P23 Side effects idempotent or after the pause.** Any side effect that may re-run on resume or retry must be idempotent. When: queued jobs, interrupts, retries. Prevents: double sends, double writes. https://docs.langchain.com/oss/python/langgraph/interrupts ; Temporal records LLM decisions so replay does not repeat them (https://temporal.io/blog/of-course-you-can-build-dynamic-ai-agents-with-temporal).

### Tools and MCP

- **P24 Consolidate tools around workflows, not endpoints.** Prefer `search_contacts` over `list_contacts`; one `schedule_event` over list+create. When: designing tools or exposing an API as MCP. Prevents: token waste and multi-call errors. https://www.anthropic.com/engineering/writing-tools-for-agents
- **P25 Namespace tool names.** E.g. `givore_listings_search`. When: an agent loads tools from more than one source. Prevents: name collisions and wrong picks. Anthropic writing tools.
- **P26 Return names, not opaque IDs; offer `response_format`.** "concise" used about one third of the tokens of "detailed". When: tool outputs. Prevents: hallucinated ID handling, context bloat. Anthropic writing tools.
- **P27 Cap tool responses.** Paginate, filter, truncate with sensible defaults; Claude Code caps at 25,000 tokens. Truncation messages tell the agent how to narrow the query. When: any list/search tool. Prevents: context overflow and context rot. Anthropic writing tools.
- **P28 Actionable error results.** Return what was wrong and a correct example, as a tool result (`isError: true`), not a stack trace. Use protocol errors only for unknown tool / malformed call. When: every tool. Prevents: the agent retrying blindly. Anthropic writing tools; MCP tools spec (https://modelcontextprotocol.io/specification/2025-06-18/server/tools); Laravel MCP `Response::error(...)`.
- **P29 Poka-yoke arguments.** Change parameters so mistakes are hard (absolute paths, enums, `user_id` not `user`, strict schemas). When: tool schema design. Prevents: argument errors. Anthropic building-effective-agents; Anthropic writing tools.
- **P30 Declare output schemas.** Servers with an `outputSchema` MUST return conforming `structuredContent` and SHOULD also return the JSON as text. When: MCP tools. Prevents: unparseable results. MCP tools spec; Laravel MCP `outputSchema()` + `Response::structured()`.
- **P31 MCP server must validate, authorise, rate-limit and sanitise.** These are MUSTs in the spec. Use `shouldRegister()` to hide tools a caller may not use and still check `$request->user()->can(...)` inside `handle()`. When: exposing the API as MCP. Prevents: tool access by listing alone. MCP tools spec; https://laravel.com/docs/12.x/mcp
- **P32 No token passthrough.** An MCP server MUST NOT accept tokens not issued for it. Session IDs MUST NOT authenticate; bind queue keys as `<user_id>:<session_id>`. When: MCP server auth. Prevents: confused deputy, session hijack, lost audit trail. https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices
- **P33 Progressive scopes.** Start with a read-only baseline scope; elevate with a targeted challenge; never publish `*`/`admin:*`. When: OAuth on MCP. Prevents: broad stolen-token blast radius. MCP security best practices "Scope Minimization".
- **P34 Treat tool annotations from other servers as untrusted.** `readOnlyHint` and friends are hints. When: consuming external MCP. Prevents: a malicious server claiming read-only. MCP tools spec.
- **P35 Allowlist external MCP servers and their tools; block SSRF.** Explicit server config (Prism Relay requires it), egress through a proxy, block private ranges. When: the API consumes MCP. Prevents: SSRF to metadata endpoints, tool-poisoning. MCP security best practices; https://github.com/prism-php/relay
- **P36 Keep big intermediate data out of the model.** Filter in code, pass references; Anthropic's code-execution approach cut one workflow from 150k to 2k tokens. Prism `ToolOutput` artifacts keep binary data out of context. When: tools that move documents or large rows. Prevents: cost and copy errors; PII exposure. https://www.anthropic.com/engineering/code-execution-with-mcp ; https://prismphp.com/core-concepts/tools-function-calling.html
- **P37 A2A only for peer agents you do not own.** MCP is agent-to-tool; A2A is agent-to-agent across an org boundary. When: almost never inside one API. Prevents: protocol overhead for in-process calls. https://a2a-protocol.org/latest/topics/a2a-and-mcp/

### Context and knowledge

- **P38 Smallest high-signal context.** Treat context as a budget with diminishing returns. When: every prompt. Prevents: context rot, which Chroma measured across 18 models; focused ~300-token prompts beat ~113k-token prompts on LongMemEval for every model. https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents ; https://www.trychroma.com/research/context-rot
- **P39 Pre-load a structured entity card, fetch the rest on demand.** Load a compact customer/listing card at start (factor 13 pre-fetch); expose deeper history as a retrieval tool. When: support drafter, moderation. Prevents: the model asking for what code already knows; stuffing whole histories. 12-factor factor 13; Anthropic context engineering "hybrid".
- **P40 Relevance threshold; zero results beats partial results.** Return nothing below a confidence threshold and let the agent say "I don't know"; log zero-result queries as knowledge gaps. When: RAG over a support KB. Prevents: answers built on tangential documents. https://www.elastic.co/blog/building-ai-agents-elasticsearch-platform
- **P41 Own the context format.** Render history as typed events; drop resolved errors; filter sensitive data before it reaches the model. When: multi-step agents. Prevents: noise and PII leaks. https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-03-own-your-context-window.md
- **P42 Canonical examples over rule lists.** A few diverse examples beat long edge-case rules. When: system prompts. Prevents: brittle prompt growth. Anthropic context engineering.
- **P43 Turn existing SOPs into numbered routines.** Each step maps to one action or output and names the edge-case branch. When: support and moderation prompts. Prevents: ambiguity. OpenAI guide p.11.
- **P44 Compaction and notes for long runs.** Clear old tool results first; summarise near the limit; write notes outside context. When: long conversations. Prevents: overflow. Anthropic context engineering.

### State, durability, observability

- **P45 Unify execution state with business state.** Store the agent thread as the source of truth so a run can serialise, resume, fork and be debugged. When: any run that pauses or retries. Prevents: split-brain state. https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-05-unify-execution-state.md
- **P46 Launch/pause/resume via plain APIs; contact humans via a tool.** The agent calls `request_human_input`, the loop saves the thread and returns, a webhook resumes it. When: approvals, clarifications. Prevents: blocked workers holding state in memory. 12-factor factor 6 and factor 7 (https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-07-contact-humans-with-tools.md).
- **P47 Resume from the failure point, not from scratch.** Checkpoint each step; retries resume. When: multi-step runs. Prevents: compounding cost and duplicated side effects. Anthropic multi-agent research system; Temporal.
- **P48 Deploy without breaking running agents.** Pin a run to its prompt/code version; shift traffic gradually (Anthropic "rainbow deployments"). When: long-running or paused runs. Prevents: a paused run resuming under a different prompt. Anthropic multi-agent research system.
- **P49 Trace every model call and tool call with GenAI attributes.** Use `gen_ai.operation.name` (`chat`, `invoke_agent`, `execute_tool`), `gen_ai.provider.name`, `gen_ai.request.model`, `gen_ai.agent.name/version`; content capture is opt-in. When: production. Prevents: undebuggable non-determinism. https://github.com/open-telemetry/semantic-conventions-genai
- **P50 Log per-run cost and latency, per agent.** Token counts (input, output, cached, reasoning), model, duration, prompt version. When: production. Prevents: invisible cost spikes. Microsoft cost optimisation; Laravel AI SDK `$response->usage->inputTokens / cacheReadInputTokens / reasoningTokens`.
- **P51 Version prompts and link versions to traces.** When: any prompt change. Prevents: not knowing which prompt produced a bad output. https://langfuse.com/docs/prompt-management/overview
- **P52 Evals from real failures, measured as pass^k.** Start with 20-50 tasks drawn from real failures. Grade outcomes, not paths. Use pass^k for customer-facing reliability (0.75 per trial -> 42% over 3). Split capability evals from regression evals. When: before and after every prompt/model change. Prevents: shipping regressions. Prevents: believing a lucky run. Source: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents . Also tau-bench found GPT-4o fell to ~25% pass^8 on retail (https://sierra.ai/blog/benchmarking-ai-agents).
- **P53 Calibrate any LLM judge against human labels.** Track agreement, precision and recall; allow "Unknown"; one judge per dimension. When: automated grading of support drafts. Prevents: optimising toward a judge that disagrees with the operator. https://hamel.dev/blog/posts/evals/ ; Anthropic demystifying evals.
- **P54 Model choice: baseline with the best model, then downsize per step.** When: cost tuning. Prevents: premature capability limits. OpenAI guide p.8; Microsoft "assign each agent a model that matches the complexity".
- **P55 Provider failover only on provider faults.** Fail over on rate limit, overload or credit errors; not on validation errors. When: production LLM calls. Prevents: masking real bugs by switching providers. Laravel AI SDK "Failover" (`FailoverableException`).

## Anti-patterns

- **A1 Agent where a function would do.** Symptom: a tool loop around a task with fixed steps. Consequence: higher cost, variable output, compounding errors. Source: Anthropic building-effective-agents; Microsoft pitfalls "nondeterministic patterns for workflows that are inherently deterministic".
- **A2 Framework hides the prompt.** Symptom: nobody can print the exact prompt and tool list sent. Consequence: undebuggable failures. Source: Anthropic building-effective-agents; 12-factor factor 2.
- **A3 Parallel writers.** Symptom: two agents (or two queued jobs) both mutate the same record or both draft parts of one reply. Consequence: conflicting implicit decisions. Source: Cognition 2025 and 2026.
- **A4 Agents without specialisation.** Symptom: agents that differ only in name. Consequence: coordination overhead, handoff loops. Source: Microsoft pitfalls; MAST FM-2.x inter-agent misalignment.
- **A5 Wrapping every endpoint as a tool.** Symptom: an MCP server with one tool per REST route. Consequence: overlapping tools, token waste, wrong picks. Source: Anthropic writing tools; OWASP LLM06.
- **A6 Unbounded tool output.** Symptom: list tools with no limit or page. Consequence: context rot, cost. Source: Anthropic writing tools; Chroma.
- **A7 Top-k retrieval without a threshold.** Symptom: always inject 10 documents. Consequence: worse answers than none (8.15 vs 9.18). Source: Elastic.
- **A8 Authorisation in the prompt.** Symptom: "only access the user's own data" in a system prompt, with the tool querying all rows. Consequence: injection bypass. Source: OWASP LLM06 "complete mediation".
- **A9 Generic high-privilege service account.** Symptom: one admin token used by every AI feature. Consequence: blast radius, no attribution. Source: OWASP LLM06; ADK safety.
- **A10 Lethal trifecta in one session.** Symptom: agent reads user messages, sees private data and can send email or call URLs. Consequence: data exfiltration via injection. Source: Willison; Meta Rule of Two.
- **A11 Token passthrough / session-as-auth on MCP.** Symptom: the MCP server forwards the client's token downstream or trusts `Mcp-Session-Id`. Consequence: confused deputy, hijack, broken audit. Source: MCP security best practices.
- **A12 No stop condition.** Symptom: loop ends only when the model stops calling tools. Consequence: runaway cost, step repetition. Source: MAST FM-1.3, FM-1.5; Anthropic.
- **A13 Non-idempotent side effect before a pause or retry.** Symptom: a queued job that sends a notification, then may retry. Consequence: duplicate sends. Source: LangGraph interrupts.
- **A14 Exact-match tests for LLM output.** Symptom: `assertEquals` on generated text. Consequence: flaky tests or tests that pin defects. Source: Microsoft observability and testing; Anthropic demystifying evals.
- **A15 Judging by transcript claims.** Symptom: eval passes because the agent said "done". Consequence: false success. Source: Anthropic demystifying evals (outcome vs transcript).
- **A16 Guardrail classifier as the only defence.** Symptom: a jailbreak classifier in front of a write-capable agent. Consequence: the 5% that slip through act. Source: Willison.
- **A17 Rate-limiting long sessions blindly.** Symptom: hard token caps applied before analysis. Consequence: cuts the most valuable sessions (Elastic top sessions averaged 583k tokens at 9.8/10). Source: Elastic. Note: this conflicts in spirit with P22; P22 caps runaway loops, A17 warns against capping legitimate depth. A reviewer should ask for both a cap and the data behind it.
- **A18 Unpinned "smartest/cheapest" model aliases.** Symptom: `#[UseCheapestModel]` or `latest` aliases. Consequence: silent behaviour change on provider release. Source: Laravel AI SDK docs warn to pin `Model`.

## Review checklist candidates

Each: question. Source. Mechanical check in this Laravel codebase (paths assume `~/workspace/recycling-api`).

1. Does the design state why a single call or fixed chain is not enough? Source: Anthropic building-effective-agents. Check: the design doc names the lower rung tried and the eval result; `grep -rn "withMaxSteps\|MaxSteps(" app/` lists every looped call, each must map to a justified agent.
2. Does every LLM loop have a step cap, token cap and timeout? Source: Anthropic; OpenAI guide p.14. Check: `grep -rn "Prism::text()" app/ | xargs` then confirm `withMaxSteps(`, `withMaxTokens(`, `withClientOptions(['timeout'` on the same chain; for `laravel/ai` agents grep `#[MaxSteps` and `#[Timeout`.
3. Does each agent have one job, a tool list under ~10, and no overlapping tools? Source: 12-factor factor 10; OpenAI guide p.16. Check: count tools per agent (`grep -c "Tool::as(" <file>`); a test asserts the exact tool name list per agent.
4. Is every tool risk-rated, and does every high-risk tool pause for approval or run behind a human? Source: OpenAI guide p.26; Meta Rule of Two. Check: tools carry `#[IsReadOnly]`/`#[IsDestructive]` (Laravel MCP) or implement `Approvable`; a test fails if a tool class lacks a rating.
5. Does the agent session combine untrusted input, private data and an outbound or write action? Source: Meta Rule of Two. Check: list the agent's tools; if any tool sends mail/push/HTTP or writes, and the input includes user text, a human gate must exist. For the support drafter: assert no send path (`grep -rn "Mail::\|Notification::send\|->notify(" app/Services/Support*`) returns nothing in the draft path.
6. Is authorisation enforced in code at each tool, independent of the prompt? Source: OWASP LLM06. Check: each tool `handle()` calls a Policy/Gate or a scoped query; a feature test calls the tool as user A for user B's record and expects an error result.
7. Does each agent have its own identity and least-privilege credential, with every write attributed? Source: ADK safety; OWASP LLM06. Check: `app/Services/Agent/AgentPermissionMatrix.php` `granted()` lists only the needed abilities; `agent_request_logs` row exists per mutating request (existing feature test); no AI job uses an admin user's token.
8. Is the tool gate deny-by-default? Source: OWASP LLM06; MCP spec "implement proper access controls". Check: a test iterates `Route::getRoutes()` and asserts every mutating route not in the allowlist returns 403 for the agent token (`AgentTokenGate`).
9. Are tool side effects idempotent under queue retry? Source: LangGraph interrupts; Temporal. Check: jobs that call tools have `$tries`/`uniqueId()` or an idempotency key column; a test dispatches the job twice and asserts one side effect.
10. Do tool errors return actionable text as a tool result, not exceptions or stack traces? Source: Anthropic writing tools; MCP spec. Check: `grep -rn "Response::error(" app/Mcp`; a test sends a bad argument and asserts the error text names the field and a valid example.
11. Are tool outputs bounded? Source: Anthropic writing tools. Check: each list/search tool has a `limit` default and max; a test seeds 500 rows and asserts the tool output length stays under a byte budget.
12. Do tools return names and readable fields, not bare IDs? Source: Anthropic writing tools. Check: snapshot test of tool output keys.
13. Does the MCP server reject tokens not issued for it and never authenticate by session? Source: MCP security best practices. Check: `routes/ai.php` applies `auth:sanctum` or `auth:api` middleware on `Mcp::web`; a test with a valid session id and no bearer gets 401.
14. Does the MCP server hide and also block tools per caller? Source: Laravel MCP docs; MCP spec. Check: tools implement `shouldRegister()` and re-check `$request->user()->can()` in `handle()`; `WeatherServer::tool(...)`-style test as an unprivileged user expects an error.
15. Is the MCP endpoint rate-limited? Source: MCP spec MUST. Check: `Mcp::web(...)->middleware(['throttle:...'])` in `routes/ai.php`.
16. Are external MCP servers and their tools allowlisted, with egress restricted? Source: MCP security best practices; Prism Relay. Check: `config/relay.php` lists servers explicitly; the code filters tool names; no user-supplied URL reaches an MCP client.
17. Does the agent load a compact entity card at start and fetch the rest via tools? Source: 12-factor factor 13; Anthropic context engineering. Check: a unit test renders the prompt for a fixture user and asserts its token estimate stays under a budget and contains the card fields.
18. Does retrieval apply a relevance threshold and allow zero results? Source: Elastic. Check: the KB search service has a min-score constant; a test with an unrelated query asserts an empty result and an "I don't know" path; zero-result queries are logged.
19. Is PII filtered before the prompt where the task does not need it? Source: 12-factor factor 3; Anthropic code-execution; project feedback "prod data anonymized before AI". Check: a prompt-render test asserts no email/phone of the fixture appears.
20. Is each run persisted with prompt version, model, tokens, cost, latency and outcome? Source: Langfuse; OTel GenAI; Microsoft. Check: a `*_runs` table (or Telescope/Sentry span) with those columns; a test asserts a row after a faked call (`PrismFake`).
21. Are spans named with GenAI conventions? Source: OTel GenAI. Check: `grep -rn "gen_ai\." app/` finds the attributes on the tracing wrapper.
22. Can a paused or failed run resume without repeating completed steps? Source: Anthropic multi-agent; 12-factor factor 5/6. Check: a test fails a step mid-run, re-dispatches, and asserts earlier model calls are not repeated (`PrismFake` call count).
23. Is there a replay eval set built from real failures, scored as pass^k, with a regression threshold? Source: Anthropic demystifying evals; tau-bench. Check: an artisan command (e.g. the existing support replay) runs N trials per case and fails below threshold; results stored per prompt version.
24. Is any LLM judge calibrated against operator labels? Source: Hamel; Anthropic demystifying evals. Check: a stored agreement metric (precision/recall vs operator-sent text) per judge version.
25. Does an evaluator loop have a cap and a defined fallback? Source: Microsoft maker-checker. Check: grep the loop for a max-iteration constant; a test with an always-failing judge asserts escalation or a warning flag.
26. In multi-agent designs, does exactly one agent write state and the final output? Source: Cognition; LangChain. Check: only one class in the pipeline calls a write service; static grep for `->save()`/`::create(` in subagent classes returns nothing.
27. Are model names pinned, and does failover trigger only on provider faults? Source: Laravel AI SDK. Check: no `UseCheapestModel`/`UseSmartestModel`/`latest` alias; failover config lists explicit models.
28. Are LLM outputs tested with fakes and rubric checks, not exact-string asserts on generated prose? Source: Microsoft; Anthropic evals. Check: tests use `PrismFake` / `Agent::fake()->preventStrayPrompts()`; no live provider calls in the suite.

## Reference repos and tutorials

| Name | URL | What to copy | Verdict |
|---|---|---|---|
| humanlayer/12-factor-agents | https://github.com/humanlayer/12-factor-agents | Factors 3, 5, 6, 7, 8, 10, 13 as review criteria; `request_human_input` as a tool; thread-as-state | High. Primary practitioner source. |
| anthropics/claude-cookbooks patterns/agents | https://github.com/anthropics/claude-cookbooks/tree/main/patterns/agents | Minimal chain, routing, parallel, evaluator-optimizer, orchestrator-workers code | High. Small and framework-free. |
| openai/openai-cs-agents-demo | https://github.com/openai/openai-cs-agents-demo | Triage + specialists, relevance and jailbreak guardrails visible in UI, scripted demo flows as fixtures | Medium. Good for routing and guardrail UI; uses handoffs between many agents, which this API does not need. |
| google/adk-samples | https://github.com/google/adk-samples | Customer-service and other agent samples with callbacks and eval sets | Medium. Python/ADK-specific; copy the before-tool callback validation idea. |
| open-telemetry/semantic-conventions-genai | https://github.com/open-telemetry/semantic-conventions-genai | Span and attribute names for agent and tool spans | High, but status Development. |
| laravel/mcp docs | https://laravel.com/docs/12.x/mcp | `Mcp::web` + middleware, `shouldRegister`, tool annotations, `outputSchema`, `Response::error`, `Server::tool()` tests, `mcp:inspector` | High. First-party. |
| laravel/ai (Laravel AI SDK) | https://laravel.com/docs/13.x/ai-sdk | `Approvable` tools + `Decision::approve/reject`, per-step middleware with `Stop::unless`, `#[MaxSteps]`, failover on `FailoverableException`, `usage` with cache/reasoning tokens, `Agent::fake()->preventStrayPrompts()` | High. First-party; the cleanest PHP model of HITL approvals found. |
| Prism PHP | https://prismphp.com/core-concepts/tools-function-calling.html | `withMaxSteps`, tool error handling returns errors to the model by default, `concurrent()` for I/O tools only, `ToolOutput` artifacts | High. Already in use here. |
| prism-php/relay | https://github.com/prism-php/relay | Explicit MCP server allowlist in config, per-server timeout, cached tool definitions | Medium. No per-tool allowlist; add one in code. |
| NeuronAI | https://docs.neuron-ai.dev/ | Workflow with checkpointing, interruption, tool approval; Inspector tracing | Medium. Overlaps with Laravel queues; docs page includes an install block aimed at coding agents. |
| LarAgent | https://github.com/MaestroError/LarAgent | Agent class conventions, history drivers, provider failover list | Low-medium. Default `max_completion_tokens` of 100 in sample config is a footgun. |
| Anthropic "Building effective agents" | https://www.anthropic.com/engineering/building-effective-agents | Pattern ladder; ACI and poka-yoke | High. |
| Anthropic "Writing effective tools for agents" | https://www.anthropic.com/engineering/writing-tools-for-agents | Tool consolidation, 25k cap, error text, `response_format` | High. |
| Microsoft "AI agent orchestration patterns" | https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns | Complexity ladder table; reliability, security, cost and HITL considerations; pitfalls list | High. Vendor-neutral content despite the Azure host. |
| Google "Multi-agent patterns in ADK" | https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/ | Eight named patterns; `output_key` state discipline | Medium-high. |
| Elastic "1 year and 1 million messages" | https://www.elastic.co/blog/building-ai-agents-elasticsearch-platform | Retrieval threshold, zero-result gap log, log-derived quality metrics | High. Measured production data; rubric not published. |
| Hamel Husain "Your AI product needs evals" | https://hamel.dev/blog/posts/evals/ | Three eval levels; judge alignment | High. |
| Generic "How to build an AI agent in 2025/2026" posts (turing.com, dev.to, relevanceai, gocodeo) | e.g. https://turing.com/resources/how-to-build-an-ai-agent | Nothing specific | Low. Surface-level listicles; no measurements. Treat as hype. |
| Intercom Fin product pages and comparisons | https://fin.ai/learn/what-is-fin-ai-agent | The idea that gains came from retrieval and reranking, not the LLM | Low as evidence. Vendor numbers; layer counts differ by source. |

## Skill topic candidates

1. **Choose the agent shape.** Walk a feature from single call to chain to routing to evaluator-optimizer to agent; output the chosen rung and the eval that justifies it.
2. **Write a tool for an LLM in Laravel.** Prism/`laravel/ai`/Laravel MCP tool with namespaced name, strict schema, bounded output, readable fields, actionable error result, policy check, risk rating, and its tests.
3. **Expose the API as an MCP server safely.** `routes/ai.php`, Sanctum vs Passport OAuth, throttle middleware, `shouldRegister` + in-handler authorisation, output schemas, no token passthrough, inspector run, tool tests.
4. **Consume an external MCP server safely.** Server and tool allowlist, egress restriction, timeout, treating annotations as untrusted, Rule of Two check.
5. **Human approval gate for a write tool.** Approval per tool call, persisted pending state, approve/reject endpoint, idempotent execution after approval, tests with fakes.
6. **Per-agent identity and least privilege.** One credential per agent, ability matrix, deny-by-default gate, attribution log, revocation test.
7. **Budget and stop conditions.** Step, token, time and cost caps per run; per-step stop middleware; what happens on breach.
8. **Build the context for a support agent.** Entity card design, retrieval threshold, zero-result logging, PII scrubbing, token-budget test.
9. **Replay eval harness.** Build tasks from real failures, run k trials, score pass^k against operator-sent text, store per prompt version, regression gate.
10. **Calibrate an LLM judge.** Label set, agreement metrics, per-dimension judges, "Unknown" option, re-calibration trigger.
11. **Run logging and tracing.** Run table schema, GenAI span attributes, cost from usage fields, prompt version link, dashboards.
12. **Durable, resumable agent runs on Laravel queues.** Thread-as-state persistence, resume from last step, idempotency keys, pinning a run to a prompt version across deploys.
13. **Multi-agent review.** When a reviewer/judge agent is justified, isolation of the judge, single writer rule.

## Sources

| Title | URL | Takeaway |
|---|---|---|
| Building effective agents (Anthropic) | https://www.anthropic.com/engineering/building-effective-agents | Climb from simple to agentic only when needed; invest in tool interfaces; add stop conditions. |
| Writing effective tools for agents (Anthropic) | https://www.anthropic.com/engineering/writing-tools-for-agents | Fewer, consolidated, namespaced tools; 25k-token cap; actionable errors; concise format uses ~1/3 tokens. |
| How we built our multi-agent research system (Anthropic) | https://www.anthropic.com/engineering/multi-agent-research-system | +90.2% on research at ~15x tokens; detailed subagent briefs; resume from failure; rainbow deploys. |
| Effective context engineering for AI agents (Anthropic) | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents | Smallest high-signal context; hybrid retrieval; compaction; subagents return 1-2k tokens. |
| Code execution with MCP (Anthropic) | https://www.anthropic.com/engineering/code-execution-with-mcp | Load tools on demand and filter data in code; 150k -> 2k tokens; needs sandboxing. |
| Demystifying evals for AI agents (Anthropic) | https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents | 20-50 tasks from real failures; grade outcomes; pass^k for customer-facing reliability. |
| A practical guide to building agents (OpenAI) | https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf | Three criteria for agents; single agent first; split on overlap or branching; tool risk ratings; escalation triggers. |
| Don't build multi-agents (Cognition, 2025) | https://cognition.com/blog/dont-build-multi-agents | Share full context; actions carry implicit decisions; prefer a single-threaded agent. |
| Multi-agents: what's actually working (Cognition, 2026) | https://cognition.com/blog/multi-agents-working | Writes single-threaded; read-only subagents; reviewer without shared context finds ~2 bugs/PR. |
| How and when to build multi-agent systems (LangChain) | https://www.langchain.com/blog/how-and-when-to-build-multi-agent-systems | Reconciles Anthropic and Cognition: read-heavy work splits, write-heavy does not. |
| Why do multi-agent LLM systems fail? (MAST) | https://arxiv.org/html/2503.13657 | 14 failure modes in 3 categories over 1,600+ traces; verification step +15.6%; prompt fixes only partial. |
| 12-factor agents (HumanLayer) | https://github.com/humanlayer/12-factor-agents | Production agents are mostly software; own prompts, context and control flow; small agents. |
| 12-factor: factor 3 own your context window | https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-03-own-your-context-window.md | Custom event format; hide resolved errors and sensitive data. |
| 12-factor: factor 5 unify state | https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-05-unify-execution-state.md | Thread as source of truth enables resume, fork and debug. |
| 12-factor: factor 7 contact humans with tools | https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-07-contact-humans-with-tools.md | Human contact is a tool call; save thread, resume via webhook. |
| 12-factor: factor 10 small focused agents | https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-10-small-focused-agents.md | 3-10 steps, 20 at most. |
| Developer's guide to multi-agent patterns in ADK (Google) | https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/ | Eight patterns; unique state keys; descriptions are the router's API docs. |
| ADK safety and security (Google) | https://adk.dev/safety/ | Agent-auth vs user-auth; in-tool guardrails; before-tool callbacks; hermetic sandboxes. |
| AI agent orchestration patterns (Microsoft) | https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns | Complexity ladder; maker-checker cap + fallback; security trimming per agent; pitfalls list. |
| LangGraph interrupts | https://docs.langchain.com/oss/python/langgraph/interrupts | Resume restarts the node; side effects before an interrupt must be idempotent. |
| LangGraph persistence | https://docs.langchain.com/oss/python/langgraph/durable-execution | Checkpointer + thread id; in-memory savers lose state on restart. |
| Temporal: dynamic AI agents | https://temporal.io/blog/of-course-you-can-build-dynamic-ai-agents-with-temporal | LLM and tool calls as activities; replay uses recorded decisions. |
| MCP tools spec (2025-06-18) | https://modelcontextprotocol.io/specification/2025-06-18/server/tools | Servers MUST validate, authorise, rate-limit, sanitise; `isError` vs protocol errors; annotations untrusted. |
| MCP security best practices | https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices | No token passthrough; no session auth; SSRF controls; progressive scopes. |
| A2A and MCP | https://a2a-protocol.org/latest/topics/a2a-and-mcp/ | MCP for tools, A2A for opaque peer agents. |
| OTel GenAI semantic conventions | https://github.com/open-telemetry/semantic-conventions-genai | Agent/tool span names and attributes; status Development. |
| The lethal trifecta (Simon Willison) | https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/ | Private data + untrusted content + external comms = exfiltration; 95% detection fails. |
| Agents Rule of Two (Meta) | https://ai.meta.com/blog/practical-ai-agent-security/ | At most two of untrusted input, sensitive access, state change per session; else human approval. |
| OWASP LLM06 Excessive Agency | https://genai.owasp.org/llmrisk/llm062025-excessive-agency/ | Minimise functionality, permissions, autonomy; authorise downstream. |
| Context rot (Chroma) | https://www.trychroma.com/research/context-rot | 18 models degrade with input length; focused prompts beat full prompts for every model. |
| Elastic: 1 year, 1 million messages | https://www.elastic.co/blog/building-ai-agents-elasticsearch-platform | Partial retrieval is worse than none; threshold retrieval; logs drive quality. |
| tau-bench (Sierra) | https://sierra.ai/blog/benchmarking-ai-agents | Customer-service agents unreliable across repeats: ~25% pass^8 for GPT-4o retail. |
| Your AI product needs evals (Hamel Husain) | https://hamel.dev/blog/posts/evals/ | Assertions, human+model eval, A/B; align judges with human critiques. |
| Langfuse prompt management | https://langfuse.com/docs/prompt-management/overview | Versioned prompts linked to traces; deploy prompts without code release. |
| Laravel MCP docs | https://laravel.com/docs/12.x/mcp | `Mcp::web` + middleware, Sanctum/Passport auth, `shouldRegister`, annotations, tests. |
| Laravel AI SDK docs | https://laravel.com/docs/13.x/ai-sdk | Agents, approvals, step middleware, failover, usage, fakes. |
| Prism tools | https://prismphp.com/core-concepts/tools-function-calling.html | `withMaxSteps` required for tools; error handling; concurrent tools; artifacts. |
| Prism Relay | https://github.com/prism-php/relay | MCP client for Prism with explicit server config and timeouts. |
| NeuronAI docs | https://docs.neuron-ai.dev/ | PHP agents with workflows, checkpoints, HITL, Inspector tracing. |
| LarAgent | https://github.com/MaestroError/LarAgent | Laravel agent classes, history drivers, failover. |
| openai-cs-agents-demo | https://github.com/openai/openai-cs-agents-demo | Triage-and-specialists support demo with visible guardrails. |
| claude-cookbooks patterns/agents | https://github.com/anthropics/claude-cookbooks/tree/main/patterns/agents | Reference code for each workflow pattern. |
