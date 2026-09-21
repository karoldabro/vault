#!/usr/bin/env bash
# SC-1 of vault/plans/2026-09-21-2040-pm-shard-contracts.md — the shard template through the gate.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
t="$root/templates/_features/project-shard.md"; gate="$root/bin/gate.sh"
[ -r "$t" ] && [ -x "$gate" ] || { echo "the shard template or the gate is missing — cannot say"; exit 2; }
git -C "$root" cat-file -e af5f530 2>/dev/null || { echo "commit af5f530 is not in this clone — cannot compare ## Consumed contract"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
grep -q '^| id | scope | command | status | depends | REQ covered | evidence | last touched | deviation |$' "$t" || fail "the shard Sessions header lacks depends after status"
grep -q '^## Cross-session contracts$' "$t" && grep -q '^| id | contract | produced by | consumed by | shape |$' "$t" || fail "the contracts section or its header is missing"
sed 's/{{[a-z]*}}/x/g' "$t" > "$tmp/shard.md"
out=$("$gate" master "$tmp/shard.md" 2>&1) || fail "the untouched instantiated template is refused: $out"
printf '%s' "$out" | grep -q '^master: ok ' || fail "no 'master: ok' for the instantiated template: $out"
sec() { awk '/^## Consumed contract$/{p=1;print;next} /^## /{p=0} p' "$1"; }
[ "$(sec "$t")" = "$(git -C "$root" show af5f530:templates/_features/project-shard.md | sec /dev/stdin)" ] || fail "## Consumed contract differs from commit af5f530"
# a filled copy: rows and contracts
awk '{print} /^\|----\|-------\|---------\|--------\|---------\|/{print "| S1 | first | /v-work | done | | REQ-01 | `x` | 2026-09-21 | |"; print "| S2 | second | /v-team | todo | S1 | REQ-02 | | 2026-09-21 | |"} /^\|----\|----------\|-------------\|-------------\|-------\|/{print "| C-1 | first output | S1 | S2 | `bin/first.sh` prints one line |"}' "$tmp/shard.md" > "$tmp/filled.md"
grep -q '^| S2 ' "$tmp/filled.md" && grep -q '^| C-1 ' "$tmp/filled.md" || fail "the grader could not insert rows into the instantiated template"
out=$("$gate" master "$tmp/filled.md" 2>&1) || fail "a filled shard is refused: $out"
sed '/^| C-1 /d' "$tmp/filled.md" > "$tmp/gap.md"
out=$("$gate" master "$tmp/gap.md" 2>&1); rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'S2 depends on S1 and no contract row is produced by S1 and consumed by S2' || fail "a shard that lost its contract row was not refused by pair: rc=$rc $out"
exit 0
