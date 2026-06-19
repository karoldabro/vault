---
type: decision
project: vault
id: ADR-007
status: accepted
scope: repo
tags: [adr, commands, lifecycle]
---

# ADR-007 — Light command siblings drop the approval gate for a scope guardrail

## Context
`/v-work` and `/v-team` are heavy: a 6-step gated lifecycle (analyze → load → propose → **approval**
→ execute → commit + capture), steps loaded on demand. The approval gate exists to make the user
sign off before changes land. But it's overkill for two common needs: (a) just *answering* a
grounded question from vault context, and (b) a *small, low-risk* change where the propose/approve
ceremony costs more than the work. Forcing both through the gated lifecycle wastes tokens and the
user's attention.

## Decision
Ship two single-file light siblings — `/v-ask` (read-only Q&A) and `/v-do` (small change) — with
**no approval gate**. For `/v-do`, a **scope guardrail replaces the gate**: before editing, escalate
when the work touches architecture/schema/auth/billing/a cross-repo contract (→ `/v-team`), spans
more than ~5 files or has unclear blast radius (→ `/v-work`), or is destructive (→ stop for explicit
consent). `/v-ask` carries no gate because it is hard read-only (no `Edit`/`Write`/`Morph`/`git`/
capture). The four commands form one escalation ladder: `/v-ask` → `/v-do` → `/v-work` → `/v-team`.

## Consequences
- Cheaper, faster path for the majority of small jobs and questions; the gated lifecycle is reserved
  for work that genuinely warrants sign-off.
- The guardrail moves the safety judgment *earlier* (before the edit) and makes "is this small?" an
  explicit check — "unsure it's small → it isn't, escalate."
- Risk: a user could push a not-actually-small change through `/v-do` by ignoring the guardrail. The
  guardrail is a documented self-check, not an enforced gate — the trade-off accepted for speed.
- Light = single-file (whole body loads at once), deliberately unlike `/v-work`·`/v-team`'s on-demand
  step files. Keeps the light commands genuinely light.
- Watch: whether the ~5-file / domain threshold is the right escalation line in practice.

## Cross-repo impact
None — framework-internal command additions.
