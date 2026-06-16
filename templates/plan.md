---
type: plan
project: {{project}}
slug: {{slug}}
status: proposed   # proposed | approved | executed | superseded
personas: [{{pack}}]
rounds: {{n}}
convergence: clean   # clean | capped-with-open-blockers
tags: [plan, team]
---

# {{slug}} — team plan

Written by `/v-team`. The converged implementation plan plus the full critique trail and the
proposed-test backlog. Reviewed at the approval gate; drives EXECUTE.

## Task
<!-- One-sentence restatement + keywords (from ANALYZE). -->

## Converged plan
<!-- Final implementation steps, dependency-ordered (v-work 03 §3a.4 shape):
     File (exact path) · Action · Tool · Pattern. -->

## Test plan
<!-- Per unit: type · scenarios · file location (v-work 03 §3a.5 shape). -->

## Proposed test backlog
<!-- Aggregated from every critic's PROPOSED_TESTS. `disposition` is filled during EXECUTE by the
     testing agent (implement | change | skip + reason). -->

| id | persona | kind | target | intent | priority | disposition |
|----|---------|------|--------|--------|----------|-------------|
|    |         |      |        |        |          |             |

## Open trade-offs / deferrals
<!-- Conflicts surfaced to the user (e.g. perf cache vs security freshness), accepted MINOR/NIT
     deferrals with rationale, and advisory (unconfirmed) findings worth recording. -->

## Critique trail
<!-- One subsection per round. Each finding's disposition: applied | deferred | rejected (+reason).
     Plus per-round metrics (findings-delta, per-persona overlap, confirmed-vs-advisory, token cost). -->

### Round 0 — draft
<!-- The v0 plan before any critique. -->

### Round 1 — findings + dispositions
| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
|         |    |          |           |       |             |

_Metrics: new confirmed blockers: N · findings-delta: N · persona overlap: N · tokens: N_

## Refs
<!-- Wikilinks: ADRs, feature dossiers, and the session ([[YYYY-MM-DD-HHMM-<slug>]]) that executes this. -->
