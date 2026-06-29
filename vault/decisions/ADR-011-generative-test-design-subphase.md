---
type: decision
project: vault
id: ADR-011
status: accepted
scope: repo
tags: [adr, v-team, testing, lifecycle]
---

# ADR-011 — Test design is a generative PROPOSE sub-phase; generators emit pre-impl, critics confirm post-impl

## Context
`/v-team`'s test design was a sub-bullet of the design step (`v-work 03 §3a.5`) plus scattered
`PROPOSED_TESTS` from design critics. LLM-authored tests skew to the happy path and skip variant/type
business logic (e.g. a "create post" endpoint where `post.type` changes required params + logic). The
existing `personas/_shared/testing/` group is six **critics** that review *already-written* tests — there
was no generative counterpart that designs the test space up front. A first draft proposed a new 7th
lifecycle step with generators that confirmed their own output; the critic panel rejected it: a 7th step
forced a renumber + dead hook phases, and confirming generated tests inside the PROPOSE panel is
temporally impossible (the confirmer votes before the dossier exists).

## Decision
Make test design a **generative sub-phase of PROPOSE** — section `(f2)` in `03-propose-loop.md`, after the
design panel converges. It fans out a new **generator** group (`personas/_shared/testing/design/`:
fault-relation-prospector, business-logic-cartographer, boundary-property-explorer) that authors a Test
Design Dossier and is the **sole authoritative writer** of the Proposed test backlog. Enforce a strict
**generate→confirm seam**: generators ground in the design plan, bind no analyzer, emit `advisory`, and
never seat on the critique panel; **all confirmation happens post-implementation in EXECUTE §5.3**, where a
new `system-domain-expert` critic (grounded in the repo's own `indications/`+`features/`) plus
`edge-case-hunter` (coverage) and `assertion-auditor` (mutation/strength) confirm the dossier against real
code. Scope: `/v-team` only; `/v-work` gets the techniques as a vocabulary checklist.

## Consequences
- Test design becomes first-class and adversarial/business-logic-aware without duplicating the critic
  lenses — generation and critique are decorrelated by phase (pre-impl vs post-impl).
- No lifecycle renumber, no new hook phases; PROPOSE owns one backlog.
- Generated fault/metamorphic cases can be vapor pre-impl (mitigated: spec-stable decision tables survive
  the diff; mutant-killing deferred to EXECUTE; `(f2)` triage keeps a 1:5–1:20 ratio). Watch the keep-rate.
- The system-domain-expert's "untested rule" finding is only `confirmed` when branch coverage backs it;
  keyword-grep absence is advisory.
- `(f2)` fails open (default-ON for business-logic diffs) so the happy-path bias it counters cannot gate
  its own activation.

## Cross-repo impact
None — framework-internal. Per-project knobs: `team_max_test_designers` (default 3) in `VAULT.md`.
