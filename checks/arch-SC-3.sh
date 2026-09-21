#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"
fx="$root/tests/fixtures/arch"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
need() { [ -f "$1" ] || { printf "%s not written yet — cannot say\n" "${1#$root/}"; exit 2; }; }
# run <expected-exit> <stderr-must-contain> <args...>: runs the gate from the repo root
run() {
    local want=$1 word=$2; shift 2
    out=$(cd "$root" && "$gate" "$@" 2>&1); rc=$?
    [ "$rc" -eq "$want" ] || { printf "gate %s: expected exit %s, got %s\n%s\n" "$*" "$want" "$rc" "$out"; exit 1; }
    [ -z "$word" ] || printf "%s" "$out" | grep -qF -- "$word" || { printf "gate %s: output lacks: %s\n%s\n" "$*" "$word" "$out"; exit 1; }
}

need "$fx/code-complete.arch.md"
mkdir "$tmp/norepo"; printf 'dod_profile: code\n' > "$tmp/norepo/VAULT.md"
R="--repo $tmp/norepo"
sed 's/orderId: string/orderId/' "$fx/code-complete.arch.md" > "$tmp/c1.arch.md"
run 1 "OrderService.place" arch "$tmp/c1.arch.md" $R
run 1 "param orderId has no type" arch "$tmp/c1.arch.md" $R
sed '/^| orders | id /s/| PK |/| |/' "$fx/code-complete.arch.md" > "$tmp/c2.arch.md"
run 1 "table has no primary key" arch "$tmp/c2.arch.md" $R
run 1 "orders" arch "$tmp/c2.arch.md" $R
sed '/^| order_lines | order_id /s/ix_order_lines_order_id/-/' "$fx/code-complete.arch.md" > "$tmp/c3.arch.md"
run 1 "order_lines.order_id" arch "$tmp/c3.arch.md" $R
run 1 "foreign key has no index" arch "$tmp/c3.arch.md" $R
sed 's/| new | searched app\/ for `Number`; no generator exists |/| new | |/' "$fx/code-complete.arch.md" > "$tmp/c4.arch.md"
run 1 "order number" arch "$tmp/c4.arch.md" $R
exit 0
