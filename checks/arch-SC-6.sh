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

need "$root/templates/arch.md"; need "$root/templates/arch-harness.md"
caps=$("$root/bin/doc-lint.sh" --list-caps)
printf '%s\n' "$caps" | grep -q '^arch-spec ' || { printf 'type arch-spec not listed by --list-caps\n'; exit 1; }
for f in templates/arch.md templates/arch-harness.md tests/fixtures/arch/code-complete.arch.md tests/fixtures/arch/harness-complete.arch.md; do
    "$root/bin/doc-lint.sh" "$root/$f" >/dev/null 2>&1 || { printf '%s fails doc-lint\n' "$f"; exit 1; }
done
{ sed -n '1,/^## Data model/p' "$fx/code-complete.arch.md"; for i in $(seq 1 310); do printf 'line %s\n' "$i"; done; } > "$tmp/long.arch.md"
"$root/bin/doc-lint.sh" "$tmp/long.arch.md" >/dev/null 2>&1 && { printf 'a 310-line arch-spec passed the cap\n'; exit 1; }
exit 0
