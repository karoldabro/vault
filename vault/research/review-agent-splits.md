---
type: research
project: vault
slug: review-agent-splits
status: living
date_researched: 2026-10-24
tags: [research, code-review, v-cr]
---

# Specialised-agent AI code review: what each agent should own beyond a linter

Fetched 2026-10-24. Every claim below carries its URL and date in the per-system sections. "Vendor, unverified" marks numbers a vendor published about its own product.

## Design takeaways (15 lines)

1. Most human review value is not defect-finding: 15% of Microsoft review comments flag a possible defect and at least 50% concern maintainability (Czerwonka 2015); review-induced changes run 75:25 maintainability to functional (Beller 2014); 68% of SWR-Bench verified issues are evolvability issues (2025).
2. LLM reviewers are weakest exactly there: on SWR-Bench they score F1 26% on logic bugs but at most 16% on evolvability/organisation, so the pattern and architecture agents need repository evidence, not more prompting.
3. Reviewer usefulness tracks familiarity with the code area (33% useful on first contact, about 67% by the third review; Czerwonka 2015). Give a pattern-conformance agent "how this repo already does X": similar code, past PRs, scoped rule files.
4. Anthropic's security-review prompt is a usable template for pattern conformance: research existing frameworks and patterns first, then diff the change against them, then report deviations.
5. Split by owned invariant, and give each agent a coverage guarantee. Amp runs one agent per `.agents/checks` file; Baz runs one sub-agent per ticket requirement; Qodo 2.0 runs bug, standards, architecture and risk agents with a judge; Anthropic's /code-review runs two rules agents and two bug agents.
6. Decomposition is supported only by vendor anecdotes that confound several changes at once (cubic: -51% false positives; Ellipsis: dozens of separately benchmarked generators). No controlled study isolates the benefit of role specialisation for code review.
7. Repeated sampling works: Bugbot ran 8 shuffled-order passes with majority voting; SWR-Bench raised F1 by up to 43.67% by having an LLM aggregate n=5-10 independent reviews. Returns diminish past n=5.
8. Same-model critics are correlated: when two LLMs both err, they agree 60% of the time (Kim, ICML 2025). Ten same-family reviewers unanimously endorsed a fake OpenSSL bug that only an executed test disproved (Refute-or-Promote 2026). Use a different model family, or an executable check, as the tiebreaker.
9. Every precise system has a separate verification stage that requires evidence: Anthropic's per-issue validators, Ellipsis's Evidence links checked by a hallucination filter, CodeRabbit's verification scripts, Google's calibrated precision target (50%) and per-category thresholds (AutoCommenter).
10. Cross-file consequences fail on retrieval, not on reasoning. Augment attributes missed bugs to missing callers/callees, type definitions, related tests and history. Ellipsis exposes LSP find-references; CodeRabbit adds co-change history to its code graph.
11. Missing or wrong tests: no vendor publishes a test-to-code mapping. Anthropic excludes test coverage by default, and Graphite reports that LLM "add tests" comments get rejected. The only at-scale evidence for "tests that pass for the wrong reason" is surviving mutants shown in review (Google: 2M mutants surfaced, 38% resolved).
12. Intent against the ticket is detectable but noisy (best F1 0.62, FORGE 2025). Use PR-Agent's shape: restate the requirements, then sort them into compliant, not compliant, and needs human verification. Treat ticket and PR text as untrusted input.
13. Exclusions are part of the design: drop linter-catchable, pre-existing, style and speculative findings; "do not speculate that a change might break other code unless you can identify the specific affected code path" (PR-Agent).
14. Measure the resolution rate (was the finding fixed before merge?), split by comment type. Bugbot: 52% to over 70%. PR-Agent at Beko: 73.8%. Mozilla/Ubisoft: 7-8% accepted overall, with refactoring comments accepted 3-4x more often than functional ones. Human comment action rate: about 50% (Graphite).
15. Route machine fixes to the author, not the reviewer: showing AI patches to reviewers slowed Meta reviews by more than 5%. Read rule files from the base branch, never from the PR (Anthropic REVIEW.md).

## Could not verify (read these first)

- Bacchelli & Bird 2013, per-category shares of the 570 coded comments: both PDF copies were unreachable (TLS error, 404). Only the abstract-level claims are used.
- Mäntylä & Lassenius 2009, the "60-75% evolvability" figure: it comes from secondary sources; the full text was not read.
- Pascarella et al. 2018, the seven information needs of reviewers: the PDF returned 404, so the list is not reproduced.
- Martian Code Review Bench: the page rendered empty. Methodology and leaderboard figures come from secondary and vendor coverage, and the snapshots contradict each other.
- Every vendor metric: Copilot (71% actionable, 5.1 comments/review), Anthropic Code Review (16% to 54% substantive, <1% incorrect), Bugbot resolution rate, Graphite (52% action rate, 96% positive), Augment and Qodo benchmark F1, the Greptile catch rate, cubic -51%, the Baz "-50% bugs" figure.
- Mutation-testing resolution figures (38% / 60%) and the multi-agent vs single-agent SE studies (arXiv 2511.00872, 2610.03010, 2505.18286): taken from abstracts or search snippets only.
- No primary source found for: claude-code-action review prompts (not fetched), Sourcegraph Cody review, Bito internals or metrics, the CodeRabbit verification-agent internals, the Graphite Agent architecture, or Copilot's handling of tests.
- The Cihan et al. 2025 paper contradicts itself on the model version and on closure times.
- The Greptile blog page carries a date of 2026-10-09 for an "AIE NYC, October 2026" talk. The date is taken as printed.

