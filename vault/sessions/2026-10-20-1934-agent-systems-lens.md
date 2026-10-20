---
type: session
project: vault
date: 2026-10-20
topic: agent-systems planning lens and agent skills
files_touched: [personas/_shared/planning/agent-systems.md, personas/_shared/planning/README.md, personas/_shared/planning/security-architect.md, personas/_shared/planning/harness-engineer.md, personas/_resolution.md, personas/api-laravel.md, skills/agent-shape/SKILL.md, skills/agent-trust-boundaries/SKILL.md, skills/agent-tools-mcp/SKILL.md, skills/agent-output-validation/SKILL.md, skills/agent-knowledge-context/SKILL.md, skills/agent-evals/SKILL.md, skills/agent-self-improvement/SKILL.md, skills/agent-runtime-ops/SKILL.md, install.sh, INSTALL.md, vault-guide.md, checks/agent-systems-lens-C3.sh, tests/unit/agent-skills.bats, tests/unit/agent-systems-c3.bats]
decisions: []
tags: [session, persona, skills, agents]
---

# agent-systems planning lens and agent skills

## Goal

Add a critic lens that scopes the architecture of LLM agents a product runs for its users, plus plugin skills that teach how to build them, grounded in cited research.

## Did

- Added `personas/_shared/planning/agent-systems.md`: five concerns, 12 checklist items, each naming one skill; severity keyed to deterministic versus probabilistic controls.
- Moved product-agent rules out of `security-architect.md` and `harness-engineer.md`; `harness-engineer` now covers developer harnesses only.
- `personas/_resolution.md` §2.3 seats `planning/agent-systems` first when the product makes a runtime LLM call; `api-laravel` lists it in `use_shared`.
- Added eight skills under `skills/agent-*/SKILL.md`, the framework's first `skills/` folder; `install.sh` links it for symlink installs.
- Stored three research records (127 sources) in `vault/research/v-pm-planning-lenses/agent-systems-*.md`.
- Fixed two old plugin layout test failures: `commands/v-reconcile.md` description, `commands/v-loop/adapters/test-and-repair.md` path note.
- Commit `664f08a` on `feat/agent-systems-lens`; not pushed.

## Learned

- The live lens run on the recycling-api support drafter returned 12 confirmed findings. The main one: the judge shares the writer's model (`claude-opus-5-5`) and was never measured against the operator's sends. Saved in `vault/plans/2026-10-20-1934-agent-systems-lens.c3-run.md`.
- `vault-quality-gates` `guard-bash.sh` refuses `bin/doc-lint.sh`, the working-copy `bin/gate.sh`, any command word or target built from a variable, and Python that mentions git or a plugin. Use the cached plugin `bin/gate.sh` and the Edit tool instead.
- `bin/gate.sh criteria` refuses a check typed into a plan; each `command` criterion needs a committed script, and the gate calls it with no arguments.
- doc-lint skips `skill` files, so skill length and wording are checked only by `tests/unit/agent-skills.bats` and by hand.
- `/v-pm` hands a planning lens to its critic verbatim; a pack overlay never reaches a planning lens.

## Behaviors & rules

- Product makes an LLM call at runtime for its users → `planning/agent-systems` takes a trigger seat before `planning/harness-engineer`.
- A planning lens other than agent-systems names `trifecta` or `TPR` → `tests/unit/planning-personas.bats` fails; edge: `harness-engineer` may keep the three-part check for harness agents.
- An agent-systems checklist item lacks one `skill: skills/agent-<name>/SKILL.md · <url>` line → `tests/unit/agent-skills.bats` fails.
- A check-field line no deeper than its `- id:` line → `checks/agent-systems-lens-C3.sh` does not count it as evidence.

## Next

- Bump `.claude-plugin/plugin.json` and release; until then sessions read the 1.13.0 cache and see neither the lens nor the skills.
- Push `feat/agent-systems-lens` and open a PR to `main`.
- Run `/v-team` in `~/workspace/recycling-api` on the support drafter, starting from the 12 findings in the c3-run file.

## Refs

- `vault/plans/2026-10-20-1934-agent-systems-lens.md` — the executed plan.
- `vault/plans/2026-10-20-1934-agent-systems-lens.trail.md` — review findings and dispositions.
- `vault/research/v-pm-planning-lenses/agent-systems-quality.md` — the judge and learning evidence.
