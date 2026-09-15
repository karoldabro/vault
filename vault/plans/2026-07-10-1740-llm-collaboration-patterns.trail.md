---
type: trail
project: vault
plan: llm-collaboration-patterns
personas: [framework-fallback: conventions-architect, skeptic, quality]
rounds: 2
convergence: capped
tags: [trail, record]
---

# llm-collaboration-patterns — process record

Record class, so chronology belongs here and nowhere else. Its contract document is
`vault/plans/2026-07-10-1740-llm-collaboration-patterns.md`, which carries the current truth only.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| pre-mortem adopted as a skeptic TECHNIQUE in `personas/_shared/skeptic.md` | a seated `personas/_shared/premortem.md` critic | correlated double-vote with skeptic (same jurisdiction, same trigger); as a 4th critic over cap-3 it evicts a decorrelated domain lens |
| verifier asymmetry folded into `vault/indications/confirmed-vs-advisory-findings.md` | a new indication `evidence-based-panel-design` | a third home for rules already owned by the template and the grounding rule |
| `optional: [research]` in `VAULT.md` | `add_folders: [research]` | research/ is a standard optional folder per vault-guide §2, so `add_folders` miscategorises it |
| undated catalog filename `vault/research/llm-collaboration-patterns.md` | a dated `2026-07-10-…` filename | a dated name matches neither convention for a living reference |
| one catalog file | a per-domain split into six files | single research effort; split only if it outgrows usefulness, no pre-split |
| short token-grep assertions in `tests/unit/v-team.bats` | full-sentence phrase assertions | full sentences are brittle; the file's own precedent asserts short structural tokens |
| minority flag keys on critic-assigned `grounding` | synthesizer-assigned `grounding` | a synthesizer re-grade from confirmed to advisory would end the obligation |
| catalog adopted at technique level only | seat-level pre-mortem adoption now | the quantified benefit is Klein's human-team evidence, with no LLM-context citation yet |

## Findings & dispositions

