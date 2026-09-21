#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
doc="$root/vault/research/probe-tool-verification.md"; fx="$root/tests/fixtures/probe"
for f in "$doc" "$root/probes/registry.tsv" "$root/lib/probe-parsers.sh" "$fx/lizard.csv" "$fx/typos.jsonl" "$fx/claude-validate.json"; do
  [ -r "$f" ] || { echo "${f#$root/} not written yet — cannot say"; exit 2; }
done
fail() { printf '%s\n' "$*"; exit 1; }
T=$(printf '\t')
n=$(grep -c '^### ' "$doc"); [ "$n" -eq 12 ] || fail "the verification file has $n claim headings, expected 12"
bad=$(awk '/^### /{ if (h && !(v&&u&&d)) print h; h=$0; v=u=d=0; next }
     /^verdict: (verified|partly|refuted|unverifiable)/ { v=1 } /^url: https:\/\// { u=1 } /^date: 2026-/ { d=1 }
     END { if (h && !(v&&u&&d)) print h }' "$doc" | head -1)
[ -z "$bad" ] || fail "a claim lacks verdict, url or date: $bad"
# every tool a registry row runs has a verified or partly verdict
while IFS="$T" read -r id stack stage detect run parser cost trust install; do
  case "$id" in ''|'#'*) continue ;; esac
  [ "$parser" = native ] && continue
  tool=${run%% *}
  case "$tool" in claude) tool="claude plugin validate" ;; esac
  sec=$(awk -v t="$tool" '/^### / { on = (index(tolower($0), tolower(t)) > 0) } on && /^verdict: /{ print $2; exit }' "$doc")
  case "$sec" in verified|partly) ;; *) fail "registry row $id runs '$tool', whose verdict is '${sec:-missing}'" ;; esac
done < "$root/probes/registry.tsv"
# parsers on captured real output
run_parser() { bash -c '. "$1"; shift; "$@"' _ "$root/lib/probe-parsers.sh" "$@"; }
rows=$(PROBE_CCN=4 run_parser parse_lizard_csv lizard < "$fx/lizard.csv") || fail "parse_lizard_csv failed"
[ "$(printf '%s\n' "$rows" | grep -c .)" -eq 3 ] || fail "lizard: expected 3 rows at PROBE_CCN=4, got: $rows"
printf '%s\n' "$rows" | awk -F'\t' 'NF != 6 || $1 != "lizard" || $5 != "high-complexity" { b = 1 } END { exit b }' || fail "lizard rows are malformed: $rows"
[ -z "$(PROBE_CCN=99 run_parser parse_lizard_csv lizard < "$fx/lizard.csv")" ] || fail "lizard: rows printed below the threshold"
rows=$(run_parser parse_typos_json typos < "$fx/typos.jsonl") || fail "parse_typos_json failed"
[ "$(printf '%s\n' "$rows" | grep -c .)" -eq 2 ] || fail "typos: expected 2 rows, got: $rows"
printf '%s\n' "$rows" | awk -F'\t' 'NF != 6 || $1 != "typos" || $4 != "warn" { b = 1 } END { exit b }' || fail "typos rows are malformed: $rows"
[ -z "$(run_parser parse_typos_json typos < /dev/null)" ] || fail "typos: rows printed for empty input"
if command -v jq >/dev/null 2>&1; then
  rows=$(run_parser parse_claude_validate claude-validate "$root" < "$fx/claude-validate.json") || fail "parse_claude_validate failed"
  printf '%s\n' "$rows" | awk -F'\t' '$4 == "error" { e = 1 } $4 == "warn" { w = 1 } NF != 6 { b = 1 } END { exit !(e && w && !b) }' || fail "claude validate: expected one error row and one warn row of six fields: $rows"
fi
exit 0
