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

need "$fx/code-complete.arch.md"; need "$fx/harness-complete.arch.md"
mkdir "$tmp/norepo"; printf 'dod_profile: code\n' > "$tmp/norepo/VAULT.md"
run 0 "arch: ok" arch "$fx/code-complete.arch.md" --repo "$tmp/norepo"
run 0 "arch: ok" arch "$fx/harness-complete.arch.md"
awk '/^## Data model$/{skip=1;next} /^## /{skip=0} !skip' "$fx/code-complete.arch.md" > "$tmp/c1.arch.md"
run 1 "missing section Data model" arch "$tmp/c1.arch.md" --repo "$tmp/norepo"
awk '/^## Load order$/{skip=1;next} /^## /{skip=0} !skip' "$fx/harness-complete.arch.md" > "$tmp/c2.arch.md"
run 1 "missing section Load order" arch "$tmp/c2.arch.md"
sed '/^type:/d' "$fx/code-complete.arch.md" > "$tmp/c3.arch.md"
run 1 "frontmatter needs type: arch-spec" arch "$tmp/c3.arch.md" --repo "$tmp/norepo"
exit 0
