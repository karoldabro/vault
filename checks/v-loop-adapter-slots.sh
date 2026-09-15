#!/usr/bin/env bash
# Every /v-loop adapter fills all six slots, and at least two adapters exist.
#
# One adapter is indistinguishable from no adapter layer: the engine could name it and still be
# welded to it. Two is the floor that makes "task-agnostic" falsifiable rather than asserted.
#
# The slot headings ARE the contract — commands/v-loop/adapters.md tells an author to copy them
# verbatim, and this reads them back. The contract file itself lives beside the directory, not in it,
# so it is never counted as an adapter.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dir="$root/commands/v-loop/adapters"
contract="$root/commands/v-loop/adapters.md"
fail=0

[ -f "$contract" ] || { printf '  MISSING  %s does not exist\n' "$contract"; exit 1; }
[ -d "$dir" ] || { printf '  MISSING  %s does not exist\n' "$dir"; exit 1; }

slots=("## Unit of work" "## Backlog" "## Actor" "## Verifier" "## Caps" "## Stop rule")

# the contract must name every slot it demands, or an author cannot copy them
for s in "${slots[@]}"; do
  grep -qF "\`$s\`" "$contract" || { printf '  MISSING  the contract never names the slot %s\n' "$s"; fail=1; }
done

mapfile -t adapters < <(find "$dir" -maxdepth 1 -name '*.md' | sort)
n=${#adapters[@]}
if [ "$n" -lt 2 ]; then
  printf '  REFUSED  %s adapter(s); two is the floor, or the engine is welded to its one task\n' "$n"
  fail=1
fi

declare -a verifier_kinds=()
for a in "${adapters[@]}"; do
  rel="commands/v-loop/adapters/$(basename "$a")"
  for s in "${slots[@]}"; do
    grep -qxF "$s" "$a" || { printf '  MISSING  %s has no %s\n' "$rel" "$s"; fail=1; }
  done
  # a slot whose body is empty is a heading, not an answer
  for s in "${slots[@]}"; do
    body=$(awk -v h="$s" 'index($0,h)==1{f=1;next} f&&/^## /{exit} f&&NF{c++} END{print c+0}' "$a")
    [ "${body:-0}" -ge 1 ] || { printf '  EMPTY    %s fills %s with nothing\n' "$rel" "$s"; fail=1; }
  done
  # The verifier slot must say what produces the verdict.
  #
  # Read the slot into a variable before matching it. Piping awk into `grep -q` lets grep close the
  # pipe on its first match, which SIGPIPEs awk; under `pipefail` the pipeline status is then 141 or
  # 0 depending on who finished first, so the kind below was detected nondeterministically.
  vslot=$(awk 'index($0,"## Verifier")==1{f=1;next} f&&/^## /{exit} f' "$a")
  if printf '%s' "$vslot" | grep -qiE 'exit code|command|a run of|hash'; then
    if printf '%s' "$vslot" | grep -qiE 'exit code|hash'; then
      verifier_kinds+=(command)
    else
      verifier_kinds+=(run)
    fi
  else
    printf '  VAGUE    %s names no concrete verifier under ## Verifier\n' "$rel"; fail=1
  fi
done

# two adapters naming the same verifier kind prove nothing about generality
if [ "$n" -ge 2 ] && [ "${#verifier_kinds[@]}" -ge 2 ]; then
  uniq_kinds=$(printf '%s\n' "${verifier_kinds[@]}" | sort -u | wc -l)
  [ "$uniq_kinds" -ge 2 ] || {
    printf '  REFUSED  every adapter verifies the same way; the split demonstrates nothing\n'; fail=1; }
fi

[ "$fail" -eq 0 ] && printf '  OK  %s adapters, each filling all six slots, verifying in more than one way\n' "$n"
exit "$fail"
