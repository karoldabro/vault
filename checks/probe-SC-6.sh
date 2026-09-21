#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/bin/probe.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$probe" ] && [ -x "$root/probes/similar-symbols.sh" ] || { echo "probes/similar-symbols.sh not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
repo="$tmp/repo"; mkdir -p "$repo/lib"
cat > "$repo/lib/text.sh" <<'SH'
#!/usr/bin/env bash
render_page() { :; }
slugify_title() {
  printf '%s' "$1"
}
SH
ln=$(grep -n '^slugify_title' "$repo/lib/text.sh" | cut -d: -f1)
spec() { cat > "$tmp/spec.md" <<MD
---
type: arch-spec
profile: harness
plan: x
---

## Reuse map

| need | existing symbol | decision | reason |
|------|-----------------|----------|--------|
| $1 | - | new | searched lib |
| parse a table | lib/text.sh render_page | reuse | already handles it |
MD
}
spec "generate title slug"
out=$("$probe" run plan --repo "$repo" --spec "$tmp/spec.md" --only similar-symbols 2>"$tmp/err"); rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for an overlapping need, got $rc: $(cat "$tmp/err")"
printf '%s\n' "$out" | awk -F'\t' -v l="$ln" '$2 == "lib/text.sh" && $3 == l && $5 == "similar-symbol" { f = 1 } END { exit !f }' \
  || fail "no similar-symbol row at lib/text.sh:$ln: $out"
printf '%s\n' "$out" | awk -F'\t' '$5 == "similar-symbol"' | grep -q render_page && fail "a reuse row was treated as new: $out"
spec "send invoice email"
out=$("$probe" run plan --repo "$repo" --spec "$tmp/spec.md" --only similar-symbols 2>"$tmp/err"); rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] || fail "an unrelated need: expected exit 0 and no rows, got $rc: $out"
exit 0
