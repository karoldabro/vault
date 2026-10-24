---
type: research
project: vault
slug: review-code-context
status: living
date_researched: 2026-10-24
tags: [research, code-review, v-cr]
---

# Code context for review agents: research findings (2026-10-24)

## Summary: design takeaways for "give each review agent a precomputed relation map of the change"

1. Precompute the map and put it in the reviewer's prompt. A graph that the agent can call but is not told to use goes unused: in 58% of CodeCompass trials the agent never called it (arXiv 2602.20048, 2026-02, preprint).
2. Plain agentic grep with a strong model is a high baseline. OpenHands and SWE-agent reach 76–77% file Acc@1 against 53% for the best embedding retriever (LocAgent, ACL 2025). Claude Code and Cline both dropped vector indexes (vendor claims, 2025-05).
3. Graphs add a small, real gain. RepoGraph adds 2.0–2.7 points of SWE-bench Lite resolve rate and 5–7 points of file-level localization, at a cost of $0.04–0.16 per task (ICLR 2025). LocAgent adds 4–7 points at function level. The value sits at 1 hop: callers and callees of the changed definitions.
4. Do not hand reviewers top-k retrieved snippets. In AACR-Bench (2026-01), BM25 and embedding context often lowered review F1 for strong models. Free agent exploration raised precision but cut recall about 4x (Claude 42.9% to 10.1%).
5. Output format matters as much as content. Summarised search capped at 50 hits scored 18.0%, paged search 12.0%, and no search 15.7%. Full-file views scored 12.7% against 18.0% for 100-line windows (SWE-agent, NeurIPS 2024). Emit path:line plus a one-line excerpt or signature, never file bodies.
6. The map should contain six relations per changed file or symbol: inbound references (who uses it), outbound dependencies, 1-hop callers of each changed symbol, mapped tests, co-change companions missing from the diff, and existing implementations of the same pattern. Greptile and CodeRabbit ship the same set (vendor).
7. Map tests by naming convention plus `rg` of the path and symbol in `tests/`. Conventions are "highly accurate" (Van Rompaey & Demeyer, CSMR 2009). ML test selection (Facebook 2019, Launchable) needs CI history that a small repo lacks.
8. Co-change mining runs on bash alone and catches omissions that static analysis cannot see. It is precise but misses most: at confidence 0.9 and support 3, ROSE was about 50% precise with about 4% recall, and 98% of complete commits drew no false warning (ICSE 2004). Report it as a "possible missing companion" hint, never as a blocking finding.
9. Drop commits that touch more than about 30 files before mining co-change; code-maat uses this default. Without the filter, renames and sweeps fill the coupling list with noise.
10. Every relation above computes in 0.1 s or less on this repo with `git` and `grep`/`rg`; both queries were measured on 2026-10-24. Use Serena's `find_referencing_symbols` for type-aware callers when it is available, and fall back to `rg -w` otherwise.
11. In a harness repo (markdown plus shell), the reference graph is the call graph. Edges are markdown links, backtick paths, "Read X" lines, `source` and `bin/*` invocations, subagent and persona names, hook-to-script links, and test-to-script links.
12. Anthropic documents that Claude may read nested references only partially (`head -100`). A reviewer should flag reference depth above 1 from an entry file, and reference files over 100 lines that have no table of contents (platform.claude.com best-practices).
13. Link checkers (lychee `--offline --include-fragments`) catch renamed files and headings. They miss renamed terms, renumbered steps and changed contracts. Vale substitution rules can enforce a rename across every file.
14. No tool reliably catches semantic contradictions between instruction files; the 2025–26 linters are regex-based and unmeasured. For each changed rule, pass the changed passage and each referrer's passage that cites it to an LLM judge, as a pairwise check.
15. Expect asymmetry and design for it. Without context, recall drops as the scope a finding needs widens, from diff to file to repo (AACR-Bench). Point one reviewer seat at repo-level relations explicitly, so cross-file findings are not left to chance.

