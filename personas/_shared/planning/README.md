---
type: persona-group
group: planning
tags: [persona, shared, planning]
---

# planning — critic group

A **stack-agnostic group of plan critics**. Each lens reviews a written plan before any code exists:
an architecture, a session split, a set of briefs. `/v-pm` seats this group on every planning panel
(selection: `personas/_resolution.md` §2.3). Any other command reuses a lens by its group-qualified id,
`planning/<id>`, through a pack's `use_shared` or `VAULT.md` `personas.add`.

Two kinds of deliverable get planned here, and they fail differently. **Software** fails at runtime:
wrong boundaries, lost data, broken contracts. **An AI harness** (commands, prompts, agents, hooks,
gates) fails when a model reads ambiguous text, loops without a cap, or claims success nothing checks.
`harness-engineer` owns the second kind; every other lens applies to both.

## The lenses

| lens | owns | not mine, goes to |
|------|------|-------------------|
| [[solution-architect]] | boundaries, interfaces, quality-attribute trade-offs, hard-to-reverse decisions, ADR conflicts, design-level failure behaviour | in-repo reuse → codebase-fit · buy or build → lazy-dev · cross-system data flow → system-integration · threats → security-architect · session split → delivery-planner |
| [[codebase-fit]] | the plan uses the repo's existing modules, layers, conventions and ADRs, and adds no second way of doing one thing | an external package or product → lazy-dev · whether the existing pattern is the right architecture → solution-architect |
| [[lazy-dev]] | an existing product, package, framework feature or config change does the job; over-engineering; the simplest plan that meets the stated need | the repo's own modules → codebase-fit · a one-way door that must be decided now → future-scope |
| [[future-scope]] | one-way doors and cheap seams that an MVP usually drops (retention, idempotency, audit, analytics events, logging, flags) | speculative generality → lazy-dev wins · the seam's shape → solution-architect |
| [[system-integration]] | the surface between two or more systems: contracts, data ownership, consistency, retries, versioning, deploy order | the inside of one system → solution-architect · caller authentication and abuse → security-architect |
| [[security-architect]] | trust boundaries, the authorization model, data classification, secrets, attack surface, abuse cases, AI-agent tool permissions | a defect visible only in code → `personas/_shared/security.md` at diff review · contract ordering and failure → system-integration |
| [[harness-engineer]] | a harness plan: deterministic code against model judgement, mechanical verification, context budget, loop and spawn caps, tool contracts | the literal handoff dry run → `personas/_shared/consumer.md` · system structure → solution-architect |
| [[delivery-planner]] | the split into sessions: vertical slices, hardest part first, size, dependencies, acceptance commands, rollout and rollback per session | what each session builds → the lenses above · whether a prompt is usable → consumer |

`consumer` and `skeptic` from `personas/_shared/` sit beside these lenses. On a planning panel
`skeptic` leaves the simpler-path question to `lazy-dev`.

## Grounding rule

A finding is `confirmed` only when its `check` field holds evidence the synthesizer can re-run:

- a repo `path:line`, or the grep command and its output;
- a vault path, with the line that conflicts;
- a command and its output, such as `npm view <pkg> version time.modified` or `composer show <pkg>`.

A fetched URL alone keeps a finding `advisory`. The operator still sees it, as a proposal with its
source. Only a `confirmed` finding may be a BLOCKER or MAJOR. Each lens's Output section links here
and states no second version of this rule.

## Scale tiers

Intake (`commands/v-pm/steps/01-intake.md`) sets the tier from facts it can count. Each lens reads
the tier from its envelope and demands only what its own `## Scale` section allows for that tier.

| tier | when | reviewers | rounds |
|------|------|-----------|--------|
| small | 1 repo, and no schema, auth, payment, public-contract or new-external-service change | 3 | 1 |
| medium | every case that is neither small nor large | 4 | 2 |
| large | 3 or more repos, or 2 repos with a contract change, or a new system | 5 | 2 |

The tier sets the per-run caps. A `team_max_parallel_critics` or `team_max_rounds` key in the repo's
`VAULT.md` caps the per-run value; the panel never writes those keys.

**Zero findings is a valid result.** A lens with nothing grounded to say on a small plan says so in
one line rather than inventing a concern.
