#!/usr/bin/env bash
# SC-4 — `rule-check.sh verify` reads an indication's `probe:` key back: ok, drift, framework, hand-written, orphan, broken.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
rc_=$root/bin/rule-check.sh
[ -x "$rc_" ] || { echo "bin/rule-check.sh not written yet"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
R="$tmp/r"; mkdir -p "$R/vault/indications" "$tmp/d"; git -C "$R" init -q; : > "$R/VAULT.md"
for i in 1 2; do printf '<?php $a = DB::table("t%s");\n' "$i" > "$R/f$i.php"; done
git -C "$R" add -A; git -C "$R" -c user.name=t -c user.email=t@t commit -qm base
printf 'glob: *.php\npattern: DB::table\\(\nseverity: warn\nmessage: Use the repository\n' > "$tmp/d/s.grep"
printf '<?php $x = DB::table("u");\n' > "$tmp/d/bad.php"; printf '<?php $x = 1;\n' > "$tmp/d/good.php"
"$rc_" install --repo "$R" --slug s --draft "$tmp/d" --stack any >/dev/null 2>&1 || fail "setup: install failed"
ind() { printf -- '---\ntype: indication\nslug: %s\nprobe: %s\n%s---\n\n# %s\n' "$1" "$2" "${3:-}" "$1" > "$R/vault/indications/$1.md"; }
ind s s 'probe_count: 2 of 4 files at abc1234
'
out=$("$rc_" verify --repo "$R" --indication "$R/vault/indications/s.md" 2>&1); rc=$?
[ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -Eq '^ok s ' || fail "a written rule must verify ok (rc $rc): $out"
for i in 3 4 5; do printf '<?php $a = DB::table("t%s");\n' "$i" > "$R/f$i.php"; done
out=$("$rc_" verify --repo "$R" --indication "$R/vault/indications/s.md" 2>&1); rc=$?
[ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^drift s: 2 -> 5$' || fail "a changed count must print 'drift s: 2 -> 5' and exit 0 (rc $rc): $out"
ind ghost ghost
out=$("$rc_" verify --repo "$R" --indication "$R/vault/indications/ghost.md" 2>&1); rc=$?
[ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q '^orphan ghost ghost$' || fail "an id the registry lacks must print 'orphan <slug> <id>' and exit 1 (rc $rc): $out"
printf -- '---\ntype: index\n---\n\n| Slug | Rule | Applies-to |\n|------|------|------------|\n| [[ghost]] | r | `*.php` |\n' > "$R/vault/indications/_index.md"
audit=$("$root/bin/indication-route-audit.sh" --repo "$R" "$R/vault/indications/_index.md" 2>&1)
printf '%s\n' "$audit" | grep -q "^unknown-probe	ghost	ghost$" || fail "the audit and verify disagree about the orphan: $audit"
ind fw md-links
out=$("$rc_" verify --repo "$R" --indication "$R/vault/indications/fw.md" 2>&1); rc=$?
[ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^framework md-links$' || fail "a framework id must print 'framework <id>' and exit 0 (rc $rc): $out"
printf 'hand\tany\tplan\ttrue\t./scripts/check.sh\tnative\tS\tyes\tnone\n' >> "$R/probes/registry.tsv"; cp "$R/probes/registry.tsv" "$tmp/reg.before"
ind hand hand
out=$("$rc_" verify --repo "$R" --indication "$R/vault/indications/hand.md" 2>&1); rc=$?
[ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^hand-written hand$' || fail "a hand-written row must print 'hand-written <id>' and exit 0 (rc $rc): $out"
cmp -s "$tmp/reg.before" "$R/probes/registry.tsv" || fail "verify changed the registry"
printf 'liar\tany\tplan\ttrue\t./scripts/check.sh\tnative\tS\tno\tnone\n' >> "$R/probes/registry.tsv"
ind liar liar
out=$("$rc_" verify --repo "$R" --indication "$R/vault/indications/liar.md" 2>&1); rc=$?
[ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q '^mislabelled liar$' || fail "a hand-written row that says no must print 'mislabelled <id>' and exit 1 (rc $rc): $out"
rm "$R/probes/rules/s.grep"
out=$("$rc_" verify --repo "$R" --slug s 2>&1); rc=$?
[ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q '^broken s: ' || fail "a missing rule file must print 'broken s: <reason>' and exit 1 (rc $rc): $out"
"$rc_" verify --repo "$R" >/dev/null 2>&1; [ $? -eq 2 ] || fail "verify with neither --slug nor --indication must exit 2"
exit 0
