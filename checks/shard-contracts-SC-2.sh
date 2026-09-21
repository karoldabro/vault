#!/usr/bin/env bash
# SC-2 of vault/plans/2026-09-21-2040-pm-shard-contracts.md — the seed step text.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
f="$root/commands/v-pm/steps/04-seed-workspace.md"
[ -r "$f" ] || { echo "the seed step is missing — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
grep -q 'seeds \*\*three\*\* sections' "$f" || fail "the seed step does not say three sections"
grep -q 'Keep \*\*all three\*\* out of' "$f" || fail "the seed step does not keep all three out of Consumed contract"
grep -q '`## Cross-session contracts`' "$f" || fail "the seed step does not name the contracts section"
grep -q 'depends' "$f" || fail "the seed step does not name depends"
grep -qi 'no rows' "$f" || fail "the seed step does not say no rows"
grep -q 'step (f3) item 6' "$f" || fail "the seed step does not point to step (f3) item 6 for who writes rows"
grep -q '^Shard contracts:' "$f" || fail "the Required output has no Shard contracts line"
exit 0
