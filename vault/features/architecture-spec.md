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

Built: the spec contract, the gate, the two templates and the propose and approval wiring.

Not built. Each item is a session in `vault/plans/2026-09-21-0900-architecture-first-planning.md`:
- the human page renderer and its gate;
- the probe kit and plan-time auditors;
- master plans with cross-session contracts;
- probe results in review panels, `/v-rule`, and stack probe packs.

Non-goals: installing any tool, and changing `/v-work` or `/v-do`.

## Contracts
- `bin/gate.sh arch <file> [--repo <root>]`: the contract, section list, check order and message text are in `commands/_shared/architecture-spec.md`. Exit 0 prints `arch: ok <spec>`, exit 1 prints `REFUSED arch <spec>: <problem> [<row>]` per defect, exit 2 means an unreadable file or bad option.
- `bin/gate.sh all <plan> --phase propose|approve [--repo <root>]` runs `arch` after `criteria`.
- `arch_profile: <name>|none` in `VAULT.md`; absent means `none`. `<name>` is a profile in `arch-profiles/`, the repo's own first and then the framework's; `code` and `harness` ship. A new project type is a `<name>.tsv` and `<name>.md` pair. `arch_spec: <slug>.arch.md` and `human_plan: <url>` in plan frontmatter.
- doc-lint type `arch-spec`, cap 300 lines. Decision record: `vault/decisions/ADR-031-architecture-first-planning.md`.

## Behaviors & rules
- Profiled repo, plan names no `arch_spec` → exit 1 naming the missing spec.
- Repo with `none`, an absent key or no `VAULT.md`, plan names no spec → exit 0, no output.
- A table with no `PK` row, or a foreign key with no index → exit 1 naming the table or `table.column`.
- An interface param without a type, or with a default value → exit 1 naming `interface.method`.
- A spec holding `{{` or `path/to/` → exit 1, so an unedited template never passes.
- A spec whose `profile` differs from the repo's `arch_profile` → exit 1.

## Coupling
- `commands/v-team.md` Step 4 and `commands/v-team/steps/03-propose-loop.md` (a) and (g) name the gate; `tests/unit/v-team.bats` guards that text.
- `bin/doc-lint.sh` types a `*.arch.md` file as `arch-spec` when frontmatter gives no type.
- `bin/gate.sh` `check_is_claimed_elsewhere` skips `*.arch.md`.
- `lib/shared-module-rules.tsv` lists the contract module as an owner.

## Gotchas
- The gate checks form, not truth: a session can write plausible rows.
- `scripts/completion-hook.sh` lists plans by `status: approved`, so a spec carries no `status` key.
- A check script that pipes into `grep -q` under `pipefail` fails on SIGPIPE. Capture the output first.
- `dod_profile` is `code` in every operator repo, so it cannot select the harness profile.

## Sessions
- [[../sessions/2026-09-21-1015-architecture-first-planning-s1-s2]]: contract, gate, templates, wiring and tests.
