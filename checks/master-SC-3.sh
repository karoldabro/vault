#!/usr/bin/env bash
# SC-3 of vault/plans/2026-09-21-1940-cross-session-contracts.md — the ordering check of gate.sh master.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"; fx="$root/tests/fixtures/master"
[ -r "$root/lib/master-check.sh" ] && [ -r "$fx/session-plan.md" ] || { echo "lib/master-check.sh or a fixture is not written yet — cannot say"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
want() {
    local name=$1 code=$2 pat=$3 f=$4 out rc
    out=$("$gate" master "$f" 2>&1); rc=$?
    [ "$rc" -eq "$code" ] || fail "$name: exit $rc, wanted $code: $out"
    printf '%s' "$out" | grep -q -- "$pat" || fail "$name: output lacks '$pat': $out"
}
cp "$fx/complete.md" "$tmp/complete.md"; cp "$fx/session-plan.md" "$tmp/session-plan.md"
want producers-done 0 '^master: ok ' "$tmp/session-plan.md"
for st in todo doing dropped; do
    sed "s/| S2 | the renderer | \/v-team | done/| S2 | the renderer | \/v-team | $st/" "$fx/complete.md" > "$tmp/complete.md"
    want "producer-$st" 1 "S3 consumes C-2, and its producer S2 has status $st, so C-2 is not produced yet; mark S2 done in the master plan if it shipped.*\[C-2\]" "$tmp/session-plan.md"
done
sed 's/^| C-3 .*/&\n| C-9 | own output | S3 | S3 | `x` |/' "$fx/complete.md" > "$tmp/complete.md"
want consumes-own-output 0 '^master: ok ' "$tmp/session-plan.md"
sed 's/| S2 | the renderer | \/v-team | done |/| S2 | the renderer | \/v-team | |/' "$fx/complete.md" > "$tmp/complete.md"
want empty-status 1 'its producer S2 has status empty' "$tmp/session-plan.md"
cp "$fx/complete.md" "$tmp/complete.md"
sed 's/^session_of: .*/session_of: complete.md/' "$fx/session-plan.md" > "$tmp/p1.md";      want no-id 1 'session_of needs the form' "$tmp/p1.md"
sed 's/^session_of: .*/session_of: gone.md#S3/' "$fx/session-plan.md" > "$tmp/p2.md";     want missing-master 1 'names a master plan that does not exist' "$tmp/p2.md"
sed 's/^session_of: .*/session_of: complete.md#S9/' "$fx/session-plan.md" > "$tmp/p3.md"; want unknown-id 1 'the master plan has no session S9' "$tmp/p3.md"
sed "s|^session_of: .*|session_of: $tmp/complete.md#S3|" "$fx/session-plan.md" > "$tmp/p4.md"; want absolute-path 0 '^master: ok ' "$tmp/p4.md"
awk '/^\| S4 /{print; print "| S3 | dup | \/v-do | done | | | |"; next}{print}' "$fx/complete.md" > "$tmp/complete.md"
want duplicate-keeps-first 0 '^master: ok ' "$tmp/session-plan.md"
awk '/^## Cross-session contracts/{s=1} /^## Refs/{s=0} !s' "$fx/complete.md" > "$tmp/complete.md"
want master-without-contracts 1 'needs a ## Cross-session contracts table' "$tmp/session-plan.md"
cp "$fx/complete.md" "$tmp/complete.md"
printf '# plan\n\n## Task\nx\n' > "$tmp/nosessions.md"
sed 's/^session_of: .*/session_of: nosessions.md#S3/' "$fx/session-plan.md" > "$tmp/p5.md"; want master-without-table 1 'names a plan with no ## Sessions table' "$tmp/p5.md"
sed '/^session_of: /d' "$fx/session-plan.md" > "$tmp/p6.md"
out=$("$gate" master "$tmp/p6.md" 2>&1); rc=$?; [ "$rc" -eq 0 ] && [ -z "$out" ] || fail "a plan without session_of was checked: rc=$rc out=$out"
exit 0
