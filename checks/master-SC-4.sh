#!/usr/bin/env bash
# SC-4 of vault/plans/2026-09-21-1940-cross-session-contracts.md — the gate on the real plans.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"
master="$root/vault/plans/2026-09-21-0900-architecture-first-planning.md"
mine="$root/vault/plans/2026-09-21-1940-cross-session-contracts.md"
[ -r "$master" ] && [ -r "$mine" ] && [ -r "$root/lib/master-check.sh" ] || { echo "the gate or a plan is missing — cannot say"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
out=$("$gate" master "$master" 2>&1) || fail "the real master plan is refused: $out"
printf '%s' "$out" | grep -q '^master: ok ' || fail "no 'master: ok' for the real master plan: $out"
cp "$master" "$tmp/master.md"; sed -i '/^| C-6 /d' "$tmp/master.md"
out=$("$gate" master "$tmp/master.md" 2>&1); rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'S10 depends on S8 and no contract row is produced by S8 and consumed by S10' || fail "the copy that lost C-6 was not refused by pair: rc=$rc $out"
out=$(cd "$root" && "$gate" all "$mine" --phase propose 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail "all --phase propose refuses this plan: $out"
printf '%s' "$out" | grep -q '^master: ok ' || fail "all --phase propose did not run the master check on this plan: $out"
# the same call on a plan whose session_of names a master copy where the producer S8 is not done
cp "$mine" "$tmp/mine.md"; cp "$root/vault/plans/2026-09-21-1940-cross-session-contracts.arch.md" "$tmp/"
sed 's/^\(| S8 .*\)| done |/\1| todo |/' "$master" > "$tmp/master.md"
sed -i 's/^session_of: .*/session_of: master.md#S10/' "$tmp/mine.md"
out=$(cd "$root" && "$gate" all "$tmp/mine.md" --phase propose 2>&1); rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'REFUSED master .*S10 consumes C-6, and its producer S8 has status todo' || fail "all --phase propose passed a plan whose producer is not done: rc=$rc $out"
exit 0
