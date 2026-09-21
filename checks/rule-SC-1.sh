#!/usr/bin/env bash
# SC-1 — the rule runner prints C-2 rows for a declarative rule file, rejects a malformed rule, and skips probes/.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
run="$root/probes/rule-grep.sh"
[ -x "$run" ] || { echo "probes/rule-grep.sh not written yet"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
R="$tmp/r"; mkdir -p "$R/probes/rules/fixtures/x" "$R/docs"
git -C "$R" init -q
printf 'glob: *.php\npattern: DB::table\\(\nseverity: warn\nmessage: Use the repository instead of DB::table\n' > "$R/probes/rules/x.grep"
printf '<?php $a = DB::table("u")->get();\n' > "$R/app.php"
printf '<?php $a = $repo->all();\n' > "$R/ok.php"
printf 'DB::table( in prose\n' > "$R/docs/notes.txt"
printf '<?php $a = DB::table("u");\n' > "$R/probes/rules/fixtures/x/bad.php"
git -C "$R" add -A && git -C "$R" -c user.name=t -c user.email=t@t commit -qm base
out=$("$run" --check x --rule probes/rules/x.grep --repo "$R" 2>"$tmp/err"); rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 with a finding, got $rc: $(cat "$tmp/err")"
[ "$(printf '%s\n' "$out" | grep -c '')" -eq 1 ] || fail "expected exactly one row (probes/ and non-matching globs are skipped): $out"
printf '%s\n' "$out" | awk -F'\t' 'NF==6 && $1=="x" && $2=="app.php" && $3=="1" && $4=="warn" && $5=="x"' | grep -q . || fail "row is not the C-2 shape for app.php:1: $out"
"$run" --check x --rule probes/rules/x.grep --repo "$R" --fixture "$R/ok.php" >/dev/null 2>&1 || fail "a clean fixture must exit 0"
out=$("$run" --check x --rule probes/rules/x.grep --repo "$R" --fixture "$R/app.php" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && [ -n "$out" ] || fail "a firing fixture must exit 1 with a row (got $rc)"
bad() { # bad <name> <rule text>
  printf '%b' "$2" > "$R/probes/rules/b.grep"
  "$run" --check b --rule probes/rules/b.grep --repo "$R" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 2 ] || fail "malformed rule ($1): expected exit 2, got $rc"
}
bad severity 'glob: *.php\npattern: a\nseverity: fatal\nmessage: m\n'
bad two-patterns 'glob: *.php\npattern: a\npattern: b\nseverity: warn\nmessage: m\n'
bad unknown-key 'glob: *.php\npattern: a\nseverity: warn\nmessage: m\nexec: rm -rf x\n'
bad unclosed-regex 'glob: *.php\npattern: (\nseverity: warn\nmessage: m\n'
bad pcre-key 'glob: *.php\npattern: a\nseverity: warn\nmessage: m\nengine: pcre\n'
bad tab-in-message 'glob: *.php\npattern: a\nseverity: warn\nmessage: a\tb\n'
bad absolute-glob 'glob: /etc/*\npattern: a\nseverity: warn\nmessage: m\n'
bad no-glob 'pattern: a\nseverity: warn\nmessage: m\n'
bad no-message 'glob: *.php\npattern: a\nseverity: warn\n'
"$run" --check x --rule ../x.grep --repo "$R" >/dev/null 2>&1; [ $? -eq 2 ] || fail "a rule path with .. must exit 2"
ln -s x.grep "$R/probes/rules/link.grep"
"$run" --check x --rule probes/rules/link.grep --repo "$R" >/dev/null 2>&1; [ $? -eq 2 ] || fail "a symlinked rule file must exit 2"
exit 0
