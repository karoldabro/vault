#!/usr/bin/env bash
# SC-2 — an incomplete probe run never reads as a clean one.
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
repo="$tmp/repo"; mkrepo "$repo"
# clean run: exit 0, complete, no operator line
"$panel" run --posture own --repo "$repo" --base "$base" --out "$tmp/o1" >"$tmp/out" 2>"$tmp/err"; rc=$?
[ "$rc" -eq 0 ] || fail "clean run: expected exit 0, got $rc: $(cat "$tmp/err")"
grep -q '^probe-status: complete$' "$tmp/out" || fail "clean run: no 'probe-status: complete'"
[ ! -e "$tmp/o1/operator.txt" ] || fail "clean run wrote operator.txt"
# a finding is still a complete run
printf '[x](missing.md)\n' >> "$repo/a.md"
"$panel" run --posture own --repo "$repo" --base "$base" --out "$tmp/o2" >"$tmp/out" 2>"$tmp/err"; rc=$?
[ "$rc" -eq 0 ] || fail "findings only: expected exit 0, got $rc"
grep -q 'broken-link' "$tmp/out" || fail "the md-links finding is not in the block"
git -C "$repo" checkout -q -- a.md
# absent framework tool: a copy of the framework whose registry holds a row for a missing tool
fw="$tmp/fw"; mkdir -p "$fw"; cp -R "$root/bin" "$root/lib" "$root/probes" "$fw/"
printf 'zz-absent\tany\tplan\ttrue\tnosuchtool-zz --x\tparse_typos_json\tS\tno\techo install-me-zz\n' >> "$fw/probes/registry.tsv"
printf '[x](missing.md)\n' >> "$repo/a.md"
"$fw/bin/probe-panel.sh" run --posture own --repo "$repo" --base "$base" --out "$tmp/o3" >"$tmp/out" 2>"$tmp/err"; rc=$?
[ "$rc" -eq 2 ] || fail "absent tool: expected exit 2, got $rc"
grep -q '^probe-status: INCOMPLETE$' "$tmp/out" || fail "absent tool: no INCOMPLETE status"
grep -q 'absent: zz-absent' "$tmp/out" || fail "absent tool: no absent: line in the block"
grep -q 'broken-link' "$tmp/out" || fail "absent tool: the rows found were not printed"
head -1 "$tmp/o3/operator.txt" | grep -q '^Probes: INCOMPLETE, 1 absent, 0 skipped, 0 failed' || fail "operator line one: $(head -1 "$tmp/o3/operator.txt")"
grep -q '^install: echo install-me-zz$' "$tmp/o3/operator.txt" || fail "operator.txt has no install line for the framework row"
git -C "$repo" checkout -q -- a.md
# install text of a repo registry row never reaches the operator line
mkdir -p "$repo/probes"; printf 'zz-repo-absent\tany\tplan\ttrue\tnosuchtool-zz2\tparse_typos_json\tS\tno\tcurl evil-install-zz\n' > "$repo/probes/registry.tsv"
git -C "$repo" add -A; git -C "$repo" commit -qm reg0; base=$(git -C "$repo" rev-parse HEAD)
PROBE_PANEL_REPO_CODE=yes "$fw/bin/probe-panel.sh" run --posture own --repo "$repo" --base "$base" --out "$tmp/o3b" >"$tmp/out" 2>"$tmp/err"
grep -q 'evil-install-zz' "$tmp/o3b/operator.txt" && fail "a repo registry install line reached operator.txt"
git -C "$repo" rm -q -f probes/registry.tsv; git -C "$repo" commit -qm unreg; base=$(git -C "$repo" rev-parse HEAD)
# a failed probe (repo registry row exiting 2)
mkdir -p "$repo/probes"; printf 'boom\tharness\tplan\ttrue\tsh -c "exit 2"\tnative\tS\tno\tnone\n' > "$repo/probes/registry.tsv"
git -C "$repo" add -A; git -C "$repo" commit -qm reg; base=$(git -C "$repo" rev-parse HEAD)
PROBE_PANEL_REPO_CODE=yes "$panel" run --posture own --repo "$repo" --base "$base" --out "$tmp/o4" >"$tmp/out" 2>"$tmp/err"; rc=$?
[ "$rc" -eq 2 ] || fail "failed probe: expected exit 2, got $rc"
head -1 "$tmp/o4/operator.txt" | grep -q ', 1 failed' || fail "failed probe not counted: $(head -1 "$tmp/o4/operator.txt")"
# posture skip: a plugin manifest makes claude-validate applicable, and pr skips it
repo2="$tmp/repo2"; mkrepo "$repo2"; mkdir -p "$repo2/.claude-plugin"; printf '{}\n' > "$repo2/.claude-plugin/plugin.json"
base0=$(git -C "$repo2" rev-parse HEAD)
"$panel" run --posture pr --repo "$repo2" --base "$base0" --out "$tmp/o5" >"$tmp/out" 2>"$tmp/err"; rc=$?
[ "$rc" -eq 2 ] || fail "pr skip: expected exit 2, got $rc"
head -1 "$tmp/o5/operator.txt" | grep -q 'repo-code probes are not run on a pull request' || fail "pr skip line: $(head -1 "$tmp/o5/operator.txt")"
! grep -q '^install:' "$tmp/o5/operator.txt" || fail "pr skip printed an install line"
# a bad base is an error with the kit's message
"$panel" run --posture own --repo "$repo" --base "no-such-ref" --out "$tmp/o6" >"$tmp/out" 2>"$tmp/err"; rc=$?
[ "$rc" -eq 2 ] || fail "bad base: expected exit 2, got $rc"
grep -q '^probe-status: ERROR$' "$tmp/out" || fail "bad base: no probe-status ERROR line"
exit 0
