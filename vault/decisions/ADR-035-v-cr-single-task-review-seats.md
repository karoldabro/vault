---
type: decision
project: vault
id: ADR-035
slug: v-cr-single-task-review-seats
status: accepted
scope: repo
date: 2026-10-24
supersedes_in_part: [ADR-034]
tags: [adr, v-cr, personas, code-review]
---

# ADR-035 — /v-cr seats five single-task reviewers fed by a precomputed relation map

## Context

`/v-cr` seated the same diff-review panel as `/v-team`: architect, `quality` and `correctness`. Each lens
covered several questions, and none owned the cross-file consequences of a change, the tests a change
needs, or whether the diff delivers the ticket.

Maintainability issues are about 68% of verified review issues on SWR-Bench, and models score lowest on
them: F1 26% on logic bugs, at most 16% on code organisation (`vault/research/review-agent-splits.md`).
Recall falls as the scope a defect needs widens from diff to file to repo. Shipping reviewers split work
by owned check: Amp runs one agent per check file, Baz one per ticket requirement, Qodo 2.0 bug,
standards, architecture and risk agents. No controlled study isolates what role specialisation adds.

A graph tool that an agent is offered goes unused in 58% of trials (CodeCompass, 2026). One hop of callers
and references carries most of a code graph's measured gain (RepoGraph, ICLR 2025). Every relation a
reviewer needs computes in about a tenth of a second with git and grep (`vault/research/review-code-context.md`).
ADR-032 bars the framework from prescribing a code-graph tool.

## Decision

1. **Five seats, one question each**, in priority order: `review/change-impact`, `review/test-gap`,
   `review/architecture-fit`, `review/pattern-conformance`, `review/intent-trace`
   (`personas/_shared/review/`, selected by `personas/_resolution.md` §2.4).
2. **Two lenses may join:** `correctness` on the high-risk list and `security` on the auth keywords. A
   joining lens takes a free seat or the lowest-priority one, never change-impact or test-gap. The cap is
   five.
3. **The relation map is precomputed and handed to each seat.** `bin/change-map.sh` reads git objects
   only and emits six relations per changed file: referenced-by, references, caller, test, co-change,
   sibling. Each persona's frontmatter `map:` key names the slice it receives.
4. **One evidence table.** `personas/_shared/review/README.md` holds each seat's confirm rule. It replaces
   the four design-evidence kinds of `commands/_shared/critic-panel.md` (e) for these seats.
5. **Co-change rows ground advisory findings only.** At ROSE's settings co-change was about 50% precise
   and caught about 4% of omissions.
6. **The head ref comes from the adapter `fetch_ref` op** on every run. Without `--sandbox` it is fetched
   into `refs/vcr/<n>` of a local repo whose remote names the base repo, and deleted at capture.

## Superseded clauses

- ADR-034 decision 5, for `/v-cr` only: diff review there no longer seats architect, `quality` and
  `correctness` by default. `/v-team` §5.2 keeps them.

## Consequences

- A `/v-cr` review spawns five agents instead of three.
- Project rules routed to a review go to architecture-fit.
- A review with no local clone of the base repo runs the seats on the diff alone and says so.
- The map is unmeasured against diff-only review beyond the seeded fixture of
  `vault/plans/2026-10-24-1903-v-cr-abstract-review.md` C3.
- **Watch for:** seats that return nothing on a capped slice, and co-change hints that operators start
  treating as must-fix.

## Alternatives considered

- **Repeated identical generalist passes with a merge** — better measured (Bugbot, SWR-Bench), but no seat
  owns a question, so a check can go unrun without anyone noticing.
- **A graph tool offered to agents** — offered tools go unused.
- **ctags, tree-sitter or ast-grep** — not installed, and ADR-032 bars a prescribed tool.
- **The same seats for `/v-team`** — the operator scoped this change to `/v-cr`.
