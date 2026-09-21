#!/usr/bin/env bash
# SC-5 — an indication may name its probe, and the audit checks that the id exists.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
audit="$root/bin/indication-route-audit.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$audit" ] || { echo "bin/indication-route-audit.sh missing"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
grep -q '^probe:' "$root/templates/indication.md" || fail "templates/indication.md has no probe: key (not written yet)"
mkvault() {  # <root> <bad-id|ok>
  local r=$1; mkdir -p "$r/vault/indications" "$r/probes"; : > "$r/VAULT.md"
  printf 'project-x\n' > /dev/null
  {
    printf -- '---\ntype: index\n---\n\n# Indications\n\n| Slug | Rule | Applies-to |\n|------|------|------------|\n'
    printf '| [[good]] | a rule | `*.md` |\n| [[other]] | a rule | `*.md` |\n| [[plain]] | a rule | `*.md` |\n'
  } > "$r/vault/indications/_index.md"
  printf -- '---\ntype: indication\nslug: good\nprobe: md-links\n---\n' > "$r/vault/indications/good.md"
  printf -- '---\ntype: indication\nslug: other\nprobe: %s\n---\n' "$2" > "$r/vault/indications/other.md"
  printf -- '---\ntype: indication\nslug: plain\n---\n' > "$r/vault/indications/plain.md"
  : > "$r/probes/registry.tsv"
}
mkvault "$tmp/a" no-such-probe
out=$("$audit" "$tmp/a/vault/indications/_index.md" 2>&1); rc=$?
[ "$rc" -eq 1 ] || fail "unknown id: expected exit 1, got $rc: $out"
printf '%s\n' "$out" | grep -q "^unknown-probe	other	no-such-probe$" || fail "no unknown-probe line naming slug and id: $out"
mkvault "$tmp/b" md-links
out=$("$audit" "$tmp/b/vault/indications/_index.md" 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail "known ids: expected exit 0, got $rc: $out"
printf '%s\n' "$out" | grep -q 'unknown-probe' && fail "a known id was reported unknown"
# a repo probe id known only to the repo registry
mkvault "$tmp/c" repo-only
printf 'repo-only\tharness\tplan\ttrue\ttrue\tnative\tS\tno\tnone\n' > "$tmp/c/probes/registry.tsv"
out=$("$audit" "$tmp/c/vault/indications/_index.md" 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail "repo registry id: expected exit 0, got $rc: $out"
# an index outside any repo: the repo registry cannot be located, so nothing fails
mkdir -p "$tmp/d/indications"; cp "$tmp/a/vault/indications/"*.md "$tmp/d/indications/"
out=$("$audit" "$tmp/d/indications/_index.md" 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail "unlocated repo registry: expected exit 0, got $rc: $out"
printf '%s\n' "$out" | grep -q "^unchecked-probe	other	no-such-probe$" || fail "no unchecked-probe line: $out"
# CRLF frontmatter is read, and a `---` rule in a file without frontmatter is not frontmatter
mkvault "$tmp/e" md-links
printf -- '---\r\ntype: indication\r\nprobe: md-links\r\n---\r\n' > "$tmp/e/vault/indications/other.md"
printf 'text\n---\nprobe: nosuch-nofm\n' > "$tmp/e/vault/indications/plain.md"
out=$("$audit" "$tmp/e/vault/indications/_index.md" 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail "CRLF or no-frontmatter case: expected exit 0, got $rc: $out"
exit 0