| round | persona | id | severity | grounding | issue | disposition |
|---|---------|----|----------|-----------|-------|-------------|
| 1 | skeptic | skeptic-1 | MAJOR | confirmed | premortem = correlated double-vote with skeptic (same jurisdiction, same trigger) | **applied** — seat dropped; technique folded into skeptic.md (step 7) |
| 1 | skeptic | skeptic-2 | MAJOR | confirmed | premortem as 4th critic over cap-3 evicts a decorrelated domain lens | **applied** — moot with seat dropped; substitute-seat variant recorded in Tier 2 |
| 1 | skeptic | skeptic-3 | MAJOR | advisory | strongest-cost adoption rests on non-LLM evidence (Klein human-team ~30%) | **applied** — technique-level only; caveat recorded in ADR-017 + Open trade-offs |
| 1 | skeptic | skeptic-4 | MINOR | confirmed | method-enforcer note duplicates template opener | **applied** — folded into existing paragraph (step 5) |
| 1 | skeptic | skeptic-5 | MINOR | confirmed | flip-tracking = metric with no consumer | **applied** — merged into §(e) item-6 metrics + minority-flag gate surface (step 8) |
| 1 | skeptic | skeptic-6 | MINOR | confirmed | dissent-preservation ~80% existing; real gap = downgraded confirmed blocker | **applied** — reduced to one clause scoped to downgrade/reject case (step 8) |
| 1 | skeptic | skeptic-7 | MINOR | confirmed | ~4 of 10 Tier-1 files exist only to wire the contested seat | **applied** — Tier 1 shrunk 10→6 framework surfaces |
| 1 | quality | quality-1 | MAJOR | confirmed | new indication = third home for rules owned elsewhere | **applied** — indication dropped; asymmetry folds into confirmed-vs-advisory-findings (step 6) |
| 1 | quality | quality-2 | MINOR | confirmed | method-enforcer restates template opener | **applied** — same as skeptic-4 |
| 1 | quality | quality-3 | MINOR | confirmed | verifier-asymmetry note duplicates grounding rule; keep only asymmetry sentence | **applied** (step 5) |
| 1 | quality | quality-4 | MINOR | confirmed | dissent subsection duplicates §(e) 3/4/6 | **applied** — one clause only (step 8) |
| 1 | quality | quality-5 | MINOR | confirmed | flip-tracking is one metrics-list entry, not a mechanism | **applied** (step 8) |
| 1 | quality | quality-6 | MINOR | confirmed | premortem tests belong with shared siblings in v-team.bats, not business-personas.bats | **applied** — moot for premortem (dropped); step 9 targets v-team.bats |
| 1 | quality | quality-7 | NIT | confirmed | dated filename matches neither convention for a living reference | **applied** — undated filename (step 3) |
| 1 | quality | quality-8 | NIT | advisory | one-file catalog OK (single-responsibility); split only if it outgrows | **recorded** — plan's Open trade-offs |
| 1 | arch | arch-1 | MAJOR | confirmed | research/ is a standard optional folder; `add_folders` miscategorizes it | **applied** — `optional: [research]` (step 1) |
| 1 | arch | arch-2 | MAJOR | confirmed | premortem is a MODE per the research's own persona×mode framing; fold into skeptic | **applied** — same cluster as skeptic-1 (step 7) |
| 1 | arch | arch-3 | MAJOR | confirmed | business-personas.bats tests the wrong shape for flat _shared critics | **applied** — moot for premortem; step 9 uses v-team.bats precedent |
| 1 | arch | arch-4 | MINOR | confirmed | README names no flat critic individually; premortem line would create asymmetry | **applied** — README edit dropped |
| 1 | arch | arch-5 | MINOR | advisory | catalog is a loose fit for research/ as documented | **applied** — vault-guide description broadened (step 2) |
| 1 | arch | arch-6 | MINOR | confirmed | indication restates existing mechanisms; scope to the novel rule | **applied** — via quality-1 disposition; novel rule lives in ADR-017 |
| 1 | arch | arch-7 | NIT | confirmed | flip-tracking belongs in §(e) metrics, not §(f) | **applied** (step 8) |
| 1 | arch | arch-8 | MINOR | confirmed | verifier-asymmetry should live with the grounding rule (indication), not template-only | **applied** (step 6) |
| 2 | arch | arch-9 | MAJOR | confirmed | ADR-017 unregistered in decisions/_inventory.md; ADR-016 row already missing (drift proven by grep) | **applied** — step 4b: append ADR-017 row + backfill ADR-016 |
| 2 | arch | arch-10 | NIT | advisory | full-sentence phrase assertions are brittle | **applied** — step 9 token-grep style |
| 2 | skeptic | skeptic-8 | MINOR | confirmed | minority-flag escapable via synthesizer grounding re-grade (confirmed→advisory ends the obligation) | **applied** — step 8(b): grounding is critic-owned, no downward re-grade; flag keys on critic-assigned grounding |
| 2 | skeptic | skeptic-9 | NIT | confirmed | v-team.bats precedent asserts short structural tokens, not prose sentences | **applied** — step 9 (same cluster as arch-10) |
| 2 | skeptic | skeptic-10 | NIT | advisory | Tier-2 substitute seat would double-home the technique | **applied** — supersede note added to Tier 2 item |
| 2 | quality | quality-9 | NIT | confirmed | verifier-asymmetry in template+indication+ADR mirrors existing grounding-rule factoring — NOT a duplication regression | **no change needed** — wording-corollary note added to step 6 |
| 2 | quality | quality-10 | MINOR | advisory | ADR-017 six-peer-decisions shape looser than ADR-016 precedent | **applied** — step 4: (a)–(c) Decision, rest Consequences/Alternatives |
| diff | quality | quality-11 | NIT | advisory | catalog 527 lines, ~8% over soft split threshold | **recorded** — keep one file per standing disposition |
| diff | arch | arch-11 | NIT | confirmed | bare `[[ADR-017]]` wikilink in plan artifact doesn't resolve | **fixed** — full slug |
| diff | arch | arch-12 | NIT | confirmed | ADR-017 omits `scope:` vs template/majority (matches ADR-016 precedent) | **recorded** — repo-wide template↔practice drift, separate cleanup; carried in the plan's deferrals |
| diff | arch | arch-13 | NIT | advisory | catalog + ADR-017 not yet in _moc | **fixed at capture** — both rows now in `vault/_moc.md` |
| diff | skeptic | skeptic-11 | MINOR | confirmed | C-06 "90%×90% ≈ 99%" arithmetic self-inconsistent (reads as 81%) | **fixed** — error-complement form (1 − 0.1×0.1) in catalog + plan digest |
| diff | skeptic | skeptic-12 | MINOR | confirmed | every-ADR-registered test was unplanned EXECUTE scope; empty-id vacuous-pass hole | **fixed** — empty-id guard added; invariant recorded in ADR-017 Consequences |

