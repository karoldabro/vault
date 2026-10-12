#!/usr/bin/env bash
# SC-2 of vault/plans/2026-10-12-0944-v-pm-planning-loop.md — bin/pm-plan.sh on the fixture and on
# broken variants built from it. Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pp="$root/bin/pm-plan.sh"; fx="$root/tests/fixtures/pm/valid"
[ -x "$pp" ] || { echo "bin/pm-plan.sh is missing or not executable"; exit 1; }
[ -f "$fx/plan.md" ] || { echo "tests/fixtures/pm/valid/plan.md is missing"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
fresh() { rm -rf "$t/p"; cp -r "$fx" "$t/p"; sed -i "s#@DIR@#$t/p#g" "$t/p/plan.md" "$t"/p/briefs/*.md; }
fresh
"$pp" check "$t/p/plan.md" >/dev/null 2>&1 || fail "check refused the valid fixture"
o=$("$pp" order "$t/p/plan.md" 2>/dev/null) || fail "order failed on the valid fixture"
n=$(grep -c . <<<"$o"); r=$(grep -cE '^[0-9]+[[:space:]]+S[0-9]+[[:space:]]+[a-z]+[[:space:]]+(runnable|waits|blocked|running|done|dropped)' <<<"$o")
{ [ "$n" -eq "$r" ] && [ "$n" -ge 2 ]; } || fail "order did not print one wave/id/status/readiness line per session"
"$pp" set "$t/p/plan.md" S1 status=doing >/dev/null || fail "set could not change S1"
grep -qE '^\| S1 \|.*\| doing \|' "$t/p/plan.md" || fail "set did not write doing into S1"
bad() { local name=$1; fresh; eval "$2"; msg=$("$pp" check "$t/p/plan.md" 2>&1); rc=$?
    [ "$rc" -eq 1 ] || fail "check on $name exited $rc, expected 1"; [ -n "$msg" ] || fail "check on $name named no defect"; }
bad missing-brief 'rm -f "$t"/p/briefs/S2-*.md'
bad no-run-line 'sed -i '\''/^## Next command/,/^## /{/^cd /d}'\'' "$t"/p/briefs/S2-*.md'
bad run-mismatch 'sed -i '\''s#&& claude --add-dir \([^ ]*\) "/v-work#\&\& claude --add-dir \1 "/v-team#'\'' "$t"/p/briefs/S2-*.md'
bad no-criteria 'sed -i '\''/^## Success criteria/,/^## /{/^| SC-/d}'\'' "$t/p/plan.md"'
bad unreached-criterion 'sed -i '\''s/^\(| SC-1 |[^|]*|\)[^|]*|/\1  |/'\'' "$t/p/plan.md"'
bad missing-done-line 'sed -i '\''/^| DD-4 |/d'\'' "$t/p/plan.md"'
bad cycle 'sed -i '\''s/^\(| S1 |[^|]*|[^|]*|[^|]*|[^|]*|\)[^|]*|/\1 S2 |/'\'' "$t/p/plan.md"'
exit 0
