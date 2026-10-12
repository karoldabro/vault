# harness-engineer: plan-critic grounding

Scope: reviews plans whose deliverable is a harness (commands, prompts, sub-agents, critic panels, hooks, tools, MCP, eval scripts). The runtime is an LLM reading text.
Sources: BEA = https://www.anthropic.com/engineering/building-effective-agents ; CE = https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents ; WT = https://www.anthropic.com/engineering/writing-tools-for-agents ; MA = https://www.anthropic.com/engineering/multi-agent-research-system ; MAST = https://arxiv.org/abs/2503.13657 (detail: https://arxiv.org/html/2503.13657v3) ; HH = https://hamel.dev/blog/posts/evals/ ; 12F = https://github.com/humanlayer/12-factor-agents ; OAI = https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf ; LJ = https://arxiv.org/abs/2306.05685 ; LT = https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/

## 1. Questions the critic asks (10-12)
1. Simplest pattern? Is a single call or fixed workflow enough before an autonomous agent or panel? "simplest solution possible, only increasing complexity when needed" (BEA). OpenAI also advises single agent first (secondary summaries only; see unverified) (OAI).
2. Where is the line between deterministic code and model judgement? Control flow, parsing, counting, file moves belong in scripts; the plan must name each. 12F factor 8 "own your control flow", factor 4 tools as structured outputs executed by code (12F). Workflows = predefined code paths (BEA).
3. How is each success claim verified mechanically (test, gate script, exit code, schema check) rather than by the model saying "done"? Agents need environment "ground truth" each step (BEA). MAST: no/incorrect verification = 8.2% + 9.1% of failures; premature termination 6.2% (MAST html). Judge end state, not path (MA).
4. Context budget per agent: what loads at start, what loads on demand, what returns? Context is finite, each token draws on an attention budget; prefer just-in-time references over preloading (CE). Sub-agents return condensed summaries (~1-2k tokens) (CE).
5. Stop conditions: max iterations, max spawns, max review rounds, wall-clock or token cap? Include "stopping conditions (such as a maximum number of iterations)" (BEA). MAST: step repetition 15.7%, unaware of termination 12.4% (MAST html).
6. Effort scaling: does the prompt tell the agent how much to spend by task size? Early failure was overinvesting on simple queries; scaling rules went into prompts (MA). Multi-agent costs ~15x chat tokens; is the task worth it? (MA)
7. Tool/command contract: inputs, outputs, error shapes, destructive flags, absolute paths, unambiguous parameter names? Tools get "as much prompt engineering attention as your overall prompts" (BEA); `user_id` not `user`, actionable errors, concise/detailed response option (WT).
8. Tool set minimal and non-overlapping? If a human cannot pick the right tool, neither can the agent (CE). Consolidate multi-step tools (WT).
9. Handoff text: can the receiver act on it alone? Each sub-agent needs objective, output format, tool/source guidance, task boundaries (MA). MAST FC2: standardize protocols, ambiguity -> task derailment 7.4%, no clarification 6.8% (MAST html).
10. Failure containment: if an agent dies mid-run, what state is on disk, can the run resume without restart, and is a partial output distinguishable from a complete one? Resume from where errors occurred plus retries and checkpoints (MA). 12F factors 5-6 (state in one place; launch/pause/resume) (12F).
11. Eval plan sized to the change: which 5-20 real cases, which binary assertions, who reads traces? Start ~20 queries (MA); Level 1 assertions on every change, read traces until nothing new (HH). Tool evals need verifiable outcomes and held-out sets (WT).
12. If an LLM judge/critic gates anything: calibrated against human labels, order-swapped, not same model as author? Position, verbosity, self-enhancement bias (LJ); measure precision and recall, not raw agreement (HH). Single-call 0.0-1.0 + pass/fail grader was most consistent (MA). Also: does any agent combine private data, untrusted input and an outbound channel? (LT)

## 2. Grounding: what counts as evidence for a finding
Quote the plan line and the file path; a finding without both is an opinion.
- Same rule stated twice with different wording (two homes for a threshold, cap or format): receivers pick either; MAST disobey-task-spec 11.8% (MAST html). Evidence: both quotes + paths.
- Loop/retry/review round/spawn with no numeric cap or no named exit: cite the step; MAST FM-1.3/1.5 (MAST html), BEA stop conditions.
- Success criterion with no command that checks it: quote the criterion, state "no script/test/gate named". Fix names the command and expected exit/output (BEA ground truth).
- Step that loads a large file or whole directory into every agent: give file, rough size (wc -c), agent count; CE just-in-time.
- Output format no parser or schema checks (free text consumed by a script, or JSON "expected" with no validator): name consumer and the missing check (WT strict data models; 12F factor 4).
- Delegation prompt missing objective/format/boundaries: list which of the four is absent (MA).
- Judge/critic run by the same model that wrote the artifact, with no calibration: LJ.
- Error path returns traceback/opaque code to the agent: WT actionable errors.
- Dry-run it: run the command or script named in the plan (--help, a fixture) and paste the output. Observed beats inferred.

