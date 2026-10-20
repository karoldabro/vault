---
name: agent-knowledge-context
description: Load when you choose what a product LLM agent sees (entity card, knowledge base or retrieval, few-shot examples) and when it abstains or escalates.
---

# Agent knowledge and context

## When to use

- You build the prompt for an agent: entity data, knowledge base, examples and rules.
- You add retrieval over a knowledge base or an example store.
- The agent answers when no knowledge supports the answer.
- A review of `personas/_shared/planning/agent-systems.md` raises context, retrieval or abstention.

## Rules

Context budget:

- **Send the smallest set of high-signal tokens that does the task.** Every model tested scored higher on focused input of about 300 tokens than on 113k tokens. https://www.trychroma.com/research/context-rot
- **Pre-load a compact entity card for the user or record the run concerns.** Code already knows these facts, so the model should not spend tool calls on them. https://github.com/humanlayer/12-factor-agents
- **Fetch live state, such as account or post status, through tools.** A pre-loaded copy goes stale and adds tokens the run may not need. https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- **Put the latest message and the key facts at the start or end of the prompt.** Models use information in the middle of a long input worst. https://arxiv.org/abs/2307.03172
- **Teach behaviour with a few diverse examples instead of a long rule list.** Instruction following falls as the instruction count grows, and earlier rules win. https://arxiv.org/abs/2507.11538

Knowledge base or retrieval:

- **Load the whole knowledge base with prompt caching when it fits under about 200k tokens.** Without a retrieval step, no answer fails on a retrieval miss. https://www.anthropic.com/news/contextual-retrieval
- **Compare the whole-base prompt against retrieval on the same cases before you choose.** A longer input also lowers accuracy. https://www.trychroma.com/research/context-rot
- **Above the budget, prefix each chunk with a short context from its document before you index it.** Contextual embeddings cut top-20 retrieval failures by 35%. https://www.anthropic.com/news/contextual-retrieval
- **Combine BM25 and embeddings, then rerank: retrieve about 150 and keep about 20.** This combination cut retrieval failures by 67%. https://www.anthropic.com/news/contextual-retrieval
- **Measure retrieval alone with recall@k on labelled question-to-entry pairs.** You then know whether a bad answer came from retrieval or from generation. https://jxnl.co/writing/2024/02/28/levels-of-complexity-rag-applications/
- **Return nothing below a relevance threshold, enforced in code.** Tangential retrieval scored 8.15 out of 10, worse than no retrieval at 9.18. https://www.elastic.co/blog/building-ai-agents-elasticsearch-platform
- **Define the threshold as a minimum score or minimum term overlap.** A match on any single query term is not a threshold, because almost every entry passes it. https://www.elastic.co/blog/building-ai-agents-elasticsearch-platform
- **Log every zero-result query as a knowledge gap, and fix the most frequent gaps first.** Content fixes on frequent gaps raised resolution by 1.23 points on average. https://fin.ai/research/a-causal-inference-approach-to-measuring-the-impact-of-improved-rag-content

Abstain and escalate:

- **Abstain or escalate in code when retrieval returns nothing, before the model drafts.** Strong models answer wrongly instead of abstaining when the context is insufficient. https://arxiv.org/abs/2411.06037
- **Attach one reason code from a fixed list to every escalation.** Examples: `no_knowledge`, `needs_human_judgement`, `abuse`, `asks_for_human`. A code makes escalations countable and testable. https://fin.ai/research/to-escalate-or-not-to-escalate-that-is-the-question

Few-shot example store:

- **Select by similarity first, then drop near-duplicates.** Similar examples beat random ones, and a covering set beats a set of near-duplicates. https://aclanthology.org/2023.acl-long.78
- **Redact personal data with consistent typed placeholders.** One name maps to one placeholder within an example, so the example keeps its meaning. https://mlflow.org/articles/pii-redaction-llm
- **Give the example store a retention period.** Stored examples hold customer text, so treat them as personal data. https://datenschutz-hamburg.de/fileadmin/user_upload/HmbBfDI/Datenschutz/Informationen/240715_Discussion_Paper_Hamburg_DPA_KI_Models.pdf

Erasure across AI stores is in `skills/agent-runtime-ops/SKILL.md`. What may enter the example store is in `skills/agent-self-improvement/SKILL.md`.

## Steps

