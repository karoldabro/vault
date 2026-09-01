# {{feature}} — generic plan

Project-agnostic. Only `/v-pm` (plan / reconcile) writes this. Each project reads it and writes its own
`projects/<proj>/plan.md` shard.

## Problem & outcome
<!-- The *why* lives in `requirements.md` (Business context & goals) — the single source. Do NOT restate
     it here; link it: → [requirements.md](./requirements.md). This section is a one-line pointer only. -->
→ see `requirements.md` — Business context & goals.

## Scope / non-goals

## Solution shape (across products)
<!-- How the products together deliver it; which moves first (usually the api). -->

## Sequencing

## Appetite
<!-- How many sessions this feature is WORTH in each repo, decided before the design is detailed.
     A ceiling the executing session must fit inside by cutting scope — not an estimate it may exceed.
     Cut against the [must]/[should]/[could] priorities in requirements.md.
     This is the ONLY sizing /v-pm emits: it does not read the code, so it never writes session-sized
     tasks. Each repo's own /v-team session splits its scope and owns the resulting rows.
     Rule: vault/indications/plan-appetite-not-tasks.md. -->
| repo | appetite (sessions) | what forces the ceiling |
|------|---------------------|-------------------------|
|      |                     |                         |

## First slice
<!-- The one cut that runs vertically through the HARDEST part, so the surprise arrives first.
     Name the part most likely to be wrong — a new integration, an external dependency, a rule nobody
     has stated cleanly — and slice through that, not through the easiest layer. One paragraph. -->

## Options considered
<!-- The approaches REJECTED and why, so the next planner does not rediscover them. Current truth: the
     reason, not the argument that produced it. One row each; omit when only one approach was viable. -->
| option | why not | source |
|--------|---------|--------|
|        |         |        |

## Research / prior art
<!-- Cited sources from the planning research gate (title · URL · takeaway). -->
