---
type: decision
project: vault
id: ADR-031
slug: architecture-first-planning
status: accepted
scope: repo
date: 2026-09-21
tags: [adr, planning, architecture, probes]
---

# ADR-031 — architecture before code: a checked spec, a generated human page, one home for probes

## Context

Agent-written code degrades in a small number of known ways: duplication instead of reuse, local
correctness without a global view, missing conventions and unbounded change volume
(`vault/research/ai-code-slop.md`). In one study 97.0% of structural failures evaded type checking and
100% evaded tests and static security scans. A green pipeline therefore does not show that a design is
coherent, and a person has to judge structure before code exists.

A `/v-team` plan held one work item per file. Agents read that well. A person cannot review data model,
layering and data flow from it. Plans also grow past the 300-line document cap when they carry structure.

`vault-quality-gates` already refuses a push when a metric is worse than its committed baseline. Probes
that run while an agent plans and reviews answer a different question at a different moment.

## Decision

1. **A plan is four files.** `plans/<slug>.md` is the agent plan. `plans/<slug>.arch.md` states the
   structure to build. `plans/<slug>.trail.md` records how the plan was reached. A generated human page
   is published as an Artifact and linked from the plan's `human_plan` key. Probes need structured
   input, and the human page renders from it.
2. **A profile is data.** `arch-profiles/<name>.tsv` lists a project type's sections, columns and rules
   and `<name>.md` is the starting text. The gate loads only the profile a spec names, from the repo's
   own `arch-profiles/` first and then from the framework, so a new project type is a new file and no
   code change. `arch_profile` in the repo's `VAULT.md` names it, or `none`; an absent key means `none`,
   so no existing repo is refused. `dod_profile` cannot serve, because it is `code` in every operator
   repo, including this harness repo.
3. **`bin/gate.sh arch` checks the spec** against `commands/_shared/architecture-spec.md`. It runs when
   the plan is finalised and again at the `/v-team` approval gate, so a session cannot skip it by
   omitting the spec.
4. **A script renders the human page and a gate compares it.** `bin/render-human.sh` writes
   `<plan>.human.html` from the plan and its spec, with no model in the loop. `bin/gate.sh human`
   re-renders the page and compares it byte for byte with the file on disk, so one check proves the page
   is present, current and untampered. The page shows only what a person reads at approval, so a status
   flip or a written verdict never makes it stale.
5. **The probe kit lives in this framework**: `bin/probe.sh` and `probes/registry.tsv`, with the contract in
   `commands/_shared/probe-kit.md`. A probe never installs a tool. A missing tool reports
   `absent: <id>: <project-scope install command>` and the run exits 2. A registry row names a tool only when
   `vault/research/probe-tool-verification.md` marks its flag verified and a parser test consumes its real
   output. A repo's own registry is read only when the caller passes `--allow-repo-registry`.
6. **A spec is document type `arch-spec` with a 300-line cap.** A 10-table feature estimates at 190 to
   230 lines, and the spec sits beside a 300-line plan.
7. **Every master plan carries a `## Cross-session contracts` table.** A later gate refuses a master plan
   where a dependency between two sessions has no contract row, or a contract names a session that does
   not exist. Otherwise a session that consumes another's output redefines its shape.

## Rejected

- **Extend `vault-quality-gates`.** It is optional, runs at push time and compares against a baseline.
  Probes here run in every planning and review session.
- **Reuse `dod_profile`.** It would give this repo the code spec, so the harness profile could never apply.
- **Hand-written human page.** A page written per run omits diagrams silently and varies between runs.
- **Structure inside the plan file.** The plan would cross its 300-line cap and mix two questions.

## Consequences

Structure is reviewable by a person before any code exists, and the gate refuses a spec with an untyped
parameter, a table without a primary key, or a foreign key without an index.

Every profiled plan grows a second file. The gate checks form, not truth: a session can fill the spec
with plausible rows. Probes that compare the spec against the existing code (later sessions) address that.

Longer planning has no controlled evidence behind it. The plan-time stage is capped at 50% added cost
over a `/v-team` PROPOSE, and the session that builds it reports the measured delta.

Watch: whether specs are filled with rows written to satisfy the gate, and whether the gate refuses
specs that a reviewer would accept.
