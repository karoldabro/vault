# security-architect plan-critic: grounding

Lens: architecture-level security of a WRITTEN PLAN, before code exists. Code-level bugs belong to the code security reviewer.
Sources fetched 2026-10-12 unless marked UNVERIFIED.

## 1. Plan-review questions (each asks what the plan states; silence is the finding)
1. Which components, data stores and external parties does the plan add, and where are the trust boundaries? ASVS 4.0.3 V1.1.2 requires threat modeling for design changes; V1.1.4 requires documented trust boundaries and data flows. https://github.com/OWASP/ASVS/blob/v4.0.3/4.0/en/0x10-V1-Architecture.md
2. For each new endpoint, job or tool: who may call it, and where is the check enforced? V1.4.1 requires trusted server-side enforcement points; V1.4.4 one access-control mechanism. https://github.com/OWASP/ASVS/blob/v4.0.3/4.0/en/0x10-V1-Architecture.md
3. Does every read or write of an object keyed by a client-supplied ID check ownership (BOLA), and every privileged function check role (BFLA)? https://api-security.owasp.org/editions/2023/en/0x11-t10
4. Which fields may a client set or see (property-level authz, mass assignment)? API3:2023. https://api-security.owasp.org/editions/2023/en/0x11-t10
5. How are tenants isolated: at every tier, or only in a WHERE clause? A04 prevention: "Isolate tenants by design across all tiers". https://top10.owasp.org/2021/A04_2021-Insecure_Design
6. What data does the plan collect or move, how is it classified, and what are retention, access and deletion rules? V1.8.1/1.8.2 require classification with protection requirements per level. https://github.com/OWASP/ASVS/blob/v4.0.3/4.0/en/0x10-V1-Architecture.md ; GDPR Art. 25 (minimisation, retention, who can access, by default). https://gdpr-info.eu/art-25-gdpr/
7. Where do secrets live, who can read them, how are they rotated? V1.6.1 requires an explicit key-management policy; V1.6.4 treats client-side secrets as insecure. https://github.com/OWASP/ASVS/blob/v4.0.3/4.0/en/0x10-V1-Architecture.md
8. What can an abuser do repeatedly: enumerate, scrape, trigger paid calls, exhaust storage? API4 Unrestricted Resource Consumption, API6 Unrestricted Access to Sensitive Business Flows; A04 "Limit resource consumption per user or service". https://api-security.owasp.org/editions/2023/en/0x11-t10 ; https://top10.owasp.org/2021/A04_2021-Insecure_Design
9. What new public surface appears (uploads, webhooks, callbacks, admin paths, user-supplied URLs)? Webhook/URL fetch = SSRF (API7); uploads need V1.12.2 handling (octet-stream download or unrelated domain). https://api-security.owasp.org/editions/2023/en/0x11-t10 ; https://github.com/OWASP/ASVS/blob/v4.0.3/4.0/en/0x10-V1-Architecture.md
10. Does a new dependency, third-party API or model enter the trust path, and who vets it? API10 Unsafe Consumption of APIs; LLM03 Supply Chain. https://api-security.owasp.org/editions/2023/en/0x11-t10 ; https://genai.owasp.org/llm-top-10/
11. What is logged, where is it sent, and can the log hold PII, tokens or prompts? Is there an audit trail for privileged actions (STRIDE Repudiation)? V1.7.1/1.7.2 common format, remote secure transport. https://github.com/OWASP/ASVS/blob/v4.0.3/4.0/en/0x10-V1-Architecture.md ; https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats
12. AI features: what untrusted text reaches the model (user input, web pages, files, tool output), what can the model do with it, and what stops exfiltration? LLM01 Prompt Injection (cannot be fully prevented; limit impact), LLM06 Excessive Agency (functionality, permissions, autonomy). https://genai.owasp.org/llmrisk/llm01-prompt-injection/ ; https://genai.owasp.org/llmrisk/llm062025-excessive-agency/
13. (Optional, if PII) Which LINDDUN threats apply: linking, identifying, detecting, disclosure, unawareness, non-compliance? https://linddun.org/

