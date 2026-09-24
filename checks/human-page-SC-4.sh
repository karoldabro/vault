#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
render="$root/bin/render-human.sh"; gate="$root/bin/gate.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf "%s\n" "$*"; exit 1; }
# shellcheck source=human-page-fixture.sh
. "$root/checks/human-page-fixture.sh"
# SC-4 of vault/plans/2026-09-24-1902-human-page-essentials.md: Data flow labels lose their parameter lists.
hp_stage "$tmp" 'OrderService.place(orderId: string, qty: (int, int))'
"$render" "$tmp/plans/plan.md" --repo "$tmp/repo" >/dev/null 2>"$tmp/err" || fail "render failed: $(cat "$tmp/err")"
page="$tmp/plans/plan.human.html"
grep -qF 'B["OrderService.place()"]' "$page" || fail "the Data flow label kept its parameters or lost its name"
grep -qF 'OrderService.place(orderId: string, qty: int): Order' "$page" || fail "the signature list lost the parameters"
grep -qF 'P["PROPOSE step (a)"]' "$page" || fail "a label with a space before ( lost its text"
exit 0
