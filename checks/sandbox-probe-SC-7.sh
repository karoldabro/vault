#!/usr/bin/env bash
# SC-7 — the touched test files pass, and the full unit suite fails only the five tests that fail on HEAD.
# Exit 0 met, 1 not met, 2 cannot read the question. Runs the suite in Docker; expect several minutes.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
run="$root/tests/run.sh"
[ -x "$run" ] || { echo "tests/run.sh missing"; exit 2; }
[ -f "$root/tests/unit/sandbox-probe.bats" ] || { echo "tests/unit/sandbox-probe.bats not written yet — cannot say"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
known=(
  "an unrecognised type is reported, not silently given the loosest cap"
  "--compare names a constraint the short version dropped"
  "every top-level command has a description in its frontmatter"
  "every step file that uses the framework root also says how to resolve it"
  "v-team PROPOSE output contract is two-layer and translates panel vocabulary"
)
for f in sandbox-probe cr-sandbox v-cr probe probe-panel rule; do
  "$run" "tests/unit/$f.bats" > "$tmp/$f.out" 2>&1
  if grep -q '^not ok' "$tmp/$f.out"; then printf 'FAIL tests/unit/%s.bats\n' "$f"; grep '^not ok' "$tmp/$f.out"; exit 1; fi
  grep -q '^1\.\.[1-9]' "$tmp/$f.out" || { printf 'no result from tests/unit/%s.bats\n' "$f"; exit 1; }
done
"$run" tests/unit > "$tmp/all.out" 2>&1
grep -q '^1\.\.[1-9]' "$tmp/all.out" || { echo "the full suite printed no plan line"; exit 1; }
grep '^not ok' "$tmp/all.out" | sed 's/^not ok [0-9]* //' | sort > "$tmp/failed"
printf '%s\n' "${known[@]}" | sort > "$tmp/known"
if ! diff -u "$tmp/known" "$tmp/failed" > "$tmp/diff"; then
  echo "the failing tests differ from the five known on HEAD:"; cat "$tmp/diff"; exit 1
fi
exit 0