## 3. MAST failure modes and the countermeasure the plan should name
(percentages = share of annotated failures; MAST html https://arxiv.org/html/2503.13657v3)
- Step repetition 15.7%, unaware of termination 12.4% -> explicit termination condition per agent plus numeric caps.
- Reasoning-action mismatch 13.2% -> output contract the next step checks (schema/script), not prose claims.
- Disobey task spec 11.8%, role spec 1.5% -> one home per rule, structured prompt, explicit role; role rewrite alone gave +9.4% in ChatDev.
- Incorrect/no verification 9.1% / 8.2%, premature termination 6.2% -> multi-level verification: low-level (script) and high-level objective check; +15.6% on ProgramDev from an objective-verification step. Self-verify/vote can be inconsistent, so prefer scripts.
- Task derailment 7.4%, fail to ask clarification 6.8% -> boundaries in handoff; allowed "blocked, need X" return path; checkpoints with human (BEA).
- Loss of conversation history 2.8%, conversation reset 2.2% -> state on disk, resumable (MA, 12F).
- Information withholding 0.85%, ignored other agent's input 1.9% -> receiver must cite the input it used; low frequency, low priority.
- Paper's broader lesson: prefer simple modular agents; context fixes alone often insufficient (MAST html).
- Multi-agent poor fit: shared context, many dependencies, few parallel parts (most coding), real-time coordination (MA).

## 4. Scale awareness: do not demand more than the change deserves
- One-line instruction tweak, wording fix, added bullet: ask only (a) one home for the rule, (b) a before/after example or a single manual dry-run. No eval harness, no panel, no caps analysis.
- Small command change with no new loop/spawn/tool: skip cost, resumability, injection analysis.
- Start-small is Anthropic's own advice: ~20 cases, small samples reveal large effects (MA); simplest solution first (BEA); Level 3 A/B only for mature products (HH).
- Escalate demands when the plan adds: a loop, a spawn, a gate that blocks work, a new tool, a parser, a judge, an untrusted-input path, or a shared prompt loaded by many agents.
- Demand tests that match the claim: a gate script needs a pass fixture and a fail fixture; a prompt change needs one case where old behaviour was wrong. Binary labels beat fine scores (HH).
- Measure each wording refinement with the eval once an eval exists (WT); do not build one to justify a tweak.
- Rule: every demand names the risk it removes; if the plan's blast radius is one file read by one agent, cap the review at 3 findings.

## 5. Decorrelation from other lenses
- Software architect lens: boundaries, coupling, data model, scalability, API shape. Harness-engineer does not review those; it reviews the text the model will read, determinism split, caps, verification commands, and token budget. Overlap point (tool/command contracts): architect asks "is the interface stable?", harness-engineer asks "can a model call it correctly from the description alone, and is the error message actionable?" (WT).
- Consumer lens (dry-runs the exact handoff text): receives only the sub-agent prompt or command text, no plan context, and tries to act. Harness-engineer reads the whole plan and asks why the handoff is shaped so; consumer asks "what do I do first, what is my output, when do I stop". Consumer finds missing objective/format/boundary (MA); harness-engineer finds the missing cap, check or deterministic step that makes the handoff unnecessary.
- Different evidence: architect cites structure and dependencies; consumer cites the exact words it could not act on; harness-engineer cites the unverified claim, uncapped loop, or oversized load with counts.
- Different failure classes: architect -> design drift; consumer -> ambiguity (MAST FC2); harness-engineer -> FC1 caps/termination and FC3 verification (MAST html).
- Ask the critic to run on a different model or with order-swapped inputs when it judges others' output, to limit self-enhancement and position bias (LJ).
- Security slice (only when untrusted input exists): lethal trifecta; prompt instructions and guardrail products are not a control; remove a leg or constrain the agent after it reads untrusted input (LT).

## Unverified
- OpenAI PDF could not be parsed (binary); its claims rest on secondary summaries (e.g. https://cheat.aktagon.com/sheets/agents/ , https://www.maginative.com/article/how-to-build-ai-agents-a-detailed-practical-guide-from-openai/).
- MAST html read only to char 100000 of 161911; table percentages come from that read, recommendations from it too.
- 12F per-factor one-liners are paraphrased from titles on the README, not from the factor pages.
- LJ verbosity/self-enhancement magnitudes not read; only that the biases are named in the abstract.
- Hamel post read at https://hamel.dev/blog/posts/evals/; no OWASP LLM01 or other prompt-injection source beyond LT was fetched.
