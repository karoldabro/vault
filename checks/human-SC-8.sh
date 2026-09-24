#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"
plan="$root/vault/plans/2026-09-21-1100-human-plan-page.md"
page="$root/vault/plans/2026-09-21-1100-human-plan-page.human.html"
fail() { printf '%s\n' "$*"; exit 1; }
[ -f "$page" ] || { printf 'the page for this plan is not rendered yet — cannot say\n'; exit 2; }
out=$(cd "$root" && "$gate" human "$plan" 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail "gate human refused this plan (exit $rc): $out"
printf '%s' "$out" | grep -qF 'human: ok' || fail "no human: ok line: $out"
grep -qF '<pre class="mermaid">' "$page" || fail "the real page holds no diagram"
exit 0
