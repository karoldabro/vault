#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
probe="$root/bin/probe.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$probe" ] && [ -r "$root/probes/registry.tsv" ] || { echo "the kit is not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
repo="$tmp/repo"; mkdir -p "$repo/probes"
printf 'repo-no\tharness\tplan\ttrue\ttouch %s\tnative\tS\tno\tnone\n' "$tmp/ran-repo-no" > "$repo/probes/registry.tsv"
printf '# a note\n' > "$repo/note.md"
# a repo registry is ignored without the opt-in flag
"$probe" run plan --repo "$repo" >/dev/null 2>"$tmp/err"
[ ! -e "$tmp/ran-repo-no" ] || fail "a repo registry row ran without --allow-repo-registry"
# detect runs a repo detect cell only with the flag
printf 'repo-det\tharness\tplan\ttouch %s\ttrue\tnative\tS\tno\tnone\n' "$tmp/ran-detect" >> "$repo/probes/registry.tsv"
"$probe" detect --repo "$repo" >/dev/null 2>&1
[ ! -e "$tmp/ran-detect" ] || fail "detect ran a repo detect cell without --allow-repo-registry"
"$probe" list --repo "$repo" --allow-repo-registry >/dev/null 2>&1
[ ! -e "$tmp/ran-detect" ] || fail "list ran a repo cell"
# with the flag it runs
"$probe" run plan --repo "$repo" --allow-repo-registry >/dev/null 2>"$tmp/err"
[ -e "$tmp/ran-repo-no" ] || fail "with --allow-repo-registry the repo row did not run: $(cat "$tmp/err")"
rm -f "$tmp/ran-repo-no"
# --no-repo-code skips it even though the row claims no
"$probe" run plan --repo "$repo" --allow-repo-registry --no-repo-code >/dev/null 2>"$tmp/err"
[ ! -e "$tmp/ran-repo-no" ] || fail "a repo row claiming 'no' ran under --no-repo-code"
grep -q '^skipped: repo-no' "$tmp/err" || fail "stderr does not say repo-no was skipped: $(cat "$tmp/err")"
# a framework row marked no still runs, and says so
"$probe" run plan --repo "$repo" --no-repo-code --only md-links >/dev/null 2>"$tmp/err"
grep -q '^ran: md-links: ' "$tmp/err" || fail "a framework row marked 'no' did not run under --no-repo-code: $(cat "$tmp/err")"
grep -q '^skipped: md-links' "$tmp/err" && fail "a framework row marked 'no' was skipped: $(cat "$tmp/err")"
# a framework row marked yes is skipped
"$probe" run plan --repo "$root" --no-repo-code --only claude-validate >/dev/null 2>"$tmp/err"
grep -q '^skipped: claude-validate' "$tmp/err" || fail "a framework row marked 'yes' was not skipped: $(cat "$tmp/err")"
exit 0
