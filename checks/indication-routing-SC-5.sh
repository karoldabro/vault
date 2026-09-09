#!/usr/bin/env bash
# SC-5 — the delivery run: route real indexes, not the one index that cannot fail.
#
# This repo's own index is 32 of 32 routable, so measuring it alone proves nothing about the
# mechanism's hard cases. The two givore indexes carry the buckets that matter: an index with a
# large permanently-unroutable tail, and one whose rules are cross-repo contracts a path glob
# cannot reach. Each fixture has ONE accepted exit code.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
audit="$root/bin/indication-route-audit.sh"
GIVORE=${GIVORE:-$HOME/vault/givore/indications}
TAB=$(printf '\t')

[ -x "$audit" ] || { printf '  MISSING  %s does not exist yet\n' "$audit"; exit 1; }

fail=0
note() { printf '  FAIL  %s\n' "$1"; fail=1; }

# Fixture 1 — this repo: every row routable, exit 0.
out=$("$audit" "$root/vault/indications/_index.md" 2>&1); rc=$?
[ "$rc" -eq 0 ] || note "this repo's index exited $rc, expected 0 (every row is glob-shaped)"
printf '%s\n' "$out" | grep -qE 'unroutable[^0-9]+0' || note "this repo's index reported a non-zero unroutable count"

# Fixture 2 — a large real index with an unroutable tail: exit 1, and the tail is NAMED.
api="$GIVORE/api/_index.md"
if [ -r "$api" ]; then
    out=$("$audit" "$api" 2>&1); rc=$?
    [ "$rc" -eq 1 ] || note "givore api index exited $rc, expected 1 (it has an unroutable tail)"
    n=$(printf '%s\n' "$out" | grep -c '^unroutable')
    [ "$n" -ge 20 ] || note "givore api index named $n unroutable slugs, expected the tail to be listed"
else
    note "no readable index at $api — the delivery run needs a real project index, not a fixture"
fi

# Fixture 3 — cross-repo contract rules, which path globs structurally cannot reach.
cross="$GIVORE/cross-repo/_index.md"
if [ -r "$cross" ]; then
    out=$("$audit" "$cross" 2>&1); rc=$?
    [ "$rc" -eq 1 ] || note "givore cross-repo index exited $rc, expected 1"
    n=$(printf '%s\n' "$out" | grep -c '^unroutable')
    [ "$n" -ge 30 ] || note "givore cross-repo index named $n unroutable slugs, expected most of 44"
else
    note "no readable index at $cross"
fi

# Fixture 4 — the surface channel. Neither givore index above routes a single row on it, so the
# delivery run would still print OK with scope parsing deleted entirely. This is the row that fails
# when a declared surface stops being recognised, in either YAML spelling.
t=$(mktemp -d) || exit 1
trap 'rm -rf "$t"' EXIT
mkdir -p "$t/indications"
printf '| Slug | Rule | Applies-to |\n|--|--|--|\n| [[surface-rule]] | x | givore_app |\n' > "$t/indications/_index.md"
for form in inline block; do
    if [ "$form" = inline ]; then
        printf 'slug: t\nindication_scopes: [givore_app, cross-repo]\n' > "$t/VAULT.md"
    else
        printf 'slug: t\nindication_scopes:\n  - givore_app\n  - cross-repo\n' > "$t/VAULT.md"
    fi
    out=$("$audit" "$t/indications/_index.md" 2>&1); rc=$?
    [ "$rc" -eq 0 ] || note "a declared surface written in $form form exited $rc, expected 0"
    printf '%s\n' "$out" | grep -qE "unroutable${TAB}0" \
        || note "a declared surface written in $form form was reported unroutable"
done

[ "$fail" -eq 0 ] && printf '  OK  routing measured against three real indexes plus both scope spellings\n'
exit "$fail"
