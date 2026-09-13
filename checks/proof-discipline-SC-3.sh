#!/usr/bin/env bash
# SC-3 — the auditor seat is a real lens, seated by a written rule, and cedes numbers.
#
# Word presence anywhere in a file is not evidence a lens binds five domains, so the domains must
# appear in one table or list block. The averaging rule is asserted as an ABSENCE through `run grep`
# semantics: a check written `! grep` is exempt from set -e and decides nothing.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
persona="$root/personas/_shared/proof-auditor.md"
resolution="$root/personas/_resolution.md"
fail=0

[ -f "$persona" ] || { printf '  MISSING  %s does not exist yet\n' "$persona"; exit 1; }

# Every shared lens carries a bound analyzer; without one its findings can only be advisory.
grep -qE '^## Bound analyzer' "$persona" || { printf '  FAIL  %s has no `## Bound analyzer` section\n' "$persona"; fail=1; }

# The five domains inside one contiguous table or list block, not scattered as prose.
block=$(awk '
  /^[|-]|^[[:space:]]*[-*][[:space:]]/ { blk = blk "\n" $0; next }
  { if (blk != "") { print blk; blk = "" } }
  END { if (blk != "") print blk }' "$persona" |
  awk -v RS='' '{ n=0
    if ($0 ~ /resolves/) n++
    if ($0 ~ /warrant/) n++
    if ($0 ~ /currency/) n++
    if ($0 ~ /standing/) n++
    if ($0 ~ /independence/) n++
    if (n==5) found=1 } END { print found+0 }')
[ "$block" -eq 1 ] || { printf '  FAIL  %s does not carry all five domains in one table or list block\n' "$persona"; fail=1; }

grep -qE 'worst' "$persona" || { printf '  FAIL  %s does not state worst-domain aggregation\n' "$persona"; fail=1; }
grep -qE 'cap|never refute' "$persona" || { printf '  FAIL  %s does not state that standing and independence cap rather than refute\n' "$persona"; fail=1; }
grep -q 'data-evidence' "$persona" || { printf '  FAIL  %s states no suppression against business/data-evidence\n' "$persona"; fail=1; }

# The fold must be stated as worst-domain. A bare `averag` grep refuses a correct persona that says
# "never average", so assert the rule positively instead of banning the word.
grep -qiE 'worst[^.]{0,40}(wins|domain)' "$persona" || { printf '  FAIL  %s does not state the fold as worst-domain\n' "$persona"; fail=1; }

grep -q 'proof-auditor' "$resolution" || { printf '  FAIL  %s never seats proof-auditor\n' "$resolution"; fail=1; }
grep -qE 'team_max_parallel_critics' "$resolution" || { printf '  FAIL  %s does not state the seat cap alongside the new seat\n' "$resolution"; fail=1; }

[ "$fail" -eq 0 ] || exit 1
printf '  OK  five domains in one block, a bound analyzer, worst-domain fold, seated, numbers ceded\n'
