#!/usr/bin/env bash
# SC-5 — the v-method files restate no rule a shared module already owns.
#
# `/v-method` writes about how to work, which is the subject the shared modules already cover. That
# makes it the command most likely to grow a second copy of agent-conduct or communication. A rule
# with a home is referenced, never repeated.
#
# The pattern list lives in lib/shared-module-rules.tsv, shared with checks/v-loop-SC-3.sh. Its own
# header carries the limit: these patterns match the owners' literal wording, so a rule reworded
# rather than copied passes. Recorded in vault/check-budget.md.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

rules="$root/lib/shared-module-rules.tsv"
[ -f "$rules" ] || { printf '  MISSING  %s does not exist\n' "$rules"; exit 1; }
owned=$(grep -v '^[[:space:]]*#' "$rules" | grep .)
[ -n "$owned" ] || { printf '  FAIL  %s carries no patterns\n' "$rules"; exit 1; }

fail=0
for f in commands/v-method.md commands/v-method/routing.md; do
  if [ ! -f "$root/$f" ]; then
    printf '  MISSING  %s does not exist yet\n' "$f"; fail=1; continue
  fi
  while IFS=$'\t' read -r pat owner; do
    [ -n "$pat" ] || continue
    if hit=$(grep -inE "$pat" "$root/$f"); then
      printf '  RESTATED  %s: %s owns this; reference it instead:\n%s\n' "$f" "$owner" "$hit"; fail=1
    fi
  done <<<"$owned"
done

# The dispatcher defers to the shared modules rather than re-teaching them.
[ -f "$root/commands/v-method.md" ] &&
  { grep -q 'agent-conduct.md' "$root/commands/v-method.md" ||
    { printf '  MISSING  commands/v-method.md defers to no shared module\n'; fail=1; }; }

[ "$fail" -eq 0 ] || exit 1
printf '  OK  both v-method files restate no shared-module rule\n'
