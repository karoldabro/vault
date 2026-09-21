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
grep -q 'flowchart' "$page" || fail "no flowchart in the page"
for node in 'S1["S1 first"]' 'S2["S2 second"]' 'S3["S3 third"]'; do grep -qF "$node" "$page" || fail "node line missing: $node"; done
for edge in 'S1 --> S2' 'S1 --> S3' 'S2 --> S3'; do grep -qF "$edge" "$page" || fail "edge missing: $edge"; done
grep -qF 'S1 --> S1' "$page" && fail "a self edge was drawn"
exit 0
