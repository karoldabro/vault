---
type: project-shard
feature: {{feature}}
project: {{project}}
status: todo   # todo | in-progress | done
---

# {{feature}} — {{project}} plan

This project's detailed plan. **Self-contained** (BMAD): it carries enough context to act without
re-reading everything. Written by this project's `/v-team <feature>` session, not by `/v-pm` — **except
the `## Business rules to satisfy` section below, which `/v-pm` seeds and `/v-team` must preserve.**

## Business rules to satisfy (from requirements.md — REQ-NN id refs)
<!-- SEEDED BY /v-pm (the one section it owns here). The `requirements.md` business-rule ids this project
     is responsible for satisfying — id refs only, never copied rule text (requirements.md is the source).
     /v-team APPENDS established evidence (which test/dossier covers each) and PRESERVES the ids — it does
     NOT overwrite this section. Keep these ids OUT of `## Consumed contract` so the Step-0 drift check
     still diffs cleanly. -->
- REQ-NN <!-- , REQ-NN … seeded by /v-pm; /v-team annotates coverage, never removes -->

## What this project does for the feature
<!-- This repo's slice of the generic plan. -->

## Consumed contract
<!-- The exact endpoints / enums / shapes from ../../contracts.md this project depends on. The Step 0
     drift check compares THIS against contracts.md — keep it field-accurate. -->

## Constraints & rationale

## Tests to guard the behavior

## Up-links
<!-- → ../../generic-plan.md · → ../../contracts.md · related threads in ../../conversation/. -->
