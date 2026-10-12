#!/usr/bin/env bash
# SC-5 of vault/plans/2026-10-12-0944-v-pm-planning-loop.md — a plan built from templates/feature-plan.md
# and two briefs from templates/handoff.md run through bin/pm-plan.sh and bin/gate.sh master.
# Exit 0 met, 1 not met.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tp="$root/templates/feature-plan.md"; th="$root/templates/handoff.md"; pp="$root/bin/pm-plan.sh"
{ [ -r "$tp" ] && [ -r "$th" ]; } || { echo "templates/feature-plan.md or templates/handoff.md is missing"; exit 1; }
[ -x "$pp" ] || { echo "bin/pm-plan.sh is missing"; exit 1; }
fail() { printf '%s\n' "$*"; exit 1; }
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/briefs" "$t/repo"
# Fill the template's tables: two criteria, two sessions, S2 depends on S1 through C-1.
awk -v repo="$t/repo" '
  /^## / { sec = $0 }
  /^\| *id *\|/ && !done[sec] { print; getline; print; done[sec] = 1
      if (sec ~ /Success criteria/) { print "| SC-1 | WHEN an admin exports THE SYSTEM SHALL download a CSV | S1 S2 |" }
      if (sec ~ /Sessions/) {
          print "| S1 | " repo " | build the core | /v-team | todo | | REQ-01 | | | |"
          print "| S2 | " repo " | wire the screen | /v-work | todo | S1 | REQ-02 | | | |" }
      if (sec ~ /Cross-session contracts/) { print "| C-1 | core endpoint | S1 | S2 | GET /core returns {id: int} |" }
      skip = 1; next }
  skip && /^\|/ && sec !~ /Definition of done/ { next }
  { skip = 0; print }
' "$tp" | sed 's/{{[a-z-]*}}/demo/g' > "$t/plan.md"
grep '^## ' "$tp" | while IFS= read -r h; do grep -qxF "$h" "$t/plan.md" || { echo "filled plan lost heading: $h"; exit 1; }; done || exit 1
for s in "S1 core /v-team" "S2 screen /v-work"; do
    set -- $s
    sed -e 's/{{[a-z-]*}}/demo/g' "$th" | awk -v id="$1" -v plan="$t/plan.md" -v line="cd $t/repo && claude --add-dir $t \"$3 $t/plan.md#$1\"" '
        /^plan:/ { print "plan: " plan; print "id: " id; next }
        /^## Next command/ { print; print ""; print line; skip = 1; next }
        skip && /^## / { skip = 0 }
        !skip { print }' > "$t/briefs/$1-$2.md"
done
"$pp" check "$t/plan.md" || fail "pm-plan.sh check refused a plan built from the templates"
"$root/bin/gate.sh" master "$t/plan.md" >/dev/null || fail "gate.sh master refused a plan built from the templates"
o=$("$pp" order "$t/plan.md") || fail "order failed"
grep -qE 'S1[[:space:]]+todo[[:space:]]+runnable' <<<"$o" || fail "S1 is not runnable: $o"
grep -qE 'S2[[:space:]]+todo[[:space:]]+waits' <<<"$o" || fail "S2 does not wait on S1: $o"
"$pp" set "$t/plan.md" S1 status=done evidence=abc1234 >/dev/null || fail "set could not close S1"
o=$("$pp" order "$t/plan.md") || fail "order failed after S1 is done"
grep -qE 'S2[[:space:]]+todo[[:space:]]+runnable' <<<"$o" || fail "S2 is not runnable once S1 is done: $o"
exit 0
