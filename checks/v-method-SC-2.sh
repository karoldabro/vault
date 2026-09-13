#!/usr/bin/env bash
# SC-2 — every file the v-method plan creates or modifies passes bin/doc-lint.sh.
#
# Fails when any shipped document carries a finding the repo's own document contract forbids.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
files=(
  commands/v-method.md
  commands/v-method/routing.md
  templates/method.md

  vault/decisions/ADR-029-methodology-command.md
  vault/features/v-method.md
  vault/_feature-index.md
  vault/_moc.md
  vault/plans/2026-09-13-1530-v-method-command.md
)

lint="$root/bin/doc-lint.sh"
[ -x "$lint" ] || { printf '  MISSING  %s\n' "$lint"; exit 1; }

missing=0 checked=0 findings=0
for f in "${files[@]}"; do
    if [ ! -f "$root/$f" ]; then
        printf '  MISSING  %s\n' "$f"; missing=$((missing + 1)); continue
    fi
    out=$("$lint" "$root/$f" 2>&1) || findings=$((findings + 1))
    [ -z "$out" ] || printf '%s\n' "$out"
    checked=$((checked + 1))
done

[ "$missing" -eq 0 ]  || { printf '  FAIL  %s file(s) this plan promises do not exist\n' "$missing"; exit 1; }
[ "$findings" -eq 0 ] || { printf '  FAIL  %s file(s) carry a doc-lint finding\n' "$findings"; exit 1; }
printf '  OK  %s files pass doc-lint\n' "$checked"
