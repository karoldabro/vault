---
type: feature
project: vault
slug: architecture-spec
status: in_progress
owners: []
tags: [feature, planning, gates]
---

# architecture-spec

## Scope
A `/v-team` plan in a repo that declares an `arch_profile` other than `none` carries a sibling structure spec, `plans/<slug>.arch.md`. `bin/gate.sh arch` checks it before any work item exists and again at the approval gate.

Built: the spec contract, the gate and the two templates. Also built: the propose and approval wiring, the human page renderer and its gate, the probe kit core, and the probe input to the review panels.

Not built. Each item is a session in `vault/plans/2026-09-21-0900-architecture-first-planning.md`:
- plan-time auditors that run the probe kit;
- master plans with cross-session contracts;
- `/v-rule` and stack probe packs.

Non-goals: installing any tool, and changing `/v-work` or `/v-do`.

## Contracts
- `bin/gate.sh arch <file> [--repo <root>]`: the contract, section list, check order and message text are in `commands/_shared/architecture-spec.md`. Exit 0 prints `arch: ok <spec>`, exit 1 prints `REFUSED arch <spec>: <problem> [<row>]` per defect, exit 2 means an unreadable file or bad option.
- `bin/gate.sh all <plan> --phase propose|approve [--repo <root>]` runs `arch` after `criteria`.
- `arch_profile: <name>|none` in `VAULT.md`; absent means `none`. `<name>` is a profile in `arch-profiles/`, the repo's own first and then the framework's; `code` and `harness` ship. A new project type is a `<name>.tsv` and `<name>.md` pair. `arch_spec: <slug>.arch.md` and `human_plan: <url>` in plan frontmatter.
- `bin/render-human.sh <plan>` writes `<plan>.human.html` from the plan and its spec, and `bin/gate.sh human <plan>` checks it; `all --phase approve` runs the check after `arch`. The rules are in `commands/_shared/human-plan.md`.
- `templates/human-plan-sections.tsv` lists the page blocks. From the plan it takes the operator's decisions, defaults, user-visible trade-offs and hand checks. From the spec it takes the data model as an `erDiagram`, the file tree, the data flow and the interface signatures. Every other section reaches the page only as its diagrams.
- `bin/probe.sh list|detect|run <plan|review>|diff|scale` runs the deterministic probes of `probes/registry.tsv` on a repo and prints six-field findings; `probes/harness.sh`, `probes/sql-schema.sh` and `probes/similar-symbols.sh` are the native probes. `bin/probe-panel.sh run --posture pr|own` gives the review panels of `/v-team`, `/v-cr` and `/v-work` one fenced block of rows, under the rules of `commands/_shared/critic-panel.md` §(a). The contract is `commands/_shared/probe-kit.md`, and what each tool claim turned out to be is in `vault/research/probe-tool-verification.md`.
- doc-lint type `arch-spec`, cap 300 lines. Decision record: `vault/decisions/ADR-031-architecture-first-planning.md`.

## Behaviors & rules
- Profiled repo, plan names no `arch_spec` → exit 1 naming the missing spec.
- Repo with `none`, an absent key or no `VAULT.md`, plan names no spec → exit 0, no output.
- A table with no `PK` row, or a foreign key with no index → exit 1 naming the table or `table.column`.
- An interface param without a type, or with a default value → exit 1 naming `interface.method`.
- A spec holding `{{` or `path/to/` → exit 1, so an unedited template never passes.
- A spec whose `profile` differs from the repo's `arch_profile` → exit 1.

- Repo registry present, no `--allow-repo-registry` → its rows never run; with it, `--no-repo-code` skips them.
- Registry row names an absent tool → `absent: <id>: <install>` on stderr, exit 2, nothing installed.
- A probe prints a malformed row → that probe fails, prints no row, and the run exits 2.
- `diff` in a repo whose config defines a filter, fsmonitor or hook command → none runs.

## Coupling
- `commands/v-team.md` Step 4 and `commands/v-team/steps/03-propose-loop.md` (a) and (g) name the gate; `tests/unit/v-team.bats` guards that text.
- `bin/doc-lint.sh` types a `*.arch.md` file as `arch-spec` when frontmatter gives no type.
- `bin/gate.sh` `check_is_claimed_elsewhere` skips `*.arch.md`. `bin/gate.sh` runs `main` only when executed, so `bin/render-human.sh` sources its helpers.
- `commands/v-team/steps/03-propose-loop.md` (g) renders, publishes and records the page; `commands/v-team.md` Step 4 gates it again; `tests/unit/v-team.bats` guards that text.
- `lib/shared-module-rules.tsv` lists the contract module as an owner.

## Gotchas
- The gate checks form, not truth: a session can write plausible rows.
- `scripts/completion-hook.sh` lists plans by `status: approved`, so a spec carries no `status` key.
- A check script that pipes into `grep -q` under `pipefail` fails on SIGPIPE. Capture the output first.
- `dod_profile` is `code` in every operator repo, so it cannot select the harness profile.
- A page renders only the blocks and columns listed in `templates/human-plan-sections.tsv`; an Open & deferred item whose status names neither `operator` nor `user-visible` stays off the page.
- A diagram line holding `click`, `href` or `javascript` is dropped from the page, so a label containing one of those words disappears too.

## Sessions
- [[../sessions/2026-09-21-1015-architecture-first-planning-s1-s2]]: contract, gate, templates, wiring and tests.
- [[../sessions/2026-09-21-1130-human-plan-page-and-profiles]]: profiles as data, the human page renderer, its gate and the `/v-team` wiring.
- [[../sessions/2026-09-24-2013-human-page-essentials]]: the page shows only the operator's decisions, defaults, user-visible trade-offs, hand checks, diagrams and signatures.
- [[../sessions/2026-09-21-1400-probe-panel-input-s7]]: `bin/probe-panel.sh` feeds probe rows to the review panels; the `probe:` key of an indication.
- [[../sessions/2026-09-21-1317-probe-kit-core-s4]]: the probe kit core, its tool verification and two review rounds.