Round 2 verdicts: quality APPROVE_WITH_NITS · skeptic APPROVE_WITH_NITS · conventions-architect
REQUEST_CHANGES. All 21 Round 1 dispositions independently verified applied by their raising critics.

**Convergence: capped** — the round cap (2) was hit. Round 2 raised one new confirmed MAJOR (arch-9),
so the no-new-blocking-findings stop was not met. That finding is dispositioned **applied**, leaving
**0 open blockers** at the approval gate.

Diff-review verdicts: quality **APPROVE** · conventions-architect **APPROVE_WITH_NITS** · skeptic
**APPROVE_WITH_NITS**. Analyzers first: full suite 229/229 green, with 3 new guards red on the
pre-change tree, so fault detection was proven. Stop: no new confirmed BLOCKER/MAJOR.

## Metrics

| round | new confirmed blockers | findings | persona overlap | previously-confirmed dropped this round (sycophancy flag) |
|---|---|---|---|---|
| 1 | 0 BLOCKER / 6 confirmed MAJOR | 23 (16 confirmed, 4 advisory, 3 NIT-confirmed) | 3 clusters: premortem-seat ×3 personas, §(e)-dedupe ×5 findings, template-dedupe ×3 findings | n/a (round 1) |
| 2 | 0 BLOCKER / 1 confirmed MAJOR (arch-9) | findings-delta 23→7 | 1 cluster: assertion-brittleness ×2 | 0 — all Round 1 confirmed findings remain applied |
| diff | 0 | 6 (4 confirmed MINOR/NIT, 2 advisory NIT) | none | 0; post-fix suite 229/229 green |

## Advisory test hints

| id | hint | outcome |
|---|---|---|
| skeptic-t1 | mutual-exclusion guard between premortem and skeptic seats | moot — premortem seat dropped entirely |
| skeptic-t2 | skeptic-side assertions for the premortem seat | superseded by step 9 (`tests/unit/v-team.bats` assertions) |
| quality-t1 | premortem persona-contract assertion | moot — no new persona |
| quality-t2 | new-indication index assertion | moot — no new indication |
| arch tests | premortem README + registration assertions | superseded by step 9 |

## Rejected / deferred

The Round 0 draft proposed the catalog under `add_folders: [research]` with a dated filename; a new
`_shared/premortem.md` persona seated alongside skeptic on high-stakes work, with its
`_resolution.md`, README and bats registration; a new indication `evidence-based-panel-design`;
method-enforcer and verifier-asymmetry notes in the persona template; and a dissent-preservation
subsection plus flip-tracking in §(e) and §(f) of `commands/v-team/steps/03-propose-loop.md`.

Every one of those was dropped. The premortem seat and its four wiring files fell to the
correlated-double-vote finding. The new indication fell because it was a third home for rules the
template and the grounding rule already own. The `add_folders` declaration and the dated research
filename were both miscategorisations. Flip-tracking survives only as one entry in the §(e) item-6
metrics list.

Deferred to Tier 2 and Tier 3 backlogs in the plan, not re-evaluated here: premortem as a SUBSTITUTE
seat, war-game and PR/FAQ modes, confidence-gated auto-accept, replay corpora, and the
architect/editor model split.
