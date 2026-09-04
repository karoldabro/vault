#!/usr/bin/env bash
# SC-1 — every subcommand vault/architecture/session-gates.md documents is one the real dispatcher
# answers to, and every one the dispatcher answers to is documented.
#
# The names are enumerated from the `case` arms, then each is VERIFIED by invoking bin/gate.sh and
# checking the dispatcher does not reject it. Reading `bin/gate.sh --help` would prove nothing:
# usage() prints the hand-written comment block at the top of the file, which the dispatcher never
# consults, so a subcommand can vanish from the case arms while --help still advertises it.
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(dirname "$here")
gate="$root/bin/gate.sh"
doc="$root/vault/architecture/session-gates.md"

[ -x "$gate" ] || { printf 'no executable at %s\n' "$gate" >&2; exit 1; }
[ -r "$doc" ]  || { printf 'no document at %s\n' "$doc" >&2; exit 1; }

# Names the dispatcher claims, taken from its case arms and then proven one at a time.
declared=$(sed -n '/case "\$sub" in/,/^    esac/p' "$gate" |
           sed -n 's/^        \([a-z][a-z-]*\)).*/\1/p' | grep -vxE 'all' | sort -u)

implemented=""
while IFS= read -r sub; do
    [ -n "$sub" ] || continue
    out=$("$gate" "$sub" 2>&1)
    if grep -q 'unknown subcommand' <<<"$out"; then
        printf 'case arm exists but the dispatcher rejects it: %s\n' "$sub" >&2
        exit 1
    fi
    implemented="${implemented}${sub}"$'\n'
done <<<"$declared"
implemented=$(printf '%s' "$implemented" | sed '/^$/d' | sort -u)

# Names the document claims. First cell of the subcommand table, stripped of backticks, bold and
# any argument list. An escaped pipe inside a cell is the document's own style, so cut on the raw
# `|` only after the escaped ones are removed.
documented=$(awk '/^## The subcommands/{s=1;next} s&&/^## /{exit} s&&/^\|/{print}' "$doc" |
             sed 's/\\|/ /g' | cut -d'|' -f2 |
             tr -d '`*' | awk '{print $1}' |
             grep -xE '[a-z][a-z-]*' | grep -vxE 'subcommand|all' | sort -u)

[ -n "$documented" ] || { printf 'parsed zero subcommands out of %s — the table shape changed\n' "$doc" >&2; exit 1; }

fail=0
missing=$(comm -13 <(printf '%s\n' "$implemented") <(printf '%s\n' "$documented"))
extra=$(comm -23 <(printf '%s\n' "$implemented") <(printf '%s\n' "$documented"))
[ -n "$missing" ] && { printf 'documented, but the dispatcher rejects it: %s\n' "$(echo $missing)" >&2; fail=1; }
[ -n "$extra" ]   && { printf 'implemented, but the document never names it: %s\n' "$(echo $extra)" >&2; fail=1; }
exit "$fail"
