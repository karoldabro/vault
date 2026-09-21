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
"$render" "$tmp/plans/plan.md" --repo "$tmp/repo" >/dev/null 2>&1 || fail "render failed"
awk '/<pre class="mermaid">/ && !done { skip = 1 } !skip { print } /<\/pre>/ && skip { skip = 0; done = 1 }' "$page" > "$tmp/cut.html"
cmp -s "$page" "$tmp/cut.html" && fail "the fixture page held no mermaid block to remove"
mv "$tmp/cut.html" "$page"
out=$("$gate" human "$tmp/plans/plan.md" --repo "$tmp/repo" 2>&1); rc=$?
[ "$rc" -eq 1 ] || fail "a page missing a diagram: expected exit 1, got $rc: $out"
printf '%s' "$out" | grep -Eq 'line [0-9]+' || fail "refusal does not name a line: $out"
exit 0
