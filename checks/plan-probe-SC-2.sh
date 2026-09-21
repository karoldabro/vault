#!/usr/bin/env bash
# SC-2 of vault/plans/2026-09-21-1800-plan-time-probes.md — the spec-symbols check.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/probes/similar-symbols.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
grep -q 'spec-symbols' "$probe" 2>/dev/null || { echo "check spec-symbols not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
T=$(printf '\t')
repo="$tmp/repo"; mkdir -p "$repo/lib"
printf 'alpha_one() { :; }\nbeta_two() { :; }\n' > "$repo/lib/x.sh"
spec="$tmp/x.arch.md"
cat > "$spec" <<'SPEC'
# x

## Reuse map

| need | existing symbol | decision | reason |
|------|-----------------|----------|--------|
| n1 | lib/x.sh alpha_one | reuse | ok |
| n2 | lib/x.sh alpha_one, beta_two | extend | ok |
| n3 | lib/missing.sh alpha_one | reuse | path absent |
| n4 | lib/x.sh gamma_three | reuse | symbol absent |
| n5 | ../etc/passwd sym | reuse | leaves the repo |
| n6 | - | reuse | dash |
| n7 | alpha_one | reuse | no path |
| n8 | lib/x.sh nothing_here | new | new is skipped |
| n9 | lib/x.sh alpha_on | reuse | prefix is not a whole word |
| n10 | `lib/x.sh` alpha_one, | reuse | backticks and trailing comma |
| n11 | /etc/passwd root | reuse | absolute |
| n12 | lib/gone.sh foo | Reuse | case of the decision |
| n13 | lib | reuse | a directory |
SPEC
run() { "$probe" --check spec-symbols --repo "$repo" --spec "$1" 2>"$tmp/err"; }
line() { grep -n "^| $1 " "$2" | head -1 | cut -d: -f1; }
out=$(run "$spec"); rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1, got $rc: $(head -3 "$tmp/err")"
rows=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
[ "$rows" -eq 6 ] || fail "expected 6 rows (n3 n4 n5 n9 n11 n12), got $rows: $out"
expect() { # expect <need> <rule>
  local l; l=$(line "$1" "$spec")
  printf '%s\n' "$out" | grep -q "^spec-symbols${T}x.arch.md${T}$l${T}error${T}$2${T}" || fail "no $2 row at line $l for $1: $out"
}
expect n3 reuse-path-missing; expect n4 reuse-symbol-missing; expect n5 reuse-path-missing
expect n9 reuse-symbol-missing; expect n11 reuse-path-missing; expect n12 reuse-path-missing
# rows are valid to the core, and a spec in the repo is named by its repo path
cp "$spec" "$repo/in.arch.md"
r2=$("$root/bin/probe.sh" run plan --repo "$repo" --spec "$repo/in.arch.md" --only spec-symbols 2>"$tmp/err"); rc=$?
[ "$rc" -eq 1 ] || fail "core run: expected exit 1, got $rc: $(head -3 "$tmp/err")"
grep -q '^failed:' "$tmp/err" && fail "the core rejected a row: $(cat "$tmp/err")"
printf '%s\n' "$r2" | cut -f2 | sort -u | grep -qx 'in.arch.md' || fail "a spec inside the repo is not named by its repo path: $r2"
# real cells of real specs give no row
real="$tmp/real.arch.md"
cat > "$real" <<'SPEC'
## Reuse map

| need | existing symbol | decision | reason |
|------|-----------------|----------|--------|
| a | bin/probe.sh run plan | reuse | real cell |
| b | lib/cr-sandbox.sh cr_sandbox_root, cr_sandbox_path_is_safe | reuse | real cell |
SPEC
r3=$("$probe" --check spec-symbols --repo "$root" --spec "$real" 2>&1); rc=$?
[ "$rc" -eq 0 ] && [ -z "$r3" ] || fail "real cells gave rows: $r3"
# CRLF copy and a shuffled copy give the same rows
sed 's/$/\r/' "$spec" > "$tmp/crlf.arch.md"
c=$(run "$tmp/crlf.arch.md" | cut -f3-); [ "$c" = "$(printf '%s\n' "$out" | cut -f3-)" ] || fail "CRLF spec gives other rows"
# a spec outside the repo is named by its base name
mkdir -p "$tmp/outside"; cp "$spec" "$tmp/outside/y.arch.md"
o=$(run "$tmp/outside/y.arch.md"); printf '%s\n' "$o" | cut -f2 | sort -u | grep -qx 'y.arch.md' || fail "external spec not named by its base name: $o"
# the row is registered and listed
"$root/bin/probe.sh" list --repo "$root" | grep -q "^spec-symbols${T}plan${T}S${T}framework${T}ok" || fail "bin/probe.sh list does not show spec-symbols as ok"
# no spec: no rows
none=$("$probe" --check spec-symbols --repo "$repo" 2>&1); [ -z "$none" ] || fail "no spec gave rows: $none"
exit 0
