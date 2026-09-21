#!/usr/bin/env bash
# SC-2 — `rule-check.sh accept` accepts a rule only with a firing bad fixture, a silent good fixture, a glob
# that selects a file and at most RULE_MAX_FINDINGS (default 20) findings; it records `<n> of <files> files at <sha>`.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
rc_=$root/bin/rule-check.sh
[ -x "$rc_" ] || { echo "bin/rule-check.sh not written yet"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
mk() { mkdir -p "$1"; git -C "$1" init -q; printf 'x\n' > "$1/readme.txt"; n=${2:-1}
  for i in $(seq 1 "$n"); do printf '<?php $a = DB::table("t%s");\n' "$i" > "$1/f$i.php"; done
  printf '<?php $ok = 1;\n' > "$1/clean.php"
  git -C "$1" add -A; git -C "$1" -c user.name=t -c user.email=t@t commit -qm base; }
draft() { mkdir -p "$1"
  printf 'glob: *.php\npattern: DB::table\\(\nseverity: warn\nmessage: Use the repository\n' > "$1/s.grep"
  printf '<?php $x = DB::table("users")->get();\n' > "$1/bad.php"; printf '<?php $x = $repo->all();\n' > "$1/good.php"; }
acc() { "$rc_" accept --repo "$1" --slug "${3:-s}" --rule "$2/s.grep" --bad "$2/bad.php" --good "$2/good.php"; }
snap() { (cd "$1" && find . -path ./.git -prune -o -type f -print | sort | xargs sha1sum); }
mk "$tmp/a" 3; draft "$tmp/da"
before=$(snap "$tmp/a")
out=$(acc "$tmp/a" "$tmp/da" 2>"$tmp/err"); rc=$?
[ "$rc" -eq 0 ] || fail "a good rule was refused: $(cat "$tmp/err")"
printf '%s\n' "$out" | grep -Eq '^accepted s: 3 of [0-9]+ files at [0-9a-f]{7,40}$' || fail "record line wrong: $out"
[ "$before" = "$(snap "$tmp/a")" ] || fail "accept wrote into the repo"
refused() { # refused <why> <regex> <repo> <draft> [slug]
  out=$(acc "$3" "$4" "${5:-s}" 2>&1 >/dev/null); rc=$?
  [ "$rc" -eq 1 ] || fail "$1: expected exit 1, got $rc"
  printf '%s\n' "$out" | grep -Eq "^refused ${5:-s}: .*$2" || fail "$1: refusal does not name the reason /$2/: $out"
}
draft "$tmp/db"; printf '<?php $x = 1;\n' > "$tmp/db/bad.php"; refused "silent bad fixture" 'bad fixture' "$tmp/a" "$tmp/db"
draft "$tmp/dc"; cp "$tmp/dc/bad.php" "$tmp/dc/good.php"; refused "firing good fixture" 'good fixture' "$tmp/a" "$tmp/dc"
draft "$tmp/dd"; sed -i 's/^glob:.*/glob: *.zzz/' "$tmp/dd/s.grep"; refused "glob selects nothing" 'glob' "$tmp/a" "$tmp/dd"
draft "$tmp/de"; refused "framework id" 'framework' "$tmp/a" "$tmp/de" md-links
draft "$tmp/df"; refused "bad slug" 'slug' "$tmp/a" "$tmp/df" 'Bad_Slug'
mk "$tmp/b" 20; draft "$tmp/dg"
acc "$tmp/b" "$tmp/dg" >/dev/null 2>&1 || fail "exactly 20 findings must be accepted"
mk "$tmp/c" 21; draft "$tmp/dh"; refused "fires everywhere (21 findings)" 'everywhere.*20' "$tmp/c" "$tmp/dh"
out=$(RULE_MAX_FINDINGS=2 acc "$tmp/a" "$tmp/da" 2>&1 >/dev/null); [ $? -eq 1 ] || fail "RULE_MAX_FINDINGS=2 must refuse 3 findings"
"$rc_" accept --repo "$tmp/a" >/dev/null 2>&1; [ $? -eq 2 ] || fail "missing options must exit 2"
exit 0
