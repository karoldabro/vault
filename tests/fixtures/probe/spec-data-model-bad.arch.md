---
type: arch-spec
profile: harness
plan: fixture
tags: [arch-spec]
---

# spec-data-model-bad — fixture

<!-- One defect of each spec-tables/spec-naming rule, paired against database/schema.sql
     (a copy of tests/fixtures/probe/schema-bad.sql) when the test repo provides one.
     customers.email: column-drift, same table name as real. customer_prefs: dup-column-set
     (4 of 4 with real customers) and column-drift on phone (cross-table name collision).
     Orders: naming-snake-case (table), fk-no-index (shopper_id), naming-glossary (client_note),
     status: an escaped pipe in a type cell. -->

## Data model

| table | column | type | null | key | index | references |
|-------|--------|------|------|-----|-------|------------|
| customers | id | bigint | no | PK | pk_customers | |
| customers | email | text | no | | ix_customers_email | |
| customer_prefs | id | bigint | no | PK | pk_customer_prefs | |
| customer_prefs | email | varchar(255) | no | | - | |
| customer_prefs | full_name | varchar(120) | no | | - | |
| customer_prefs | phone | int | yes | | - | |
| customer_prefs | country_code | char(2) | yes | | - | |
| Orders | id | bigint | no | PK | pk_orders | |
| Orders | shopper_id | bigint | no | FK | - | shoppers.id |
| Orders | status | enum('a'\|'b') | yes | | - | |
| Orders | client_note | text | yes | | - | |
