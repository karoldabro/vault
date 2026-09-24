#!/usr/bin/env bash
# SC-5 of vault/plans/2026-09-24-1651-remove-mcp-tools.md — no unit test fails that passes on the
# commit before this change. Both suites run inside Docker, as tests/run.sh runs them. A test that
# already failed on the base commit is named on stdout, not counted.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
base=c23d9b1
[ -x "$root/tests/run.sh" ] || exit 2
git -C "$root" cat-file -e "$base^{commit}" 2>/dev/null || { echo "base commit $base is missing"; exit 2; }
tmp=$(mktemp -d)
cleanup() { git -C "$root" worktree remove --force "$tmp/base" >/dev/null 2>&1; rm -rf "$tmp"; }
trap cleanup EXIT
fails() { sed -n 's/^not ok [0-9]* //p' "$1" | sort -u; }
"$root/tests/run.sh" tests/unit > "$tmp/now.log" 2>&1
git -C "$root" worktree add -q "$tmp/base" "$base" || exit 2
"$tmp/base/tests/run.sh" tests/unit > "$tmp/base.log" 2>&1
grep -q '^1\.\.' "$tmp/now.log"  || { echo "the suite did not run"; tail -20 "$tmp/now.log"; exit 2; }
grep -q '^1\.\.' "$tmp/base.log" || { echo "the base suite did not run"; exit 2; }
new=$(comm -23 <(fails "$tmp/now.log") <(fails "$tmp/base.log"))
old=$(comm -12 <(fails "$tmp/now.log") <(fails "$tmp/base.log"))
[ -n "$old" ] && printf 'fails on the base commit too: %s\n' "$old"
if [ -n "$new" ]; then printf 'newly failing:\n%s\n' "$new"; exit 1; fi
exit 0
