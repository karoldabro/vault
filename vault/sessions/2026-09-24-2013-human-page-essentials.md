---
type: session
project: vault
date: 2026-09-24
topic: human-page-essentials
files_touched: [lib/human-render.sh, templates/human-plan-sections.tsv, commands/_shared/human-plan.md, lib/arch-check.sh, arch-profiles/code.tsv, arch-profiles/harness.tsv, arch-profiles/code.md, arch-profiles/harness.md, templates/plan.md, templates/human-plan.html, tests/unit/human-plan.bats, tests/unit/gate.bats, tests/fixtures/human/plan.md, tests/fixtures/human/expected.html, vault/features/architecture-spec.md, .claude-plugin/plugin.json]
decisions: [ADR-031]
tags: [session, human-plan, planning]
---

# human-page-essentials

## Goal
Cut the human plan page down to what only the operator supplies or judges, after the operator judged the value-gauge page too long and cluttered.

## Did
- Rewrote `lib/human-render.sh` so `templates/human-plan-sections.tsv` drives the page with five fields per row and the modes `all`, `task`, `match`, `er`, `signatures`, `labels` and `diagrams`. Commit `a8c3ac3`.
- Dropped the "Check these yourself" checklist, the `@review` lines in both profiles and the `@` skip in `lib/arch-check.sh`.
- Added the `user-visible` status to `templates/plan.md` and rewrote `commands/_shared/human-plan.md`.
- Re-rendered the 12 local plan pages. Published a value-gauge preview from a relabelled scratchpad copy at `https://claude.ai/artifact/FDPXtEhAtQt3KstMrkW4wN`; the operator accepted it.
- Tests: `tests/unit/human-plan.bats` 33 of 33, three seeded mutants each failed a test. The full unit suite shows no new failure against `da3a2bd`; 9 tests fail there too.
- Set the plugin version to 1.11.0 and pushed `main` to `origin`.

## Learned
- Exact status matching hid most real operator items. Over 172 Open items in givore plans it kept 11 and hid 25 decisions written as `**needs the operator:**`, `state` columns or qualified prefixes.
- A 40-character diagram-label gate would have refused 28 of 33 existing specs, so the renderer strips parameter lists instead of the gate refusing them.
- `gate.sh verdict --run` re-runs the Docker suite through SC-5 and takes over ten minutes; editing `lib/` while it runs corrupts the comparison, because the container reads the repo live.
- Editing a plan's Open & deferred items makes its own page stale, so a plan whose check re-renders every page must be re-rendered after each such edit.

## Behaviors & rules
- An Open & deferred item whose status text names `operator` → shown under "Needs your decision"; edge: `blocked — needs the operator` shows, plain `open` or `blocked` does not.
- An item naming `user-visible` or `user visible` → shown under "Users will notice".
- A spec section the TSV does not list → reaches the page as its mermaid blocks only; a section two rows name draws its diagram once.
- A Data model table → one generated `erDiagram` that replaces any hand-written one; edge: with no table, the hand-written diagram shows.
- A quoted Data flow label `"Svc.run(id: int)"` → `"Svc.run()"`; edge: `"step (a)"` keeps its text.
- A verdict or evidence written into a success criterion → the page does not change.

## Next
- Six in-flight givore plans with `status: proposed` get a stale refusal from `bin/gate.sh human` at approval; their sessions re-render and republish.
- The published Artifacts of the 12 executed local plans still show the old page.
- The value-gauge plan's real Open rows still read `accepted`; its session relabels the user-facing ones `user-visible` when it next edits the plan.

## Refs
- [[../plans/2026-09-24-1902-human-page-essentials]]: the plan, with its criteria and evidence.
- [[../decisions/ADR-031-architecture-first-planning]]: decision 4, the script-rendered page, still holds.
- [[../features/architecture-spec]]: dossier updated with the page blocks.
- [[2026-09-21-1130-human-plan-page-and-profiles]]: the session that built the first page.
