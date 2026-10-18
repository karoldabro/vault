#!/usr/bin/env bash
# SC-7 of vault/plans/2026-10-18-1257-quality-loops.md — delivery: two real repos run through bin/vault-check.sh on the host.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
fail() { printf '%s\n' "$*"; exit 1; }
[ -x bin/vault-check.sh ] || fail "bin/vault-check.sh is missing"
# run <stage> <repo> <allowed exits regex> [<required output regex>]
run() {
    local stage=$1 repo=$2 want=$3 need=${4:-} out rc=0
    [ -r "$repo/VAULT.md" ] || { echo "$repo/VAULT.md is unreadable"; exit 2; }
    out=$(bin/vault-check.sh "$stage" --repo "$repo" --base HEAD 2>&1) || rc=$?
    printf '%s %s exit %s\n%s\n' "$stage" "$repo" "$rc" "$(printf '%s\n' "$out" | tail -4)"
    [[ $rc =~ ^($want)$ ]] || fail "$stage on $repo exited $rc, wanted $want"
    grep -qi 'fallback' <<<"$out" || fail "$stage on $repo printed no fallback note"
    [ -z "$need" ] || grep -qiE "$need" <<<"$out" || fail "$stage on $repo did not print $need"
}
run static "$HOME/workspace/recycling-api" '0|1'
run tests  "$HOME/workspace/recycling-api" '2' 'template'
run tests  /media/kdabrow/Programy/vivi    '0|1' 'unmeasured.*coverage'
exit 0
