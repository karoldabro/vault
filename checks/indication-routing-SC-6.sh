#!/usr/bin/env bash
# SC-6 — every file this plan writes passes doc-lint.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lint="$root/bin/doc-lint.sh"
[ -x "$lint" ] || { printf '  MISSING  %s\n' "$lint"; exit 1; }

files="
vault/plans/2026-09-09-1052-indication-routing-coverage.md
vault/plans/2026-09-09-1052-indication-routing-coverage.trail.md
vault/indications/rules-routed-not-recalled.md
vault/indications/_index.md
vault/check-budget.md
commands/_shared/critic-panel.md
commands/v-cr/steps/02-gather.md
commands/v-cr/steps/03-review.md
commands/v-cr/steps/04-post.md
"
fail=0 n=0
for f in $files; do
    [ -r "$root/$f" ] || { printf '  MISSING  %s\n' "$f"; fail=1; continue; }
    "$lint" "$root/$f" || fail=1
    n=$((n + 1))
done
[ "$fail" -eq 0 ] && printf '  OK  %s files pass doc-lint\n' "$n"
exit "$fail"
