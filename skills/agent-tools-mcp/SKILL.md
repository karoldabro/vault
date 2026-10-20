---
name: agent-tools-mcp
description: Load when you design tools for a product LLM agent, expose your API as an MCP server, or connect an agent to third-party MCP servers.
---

# Agent tools and MCP

## When to use

- You write or review a tool that an agent inside your API calls.
- You expose existing API endpoints to agents as an MCP server.
- Your product agent loads tools from an MCP server you do not own.
- A review of `personas/_shared/planning/agent-systems.md` raises tool design or MCP exposure.

## Rules

Tool contract:

- **Build one tool per user workflow, not one per endpoint.** Overlapping tools waste tokens and make the model pick the wrong one. https://www.anthropic.com/engineering/writing-tools-for-agents
- **Prefix every tool name with a namespace, such as `acme_listings_search`.** Tools from several sources otherwise collide. https://www.anthropic.com/engineering/writing-tools-for-agents
- **Make wrong arguments impossible to send: enums, strict schemas, `user_id` instead of `user`.** The schema then rejects the error before the handler runs. https://www.anthropic.com/engineering/building-effective-agents
- **Return a readable name beside every ID.** A bare ID makes the model guess or invent references. https://www.anthropic.com/engineering/writing-tools-for-agents
- **Offer a `response_format` argument with `concise` and `detailed` values.** The concise form used about one third of the tokens. https://www.anthropic.com/engineering/writing-tools-for-agents
- **Give every list or search tool a default limit, a maximum and a page cursor.** Unbounded output fills the context and lowers accuracy. https://www.anthropic.com/engineering/writing-tools-for-agents
- **When you truncate output, tell the model which filter narrows the query.** The model then refines the call instead of repeating it. https://www.anthropic.com/engineering/writing-tools-for-agents
- **Return a bad call as a tool result with `isError: true`, the wrong field and a valid example.** A stack trace gives the model nothing to correct. https://modelcontextprotocol.io/specification/2025-06-18/server/tools
- **Use protocol errors only for an unknown tool or a malformed request.** Every other failure is something the model can fix. https://modelcontextprotocol.io/specification/2025-06-18/server/tools
- **Rate every tool `read`, `write` or `irreversible` in code.** Code reads the rating and sends `irreversible` calls to the approval flow in `skills/agent-trust-boundaries/SKILL.md`. https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf

Exposing your API as an MCP server:

- **Put authentication middleware on the MCP route for every non-public tool.** A route without it serves every caller. https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
- **Accept only tokens issued for your server, and never forward the caller's token downstream.** A forwarded token lets a client act through your server and breaks the audit trail. https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices
- **Never authenticate a caller by the MCP session ID.** A session ID is not a credential; key session state as `<user_id>:<session_id>`. https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices
- **Throttle the MCP route per user and per IP.** The spec requires servers to rate-limit tool calls. https://modelcontextprotocol.io/specification/2025-06-18/server/tools
- **Validate every argument as a form request does: type, maximum length, enum.** Untrusted text can steer the model that writes the arguments. https://laravel.com/docs/12.x/mcp
- **Check authorization inside each tool handler on every call.** Hiding a tool from the list does not stop a client that calls it by name. https://laravel.com/docs/12.x/mcp
- **Query through the same visibility scopes the REST endpoint uses.** Otherwise the MCP server returns rows that REST hides, such as banned or blocked content. https://modelcontextprotocol.io/specification/draft/basic/security_best_practices
- **Declare an output schema, return conforming structured content, and repeat the JSON as text.** Clients then parse results without guessing. https://modelcontextprotocol.io/specification/2025-06-18/server/tools

Consuming third-party MCP servers:

- **List allowed servers and allowed tool names explicitly in config.** A new tool on an allowed server otherwise reaches the agent unreviewed. https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices
- **Pin each server version and a hash of each tool description, and re-approve when a hash changes.** A server can rewrite a description after approval to hide instructions in it. https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks
- **Treat annotations such as `readOnlyHint` as untrusted.** A malicious server can label a destructive tool read-only. https://modelcontextprotocol.io/specification/2025-06-18/server/tools
- **Send outbound MCP traffic through SSRF controls: HTTPS only, private ranges blocked, each redirect checked.** A peer can otherwise point your server at internal addresses. https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices
- **Limit each agent session to one trust scope, such as one customer.** One session with broad access leaked private repository data through an injected issue. https://invariantlabs.ai/blog/mcp-github-vulnerability

