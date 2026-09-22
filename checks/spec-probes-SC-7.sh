#!/usr/bin/env bash
# SC-7 (delivery) of vault/plans/2026-09-22-1023-spec-reading-probes.md — the stage runs end to end
# on this repo's own spec, which has no real SQL and a harness-profile spec (no Data model section).
# Scoped to the two changed bats files (round-1 correctness-4: no test-count tolerance is implemented
# or needed once the run excludes unrelated pre-existing failures by construction).
# Exit 0 met, 1 not met, 2 cannot say yet.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
spec="$root/vault/plans/2026-09-22-1023-spec-reading-probes.arch.md"
[ -f "$spec" ] || { echo "this plan's own arch spec is missing — cannot say"; exit 2; }
grep -q '^spec-tables' "$root/probes/registry.tsv" 2>/dev/null || { echo "registry rows not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }

out=$("$root/bin/probe-panel.sh" run --stage plan --spec "$spec" --repo "$root" --only spec-tables --only spec-naming 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail "probe-panel.sh exited $rc: $out"
printf '%s\n' "$out" | grep -qx 'probe-status: complete' || fail "expected probe-status: complete: $out"

test_out=$("$root/tests/run.sh" tests/unit/probe.bats tests/unit/plan-probes.bats 2>&1); trc=$?
if [ "$trc" -ne 0 ]; then
    printf '%s\n' "$test_out" | tail -40
    fail "tests/unit/probe.bats and tests/unit/plan-probes.bats did not pass"
fi
exit 0
