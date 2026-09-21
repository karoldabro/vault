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
sed -i 's/^| orders | status |/| orders | <script>alert(1)<\/script> \& "q" |/' "$tmp/arch/code-complete.arch.md"
sed -i 's/^Session S3 fixture\./Session <b>x<\/b> <script>y<\/script>./' "$tmp/plans/plan.md"
"$render" "$tmp/plans/plan.md" --repo "$tmp/repo" >/dev/null 2>"$tmp/err" || fail "render failed: $(cat "$tmp/err")"
grep -q '<script' "$page" && fail "the page holds a script tag"
grep -qF '&lt;script&gt;alert(1)&lt;/script&gt;' "$page" || fail "the script text is not shown as text in a spec cell"
grep -qF '&lt;b&gt;x&lt;/b&gt;' "$page" || fail "markup in a plan line is not shown as text"
grep -qF '&amp;' "$page" || fail "an ampersand is not escaped"
exit 0
