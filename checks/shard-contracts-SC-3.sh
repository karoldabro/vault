#!/usr/bin/env bash
# SC-3 of vault/plans/2026-09-21-2040-pm-shard-contracts.md — the status step text.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
f="$root/commands/v-pm/steps/07-status.md"
[ -r "$f" ] || { echo "the status step is missing — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
grep -q 'bin/gate.sh master <shard> 2>&1' "$f" || fail "S.2 does not carry the literal gate command"
grep -q 'REFUSED master' "$f" || fail "S.2 does not filter on REFUSED master"
grep -q 'gate: N refusal(s)' "$f" || fail "S.2 does not drop the trailer line"
grep -q 'Four exceptions earn a line each' "$f" || fail "S.3 does not count four exceptions"
grep -q '\*\*Contract gap\*\*' "$f" || fail "S.3 has no Contract gap exception"
grep -q 'has no depends column; its /v-team session adds it' "$f" || fail "the legacy-shard line is missing"
grep -q '^saved-filters .*Contract gap' "$f" || fail "S.5 has no sample Contract gap row"
grep -q 'empty `id`' "$f" || fail "S.2 does not leave out a row with an empty id"
exit 0
