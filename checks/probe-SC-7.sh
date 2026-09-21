#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/bin/probe.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$probe" ] || { echo "bin/probe.sh not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
T=$(printf '\t')
repo="$tmp/repo"; mkdir -p "$repo/probes"
git -C "$repo" init -q; for i in 1 2 3; do printf 'line\n' > "$repo/f$i.txt"; done
cat > "$repo/probes/registry.tsv" <<EOF2
cheap${T}harness${T}plan${T}true${T}touch $tmp/ran-cheap${T}native${T}S${T}no${T}none
mid${T}harness${T}plan${T}true${T}touch $tmp/ran-mid${T}native${T}M${T}no${T}none
EOF2
git -C "$repo" add f1.txt f2.txt f3.txt probes/registry.tsv >/dev/null 2>&1
sc() { PROBE_SCALE_L=$1 PROBE_SCALE_M=$2 "$probe" scale --repo "$repo" --allow-repo-registry 2>&1; }
out=$(sc 10 20) || fail "scale failed: $out"
printf '%s\n' "$out" | grep -q "^files${T}4\$" || fail "files line is not 4 (three files and the registry): $out"
printf '%s\n' "$out" | grep -q "^max-cost${T}L\$" || fail "4 files with L limit 10 should give L: $out"
out=$(sc 3 20); printf '%s\n' "$out" | grep -q "^max-cost${T}M\$" || fail "4 files, L limit 3, M limit 20 should give M: $out"
out=$(sc 2 3);  printf '%s\n' "$out" | grep -q "^max-cost${T}S\$" || fail "4 files, M limit 3 should give S: $out"
printf '%s\n' "$(sc 10 20)" | grep -q "^lines${T}[0-9]" || fail "no lines line"
"$probe" run plan --repo "$repo" --allow-repo-registry --max-cost S >/dev/null 2>"$tmp/err"
[ -e "$tmp/ran-cheap" ] || fail "the S row did not run"
[ ! -e "$tmp/ran-mid" ] || fail "the M row ran under --max-cost S"
grep -q '^skipped: mid' "$tmp/err" || fail "stderr does not say mid was skipped: $(cat "$tmp/err")"
exit 0