## Unverified or open (read first)

- Vendor numbers I could not replicate: Augment "70%+" (2026-02; metric undefined), Cursor semantic search +12.5% (internal benchmark), Greptile and CodeRabbit graph benefit (no numbers published), and the Claude Code "agentic search beats RAG" claim (Cherny himself called it "vibes").
- The CodeRabbit code-graph docs page returned 404 on fetch. The claim that it mines co-change from commit history comes from a search snippet only.
- From memory, not re-read this session: that Aider's ranking is networkx personalised PageRank, Cline's `list_code_definition_names`, TAP's build-graph test selection, remark-validate-links' anchor checking, Semgrep Bash support, and the stack-graphs repo archival.
- Open: no study measures whether a precomputed relation map improves LLM review precision and recall compared with diff-only review or free exploration. AACR-Bench tested retrieval and agents, not a structured map. This needs a local eval: the same diffs with and without the map, scored on seeded cross-file defects.
- Open: the co-change confidence threshold for a small repo with about 12 commits per file is unknown. ROSE's 0.9 / support 3 setting came from large OSS histories.
- Open: how to detect a semantic contradiction between instruction files cheaply. The LLM-judge pairwise check is untested here.
- Open: `graphify-out/graph.json` already exists (untracked) in /home/kdabrow/workspace/vault. It has not been evaluated as a source for the map.


<!-- SUMMARY and UNRESOLVED sections are written last, above this line -->

## Detail: sources (appended per source)

### Aider repo map
- Computes: per-file definitions and references from tree-sitter tags; a file graph (node = file, edge = dependency through a shared identifier); a graph ranking picks the most-referenced symbols that fit a token budget (`--map-tokens`, default 1k). Source: https://aider.chat/docs/repomap.html (undated docs page, read 2026-10-24); https://aider.chat/2023/10/22/repomap.html (2023-10-22). The 2023 post says "graph ranking algorithm"; the PageRank (personalised, from networkx) attribution comes from aider's source `aider/repomap.py`, not from these two pages — not re-verified here.
- Tooling: tree-sitter `tags.scm` queries per language (same idea as universal-ctags). bash-only: approximable with `ctags -R --fields=+n` plus `rg -w <symbol>` counts; ranking needs a small script.
- Evidence: none quantitative in the post; qualitative only.

### Claude Code: agentic search over vector RAG
- Boris Cherny (Anthropic, Claude Code lead): early versions used RAG with a local vector DB; the team moved to agentic search (grep/glob/read) because it "outperformed everything else by a lot", reasons: simplicity, no stale index, no security/privacy copy. He states the evidence was "just 'vibes' – internal vibes" plus some internal benchmarks. Video: https://www.youtube.com/watch?v=zDmW5hJPsvQ&t=2083s ; write-up https://officechai.com/ai/claude-researcher-explains-how-agentic-search-performed-better-than-rag-for-code-generation/ (2025-05-27). VENDOR CLAIM, UNVERIFIED (no published benchmark).

### Cline: no indexing
- Nick Baumann, "Why Cline Doesn't Index Your Codebase", https://cline.bot/blog/why-cline-doesnt-index-your-codebase-and-why-thats-a-good-thing (2025-05-27). Arguments: chunking splits a call from its definition; an index is "a snapshot frozen in time"; embeddings are a second copy of sensitive code. Cline instead reads files, follows imports, checks callers ("Discovery, Not Retrieval"). VENDOR CLAIM, no benchmark. Cline's tool set (ripgrep search, tree-sitter `list_code_definition_names`) is from its repo/docs, not from this post — not re-verified here.

