---
type: research
project: vault
slug: agent-systems-security
status: snapshot
date_researched: 2026-10-20
tags: [research, agents]
---

# Security, safety and validation of API-embedded LLM agents

Input for the "critic lens" design-review persona. Scope: product agents that run inside a Laravel 12 API.
Givore examples: support reply drafter (`app/Services/Support/*`), idea generation (`app/Prompts/IdeaForRecycling.php`),
content moderation (`app/Prompts/ContentModeration.php`), public MCP server (`routes/ai.php`, `app/Mcp/*`),
write-capable local-agent token (`app/Services/Agent/AgentPermissionMatrix.php`, `AgentTokenGate`).

Consensus in one line: prompt injection is unsolved, so a design is secure only if a fully compromised model still cannot cause a consequential action or a leak. Every detector, filter and prompt rule is a probability layer on top of that, never the boundary.

## Open questions / contradictions

1. **Do detectors and classifiers count as a defense?**
   - Anthropic reports classifiers plus training cut browser-agent attack success from ~8-14% to ~1.4-2.4%, and still calls 1% "meaningful risk" (https://www.anthropic.com/research/prompt-injection-defenses).
   - Microsoft ships Prompt Shields and Spotlighting (spotlighting: >50% to <2% ASR on GPT models). Microsoft also says its approach "does not rely on our ability to block all prompt injections" (https://www.microsoft.com/msrc/blog/2025/07/how-microsoft-defends-against-indirect-prompt-injection-attacks, https://arxiv.org/abs/2403.14720).
   - Nasr et al. 2025 broke 12 published defenses with adaptive attacks at >90% success; most had reported near-zero ASR (https://arxiv.org/abs/2510.09023).
   - Willison: "95% is very much a failing grade" (https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/).
   - Resolution for reviewers: detectors may be recommended, never accepted as the control that makes a design safe.
2. **Human approval: strong control or theatre?** OWASP LLM01/LLM06, OpenAI and Meta Rule of Two all prescribe human approval for consequential actions. Beurer-Kellner et al. judge "user confirmation alone" weak for the software-engineering case. OWASP Agentic T10 and ASI09 name approval fatigue and agent-persuaded humans as threats. Open: when does a human-sent support draft count as a real gate? Proposed answer: only when the human sees the exact outbound text and every link and recipient, and approval is per action, not "always allow".
3. **Where untrusted text belongs in the prompt.** OpenAI says put untrusted input in user messages, never developer/system messages (https://developers.openai.com/api/docs/guides/agent-builder-safety). Spotlighting says wrap or encode it. OWASP cheat sheet says delimiters and labels are formatting, not enforcement (https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html). Consistent reading: do all three as hygiene, count none as a boundary.
4. **Are embeddings and stored prompt examples personal data under GDPR?** Hamburg DPA (2024) says an LLM itself stores no personal data. Erasure still applies to the system's inputs and outputs (https://datenschutz-hamburg.de/fileadmin/user_upload/HmbBfDI/Datenschutz/Informationen/240715_Discussion_Paper_Hamburg_DPA_KI_Models.pdf). EDPB Opinion 28/2024 says anonymity is case-by-case and needs negligible extraction risk (https://cms.law/en/int/legal-updates/edpb-opinion-28-2024-key-takeaways-on-processing-personal-data-in-the-context-of-ai-models). No source found that rules on vector indexes or few-shot example stores. Safe engineering default: treat them as personal data and delete on erasure.
5. **OWASP agentic lists are two documents.** "Agentic AI - Threats and Mitigations" v1.0 (Feb 2025, T1-T15) and "Top 10 for Agentic Applications 2026" (Dec 2025, ASI01-ASI10). The primary PDFs were not readable through fetch; mappings below rely on secondary summaries (Teleport, securedgenai). Verify the wording against the OWASP PDFs before citing IDs in the persona.
6. **Laravel MCP OAuth vs the MCP spec.** The spec wants least-privilege scopes and step-up challenges. `laravel/mcp` advertises one `mcp:use` scope and says custom scopes are not supported (https://laravel.com/docs/12.x/mcp). Per-tool authorization must therefore live in code (`shouldRegister`, Gates), not in token scopes.
7. **Context-minimization for a support drafter.** The paper recommends action-selector plus context-minimization for customer-service bots. A reply drafter must read the customer text to answer it, so pure context-minimization does not fit. The applicable pattern is dual-LLM-like isolation of the output channel plus a human sender. Unresolved: whether past operator replies retrieved as few-shot examples are "trusted". They contain prior customer data and can be poisoned if a customer message ever lands in the example store (OWASP ASI06 memory poisoning).
8. **Anthropic structured output on newest models.** Prism docs: forced tool choice returns 400 on Opus 5.5 / Sonnet 5.5 / Fable 5.1. `ToolChoice::Auto` avoids it but then the schema is not enforced (https://prismphp.com/core-concepts/structured-output.html). A schema is only a guarantee when the provider uses constrained decoding. Always validate in PHP.

## Patterns

Each: rule. When. Threat stopped. Source.

### A. Prompt-injection architecture (the load-bearing controls)

1. **Untrusted input must not be able to trigger a consequential action.** Applies to every agent that reads text a third party wrote. Stops indirect injection turning into side effects. https://arxiv.org/html/2506.08837v3
2. **Break the lethal trifecta / Rule of Two: one session holds at most two of {untrusted input, private data, external communication}.** Applies at design time to every agent. Stops data exfiltration via injection. https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/ , https://ai.meta.com/blog/practical-ai-agent-security/
   - Support drafter: has [A] customer text and [B] KB + customer card. [C] is removed because a human sends the reply. The review must confirm there is no other [C]: no tool calls, no URL fetch, no rendered markdown/images, no webhook (`N8nWebhookDispatcher`) fed by model output without human release.
3. **Action-selector: the model picks from a fixed allowlist of actions; tool output never returns to the model.** For classifiers and routers (moderation verdicts, category tagging). Stops all injection in tool data. https://arxiv.org/html/2506.08837v3
4. **Plan-then-execute: fix the action list before reading untrusted data.** For multi-step agents. Stops control-flow hijack; does not stop parameter tampering. Same source.
5. **LLM map-reduce: process each untrusted item in an isolated call; aggregate only constrained outputs (bool, enum, number).** For moderation over many posts, review summarisation, batch tagging. Stops one malicious item contaminating others. Same source.
6. **Dual LLM: a privileged model plans and calls tools but never sees untrusted text. A quarantined model reads untrusted text and has no tools. Code passes results by reference.** For agents that must both read untrusted text and act. Stops injection reaching tools. Known flaw: the quarantined model can still alter values it returns (for example an email address). https://simonwillison.net/2023/Apr/25/dual-llm-pattern/
7. **CaMeL / information-flow control: code tracks provenance on every value and a policy decides whether a tool call with tainted arguments runs or needs approval**. For high-value agents with real tools. Gives provable security on 77% of AgentDojo tasks vs 84% utility undefended. Sources: https://arxiv.org/abs/2503.18813 , https://simonwillison.net/2025/Apr/11/camel/ . Microsoft FIDES is the same idea.
8. **Context-minimization: drop the user's raw text from context once it is mapped to an intent.** For bots whose answer comes from a KB, not from the user's words. Stops user-prompt injection shaping the final output. https://arxiv.org/html/2506.08837v3
9. **Constrain data flow with structured outputs between steps (enums, fixed schemas, required fields).** Everywhere one model's output feeds code or another model. Removes free-text channels that smuggle instructions. https://developers.openai.com/api/docs/guides/agent-builder-safety
10. **Put untrusted text in the user role, never the system/developer role; mark it (spotlighting: delimit, datamark, or encode).** Every prompt that embeds third-party text. Lowers attack success; not a boundary. https://developers.openai.com/api/docs/guides/agent-builder-safety , https://arxiv.org/abs/2403.14720
11. **Act with the end user's permissions, never a superuser's.** Any agent that reads data. Stops cross-user data reach. Microsoft: indirect injection "relies on the LLM-based application operating with the same level of access permissions as the user". https://www.microsoft.com/msrc/blog/2025/07/how-microsoft-defends-against-indirect-prompt-injection-attacks , OWASP LLM06 https://genai.owasp.org/llmrisk/llm062025-excessive-agency/

### B. Agent identity, authorization and side effects

12. **Give each agent its own identity and credential, distinct from any human's.** Every agent with API access. Enables audit, revocation and per-agent limits. OWASP ASI03 https://goteleport.com/blog/owasp-top-10-agentic-applications
13. **Enforce authorization outside the model ("complete mediation"), deny by default per route/tool.** Every tool or API the agent can reach. Stops excessive agency and prompt-driven privilege escalation. OWASP LLM06.
14. **Prefer narrow tools over open-ended ones (no generic HTTP fetch, shell, or SQL).** Tool design. Stops SSRF and arbitrary action. OWASP LLM06.
15. **Require human approval for consequential actions; the approval binds the exact operation, target and arguments.** Writes, sends, payments, deletes. Stops injected actions executing silently. The executor must re-check that the approved action is the one being run. https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html
16. **Tier approvals: automate low risk, escalate high risk, so humans are not flooded.** Any HITL design. Stops approval fatigue (OWASP Agentic T10). https://securedgenai.substack.com/p/review-agent-security
17. **Write kill switch that revokes write capability without a deploy.** Write-capable agents. Limits blast radius during an incident. OWASP ASI04/ASI10.
18. **Log every agent action, allowed and denied, with identity, tool, arguments hash, and outcome.** Every agent. Stops repudiation (T8) and enables detection. OWASP LLM06 damage-limiting; ASI10.
19. **Rate-limit agent actions per identity.** Every write path. Caps how many bad actions happen before someone notices. OWASP LLM06.
20. **Block known exfiltration channels deterministically: no auto-rendered markdown images, no model-authored links to non-allowlisted domains, no model-chosen outbound URLs.** Any surface that renders model output (admin dashboard, chat, email). Stops zero-click exfiltration. https://embracethered.com/blog/posts/2023/chatgpt-webpilot-data-exfil-via-markdown-injection/ , MSRC.

### C. MCP (exposing and consuming)

21. **Your MCP server accepts only tokens issued for it (audience-bound) and never passes a client token downstream.** Any authenticated MCP server. Stops token passthrough and confused deputy. "MCP servers MUST NOT accept any tokens that were not explicitly issued for the MCP server." https://modelcontextprotocol.io/specification/draft/basic/security_best_practices , https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
22. **Do per-tool authorization in code on every call; registration filtering is not enough.** Laravel MCP: `shouldRegister()` hides a tool, `$request->user()->can()` must still run inside `handle()`. https://laravel.com/docs/12.x/mcp
23. **Validate every tool argument like a FormRequest (`$request->validate([...])`, max lengths, enums).** Every MCP tool. Stops injection into queries and oversized inputs. Same source; OWASP ASI02.
24. **Least-privilege scopes with step-up; no omnibus scopes.** OAuth-protected MCP servers. Limits stolen-token blast radius. MCP security best practices "Scope Minimization".
25. **State handles in tool arguments are bound to the authenticated user and are unguessable.** Stateful MCP tools. Stops state handle hijacking. Same source.
26. **Public MCP tools return only data already public via the REST API, with the same visibility filters and rate limits.** Read-only public MCP. Stops MCP becoming a side door around `listQuery()` scoping. Inference from MCP BP + OWASP API BOLA.
27. **When consuming third-party MCP servers: pin version and tool-description hash, show full descriptions, re-approve on change, isolate servers from each other.** Any agent that loads external tools. Stops tool poisoning, rug pulls and cross-server shadowing. https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks
28. **One agent session touches one trust scope (for example one repository, one customer).** Agents with broad tokens. Stops toxic flows like the GitHub MCP exploit. https://invariantlabs.ai/blog/mcp-github-vulnerability
29. **Outbound fetches from server-side MCP clients go through SSRF protection (HTTPS only, block private ranges, validate each redirect, egress proxy).** Any server that follows URLs from an MCP peer. MCP security best practices "SSRF".

### D. Output validation

30. **Treat model output as untrusted user input: validate in code before any downstream use.** Every agent. OWASP LLM05 https://genai.owasp.org/llmrisk/llm052025-improper-output-handling/
31. **Use the provider's constrained decoding (JSON schema strict mode) and still validate the parsed object in PHP (finish reason, non-empty, required fields, enum membership).** Every structured call. https://prismphp.com/core-concepts/structured-output.html
32. **Encode output for its sink: HTML-escape for web, parameterised queries for SQL, no `{!! !!}` on model text.** Any rendered or persisted output. OWASP LLM05.
33. **Deterministic content checks on drafts: leaked PII of other users, copied names from examples, forbidden phrases, links outside an allowlist, citation of non-existent KB entries**. Generators whose output reaches a customer. Stops cross-customer leaks and hallucinated promises. OWASP LLM01 item 2 ("use deterministic code to check that outputs match"), LLM02, LLM09.
34. **Fail closed on validation failure for anything consequential; retry-with-feedback only for format errors, with a hard retry cap.** Every validated call. Retrying on a policy violation lets an attacker sample until a bad output passes (Best-of-N: 89% on GPT-4o with up to 10k attempts). https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html
35. **Use guardrail frameworks only as a supplementary detector, run in blocking mode before side effects**. OpenAI Agents SDK: parallel input guardrails let the agent spend tokens and run tools before the tripwire fires. Blocking mode prevents that. Tool guardrails do not cover hosted tools or handoffs. https://openai.github.io/openai-agents-python/guardrails/
36. **Map-reduce over memory: never auto-write agent output back into trusted memory or the example store.** Learning loops (support drafter learning from sent replies). Stops memory poisoning. OWASP ASI06.

### E. Data protection

37. **Redact or pseudonymise PII before the model when the task does not need it.** Every prompt builder. OWASP LLM02 https://genai.owasp.org/llmrisk/llm022025-sensitive-information-disclosure/ . Tools: Presidio (via NeMo), or deterministic redactors (Givore: `ReplyRedactor`).
38. **Do not rely on system-prompt instructions to keep data secret.** OWASP LLM02: such restrictions "may not always be honored and could be bypassed via prompt injection". Keep the data out of context instead.
39. **Choose retention deliberately: provider default is ~30 days (OpenAI abuse logs, Anthropic API). ZDR needs an agreement. Stateful features (OpenAI vector stores, files, assistants, stored responses) are not ZDR-eligible. Anthropic keeps flagged content up to 2 years.** Every provider integration. https://developers.openai.com/api/docs/guides/your-data , https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data
40. **Set `store=false` (OpenAI Responses) unless state is required.** OpenAI integrations. Same source.
41. **Log prompts and completions with PII redacted, with a retention TTL, and with access restricted to admins.** Prompt/trace logging (Telescope, Sentry, DB draft records). Stops logs becoming the leak. OWASP LLM02 + MCP BP "Token Theft" (tokens cached or logged).
42. **GDPR erasure reaches every copy: prompt logs, stored drafts, few-shot example stores, embeddings, eval/replay fixtures.** Any store that holds user text. Hamburg DPA locates erasure at system inputs/outputs; EDPB says technical impossibility is no excuse (via IAPP/Mondaq summary). Givore: extend the existing anonymisation (`gdpr_user_anonymization` memory) to the support example store and replay cases.

### F. Abuse and cost

43. **Cap input size before the call.** Every endpoint that forwards user text. OWASP LLM10 https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/
44. **Per-user and global budgets on LLM calls, enforced before dispatch.** Every LLM feature reachable by users. Stops denial of wallet. OWASP LLM10. Givore: `SupportCallBudget`.
45. **Hard caps on agent loop turns, tool calls per run, retries, and wall-clock timeout.** Every agent loop and queued AI job. OWASP LLM10 "Timeouts and Throttling", "Limit Queued Actions". (Laravel: `$tries`, `$timeout`, Prism `maxSteps`.)
46. **Isolate AI jobs on their own queue lane so a spike cannot starve core work.** Queue-based AI. OWASP LLM10 graceful degradation. Givore already does this (`ai` queue).
47. **Alert on spend anomalies, not only on errors.** Every provider account. OWASP LLM10 monitoring.

### G. Testing

48. **Test against adaptive attackers, not a fixed string list.** Any claim of injection resistance. https://arxiv.org/abs/2510.09023
49. **Keep a regression corpus of injection payloads embedded in each untrusted field (customer message, post title, KB entry, MCP tool arg). Assert the deterministic controls hold, using a faked model that obeys the injection.** Every agent. Tests the architecture, not the model. Laravel: `PrismFake` returning the attacker-desired output, then assert no side effect, validator rejects, no outbound URL.
50. **Run a periodic red-team scan against the real endpoint with promptfoo or garak.** Pre-release or nightly. promptfoo plugins: `indirect-prompt-injection`, `pii:*`, `excessive-agency`, `bola`, `bfla`, `ssrf`, `prompt-extraction`, `hijacking`, `data-exfil`, `mcp`, `cross-session-leak`. https://www.promptfoo.dev/docs/red-team/plugins/ ; HTTP provider targets any REST API https://www.promptfoo.dev/docs/providers/http/ ; garak `rest.RestGenerator` https://github.com/NVIDIA/garak
51. **Use AgentDojo / InjecAgent for model and pattern selection, not for app CI.** They are Python benchmarks with their own tool suites; useful to compare models or defenses. InjecAgent: 1,054 cases, ReAct GPT-4 24% vulnerable, nearly doubled with a "hacking prompt". https://github.com/ethz-spylab/agentdojo , https://arxiv.org/abs/2403.02691

## Anti-patterns / theatre

| Symptom | Why it fails | Source |
|---|---|---|
| Regex or keyword filter for "ignore previous instructions" as the main defense | Attacks need none of the keywords; typos, encodings, other languages bypass it. Cheat sheet: "output keyword filtering is not sufficient". | https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html |
| Delimiters, XML tags or "treat the following as data" as the security boundary | The model still reads and may follow the text. Labels are formatting, not enforcement. | same; https://arxiv.org/abs/2403.14720 (probabilistic) |
| System prompt says "never reveal X / never call Y unless..." | Prompt rules are bypassable; authorization must be in code. | OWASP LLM02, LLM06 |
| Guardrail LLM or classifier as the only control | Classifiers are injectable and adaptive attacks beat 12 defenses at >90%. "95% is a failing grade." | https://arxiv.org/abs/2510.09023 ; https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/ |
| Agent uses a shared admin/service token | No per-agent audit, no scoped revocation, injection inherits admin power. | OWASP ASI03; LLM06 |
| Tool visibility (`shouldRegister`, tool list) used as authorization | Hidden is not denied; checks must run on invocation. | https://laravel.com/docs/12.x/mcp |
| "Always allow" approval or approval prompts on every read | Users stop reading; GitHub MCP exploit relied on "Always Allow". | https://invariantlabs.ai/blog/mcp-github-vulnerability ; OWASP T10 |
| Approval UI shows a model summary, not the exact action | The model can misdescribe what it will do (ASI09 human-agent trust exploitation). | https://goteleport.com/blog/owasp-top-10-agentic-applications |
| Model output rendered as markdown/HTML in an admin panel | Image/link exfiltration and stored XSS. | https://embracethered.com/blog/posts/2023/chatgpt-webpilot-data-exfil-via-markdown-injection/ ; OWASP LLM05 |
| Retry until the validator passes | Turns a validator into an oracle; Best-of-N wins eventually. | OWASP cheat sheet (Best-of-N) |
| "Temperature 0 makes it safe" | Cheat sheet: "Temperature zero did not eliminate jailbreaks." | OWASP cheat sheet |
| Agent output auto-appended to the KB / example store | Poisoned memory affects every future answer. | OWASP ASI06 / T1 |
| MCP server forwards the caller's token to another API | Token passthrough; forbidden by spec. | MCP security best practices |
| Consuming a third-party MCP server by URL with no pin | Rug pull after approval; tool-description poisoning. | https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks |
| A passing static jailbreak test suite cited as proof | Static suites overstate robustness. | https://arxiv.org/abs/2510.09023 ; OWASP cheat sheet |
| Guardrails run in parallel with a tool-using agent | Tools and spend happen before the tripwire. | https://openai.github.io/openai-agents-python/guardrails/ |
| RAG or fine-tuning offered as an injection fix | OWASP: "they do not fully mitigate prompt injection". | https://genai.owasp.org/llmrisk/llm01-prompt-injection/ |

## Review checklist candidates

Format: question. Source. Mechanical check in this Laravel codebase.

### Architecture / injection
1. Can any text written by a non-operator (customer message, post, comment, KB entry, tool result) reach a model whose output triggers a write, send, or outbound request? It fails when no human approves that exact action. Source: https://arxiv.org/html/2506.08837v3. Check: trace from the prompt class (`grep -rn "Prism::" app`) to every consumer of `->text` / `->structured`; any `->create(`, `->update(`, `Http::`, `Mail::`, `dispatch(` reached without an approval record is a fail.
2. Does any single agent run hold all three of untrusted input, private data and an external channel? Source: https://ai.meta.com/blog/practical-ai-agent-security/. Check: list for each prompt class: inputs (untrusted?), context data (private?), outputs (sent anywhere?). Write it as a table in the design doc; reviewer verifies each row by reading the builder (`SupportDraftContextBuilder`, `CustomerCardBuilder`).
3. Is untrusted text placed only in the user message, never in the system prompt? Source: https://developers.openai.com/api/docs/guides/agent-builder-safety. Check: `grep -rn "withSystemPrompt" app/Prompts app/Services` and inspect that no interpolated customer/user field appears there.
4. Is the model's role an action-selector or classifier where possible (enum output, not free text)? Source: Beurer-Kellner. Check: moderation prompt uses a schema with `EnumSchema`; `grep -rn "EnumSchema\|ObjectSchema" app/Prompts`.
5. Is each untrusted item processed in its own call (map-reduce) when batching? Check: no loop that concatenates many users' posts into one prompt; `grep -rn "implode\|->join(" app/Prompts`.

### Identity, authorization, side effects
6. Does the agent authenticate with its own credential, not a human admin's? Source: OWASP ASI03. Check: agent tokens belong to a service user (`ServiceUserProvisioner`); test asserts `$token->tokenable->is_service_account` (or equivalent).
7. Is every route the agent can call denied unless explicitly granted? Source: OWASP LLM06. Check: a test iterates `Route::getRoutes()` and asserts `AgentTokenGate` returns 403 for every route not in `AgentPermissionMatrix::granted()`.
8. Is there a write kill switch that works without deploy, and is it tested in both states? Source: OWASP ASI10. Check: `grep -rn "AGENT_WRITE_ENABLED" config app`; feature test toggles config and asserts 403 on POST.
9. Are denied attempts logged as well as allowed ones? Source: OWASP T8. Check: test sends a forbidden request and asserts a row in `agent_request_logs` with outcome `denied`.
10. Do approvals bind the exact payload (hash of action + args) and does the executor re-verify it? Source: OWASP cheat sheet HITL. Check: grep for the approval model; assert a test where the payload changes after approval and execution is refused.
11. Can model output choose a URL, recipient, or webhook target? Source: lethal trifecta. Check: `grep -rn "Http::\(get\|post\)" app` and confirm no argument originates from model output; recipients come from DB IDs, not model text.
12. Is model output ever rendered unescaped? Source: OWASP LLM05. Check: in admin/dashboard repos `grep -rn "v-html\|dangerouslySetInnerHTML\|{!!"`; API side: resources return plain strings, and a test asserts `![` and non-allowlisted `http` links are stripped or flagged in drafts.

### MCP
13. Does the MCP route require auth where it exposes anything non-public, and is it rate-limited? Source: MCP authorization spec. Check: `cat routes/ai.php` shows `auth:*` or `optional-auth` plus `throttle:`; `php artisan route:list --path=mcp`.
14. Does every tool call `$request->validate()` with bounds, and check authorization inside `handle()`? Source: Laravel MCP docs. Check: `grep -L "validate(" app/Mcp/Tools/*Tool.php` must print nothing; MCP unit test with `Server::actingAs($otherUser)->tool(...)` asserts no foreign private data.
15. Do MCP tools reuse the same visibility scoping as REST (`listQuery()`/`showQuery()`, ban/block filters)? Source: OWASP API BOLA via MCP. Check: test creates a hidden/banned/blocked listing and asserts `SearchListingsTool` and `GetListingTool` do not return it.
16. Does the server reject tokens not issued for it and never forward the caller's token? Source: MCP security BP. Check: `grep -rn "bearerToken()" app/Mcp app/Http` and confirm no forwarding into `Http::withToken`.
17. If the product consumes third-party MCP servers: are server versions and tool-description hashes pinned and re-approved on change? Source: Invariant. Check: config lists servers with version + hash; test fails when description hash changes.

### Output validation
18. Is every structured response validated in PHP after parsing (finish reason, non-empty, schema)? Source: Prism docs. Check: `grep -rn "->structured" app` and confirm each is followed by a validator or `Validator::make`; test with `PrismFake` returning a refusal and malformed object asserts fail-closed.
19. Do customer-facing drafts pass deterministic checks for other customers' names, emails, phones, and forbidden phrases? Source: OWASP LLM02, LLM01. Check: unit tests for `ExampleLeakCheck`, `PhraseRules`, `KnownNames` with a draft that copies a name from a few-shot example must fail.
20. On validation failure, does the system fail closed with a bounded retry count? Source: OWASP cheat sheet. Check: grep retry loops near Prism calls; assert max attempts constant and a test where every attempt fails ends with no draft/side effect.

### Data protection
21. Is PII not needed for the task removed before the prompt? Source: OWASP LLM02. Check: snapshot test of the built prompt (`SupportDraftContextBuilder`) asserts no email, phone, address, or other user's name.
22. Are prompts/completions logged with redaction and a retention TTL? Source: OWASP LLM02. Check: `grep -rn "Log::.*prompt\|->prompt" app`; Telescope/Sentry filters hide AI request bodies; a prune command exists for draft/log tables (`grep -rn "prunable\|Prunable" app/Models`).
23. Does user erasure delete or anonymise every store that holds the user's text: drafts, example store, embeddings, replay fixtures, agent logs? Source: Hamburg DPA, EDPB. Check: GDPR anonymisation test seeds one row in each table and asserts it is gone or scrubbed after erasure.
24. Is provider retention configured deliberately (ZDR or `store=false`, no stateful provider features holding PII)? Source: OpenAI data controls. Check: `grep -rn "store" config/prism.php app/Prompts`; design doc states retention per provider.

### Abuse and cost
25. Is input length capped before the call? Source: OWASP LLM10. Check: FormRequest `max:` rule on every field forwarded to a model.
26. Is there a per-user and global LLM budget enforced before dispatch? Source: OWASP LLM10. Check: test exhausts `SupportCallBudget` and asserts no Prism call (`PrismFake::assertCallCount`).
27. Do AI jobs set `$tries`, `$timeout`, `$maxExceptions`, and any agent loop a max step count? Source: OWASP LLM10. Check: `grep -L "timeout" app/Jobs/*Ai*.php app/Jobs/*Idea*.php`; `grep -rn "withMaxSteps" app`.
28. Are public AI-triggering endpoints rate limited per user and per IP? Source: OWASP LLM10. Check: `php artisan route:list -v` shows `throttle:` on each.

### Testing
29. Is there a regression suite where a faked model obeys an injection and the test asserts no side effect? Source: Nasr et al.; OWASP LLM01. Check: `grep -rln "PrismFake" tests | xargs grep -l -i "inject"`.
30. Is a red-team scan (promptfoo/garak) run against the real endpoint before release, with results stored? Source: promptfoo docs. Check: a config file exists (for example `tests/redteam/promptfooconfig.yaml`) and the QA runbook names the command.

## Severity guidance

**Block the design (must fix before build):**
- Untrusted text can trigger a consequential action or outbound request with no human approval of the exact action (checklist 1, 11).
- Lethal trifecta in one run with no break (checklist 2).
- Authorization decided by prompt text, by tool visibility, or by the model (checklist 7, 14).
- Agent uses a human or admin credential, or there is no way to revoke writes quickly (6, 8).
- MCP or agent endpoint returns data beyond what the same caller gets from REST (15), or forwards tokens (16).
- Model output reaches SQL, shell, HTML render, or a URL fetch unvalidated (12, 18).
- Another user's PII can appear in a draft and there is no deterministic check (19).
- No budget, no timeout, or no loop cap on a user-reachable LLM path (26, 27).
- GDPR erasure misses a store that holds user text (23).

**Recommendation (log, do not block):**
- Spotlighting, datamarking, role placement hygiene (3).
- Adding a classifier or guardrail framework (Prompt Shields, LlamaFirewall, NeMo, Llama Guard).
- Red-team scan cadence and tooling choice (30).
- Moving from approval-gated to provenance-tracked (CaMeL-style) design.
- ZDR vs default retention when no special-category data is sent.
- Spend anomaly alerts.

Rule for the persona: a missing deterministic control is blocking; a missing probabilistic control is a recommendation.

## Skill topic candidates

1. Threat-model an LLM feature with the Rule of Two table (inputs, data, outputs per run) and pick a Beurer-Kellner pattern.
2. Write a Prism structured-output call that fails closed: schema, strict mode, finish-reason check, PHP validation, bounded retry.
3. Build deterministic output validators for customer-facing drafts: PII of others, copied example names, forbidden phrases, link allowlist, KB citation check.
4. Add an agent identity: service user, scoped Sanctum token, deny-by-default gate, permission matrix, audit log, kill switch, plus the route-sweep test.
5. Expose a Laravel MCP tool safely: auth middleware, throttle, `validate()`, in-handle authorization, reuse of model scopes, MCP unit tests with `actingAs`.
6. Consume a third-party MCP server safely: pin, hash tool descriptions, isolate, SSRF-safe egress.
7. Write injection regression tests with `PrismFake` (model obeys the attacker; assert architecture holds).
8. Run promptfoo red-team against a Laravel endpoint locally (HTTP provider, plugin set, JUnit output, threshold script) without CI services.
9. Redact PII before prompts and in logs (deterministic redactor, Telescope/Sentry filters, retention TTL).
10. Extend GDPR erasure to AI stores (drafts, few-shot examples, embeddings, replay fixtures, agent logs).
11. Budget and cap LLM usage: per-user/global budgets, job timeouts, loop caps, dedicated queue lane, spend alerts.
12. Render model output safely in admin UIs (no markdown images, link allowlist, escaping, CSP).
13. Protect learning loops from memory poisoning (what may enter the example store, provenance, rollback).

## Sources

| Title | URL | Takeaway |
|---|---|---|
| Design Patterns for Securing LLM Agents against Prompt Injections (Beurer-Kellner et al. 2025) | https://arxiv.org/html/2506.08837v3 | Six patterns; untrusted input must not trigger consequential actions; customer service = action-selector + context-minimization. |
| Defeating Prompt Injections by Design (CaMeL) | https://arxiv.org/abs/2503.18813 | Control/data-flow separation with capabilities; 77% tasks with provable security vs 84% undefended. |
| Willison: CaMeL commentary | https://simonwillison.net/2025/Apr/11/camel/ | Most promising defense; weakness is policy burden and approval fatigue. |
| Willison: The lethal trifecta | https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/ | Private data + untrusted content + exfil channel = exploitable; 95% detection fails. |
| Willison: The Dual LLM pattern | https://simonwillison.net/2023/Apr/25/dual-llm-pattern/ | Privileged vs quarantined model, variables by reference; admits social-engineering and chaining gaps. |
| Meta: Agents Rule of Two | https://ai.meta.com/blog/practical-ai-agent-security/ | At most two of untrusted input, sensitive access, external action per session. |
| Spotlighting (Hines et al.) | https://arxiv.org/abs/2403.14720 | Delimit/datamark/encode untrusted input; ASR >50% to <2% on GPT models; probabilistic. |
| MSRC: How Microsoft defends against indirect prompt injection | https://www.microsoft.com/msrc/blog/2025/07/how-microsoft-defends-against-indirect-prompt-injection-attacks | Defense in depth; deterministic block of markdown-image exfil; does not rely on blocking all injections. |
| Instruction Hierarchy (Wallace et al.) | https://arxiv.org/abs/2404.13208 | Train models to prefer higher-privilege instructions; a model property, not an app control. |
| The Attacker Moves Second (Nasr et al. 2025) | https://arxiv.org/abs/2510.09023 | Adaptive attacks broke 12 defenses at >90%; static evals are misleading. |
| Anthropic: prompt injection defenses | https://www.anthropic.com/research/prompt-injection-defenses | Training + classifiers cut ASR to ~1-2%; 1% is still meaningful risk. |
| OpenAI: Safety in building agents | https://developers.openai.com/api/docs/guides/agent-builder-safety | Structured outputs between nodes; untrusted input in user messages; keep tool approvals on. |
| OpenAI Agents SDK guardrails | https://openai.github.io/openai-agents-python/guardrails/ | Input/output/tool guardrails; parallel mode lets side effects happen first; coverage gaps. |
| OWASP Top 10 for LLM Applications 2025 | https://genai.owasp.org/llm-top-10/ | LLM01-LLM10 index. |
| OWASP LLM01 Prompt Injection | https://genai.owasp.org/llmrisk/llm01-prompt-injection/ | Seven mitigations; RAG/fine-tuning do not fix it. |
| OWASP LLM02 Sensitive Information Disclosure | https://genai.owasp.org/llmrisk/llm022025-sensitive-information-disclosure/ | Sanitize before processing; system-prompt restrictions are bypassable. |
| OWASP LLM05 Improper Output Handling | https://genai.owasp.org/llmrisk/llm052025-improper-output-handling/ | Zero-trust output, context-aware encoding, parameterised queries, CSP. |
| OWASP LLM06 Excessive Agency | https://genai.owasp.org/llmrisk/llm062025-excessive-agency/ | Minimise tools, functions, permissions; user context; complete mediation; HITL. |
| OWASP LLM10 Unbounded Consumption | https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/ | Denial of wallet; input limits, quotas, timeouts, queue caps, monitoring. |
| OWASP LLM Prompt Injection Prevention Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html | Lists anti-patterns; keyword filters and delimiters are not enforcement; Best-of-N. |
| OWASP Agentic AI Threats and Mitigations (summary) | https://securedgenai.substack.com/p/review-agent-security | T1-T15 with mitigation playbooks (secondary source). |
| OWASP Top 10 for Agentic Applications 2026 (summary) | https://goteleport.com/blog/owasp-top-10-agentic-applications | ASI01-ASI10 with mitigations (secondary source). |
| OWASP Agentic AI Threats and Mitigations (primary page) | https://genai.owasp.org/resource/agentic-ai-threats-and-mitigations/ | v1.0, 17 Feb 2025; PDF download. |
| MCP Security Best Practices | https://modelcontextprotocol.io/specification/draft/basic/security_best_practices | Confused deputy, token passthrough ban, SSRF, state handle hijack, scope minimisation. |
| MCP Authorization spec 2025-11-25 | https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization | OAuth 2.1, RFC 9728 metadata, RFC 8707 audience binding, PKCE, no passthrough. |
| Invariant Labs: MCP tool poisoning | https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks | Hidden instructions in tool descriptions, rug pulls, cross-server shadowing; pin and isolate. |
| Invariant Labs: GitHub MCP exploit | https://invariantlabs.ai/blog/mcp-github-vulnerability | Toxic agent flow; one repo per session; "Always Allow" defeated confirmation. |
| Laravel MCP docs | https://laravel.com/docs/12.x/mcp | Sanctum/Passport auth; single `mcp:use` scope; `shouldRegister`; `validate()`; `actingAs` tests. |
| Prism structured output | https://prismphp.com/core-concepts/structured-output.html | Strict mode; refusal returns empty without throwing; always validate in app. |
| Embrace The Red: markdown image exfiltration | https://embracethered.com/blog/posts/2023/chatgpt-webpilot-data-exfil-via-markdown-injection/ | Injected markdown image URL leaks chat data on render. |
| OpenAI data controls | https://developers.openai.com/api/docs/guides/your-data | 30-day abuse logs; ZDR forces store=false; vector stores/files not ZDR-eligible. |
| Anthropic data retention | https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data | 30-day default; ZDR by agreement; flagged content kept up to 2 years. |
| Hamburg DPA discussion paper on LLMs | https://datenschutz-hamburg.de/fileadmin/user_upload/HmbBfDI/Datenschutz/Informationen/240715_Discussion_Paper_Hamburg_DPA_KI_Models.pdf | Model holds no personal data; rights apply to system inputs/outputs. |
| EDPB Opinion 28/2024 (CMS summary) | https://cms.law/en/int/legal-updates/edpb-opinion-28-2024-key-takeaways-on-processing-personal-data-in-the-context-of-ai-models | Anonymity case-by-case; negligible extraction risk required. |
| NeMo Guardrails | https://docs.nvidia.com/nemo/guardrails/latest/index.html | Python rails (input/dialog/retrieval/execution/output); Presidio PII, Llama Guard; server mode usable from PHP over HTTP. |
| LlamaFirewall | https://arxiv.org/abs/2505.03574 | PromptGuard 2, AlignmentCheck (experimental), CodeShield; detector layer. |
| AgentDojo | https://github.com/ethz-spylab/agentdojo | Python benchmark for agent injection attacks/defenses. |
| InjecAgent | https://arxiv.org/abs/2403.02691 | 1,054 IPI cases; ReAct GPT-4 vulnerable 24%, about double with hacking prompt. |
| promptfoo red teaming | https://www.promptfoo.dev/docs/red-team/plugins/ | Plugins for indirect injection, PII, excessive agency, BOLA/BFLA, SSRF, data-exfil, MCP. |
| promptfoo HTTP provider | https://www.promptfoo.dev/docs/providers/http/ | Point red-team at any REST endpoint with a bearer token. |
| promptfoo CI/CD | https://www.promptfoo.dev/docs/integrations/ci-cd/ | Shell-run in any CI; JUnit output; `--fail-on-error`; cache path. |
| garak | https://github.com/NVIDIA/garak | LLM vulnerability scanner; `rest.RestGenerator` targets any REST API. |
