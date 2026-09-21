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

need "$fx/harness-complete.arch.md"
sed 's#bin/gate.sh#bin/does-not-exist.sh#g' "$fx/harness-complete.arch.md" > "$tmp/c1.arch.md"
run 1 "path does not exist" arch "$tmp/c1.arch.md"
run 1 "bin/does-not-exist.sh" arch "$tmp/c1.arch.md"
sed 's#| checks/arch-SC-9.sh | yes |#| checks/arch-SC-9.sh | no |#' "$fx/harness-complete.arch.md" > "$tmp/c2.arch.md"
run 1 "checks/arch-SC-9.sh" arch "$tmp/c2.arch.md"
exit 0
