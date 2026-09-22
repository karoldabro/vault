---
type: arch-spec
profile: harness
plan: fixture
tags: [arch-spec]
---

# spec-no-data-model — fixture

Proves spec-tables/spec-naming print nothing when the spec contributes no facts, even when a real
schema present in the same repo (e.g. tests/fixtures/probe/schema-bad.sql) already trips
sql-dup-columns/sql-fk-index/sql-naming on its own.

## Data model

n/a: this change touches no table
