#!/usr/bin/env bash
# SC-4 of vault/plans/2026-09-22-1023-spec-reading-probes.md — commands/_shared/plan-probes.md's
# ## Auditors section names all three auditors, each with its literal reads set and a one-sentence
# question matching this plan's ## Auditor content table, and reuse's existing behaviour is untouched.
# Exit 0 met, 1 not met, 2 cannot say yet.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
f="$root/commands/_shared/plan-probes.md"
[ -f "$f" ] || { echo "commands/_shared/plan-probes.md is missing — cannot say"; exit 2; }
grep -q '^| data-model ' "$f" 2>/dev/null || { echo "the Auditors table has no data-model row yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }

grep -q '^| reuse ' "$f" || fail "reuse row missing from the Auditors table"
grep -q '^| data-model ' "$f" || fail "data-model row missing from the Auditors table"
grep -q '^| naming ' "$f" || fail "naming row missing from the Auditors table"

grep -Fq 'spec-tables' "$f" || fail "no row names spec-tables as a reads value"
grep -Fq 'spec-naming' "$f" || fail "no row names spec-naming as a reads value"

grep -Eq '^\| data-model \|[^|]*spec-tables[^|]*\|[^|]*Data model table[^|]*\|' "$f" \
    || fail "data-model row's reads/question cells don't match this plan's ## Auditor content table"
grep -Eq '^\| naming \|[^|]*spec-naming[^|]*\|[^|]*snake_case[^|]*\|' "$f" \
    || fail "naming row's reads/question cells don't match this plan's ## Auditor content table"

grep -E '^\| reuse ' "$f" | grep -Fq 'similar-symbols' || fail "reuse row's probe reference (similar-symbols) is gone — reuse's behaviour changed"
grep -E '^\| reuse ' "$f" | grep -Fq 'spec-symbols' || fail "reuse row's probe reference (spec-symbols) is gone — reuse's behaviour changed"

exit 0
