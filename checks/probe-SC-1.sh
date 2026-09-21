#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question (vault/indications/unreadable-is-not-no.md).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/bin/probe.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$probe" ] || { echo "bin/probe.sh not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
T=$(printf '\t')
repo="$tmp/repo"; mkdir -p "$repo/probes"
: > "$repo/present-marker"
row() { printf '%s\n' "$1${T}$2${T}$3${T}$4${T}$5${T}native${T}S${T}no${T}$6"; }
{
  row here    harness plan 'test -e present-marker' 'printf ""' 'none'
  row nothere sql     plan 'test -e absent-marker'  'printf ""' 'none'
  row notool  harness plan 'true' 'no-such-tool-xyz --x' 'python3 -m venv .v && .v/bin/pip install no-such-tool-xyz'
} > "$repo/probes/registry.tsv"
list=$("$probe" list --repo "$repo" --allow-repo-registry 2>&1) || fail "list exited nonzero: $list"
for id in here nothere notool; do printf '%s\n' "$list" | grep -q "^$id${T}" || fail "list has no line for $id: $list"; done
printf '%s\n' "$list" | grep "^here${T}"   | grep -q "${T}ok\$"  || fail "here is not ok: $list"
printf '%s\n' "$list" | grep "^notool${T}" | grep -q "${T}absent: python3 -m venv .v && .v/bin/pip install no-such-tool-xyz\$" || fail "notool does not print its install command: $list"
det=$("$probe" detect --repo "$repo" --allow-repo-registry 2>&1) || fail "detect exited nonzero: $det"
printf '%s\n' "$det" | grep -q '^here'    || fail "detect misses a present stack: $det"
printf '%s\n' "$det" | grep -q '^notool'  || fail "detect misses notool, whose stack is present: $det"
printf '%s\n' "$det" | grep -q '^nothere' && fail "detect names a probe whose stack is absent: $det"
none=$("$probe" list --repo "$repo" 2>&1)
printf '%s\n' "$none" | grep -q "^here${T}" && fail "list read the repo registry without --allow-repo-registry: $none"
exit 0