## 2. Five-minute procedure on a written plan
Frame: Shostack's four questions: what are we working on, what can go wrong, what will we do about it, did we do a good enough job. https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html
1. List deltas only: new endpoints, jobs, stores, external calls, dependencies, roles, data fields, secrets, agent tools. Ignore unchanged system.
2. Draw the flow in text: actor -> entry point -> process -> store/external. Mark every trust boundary crossing (internet, tenant, service, privilege, user content -> LLM). The OWASP method models data flows, trust boundaries, stores, processes, external entities as the likely attack points. https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html
3. Per crossing apply STRIDE: Spoofing (authN), Tampering (integrity), Repudiation (audit), Information disclosure (confidentiality), DoS (availability), Elevation of privilege (authZ). https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html ; https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats
4. For each data field: classify, then check collection purpose, retention, access, deletion (Art. 25; V1.8). For each AI tool: list functionality, permissions, autonomy (LLM06).
5. For each threat record the plan's response: mitigate, eliminate, transfer, accept. Missing response = finding. Rank by likelihood x impact. https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html
6. Verify testability: each mitigation needs a named test or check in the plan (A04: tests covering use and misuse cases). https://top10.owasp.org/2021/A04_2021-Insecure_Design
7. Output: findings tied to a plan section, each with the missing decision, not a generic warning.
Cheat sheet: do not add techniques "to appear comprehensive"; keep it proportionate and repeat when the design changes. https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html

