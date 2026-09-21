#!/usr/bin/env bash
# SC-6 — delivery: a rule written by `install` reaches a review through the real kit and panel helper. It is listed
# `[advisory]` under `own` with PROBE_PANEL_REPO_CODE=yes, and it does not run under `own` without it or under `pr`.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
for f in bin/rule-check.sh bin/probe-panel.sh probes/rule-grep.sh; do [ -x "$root/$f" ] || { echo "$f not written yet"; exit 2; }; done
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
R="$tmp/r"; mkdir -p "$R" "$tmp/d"; git -C "$R" init -q
printf '<?php $a = DB::table("old");\n' > "$R/old.php"; printf 'hello\n' > "$R/readme.txt"
git -C "$R" add -A; git -C "$R" -c user.name=t -c user.email=t@t commit -qm base
printf 'glob: *.php\npattern: DB::table\\(\nseverity: warn\nmessage: Use the repository\n' > "$tmp/d/dbtable.grep"
printf '<?php $x = DB::table("u");\n' > "$tmp/d/bad.php"; printf '<?php $x = 1;\n' > "$tmp/d/good.php"
"$root/bin/rule-check.sh" install --repo "$R" --slug dbtable --draft "$tmp/d" --stack any >/dev/null 2>&1 || fail "install failed"
git -C "$R" add -A; git -C "$R" -c user.name=t -c user.email=t@t commit -qm rule
base=$(git -C "$R" rev-parse HEAD)
printf '<?php $b = DB::table("new");\n' > "$R/new.php"; git -C "$R" add -A; git -C "$R" -c user.name=t -c user.email=t@t commit -qm change
panel() { "$root/bin/probe-panel.sh" run --posture "$1" --repo "$R" --base "$base" --out "$tmp/o.$1.$2" 2>&1; }
out=$(PROBE_PANEL_REPO_CODE=yes panel own yes)
adv=$(printf '%s\n' "$out" | awk '/^\[advisory\]$/ {a=1; next} /^\[confirmed\]$/ {a=0} /^PROBE ROWS END/ {a=0} a')
printf '%s\n' "$adv" | awk -F'\t' '$1=="dbtable" && $2=="new.php" && $3=="1"' | grep -q . || fail "own + PROBE_PANEL_REPO_CODE=yes: the rule row for new.php:1 is not listed [advisory]: $out"
printf '%s\n' "$adv" | awk -F'\t' '$2=="old.php"' | grep -q . && fail "a file the change did not touch was reported"
conf=$(printf '%s\n' "$out" | awk '/^\[confirmed\]$/ {c=1; next} /^\[advisory\]$/ {c=0} c')
printf '%s\n' "$conf" | grep -q 'dbtable' && fail "a repo rule row was listed [confirmed]"
out=$(panel own no); printf '%s\n' "$out" | grep -q 'dbtable' && fail "own without PROBE_PANEL_REPO_CODE ran the repo rule"
out=$(PROBE_PANEL_REPO_CODE=yes panel pr no); printf '%s\n' "$out" | grep -q 'dbtable' && fail "pr ran the repo rule although the variable was set"
exit 0
