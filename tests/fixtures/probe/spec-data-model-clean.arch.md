---
type: arch-spec
profile: harness
plan: fixture
tags: [arch-spec]
---

# spec-data-model-clean — fixture

A Data model table that breaks no spec-tables/spec-naming rule.

## Data model

| table | column | type | null | key | index | references |
|-------|--------|------|------|-----|-------|------------|
| shipments | id | bigint | no | PK | pk_shipments | |
| shipments | tracking_code | varchar(64) | no | UQ | ux_shipments_tracking | |
| shipments | order_id | bigint | no | FK | ix_shipments_order | orders.id |
