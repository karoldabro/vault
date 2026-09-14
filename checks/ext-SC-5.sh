#!/usr/bin/env bash
# SC-5 — a plugin naming a point this framework does not implement is refused
#
# Exit 1 when the cases below fail. Exit 2 when the suite could not run, so "I could not read
# the question" never reports as "the answer is no" (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
suite="$root/tests/unit/plugin-registry.bats"
cases=(
    "a plugin naming an unimplemented point is refused and the point is named"
    "a plugin declaring only init and dod-keys registers"
)

if [ ! -f "$suite" ]; then
    printf 'plugin-registry.bats: suite not written yet — cannot say\n'; exit 2
fi
out=$(cd "$root" && ./tests/run.sh tests/unit/plugin-registry.bats 2>&1); rc=$?
if [ "$rc" -eq 2 ] || printf '%s' "$out" | grep -q 'docker not found'; then
    printf 'plugin-registry.bats: suite could not run (rc=%s)\n' "$rc"; exit 2
fi
missing=0; failed=0
for c in "${cases[@]}"; do
    if printf '%s\n' "$out" | grep -F 'not ok' | grep -qF "$c"; then
        printf '  FAILING  %s\n' "$c"; failed=$((failed + 1))
    elif ! printf '%s\n' "$out" | grep -qF "$c"; then
        printf '  ABSENT   %s\n' "$c"; missing=$((missing + 1))
    fi
done
if [ "$missing" -ne 0 ]; then
    printf 'plugin-registry.bats: %s of %s cases not written\n' "$missing" "${#cases[@]}"; exit 1
fi
if [ "$failed" -ne 0 ]; then
    printf 'plugin-registry.bats: %s of %s cases failing\n' "$failed" "${#cases[@]}"; exit 1
fi
printf 'plugin-registry.bats: %s of %s cases passing\n' "${#cases[@]}" "${#cases[@]}"
