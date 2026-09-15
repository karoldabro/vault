---
type: trail
project: vault
plan: vpm-business-knowledge-center
tags: [trail, record]
---

# vpm-business-knowledge-center — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`vault/plans/2026-07-03-1510-vpm-business-knowledge-center.md`, which carries the current truth only.

## Panel configuration

| field | value |
|---|---|
| personas | `degraded-general-panel` — no stack pack resolves for a markdown/process framework repo |
| rounds | 2, then one diff-review round on the implemented diff |
| convergence | capped at round 2 — the run hit the `team_max_rounds` ceiling; every round-2 finding applied; 0 open blockers |

The single-repo extension (steps S1–S7) arrived after the cap, on user direction, so no critic saw it
in PROPOSE. EXECUTE self-review and the diff-review round covered it instead.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Spec lives in the neutral `_features/` workspace; each project's own `/v-team` writes the established dossier | v-pm writing a business-rule stub into every participant vault, plus an `_feature-index.md` append | The stub collides with the existing `<proj>/features/<feature>` symlink and dirties a committed sibling repo |
| One canonical test shape, `precondition → expected` | Given/When/Then carried alongside it | Two isomorphic shapes; the Given/When/Then half had no consumer |
| `requirements.md` owns the "why"; `generic-plan.md` back-references it | Both documents carrying `## Problem & outcome` | One statement with two homes drifts |
| Knowledge center runs for 1+ repos; the coordination workspace stays gated at 2+ | Deferring single-repo support to a later plan | User direction: single vault repos exist and are strong, e.g. `~/vault/givore` |
| The `REQ-NN` → dossier carry is defined once in `/v-capture` Step 4d | `commands/v-team/steps/04-execute-loop.md` owning the carry | Single-repo work runs through `/v-work`, so the id chain would never close there |

## Findings & dispositions

One table, one row per finding. `round` is 1, 2, or `diff` for the review of the implemented diff.

