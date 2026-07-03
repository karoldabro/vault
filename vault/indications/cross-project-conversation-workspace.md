---
type: indication
project: vault
slug: cross-project-conversation-workspace
scope: repo
tags: [indication, v-pm, cross-project, coordination, blackboard]
---

# cross-project-conversation-workspace

## Rule
Coordinate multiple project sessions through a **shared file-based conversation workspace**, not a live
channel and not the human. Encode thread **state in the filename** (`OPEN_→<proj>` / `ANSWERED_<who>` /
`RESOLVED`); make any index a **derived view** computed on read (never a written append-log — that races
across parallel sessions). Pickup is **pull** (each session drains threads addressed to it on start), so
always pair it with a **push surface** (a cross-feature `status` sweep) or threads orphan. State the
latency honestly: a reply lands only at the next open of the asking session. Split the cross-project
interface into a **structured** contract so drift is checked **deterministically** (field compare), with
the LLM phrasing rationale only — never deciding whether drift exists.

## Rationale
The failure mode is the human as message bus: context hand-carried between agent sessions, re-explained,
lost in the handoff. A blackboard/file-A2A workspace decouples the sessions and gives a free audit trail,
but has three sharp edges this rule closes: (1) a shared writable ledger races → derive it instead;
(2) pull-only pickup silently orphans work → add a push surface; (3) an LLM prose "consistency" read is
false-confidence → make the high-value check (contract drift) deterministic. Skipping any of the three
brings back the exact problem the workspace was meant to remove.

## Examples
- Do: `THREAD_3_OPEN_→api.md` renamed to `…_ANSWERED_api.md` — `/v-pm status` derives "waiting/answered"
  from the names; no ledger file is written.
- Do: a single-participant feature skips the whole workspace and hands off to `/v-team` (below break-even).
- Don't: append thread state to a shared `ledger.md` that every session writes (multi-writer race).
- Don't: rely on auto-pickup alone — without `/v-pm status`, a thread `→api` sits forever if `api` is
  never reopened.
- Don't: ask an LLM to prose-compare plan files for "drift" as the gate; diff the structured contract.

## Applies-to
`commands/v-pm.md`, `commands/v-pm/steps/**`, `commands/v-team/steps/00-feature-pickup.md`,
`templates/_features/**`, `vault-guide.md` §13.
