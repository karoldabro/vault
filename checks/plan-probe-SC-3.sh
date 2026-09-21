#!/usr/bin/env bash
# SC-3 of vault/plans/2026-09-21-1800-plan-time-probes.md — bin/plan-probes.sh verify.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pp="$root/bin/plan-probes.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$pp" ] || { echo "bin/plan-probes.sh not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
T=$(printf '\t')
C1="spec-symbols${T}docs/x.md${T}12${T}error${T}reuse-symbol-missing${T}symbol foo is missing"
C2="similar-symbols${T}bin/a.sh${T}5${T}warn${T}similar-symbol${T}existing run_thing shares the word run"
A1="probe-x${T}f.md${T}3${T}error${T}r${T}m"
mk() { local d=$1; shift; mkdir -p "$d"; : > "$d/confirmed.tsv"; : > "$d/advisory.tsv"; printf 'full\n' > "$d/tier.txt"; }
out1="$tmp/o1"; mk "$out1"; printf '%s\n%s\n' "$C1" "$C2" > "$out1/confirmed.tsv"; printf '%s\n' "$A1" > "$out1/advisory.tsv"
r=$("$pp" verify "$out1" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] || fail "confirmed error: expected exit 1, got $rc"
printf '%s\n' "$r" | grep -q '^open: spec-symbols docs/x.md:12 ' || fail "no open line: $r"
[ "$(printf '%s\n' "$r" | grep -c '^open: ')" -eq 1 ] || fail "advisory error printed an open line: $r"
out2="$tmp/o2"; mk "$out2"; printf '%s\n' "$C2" > "$out2/confirmed.tsv"; printf '%s\n' "$A1" > "$out2/advisory.tsv"
r=$("$pp" verify "$out2" 2>/dev/null); rc=$?
[ "$rc" -eq 0 ] || fail "warn and advisory error: expected exit 0, got $rc: $r"
printf '%s\n' "$r" | grep -q '^open: ' && fail "an open line for a warn or advisory row"
# auditor lines
rows="$tmp/rows"
{ printf 'does-not-apply%s%s\n' "$T" "$C2"
  printf 'applies%s%s\n' "$T" "${C2/warn/info}"                      # forged severity
  printf 'applies%s%s\n' "$T" "${C2/shares/forged}"                   # forged message
  printf 'applies%s%s\n' "$T" "${C2/${T}5${T}/${T}05${T}}"            # line 05 for 5
  printf 'maybe%s%s\n' "$T" "$C2"                                     # unknown verdict
  printf 'appl%sies%s%s\n' "$T" "$T" "$C2"                            # tab in the verdict
  printf 'applies%s%s\r\n' "$T" "$C2"                                 # CRLF
  printf 'unclear%ssimilar-symbols%sbin/other.sh%s1%swarn%sr%sm\n' "$T" "$T" "$T" "$T" "$T" "$T"   # row not in the block
  printf 'does-not-apply%s%s\n' "$T" "$C2"                            # repeated line
} > "$rows"
r=$("$pp" verify "$out2" "$rows" 2>/dev/null); rc=$?
[ "$rc" -eq 0 ] || fail "auditor lines changed the exit code to $rc"
kept=$(printf '%s\n' "$r" | grep -c "^does-not-apply${T}")
[ "$kept" -eq 1 ] || fail "expected the good line printed once, got $kept: $r"
[ "$(printf '%s\n' "$r" | grep -c "^\(applies\|unclear\|maybe\)")" -eq 0 ] || fail "a forged line was kept: $r"
printf '%s\n' "$r" | grep -q "^does-not-apply${T}$C2\$" || fail "the kept line is not the block's own row"
printf '%s\n' "$r" | grep -q '^note: 7 auditor lines' || fail "no dropped-lines note with the count 7: $r"
# a verdict never unblocks
printf 'does-not-apply%s%s\n' "$T" "$C1" > "$rows"
"$pp" verify "$out1" "$rows" >/dev/null 2>&1; rc=$?; [ "$rc" -eq 1 ] || fail "a verdict unblocked a confirmed error (exit $rc)"
# tier.txt
rm "$out2/tier.txt"; "$pp" verify "$out2" >/dev/null 2>&1; rc=$?; [ "$rc" -eq 2 ] || fail "missing tier.txt: expected exit 2, got $rc"
printf 'banana\n' > "$out2/tier.txt"; "$pp" verify "$out2" >/dev/null 2>&1; rc=$?; [ "$rc" -eq 2 ] || fail "invalid tier.txt: expected exit 2, got $rc"
"$pp" verify "$tmp/nope" >/dev/null 2>&1; rc=$?; [ "$rc" -eq 2 ] || fail "missing directory: expected exit 2, got $rc"
# operator.txt becomes notes
mk "$tmp/o3"; printf 'Probes: INCOMPLETE, 1 absent, 0 skipped, 0 failed\ninstall: python3 -m venv .venv-probes\n' > "$tmp/o3/operator.txt"
r=$("$pp" verify "$tmp/o3" 2>/dev/null)
printf '%s\n' "$r" | grep -q '^note: .*absent' && printf '%s\n' "$r" | grep -q '^note: install: python3' || fail "operator.txt did not become notes: $r"
# a clean block prints nothing
mk "$tmp/o4"; printf '%s\n' "$C2" > "$tmp/o4/confirmed.tsv"; r=$("$pp" verify "$tmp/o4" 2>/dev/null); [ -z "$r" ] || fail "a clean run printed: $r"
# the tier does not change what tools found
printf 'skip\n' > "$out1/tier.txt"; "$pp" verify "$out1" >/dev/null 2>&1; rc=$?; [ "$rc" -eq 1 ] || fail "tier skip hid a confirmed error (exit $rc)"
exit 0
