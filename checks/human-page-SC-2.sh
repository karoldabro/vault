#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
render="$root/bin/render-human.sh"; gate="$root/bin/gate.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf "%s\n" "$*"; exit 1; }
# shellcheck source=human-page-fixture.sh
. "$root/checks/human-page-fixture.sh"
# SC-2 of vault/plans/2026-09-24-1902-human-page-essentials.md: Data model as an erDiagram, Interfaces as signatures.
hp_stage "$tmp"
"$render" "$tmp/plans/plan.md" --repo "$tmp/repo" >/dev/null 2>"$tmp/err" || fail "render failed: $(cat "$tmp/err")"
page="$tmp/plans/plan.human.html"
grep -qx 'erDiagram' "$page" || grep -q '^ *erDiagram$' "$page" || fail "no erDiagram on the page"
grep -Eq '^ *orders \{$' "$page" || fail "no entity for table orders"
grep -Eq '^ *order_lines \{$' "$page" || fail "no entity for table order_lines"
grep -Eq '^ *orders \|\|--o\{ order_lines : order_id$' "$page" || fail "no line orders ||--o{ order_lines : order_id"
grep -qF 'OrderService.place(orderId: string, qty: int): Order' "$page" || fail "no signature line for OrderService.place"
grep -qF 'OrderRepository.save(order: Order): void' "$page" || fail "no signature line for OrderRepository.save"
if grep -qF '<th>interface</th>' "$page"; then fail "Interfaces still render as a table"; fi
if grep -qF '<th>table</th>' "$page"; then fail "Data model still renders as a table"; fi
exit 0
