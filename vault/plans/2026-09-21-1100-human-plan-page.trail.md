---
type: trail
project: vault
plan: 2026-09-21-1100-human-plan-page
tags: [trail, record]
---

# 2026-09-21-1100-human-plan-page — process record

Record class. Its contract document is `vault/plans/2026-09-21-1100-human-plan-page.md`.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| A script renders the page | a model writes the page from a template | a model omits diagrams silently and varies between runs |
| The gate compares the page with a fresh render | the gate searches the page for each spec element | one byte comparison covers presence, currency and tampering |
| Review checklist as `@review` lines in the profile | a fixed list in the renderer | the checklist differs per project type |

## Findings & dispositions

### Round 1

One round ran with two reviewers. The revision was not re-reviewed.

| reviewer | ref | severity | grounding | problem | result |
|----------|-----|----------|-----------|---------|--------|
| consumer | 1 | BLOCKER | confirmed | a correct renderer escapes `&` in a heading and fails SC-1 | applied: SC-1 compares the escaped heading |
| consumer | 2 | BLOCKER | confirmed | plan and checks disagree on `>` inside mermaid | applied: D-6, T-3, the contract |
| consumer | 3 | BLOCKER | confirmed | the skip rule was ambiguous and would fail SC-2 to SC-4 | applied: D-5, gate order in the contract |
| consumer | 4 to 9 | MAJOR | confirmed | sourcing the gate, frontmatter in the page, message texts, `@review` format, order of work, determinism traps | applied: D-3, D-7, D-8, the contract |
| consumer | 10 to 15 | MINOR, NIT | mixed | page structure, `--repo`, existing approve tests, fallback view | applied |
| skeptic | 1, 2 | MAJOR | confirmed | the page goes stale on status and verdict changes, and the master page was ordered before its edits | applied: D-3 column whitelist, master page moved to S3b |
| skeptic | 3 | MAJOR | confirmed | a URL proves only its shape | recorded as an accepted limit |
| skeptic | 4 | MAJOR | confirmed | plans use `\|`, bold, nested lists and long lines | applied: D-9, T-11, T-12 |
| skeptic | 5 | MAJOR | confirmed | 25 work items in one session | applied: split, the `/v-team` wiring and master page are S3b |
| skeptic | 6 | MAJOR | confirmed | regenerating the master page drops 5 hand-drawn diagrams | applied: S3b moves them into the master spec first |
| skeptic | 7 | MAJOR | confirmed | SC-7 could pass or fail for the wrong reason | applied: SC-8 runs the real gate on this plan and checks the page |
| skeptic | 8 | MAJOR | advisory | mermaid directives in plan text are interpreted by mermaid | applied: D-6, SC-7, T-13 |
| skeptic | 9 to 11 | MINOR | mixed | two table parsers, awk differences, byte equality proves the script ran | applied: T-11, golden page; the last recorded as an accepted limit |

### Diff review

| seat | finding | severity | grounding | what was wrong | outcome |
|------|---------|----------|-----------|----------------|---------|
| quality | Q-1, P-1 | MAJOR, MINOR | confirmed | work-item statuses stale, three edited files had no row | applied |
| quality | Q-2 | MAJOR | confirmed | `lib/human-render.sh` over its size budget | applied: budget raised to 340 with the added checks |
| quality | Q-3, Q-4 | MINOR | confirmed | argument parsing copied three times, EXIT traps replace each other | trap fixed; parsing recorded as deferred |
| quality | W-1 to W-3, R-1 | MINOR | confirmed | the wiring text did not name the tool call or the skip case | applied |
| quality | M-1, M-2 | MINOR | advisory | ragged graph labels, the overview diagram last, interfaces missing | applied |
| quality | T-1 | MINOR | confirmed | `variant` did nothing on a missing pattern, gate branches untested | applied |
| correctness | 1 | MINOR | confirmed | the diagram filter missed `Click` and a mid-line `;click` | applied: filter widened, T-19 |
| correctness | 2, 7 | MINOR, NIT | confirmed | empty diagram and unrecognised fences contradicted the contract | applied: contract states them |
| correctness | 3, 9 | MINOR, NIT | confirmed | wrong line for a final-newline difference, doubled message prefix | applied |
| correctness | 4, 5, 6 | MINOR, NIT | confirmed | duplicate ids, the keyword `end`, dropped extra cells, a trailing `\|` | applied |
| correctness | 8, 10 | NIT | confirmed | symlinked gate found no libraries, a quoted trap | applied; the stdin case recorded |
| correctness | 11 | NIT | confirmed | the master plan claimed this plan's check names | applied |

## Metrics