1. Count the knowledge-base tokens with the provider's token-count endpoint. Under about 200k, load it whole and cached; above it, build retrieval.
2. List the entity card fields the task needs. Drop every field the task does not use, and cap the card in tokens.
3. Write a tool for each piece of live state the agent reads.
4. For retrieval, add chunk context, index BM25 and embeddings, merge the two ranked lists, and rerank.
5. Build at least 50 question-to-entry pairs from real questions. Compute recall@k and store it with the index version.
6. Sweep the relevance threshold on a replay set. Pick the value that keeps recall@k and removes tangential hits.
7. Route an empty result to abstain or escalate with a reason code. Write a gap row for each zero-result query.
8. Build the example store filter: similarity, duplicate cut, redaction.
9. Order the prompt: cached stable instructions and knowledge first, the latest message last.

## Checks

- Test: render the prompt for a fixture user; assert its token estimate stays under the budget and contains every card field.
- Command: the recall@k run prints k, n and recall; a change that lowers recall fails the run.
- `grep -rnE 'min_score|threshold' <retrieval service path>` finds a constant applied in the query.
- Test: an unrelated query returns an empty result and the run ends with an escalation reason.
- Test: a query that matches one common term only returns nothing.
- Test: a zero-result query writes one knowledge-gap row.
- Test: two near-identical examples are never returned together.
- Test: the redactor maps the same name to the same placeholder within one example.
- Test: the rule count in the system prompt stays under a fixed budget.
- Metric: share of runs that escalate with `no_knowledge`, per week.

## Laravel

Detect before you use: `composer show prism-php/prism`, `composer show laravel/ai`, `composer show pgvector/pgvector`. Check the database extension with `psql -c "select extversion from pg_extension where extname = 'vector'"`. Never assume one is installed.

- Prism caching: set `withProviderOptions(['cacheType' => 'ephemeral'])` on the system message that holds the stable knowledge. This applies to the Anthropic provider.
- Prism embeddings: `Prism::embeddings()->using(<provider>, <model>)->fromInput($text)->asEmbeddings()`.
- PostgreSQL full text: add a generated `tsvector` column with a GIN index, and query with `websearch_to_tsquery` in the content's language.
- Rank full text with `ts_rank_cd`, and apply the minimum score in the `WHERE` clause.
- pgvector: add a `vector(<dims>)` column with an HNSW index using `vector_cosine_ops`. Query with the `<=>` cosine distance operator.
- Apply the vector threshold in SQL as `1 - (embedding <=> :query) >= :min`, never in the prompt.
- Run retrieval tests on PostgreSQL. SQLite has no `tsvector` and no `vector` type.
- Fake model calls in tests with `Prism::fake()` so retrieval tests stay deterministic.

## Sources

- Context rot (Chroma): https://www.trychroma.com/research/context-rot
- Effective context engineering for AI agents (Anthropic): https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- 12-factor agents (HumanLayer): https://github.com/humanlayer/12-factor-agents
- Lost in the Middle: https://arxiv.org/abs/2307.03172
- How many instructions can LLMs follow at once (IFScale): https://arxiv.org/abs/2507.11538
- Contextual retrieval (Anthropic): https://www.anthropic.com/news/contextual-retrieval
- Levels of complexity: RAG applications (Jason Liu): https://jxnl.co/writing/2024/02/28/levels-of-complexity-rag-applications/
- 1 year and 1 million messages (Elastic): https://www.elastic.co/blog/building-ai-agents-elasticsearch-platform
- Causal impact of improved RAG content (Fin): https://fin.ai/research/a-causal-inference-approach-to-measuring-the-impact-of-improved-rag-content
- Sufficient context: https://arxiv.org/abs/2411.06037
- To escalate or not to escalate (Fin): https://fin.ai/research/to-escalate-or-not-to-escalate-that-is-the-question
- What makes good in-context examples (Liu 2021): https://arxiv.org/abs/2101.06804
- Diverse demonstrations (Levy 2023): https://aclanthology.org/2023.acl-long.78
- PII redaction for LLMs (MLflow): https://mlflow.org/articles/pii-redaction-llm
- Hamburg DPA discussion paper on LLMs: https://datenschutz-hamburg.de/fileadmin/user_upload/HmbBfDI/Datenschutz/Informationen/240715_Discussion_Paper_Hamburg_DPA_KI_Models.pdf
