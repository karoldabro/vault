#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"; render="$root/bin/render-human.sh"
fx="$root/tests/fixtures"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
need() { [ -e "$1" ] || { printf "%s not written yet — cannot say\n" "${1#$root/}"; exit 2; }; }
# stage: copy the fixture plan and the spec it names into $tmp/plans and $tmp/arch, so a case may edit them
stage() {
    mkdir -p "$tmp/plans" "$tmp/arch" "$tmp/repo"
    cp "$fx/human/plan.md" "$tmp/plans/plan.md"; cp "$fx/arch/code-complete.arch.md" "$tmp/arch/code-complete.arch.md"
    printf "dod_profile: code\n" > "$tmp/repo/VAULT.md"
    page="$tmp/plans/plan.human.html"
}
fail() { printf "%s\n" "$*"; exit 1; }

need "$render"; need "$fx/human/plan.md"; stage
"$render" "$tmp/plans/plan.md" --repo "$tmp/repo" >/dev/null 2>"$tmp/err" || fail "render failed: $(cat "$tmp/err")"
[ -f "$page" ] || fail "no page written at plans/plan.human.html"
spec="$tmp/arch/code-complete.arch.md"
while IFS= read -r h; do
    esc=$(printf '%s' "${h#\#\# }" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    grep -qF "<h2>${esc}</h2>" "$page" || fail "section heading missing from the page: $h"
done < <(grep '^## ' "$spec")
want=$(grep -c '^```mermaid' "$spec"); got=$(grep -c '<pre class="mermaid">' "$page")
[ "$got" -ge "$want" ] || fail "spec has $want mermaid blocks, page has $got"
for v in orders order_lines OrderController OrderService OrderRepository; do grep -qF "$v" "$page" || fail "value missing from the page: $v"; done
review=$(grep -m1 '^@review' "$root/arch-profiles/code.tsv" | cut -f2)
[ -n "$review" ] || fail "arch-profiles/code.tsv has no @review line"
grep -qF "Check these yourself" "$page" || fail "no review checklist heading"
grep -qF "$review" "$page" || fail "review line missing from the page: $review"
exit 0
