#!/usr/bin/env bash
# SC-8 of vault/plans/2026-09-22-1023-spec-reading-probes.md — the rewritten ## Auditors section of
# commands/_shared/plan-probes.md (one shared template + a 3-row table) shows no net line growth over
# its pre-change baseline (28 lines, one auditor's prose), even though it now covers three auditors.
# Exit 0 met, 1 not met, 2 cannot say yet.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
f="$root/commands/_shared/plan-probes.md"
[ -f "$f" ] || { echo "commands/_shared/plan-probes.md is missing — cannot say"; exit 2; }
grep -q '^| data-model ' "$f" 2>/dev/null || { echo "the Auditors table has no data-model row yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
n=$(awk '/^## Auditors/{f=1} f{print} f && /^## / && !/^## Auditors/{exit}' "$f" | wc -l | tr -d ' ')
baseline=28
[ "$n" -le "$baseline" ] || fail "## Auditors section is now $n lines, past the $baseline-line pre-change baseline for one auditor"
exit 0