## 3. Grounding: evidence that confirms a finding at plan time
Rule: a finding needs a quote from the plan or a file path from the repo. "Could be insecure" is not a finding.
- Missing authz: plan adds a route/handler/tool and states no caller, role, or ownership rule. Evidence: the plan line + `grep` of the repo's route definitions showing the existing guard (file path) the new route does not mention.
- Bypassed middleware: repo has an auth/tenant middleware (find via grep for `auth`, `middleware`, `guard`, `policy`, `tenant`) and the plan puts the new path outside it (public router, separate server, cron/webhook entry). Cite the middleware file path and the plan section.
- PII without rules: plan adds a column/field/event property (email, name, location, IP, device id, free text, uploads) with no retention, access, deletion, or log-redaction statement. Cite the field and compare with existing schema/migration files for how similar fields are handled.
- Secret named in config: plan puts a key, token, DSN or password in a config file, env example with real value, client bundle, or prompt. Cite the line. Never open `~/.keys/`; check only that the plan references a path or secret manager.
- New dependency: plan names a package/SDK/model/API. Check: registry age, maintainers, weekly downloads, license, install scripts, last release, known advisories (e.g. `pnpm view <pkg>`, `pnpm audit`, https://osv.dev). Evidence = the lookup output; report "unchecked" if offline. Supply-chain grounding: LLM03, API10. https://genai.owasp.org/llm-top-10/
- Unbounded cost: plan calls a paid API (LLM, SMS, email, storage) from a user-triggerable path with no quota, per-user cap or rate limit. Cite the call and the trigger. LLM10 Unbounded Consumption. https://genai.owasp.org/llm-top-10/
- Enumeration: plan uses sequential/guessable IDs or distinguishable "not found" vs "forbidden" responses on a public route. Cite the ID scheme in the schema.
- User-controlled URL: plan fetches a URL the user supplies (webhook target, import, link preview) with no allowlist. SSRF, API7. https://api-security.owasp.org/editions/2023/en/0x11-t10
- Agent over-reach: plan gives an LLM/agent a shell, generic DB, broad OAuth scope, or send/delete tools, or runs it with a shared high-privilege identity; no confirmation step for high-impact actions. LLM06. https://genai.owasp.org/llmrisk/llm062025-excessive-agency/
- LLM exfiltration path: untrusted content (web, email, file, tool output) and private data in the same context, plus an output channel to an attacker-reachable sink (rendered image/link, outbound tool, webhook). Documented scenario: hidden instructions make the model emit an image URL that leaks the conversation. https://genai.owasp.org/llmrisk/llm01-prompt-injection/
- Authorization delegated to the model: plan says "the model decides if the user may do X". Downstream system must enforce. https://genai.owasp.org/llmrisk/llm062025-excessive-agency/
- Sensitive log: plan logs request bodies, prompts, or tokens. Cite the log statement/config.

## 4. Severity examples at plan level
Severity = likelihood x impact, with the plan's declared exposure (internet, tenant data, money). Rank method: https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html
- BLOCKER: multi-tenant read/write endpoint keyed by client ID with no ownership/tenant rule; secret placed in client bundle or repo; agent with write/send tools reading untrusted content with no human approval and no downstream authz; new public endpoint outside the existing auth middleware; user-supplied URL fetched server-side with no egress rule.
- MAJOR: PII collected with no retention/deletion/access rule; paid call on a public path with no per-user cap; upload with no type/size/serving-domain decision; admin path reachable on the public host; unvetted dependency in the auth/payment/parse path; logs that capture PII or prompts.
- MINOR: guessable IDs behind authz (hygiene only); missing audit log on low-value actions; no rate limit on an authenticated, free, cheap endpoint; dependency choice undocumented but well-known.
- NOTE (raise, do not gate): residual risk the plan explicitly accepts with an owner (cheat sheet allows "accept"). https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html

## 5. Scale awareness (what NOT to demand)
Basis: the cheat sheet warns against techniques added to look comprehensive; GDPR Art. 25 itself weighs state of the art, cost and risk to individuals; CISA asks for defaults secure out of the box, not maximal controls. https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html ; https://gdpr-info.eu/art-25-gdpr/ ; https://www.cisa.gov/securebydesign
- Small internal tool / single-user / local CLI (the repo's own shell scripts and hooks are in this class): do not demand tenant isolation, WAF, rate limits, SSO, formal DFDs, SOC2-style audit logs, or a pentest. DO still demand: no secret in repo, no untrusted input into shell/eval, least privilege for agents, a vetted new dependency.
- Internal tool with an AI agent: agent scope and approval gates still apply in full (LLM06); the blast radius is the operator's machine and credentials.
- Public single-tenant app: add authN, rate limits on cost-bearing and enumerable paths, upload handling, retention for PII.
- Public multi-tenant product: add per-object and per-tenant authz at every tier, abuse/cost caps, audit trail for privileged actions, data classification, privacy review (LINDDUN/Art. 25), dependency policy.
- Rule: scale the ask to declared exposure and data class in the plan. If the plan does not state exposure, ask that one question first; do not assume the worst.
- Do not demand: mitigations for threats the plan removes by design (eliminate beats mitigate), controls for unchanged parts of the system, or compliance paperwork the plan owner has not been told applies.
- Not-a-finding: "might use a vulnerable library" without a named package; generic "add encryption".

## 6. Decorrelation
- vs code-level security reviewer: it reads diffs for injection, XSS, unsafe deserialization, missing validation, crypto misuse, off-by-one authz in a given handler. security-architect reads the PLAN for whether an authz model, data rule, secret home, or abuse limit EXISTS at all. Test: if the finding needs a line of code to confirm, hand it off; if it is a missing decision in the plan, keep it. The ASVS split is the same: V1 architecture vs per-feature verification chapters. https://github.com/OWASP/ASVS/blob/v4.0.3/4.0/en/0x10-V1-Architecture.md
- vs system-integration reviewer: it checks that components fit (contracts, ordering, versions, failure modes, rollback, existing callers). security-architect asks who is allowed, what leaks, what is abused. Overlap zone (new webhook, new service-to-service call): integration owns the contract and failure behavior; security owns authentication of the caller, boundary, and abuse. Do not report a broken contract or retry storm; do report an unauthenticated internal call (V1.2.2 authentication between components, V1.9 encrypted/authenticated communications). https://github.com/OWASP/ASVS/blob/v4.0.3/4.0/en/0x10-V1-Architecture.md
- Report format: one finding = plan quote or file path, STRIDE/OWASP tag, severity, the decision the plan must add. No code fixes.

## Reference list (framework identities)
- OWASP Top 10 2021 A04 prevention list: https://top10.owasp.org/2021/A04_2021-Insecure_Design
- OWASP Top 10 for LLM 2025 (LLM01-LLM10): https://genai.owasp.org/llm-top-10/
- OWASP API Security Top 10 2023 (API1-API10): https://api-security.owasp.org/editions/2023/en/0x11-t10
- LINDDUN (7 categories; GO/PRO variants, GO = lean card deck): https://linddun.org/
- NIST SSDF SP 800-218 v1.1 (Feb 2022): https://csrc.nist.gov/pubs/sp/800/218/final

## Not verified
- NIST SSDF practice IDs (PW.1.1 design/threat modeling) not confirmed; the landing page does not list them. Cite SP 800-218 generally.
- ASVS v5 not fetched; V1 references are v4.0.3 (v5 renumbered chapters).
- CISA Secure by Design: principles confirmed; specific guidance pages (404 on one URL) not read.
- Shostack's book not fetched; the four questions are confirmed via the OWASP cheat sheet.
- Dependency-check tools (osv.dev, pnpm audit) are standard practice, not sourced from the research fetches.