### RepoGraph (ICLR 2025)
- Ouyang et al., arXiv 2410.14684 (v1 2024-10-03, v2 2025-03-18), https://arxiv.org/html/2410.14684v2 ; ICLR 2025 https://proceedings.iclr.cc/paper_files/paper/2025/hash/4a4a3c197deac042461c677219efd36c-Abstract-Conference.html
- Computes: line-level graph; node = code line tagged def/ref (tree-sitter over Python), edges `invoke` (def->ref) and `contain`; built-ins and third-party calls filtered out. Retrieval = k-hop ego-graph (k=1,2) around a key symbol, flattened or LLM-summarised into the prompt.
- Evidence (SWE-bench Lite resolve %, baseline -> +RepoGraph): RAG/GPT-4 2.67->5.33; Agentless/GPT-4o 27.33->29.67; AutoCodeRover/GPT-4 19.00->21.33; SWE-agent/GPT-4o 18.33->20.33 (+2.0 to +2.7 absolute; the "32.8% relative" headline is dominated by the RAG baseline doubling). File-level localization gains largest: Agentless 68.7->74.3, ACR 62.3->69.0, SWE-agent 61.7->67.3; line-level +2–3 pts. Cost: +$0.04 to +$0.16 per instance (Agentless 42k->47k tokens).
- bash-only: no (needs tree-sitter parse); a ctags+rg approximation of 1-hop "who references the changed def" is feasible.

### LocAgent (ACL 2025)
- Chen et al., arXiv 2503.09089, https://arxiv.org/html/2503.09089v1 (2025-03). Graph: directory/file/class/function nodes; edges contain, import, invoke, inherit (Python). Tools: SearchEntity (keyword over entity index), TraverseGraph (typed BFS, direction/hops/edge-type configurable), RetrieveEntity. Indexing "a few seconds per codebase".
- Evidence (SWE-bench Lite, Claude-3.5, File Acc@1/@3/@5; Function Acc@10): Agentless 72.6/79.2/79.6, 58.8; MoatlessTools 72.6/85.8/86.1, 65.0; SWE-agent 77.4/87.2/90.2, 64.6; OpenHands 76.3/89.8/90.2, 70.1; LocAgent 77.7/92.0/94.2, 77.4. Best embedding retriever (CodeRankEmbed) file Acc@1 52.6, function Acc@10 58.8. Reading: plain agentic search (OpenHands/SWE-agent) already beats embeddings by ~25 pts at Acc@1; the graph adds ~0–1 pt at Acc@1 and ~4–7 pts at function level. Cost $0.66/example with Claude-3.5. Abstract: fine-tuned Qwen-32B 92.7% file-level, +12% Pass@10 downstream resolution.

### Agentless
- Xia et al., arXiv 2407.01489, https://arxiv.org/html/2407.01489v2 (v1 2024-07). Hierarchical localization: repo tree -> suspicious files (LLM + embedding retrieval) -> skeletons (class/function signatures) -> edit locations; then repair + validation. v1 27.33% SWE-bench Lite at $0.34; later version 32.00% at $0.70. Also found 4.3% of Lite issues contain the gold patch, 10% lack needed info. Key technique for reviewers: give the model a *skeleton* (signatures only) of related files rather than full bodies.

### AutoCodeRover (ISSTA 2024)
- Zhang et al., arXiv 2404.05427, https://arxiv.org/html/2404.05427v3 (2024-04). AST-based local search APIs (search class / method / method-in-file / code snippet) return signatures first, bodies on request; optional spectrum-based fault localization from tests ranks suspicious methods. 19% SWE-bench Lite (v3 abstract). Exact API names not re-verified from paper text.

