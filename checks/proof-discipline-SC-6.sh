#!/usr/bin/env bash
# SC-6 (delivery) — the shipped gate grades this plan, and refuses exactly one corrupted anchor.
#
# A run of the real system through the path this change serves. Two halves, because each covers the
# other's blind spot: a pass-everything stub survives the first, and a crash-on-everything stub
# survives a "nonzero means it bit" second half. So the refusal must be exit 1 — not the exit 2 that
# a usage error or an unparseable table returns — and it must name the anchor it rejected.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"
plan="$root/vault/plans/2026-09-13-1355-proof-discipline.md"   # fixed: a delivery check the environment can redirect grades another file
fail=0

[ -x "$gate" ] || { printf '  MISSING  %s\n' "$gate"; exit 1; }
[ -r "$plan" ] || { printf '  MISSING  %s\n' "$plan"; exit 1; }

out=$("$gate" claims "$plan" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then
    printf '  FAIL  `gate.sh claims` exited %s on its own plan\n%s\n' "$rc" "$out"; fail=1
fi

# Corrupt ONE claim row by id, so the prose that defines the grounds kinds is untouched and the
# refusal can only come from the anchor under test.
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
awk '$0 ~ /^\| C-3 \|/ { gsub(/:"[^"]*"/, ":\"zzz-no-such-token\"") } 1' "$plan" > "$tmp/broken.md"

if ! grep -q 'zzz-no-such-token' "$tmp/broken.md"; then
    printf '  FAIL  no C-3 anchor was corrupted — SC-6 cannot prove the gate bites\n'; fail=1
elif ! diff -q "$plan" "$tmp/broken.md" >/dev/null 2>&1; then
    bout=$("$gate" claims "$tmp/broken.md" 2>&1); brc=$?
    if [ "$brc" -ne 1 ]; then
        printf '  FAIL  `gate.sh claims` exited %s on a plan with one wrong anchor; a substantive refusal is exit 1\n%s\n' "$brc" "$bout"; fail=1
    elif ! printf '%s\n' "$bout" | grep -q 'C-3'; then
        printf '  FAIL  the refusal does not name C-3, so it may be refusing something else\n%s\n' "$bout"; fail=1
    fi
else
    printf '  FAIL  the corruption changed nothing in %s\n' "$plan"; fail=1
fi

[ "$fail" -eq 0 ] || exit 1
printf '  OK  the gate grades its own plan and refuses C-3 with exit 1\n'
