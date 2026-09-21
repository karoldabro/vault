#!/usr/bin/env bash
# SC-1 — `probe.sh diff --changed-list <file>` reads the changed files from the list and runs no git, and
# PROBE_TOOLS_FROM=image keeps the repo's tool directories out of PATH.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe=$root/bin/probe.sh
grep -q -- '--changed-list' "$probe" || { echo "probe.sh has no --changed-list yet"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
R=$tmp/r; mkdir -p "$R" "$tmp/shim"
printf '[a](missing-a.md)\n' > "$R/x.md"; printf '[b](missing-b.md)\n' > "$R/y.md"
printf '#!/bin/sh\necho "$@" >> %s/git.log\nexit 99\n' "$tmp" > "$tmp/shim/git"; chmod +x "$tmp/shim/git"
run() { PATH="$tmp/shim:$PATH" "$probe" "$@"; }

printf 'x.md\0' > "$tmp/list"
out=$(run diff --repo "$R" --changed-list "$tmp/list" --only md-links 2>"$tmp/err"); rc=$?
[ "$rc" -eq 1 ] || fail "a changed file with a broken link must exit 1 (rc $rc): $(cat "$tmp/err")"
printf '%s\n' "$out" | awk -F'\t' '$2=="x.md"{f=1} $2=="y.md"{g=1} END{exit !(f && !g)}' || fail "rows must cover x.md only: $out"
[ ! -s "$tmp/git.log" ] || fail "git ran under --changed-list: $(cat "$tmp/git.log")"

printf '' > "$tmp/empty"
out=$(run diff --repo "$R" --changed-list "$tmp/empty" --only md-links 2>/dev/null); rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] || fail "an empty list must give no rows and exit 0 (rc $rc): $out"
printf '../x.md\0/etc/passwd\0gone.md\0' > "$tmp/bad"
out=$(run diff --repo "$R" --changed-list "$tmp/bad" --only md-links 2>/dev/null); rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] || fail "an escaping, absolute or missing path must be dropped (rc $rc): $out"

run diff --repo "$R" --changed-list "$tmp/nope" --only md-links >/dev/null 2>&1; [ $? -eq 2 ] || fail "an unreadable list must exit 2"
run diff --repo "$R" --changed-list "$tmp/list" --base HEAD >/dev/null 2>&1; [ $? -eq 2 ] || fail "--changed-list with --base must exit 2"
run run plan --repo "$R" --changed-list "$tmp/list" >/dev/null 2>&1; [ $? -eq 2 ] || fail "--changed-list on run must exit 2"

# PROBE_TOOLS_FROM=image
T=$tmp/t; mkdir -p "$T/.venv-probes/bin"; printf '[default]\n' > "$T/_typos.toml"
printf '#!/bin/sh\ntouch %s/marker\nprintf "[]"\n' "$tmp" > "$T/.venv-probes/bin/typos"; chmod +x "$T/.venv-probes/bin/typos"
command -v typos >/dev/null 2>&1 && { echo "typos is on PATH here, so the grader cannot tell"; exit 2; }
out=$(run list --repo "$T" | awk -F'\t' '$1=="typos"{print $5}')
[ "$out" = ok ] || fail "without the variable a repo-local typos must be found by list (got: $out)"
out=$(PROBE_TOOLS_FROM=image run list --repo "$T" | awk -F'\t' '$1=="typos"{print $5}')
case $out in absent:*) ;; *) fail "PROBE_TOOLS_FROM=image must report typos absent (got: $out)" ;; esac
rm -f "$tmp/marker"
printf 'x\n' > "$T/a.txt"; printf 'a.txt\0' > "$tmp/l2"
PROBE_TOOLS_FROM=image run diff --repo "$T" --changed-list "$tmp/l2" --only typos >/dev/null 2>"$tmp/err2"; rc=$?
[ ! -e "$tmp/marker" ] || fail "the repo-local tool ran under PROBE_TOOLS_FROM=image"
grep -q '^absent: typos: ' "$tmp/err2" && [ "$rc" -eq 2 ] || fail "typos must read absent and exit 2 (rc $rc): $(cat "$tmp/err2")"
PROBE_TOOLS_FROM=repo run list --repo "$T" >/dev/null 2>&1; [ $? -eq 2 ] || fail "a value other than image must exit 2"
PROBE_TOOLS_FROM= run list --repo "$T" >/dev/null 2>&1 || fail "an empty PROBE_TOOLS_FROM must read as unset"
exit 0
