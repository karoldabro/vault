#!/usr/bin/env bash
# SC-4 — the two v-loop rule files are written in requirement form, not prohibition form.
#
# Prohibition-shaped rules fall from 73% compliance at turn 5 to 33% by turn 16; requirements hold.
# A campaign runs for hours, so it has more turns than anything else the framework ships, and it is
# the worst possible place for a "never do X" safety rule. Fails when prohibitions outnumber
# requirements in either file.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Same two patterns bin/rule-count.sh uses, so one grammar governs the whole framework.
PROHIBIT='(^|[^a-z])(never|do not|don.t|must not|cannot|may not|refuses? to)([^a-z]|$)'
REQUIRE='(^|[^a-z])(must|shall|always|is required|are required)([^a-z]|$)'

fail=0
for f in commands/v-loop.md commands/v-loop/campaign-rules.md; do
  if [ ! -f "$root/$f" ]; then
    printf '  MISSING  %s\n' "$f"; fail=1; continue
  fi
  p=$(grep -ciE "$PROHIBIT" "$root/$f" || true)
  r=$(grep -iE "$REQUIRE" "$root/$f" 2>/dev/null | grep -civE 'must not|never' || true)
  if [ "$p" -gt "$r" ]; then
    printf '  OVER  %s: %d prohibitions against %d requirements. Rewrite as requirements; do not delete the rule\n' "$f" "$p" "$r"
    fail=1
  else
    printf '  OK  %s: %d prohibitions, %d requirements\n' "$f" "$p" "$r"
  fi
done
exit "$fail"
