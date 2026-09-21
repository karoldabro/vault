#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/bin/probe.sh"; fx="$root/tests/fixtures/probe"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
for f in "$probe" "$root/probes/sql-schema.sh" "$fx/schema-bad.sql" "$fx/schema-clean.sql"; do
  [ -e "$f" ] || { echo "${f#$root/} not written yet — cannot say"; exit 2; }
done
fail() { printf '%s\n' "$*"; exit 1; }
repo="$tmp/bad"; mkdir -p "$repo/database"; cp "$fx/schema-bad.sql" "$repo/database/schema.sql"
out=""
for id in sql-dup-columns sql-fk-index sql-naming; do
  o=$("$probe" run plan --repo "$repo" --only "$id" 2>"$tmp/err"); rc=$?
  [ "$rc" -eq 1 ] || fail "$id on the bad schema: expected exit 1, got $rc: $(cat "$tmp/err")"
  out="$out$o"$'\n'
done
# each defect line of the fixture ends with `-- expect: <rule>`; the probe must name that rule at that line
n=0
while IFS= read -r m; do
  ln=${m%%:*}; rule=$(printf '%s' "$m" | sed 's/.*-- expect: *//; s/ *$//')
  n=$((n + 1))
  printf '%s\n' "$out" | awk -F'\t' -v r="$rule" -v l="$ln" '$5 == r && $2 == "database/schema.sql" && $3 == l { f = 1 } END { exit !f }' \
    || fail "no $rule row at database/schema.sql line $ln. Rows: $(printf '%s' "$out" | tr '\n' '|')"
done < <(grep -n -- '-- expect: ' "$fx/schema-bad.sql")
[ "$n" -ge 4 ] || fail "the bad fixture marks $n defects; it needs at least the four rules of SC-5"
for rule in dup-column-set fk-no-index dup-column-in-table naming-snake-case; do
  grep -q -- "-- expect: $rule" "$fx/schema-bad.sql" || fail "the bad fixture has no $rule marker"
done
extra=$(printf '%s\n' "$out" | awk -F'\t' 'NF && $3 !~ /^[0-9]+$/')
[ -z "$extra" ] || fail "rows with a non-numeric line: $extra"
clean="$tmp/clean"; mkdir -p "$clean/database"; cp "$fx/schema-clean.sql" "$clean/database/schema.sql"
for id in sql-dup-columns sql-fk-index sql-naming; do
  o=$("$probe" run plan --repo "$clean" --only "$id" 2>"$tmp/err"); rc=$?
  [ "$rc" -eq 0 ] && [ -z "$o" ] || fail "$id on the clean schema: expected exit 0 and no rows, got $rc: $o $(cat "$tmp/err")"
done
exit 0
