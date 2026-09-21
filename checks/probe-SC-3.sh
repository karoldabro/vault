#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/bin/probe.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$probe" ] || { echo "bin/probe.sh not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
repo="$tmp/repo"; mkdir -p "$repo/probes"; marker="$tmp/installed-marker"
printf 'needs-tool\tharness\tplan\ttrue\tno-such-tool-xyz --x\tnative\tS\tno\ttouch %s\n' "$marker" > "$repo/probes/registry.tsv"
out=$("$probe" run plan --repo "$repo" --allow-repo-registry 2>"$tmp/err"); rc=$?
[ "$rc" -eq 2 ] || fail "expected exit 2, got $rc"
grep -q "^absent: needs-tool: touch $marker\$" "$tmp/err" || fail "stderr has no absent line with the install command: $(cat "$tmp/err")"
[ ! -e "$marker" ] || fail "the install command ran and created $marker"
[ -z "$out" ] || fail "stdout is not empty: $out"
[ -z "$(find "$repo" -newer "$repo/probes/registry.tsv" -type f 2>/dev/null)" ] || fail "the run created a file in the repo: $(find "$repo" -newer "$repo/probes/registry.tsv" -type f)"
exit 0
