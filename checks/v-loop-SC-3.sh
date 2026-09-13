#!/usr/bin/env bash
# SC-3 — commands/v-loop/campaign-rules.md restates no rule a shared module already owns.
#
# Every prose rule the framework adds spends the same attention as one that matters, and a session
# does not get to choose which rules lose. A rule with a home is referenced from here, never
# repeated. Fails on a restatement.
#
# The pattern list lives in lib/shared-module-rules.tsv, shared with checks/v-method-SC-5.sh. Its
# own header carries the limit: these patterns match the owners' literal wording, so a rule reworded
# rather than copied passes. Recorded in vault/check-budget.md.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
f="$root/commands/v-loop/campaign-rules.md"
[ -f "$f" ] || { printf '  MISSING  %s does not exist\n' "$f"; exit 1; }

rules="$root/lib/shared-module-rules.tsv"
[ -f "$rules" ] || { printf '  MISSING  %s does not exist\n' "$rules"; exit 1; }
owned=$(grep -v '^[[:space:]]*#' "$rules" | grep .)
[ -n "$owned" ] || { printf '  FAIL  %s carries no patterns\n' "$rules"; exit 1; }

fail=0
while IFS=$'\t' read -r pat owner; do
  [ -n "$pat" ] || continue
  if hit=$(grep -inE "$pat" "$f"); then
    printf '  RESTATED  %s owns this; reference it instead:\n%s\n' "$owner" "$hit"; fail=1
  fi
done <<<"$owned"

# every module under commands/_shared/ must appear as an owner above, so a new module cannot be
# added without extending this check
for m in "$root"/commands/_shared/*.md; do
  n=$(basename "$m")
  grep -q "$n" <<<"$owned" || { printf '  UNCOVERED  %s owns rules this check never looks for\n' "$n"; fail=1; }
done

grep -q 'agent-conduct.md' "$f" || { printf '  MISSING  the file defers to no shared module\n'; fail=1; }

[ "$fail" -eq 0 ] && printf '  OK  campaign-rules.md restates no shared-module rule; all _shared modules covered\n'
exit "$fail"
