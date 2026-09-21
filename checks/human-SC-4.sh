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
run() { # <human_plan value> <expected exit> <substring>
    sed "s|^human_plan:.*|human_plan: $1|" "$fx/human/plan.md" > "$tmp/plans/plan.md"
    out=$("$gate" human "$tmp/plans/plan.md" --repo "$tmp/repo" 2>&1); rc=$?
    [ "$rc" -eq "$2" ] || fail "human_plan '$1': expected exit $2, got $rc: $out"
    [ -z "$3" ] || printf '%s' "$out" | grep -qF -- "$3" || fail "human_plan '$1': output lacks '$3': $out"
}
run "https://claude.ai/artifact/LHVhsU2fsQWNFpJTH6NKuC" 0 "human: ok"
run "file:plan.human.html" 0 "human: ok"
run "" 1 "names no human_plan"
run "http://claude.ai/artifact/abc" 1 "human_plan must be"
run "https://claude.ai/artifact/" 1 "human_plan must be"
run "https://example.com/artifact/abc" 1 "human_plan must be"
run "file:other.html" 1 "human_plan must be"
rm -f "$page"; run "file:plan.human.html" 1 "page is missing"
exit 0
