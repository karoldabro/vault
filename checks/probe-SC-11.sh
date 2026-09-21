#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question. Hostile repository content.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/bin/probe.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$probe" ] && [ -r "$root/probes/registry.tsv" ] || { echo "the kit is not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
T=$(printf '\t')
marker="$tmp/pwned"
repo="$tmp/r\$(touch $marker)x"; mkdir -p "$repo/lib"
mkdir -p "$tmp/outside"; printf '[x](TOPSECRET-missing.md)\n' > "$tmp/outside/secret.md"
ln -s "$tmp/outside/secret.md" "$repo/leak.md"
ln -s "$tmp/outside" "$repo/linkdir"
printf '[x](gone.md)\n' > "$repo/real.md"
printf '[x](gone-tab.md)\n' > "$repo/a${T}b.md"
nl=$'\n'
printf '[x](gone-nl.md)\n' > "$repo/x${nl}md-links${T}forged.md${T}1${T}error${T}broken-link${T}forged${nl}.md"
printf 'nothing\n' > "$repo/lib/f.sh"
out=$("$probe" run plan --repo "$repo" 2>"$tmp/err"); rc=$?
case "$rc" in 0|1) ;; *) fail "expected exit 0 or 1, got $rc: $(head -5 "$tmp/err")" ;; esac
[ ! -e "$marker" ] || fail "a command inside the repo path ran"
printf '%s\n%s\n' "$out" "$(cat "$tmp/err")" | grep -q 'TOPSECRET' && fail "content of a symlink target reached the output"
printf '%s\n' "$out" | grep -q 'forged' && fail "a forged row reached stdout: $out"
bad=$(printf '%s\n' "$out" | awk -F'\t' 'NF && (NF != 6 || $4 !~ /^(error|warn|info)$/) { print }' | head -2)
[ -z "$bad" ] || fail "a row is malformed: $bad"
printf '%s\n' "$out" | awk -F'\t' '$2 == "real.md" { f = 1 } END { exit !f }' || fail "the ordinary broken link in real.md was not reported: $out"
# the same tree inside git: a symlink must not be listed either
git -C "$repo" init -q
git -C "$repo" add leak.md linkdir real.md >/dev/null 2>&1
out=$("$probe" run plan --repo "$repo" 2>"$tmp/err"); rc=$?
case "$rc" in 0|1) ;; *) fail "inside git: expected exit 0 or 1, got $rc: $(head -5 "$tmp/err")" ;; esac
printf '%s\n%s\n' "$out" "$(cat "$tmp/err")" | grep -q 'TOPSECRET' && fail "inside git: content of a symlink target reached the output"
printf '%s\n' "$out" | awk -F'\t' '$2 == "leak.md" || $2 ~ /^linkdir\// { f = 1 } END { exit f }' || fail "inside git: a symlink was read as a file: $out"
exit 0
