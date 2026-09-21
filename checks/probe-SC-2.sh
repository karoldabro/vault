#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/bin/probe.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$probe" ] || { echo "bin/probe.sh not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
T=$(printf '\t')
repo="$tmp/repo"; mkdir -p "$repo/probes"
{
  printf 'emit1\tharness\tplan\ttrue\tprintf "emit1\\ta.md\\t3\\twarn\\trule-x\\tmessage\\n"\tnative\tS\tno\tnone\n'
  printf 'clean\tharness\tplan\ttrue\ttrue\tnative\tS\tno\tnone\n'
  printf 'short\tharness\tplan\ttrue\tprintf "a\\tb\\n"\tnative\tS\tno\tnone\n'
  printf 'exit2\tharness\tplan\ttrue\tsh -c "exit 2"\tnative\tS\tno\tnone\n'
  printf 'badsev\tharness\tplan\ttrue\tprintf "p\\tf\\t1\\tfatal\\tr\\tm\\n"\tnative\tS\tno\tnone\n'
  printf 'badline\tharness\tplan\ttrue\tprintf "p\\tf\\tx\\twarn\\tr\\tm\\n"\tnative\tS\tno\tnone\n'
} > "$repo/probes/registry.tsv"
run() { "$probe" run plan --repo "$repo" --allow-repo-registry --only "$1" 2>"$tmp/err"; }
out=$(run emit1); rc=$?
[ "$rc" -eq 1 ] || fail "one finding: expected exit 1, got $rc"
[ "$out" = "emit1${T}a.md${T}3${T}warn${T}rule-x${T}message" ] || fail "finding row differs: $out"
grep -q '^ran: emit1: 1$' "$tmp/err" || fail "stderr has no 'ran: emit1: 1' line: $(cat "$tmp/err")"
out=$(run clean); rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] || fail "clean run: expected exit 0 and no output, got $rc and: $out"
grep -q '^ran: clean: 0$' "$tmp/err" || fail "stderr has no 'ran: clean: 0' line: $(cat "$tmp/err")"
for id in short exit2 badsev badline; do
  out=$(run $id); rc=$?
  [ "$rc" -eq 2 ] || fail "$id: expected exit 2, got $rc"
  grep -q "^failed: $id" "$tmp/err" || fail "$id: stderr has no 'failed: $id' line: $(cat "$tmp/err")"
  [ -z "$out" ] || fail "$id: a malformed row reached stdout: $out"
done
exit 0
