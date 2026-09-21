#!/usr/bin/env bash
# SC-1 of vault/plans/2026-09-21-1800-plan-time-probes.md — the plan stage of bin/probe-panel.sh.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
panel="$root/bin/probe-panel.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
[ -x "$panel" ] && grep -q -- '--stage' "$panel" || { echo "bin/probe-panel.sh has no --stage yet — not written yet, cannot say"; exit 2; }
fail() { printf '%s\n' "$*"; exit 1; }
T=$(printf '\t')
repo="$tmp/repo"; mkdir -p "$repo/bin" "$repo/lib"
git -C "$repo" init -q && git -C "$repo" config user.email t@t && git -C "$repo" config user.name t
printf '#!/usr/bin/env bash\nrun_thing() { :; }\n' > "$repo/bin/a.sh"
printf 'alpha_one() { :; }\n' > "$repo/lib/x.sh"
git -C "$repo" add -A && git -C "$repo" commit -qm base
spec="$tmp/x.arch.md"
cat > "$spec" <<'SPEC'
# x

## Reuse map

| need | existing symbol | decision | reason |
|------|-----------------|----------|--------|
| run a thing | - | new | searched bin |
| load alpha | lib/x.sh alpha_one | reuse | exists |
| load gamma | lib/x.sh gamma_missing | reuse | absent |
SPEC
run() { "$panel" run --stage plan --spec "$spec" --repo "$repo" "$@" >"$tmp/out" 2>"$tmp/err"; }

run --only similar-symbols; rc=$?
[ "$rc" -eq 0 ] || fail "plan stage exited $rc: $(head -3 "$tmp/err")"
grep -q '^probe-status: complete' "$tmp/out" || fail "no complete status: $(head -3 "$tmp/out")"
grep -q '^<<<PROBE ROWS ' "$tmp/out" && grep -q '^PROBE ROWS END ' "$tmp/out" || fail "the fenced block is missing"
grep -q '^\[confirmed\]$' "$tmp/out" && grep -q '^\[advisory\]$' "$tmp/out" || fail "the tag lines are missing"
awk '/^\[confirmed\]$/ {on=1; next} /^\[advisory\]$/ {on=0} on' "$tmp/out" | grep -q "^similar-symbols${T}bin/a.sh${T}2${T}warn${T}similar-symbol${T}" || fail "no [confirmed] similar-symbol row for bin/a.sh"
grep -q "spec-symbols${T}" "$tmp/out" && fail "an id that was not named ran"

run --only similar-symbols --only spec-symbols; rc=$?
[ "$rc" -eq 0 ] || fail "two ids: exit $rc: $(head -3 "$tmp/err")"
awk '/^\[confirmed\]$/ {on=1; next} /^\[advisory\]$/ {on=0} on' "$tmp/out" | grep -q "^spec-symbols${T}.*${T}error${T}reuse-symbol-missing${T}" || fail "no [confirmed] spec-symbols error row"

run --only nosuch-probe; rc=$?
[ "$rc" -eq 2 ] || fail "unknown id: expected exit 2, got $rc"
grep -q '^probe-status: ERROR' "$tmp/out" || fail "unknown id did not print ERROR: $(head -3 "$tmp/out")"

run --posture own --only similar-symbols; rc=$?
[ "$rc" -eq 2 ] || fail "--posture with --stage plan: expected exit 2, got $rc"
"$panel" run --stage plan --repo "$repo" --only similar-symbols >"$tmp/out" 2>"$tmp/err"; rc=$?
[ "$rc" -eq 2 ] || fail "--stage plan without --spec: expected exit 2, got $rc"
"$panel" run --stage sideways --spec "$spec" --repo "$repo" >"$tmp/out" 2>"$tmp/err"; rc=$?
[ "$rc" -eq 2 ] || fail "unknown stage: expected exit 2, got $rc"
norm() { sed -e '/^out: /d' -e '/^<<<PROBE ROWS /d' -e '/^PROBE ROWS END /d' "$tmp/out"; }
run --only similar-symbols; run2=$(norm); run --only similar-symbols; [ "$run2" = "$(norm)" ] || fail "two runs differ"

# the diff stage is unchanged: --stage is optional and the review graders SC-1 to SC-6 still pass
for n in 1 2 3 4 5 6; do
  "$root/checks/probe-panel-SC-$n.sh" >"$tmp/g" 2>&1 || fail "checks/probe-panel-SC-$n.sh no longer passes: $(head -3 "$tmp/g")"
done
exit 0
