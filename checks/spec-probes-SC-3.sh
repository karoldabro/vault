#!/usr/bin/env bash
# SC-3 of vault/plans/2026-09-22-1023-spec-reading-probes.md — sql-schema.sh --check spec-naming.
# Exit 0 met, 1 not met, 2 cannot say yet.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/probes/sql-schema.sh"
[ -x "$probe" ] || { echo "probes/sql-schema.sh not written yet — cannot say"; exit 2; }
grep -q 'spec-naming' "$probe" || { echo "--check spec-naming not written yet — cannot say"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }

repo="$tmp/repo"; mkdir -p "$repo/probes"
printf '# banned\tpreferred\nclient\tcustomer\n' > "$repo/probes/glossary.tsv"

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
| Client_Orders | id | uuid | no | PK | pk_client_orders | |
| Client_Orders | total | int | no | | - | |
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
| customer_orders | id | uuid | no | PK | pk_customer_orders | |
| customer_orders | total | int | no | | - | |
SPEC

out=$("$probe" --check spec-naming --repo "$repo" --spec "$tmp/bad.arch.md" 2>"$tmp/err"); rc=$?
[ "$rc" -eq 1 ] || fail "bad spec: expected exit 1, got $rc: $(cat "$tmp/err")"
printf '%s\n' "$out" | grep -q 'naming-snake-case' || fail "no naming-snake-case row: $out"
printf '%s\n' "$out" | grep -q 'naming-glossary' || fail "no naming-glossary row: $out"
printf '%s\n' "$out" | awk -F'\t' '{print $1}' | sort -u | grep -qx spec-naming || fail "rows are not tagged probe=spec-naming: $out"

out=$("$probe" --check spec-naming --repo "$repo" --spec "$tmp/clean.arch.md" 2>"$tmp/err"); rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] || fail "clean spec: expected exit 0 and no rows, got $rc: $out"
exit 0
