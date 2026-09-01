---
type: research
project: vault
slug: subagent-token-economics
status: living   # one measured run; add runs rather than rewriting
date_researched: 2026-09-01
tags: [research, subagents, tokens, cost, v-team]
---

# Subagent token economics — measured from one fan-out run

First-party measurement of where tokens go in a large `/v-team`-shaped fan-out. Distinct from
[[llm-collaboration-patterns]], which catalogs external evidence; this is one run of this framework,
instrumented. **n=1.** Treat the ratios as a starting hypothesis, not a result.

## Reproduce it

Transcripts live at `~/.claude/projects/<slug>/<session-id>.jsonl`, with per-agent files under
`<session-id>/subagents/`. Per-agent totals:

```sh
for f in *.jsonl; do
  jq -rs '[.[]|select(.message.usage)|.message.usage] as $u
    | [($u|length),
       ($u|map(.output_tokens//0)|add//0),
       ($u|map(.cache_read_input_tokens//0)|add//0),
       ($u|map(.cache_creation_input_tokens//0)|add//0)] | @tsv' "$f"
done
```

`<agent>.meta.json` carries the model and agent type actually used, which is the field to check
against what the orchestrator intended.

## The run

Mining 120 code-review comments across seven pull requests into vault rules: extract in six parallel
slices, critique in four lenses, finalize in five writers, then index. 21 agents, all `opus`,
1,436 turns.

| | turns | cache read | cache write | output |
|---|---|---|---|---|
| main thread | 319 | 69.4M | 0.7M | 310K |
| 21 subagents | 1,117 | 120.7M | 7.8M | 12K |
| **total** | **1,436** | **190.1M** | **8.5M** | **322K** |

**Cache read is the entire cost.** Output is 0.17% of input. Every turn re-reads its whole context,
so cost tracks `turns × context size`, and context size is the term worth attacking.

Average context per turn: 132K across all agents, 218K on the main thread.

## Findings, by what they would save

| # | finding | share of subagent tokens |
|---|---|---|
| 1 | Mechanical work ran on the frontier model | 13% (15.8M) |
| 2 | One verifier re-read the repo per item | 15% (18.6M) |
| 3 | Shared context handed to every agent whole | ~1% measured, unbounded in general |
| 4 | Spec changed after spawning, forcing a redo | 1.4% (1.7M) |

**1. Model choice was never justified per agent.** The orchestrator passed `model: "opus"` to all 21
spawns as a default. Four index-row writers (compress a file to a 20-word row) and two repair passes
following an exact spec produced mechanically checkable output and needed no frontier judgement. The
extractors and critics did: they made calls a cheaper model would have got wrong, and re-running them
would have cost more than the saving.

**2. A verifier given a repo re-reads it once per item.** The grounding critic checked 57 drafts
against live code with 79 tool calls and 126 turns, re-grepping the same tree each time. Building the
symbol and path index once in the parent and passing it collapses this. A repo with `graphify` already
has that index.

**3. Shared context was sliced by corpus, not by need.** A 27K dedupe sheet went to all six extractors
whole; each needed roughly a fifth. Small here, but it scales with agent count, not with the work.

**4. A spec change after spawning is a full redo.** Two row-writers finished at one word budget, then
repeated the work at another because the constraint arrived late. The orchestrator's sequencing error,
and the reason identifiers and formats are now settled before the fan-out.

## What the run got right

- **Artifacts written to disk as produced.** One agent hit a usage limit after writing 12 files and
  before reporting. The files survived; only the report was lost, and the orchestrator rebuilt it by
  reading them.
- **The critique round paid for itself.** 28.7M found factual errors in 7 of 57 drafts before they
  reached the vault, against a much larger cost to find them after.
- **Merge staged separately from extraction.** Six agents on disjoint slices produced 57 drafts that
  collapsed to 46 files. Overlap is structural, and a dedicated merge pass costs 2.6M.

## Limits

One run, one task shape — verification-heavy corpus mining, where re-reading source dominates. No
counterfactual was run: the model-tiering saving is inferred from what each agent did, not measured
against a cheaper model doing it. An implementation or refactoring fan-out may distribute differently.

## What changed because of it

`commands/_shared/agent-conduct.md` gained the fan-out rules on model tiering, settling identifiers
before spawning, and budgeting a merge stage.
