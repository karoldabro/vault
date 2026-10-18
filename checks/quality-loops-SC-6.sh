#!/usr/bin/env bash
# SC-6 of vault/plans/2026-10-18-1257-quality-loops.md — the whole unit suite passes, except tests that already failed.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root" || exit 2
# known: one test name per line, each failing on c0fb5f6, the parent of this plan's first commit
# (./tests/run.sh tests/unit on a clean worktree of c0fb5f6, 2026-10-18).
known=$(cat <<'KNOWN'
an unrecognised type is reported, not silently given the loosest cap
--compare names a constraint the short version dropped
T-10 the plan stage prints the review block with no posture and no base, and the diff stage is unchanged
T-11 spec-symbols reads the cell grammar and names a spec outside the repo by its base name
the stage on two real past specs stays under 50% of their recorded baselines
T-14 step (b2) sits between (b) and (c), plan-probes.md lists the auditors, the rule count is unchanged
every top-level command has a description in its frontmatter
every step file that uses the framework root also says how to resolve it
T-5: a repo registry needs the flag, and --no-repo-code skips it and every yes row
v-team PROPOSE output contract is two-layer and translates panel vocabulary
T-3 the driver builds the envelope, the mounts and the four files
T-4 no forged row, hand-written row or container failure runs anything on the host
templates/VAULT.md and repo VAULT.md expose the same top-level sections
KNOWN
)
out=$(./tests/run.sh tests/unit 2>&1)
grep -q '^1\.\.' <<<"$out" || { echo "tests/unit did not run"; exit 2; }
bad=$(grep '^not ok' <<<"$out" || true)
[ -n "$known" ] && bad=$(grep -vF "$known" <<<"$bad" || true)
[ -z "$bad" ] || { printf '%s\n' "$bad"; exit 1; }
exit 0