| round | persona | id | severity | grounding | issue | disposition |
|---|---|----|----------|-----------|-------|-------------|
| 1 | Skeptic | skep-1 | BLOCKER | confirmed | participant stub collides with existing symlink | **applied** — dropped participant-vault write; reach via workspace symlink + shard |
| 1 | Architect | arch-1/2/4 | MAJOR | confirmed | cross-repo tracked/uncommitted write = footgun the symlink avoids | **applied** — same redesign (step 4b) |
| 1 | Skeptic | skep-2/5 | MAJOR/MINOR | confirmed | uncommitted stub dirties committed sibling repo; §9 sweep doesn't cover | **applied** — no cross-repo write |
| 1 | Requirements | req-1 | MAJOR | confirmed | two isomorphic test shapes (G/W/T + P→E); G/W/T inert | **applied** — unify on canonical P→E; stories ref rule ids (step 1) |
| 1 | Requirements | req-2 | MAJOR | confirmed | id traceability has no consumer (cartographer reads project vault, not requirements.md) | **applied** — step 6 routes requirements.md into the f2 digest and carries the id to the backlog; round 2 then corrected which file does it |
| 1 | Requirements | req-3 | MAJOR | confirmed | missing decision-table/state-transition the cartographer consumes | **applied** — `## Variant & state rules` (step 1) |
| 1 | Architect/Req | arch-3/req-4 | MAJOR | confirmed | `Business context` dup of generic-plan `Problem & outcome` | **applied** — requirements = single source of why; generic-plan back-refs (steps 2,3) |
| 1 | Skeptic | skep-4 | BLOCKER | confirmed | riskiest fork proceeded-on by default | **disposed** — risky action removed (no cross-repo write); residual reach is neutral-only + low-risk; still surfaced at approval gate |
| 1 | Requirements | req-5 | MINOR | advisory | authz/error/nfr rules have no home | **applied** — axis tags on `## Business rules` (step 1) |
| 1 | Skeptic | skep-6/7 | MINOR | advisory | earns-its-keep / triple-duplication | **applied (partial)** — single-source-by-id + omit-when-none; single-repo deferred at this point, and the user reversed that deferral at the approval gate |
| 1 | Architect | arch-5 | MINOR | confirmed | spec-derived marker convention | **resolved by redesign** — no spec rules written to project dossier; /v-team writes established+id only |
| 1 | Architect | arch-6 | NIT | confirmed | template count test goes stale | **applied** — update bats to seven templates |
| 2 | Skeptic / Architect | skep-8 / arch-7 | MAJOR | confirmed | v-pm enriching `projects/<proj>/plan.md` clashes with shard single-writer (/v-team) ownership → clobber risk | **applied** — step 3b: dedicated v-pm-owned `## Business rules to satisfy` section + ownership carve-out + merge-not-overwrite |
| 2 | Architect / Requirements | arch-9 / req-6 | MAJOR | confirmed | id-traceability seam wired into wrong file (00-feature-pickup is pre-ANALYZE; f2 digest assembled later) → seam may never fire | **applied** — step 6 split across 00-feature-pickup (read) + 03-propose-loop (digest+backlog source) + the capture-time carry |
| 2 | Requirements | req-6 (part) | MAJOR | confirmed | step-5 record omits variant/state tables (cartographer's primary food) | **applied** — step 5 pushes variant/state tables too |
| 2 | Architect | arch-8 | NIT | confirmed | 03-plan-panel §(a) prose still says generic-plan owns problem/outcome | **applied** — step 2 rewrites §(a) line 12 |
| 2 | Requirements | req-7 | NIT | advisory | unifying on `precondition → expected` folds the BDD "When" trigger implicit | **applied (cheap)** — step 1: add one template example rule with an explicit action-trigger (`; edge: when X then Y`) |
| diff | Skeptic | skep-9 | MAJOR | confirmed | single-repo promised the id chain closes via `/v-work` too, but the `REQ-NN`→dossier carry lived only in v-team's execute-loop | **applied** — moved the canonical carry to shared `/v-capture` Step 4d (fires for both lifecycles); v-team §5.4a defers to it; intake §1.3.4 points to it. Test 8 locks it. |
| diff | Skeptic | skep-10 | MINOR | confirmed | §1.4 slug-collision only checked `_features/`, not single-repo `requirements/` | **applied** — §1.4 branches the check by mode |
| diff | Skeptic | skep-11 | MINOR | confirmed | `requirements/_index.md` had no §3 maintenance contract → rot | **applied** — §3 row + `_moc` trigger |
| diff | Skeptic | skep-12 | NIT | confirmed | §1.3 step-number parentheticals conflicted with file titles | **applied** — reference by filename |
| diff | Architect | arch-11 | NIT | confirmed | 05-capture Required-output/closing was multi-repo-only (would report a `_features/` commit single-repo never made) | **applied** — branched output block for single-repo |
| diff | Architect | arch-10 | NIT | confirmed | §6 said "trio" but now lists four categories | **applied** — "four categories" |

Round 2 re-spawned all three critics against the real files and verified every round-1 finding
resolved with no regression. The diff-review round resumed the architect and skeptic on the
implemented diff, focused on cross-file seam coherence and the post-cap single-repo extension.
Architect verdict APPROVE_WITH_NITS; skeptic REQUEST_CHANGES, then every change applied.

## Metrics

| round | findings | confirmed | advisory | overlap across critics | regressions |
|---|---|---|---|---|---|
| 1 | 15 (2 blockers + 4 major clusters + minors) | 11 | 4 | 3/3 on the cross-repo-write cluster | — |
| 2 | 4 new (3 MAJOR + 1 NIT) | 3 | 1 | 2/3 on shard-ownership (skep+arch) and on seam-placement (arch+req) | 0 |
| diff | 6 new (1 MAJOR + 5 minor/nit) | 6 | 0 | architect + skeptic only (two-reviewer round) | 0 |

All confirmed blockers and majors were applied or disposed by a design change. The panel does not
loop past the round cap, per §f.

## Advisory test hints

The (f2) generative fan-out was skipped, so the proposed test backlog in the plan was consolidated
from the panel's `PROPOSED_TESTS` and deduped across critics. Those hints are advisory; the plan's
`## Proposed test backlog` is the authoritative list.

## Rejected / deferred

- **v0 draft** — `requirements.md` plus a per-project stub written into each participant vault and an
  `_feature-index` append. Killed by the symlink collision (skep-1) and the cross-repo write
  footgun (arch-1/2/4).
- **Deferring single-repo support.** Live through round 2; the user reversed it at the approval gate.
- **A spec-derived marker convention in the project dossier** (arch-5). The redesign removed the need:
  no spec rule ever reaches the dossier.
- **The (f2) generative test fan-out.** Skipped per the §f2 skip clause. The design generators
  `fault-relation-prospector`, `business-logic-cartographer` and `boundary-property-explorer` target
  runtime decision tables, metamorphic relations and BVA, and a doc-contract grep diff offers none.
