#!/usr/bin/env bash
# rule-compliance SC-2: two runs over the same corpus print the same numbers.
set -uo pipefail
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
./bin/rule-audit.sh > "${tmp}/a" 2>&1 || { printf 'first run failed\n'; exit 1; }
./bin/rule-audit.sh > "${tmp}/b" 2>&1 || { printf 'second run failed\n'; exit 1; }
if ! diff -q "${tmp}/a" "${tmp}/b" >/dev/null; then
    printf 'two runs disagreed:\n%s\n' "$(diff "${tmp}/a" "${tmp}/b" | head -5)"
    exit 1
fi
printf 'two runs over the cached corpus printed identical output\n'
