#!/usr/bin/env bash
# SC-5 — `rule-check.sh own-comments` keeps only comments whose forge user id equals the operator's id and whose
# type is User; a matching login with another id, a bot with the operator's id and a malformed id are not kept (D-13).
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
rc_=$root/bin/rule-check.sh
[ -x "$rc_" ] || { echo "bin/rule-check.sh not written yet"; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "jq is not installed"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
json='[
 {"id":1,"user":{"id":42,"login":"karol","type":"User"},"body":"mine","html_url":"https://x/1"},
 {"id":2,"user":{"id":99,"login":"karol","type":"User"},"body":"same login, other id","html_url":"https://x/2"},
 {"id":3,"user":{"id":42,"login":"karol-bot","type":"Bot"},"body":"bot with the same id","html_url":"https://x/3"},
 {"id":4,"user":{"id":7,"login":"someone","type":"User"},"body":"someone else","html_url":"https://x/4"},
 {"id":5,"user":{"id":42,"login":"karol","type":"User"},"body":"mine too","html_url":"https://x/5"},
 {"id":6,"user":null,"body":"ghost user","html_url":"https://x/6"},
 {"id":7,"user":{"id":42,"login":"karol","type":"User"},"body":"<!-- v-cr:summary --> derived from the diff","html_url":"https://x/7"},
 {"id":8,"user":{"id":42,"login":"karol","type":"User"},"body":"posted by an app","performed_via_github_app":{"id":1},"html_url":"https://x/8"}
]'
out=$(printf '%s' "$json" | "$rc_" own-comments --operator-id 42 2>/dev/null); rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0, got $rc"
ids=$(printf '%s' "$out" | jq -r '.[].id' 2>/dev/null | tr '\n' ' ')
[ "$ids" = "1 5 " ] || fail "expected comments 1 and 5 only, got: [$ids]"
out=$(printf '%s' '[]' | "$rc_" own-comments --operator-id 42 2>/dev/null); [ "$(printf '%s' "$out" | jq -r 'length')" = 0 ] || fail "an empty list must stay empty"
for bad in '4x' '' '-1' '4 2' '042x'; do
  printf '%s' "$json" | "$rc_" own-comments --operator-id "$bad" >/dev/null 2>&1; [ $? -eq 2 ] || fail "operator id '$bad' must exit 2"
done
printf '%s' "$json" | "$rc_" own-comments >/dev/null 2>&1; [ $? -eq 2 ] || fail "a missing --operator-id must exit 2"
printf 'not json' | "$rc_" own-comments --operator-id 42 >/dev/null 2>&1; [ $? -eq 2 ] || fail "input that is not JSON must exit 2"
printf '%s' '{"message":"Not Found"}' | "$rc_" own-comments --operator-id 42 >/dev/null 2>&1; [ $? -eq 2 ] || fail "a forge error object must exit 2, never read as no comments"
exit 0
