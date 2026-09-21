#!/usr/bin/env bash
# SC-7 — the skill text, its single homes and its guards: /v-rule states the own-account rule and the approval gate,
# the rule-file format lives only in probe-kit.md, no review command calls /v-rule, and the master plan carries S10 and C-8.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
v=commands/v-rule.md
[ -f "$v" ] || { echo "$v not written yet"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
head -5 "$v" | grep -q '^description: .' || fail "$v has no frontmatter description"
for s in 'rule-check.sh own-comments' 'rule-check.sh accept' 'rule-check.sh install' 'rule-check.sh verify' 'operator approves' 'Bitbucket'; do
  grep -qF -- "$s" "$v" || fail "$v does not say: $s"
done
[ "$(grep -c '^## Rule files' commands/_shared/probe-kit.md)" -eq 1 ] || fail "commands/_shared/probe-kit.md must hold one '## Rule files' section"
n=$(grep -rlF -- '--rule probes/rules/' commands | wc -l | tr -d ' ')
[ "$n" -eq 1 ] || fail "the rule row template must live in one command file, found $n"
for f in v-cr v-team v-work v-do v-loop v-method v-pm; do
  hit=$(grep -rlF 'v-rule' "commands/$f.md" "commands/$f" 2>/dev/null); [ -z "$hit" ] || fail "a command flow names /v-rule (D-12): $hit"
done
grep -q '`/v-rule`' README.md || fail "README.md does not list /v-rule"
grep -q 'rule' tests/unit/rule.bats 2>/dev/null || fail "tests/unit/rule.bats missing"
grep -q 'D-12' tests/unit/rule.bats || fail "tests/unit/rule.bats has no guard that no command calls /v-rule"
m=vault/plans/2026-09-21-0900-architecture-first-planning.md
grep -Eq '^\| S8 \|.*\| done \|' "$m" || fail "master plan S8 row is not done"
grep -Eq '^\| S10 \|.*probe-sandbox.*\| (todo|done) \| S8' "$m" || fail "master plan has no S10 row for the sandbox probes that depends on S8"
grep -Eq '^\| C-8 \| ' "$m" || fail "master plan has no C-8 contract row"
grep -q 'rule-grep.sh' <(grep '^| C-6 ' "$m") || fail "master plan C-6 does not name the rule row template"
[ "$(bin/rule-count.sh 2>/dev/null | awk '/^rule lines/ {print $3}')" -le 181 ] || fail "bin/rule-count.sh reports more than 181 rule lines"
exit 0
