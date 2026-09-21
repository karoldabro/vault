#!/usr/bin/env bash
# SC-3 — `rule-check.sh install` writes the rule file, two fixtures and one template registry row, and nothing else,
# and refuses a symlinked registry, the framework's own registry, a repeated id and a rule that fails accept.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
rc_=$root/bin/rule-check.sh
[ -x "$rc_" ] || { echo "bin/rule-check.sh not written yet"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
mk() { mkdir -p "$1"; git -C "$1" init -q; printf '<?php $a = DB::table("t");\n' > "$1/f.php"; printf 'x\n' > "$1/readme.txt"
  git -C "$1" add -A; git -C "$1" -c user.name=t -c user.email=t@t commit -qm base; }
draft() { mkdir -p "$1"
  printf 'glob: *.php\npattern: DB::table\\(\nseverity: warn\nmessage: Use the repository\n' > "$1/s.grep"
  printf '<?php $x = DB::table("users")->get();\n' > "$1/bad.php"; printf '<?php $x = $repo->all();\n' > "$1/good.php"; }
files() { (cd "$1" && find . -path ./.git -prune -o \( -type f -o -type l \) -print | sort); }
inst() { "$rc_" install --repo "$1" --slug "${3:-s}" --draft "$2" --stack any; }
mk "$tmp/a"; draft "$tmp/da"; before=$(files "$tmp/a")
out=$(inst "$tmp/a" "$tmp/da" 2>"$tmp/err"); rc=$?
[ "$rc" -eq 0 ] || fail "install failed: $(cat "$tmp/err")"
added=$(comm -13 <(printf "%s\n" "$before") <(files "$tmp/a") | tr "\n" " ")
want="./probes/registry.tsv ./probes/rules/fixtures/s/bad.php ./probes/rules/fixtures/s/good.php ./probes/rules/s.grep "
[ "$added" = "$want" ] || fail "install wrote the wrong set of files: [$added] wanted [$want]"
row=$(grep -v '^#' "$tmp/a/probes/registry.tsv")
[ "$(printf '%s\n' "$row" | grep -c '')" -eq 1 ] || fail "expected one registry row, got: $row"
printf '%s\n' "$row" | awk -F'\t' 'NF==9 && $1=="s" && $2=="any" && $3=="plan" && $5=="\"$PROBE_FRAMEWORK/probes/rule-grep.sh\" --check s --rule probes/rules/s.grep" && $6=="native" && $7=="S" && $8=="yes" && $9=="none"' | grep -q . || fail "the row is not the template row: $row"
head -1 "$tmp/a/probes/registry.tsv" | grep -q '^#' || fail "a new registry starts with a comment header"
printf '%s\n' "$out" | grep -Eq '^record: 1 of [0-9]+ files at [0-9a-f]{7,40}$' || fail "no record line: $out"
cmp -s "$tmp/da/s.grep" "$tmp/a/probes/rules/s.grep" || fail "the rule file was altered on copy"
# the row runs through the real kit
"$root/bin/probe.sh" list --repo "$tmp/a" --allow-repo-registry 2>/dev/null | awk -F'\t' '$1=="s" && $4=="repo" && $5=="ok"' | grep -q . || fail "bin/probe.sh list does not show the rule as ok"
# a second install of the same id is refused and changes nothing
sum=$(sha1sum "$tmp/a/probes/registry.tsv"); inst "$tmp/a" "$tmp/da" >/dev/null 2>&1; [ $? -eq 1 ] || fail "a repeated id must exit 1"
[ "$sum" = "$(sha1sum "$tmp/a/probes/registry.tsv")" ] || fail "a refused install changed the registry"
# an existing registry keeps its rows byte for byte
mk "$tmp/b"; mkdir -p "$tmp/b/probes"; printf '# mine\nold\tany\tplan\ttrue\ttrue\tnative\tS\tyes\tnone\n' > "$tmp/b/probes/registry.tsv"; cp "$tmp/b/probes/registry.tsv" "$tmp/b.orig"
inst "$tmp/b" "$tmp/da" >/dev/null 2>&1 || fail "install into an existing registry failed"
head -c "$(wc -c < "$tmp/b.orig")" "$tmp/b/probes/registry.tsv" | cmp -s - "$tmp/b.orig" || fail "existing registry rows were rewritten"
# a symlinked registry is refused and nothing is written through it
mk "$tmp/c"; mkdir -p "$tmp/c/probes"; : > "$tmp/target.tsv"; ln -s "$tmp/target.tsv" "$tmp/c/probes/registry.tsv"
inst "$tmp/c" "$tmp/da" >/dev/null 2>&1; [ $? -eq 1 ] || fail "a symlinked registry must exit 1"
[ ! -s "$tmp/target.tsv" ] || fail "install wrote through a symlink"
[ ! -e "$tmp/c/probes/rules/s.grep" ] || fail "a refused install left a rule file behind"
# slug, stack and fixture extension are validated before anything is written
for slug in 'a;id' 'a$(id)' '../x' '-x' 'Bad' 'md-links'; do
  mk "$tmp/v"; b=$(files "$tmp/v"); "$rc_" install --repo "$tmp/v" --slug "$slug" --draft "$tmp/da" --stack any >/dev/null 2>&1
  [ $? -eq 1 ] || fail "slug '$slug' must be refused with exit 1"; [ "$b" = "$(files "$tmp/v")" ] || fail "slug '$slug' wrote files"; rm -rf "$tmp/v"
done
mk "$tmp/v"; "$rc_" install --repo "$tmp/v" --slug s --draft "$tmp/da" --stack 'a;b' >/dev/null 2>&1; [ $? -eq 1 ] || fail "a stack outside the list must exit 1"; rm -rf "$tmp/v"
mk "$tmp/v"; draft "$tmp/dx"; mv "$tmp/dx/good.php" "$tmp/dx/good.txt"; "$rc_" install --repo "$tmp/v" --slug s --draft "$tmp/dx" --stack any >/dev/null 2>&1; [ $? -eq 1 ] || fail "fixtures with different extensions must exit 1"; rm -rf "$tmp/v"
mkdir -p "$tmp/ng" && printf '<?php DB::table(1);\n' > "$tmp/ng/f.php"; "$rc_" install --repo "$tmp/ng" --slug s --draft "$tmp/da" --stack any >/dev/null 2>&1; [ $? -eq 1 ] || fail "a directory that is not a git repository must exit 1"
# a symlinked probes/rules directory and a pre-existing rule file link are refused; nothing is written through them
mk "$tmp/l"; mkdir -p "$tmp/l/probes" "$tmp/elsewhere"; ln -s "$tmp/elsewhere" "$tmp/l/probes/rules"
"$rc_" install --repo "$tmp/l" --slug s --draft "$tmp/da" --stack any >/dev/null 2>&1; [ $? -eq 1 ] || fail "a symlinked probes/rules must exit 1"
[ -z "$(ls -A "$tmp/elsewhere")" ] || fail "install wrote through a symlinked directory"
mk "$tmp/m"; mkdir -p "$tmp/m/probes/rules"; : > "$tmp/target2"; ln -s "$tmp/target2" "$tmp/m/probes/rules/s.grep"
"$rc_" install --repo "$tmp/m" --slug s --draft "$tmp/da" --stack any >/dev/null 2>&1; [ $? -eq 1 ] || fail "a pre-existing linked rule file must exit 1"
[ ! -s "$tmp/target2" ] || fail "install wrote through a symlinked rule file"
# the framework's own registry is refused
fw=$(git -C "$root" status --porcelain -- probes | sha1sum)
inst "$root" "$tmp/da" >/dev/null 2>&1; [ $? -eq 1 ] || fail "installing into the framework repo must exit 1"
[ "$fw" = "$(git -C "$root" status --porcelain -- probes | sha1sum)" ] || fail "a refused install changed the framework"
# a rule that fails accept writes nothing
mk "$tmp/d"; draft "$tmp/dd"; printf '<?php ok;\n' > "$tmp/dd/bad.php"; b=$(files "$tmp/d")
inst "$tmp/d" "$tmp/dd" >/dev/null 2>&1; [ $? -eq 1 ] || fail "a failing rule must exit 1"
[ "$b" = "$(files "$tmp/d")" ] || fail "a refused install wrote files"
exit 0
