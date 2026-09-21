#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/bin/probe.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$probe" ] && [ -r "$root/probes/registry.tsv" ] || { echo "the kit is not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
g() { command git -C "$repo" -c user.email=t@t -c user.name=t "$@"; }
repo="$tmp/repo"; mkdir -p "$repo"
g init -q
printf '[x](gone-a.md)\n' > "$repo/a.md"; printf '[x](gone-b.md)\n' > "$repo/b.md"
g add a.md b.md >/dev/null; g commit -q -m base
g config core.fsmonitor "touch $tmp/fsmonitor-ran; echo"
printf 'more\n' >> "$repo/a.md"; printf '[x](gone-c.md)\n' > "$repo/c.md"
out=$("$probe" diff --repo "$repo" --only md-links 2>"$tmp/err"); rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1, got $rc: $(cat "$tmp/err")"
printf '%s\n' "$out" | awk -F'\t' '$2 == "a.md" { a = 1 } $2 == "c.md" { c = 1 } $2 == "b.md" { b = 1 } END { exit !(a && c && !b) }' \
  || fail "diff must report a.md and untracked c.md and not the unchanged b.md: $out"
[ ! -e "$tmp/fsmonitor-ran" ] || fail "diff ran the repo's core.fsmonitor command"
plain="$tmp/plain"; mkdir -p "$plain"; printf '[x](gone.md)\n' > "$plain/a.md"
"$probe" diff --repo "$plain" --only md-links >/dev/null 2>"$tmp/err"; rc=$?
[ "$rc" -eq 2 ] || fail "outside git: expected exit 2, got $rc"
grep -qi 'git' "$tmp/err" || fail "outside git: stderr does not say why: $(cat "$tmp/err")"
exit 0
