#!/usr/bin/env bash
# SC-4 of vault/plans/2026-10-18-1257-quality-loops.md — the code-review panel critiques design and drops what static tools report.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
fail() { printf '%s\n' "$*"; exit 1; }
c=commands/_shared/critic-panel.md; q=personas/_shared/quality.md; p=personas/_shared/performance.md; r=personas/_resolution.md
for f in "$c" "$q" "$p" "$r"; do [ -r "$f" ] || fail "$f is missing"; done
grep -q 'bin/vault-check.sh static' "$c" || fail "$c does not put the static output in the critic envelope"
grep -qi 'is dropped' "$c" || fail "$c has no drop rule for findings that restate a static check"
for x in 'path:line' 'rewrite' 'measurement' 'package'; do grep -qi "$x" "$c" || fail "$c does not name design evidence: $x"; done
grep -qi 'simpler' "$q" || fail "$q does not own simpler solutions"
grep -qi 'package' "$q" || fail "$q does not own existing packages"
m=$(grep -niE 'nesting|dead code|copy-pasted' "$q" | head -1 | cut -d: -f1); cl=$(grep -niE 'no static check ran' "$q" | head -1 | cut -d: -f1)
[ -n "$m" ] && { [ -n "$cl" ] && [ "$cl" -lt "$m" ]; } || [ -z "$m" ] || fail "$q lists mechanical items outside the no-static-check condition"
grep -qi 'scratch worktree' "$c" || fail "$c does not require a rewrite to be applied and re-run"
grep -qi 'approach' "$p" || fail "$p does not own the cost of the approach"
grep -qiE 'diff review.*(quality.*correctness|correctness.*quality)' "$r" || fail "$r does not seat quality and correctness by default on diff review"
exit 0
