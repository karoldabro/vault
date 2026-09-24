#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
render="$root/bin/render-human.sh"; fx="$root/tests/fixtures"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
need() { [ -e "$1" ] || { printf "%s not written yet — cannot say\n" "${1#$root/}"; exit 2; }; }
fail() { printf '%s\n' "$*"; exit 1; }
need "$render"; need "$fx/human/plan.md"
mkdir -p "$tmp/plans" "$tmp/arch" "$tmp/repo"
cp "$fx/human/plan.md" "$tmp/plans/plan.md"; printf 'dod_profile: code\n' > "$tmp/repo/VAULT.md"
awk '{ print } /^```mermaid/ && ++seen == 2 { print "click A href \"javascript:alert(1)\""; print "%%{init: {\"securityLevel\": \"loose\"}}%%"; print "A --> B %% see javascript:x"; done = 1 }' "$fx/arch/code-complete.arch.md" > "$tmp/arch/code-complete.arch.md"
grep -q 'javascript:' "$tmp/arch/code-complete.arch.md" || fail "the staged spec holds no hostile line to remove"
"$render" "$tmp/plans/plan.md" --repo "$tmp/repo" >/dev/null 2>"$tmp/err" || fail "render failed: $(cat "$tmp/err")"
page="$tmp/plans/plan.human.html"
grep -q 'click A' "$page" && fail "a click line reached the page"
grep -q '%%{' "$page" && fail "a %% directive reached the page"
grep -q 'javascript:' "$page" && fail "a javascript: line reached the page"
grep -qF -- '-->|StoreOrderRequest|' "$page" || fail "the legitimate diagram lines were lost with the hostile ones"
exit 0
