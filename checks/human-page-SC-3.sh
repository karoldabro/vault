#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
render="$root/bin/render-human.sh"; gate="$root/bin/gate.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf "%s\n" "$*"; exit 1; }
# shellcheck source=human-page-fixture.sh
. "$root/checks/human-page-fixture.sh"
# SC-3 of vault/plans/2026-09-24-1902-human-page-essentials.md: the Data flow diagram and an unlisted section's diagram reach the page.
hp_stage "$tmp"
"$render" "$tmp/plans/plan.md" --repo "$tmp/repo" >/dev/null 2>"$tmp/err" || fail "render failed: $(cat "$tmp/err")"
page="$tmp/plans/plan.human.html"
n=$(grep -c '<pre class="mermaid">' "$page"); er=$(grep -c '^ *erDiagram$' "$page")
[ $((n - er)) -ge 2 ] || fail "page holds $((n - er)) diagrams besides the erDiagram, want 2"
grep -qF 'OrderController' "$page" || fail "the Data flow diagram is missing"
grep -qF 'pipeline-xyz' "$page" || fail "the diagram of the unlisted Pipeline section is missing"
exit 0
