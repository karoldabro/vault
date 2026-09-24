#!/usr/bin/env bash
# Shared by checks/human-page-SC-*.sh: writes a plan, a code-profile spec and a repo into $1.
# Sourced; defines hp_stage <dir> <data-flow label>.
hp_stage() {
    local d=$1 label=${2:-OrderService.place}
    mkdir -p "$d/plans" "$d/repo"
    printf 'dod_profile: code\narch_profile: code\n' > "$d/repo/VAULT.md"
    cat > "$d/plans/plan.md" <<'PLAN'
---
type: plan
project: fixture
slug: chk
arch_spec: s.arch.md
human_plan: file:plan.human.html
---

# chk — plan

## Task
Build the thing for the fixture.
Keywords: secretkw, otherkw.

## Open & deferred

| # | item | status |
|---|------|--------|
| O1 | row-open-xyz | open |
| O2 | row-accepted-xyz | accepted |
| O3 | row-uservis-xyz | User-Visible |
| O4 | row-needs-xyz | needs the operator |
| O5 | row-blockop-xyz | blocked — needs the operator |

- blocked: bullet-blocked-xyz
- deferred: bullet-deferred-xyz
- **needs the operator:** bullet-boldop-xyz
- deferred to the operator: bullet-deferop-xyz
- user visible: bullet-uservis-xyz
- open: bullet-multi-xyz
  cont-open-xyz

prose-open-xyz

## Open questions

| id | question | blocks | searched | status | answer |
|----|----------|--------|----------|--------|--------|
| Q-1 | q-defaulted-xyz | no | vault | defaulted | a-defaulted-xyz |
| Q-2 | q-answered-xyz | yes | vault | answered | a-answered-xyz |

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | crit-command-xyz | functional | command | `checks/x.sh` | exit 0 | | |
| SC-2 | crit-observed-xyz | delivery | observed | look at it | ok | MET | evidence-xyz |

## Decisions

| decision | reason | record |
|----------|--------|--------|
| dec-xyz | reason-xyz | local |
PLAN
    cat > "$d/plans/s.arch.md" <<SPEC
---
type: arch-spec
profile: code
plan: chk
tags: [arch-spec]
---

# chk — architecture spec

## Data model

| table | column | type | null | key | index | references |
|-------|--------|------|------|-----|-------|------------|
| orders | id | uuid | no | PK | pk_orders | |
| order_lines | id | uuid | no | PK | pk_order_lines | |
| order_lines | order_id | uuid | no | FK | ix_order_lines_order_id | orders.id |

## Data flow

\`\`\`mermaid
flowchart LR
    A["OrderController"] -->|"request"| B["$label"]
    B --> P["PROPOSE step (a)"]
\`\`\`

## Interfaces

| interface | method | params | returns | throws | layer |
|-----------|--------|--------|---------|--------|-------|
| OrderService | place | orderId: string, qty: int | Order | OutOfStock | service |
| OrderRepository | save | order: Order | void | - | data |

## Layers & placement

| logic | layer | file |
|-------|-------|------|
| layer-xyz | service | app/Services/OrderService.php |

## Reuse map

| need | existing symbol | decision | reason |
|------|-----------------|----------|--------|
| reuse-xyz | - | new | searched app/ for it; none exists |

## Size budgets

| path | max lines | max method lines |
|------|-----------|------------------|
| app/Services/OrderService.php | 200 | 30 |

## Pipeline

\`\`\`mermaid
flowchart TD
    X["pipeline-xyz"] --> Y["end-xyz"]
\`\`\`
SPEC
}
