#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
render="$root/bin/render-human.sh"; gate="$root/bin/gate.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf "%s\n" "$*"; exit 1; }
# shellcheck source=human-page-fixture.sh
. "$root/checks/human-page-fixture.sh"
# SC-1 of vault/plans/2026-09-24-1902-human-page-essentials.md: only operator-facing content reaches the page.
hp_stage "$tmp"
"$render" "$tmp/plans/plan.md" --repo "$tmp/repo" >/dev/null 2>"$tmp/err" || fail "render failed: $(cat "$tmp/err")"
page="$tmp/plans/plan.human.html"
for v in "Build the thing" row-uservis-xyz row-needs-xyz bullet-boldop-xyz bullet-deferop-xyz bullet-uservis-xyz q-defaulted-xyz a-defaulted-xyz crit-observed-xyz plan.md s.arch.md "Needs your decision" "Users will notice" "Defaults taken for you" "Checks you run yourself"; do
    grep -qF -- "$v" "$page" || fail "missing from the page: $v"
done
for v in cont-open-xyz prose-open-xyz bullet-multi-xyz row-open-xyz bullet-blocked-xyz q-answered-xyz evidence-xyz ">MET<" row-accepted-xyz bullet-deferred-xyz crit-command-xyz secretkw dec-xyz layer-xyz reuse-xyz "Check these yourself" "<h2>Decisions" "<h2>Layers" "<h2>Reuse map" "<h2>Size budgets" "<h2>Files" "<h2>Load order" "<h2>Config points"; do
    if grep -qF -- "$v" "$page"; then fail "on the page but should not be: $v"; fi
done
[ "$(grep -c row-blockop-xyz "$page")" -eq 1 ] || fail "row-blockop-xyz must appear exactly once"
[ "$(grep -c row-needs-xyz "$page")" -eq 1 ] || fail "row-needs-xyz must appear exactly once"
exit 0