## Steps

1. List the user workflows the agent serves. Write one tool for each workflow.
2. For each tool, write the namespaced name, a description, the argument schema, the risk rating and the output schema.
3. Write the handler in this order: validate arguments, authorize the caller, run the scoped query, cap the output, add readable names.
4. Return every failure the model can fix as an error result that names the field and a valid value.
5. Register the route with authentication and throttle middleware.
6. Write the tests listed in Checks, acting as a second user.
7. Run the MCP inspector against the route and call each tool once with valid and invalid arguments.
8. For a third-party server, add it to the allowlist, store its version and description hashes, and route its traffic through the egress controls.

## Checks

- `grep -L 'validate(' app/Mcp/Tools/*.php` prints nothing.
- `grep -L -E 'can\(|authorize\(|Gate::' app/Mcp/Tools/*.php` prints nothing.
- `php artisan route:list --path=mcp -v` shows authentication and `throttle:` middleware on every non-public MCP route.
- `grep -rn 'bearerToken()' app/Mcp` shows no value passed into `Http::withToken`.
- Test: user B calls a tool on user A's private record and gets an error result with none of A's fields.
- Test: a hidden, banned or blocked record is absent from both the REST response and the tool result.
- Test: with 500 seeded rows, a list tool returns at most its maximum, stays under a byte budget, and includes a cursor.
- Test: an invalid argument returns `isError: true` and the error text names the field.
- Test: every tool class carries a risk rating; the test fails for a class without one.
- Test: a changed tool description hash on a third-party server blocks the tool until re-approval.

## Laravel

Detect each package before you use it: `composer show laravel/mcp`, `composer show prism-php/prism`, `composer show prism-php/relay`, `composer show laravel/ai`. Never assume one is installed.

- `laravel/mcp`: register with `Mcp::web('/mcp/<name>', Server::class)->middleware([...])` in `routes/ai.php`. Use Sanctum or Passport middleware there.
- `laravel/mcp` OAuth offers one `mcp:use` scope, so per-tool authorization lives in code.
- `shouldRegister()` hides a tool from the list. Call `$request->user()->can(...)` inside `handle()` as well, because hiding does not deny.
- Validate with `$request->validate([...])` inside `handle()`.
- Return `Response::error('...')` for a failure the model can fix. Declare `outputSchema()` and return `Response::structured([...])`.
- Annotate with `#[IsReadOnly]`, `#[IsDestructive]`, `#[IsIdempotent]` or `#[IsOpenWorld]`. Clients read these as hints, so enforce the rating in code too.
- Test with `Server::actingAs($user)->tool(Tool::class, [...])` and assert with `assertOk()`, `assertHasErrors()`, `assertDontSee()` or `assertStructuredContent()`.
- Inspect with `php artisan mcp:inspector <route>`.
- Prism: define tools with `Tool::as('ns_name')->for('...')->using(fn (...) => ...)`. Tool use needs `withMaxSteps()`. Prism returns tool exceptions to the model as errors by default.
- Prism Relay: list servers in `config/relay.php` with a timeout each. Relay has no per-tool allowlist, so filter `Relay::tools('<server>')` by name before `withTools()`.

## Sources

- Writing effective tools for agents (Anthropic): https://www.anthropic.com/engineering/writing-tools-for-agents
- Building effective agents (Anthropic): https://www.anthropic.com/engineering/building-effective-agents
- A practical guide to building agents (OpenAI): https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf
- MCP tools specification 2025-06-18: https://modelcontextprotocol.io/specification/2025-06-18/server/tools
- MCP security best practices 2025-06-18: https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices
- MCP security best practices, draft: https://modelcontextprotocol.io/specification/draft/basic/security_best_practices
- MCP authorization 2025-11-25: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
- MCP tool poisoning attacks (Invariant Labs): https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks
- GitHub MCP exploit (Invariant Labs): https://invariantlabs.ai/blog/mcp-github-vulnerability
- Laravel MCP documentation: https://laravel.com/docs/12.x/mcp
- Prism tools and function calling: https://prismphp.com/core-concepts/tools-function-calling.html
- Prism Relay: https://github.com/prism-php/relay
