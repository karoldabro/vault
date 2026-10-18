#!/usr/bin/env bash
# SC-3 of vault/plans/2026-10-18-1257-quality-loops.md — the execute steps run the static check and the shared testing loop.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
fail() { printf '%s\n' "$*"; exit 1; }
w=commands/v-work/steps/04-execute.md; t=commands/v-team/steps/04-execute-loop.md; l=commands/_shared/testing-loop.md
for f in "$w" "$t" "$l" commands/_shared/definition-of-done.md; do [ -r "$f" ] || fail "$f is missing"; done
grep -q '^## 4.6a' "$w" || fail "$w has no §4.6a"
awk '/^## 4.6a/,/^## 4.7/' "$w" | grep -q 'bin/vault-check.sh static' || fail "$w §4.6a does not run bin/vault-check.sh static"
for f in "$w" "$t" commands/_shared/definition-of-done.md; do grep -q 'commands/_shared/testing-loop.md' "$f" || fail "$f does not name commands/_shared/testing-loop.md"; done
grep -qiE 'magic numbers|unused imports|nesting \(>3' "$w" && fail "$w §4.8 still lists checks a static tool owns"
a=$(grep -n '^## 5.1 Implement' "$t" | cut -d: -f1); b=$(grep -n '^## 5.2 Code-review loop' "$t" | cut -d: -f1); c=$(grep -n '^## 5.3 Testing loop' "$t" | cut -d: -f1)
{ [ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ]; } || fail "$t sections are not Implement, Code-review loop, Testing loop in order"
grep -q 'bin/vault-check.sh tests' "$l" || fail "$l does not run bin/vault-check.sh tests"
grep -qi 'test files only' "$l" || fail "$l has no writer-edits-tests-only rule"
grep -qF 'max(80, floor)' "$l" || fail "$l states no max(80, floor) floor"
for x in missing-test weak-test 'equivalent:' team_max_test_rounds team_max_test_writers 'coverage unmeasured' 'max(80' 'git diff --name-only'; do grep -q -- "$x" "$l" || fail "$l does not name $x"; done
awk '/^## 4.7/,/^## 4.8/' "$w" | grep -q 'bin/vault-check.sh tests' || fail "$w §4.7 does not run bin/vault-check.sh tests once"
awk '/^## 4.6a/,/^## 4.8/' "$w" | grep -qiE 'team_max_test_rounds|next round|assertion-auditor' && fail "$w §4.6a to §4.7 describe a loop; /v-work is single pass"
grep -qE '[0-9]+ to [0-9]+' commands/v-team.md || fail "commands/v-team.md does not restate the spawn range"
exit 0
