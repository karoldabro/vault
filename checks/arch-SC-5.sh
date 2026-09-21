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

plan="$root/vault/plans/2026-09-21-0900-architecture-first-planning.md"
need "$fx/harness-complete.arch.md"; need "$plan"
# (a) the real phase entry, on the real plan, reaches the arch check
run 0 "arch: ok" all "$plan" --phase propose
# (b) a repo that declares a profile refuses a plan naming no arch_spec
mkdir -p "$tmp/r1" "$tmp/r2"
printf 'arch_profile: harness\n' > "$tmp/r1/VAULT.md"
printf '%s\n' '---' 'type: plan' '---' '# p' > "$tmp/r1/plan.md"
cp "$tmp/r1/plan.md" "$tmp/r2/plan.md"
run 1 "names no arch_spec" arch "$tmp/r1/plan.md" --repo "$tmp/r1"
# (c) a repo with no profile skips a plan that names none
printf 'dod_profile: code\n' > "$tmp/r2/VAULT.md"
out=$(cd "$root" && "$gate" arch "$tmp/r2/plan.md" --repo "$tmp/r2" 2>&1); rc=$?
[ "$rc" -eq 0 ] && ! printf '%s' "$out" | grep -q 'arch: ok' || { printf 'unprofiled repo: expected silent exit 0, got rc=%s: %s\n' "$rc" "$out"; exit 1; }
# (d) a spec whose profile differs from the repo's is refused
printf 'arch_profile: code\n' > "$tmp/r2/VAULT.md"
cp "$fx/harness-complete.arch.md" "$tmp/r2/x.arch.md"
run 1 "profile" arch "$tmp/r2/x.arch.md" --repo "$tmp/r2"
exit 0