## Unresolved questions

- Does role specialisation beat N identical generalist passes plus aggregation, at equal token budget, for code review? No controlled comparison exists. SWR-Bench Self-Agg against a role-split ensemble would be the experiment to run.
- No public benchmark labels architecture, layering, contract or pattern-conformance issues as a separate class. Every benchmark scores bugs, and SWR-Bench's evolvability labels are the closest.
- No public evaluation covers missing-test detection or "test passes for the wrong reason" detection by an LLM reviewer.
- Which comment types developers accept is contested: Mozilla/Ubisoft favours refactoring comments, while Graphite says best-practice comments get rejected. The difference may come from the audience (reviewer-facing vs author-facing) and the amount of context.
- What is the cost and latency of per-check agents as the number of checks grows (Amp, Anthropic REVIEW.md)? No data was found.


## Per-system detail

### Anthropic Claude Code `/code-review` plugin
Source: https://github.com/anthropics/claude-code/blob/main/plugins/code-review/commands/code-review.md (fetched 2026-10-24; file undated, plugin shipped 2025)
1. Passes: haiku eligibility gate (closed/draft/trivial/already-commented) -> haiku agent returns CLAUDE.md paths (root + every dir containing a changed file) -> sonnet change summary -> 4 parallel reviewers: two sonnet agents for CLAUDE.md compliance (duplicated on purpose; only CLAUDE.md files on the changed file's path), opus "obvious bugs, diff only, no outside context", opus "security / incorrect logic in introduced code".
2. Context: diff, PR title + description (intent), scoped CLAUDE.md files. No code graph, no callers. Bug agent 3 is explicitly told NOT to read outside the diff.
3. Missing tests: explicitly EXCLUDED - false-positive list says "General quality concerns (e.g., test coverage, general security) unless CLAUDE.md explicitly requires them".
4. Precision: every issue goes to a parallel per-issue validator subagent (opus for bugs, sonnet for CLAUDE.md, which checks rule scope and real violation); unvalidated issues dropped. Binary filter, no numeric score in the current version. Excludes pre-existing issues, linter-catchable issues, nitpicks, lint-ignored lines. "If you are not certain an issue is real, do not flag it."
5. Effectiveness: none published in the file.
Design reading: Anthropic's own split is by evidence type (rule file vs diff-local bug), not by concern (architecture/tests); it deliberately cedes architecture, coverage, cross-file reasoning.

### Qodo Merge / PR-Agent (open source) `/review`
Source: https://raw.githubusercontent.com/qodo-ai/pr-agent/main/pr_agent/settings/pr_reviewer_prompts.toml (fetched 2026-10-24, main branch)
1. One generalist LLM call with a structured YAML schema (not multi-agent): ticket_compliance_check, estimated_effort_to_review_[1-5], risk_level, merge_recommendation, failure_modes (what/where/trigger/detected_by/covered_in_this_pr), review_priority_files, score 0-100, relevant_tests (Yes/No), key_issues_to_review, security_concerns, todo_sections, can_be_split.
2. Context: diff + linked tickets (Jira/GitHub/Linear) fetched by the tool; repo-level best-practices / "wiki" config in Qodo Merge (commercial).
3. Tests: "Does this PR have relevant tests added or updated? Answer exactly Yes or No." plus failure_modes.covered_in_this_pr - a cheap schema field, not a test-to-code mapping.
4. Precision: "Only include issues you are confident about"; "only on issues introduced by this PR"; "Do not flag intentional design choices or stylistic preferences unless they introduce a clear defect"; "Do not speculate that a change might break other code unless you can identify the specific affected code path". PR text/tickets/CI artifacts declared untrusted data (prompt-injection guard).
5. Intent vs ticket: TicketCompliance = restate requirements -> fully compliant / not compliant / needs human verification (UI/browser). This is the most concrete public "intent vs ticket" design.

### Cursor Bugbot
Source: https://cursor.com/blog/building-bugbot (Jon Kaplan, 2026-01-15); forum summary https://forum.cursor.com/t/building-a-better-bugbot/149040 (2026-01-16)
1. V1 pipeline: 8 parallel passes over randomized diff order -> majority voting (bugs seen in one pass dropped) -> bucket/merge similar bugs -> category filter (drop compiler warnings, doc errors) -> validator model -> dedup against earlier runs. Fall 2025: replaced by one agentic loop that reasons over diff and calls tools; prompts changed from restraining to "aggressive" investigation, with validation keeping precision.
2. Context: moved from static to dynamic (agent pulls at runtime); "Bugbot rules" encode team checks (unsafe migrations, forbidden internal API use). Tool design "had a large effect".
3. Tests: not covered.
4. Precision: voting + validator (V1), then validation in agent loop. 
5. Metric: "resolution rate" = LLM judge at merge time decides which flagged bugs were fixed in the final diff (spot-checked against authors). 52% -> >70% (forum also cites 76% elsewhere; unverified); bugs/run 0.4 -> 0.7; resolved bugs/PR ~0.2 -> ~0.5. Offline: BugBench (human-annotated real diffs), ~40 major experiments. Vendor-reported, unverified.
Design reading: the strongest public evidence that self-consistency voting across N identical passes (input-order perturbation) gave a precision gain, and that one agent with tools later beat the fixed multi-pass pipeline on recall.

### CodeRabbit
Sources: https://docs.coderabbit.ai/overview/architecture (undated, fetched 2026-10-24); https://coderabbit.ai/blog/context-engineering-ai-code-reviews (Sahil Mohan Bansal, 2025-07-17); https://docs.coderabbit.ai/integrations/code-graph-analysis
1. Named agents: Review, Verification, Chat, Pre-Merge Checks; "Finishing Touches" (docstrings, unit-test generation, fix comments).
2. Context: sandbox clone; code graph rebuilt per review (symbol defs/refs + files that change together = co-change); past PR titles/descriptions/commits; linked issues (Jira, Linear, GitHub, GitLab); "learnings" from chat feedback; path-based instructions; imports coding-agent guideline files; 40+ (blog) / 50+ (docs) linters/SAST whose output is fed to the LLM and filtered by the verification agent; web search. Claims "1:1 ratio of code-to-context" in prompts (unverified).
3. Tests: generation as a post-review action; no published test-to-code mapping.
4. Precision: post-generation verification of each suggestion against guidelines; generated verification scripts run in sandbox; linter output validated by verification agent.
5. Metrics: none published in these sources (unverified marketing elsewhere).
Design reading: linters are an INPUT to the LLM, verified, not a competing channel; co-change history is a cheap "cross-file consequence" signal.

### Greptile
Source: https://www.greptile.com/blog/how-to-build-a-code-review-agent (Daksh Gupta, dated 2026-10-09 per page, adapted from AIE NYC talk)
1. Sandbox agent per PR; model routing per subtask; dynamic testing (install deps, run dev server, drive endpoints/UI via computer use) using a knowledge-base mapping of code sections -> user flows.
2. Context: periodic crawler agents maintain a codebase wiki injected into review; MCP gateway to Jira/Linear for intent; reverts and incidents recorded in wiki via telemetry (incident memory). Greptile marketing also describes a repo graph of functions/files/dirs (https://greptile.com/code-context).
3. Tests: dynamic execution of flows rather than test-file mapping.
4. Precision: prompts target named bug classes and skip nits; reviewer from a DIFFERENT model family than the author model raises catch rate "about 10%" (vendor research, unverified); historical-PR datasets for tuning.
5. Metrics: ">1% of GitHub PRs daily", cost $2-$20/run (vendor, unverified); claims Claude models ~2x likelier to introduce and to miss N+1 errors (unverified).
Design reading: correlated-critic risk addressed by model-family diversity, not by role split.

### GitHub Copilot code review
Sources: https://github.blog/news-insights/company-news/60-million-copilot-code-reviews-and-counting/ (Ria Gopu, David Apirian, 2026-03-05); https://github.blog/changelog/2026-03-05-copilot-code-review-now-runs-on-an-agentic-architecture/ (2026-03-05); https://github.blog/changelog/2025-10-28-new-public-preview-features-in-copilot-code-review-ai-reviews-that-see-the-full-picture/ (2025-10-28); https://docs.github.com/en/copilot/concepts/agents/code-review
1. Single agentic reviewer (runs on GitHub Actions) that writes an explicit review plan for long PRs, flags issues as it reads (earlier design lost early findings by finalising only at the end), clusters repeated pattern errors into one comment. Deterministic tools CodeQL, ESLint, PMD blended in (public preview).
2. Context: agentic tool calls for relevant code, directory structure, references; memory across reviews; reads linked issues and PRs "to catch code that looks correct in isolation but misses project requirements" (intent check); repo custom instructions (.github/copilot-instructions.md).
3. Tests: no published mechanism.
4. Precision: "Silence is better than noise"; stays silent in 29% of reviews; internal eval on known issues; thumbs up/down; resolved-before-merge tracking.
5. Metrics (vendor, unverified): >1 in 5 GitHub code reviews; 71% of reviews have actionable feedback; ~5.1 comments/review; agentic redesign +8.1% positive feedback; stronger reasoning model +6% positive feedback at +16% latency. Comment kinds highlighted: logic + maintainability (missing useCallback dependency), edge-case reliability (unbounded 429 retry), config gaps.

### Graphite Diamond / Graphite Agent
Sources: talk "AI-powered entomology: lessons from millions of AI code reviews", Tomas Reimers, AI Engineer World's Fair 2025 (https://ai.engineer/talks/TswQeKftnaw-ai-powered-entomology-lessons-from-millions-ai, mid-2025); https://www.braintrust.dev/blog/graphite (undated, (c)2026); https://graphite.com/docs/ai-review-comments.md
1. Architecture not published in detail; docs show per-category comment stats (logic bugs, security, edge cases) with acceptance rate per category; custom rules.
2. Context: repo history, style guides, custom rules ("more repository context widens the set of comments developers will accept").
3. Tests: the talk reports "add tests" / "extract function" / "add comments" best-practice comments are ones an LLM CAN produce but developers often REJECT as unwelcome when they come from an LLM.
4. Precision: eval datasets from accepted/rejected comments on internal PRs; scorers = line-range validation, semantic similarity to prior versions, binary thumbs.
5. Measured: ~10,000 comments categorised by LLMs; ~50% of HUMAN review comments lead to a change in the same PR; Diamond 52% within-PR action rate (March 2025); downvote <4% (denominator unspecified). Category reception table from the talk: wanted = logic bugs, accidentally committed code, perf, security, doc mismatch; context-dependent = style; LLM-capable but rejected = best-practice/cleanliness (add tests, extract function); wanted but LLM cannot = tribal knowledge ("we did it this way because..."); rejected = advice to make code do what it already does, revert-to-old-behaviour. Marketing: "96% positive feedback", "67% implementation rate" (https://graphite.com/guides/best-ai-pull-request-reviewers-2025, unverified), "5-8% false positive" (unverified, no method).

## Evidence: what human review comments are about (share of non-static value)

- Mäntylä & Lassenius, "What Types of Defects Are Really Discovered in Code Reviews?", IEEE TSE 35(3):430-448, 2009, doi:10.1109/TSE.2008.71. Taxonomy: evolvability defects (documentation, visual representation, structure = organisation + solution approach) vs functional defects (resource, check, interface, logic, timing, support, larger defects). Secondary sources report 60-75% evolvability (https://metrics.blogg.gu.se/?p=772); exact figure not verified against full text.
- Beller, Bacchelli, Zaidman, Juergens, "Modern Code Reviews in Open-Source Projects: Which Problems Do They Fix?", MSR 2014, doi:10.1145/2597073.2597082 (https://flosshub.org/node/1650): >1,400 review-induced changes in ConQAT and GROMACS; 75:25 maintainability:functional; 7-35% of review comments discarded; 10-22% of changes not triggered by an explicit comment.
- Czerwonka, Greiler, Tilford (Microsoft), "Code Reviews Do Not Find Bugs", ICSE SEIP 2015 (https://microsoft.com/en-us/research/wp-content/uploads/2015/05/PID3556473.pdf, read in full): "Only about 15% of comments provided by reviewers indicate a possible defect"; "at least 50%" concern long-term maintainability. Reviewer usefulness depends on prior exposure: 33% useful on first contact with that code area, ~67% by third time. Usefulness drops for reviews with >=20 changed files. -> repository familiarity, not model skill, drives usefulness; an agent needs the equivalent of "has seen this area before" (similar code, past PRs, rules).
- Fregnan, Petrulio, Bacchelli 2022 (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9489594/): majority of review-induced changes are evolvability, dominated by documentation and structure.
- Bacchelli & Bird, "Expectations, Outcomes, and Challenges of Modern Code Review", ICSE 2013, doi:10.1109/ICSE.2013.6606617 (https://microsoft.com/en-us/research/?p=164195): finding defects is the top stated motivation but outcomes are "less about defects than expected"; "code improvements" (readability, commenting, consistency, dead code) is the most frequent comment topic; "code and change understanding is the key aspect of code reviewing" and is poorly tool-supported. Per-category percentages from the 570-comment sample NOT verified (PDF copies unreachable from this sandbox: TLS error / 404).

## Evidence: LLM review in practice (deployment studies)

- Olewicki et al., "Impact of LLM-based Review Comment Generation in Practice: A Mixed Open-/Closed-source User Study" (Mozilla + Ubisoft, RevMate with RAG + LLM-as-judge filter), arXiv:2411.07091, 2024-11-11 (https://arxiv.org/abs/2411.07091): accepted 8.1% (Mozilla) / 7.2% (Ubisoft); a further 14.6% / 20.5% rated valuable tips. REFACTORING comments accepted 18.2% / 18.6% vs FUNCTIONAL 4.8% / 5.2%. Median 43 s extra per patch. -> LLM comments land better on evolvability than on defects in this setup - the opposite of Graphite's anecdote; context (RAG) and reviewer-facing vs author-facing differ.
- Cihan et al. (Bilkent/Beko), "Automated Code Review In Practice", ICSE SEIP 2025, arXiv:2412.18531 (https://arxiv.org/html/2412.18531v2): Qodo PR-Agent on GPT-4 (version inconsistent in paper), 3 projects, 4,335 PRs, 1,568 bot-reviewed; 73.8% of 1,408 bot comments "Resolved" (55% project 1, 90% project 3); 21.3% won't-fix; PR closure time 5h52m -> 8h20m (p<0.001); 3.65 bot comments/PR. Survey: value = coding-standard adherence, code smells, potential bugs, forgotten test code, typos; drawbacks = irrelevant/out-of-scope comments, over-reliance. No per-type breakdown. Paper has internal inconsistencies (noted by fetch).
- Frömmgen & Kharatyan (Google), "Resolving code review comments with ML", 2023-05-23 (https://research.google/blog/resolving-code-review-comments-with-ml/); paper ICSE SEIP 2024 (https://research.google/pubs/resolving-code-review-comments-with-machine-learning/): DIDACT-style model fine-tuned on reviewer comment -> author edit; calibrated to target precision 50%; offline addresses 52% of comments at that precision; 40-50% of previewed edits applied; paper abstract: 7.5% of all reviewer comments addressed by ML edit in deployment. Lesson: an explicit precision target with a confidence threshold, plus heuristics removing recurring failure patterns.
- Vijayvergiya et al. (Google), "AI-Assisted Assessment of Coding Practices in Modern Code Review" (AutoCommenter), AIware 2024, arXiv:2405.13565 (https://arxiv.org/html/2405.13565): each comment = location + best-practice URL (correct only if both match); per-URL confidence thresholds replaced a global 0.98; comments only on changed lines; regex suppression of outdated practices; useful ratio 54% -> 66% (dev) / 60% -> 74% (raters) by suppressing 17 non-actionable URLs, then >80%. 66% of top-50 sampled best practices are beyond linter scope. Explicit feedback is rare (~10% of comments). Estimated resolution ~40%.
- Maddila et al. (Meta), "AI-Assisted Fixes to Code Review Comments at Scale" (MetaMateCR), arXiv:2507.13499, FSE 2026 industry (https://arxiv.org/abs/2507.13499): 64k comment->patch pairs, fine-tuned Llama; 19.7% ActionableToApplied in production (+9.2pp over GPT-4o); showing AI patches to REVIEWERS slowed reviews >5%; showing only to authors removed the regression. -> route machine output to the author, not the reviewer.

## Evidence: decomposition (narrow agents) vs generalist, and correlated critics

- cubic, "Learnings from building AI agents", Paul Sanglé-Ferrière, byline 2025-06-19 (https://www.cubic.dev/blog/learnings-from-building-ai-agents): one big prompt with accumulating rules -> rules "often ignored"; moved to Planner (decides which checks are needed) + Security + Duplication + Editorial micro-agents, mandatory JSON {reasoning, finding, confidence}, toolset cut to simplified LSP + terminal. Result: -51% false positives "without sacrificing recall", median comments/PR halved, 6 weeks, hundreds of PRs (vendor, unverified; combined effect of three changes, specialisation not isolated).
- Ellipsis, "How we built Ellipsis", Nick Bradford, 2025-01-30 (https://nickbradford.substack.com/p/lessons-from-27-months-building-llm): "dozens of smaller agents that can be independently benchmarked and optimized"; parallel Comment Generators (examples: custom-rule checker, duplicated-code finder) each attach Evidence (link to supporting snippet); sequential filters ConfidenceFilter (per-customer threshold) -> DedupeFilter -> logical-correctness/hallucination filter that checks the Evidence; filtered comments kept in output with reasons. Shared Code Search subagent (tree-sitter chunks, per-file LLM summaries embedded, keyword+vector, LLM binary relevance classifier instead of cosine cutoff); LSP sidecar for go-to-definition/find-references. Feedback: embedding search over past thumbs-reacted comments feeds the filter (chosen over fine-tuning). Evals: ~30-example benchmark per prompt. No numbers published.
- Cursor Bugbot (above): 8 identical passes with shuffled diff order + majority vote = self-consistency, not specialisation; later one agent with tools beat it.
- Agarwal, "Refute-or-Promote", arXiv:2604.19049, 2026-04-21 (https://arxiv.org/abs/2604.19049): adversarial refuters at each gate, cross-model critic, mandatory empirical test gate; 79-83% of candidates killed. Key failure: TEN dedicated same-family reviewers unanimously endorsed a non-existent OpenSSL padding oracle; only an executed test killed it. -> correlated critics: more agents of one model family do not add independent evidence; an executable check does.
- Greptile (above): different-model-family reviewer +~10% catch rate (vendor, unverified).
- Adjacent, not code-review-specific: arXiv:2511.00872 (agent frameworks on SE tasks, 2025-11) - single-agent better on executability/consistency, multi-agent on completeness, ~2x steps; arXiv:2610.03010 (2026-10) - multi-agent raises vulnerability-detection accuracy but single/non-agentic configs dominate the cost Pareto front, multi-agent ~6x time/energy; arXiv:2505.18286 - MAS benefit over SAS shrinks as model capability grows. Not verified beyond abstracts.

## Per-system detail (continued)

### Anthropic Claude Code Review (managed service) and security-review action
Sources: https://claude.com/blog/code-review (2026-03-09); https://code.claude.com/docs/en/code-review and https://code.claude.com/docs/en/code-review-customize (fetched 2026-10-24); https://github.com/anthropics/claude-code-security-review + https://raw.githubusercontent.com/anthropics/claude-code-security-review/main/claudecode/prompts.py (fetched 2026-10-24).
1. Managed Code Review: Find (several agents in parallel over diff + surrounding code) -> Verify (checks candidates against code, drops false positives) -> Rank (dedupe, severity) -> Post. Depth and agent count scale with PR size; Quick/Standard/Deep levels. Reads code only; never builds or runs it; never approves/blocks.
2. Context: CLAUDE.md (root + parent dirs of each changed file) as project rules; REVIEW.md (root + subdir, read from protected base/default branch, never from the PR's own changes - injection guard) given to both finder and verifier agents. Documented REVIEW.md patterns: redefine severity, cap nits, "Do not report anything CI already enforces", "Always check: New API routes have an integration test", require evidence "behavior claims need a file:line citation in the source, not an inference from naming".
3. Tests: default "focuses on correctness ... not formatting preferences or missing test coverage"; test expectations must be added as REVIEW.md rules.
4. Precision: dedicated verification stage; vendor reports "<1%" of findings marked incorrect (unverified).
5. Metrics (vendor, internal, unverified): PRs with substantive review comments 16% -> 54%; >1,000-line PRs: 84% get findings, avg 7.5; <50-line PRs: 31%, avg 0.5; ~20 min, $15-25/review.
security-review action: prompt phases = (1) repository context research ("Identify existing security frameworks and libraries in use", "Look for established secure coding patterns in the codebase") -> (2) comparative analysis ("Compare new code changes against existing security patterns", "Identify deviations from established secure practices") -> (3) vulnerability assessment with data-flow tracing; ">80% confident" exploitability rule (bands say <0.7 not reported - inconsistent); hard exclusions (DoS, rate limiting, resource exhaustion, generic input validation, open redirect); separate LLM false-positive filter pass with user-tunable instructions; README warns it is "not hardened against prompt injection".
Design reading: the security prompt is the one Anthropic artifact that does explicit PATTERN CONFORMANCE (find how the repo already does it, then diff against that) - a template for a pattern-conformance agent.

### Amp (Sourcegraph spin-out) review agent + Checks
Source: https://ampcode.com/news/liberating-code-review (2026-02-04); Tessl coverage https://tessl.io/blog/amp-adds-agentic-code-review-to-its-coding-agent-toolkit (2025-12-31)
1. Review agent is a UI-free subroutine (`amp review`, or in-thread); output pipes to a fixer.
2. Checks: markdown files in `.agents/checks/` (frontmatter name/description + criteria), scoped to the directory containing `.agents/`. "The code_review tool will kick off a separate agent for each check", which "provides a stronger guarantee that each check will actually be checked" than putting criteria in AGENTS.md.
3-5. Tests, precision, metrics: not described.
Design reading: direct vendor statement of the "one invariant per agent" rationale = coverage guarantee, not accuracy. Sourcegraph Cody's own review product: no primary source found.

### Augment Code Review
Sources: https://www.augmentcode.com/blog/how-we-built-high-quality-ai-code-review-agent (Akshay Utture, 2026-03-10, updated 2026-06-18); https://www.augmentcode.com/blog/we-benchmarked-7-ai-code-review-tools-on-real-world-prs-here-are-the-results (2025-12-11, updated 2026-06-18)
1. One agent; harness = tools + system prompt + model-prompt pairing + guardrails. Tools with "little overlap": semantic retrieval, file browse, symbol search. Large inputs (diff, existing comments) injected deterministically rather than tool-fetched.
2. Context Engine (semantic search) answers "which other services depend on the changed code"; cross-repo via MCP; Linear/Jira/Notion via MCP; repo-level + directory-scoped guidelines as tribal knowledge.
3. Tests: benchmark post names "related tests and fixtures" among context tools fail to retrieve.
4. Precision: prompt names categories to skip; guardrails; per-model prompt tuning.
5. Metrics (vendor, unverified): production bugs fixed/PR 1.03 vs human 0.54; comments addressed 45% vs human 50%. Benchmark (vendor-run, 50 PRs from Sentry, Grafana, Cal.com, Discourse, Keycloak - derived from an earlier public set, golden set re-labelled by Augment and validated against tool outputs): P/R/F Augment 65/55/59, Bugbot 60/41/49, Greptile 45/45/45, Codex 68/29/41, CodeRabbit 36/43/39, Claude Code 23/51/31, Copilot 20/34/25. Stated miss cause: failure to retrieve "dependent modules, caller/callee chains, type definitions, related tests and fixtures, and historical changes". Later revision (Code Review Bench): Augment F1 53.8, R 62.8, P 47.0 among 12 tools.

### Bito
Sources: https://docs.bito.ai/ai-code-review-agent/overview ; https://bito.ai/blog/major-upgrades-to-the-ai-code-review-agent-and-ide-extensions/ (dates not captured)
Context pipeline: symbol index -> AST structure -> embeddings for files/functions/comments; "AI Architect" knowledge graph served over MCP for cross-repo impact analysis and dependency awareness (vendor claims, unverified). No published agent split, test mapping, or acceptance numbers found.

### Qodo 2.0 (commercial; PR-Agent is the open-source base above)
Sources: https://www.qodo.ai/blog/introducing-qodo-2-0/ (2026-02-04); https://docs.qodo.ai/qodo-core-features ; https://itbrief.co.uk/story/qodo-2-0-debuts-multi-agent-ai-code-review-upgrade (2026-02-05)
1. Four parallel review agents: logic correctness/bugs; standards compliance/maintainability; "architectural and system-level reasoning"; risk assessment. Plus a Finding Recommendation agent that "references past PRs, previous review feedback, and recurring patterns" (ranks by whether similar past suggestions were acted on), and a Judge agent that dedupes, resolves conflicts, and drops findings below "a high confidence and relevance threshold". Stated rationale: "Finding bugs, enforcing standards, assessing risk, and understanding context are separate forms of reasoning."
2. Context: full codebase, cross-file dependencies, PR history "as a first-class signal"; 2.1 Rules System infers implicit standards "from codebase patterns and PR history" (beta).
3. Tests: no test agent documented.
5. Vendor benchmark: real OSS PRs with INJECTED verified issues (functional bugs + rule violations); F1 60.1%, recall 56.7%, no precision published (unverified).
Design reading: the closest public analogue to the requested split (architecture agent, standards/pattern agent, judge), but no published per-agent evaluation.

### Baz
Source: https://aws.amazon.com/blogs/machine-learning/how-baz-improved-its-ai-agent-code-review-accuracy-using-amazon-bedrock-agentcore/ (Atas, Eisenkot, Kor, 2026-06-02); https://docs.baz.co/agents
1. Spec Review agent: pulls Jira (REST) + Figma (MCP) concurrently; a Specification Subagent splits them into visual and functional requirements (acceptance criteria, user-story intent); spawns ONE isolated sub-agent per requirement, each checks source and validates runtime behaviour in a live preview via headless browser (DOM inspection, event simulation); Report Generator consolidates.
2. Other reviewers: indexable units + embedding retrieval + static analysis + optional runtime inspection (docs).
5. Claims "reported bugs down up to 50%, time-to-merge down 30-70%" (vendor, unverified).
Design reading: the most concrete "intent vs ticket" decomposition: one agent per acceptance criterion, with execution as evidence.

## Evidence: missing / wrong tests

No surveyed vendor publishes a test-to-code mapping mechanism. What exists:
- Qodo PR-Agent: relevant_tests Yes/No field + failure_modes.covered_in_this_pr (prompt above).
- Anthropic managed Code Review: excludes "missing test coverage" by default; teams add rules such as "New API routes have an integration test" in REVIEW.md. Local /code-review excludes test coverage unless CLAUDE.md requires it.
- CodeRabbit: unit-test generation as a post-review action; pre-merge "Issue Assessment" and docstring-coverage checks, no test-coverage check (https://docs.coderabbit.ai/pr-reviews/pre-merge-checks).
- Greptile, Baz: execute flows in a sandbox instead of judging tests (dynamic evidence).
- Augment benchmark post: "related tests and fixtures" listed among context tools fail to retrieve.
- Graphite talk: LLM "add tests" comments are commonly rejected by developers.
- Strongest evidence for "tests that pass for the wrong reason" is mutation testing surfaced IN code review at Google: Petrović et al., "Practical Mutation Testing at Scale", arXiv:2102.11378 (2021): ~17M mutants, 760k changes, 2M mutants surfaced in review, feedback raised productive mutants 15% -> 89%; "Does mutation testing improve testing practices?", ICSE 2021, arXiv:2103.07189: developers exposed to surviving mutants write more and better tests; mutants coupled with real faults; ICSE 2023 follow-up (https://homes.cs.washington.edu/~rjust/publ/mutation_testing_resolution_icse_2023.pdf): 38% of surfaced mutants resolved, 60% of reviewer-endorsed mutants resolved (figures from abstracts/search snippets, not full text).
- Meta ACH, "Mutation-Guided LLM-based Test Generation at Meta", arXiv:2501.12862, FSE Companion 2025: LLM generates mutants of a fault class then tests that kill them; 73% of tests accepted by engineers; equivalent-mutant detector agent P 0.79 / R 0.47 raw, 0.95 / 0.96 with preprocessing.
- ReAccept, ISSTA 2025, arXiv:2411.11033: LLM + dynamic validation to identify/update obsolete tests after production change; 60.16% update accuracy (537 Java projects). SITAR (pre-LLM): ML predicts when a production change needs a test change (975 Java projects).
-> A "tests" agent can be grounded on (a) changed symbols with no test file touching them (static mapping by import/call graph or naming), (b) a mutation of the changed line that the existing tests do not kill (executable evidence that a test passes for the wrong reason). Only (b) is evidenced at scale.

## Evidence: intent vs ticket

- Işık, Çağlar, Tüzün, "Enhancing Pull Request Reviews: Leveraging LLMs to Detect Inconsistencies Between Issues and Pull Requests", FORGE 2025 (2025-04-28) (https://conf.researchr.org/details/forge-2025/forge-2025-papers/4/...): Transformers repo sample: 68.04% exact, 16.5% missing, 13.40% tangling, 2.06% both; merged PRs 75.46% exact. Best weighted F1 0.619 (Llama-3.1-405B), GPT-4o 0.595 using issue + PR text + diff. -> ticket-alignment is detectable but noisy; frame output as "needs human verification" (as PR-Agent does).
- Product implementations: PR-Agent TicketCompliance (restate -> compliant / not / needs human check); CodeRabbit Issue Assessment pre-merge check (addresses linked issues without out-of-scope changes); Copilot reads linked issues; Baz one-sub-agent-per-requirement with runtime validation; Greptile MCP to Jira/Linear.

## Benchmarks

- SWR-Bench, arXiv:2509.01494, FSE 2026 (https://arxiv.org/html/2509.01494): 1,000 manually verified PRs, 12 Python projects, full repo checkpoint. Ground truth after verification: 31.8% functional / ~68.2% evolutionary. LLM reviewers detect functional issues better (F.2 Logic F1 26.2%) than evolutionary (best, E.3.1 Organization, 16.45%). Multi-Review = run reviewer n times, LLM synthesises the n reports: F1 +43.67% (Gemini-2.5-Flash, n=10), recall +118.83%; diminishing returns past n=5; Multi-Agg variant across different LLMs. Absolute F1 stays ~20-24%.
- Greptile benchmark (https://greptile.com/benchmarks, ~July 2025, vendor): 50 bug-fix PRs traced to bug-introducing commits in Sentry, Cal.com, Grafana, Keycloak, Discourse; catch rate only, no false-positive count; Greptile 82%, Cursor 58%, Copilot 54%, CodeRabbit 44%, Graphite 6%. This set was later re-labelled by Augment and used in Martian's offline bench.
- Martian Code Review Bench (https://codereview.withmartian.com/, launched ~2026-02; page not readable by fetch): offline 50 PRs / 173 golden comments; online = acted-on suggestions in public PRs as precision proxy, no true recall denominator; Martian says cross-tool comparison is unreliable because tools see different repos. Leaderboard snapshots disagree by date (Greptile, Cubic, CodeRabbit, Qodo each cited as #1) - secondary sources only.
- CodeFuse-CR-Bench, arXiv:2509.14856: 601 instances, 70 Python projects, includes linked issue + repo state.
- AACR-Bench, arXiv:2601.19494 (2026-01): multi-language, cross-file; argues raw PR comments are noisy ground truth; AI-assisted expert-verified annotation found 285% more defects than original PR comments.
- CodeReviewer (Li et al., ESEC/FSE 2022, arXiv:2203.09095): the pre-LLM dataset/model (diff-hunk level, no repo context). Liu, Lin, Thongtanunam, "Too Noisy To Learn", MSR 2025, arXiv:2502.02757: open-source review-comment datasets carry many vague/non-actionable comments; LLM cleaning detects valid comments at 66-85% precision.
- Kim, Garg, Peng, Garg, "Correlated Errors in Large Language Models", ICML 2025 (https://proceedings.mlr.press/v267/kim25e.html): models agree on 60% of cases where both err (one leaderboard); same provider / architecture raises error correlation; larger more accurate models correlate even across providers; LLM judges inflate same-provider models. -> N critics on one model are not N independent votes.
