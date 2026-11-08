#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot run the question. C4 of vault/plans/2026-11-08-1337-plan-goal-fit.md.
# Met when, on the frozen device-sync-tests plan with goal_fit: required:
#   gate.sh goal refuses its unowned goal cases, gate.sh master refuses the S7-S10 scopes that
#   append rows for the rest, and gate.sh goal passes once every goal case row has an owner.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fx="$root/tests/fixtures/goal/device-sync-tests.md"
[ -f "$fx" ] || { printf 'tests/fixtures/goal/device-sync-tests.md not written yet\n'; exit 1; }
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT
run() { out=$("$root/bin/gate.sh" "$@" 2>&1); rc=$?; [ "$rc" -eq 2 ] && { printf '%s\n' "$out"; exit 2; }; }

run goal "$fx"
[ "$rc" -eq 1 ] || { printf 'gate.sh goal passed the frozen plan (exit %s); its goal cases are not all owned\n' "$rc"; exit 1; }
grep -q 'owned' <<<"$out" || { printf 'the goal refusal does not report ownership:\n%s\n' "$out"; exit 1; }

run master "$fx"
[ "$rc" -eq 1 ] || { printf 'gate.sh master passed the S7-S10 scopes (exit %s)\n' "$rc"; exit 1; }
grep -q 'append rows' <<<"$out" || { printf 'the master refusal does not name the phrase:\n%s\n' "$out"; exit 1; }

# Give every unowned goal-case row an owner; the fixture marks such rows with an empty owner cell.
awk -F'|' 'BEGIN{OFS="|"} /^## /{s=($0=="## Goal cases")} s && NF>6 && $2 !~ /^ *(id|-+) *$/ && $5 ~ /^ *$/ {$5=" S11 "} {print}' "$fx" > "$tmp/plan.md"
run goal "$tmp/plan.md"
[ "$rc" -eq 0 ] || { printf 'the plan with every goal case owned is refused (exit %s):\n%s\n' "$rc" "$out"; exit 1; }
exit 0