### SWE-agent ACI (NeurIPS 2024)
- Yang et al., arXiv 2405.15793 (2024-05), https://arxiv.org/abs/2405.15793 ; NeurIPS 2024 https://papers.neurips.cc/paper_files/paper/2024/hash/5a7c947568c1b1328ccc5230172e1e7c-Abstract-Conference.html
- Computes: nothing precomputed. Commands `find_file`, `search_file`, `search_dir` return a *summary* (file list + match counts), capped at 50 results; a 100-line file viewer; linting guardrail on edit.
- Evidence (Table 3, SWE-bench Lite, GPT-4, read from the PDF text): Summarized search 18.0; Iterative search (one result at a time) 12.0; No search (shell only) 15.7. Viewer 100 lines 18.0 vs 30 lines 14.3 vs full file 12.7. Edit w/ linting 18.0 vs without 15.0. Lesson for a review harness: the *format* of search output matters as much as having search — summarised, capped results beat both raw shell and exhaustive paging; full-file dumps hurt.
- bash-only: yes (it is shell + wrappers around grep/find).

### CodexGraph (NAACL 2025)
- Liu et al., arXiv 2408.03910 (2024-08-07), https://www.arxiv.org/abs/2408.03910 ; NAACL 2025 https://preview.aclanthology.org/setup/2025.naacl-long.7
- Computes: static-analysis graph in Neo4j; nodes MODULE/CLASS/FUNCTION (+ fields etc.), edges CONTAINS/INHERITS/USES; the agent writes natural-language queries that a translation agent turns into Cypher. Evaluated on CrossCodeEval, SWE-bench, EvoCodeBench. bash-only: no (graph DB). Numbers not re-extracted here.

### CodeCompass (preprint 2026)
- Paipuru, arXiv 2602.20048 (2026-02-23), https://arxiv.org/abs/2602.20048v1 . Not peer reviewed; single author; one FastAPI repo, 30 tasks, 258 trials.
- Computes: dependency graph exposed via MCP server. Hidden-dependency task completion: graph 99.4% vs vanilla agent 76.2% vs BM25 78.2%. 58% of trials with the graph tool available made ZERO calls to it; agents needed explicit prompting to use it. Conclusion "not tool availability but behavioral alignment".
- Design implication: do not offer a graph as an optional tool — precompute the relation map and put it in the reviewer's prompt.

### Serena
- https://github.com/oraios/serena (read 2026-10-24). MCP server; SolidLSP backend wraps language servers (40+ languages; README lists Bash and Markdown) or a paid JetBrains backend. Capabilities: find symbol, symbol overview (file outline), find referencing symbols, find declaration, find implementations, symbol-level edit/rename. No quantitative benchmark published (vendor "agent-based evaluation" of ~20 tasks). Cost: a language server per language must start and index; first call is slow on big repos. Gives precise callers (`find_referencing_symbols`) which grep only approximates.

### Greptile (vendor)
- https://www.greptile.com/docs/how-greptile-works/graph-based-codebase-context (undated, read 2026-10-24). Parses every file into directories/files/functions/classes/variables linked by calls, imports, dependencies, variable usage; AI docstrings per node. At review time, for each changed function it pulls dependencies (what it calls/imports/reads), call sites ("changes will affect 3 files"), and *similar code* (other functions following the same pattern; example flags a concatenated SQL query next to parameterised ones). Reads claude.md / cursorrules; `patternsRepo` in greptile.json. VENDOR CLAIM, no published accuracy numbers.

### CodeRabbit (vendor)
- Code graph analysis docs https://docs.coderabbit.ai/integrations/code-graph-analysis (search snippet 2026-10-24; page returned 404 on fetch, so wording is from search snippet, UNVERIFIED). Three context types: definition files, reference files, and "related files" from usage patterns and *commit history (files that often change together)* — i.e. co-change mining in a commercial reviewer.
- Context-engineering blog https://coderabbit.ai/blog/context-engineering-ai-code-reviews (2025-07): sources = ticket intent, code graph, past PRs, learnings, linter output; claims a ~1:1 code-to-context token ratio in review prompts. VENDOR CLAIM.

