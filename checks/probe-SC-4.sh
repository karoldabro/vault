#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question. Runs the real harness probes on this repo.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/bin/probe.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$probe" ] && [ -r "$root/probes/registry.tsv" ] || { echo "the kit is not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
T=$(printf '\t')
det=$("$probe" detect --repo "$root" 2>&1) || fail "detect failed: $det"
for id in md-links dead-files token-size; do printf '%s\n' "$det" | grep -q "^$id${T}plan" || fail "detect on this repo misses $id: $det"; done
out=$("$probe" run plan --repo "$root" 2>"$tmp/err"); rc=$?
case "$rc" in 0|1) ;; *) fail "run plan exited $rc: $(head -5 "$tmp/err")" ;; esac
grep -q '^failed:' "$tmp/err" && fail "a probe failed: $(grep '^failed:' "$tmp/err" | head -3)"
[ -z "$out" ] && exit 0
bad=$(printf '%s\n' "$out" | awk -F'\t' 'NF != 6 || $4 !~ /^(error|warn|info)$/ || $3 !~ /^[0-9]+$/ { print NR": "$0 }' | head -3)
[ -z "$bad" ] || fail "invalid finding rows: $bad"
exit 0
