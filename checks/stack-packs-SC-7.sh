#!/usr/bin/env bash
# SC-7 of vault/plans/2026-09-22-0900-stack-packs.md — this plan passes doc-lint and the approve gate.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
plan="$root/vault/plans/2026-09-22-0900-stack-packs.md"
[ -r "$plan" ] || { echo "plan file is missing"; exit 2; }
"$root/bin/doc-lint.sh" "$plan" >/tmp/stack-packs-sc7.log 2>&1 || { cat /tmp/stack-packs-sc7.log; exit 1; }
"$root/bin/gate.sh" all "$plan" --phase approve >>/tmp/stack-packs-sc7.log 2>&1 || { cat /tmp/stack-packs-sc7.log; exit 1; }
exit 0
