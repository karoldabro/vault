#!/usr/bin/env bash
# Exit 0 met, 1 not met, 2 cannot read the question. C3 of vault/plans/2026-10-20-1934-agent-systems-lens.md.
# Reads the saved output of one agent-systems review of a real plan. Met when at least 3 findings are
# `grounding: confirmed` and each confirmed finding carries a `check:` line that is not `none`.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
out="$root/vault/plans/2026-10-20-1934-agent-systems-lens.c3-run.md"
[ -f "$out" ] || { printf 'no saved lens run at %s\n' "$out"; exit 2; }
confirmed=$(grep -c 'grounding: confirmed' "$out")
[ "$confirmed" -ge 3 ] || { printf '%s confirmed findings, need 3\n' "$confirmed"; exit 1; }
bad=$(awk '/grounding: confirmed/{c=1;next} c&&/check:/{if($0 ~ /check:[[:space:]]*(none|"none")?[[:space:]]*$/)n++; c=0} END{print n+0}' "$out")
[ "$bad" -eq 0 ] || { printf '%s confirmed findings have no check\n' "$bad"; exit 1; }
exit 0
