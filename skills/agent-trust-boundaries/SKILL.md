---
name: agent-trust-boundaries
description: Load when a product's LLM agent reads third-party text, touches private data, or can write or send: trust table, injection patterns, authorization, approvals, injection tests.
---

# Agent trust boundaries

Assume the model is fully compromised by any untrusted text it reads. The design is safe only if that compromised model still cannot act or leak.

## When to use

- A run reads text a non-operator wrote: a customer message, a post, a comment, a knowledge entry, a tool result.
- A run can write, send, call a URL, or reach another user's data.
- You expose an MCP server or issue an agent token that can write.
- A review of `personas/_shared/planning/agent-systems.md` raises untrusted input, authorization, agent identity or approvals.

## Rules

- **Fill the trust table for every agent run before you build it.** One run holding untrusted input, private data and an outbound channel can leak data. https://ai.meta.com/blog/practical-ai-agent-security/
- **Make sure untrusted input never triggers a consequential action on its own.** Injection is unsolved, so only the architecture limits what injected text can do. https://arxiv.org/html/2506.08837v3
- **Count detectors, spotlighting, delimiters and prompt rules as hygiene, never as the boundary.** Adaptive attacks broke 12 published defenses at over 90% success. https://arxiv.org/abs/2510.09023
- **Put untrusted text in the user message, never in the system prompt.** This lowers attack success, but it does not stop an attack. https://developers.openai.com/api/docs/guides/agent-builder-safety
- **Check authorization in code inside each tool call, and deny every route and tool by default.** A prompt rule or a hidden tool does not deny anything (OWASP LLM06). https://genai.owasp.org/llmrisk/llm062025-excessive-agency/
- **Run each agent under its own revocable identity, scoped to the end user's permissions and separate from every human account.** A shared admin token gives injected text admin power and breaks the audit trail. https://www.microsoft.com/msrc/blog/2025/07/how-microsoft-defends-against-indirect-prompt-injection-attacks
- **Bind each approval to the exact action, target and payload hash, and re-check the hash before execution.** The model can describe one action and run another. https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html
- **Never offer an "always allow" option.** The GitHub MCP exploit ran through a confirmation the user had set to always allow. https://invariantlabs.ai/blog/mcp-github-vulnerability
- **Block exfiltration channels in code: no rendered markdown images, no links outside an allowlist, no model-chosen URLs or recipients.** A rendered image URL sends private data out with zero clicks. https://embracethered.com/blog/posts/2023/chatgpt-webpilot-data-exfil-via-markdown-injection/
- **Test the architecture with a fake model that obeys the attacker.** A real model refusing once proves nothing about the next attempt (OWASP LLM01). https://genai.owasp.org/llmrisk/llm01-prompt-injection/

What may enter the example store lives in `skills/agent-self-improvement/SKILL.md`.

## Steps

1. List every agent run. A run is one model call or loop that shares one context.
2. Fill one row per run in the trust table below. Read the context builder and every consumer of the output; do not fill it from memory.

   | run | untrusted input (A) | private data (B) | outbound or write channel (C) | which leg is broken, and by what code |
   |---|---|---|---|---|

   A is any text a non-operator wrote. B is data the requester could not read through the REST API. C is any send, write, URL fetch, webhook, rendered link or image, or tool with side effects.
3. For a row with A, B and C, break one leg in code, or put a human approval of the exact action on C.
4. Pick the injection pattern that fits the run.

   | pattern | how it works | fits when |
   |---|---|---|
   | action-selector | the model picks one action from a fixed list; tool output never returns to the model | moderation verdicts, routing, tagging |
   | plan-then-execute | code fixes the action list before the model reads untrusted data | multi-step agents; argument tampering is still possible |
   | LLM map-reduce | each untrusted item gets its own call; code aggregates only booleans, enums or numbers | moderation or tagging over many posts |
   | dual LLM | a privileged model calls tools and never sees untrusted text; a quarantined model reads it with no tools; code passes values by reference | an agent must read untrusted text and act |
   | code-then-execute (CaMeL) | code tracks the source of every value; a policy blocks or asks approval for tool calls with tainted arguments | high-value agents with real tools |
   | context-minimization | code drops the user's raw text once it maps to an intent | answers come from a knowledge base, not the user's words |

5. When the run must read the untrusted text, context-minimization does not fit. Break leg C with a human who sees the exact output, every link and the recipient before anything leaves.
6. Then confirm the run has no other outbound path. Check tool calls, URL fetches, rendered markdown or images, and webhooks fed by model output.
7. Guard any learning loop with `skills/agent-self-improvement/SKILL.md`.
8. Give each agent its own service user and token. Write the granted routes or tools in one permission file and deny everything else.
9. Store approvals as rows: actor, action, target, payload hash, expiry. Refuse execution when the hash differs.
10. Write the injection regression tests in `## Checks`. Schedule a red-team scan with promptfoo or garak before each release. A passing scan is a sample, not proof.

