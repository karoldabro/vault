#!/usr/bin/env bash
# SC-3 — framework rows are confirmed, repo rows advisory, and cited says which.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
panel="$root/bin/probe-panel.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$panel" ] || { echo "bin/probe-panel.sh not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
mkrepo() {
  local r=$1; mkdir -p "$r"
  git -C "$r" init -q && git -C "$r" config user.email t@t && git -C "$r" config user.name t
  printf "# ok\n" > "$r/a.md"; git -C "$r" add -A; git -C "$r" commit -qm base
  base=$(git -C "$r" rev-parse HEAD)
}
repo="$tmp/repo"; mkrepo "$repo"; mkdir -p "$repo/probes"
printf 'repo-x\tharness\tplan\ttrue\tprintf "repo-x\\tb.md\\t1\\twarn\\tr\\tm\\n"\tnative\tS\tno\tnone\n' > "$repo/probes/registry.tsv"
git -C "$repo" add -A; git -C "$repo" commit -qm reg; base=$(git -C "$repo" rev-parse HEAD)
printf '[x](missing.md)\n' >> "$repo/a.md"; printf '# b\n' > "$repo/b.md"
n=$(grep -n 'missing.md' "$repo/a.md" | head -1 | cut -d: -f1)
section() { awk -v s="$1" '$0==s {on=1; next} /^\[/ {on=0} on' "$2"; }
PROBE_PANEL_REPO_CODE=yes "$panel" run --posture own --repo "$repo" --base "$base" --out "$tmp/o1" >"$tmp/out" 2>"$tmp/err"
section '[confirmed]' "$tmp/out" | grep -q "^md-links	a.md	$n	" || fail "md-links row is not under [confirmed]: $(cat "$tmp/out")"
section '[advisory]'  "$tmp/out" | grep -q '^repo-x	b.md	1	' || fail "repo row is not under [advisory]"
section '[confirmed]' "$tmp/out" | grep -q '^repo-x' && fail "repo row printed under [confirmed]"
v=$("$panel" cited "$tmp/o1" md-links a.md "$n");  [ "$v" = confirmed ] || fail "cited md-links: expected confirmed, got '$v'"
v=$("$panel" cited "$tmp/o1" repo-x b.md 1);       [ "$v" = advisory ]  || fail "cited repo-x: expected advisory, got '$v'"
v=$("$panel" cited "$tmp/o1" md-links a.md 999);   rc=$?; [ "$v" = none ] && [ "$rc" -eq 1 ] || fail "cited unknown row: got '$v' rc=$rc"
v=$("$panel" cited "$tmp/o1" md-links b.md "$n"); rc=$?; [ "$v" = none ] && [ "$rc" -eq 1 ] || fail "cited with the right probe and line but another file: got '$v' rc=$rc"
"$panel" cited "$tmp/o1" 'BAD ID' a.md 1 >/dev/null 2>&1; [ $? -eq 2 ] || fail "cited with a bad id did not exit 2"
"$panel" cited "$tmp/o1" md-links a.md 'x' >/dev/null 2>&1; [ $? -eq 2 ] || fail "cited with a bad line did not exit 2"
# a repo row that reuses a framework id makes that id advisory
printf 'md-links\tharness\tdiff\ttrue\ttrue\tnative\tS\tno\tnone\n' >> "$repo/probes/registry.tsv"
git -C "$repo" add -A; git -C "$repo" commit -qm shared; base2=$(git -C "$repo" rev-parse HEAD)
printf '[y](gone.md)\n' >> "$repo/b.md"
PROBE_PANEL_REPO_CODE=yes "$panel" run --posture own --repo "$repo" --base "$base2" --out "$tmp/o2" >"$tmp/out" 2>"$tmp/err"
grep -q '^id-shared: md-links' "$tmp/out" || fail "no id-shared line: $(cat "$tmp/out")"
section '[confirmed]' "$tmp/out" | grep -q '^md-links' && fail "a shared id stayed confirmed"
# a diff that edits the registry makes every row advisory
git -C "$repo" checkout -q "$base" -- probes/registry.tsv 2>/dev/null; git -C "$repo" commit -qam back 2>/dev/null; base3=$(git -C "$repo" rev-parse HEAD)
printf '# edit\n' >> "$repo/probes/registry.tsv"; printf '[z](nowhere.md)\n' >> "$repo/b.md"
PROBE_PANEL_REPO_CODE=yes "$panel" run --posture own --repo "$repo" --base "$base3" --out "$tmp/o3" >"$tmp/out" 2>"$tmp/err"
grep -q '^registry-edited' "$tmp/out" || fail "no registry-edited line: $(cat "$tmp/out")"
section '[confirmed]' "$tmp/out" | grep -q . && fail "a row stayed confirmed although the registry was edited"
# an edit under probes/rules/ or to a probe script makes every row advisory
for touched in probes/rules/x.txt probes/harness.sh; do
  repo4="$tmp/repo4"; rm -rf "$repo4"; mkdir -p "$repo4/probes/rules"; git -C "$repo4" init -q; git -C "$repo4" config user.email t@t; git -C "$repo4" config user.name t
  printf '# a\n' > "$repo4/a.md"; printf 'x\n' > "$repo4/probes/rules/x.txt"; printf 'y\n' > "$repo4/probes/harness.sh"
  git -C "$repo4" add -A; git -C "$repo4" commit -qm b; b4=$(git -C "$repo4" rev-parse HEAD)
  printf '[q](void.md)\n' >> "$repo4/a.md"; printf 'z\n' >> "$repo4/$touched"
  "$panel" run --posture own --repo "$repo4" --base "$b4" --out "$tmp/o5" >"$tmp/out" 2>"$tmp/err"
  grep -q '^registry-edited' "$tmp/out" || fail "an edit to $touched did not print registry-edited"
  section '[confirmed]' "$tmp/out" | grep -q . && fail "a row stayed confirmed after an edit to $touched"
done
# a framework row that runs repo code is advisory even though its origin is the framework
fw="$tmp/fw"; mkdir -p "$fw"; cp -R "$root/bin" "$root/lib" "$root/probes" "$fw/"
printf 'zz-yes\tany\tplan\ttrue\tprintf "zz-yes\\tb.md\\t1\\twarn\\tr\\tm\\n"\tnative\tS\tyes\tnone\n' >> "$fw/probes/registry.tsv"
repo3="$tmp/repo3"; mkdir -p "$repo3"; git -C "$repo3" init -q; git -C "$repo3" config user.email t@t; git -C "$repo3" config user.name t
printf '# a\n' > "$repo3/a.md"; git -C "$repo3" add -A; git -C "$repo3" commit -qm b; b3=$(git -C "$repo3" rev-parse HEAD); printf '# b\n' > "$repo3/b.md"
PROBE_PANEL_REPO_CODE=yes "$fw/bin/probe-panel.sh" run --posture own --repo "$repo3" --base "$b3" --out "$tmp/o4" >"$tmp/out" 2>"$tmp/err"
section '[advisory]' "$tmp/out" | grep -q '^zz-yes' || fail "a framework yes row is not under [advisory]: $(cat "$tmp/out")"
section '[confirmed]' "$tmp/out" | grep -q '^zz-yes' && fail "a framework yes row printed under [confirmed]"
exit 0