### Augment Context Engine (vendor)
- https://www.augmentcode.com/blog/context-engine-mcp-now-live (2026-02-06) and changelog https://www.augmentcode.com/changelog/context-engine-mcp-in-ga : semantic index exposed over MCP; claims "70%+" agent improvement over 300 Elasticsearch PRs / 900 attempts (Claude Code+Opus 4.5 80%). Review benchmark post https://augmentcode.com/blog/we-benchmarked-7-ai-code-review-tools-on-real-world-prs-here-are-the-results (2025-12-11) credits retrieval of "files, dependencies, and call sites". VENDOR CLAIMS, not independently replicated; metric definition of "70%" not verified.

### Cursor indexing (vendor)
- https://cursor.com/blog/secure-codebase-indexing (read 2026-10-24; date not captured). Merkle tree of file hashes for incremental sync; syntactic chunks -> embeddings cached by chunk hash; index reuse across teammates (clones 92% similar). No accuracy number found in this post. VENDOR.

### Cursor semantic search A/B (vendor)
- https://cursor.com/blog/semsearch (2025-11). Semantic search *alongside* grep: +12.5% avg QA accuracy on internal Cursor Context Bench (6.5–23.5% by model); code retention +0.3% overall, +2.6% on repos >=1,000 files; dissatisfied follow-ups +2.2% when semantic search removed. Custom embedding trained on agent traces. VENDOR CLAIM; benchmark internal. Reading: embeddings add a modest increment on top of grep, mainly on large repos; they do not replace grep.

### Sourcegraph SCIP
- https://sourcegraph.com/blog/announcing-scip (2022; exact day not captured). Protobuf index format (successor to LSIF) produced by per-language indexers (scip-typescript, scip-python, scip-java, ...) run in CI; powers compiler-accurate go-to-definition / find-references / find-implementations, cross-repo when both sides indexed at matching commits. Search-based navigation is the fallback and "can occasionally return false-positive and false-negative results". Cost: one indexer run per language per commit (needs a build/type-check). bash-only: no, but `scip print`/`scip snapshot` output is greppable once produced.

### GitHub stack-graphs
- https://github.blog/2021-12-09-introducing-stack-graphs/ (2021-12-09); paper Creager & van Antwerpen, "Stack graphs: Name resolution at scale", arXiv 2211.01224 (EVCS 2023, https://drops.dagstuhl.de/opus/volltexte/2023/17778/). Declarative tree-sitter-based name-binding rules per language; each file's subgraph built in isolation, so incremental and no build needed. Note: GitHub archived the stack-graphs repo in 2025 (from memory, NOT verified this session).

### Moatless Tools
- https://github.com/aorwall/moatless-tools ; PyPI notes https://pypi.org/project/moatless/0.0.3a0 . Embedding-backed code search (Voyage vectors) + class/function-span retrieval; 0.0.1 GPT-4o 24% @ $0.13; 0.0.2 Claude-3.5 26.7% @ $0.17; 0.0.3 38% @ $0.30 (SWE-bench Lite). In LocAgent's table it trails SWE-agent/OpenHands on localization.

