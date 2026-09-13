#!/usr/bin/env bash
# SC-2 — `coverage` is built, and its two exit codes mean different things.
#
# U-2 has sat in session-gates-unbuilt.md since 2026-09-04, and a plan relying on an unbuilt check
# closes ungated. Three behaviours, because the dispatcher turns exit 1 into a FAILED session: an
# uncovered criterion is exit 1, a table it cannot parse is exit 2, and all-covered is exit 0. If a
# parse error returned 1, a malformed table would declare the work impossible.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"
built="$root/vault/architecture/session-gates.md"
unbuilt="$root/vault/architecture/session-gates-unbuilt.md"
fail=0

[ -x "$gate" ] || { printf '  MISSING  %s\n' "$gate"; exit 1; }

if grep -qE '^\| U-2 ' "$unbuilt"; then
    printf '  FAIL  U-2 is still listed unbuilt in %s\n' "$unbuilt"; fail=1
fi
grep -qE '^\| `coverage <plan>`' "$built" || { printf '  FAIL  %s subcommand table does not name `coverage <plan>`\n' "$built"; fail=1; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

sc_block() { cat <<'SC'

## Success criteria

| id | criterion | kind | how | check | expect | verdict | evidence |
|----|-----------|------|-----|-------|--------|---------|----------|
| SC-1 | WHEN a plan is graded THE SYSTEM SHALL refuse | delivery | command | `bin/gate.sh` | exit 0 |  |  |
SC
}
head_block() { printf -- '---\ntype: plan\nstatus: proposed\n---\n# fixture — plan\n'; }

# (a) a criterion no work item covers -> exit 1, naming the id
{ head_block; sc_block; cat <<'W'

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | README.md | modify | Edit | none |  | none | TODO |
W
} > "$tmp/uncovered.md"
out=$("$gate" coverage "$tmp/uncovered.md" 2>&1); rc=$?
if [ "$rc" -ne 1 ]; then
    printf '  FAIL  an uncovered criterion exited %s; expected 1\n%s\n' "$rc" "$out"; fail=1
elif ! printf '%s\n' "$out" | grep -q 'SC-1'; then
    printf '  FAIL  the refusal does not name SC-1\n%s\n' "$out"; fail=1
fi

# (b) every criterion covered -> exit 0
{ head_block; sc_block; cat <<'W'

## Work items

| id | file (exact path) | action | tool | constraint | covers | verification | status |
|----|-------------------|--------|------|------------|--------|--------------|--------|
| W-1 | README.md | modify | Edit | none | SC-1 | none | TODO |
W
} > "$tmp/covered.md"
out=$("$gate" coverage "$tmp/covered.md" 2>&1); rc=$?
[ "$rc" -eq 0 ] || { printf '  FAIL  an all-covered plan exited %s; expected 0\n%s\n' "$rc" "$out"; fail=1; }

# (c) no `covers` column at all -> exit 2, NOT 1. due_criteria treats the absent column as
# "every criterion is due"; coverage must refuse to guess instead of failing the session.
{ head_block; sc_block; cat <<'W'

## Work items

| id | file (exact path) | action | tool | constraint | verification | status |
|----|-------------------|--------|------|------------|--------------|--------|
| W-1 | README.md | modify | Edit | none | none | TODO |
W
} > "$tmp/nocol.md"
out=$("$gate" coverage "$tmp/nocol.md" 2>&1); rc=$?
[ "$rc" -eq 2 ] || { printf '  FAIL  a missing `covers` column exited %s; expected 2\n%s\n' "$rc" "$out"; fail=1; }

# (d) no work-items table at all -> exit 2
{ head_block; sc_block; } > "$tmp/notable.md"
out=$("$gate" coverage "$tmp/notable.md" 2>&1); rc=$?
[ "$rc" -eq 2 ] || { printf '  FAIL  a missing `## Work items` table exited %s; expected 2\n%s\n' "$rc" "$out"; fail=1; }

[ "$fail" -eq 0 ] || exit 1
printf '  OK  coverage is built and listed; 1 uncovered, 0 covered, 2 unparseable\n'
