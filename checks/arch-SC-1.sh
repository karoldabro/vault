#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"
fx="$root/tests/fixtures/arch"

doc="$root/vault/research/ai-code-slop.md"
[ -f "$doc" ] || { printf 'ai-code-slop.md not written yet — cannot say\n'; exit 2; }
for n in 1 2 3 4 5 6 7 8; do
    sec=$(awk -v n="$n" '$0 ~ "^### M"n"( |$)"{f=1;next} /^### M[0-9]/{f=0} /^## /{f=0} f' "$doc")
    [ -n "$sec" ] || { printf 'mechanism M%s missing\n' "$n"; exit 1; }
    printf '%s' "$sec" | grep -Eq 'https?://' || { printf 'M%s has no source URL\n' "$n"; exit 1; }
    printf '%s' "$sec" | grep -Eq '^verified: (primary|summary-only)' || { printf 'M%s has no verified: field\n' "$n"; exit 1; }
done
exit 0