### OpenHands
- CodeAct agent uses bash, IPython, file editor, browser; no repo map or precomputed graph found in its README (https://github.com/All-Hands-AI/OpenHands , read 2026-10-24). Still the second-best localizer in LocAgent's table — evidence that plain shell exploration with a strong model is a high baseline.

### Change coupling / co-change mining
- Gall, Hajek, Jazayeri, "Detection of logical coupling based on product release history", ICSM 1998, https://plg.uwaterloo.ca/~migod/846/papers/gall-coupling.pdf . Origin of "logical coupling": modules that change in the same releases are dependent even without a code-level link. 20 releases of a telecom switching system.
- Zimmermann, Weißgerber, Diehl, Zeller, "Mining Version Histories to Guide Software Changes", ICSE 2004 (May 2004), PDF https://www.st.uni-trier.de/diehl/pubs/icse04.pdf ; TSE 2005 version reports top-3 >70%. ROSE mines association rules "programmers who changed these functions also changed..." with support/confidence. Uses: (a) predict further changes, (b) coupling "indetectable by program analysis", (c) "prevent errors due to incomplete changes". Numbers (8 OSS projects, read from PDF Table 2):
  - Navigation (support 1, conf 0.1): recall 0.15, precision 0.26, top-3 contains a correct location 64%.
  - Missing-change warning (support 3, conf 0.9, leave-one-out): recall ~0.04 (catches 1 in 25 omissions; GCC 1 in 5), precision ~0.50.
  - Closure (complete transaction, how often a false "missing" warning): ~98% of complete transactions get no false warning.
  - Design implication: a co-change "missing companion" flag is cheap and low-noise at high confidence but low recall — treat it as a hint to a reviewer, never a gate.
- Ying, Murphy, Ng, Chu-Carroll, "Predicting source code changes by mining change history", IEEE TSE 30(9) 2004, https://www.eecs.yorku.ca/course_archive/2009-10/W/6431/Murphy.pdf . Frequent-pattern mining of files changed together (Eclipse, Mozilla); evaluated "interestingness" — many recommendations are obvious, a minority are non-obvious and valuable.
- Tooling: code-maat (Tornhill), https://github.com/adamtornhill/code-maat . Input `git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after=YYYY-MM-DD`; `-a coupling` outputs entity, coupled, degree (0–100), average-revs. Defaults: min-revs 5, min-shared-revs 5, min-coupling 30%, max-changeset-size 30 (drop huge commits — renames/format sweeps poison co-change). Needs Java; the same computation is ~20 lines of awk over `git log --name-only --format=%H` (bash-only: YES).
- CodeRabbit lists commit-history co-change as one of its three review context types (see above; vendor).

### Test impact analysis
- Google TAP: Memon et al., "Taming Google-Scale Continuous Testing", ICSE-SEIP 2017, https://research.google.com/pubs/pub45861.html . TAP runs tests that transitively depend (via the Blaze/Bazel build graph) on changed code; findings: very few tests ever fail, failing tests are "closer" to the code they test, and code recently modified by several developers breaks more often. The build-graph selection detail is from general knowledge of TAP, not re-read in this paper this session.
- Facebook Predictive Test Selection: Machalica, Samylkin, Porth, Chandra, ICSE-SEIP 2019, arXiv 1810.05286 https://export.arxiv.org/abs/1810.05286 ; blog https://engineering.fb.com/developer-tools/predictive-test-selection/ . ML (gradient-boosted trees) over historical change/test outcomes; halves test infra cost while reporting >95% of individual test failures and >99.9% of faulty changes; blog: runs "just a third of all tests that transitively depend on modified code". Requires large CI history — not applicable to a small repo.
- Launchable PTS: https://docs.launchableinc.com/features/predictive-test-selection/how-launchable-selects-tests . Features: test history, how often changed files correlated with failing tests, name/path similarity, change size/type; ~2–4 weeks of data to train. VENDOR.
- Naming-convention mapping: Van Rompaey & Demeyer, "Establishing Traceability Links between Unit Test Cases and Units under Test", CSMR 2009, https://win.uantwerpen.be/~sdemey/Pubs/summ/VanRompaeyCSMR2009.html . Six strategies; "test conventions yield highly accurate results", and absent conventions "last call before assert" (LCBA) is the best alternative. bash-only: YES for naming (`tests/unit/gate.bats` <-> `bin/gate.sh`) and for "which test files mention this symbol/path" (`rg -l`).
- Coverage-based mapping (per-test coverage, e.g. `coverage run --context=test`, kcov for bash) is exact for what ran but needs a test run per mapping refresh. Not verified with sources this session.

### Code review needs context (human and LLM)
- Bacchelli & Bird, "Expectations, Outcomes, and Challenges of Modern Code Review", ICSE 2013, https://web.eecs.umich.edu/~weimerw/2018-481/readings/codereview.pdf . Microsoft study: "code and change understanding is the key aspect of code reviewing"; most understanding needs were unsupported by tools.
- AACR-Bench, arXiv 2601.19494 (2026-01-27), https://arxiv.org/html/2601.19494v1 . Review comments labelled by needed scope: diff-only 754, file 518, repo 233. Context modes: none / BM25 top-3 / embedding top-3 / agent (Claude Code). Findings: without context, recall drops as needed scope widens (Claude-4.5-Sonnet 45.8% diff -> 38.6% repo). Retrieval (BM25/embedding) often LOWERS F1 for strong models (Claude BM25 F1 9.98 vs none 14.46). Agent mode: precision up (Claude 39.9% vs 8.7%) but recall collapses (10.1% vs 42.9%) — ~0.1 comments per patch. Agent helps only some models (Claude yes; GPT-5.2, DeepSeek, Qwen no). Design implication: free-form agentic exploration makes reviewers conservative and terse; precomputed targeted context plus an explicit instruction to check each relation is the untested middle path.

### Structural search tools (local, bash-callable)
- universal-ctags reference tags: https://docs.ctags.io/en/latest/output-tags.html . `ctags -R -o - --extras=+r --fields=+rnK` emits definitions AND references with roles (def, imported, local, system, undef...). Reference coverage varies per language parser (strong for C/Python imports; weak for call sites in most languages). Not installed on this machine (checked 2026-10-24). Cost: seconds per repo; bash-only: yes once installed.
- ast-grep: https://ast-grep.github.io/guide/introduction.html . tree-sitter patterns with metavariables (`ast-grep --pattern 'foo($A)' --lang py`); Rust, multi-core, "tens of thousands files in seconds" (vendor). Bash not in the default language table (custom grammar possible). Use: "where is this pattern already implemented" with syntax awareness, e.g. find every other `trap ... EXIT` or every caller shape. Not installed here (`/usr/bin/sg` on this machine is the shadow-utils group tool, not ast-grep).
- Semgrep: https://semgrep.dev/docs/semgrep-code/semgrep-pro-engine-data-flow . Community Edition = per-file structural patterns (`pattern-inside`, `pattern-not-inside`, metavariables); cross-file taint/constant-propagation needs Pro (`--pro`, `options: interfile: true`). Use for "the change violates an existing project convention" rules; heavy (Python install). Bash support exists (Semgrep lists Bash as a supported language — from memory, not re-verified).
- Serena / LSP: see above — the only option here that gives type-aware callers (`find_referencing_symbols`) without a build-time indexer.

### Harness-like repos (instructions + scripts)
Evidence base is thin: no peer-reviewed study measured review accuracy on prompt/skill repos. What exists is (a) vendor guidance on how agents *read* instruction files, (b) link/prose linters, (c) young lint tools for agent config files.
- How Claude reads linked instruction files (primary, Anthropic): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (read 2026-10-24, undated). Only name+description preloaded; SKILL.md read on trigger; referenced files read on demand. "Claude might partially read files when they're referenced from other referenced files ... might use commands such as `head -100`" -> "Keep references one level deep from SKILL.md". Reference files >100 lines need a table of contents. SKILL.md body <500 lines. "Use consistent terminology". Implication for a reviewer: the include/reference graph of a harness IS its call graph; depth >1 and missing TOCs are review findings, and a renamed term is a cross-file break even when no link breaks.
- Claude Code plugin layout (third-party mirror of Anthropic's plugin-structure skill, https://tessl.io/registry/skills/github/anthropics/claude-code/plugin-structure ): `.claude-plugin/plugin.json`; `commands/*.md`, `agents/*.md`, `skills/<name>/SKILL.md`, `hooks/hooks.json`, `.mcp.json` at plugin root; `${CLAUDE_PLUGIN_ROOT}` path references. These give the edge types a relation map must extract: command -> step file (markdown link or "Read X"), command -> agent (subagent_type / persona name), skill -> reference file, hook -> script, script -> sourced lib (`source`/`.`), any file -> `bin/*.sh` invocation, test -> script under test.
- Link checking: lychee https://github.com/lycheeverse/lychee — `--offline` (local only), `--include-fragments` (anchors; target must be Markdown/HTML), `--root-dir` for absolute links. remark-validate-links checks local links and heading anchors offline (from memory, NOT verified this session). Both catch a renamed file or heading; neither catches a renamed *term*, a changed step number, or a changed contract.
- Prose/term linting: Vale https://vale.sh (rule types existence, substitution, consistency, etc., YAML rules, `.vale.ini`; per mintlify mirror https://www.mintlify.com/errata-ai/vale/guides/writing-rules ). A `substitution` rule is the cheap way to make a rename stick across all instruction files (old term -> new term), which is exactly the "clean renames" need.
- Agent-config contradiction linters (2025–2026, all young, mostly regex/structural, UNVERIFIED rule sets): promptproof (PyPI, offline, covers CLAUDE.md/AGENTS.md/SKILL.md/agents/commands, "contradiction detection"), whyrule (PyPI, CONFLICT001, notes CLAUDE.md layers concatenate rather than override), Codacy AgentLinter https://blog.codacy.com/introducing-agentlinter-codacy-now-scans-your-ai-agent-config-files (cross-file contradictions), cclint https://pkg.go.dev/github.com/pthm/cclint , ctxlint (stale commands, dead paths). None found with published precision numbers. Semantic contradiction ("must X" in A vs "never X" in B phrased differently) still needs an LLM judge given both texts.
- DSPy (Khattab et al., arXiv 2310.03714, 2023-10): prompts as typed modules (signatures) composed in Python, so prompt dependencies become ordinary code imports and a changed signature is caught by normal code analysis + re-compilation against a metric. Relevance: the cleanest way to make prompt dependencies analysable is to make them explicit references, which a markdown harness approximates with links and paths.
- Measured on this repo (2026-10-24, /home/kdabrow/workspace/vault): reverse-reference query "which tracked non-vault files mention `communication.md`" = `git ls-files -z | xargs -0 grep -IlF communication.md | grep -v '^vault/'` -> 20+ files in 0.07 s. Co-change query for `bin/gate.sh` over last 2,000 commits with changesets <=30 files (awk over `git log --format=@%H --name-only`) -> `tests/unit/gate.bats` co-changed in 8 of 12 gate.sh commits (~67%), then plan/architecture docs, in 0.10 s. Both are bash-only and cheap enough to run for every changed file on every review. Repo also already contains `graphify-out/graph.json` (a graphify knowledge graph, untracked) — not evaluated here.

### Recipe: bash-only relation map per changed file (derived from the sources above; not itself benchmarked)
For each path P in `git diff --name-only <base>...HEAD` (and each changed symbol S from `git diff -U0` hunk headers / ctags):
1. Inbound references to P: `rg -l --fixed-strings "$(basename P)"` and the repo-relative path; for markdown, also link targets `](...P...)`; for shell, `source|\. .*P` and bare invocations `bin/name`.
2. Outbound references from P (what P depends on): paths/links/`source`/invoked scripts inside P.
3. Callers of S: `rg -nw S` (exclude P itself and vault history dirs); with Serena, `find_referencing_symbols` instead; cap each list (SWE-agent: <=50, summarised).
4. Tests: naming convention (`tests/**/basename.*`), plus `rg -l` of P's path/S in `tests/`; flag "changed code, no test file changed".
5. Co-change companions: files with confidence >= ~0.5–0.9 and support >= 3 not in the diff -> "possible missing companion" (ROSE: high confidence => ~50% precision, low recall).
6. Similar implementations: `rg` / ast-grep for the changed construct elsewhere (Greptile "similar code") -> "does the change match or diverge from the existing pattern".
Emit as a compact per-file block (paths + line numbers + one-line excerpt), not file bodies (SWE-agent: full-file dumps hurt; Agentless: skeletons suffice).
