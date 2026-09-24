---
type: trail
project: vault
plan: human-page-essentials
tags: [trail, record]
---

# human-page-essentials — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`plans/2026-09-24-1902-human-page-essentials.md`, which carries the current truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Contains-match on the status text | exact match on four status values | over 172 real Open items in givore plans it kept 11 and hid 25 operator items written as `**needs the operator:**`, `state` columns or qualified prefixes |
| Renderer strips parameter lists from quoted Data flow labels | `bin/gate.sh arch` refuses labels over 40 characters | the gate refused 28 of 33 existing specs, 6 of them in-flight givore plans |
| No status vocabulary gate | `bin/gate.sh human` refuses an unknown status | existing plans use free prefixes such as `pre-existing:` and `flaky, not this plan's:`; the contains-match already shows near misses |
| `open` and `blocked` items stay off the page | show them in the decisions block | gauge row O8 is agent work marked `open` |
| Page drops the Decisions table | keep it | 25 rows on the gauge page, all agent-owned detail |

## Findings & dispositions

### Round 1

Seats: consumer, correctness, architect with the quality lens. No persona pack resolves for this repo, so the shared personas were seated.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| consumer | consumer-1 | MAJOR | confirmed | the gauge preview from the unedited plan has no user-visible rows and long labels | applied: scratch copy relabelled; `labels` mode |
| consumer | consumer-2 | MINOR | confirmed | `open` rows are agent work | applied |
| consumer | consumer-3 | MINOR | confirmed | a misspelled status hides a trade-off | applied differently: contains-match; vocabulary gate rejected |
| consumer | consumer-4 | MINOR | confirmed | the TSV rows were not in the spec | applied: Config points |
| architect | architect-1 | MAJOR | confirmed | one mode per row let verdict and evidence reach the page | applied: separate `cols` field |
| architect | architect-2 | MAJOR | confirmed | a typo hides an operator decision | applied differently: contains-match |
| architect | architect-3 | MAJOR | confirmed | preview has empty blocks | applied |
| architect | architect-4 | MINOR | confirmed | hand-written erDiagram and double drawing undefined | applied |
| architect | architect-5 | MINOR | confirmed | `arch-profiles/code.md` tells authors to write signatures in nodes | applied: W-7, W-8 |
| architect | architect-6 | MINOR | advisory | defaulted questions are the operator's content | applied |
| architect | architect-7 | NIT | confirmed | wrong work-item id | applied |
| architect | architect-8 | NIT | confirmed | dossier has two lines to edit | applied |
| correctness | correctness-1 | BLOCKER | confirmed | exact match hides most real operator items | applied: contains-match, `state` column, stripped markup |
| correctness | correctness-2 | MAJOR | confirmed | label gate refuses 28 of 33 specs | applied: gate dropped, `labels` mode |
| correctness | correctness-3 | MAJOR | confirmed | preview has no user-visible rows | applied |
| correctness | correctness-4 | MAJOR | confirmed | SC-3 passes with the Data flow diagram gone | applied |
| correctness | correctness-5 | MAJOR | confirmed | `UQ`, spaced types, dotted names and `click` break the erDiagram | applied |
| correctness | correctness-6 | MINOR | advisory | footer path depends on the caller | applied |
| correctness | correctness-7 | MINOR | advisory | label rule ambiguous | moot: gate dropped |
| correctness | correctness-8 | NIT | confirmed | relationship form unpinned | applied |

### Round 2

Seat: correctness.

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| correctness | F1 | MAJOR | confirmed | `labels` empties `"PROPOSE step (a)"` and 6 other non-call labels | applied: strip only after a letter, digit or `_` |
| correctness | F2 | MAJOR | confirmed | multi-line bullets and paragraphs undefined under `match` | applied: whole-item matching |
| correctness | F3 | MAJOR | confirmed | `blocked — needs the operator` read as hidden | applied: wording and fixture row |

## Metrics

Round 1: 7 confirmed BLOCKER or MAJOR, all applied. Round 2: 3 new confirmed MAJOR, all applied; the round cap of 2 ended the loop. Probe block: tier full, no rows.

## Advisory test hints

- An observed criterion given `MET` and evidence after rendering leaves `bin/gate.sh human` at `human: ok`.
- A Data model holding a table and a hand-written erDiagram renders exactly one `erDiagram`.
- Match styles: `**needs the operator:**`, `**open** — x`, `blocked, api: x`, a `| state |` column.
- er edge inputs: `UQ`, `timestamp with time zone`, `click_count`, `-` reference.

## Rejected / deferred

- Test-design fan-out skipped: the change is a renderer with its cases enumerated by the panel and listed in the plan's Test plan.
