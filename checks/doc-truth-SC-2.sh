#!/usr/bin/env bash
# SC-2 — what vault/architecture/session-gates.md says decides an `artifact` criterion is what
# bin/gate.sh actually does with one.
#
# Run the real gate against a plan whose artifact row names a pattern that is NOT in the file, and
# see whether it refuses. cmd_verdict executes only `how: command` rows, so an artifact row is
# decided by whatever verdict the session typed. A document that says otherwise closes criteria
# against files nobody opened. If artifact checking is ever built, this check fails and the document
# claim must come back with it.
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(dirname "$here")
gate="$root/bin/gate.sh"
doc="$root/vault/architecture/session-gates.md"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/vault/plans"
: > "$tmp/empty-artifact.md"

cat > "$tmp/vault/plans/probe.md" <<'PLAN'
---
type: plan
no-runtime: probe fixture, exercises the gate itself
---

# probe — plan

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN the gate reads this row THE SYSTEM SHALL open the named file | unit | artifact | `empty-artifact.md` contains `THIS-STRING-IS-NOT-IN-THE-FILE` | the pattern is present | MET | `empty-artifact.md:1` |
PLAN

out=$("$gate" verdict "$tmp/vault/plans/probe.md" --run 2>&1); rc=$?

claims_checked=0
grep -q 'the gate checks both' "$doc" && claims_checked=1

if [ "$rc" -eq 0 ]; then
    # The gate did not open the file. The document must not claim it did.
    if [ "$claims_checked" -eq 1 ]; then
        printf 'gate closed an artifact row MET against a file lacking the pattern (exit %d), but %s still says "the gate checks both"\n' "$rc" "$doc" >&2
        exit 1
    fi
    exit 0
fi

# The gate refused: artifact checking exists. The document should say so again.
if [ "$claims_checked" -eq 0 ]; then
    printf 'gate now verifies artifact rows (exit %d: %s) — restore the "the gate checks both" claim in %s\n' "$rc" "$(tail -1 <<<"$out")" "$doc" >&2
    exit 1
fi
exit 0
