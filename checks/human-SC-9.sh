#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"
plan="$root/vault/plans/2026-09-21-0900-architecture-first-planning.md"
page="$root/vault/plans/2026-09-21-0900-architecture-first-planning.human.html"
fail() { printf '%s\n' "$*"; exit 1; }
[ -x "$root/bin/render-human.sh" ] || { printf 'bin/render-human.sh not written yet — cannot say\n'; exit 2; }
out=$(cd "$root" && "$gate" human "$plan" 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail "gate human refused the master plan (exit $rc): $out"
printf '%s' "$out" | grep -qF 'human: ok' || fail "no human: ok line: $out"
n=$(grep -c '<pre class="mermaid">' "$page"); [ "$n" -ge 4 ] || fail "the regenerated master page holds $n diagrams, the master plan has 4"
out=$(cd "$root" && "$gate" all "$plan" --phase approve 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail "approve phase refused the master plan (exit $rc): $out"
printf '%s' "$out" | grep -qF 'human: ok' || fail "approve phase did not reach the human check: $out"
exit 0
