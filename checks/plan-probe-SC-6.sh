#!/usr/bin/env bash
# SC-6 of vault/plans/2026-09-21-1800-plan-time-probes.md — the stage on two real past plans costs at most 50%.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pp="$root/bin/plan-probes.sh"; panel="$root/bin/probe-panel.sh"
plan="$root/vault/plans/2026-09-21-1800-plan-time-probes.md"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$pp" ] && grep -q -- '--stage' "$panel" || { echo "the stage is not written yet — cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
base() { sed -n "s/^- the $1 .*PROPOSE window cost \([0-9,]*\) fresh tokens.*/\1/p" "$plan" | head -1 | tr -d ','; }
b8=$(base 'v-rule plan (S8)'); b10=$(base 'sandbox-probe plan (S10)')
[ -n "$b8" ] && [ -n "$b10" ] || { echo "the recorded baselines are missing from Verified current state"; exit 2; }
one() { # one <label> <arch spec> <critics> <baseline>
  local label=$1 spec="$root/vault/plans/$2" c=$3 bl=$4 d="$tmp/$1" added pct
  [ -r "$spec" ] || { echo "cannot read $spec"; exit 2; }
  mkdir -p "$d"
  "$panel" run --stage plan --spec "$spec" --repo "$root" --only similar-symbols --only spec-symbols --out "$d" > "$d/block.txt" 2>"$d/err"
  grep -q '^probe-status: ' "$d/block.txt" || fail "$label: no block: $(head -3 "$d/err")"
  grep -q '^probe-status: ERROR' "$d/block.txt" && fail "$label: the block reads ERROR: $(sed -n 3,4p "$d/block.txt")"
  out=$("$pp" budget --critics "$c" --rounds 1 --block "$d/block.txt" --out "$d" 2>&1) || fail "$label: budget failed: $out"
  added=$(printf '%s\n' "$out" | sed -n 's/^projected: added=\([0-9]*\).*/\1/p')
  [ -n "$added" ] || fail "$label: no projected line: $out"
  pct=$((added * 100 / bl))
  printf '%s: block %s bytes, %s rows, added %s tokens, %s%% of the recorded %s, tier %s\n' "$label" "$(wc -c < "$d/block.txt")" "$(grep -c '^similar-symbols\|^spec-symbols' "$d/block.txt")" "$added" "$pct" "$bl" "$(cat "$d/tier.txt")"
  [ "$pct" -le 50 ] || fail "$label: the projected added cost is $pct% of the recorded baseline"
}
one v-rule 2026-09-21-1430-v-rule.arch.md 3 "$b8"
one sandbox-probe 2026-09-21-1600-sandbox-probe.arch.md 4 "$b10"
# the recorded baselines are reproducible when the transcripts exist on this machine
P="$HOME/.claude/projects/-home-kdabrow-workspace-vault"
if [ -r "$P/addebe05-74e1-4854-9d29-9a12da7a8fa2.jsonl" ] && [ -r "$P/357c4e40-91b3-4514-b2ae-dd335bda31aa.jsonl" ] && command -v jq >/dev/null; then
  m8=$("$pp" measure "$P/addebe05-74e1-4854-9d29-9a12da7a8fa2.jsonl" --from 2026-09-21T12:16:00Z --to 2026-09-21T12:46:27Z 2>/dev/null | sed -n 's/^total\tfresh=\([0-9]*\).*/\1/p')
  m10=$("$pp" measure "$P/357c4e40-91b3-4514-b2ae-dd335bda31aa.jsonl" --from 2026-09-21T13:56:00Z --to 2026-09-21T14:44:49Z 2>/dev/null | sed -n 's/^total\tfresh=\([0-9]*\).*/\1/p')
  [ "$m8" = "$b8" ] || fail "measure gives $m8 for the v-rule window; the plan records $b8"
  [ "$m10" = "$b10" ] || fail "measure gives $m10 for the sandbox window; the plan records $b10"
  echo "baselines re-measured from the transcripts: $m8 and $m10"
else
  echo "transcripts absent: the recorded baselines were not re-measured"
fi
exit 0