## Checks

- Find every model call and follow each result to its consumers:
  `grep -rn "Prism::\|->structured\|->text\b" app/`
  Any `->create(`, `->update(`, `Http::`, `Mail::` or `dispatch(` reached without an approval row fails the check.
- Find model-chosen URLs and recipients:
  `grep -rn "Http::\(get\|post\)\|Mail::to" app/` and confirm no argument comes from model output.
- Find untrusted text in system prompts:
  `grep -rn "withSystemPrompt" app/` and confirm no customer or user field is interpolated there.
- Find concatenated batches that break map-reduce:
  `grep -rn "implode\|->join(" app/Prompts`
- Unescaped rendering checks live in `skills/agent-output-validation/SKILL.md`.
- Route sweep test: iterate `Route::getRoutes()` and assert the agent token gets 403 on every route outside the granted list.
- Approval test: approve an action, change one payload byte, execute, and assert refusal and no side effect.
- Injection test shape:
  1. Put a payload in one untrusted field, for example a customer message that asks to email the knowledge base to an outside address.
  2. Fake the model so it returns exactly what the attacker wants: a tool call, an outside link, a markdown image, another customer's email.
  3. Assert the deterministic controls hold: no outbound request, no write, validator rejection, no new example-store row.
- Confirm the tests exist:
  `grep -rln "PrismFake\|::fake(" tests | xargs grep -li "inject"`
- Red-team scan: promptfoo with the HTTP provider against the real endpoint, plugins `indirect-prompt-injection`, `pii`, `excessive-agency`, `bola`, `data-exfil`.

## Laravel

Detect the stack first; never assume it:
`composer show prism-php/prism laravel/ai laravel/mcp prism-php/relay 2>/dev/null`

- Prism PHP: fake the model with `Prism::fake([...])`, which returns `PrismFake`. Return the attacker's tool call or text, then assert side effects with `Http::fake()`, `Mail::fake()`, `Queue::fake()` and database assertions.
- `laravel/ai`: mark consequential tools `Approvable` and resolve them with `Decision::approve` or `Decision::reject`. Bind the decision to the payload hash in your own table. Fake with `Agent::fake()->preventStrayPrompts()`.
- `laravel/mcp`: per-tool authorization lives in `skills/agent-tools-mcp/SKILL.md`.
- Agent token: a service user per agent with a Sanctum token and explicit abilities, for example `$user->createToken('agent', ['posts:read'])`. Revoke it with `$token->delete()`.
- Gate: one deny-by-default middleware maps each route name to a grant in one permission file and returns 403 for the rest. Iterate `Route::getRoutes()` in the sweep test.
- The audit log row per mutating request lives in `skills/agent-runtime-ops/SKILL.md`.

## Sources

- Design Patterns for Securing LLM Agents against Prompt Injections — https://arxiv.org/html/2506.08837v3
- Defeating Prompt Injections by Design (CaMeL) — https://arxiv.org/abs/2503.18813
- Willison, The lethal trifecta — https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/
- Willison, The Dual LLM pattern — https://simonwillison.net/2023/Apr/25/dual-llm-pattern/
- Meta, Agents Rule of Two — https://ai.meta.com/blog/practical-ai-agent-security/
- Spotlighting (Hines et al.) — https://arxiv.org/abs/2403.14720
- The Attacker Moves Second (Nasr et al.) — https://arxiv.org/abs/2510.09023
- MSRC, defending against indirect prompt injection — https://www.microsoft.com/msrc/blog/2025/07/how-microsoft-defends-against-indirect-prompt-injection-attacks
- OpenAI, Safety in building agents — https://developers.openai.com/api/docs/guides/agent-builder-safety
- OWASP LLM01 Prompt Injection — https://genai.owasp.org/llmrisk/llm01-prompt-injection/
- OWASP LLM06 Excessive Agency — https://genai.owasp.org/llmrisk/llm062025-excessive-agency/
- OWASP LLM Prompt Injection Prevention Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html
- Invariant Labs, GitHub MCP exploit — https://invariantlabs.ai/blog/mcp-github-vulnerability
- Embrace The Red, markdown image exfiltration — https://embracethered.com/blog/posts/2023/chatgpt-webpilot-data-exfil-via-markdown-injection/
- Laravel MCP — https://laravel.com/docs/12.x/mcp
- Laravel AI SDK — https://laravel.com/docs/13.x/ai-sdk
- promptfoo red-team plugins — https://www.promptfoo.dev/docs/red-team/plugins/
- garak — https://github.com/NVIDIA/garak
