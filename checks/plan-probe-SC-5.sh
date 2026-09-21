#!/usr/bin/env bash
# SC-5 of vault/plans/2026-09-21-1800-plan-time-probes.md — bin/plan-probes.sh measure.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pp="$root/bin/plan-probes.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$pp" ] || { echo "bin/plan-probes.sh not written yet — cannot say"; exit 2; }
command -v jq >/dev/null || { echo "jq is absent — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
T=$(printf '\t')
# msg <id> <timestamp> <input> <cache_creation> <cache_read> <output>
msg() { printf '{"type":"assistant","timestamp":"%s","message":{"id":"%s","usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":%s}}}\n' "$2" "$1" "$3" "$4" "$5" "$6"; }
s="$tmp/sess"; mkdir -p "$s.d/subagents"
{ msg m1 2026-09-21T10:00:00Z 2 100 1000 5
  msg m1 2026-09-21T10:00:01Z 2 100 1000 50
  msg m1 2026-09-21T10:00:02Z 2 100 1000 500
  msg m2 2026-09-21T10:05:00Z 1 0 0 10
  msg m3 2026-09-21T12:00:00Z 9 9 9 9
  printf 'this is not json\n'
  printf '{"type":"assistant","timestamp":"2026-09-21T10:06:00Z","message":{"id":"m4"}}\n'
  printf '{"type":"assistant","timestamp":"2026-09-21T10:06:30Z","message":{"id":"m5","usage":{"input_tokens":4,"output_tokens":6}}}\n'
  printf '{"type":"user","timestamp":"2026-09-21T10:07:00Z","message":{"content":"hi"}}\n'
  msg m6 2026-09-21T10:10:00Z 3 0 0 4
  msg m7 2026-09-21T10:10:00.500Z 50 0 0 50
  msg m8 2026-09-21T09:59:59.999Z 50 0 0 50
} > "$s.jsonl"
{ msg a1 2026-09-21T10:02:00Z 0 10 5 10; msg a1 2026-09-21T10:02:01Z 0 10 5 10; } > "$s.d/subagents/agent-a.jsonl"
msg b1 2026-09-21T11:00:00Z 5 5 5 5 > "$s.d/subagents/agent-b.jsonl"
mv "$s.d" "$tmp/sess"
r=$("$pp" measure "$s.jsonl" --from 2026-09-21T10:00:00Z --to 2026-09-21T10:10:00Z 2>"$tmp/err"); rc=$?
[ "$rc" -eq 0 ] || fail "measure exited $rc: $(head -3 "$tmp/err")"
# main: m1 counts once at its largest output (2+100+500=602), m2 11, m5 10, m6 7 -> 630; cache_read 1000; 4 messages
printf '%s\n' "$r" | grep -q "^sess.jsonl${T}fresh=630${T}cache_read=1000${T}messages=4\$" || fail "main file line is wrong: $r"
printf '%s\n' "$r" | grep -q "^agent-a.jsonl${T}fresh=20${T}cache_read=5${T}messages=1\$" || fail "agent-a line is wrong: $r"
printf '%s\n' "$r" | grep -q "^agent-b.jsonl${T}fresh=0${T}cache_read=0${T}messages=0\$" || fail "agent-b line is wrong: $r"
printf '%s\n' "$r" | grep -q "^total${T}fresh=650${T}cache_read=1005${T}messages=5\$" || fail "total line is wrong: $r"
grep -qi 'skipped 1 line' "$tmp/err" || fail "the non-JSON line is not reported on stderr: $(cat "$tmp/err")"
# bad calls
"$pp" measure "$s.jsonl" --from 2026-09-21T10:10:00Z --to 2026-09-21T10:00:00Z >/dev/null 2>&1; [ $? -eq 2 ] || fail "from after to: expected exit 2"
"$pp" measure "$s.jsonl" --from 2026-09-21T10:00:00Z >/dev/null 2>&1; [ $? -eq 2 ] || fail "missing --to: expected exit 2"
"$pp" measure "$tmp/nope.jsonl" --from 2026-09-21T10:00:00Z --to 2026-09-21T10:10:00Z >/dev/null 2>&1; [ $? -eq 2 ] || fail "missing transcript: expected exit 2"
"$pp" measure "$s.jsonl" --from yesterday --to 2026-09-21T10:10:00Z >/dev/null 2>&1; [ $? -eq 2 ] || fail "bad timestamp: expected exit 2"
: > "$tmp/empty.jsonl"; r=$("$pp" measure "$tmp/empty.jsonl" --from 2026-09-21T10:00:00Z --to 2026-09-21T10:10:00Z 2>/dev/null)
printf '%s\n' "$r" | grep -q "^total${T}fresh=0${T}cache_read=0${T}messages=0\$" || fail "an empty transcript did not give zeros: $r"
# widening the window never lowers the total
w=$("$pp" measure "$s.jsonl" --from 2026-09-21T00:00:00Z --to 2026-09-21T23:59:59Z 2>/dev/null | sed -n "s/^total${T}fresh=\([0-9]*\).*/\1/p")
[ "$w" -ge 650 ] || fail "a wider window lowered the total: $w"
exit 0
