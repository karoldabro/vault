#!/usr/bin/env bash
# SC-1 — the posture decides which repo code a review runs; --base has no default.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
panel="$root/bin/probe-panel.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$panel" ] || { echo "bin/probe-panel.sh not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
# fixture: a git repo with one commit; prints the repo path, the base commit is in $base
mkrepo() {
  local r=$1; mkdir -p "$r"
  git -C "$r" init -q && git -C "$r" config user.email t@t && git -C "$r" config user.name t
  printf "# ok\n" > "$r/a.md"; git -C "$r" add -A; git -C "$r" commit -qm base
  base=$(git -C "$r" rev-parse HEAD)
}
repo="$tmp/repo"; mkrepo "$repo"; mkdir -p "$repo/probes"
marker="$tmp/ran-repo-row"
printf 'rrow\tharness\tplan\ttrue\ttouch %s\tnative\tS\tno\tnone\n' "$marker" > "$repo/probes/registry.tsv"
git -C "$repo" add -A; git -C "$repo" commit -qm registry; base=$(git -C "$repo" rev-parse HEAD)
printf '# changed\n' >> "$repo/a.md"
run() { "$panel" run --repo "$repo" --base "$base" "$@" >"$tmp/out" 2>"$tmp/err"; }
run --posture pr;  [ ! -e "$marker" ] || fail "pr ran a repo registry row"
run --posture own; [ ! -e "$marker" ] || fail "own ran a repo registry row without PROBE_PANEL_REPO_CODE"
PROBE_PANEL_REPO_CODE=yes run --posture pr; [ ! -e "$marker" ] || fail "pr ran a repo registry row under PROBE_PANEL_REPO_CODE"
PROBE_PANEL_REPO_CODE=yes run --posture own; [ -e "$marker" ] || fail "own with PROBE_PANEL_REPO_CODE=yes did not run the repo row: $(cat "$tmp/err")"
# a framework row marked executes-repo-code: yes runs only when the operator opts in, and never under pr
fw="$tmp/fw"; mkdir -p "$fw"; cp -R "$root/bin" "$root/lib" "$root/probes" "$fw/"
ymark="$tmp/ran-yes-row"
printf 'zz-yes\tany\tplan\ttrue\ttouch %s\tnative\tS\tyes\tnone\n' "$ymark" >> "$fw/probes/registry.tsv"
yrun() { "$fw/bin/probe-panel.sh" run --repo "$repo" --base "$base" "$@" >"$tmp/out" 2>"$tmp/err"; }
yrun --posture pr;  [ ! -e "$ymark" ] || fail "pr ran a framework row marked yes"
yrun --posture own; [ ! -e "$ymark" ] || fail "own ran a framework row marked yes without PROBE_PANEL_REPO_CODE"
PROBE_PANEL_REPO_CODE=yes yrun --posture pr; [ ! -e "$ymark" ] || fail "pr ran a framework row marked yes under PROBE_PANEL_REPO_CODE"
PROBE_PANEL_REPO_CODE=yes yrun --posture own; [ -e "$ymark" ] || fail "own with PROBE_PANEL_REPO_CODE=yes did not run the yes row: $(cat "$tmp/err")"
"$panel" run --posture own --repo "$repo" >"$tmp/out" 2>"$tmp/err"; rc=$?
[ "$rc" -eq 2 ] || fail "run without --base: expected exit 2, got $rc"
"$panel" run --repo "$repo" --base "$base" >"$tmp/out" 2>"$tmp/err"; rc=$?
[ "$rc" -eq 2 ] || fail "run without --posture: expected exit 2, got $rc"
"$panel" run --posture sideways --repo "$repo" --base "$base" >"$tmp/out" 2>"$tmp/err"; rc=$?
[ "$rc" -eq 2 ] || fail "unknown posture: expected exit 2, got $rc"
exit 0
