---
type: session
project: vault
date: 2026-09-21
topic: human-plan-page-and-profiles
continues: [[2026-09-21-1015-architecture-first-planning-s1-s2]]
files_touched: [bin/render-human.sh, lib/human-render.sh, lib/human-check.sh, bin/gate.sh, lib/arch-check.sh, arch-profiles/code.tsv, arch-profiles/harness.tsv, templates/human-plan.html, templates/human-plan-sections.tsv, commands/_shared/human-plan.md, commands/v-team.md, commands/v-team/steps/03-propose-loop.md]
decisions: [ADR-031]
tags: [session, planning, architecture, gates]
---

# human-plan-page-and-profiles

## Goal
Make the architecture spec profiles data instead of code. Then build session S3 of the master plan. S3 is a script that renders the human plan page, a gate that checks it, and the `/v-team` wiring.

## Did
- Moved the section list of the `code` and `harness` profiles out of `lib/arch-check.sh` into `arch-profiles/<name>.tsv`, loaded by name from the repo first and then the framework. Commit `988c15e`.
- Planned S3 with two reviewers and split it in two. The operator then asked for one session, so the halves merged. The plan is `vault/plans/2026-09-21-1100-human-plan-page.md`.
- Built `bin/render-human.sh`, `lib/human-render.sh` and `lib/human-check.sh`. `bin/gate.sh human` re-renders the page and compares it byte for byte with the file on disk.
- Added `@review` checklist lines to both profiles, `templates/human-plan-sections.tsv` for the plan sections shown, and the wiring in `03-propose-loop.md` (g) and `commands/v-team.md` Step 4.
- Regenerated the master plan's page with the renderer and published both pages. Commit `7a1063e`.
- Tests: `tests/unit/human-plan.bats` 22 cases, rendered in the BusyBox container against a golden page made on the host. The suite has 832 tests and the same 5 fail as on the parent commit.

## Learned
- A bare `! grep` in the middle of a bats test never fails it. Half of the first negative assertions here were vacuous, and a seeded break survived until the check went through a function.
- A page that is a pure function of the plan and spec goes stale on every status flip unless the page hides the volatile columns. Whitelisting columns per section fixed that.
- Mermaid interprets directives itself, so HTML escaping is not enough. A line holding `click`, `href` or `javascript` in any case is dropped.
- Two check scripts named in two plans make the gate refuse the second plan. The master plan's evidence text named this plan's checks in backticks.
- Sourcing `bin/gate.sh` needed `main` to run only when executed. `bin/render-human.sh` then reuses its helpers.

## Behaviors & rules
- Plan names an `arch_spec` and the page differs from a fresh render → `gate.sh human` exits 1 and names the first differing line.
- Plan names no `arch_spec` → `gate.sh human` exits 0 with no output.
- `human_plan` empty, not an `https://claude.ai/artifact/<id>` URL, or a `file:` name other than the page's → exit 1.
- A Sessions status, date, verdict or evidence changes → the page does not.
- A mermaid line holding `click`, `%%`, `href`, `javascript` or `vbscript` in any case → left out of the page.
- A repo adds a project type by adding `arch-profiles/<name>.tsv` and `.md`; no framework code changes.

## Next
- S4 probe kit core, then S5 to S9 in the order of the master plan's Sessions table.
- Open: 12 probe-tool claims unverified until S4; publishing an Artifact from a subagent is untested.
- Deferred: `cmd_arch`, `cmd_human` and the renderer repeat one argument parser; `tests/unit/v-team.bats` lines 54 to 79 hold vacuous negative assertions.

## Refs
- [[../plans/2026-09-21-1100-human-plan-page]]: the S3 plan.
- [[../plans/2026-09-21-0900-architecture-first-planning]]: the master plan.
- [[../decisions/ADR-031-architecture-first-planning]]: decisions 1 to 4.
- [[../features/architecture-spec]]: the feature dossier.
