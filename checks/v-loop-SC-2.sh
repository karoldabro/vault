#!/usr/bin/env bash
# SC-2 — every file the v-loop plan creates or modifies passes bin/doc-lint.sh.
#
# Fails when any shipped document carries a finding the repo's own document contract forbids.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
files=(
  commands/v-loop.md
  commands/v-loop/campaign-rules.md
  templates/campaign/STATE.md
  templates/campaign/defects.md
  templates/campaign/ledger.md
  templates/campaign/result.md
  templates/campaign/TESTER-BRIEF.md

  vault/decisions/ADR-027-autonomous-test-fix-loop.md
  vault/indications/campaign-evidence-from-the-running-system.md
  vault/indications/_index.md
  vault/features/v-loop.md
  vault/check-budget.md
  vault/defect-ledger.md
  README.md
  vault-guide.md
  vault/_moc.md
)
fail=0
for f in "${files[@]}"; do
  if [ ! -f "$root/$f" ]; then
    printf '  MISSING  %s\n' "$f"; fail=1; continue
  fi
  "$root/bin/doc-lint.sh" "$root/$f" || fail=1
done
[ "$fail" -eq 0 ] && printf '  OK  %d files pass doc-lint\n' "${#files[@]}"
exit "$fail"
