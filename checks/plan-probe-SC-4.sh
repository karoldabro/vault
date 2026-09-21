#!/usr/bin/env bash
# SC-4 of vault/plans/2026-09-21-1800-plan-time-probes.md — bin/plan-probes.sh budget.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pp="$root/bin/plan-probes.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$pp" ] || { echo "bin/plan-probes.sh not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
T=$(printf '\t')
# block <file> <bytes> <auditor 0|1>: a block of exactly <bytes> bytes; the first line is a reuse row when auditor is 1
block() {
  local f=$1 b=$2 a=$3 first="filler"
  [ "$a" = 1 ] && first="similar-symbols${T}f${T}1${T}warn${T}r${T}m"
  { printf '%s\n' "$first"; head -c "$((b - ${#first} - 1))" /dev/zero | tr '\0' 'x'; } > "$f"
  [ "$(wc -c < "$f")" -eq "$b" ] || fail "fixture block is not $b bytes"
}
# expect <critics> <rounds> <bytes> <auditor> <tier>
expect() {
  local c=$1 r=$2 b=$3 a=$4 want=$5 d="$tmp/d.$RANDOM" o notes
  block "$tmp/blk" "$b" "$a"
  o=$("$pp" budget --critics "$c" --rounds "$r" --block "$tmp/blk" --out "$d" 2>"$tmp/err"); rc=$?
  [ "$rc" -eq 0 ] || fail "c=$c r=$r bytes=$b aud=$a: exit $rc: $(head -2 "$tmp/err")"
  printf '%s\n' "$o" | grep -qx "tier: $want" || fail "c=$c r=$r bytes=$b aud=$a: wanted tier $want, got: $o"
  [ "$(cat "$d/tier.txt")" = "$want" ] || fail "tier.txt is not $want"
  notes=$(printf '%s\n' "$o" | grep -c '^note: ')
  if [ "$want" = full ]; then [ "$notes" -eq 0 ] || fail "a note on tier full: $o"; else [ "$notes" -eq 1 ] || fail "tier $want needs exactly one note: $o"; fi
  printf '%s\n' "$o" | grep '^note: ' | while read -r l; do [ "$(printf '%s' "$l" | wc -w)" -le 30 ] || { echo long; }; done | grep -q long && fail "a note is over 30 words: $o"
  printf '%s\n' "$o" | grep -q '^projected: added=[0-9]* baseline=[0-9]* percent=[0-9]*$' || fail "no projected line: $o"
}
# c=1 r=1: baseline 530000, limit 265000 at the defaults. With the auditor the block edge is 458000 bytes, without it 530000.
expect 1 1 1000 1 full
expect 1 1 458000 1 full
expect 1 1 458001 1 block-only
expect 1 1 530000 0 full
expect 1 1 530001 0 skip
expect 1 1 600000 1 skip
# monotone: a bigger block never improves the tier
rank() { case $1 in full) echo 0 ;; block-only) echo 1 ;; *) echo 2 ;; esac; }
prev=0
for b in 100000 300000 458000 458004 500000 530000 530004 700000; do
  block "$tmp/blk" "$b" 1; "$pp" budget --critics 1 --rounds 1 --block "$tmp/blk" --out "$tmp/m" >"$tmp/mo" 2>&1
  t=$(sed -n 's/^tier: //p' "$tmp/mo"); rk=$(rank "$t"); [ "$rk" -ge "$prev" ] || fail "tier improved at $b bytes"; prev=$rk
done
# critics and rounds enter as a product
block "$tmp/blk" 300000 1
a=$("$pp" budget --critics 2 --rounds 3 --block "$tmp/blk" --out "$tmp/m" | sed -n 's/^tier: //p'); b=$("$pp" budget --critics 3 --rounds 2 --block "$tmp/blk" --out "$tmp/m" | sed -n 's/^tier: //p')
[ "$a" = "$b" ] || fail "critics 2 x rounds 3 gave $a and critics 3 x rounds 2 gave $b"
# the settings come from the environment
block "$tmp/blk" 1000 1
PLAN_PROBE_LIMIT_PERCENT=0 "$pp" budget --critics 1 --rounds 1 --block "$tmp/blk" --out "$tmp/m" | grep -qx 'tier: skip' || fail "PLAN_PROBE_LIMIT_PERCENT=0 did not skip"
# bad input exits 2 and writes no tier.txt
bad() { local d="$tmp/bad.$RANDOM"; shift 0; "$@" --out "$d" >/dev/null 2>"$tmp/err"; rc=$?; [ "$rc" -eq 2 ] || fail "expected exit 2, got $rc for: $*"; [ ! -e "$d/tier.txt" ] || fail "tier.txt written on bad input: $*"; }
bad "$pp" budget --critics abc --rounds 1 --block "$tmp/blk"
bad "$pp" budget --critics 0 --rounds 1 --block "$tmp/blk"
bad "$pp" budget --critics 1 --rounds 0 --block "$tmp/blk"
bad "$pp" budget --critics 08 --rounds 1 --block "$tmp/blk"
bad "$pp" budget --critics 1000000001 --rounds 1 --block "$tmp/blk"
bad "$pp" budget --critics 1 --rounds 1 --block "$tmp/none"
bad "$pp" budget --critics 1 --rounds 1
PLAN_PROBE_LIMIT_PERCENT=x bad "$pp" budget --critics 1 --rounds 1 --block "$tmp/blk"
PLAN_PROBE_BYTES_PER_TOKEN=0 bad "$pp" budget --critics 1 --rounds 1 --block "$tmp/blk"
"$pp" budget --critics 1 --rounds 1 --block "$tmp/blk" --out "$tmp/m" >/dev/null 2>"$tmp/err"
PLAN_PROBE_LIMIT_PERCENT=x "$pp" budget --critics 1 --rounds 1 --block "$tmp/blk" --out "$tmp/m" >/dev/null 2>"$tmp/err"; grep -q PLAN_PROBE_LIMIT_PERCENT "$tmp/err" || fail "a bad setting is not named on stderr: $(cat "$tmp/err")"
"$pp" budget --critics abc --rounds 1 --block "$tmp/blk" --out "$tmp/m" >/dev/null 2>"$tmp/err"; grep -q -- '--critics' "$tmp/err" || fail "a bad flag is not named on stderr: $(cat "$tmp/err")"
: > "$tmp/empty"; o=$("$pp" budget --critics 1 --rounds 1 --block "$tmp/empty" --out "$tmp/m" 2>&1); printf '%s\n' "$o" | grep -qx 'tier: full' || fail "an empty block did not give full: $o"
exit 0
