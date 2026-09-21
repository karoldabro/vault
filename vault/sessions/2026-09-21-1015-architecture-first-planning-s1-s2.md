---
type: session
project: vault
date: 2026-09-21
topic: architecture-first-planning-s1-s2
files_touched: [bin/gate.sh, lib/arch-check.sh, bin/doc-lint.sh, commands/_shared/architecture-spec.md, commands/v-team.md, commands/v-team/steps/03-propose-loop.md, templates/arch.md, templates/arch-harness.md, templates/plan.md, templates/VAULT.md, VAULT.md, vault/research/ai-code-slop.md, vault/decisions/ADR-031-architecture-first-planning.md]
decisions: [ADR-031]
tags: [session, planning, architecture, gates]
---

# architecture-first-planning-s1-s2

## Goal
Plan the architecture-first change to `/v-team` and `/v-pm` as a nine-session master plan, and build its first two sessions: the research write-up and the checked architecture spec with its gate.

## Did
- Wrote the master plan `vault/plans/2026-09-21-0900-architecture-first-planning.md`, its structure spec, its trail and a published human page (https://claude.ai/artifact/LHVhsU2fsQWNFpJTH6NKuC).
- Built `bin/gate.sh arch` in `lib/arch-check.sh` against the contract `commands/_shared/architecture-spec.md`, wired into `commands/v-team/steps/03-propose-loop.md` step (g) and `commands/v-team.md` Step 4.
- Added doc type `arch-spec` (cap 300) to `bin/doc-lint.sh`, the `arch_profile` key to `templates/VAULT.md` and `VAULT.md`, and the `arch_spec` and `human_plan` keys to `templates/plan.md`.
- Wrote `vault/research/ai-code-slop.md`, ADR-031 and the `architecture-before-code` indication.
- Tests: `tests/unit/gate.bats` 93 cases, two in `document-standard.bats`, three guards in `v-team.bats`; three seeded mutants each failed at least one arch test.
- Commit `1e72239`. The full unit suite has 803 tests and 5 fail, the same 5 that fail on the parent commit.

## Learned
- A reviewer's dry run of the receiving session found the spec contract missing from the plan. Two complete example specs made the contract concrete. The check scripts then derived every defect from them.
- `dod_profile` is `code` in all 13 operator repos, this harness repo included, so a separate `arch_profile` key was needed.
- `table_rows` dropped any dash-only data row as a separator; it now treats only the first separator line as one.
- A check script that pipes into `grep -q` under `pipefail` fails on SIGPIPE; capture the output first.
- Some research figures differed from the first summary: 97.0% of structural failures evaded type checking and 100% evaded tests and static security scans.
- A test helper named `mkrepo` already existed in `gate.bats`; a second definition silently changed four older tests.

## Behaviors & rules
- Profiled repo, plan names no `arch_spec` → `gate.sh arch` exits 1 naming the missing spec.
- Repo with no `arch_profile` or no `VAULT.md`, plan names no spec → exit 0 with no output.
- Spec table with no `PK` row → exit 1 naming the table; a foreign key with index `-` → exit 1 naming `table.column`.
- Interface param without a type, or with a default value → exit 1 naming `interface.method`; arrow types `->` and `=>` are legal.
- Spec still holding `{{` or `path/to/` → exit 1, so an unedited template never passes.
- CRLF spec gives the same verdict as its LF copy; a repeated section heading is refused.

## Next
- S3: human page renderer, `gate.sh human`, `human_plan` link check.
- S4: probe kit core, then S5 to S9 in the order of the plan's Sessions table.
- Open: 12 probe-tool claims unverified until S4; publishing an Artifact from a subagent is untested.

## Refs
- [[../plans/2026-09-21-0900-architecture-first-planning]]: the master plan and its nine session rows.
- [[../decisions/ADR-031-architecture-first-planning]]: the structural decisions.
- [[../indications/architecture-before-code]]: the working rule.
- [[../research/ai-code-slop]]: why agent code degrades, with sources.
