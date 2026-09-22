#!/usr/bin/env bash
# SC-2 of vault/plans/2026-09-22-1023-spec-reading-probes.md — sql-schema.sh --check spec-tables.
# Exit 0 met, 1 not met, 2 cannot say yet.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/probes/sql-schema.sh"
[ -x "$probe" ] || { echo "probes/sql-schema.sh not written yet — cannot say"; exit 2; }
grep -q 'spec-tables' "$probe" || { echo "--check spec-tables not written yet — cannot say"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }

repo="$tmp/repo"; mkdir -p "$repo/database"
cat > "$repo/database/schema.sql" <<'SQL'
CREATE TABLE customers (
  id BIGINT NOT NULL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  phone VARCHAR(40) NULL,
  country_code CHAR(2) NULL,
  created_at TIMESTAMP NULL
);
SQL

# a bad spec: a table that duplicates customers' column set, a drifted email type, an unindexed FK
cat > "$tmp/bad.arch.md" <<'SPEC'
---
type: arch-spec
profile: code
plan: fixture
tags: [arch-spec]
---
# fixture

## Data model

| table | column | type | null | key | index | references |
|-------|--------|------|------|-----|-------|------------|
| customers | id | bigint | no | PK | pk_customers | |
| customers | email | text | no | | ix_customers_email | |
| customers | full_name | varchar(120) | no | | - | |
| customers | phone | varchar(40) | yes | | - | |
| customers | country_code | char(2) | yes | | - | |
| customers | created_at | timestamp | yes | | - | |
| customers_archive | id | bigint | no | PK | pk_customers_archive | |
| customers_archive | email | varchar(255) | no | | - | |
| customers_archive | full_name | varchar(120) | no | | - | |
| customers_archive | phone | varchar(40) | yes | | - | |
| customers_archive | country_code | char(2) | yes | | - | |
| customers_archive | created_at | timestamp | yes | | - | |
| orders | id | bigint | no | PK | pk_orders | |
| orders | customer_id | bigint | no | FK | - | customers.id |
SPEC

cat > "$tmp/clean.arch.md" <<'SPEC'
---
type: arch-spec
profile: code
plan: fixture
tags: [arch-spec]
---
# fixture

## Data model

| table | column | type | null | key | index | references |
|-------|--------|------|------|-----|-------|------------|
| widgets | id | uuid | no | PK | pk_widgets | |
| widgets | name | text | no | | ix_widgets_name | |
SPEC

out=$("$probe" --check spec-tables --repo "$repo" --spec "$tmp/bad.arch.md" 2>"$tmp/err"); rc=$?
[ "$rc" -eq 1 ] || fail "bad spec: expected exit 1, got $rc: $(cat "$tmp/err")"
printf '%s\n' "$out" | grep -q 'dup-column-set' || fail "no dup-column-set row: $out"
printf '%s\n' "$out" | grep -q 'column-drift' || fail "no column-drift row: $out"
printf '%s\n' "$out" | grep -q 'fk-no-index' || fail "no fk-no-index row: $out"
printf '%s\n' "$out" | awk -F'\t' '{print $1}' | sort -u | grep -qx spec-tables || fail "rows are not tagged probe=spec-tables: $out"

out=$("$probe" --check spec-tables --repo "$repo" --spec "$tmp/clean.arch.md" 2>"$tmp/err"); rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] || fail "clean spec: expected exit 0 and no rows, got $rc: $out"

out=$("$probe" --check spec-tables --repo "$repo" 2>"$tmp/err"); rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] || fail "no --spec: expected exit 0 and no rows, got $rc: $out"
exit 0
