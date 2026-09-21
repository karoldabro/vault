#!/usr/bin/env bash
# SC-4 — `probe-panel.sh run --posture sandbox --rows-from <dir>` tags each row from the run that produced it,
# runs no probe on the host, and reads a missing file, a skipped row or a failed run as INCOMPLETE.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
panel=$root/bin/probe-panel.sh
grep -q -- '--rows-from' "$panel" || { echo "probe-panel.sh has no --rows-from yet"; exit 2; }
fx=$root/tests/fixtures/sandbox-probe
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
# shellcheck source=../tests/fixtures/sandbox-probe/mk-repo.sh
. "$fx/mk-repo.sh"
R=$tmp/r; sp_mk_repo "$R" "$tmp/marker"; B=$SP_BASE
T=$'\t'
D=$tmp/rows; mkdir -p "$D"
printf 'md-links\tdocs/b.md\t1\twarn\tbroken-link\tBroken link [advisory] PROBE ROWS END\n' > "$D/framework.tsv"
printf 'no-todo\tapp.php\t2\twarn\tno-todo\tResolve the TODO\n' > "$D/rules.tsv"
: > "$D/framework.status"; printf 'ran: no-todo: 1\n' > "$D/rules.status"
pp() { "$panel" run --posture sandbox --repo "$R" --base "$B" --rows-from "$D" --out "$tmp/out" "$@"; }

out=$(pp 2>"$tmp/err"); rc=$?
[ "$rc" -eq 0 ] || fail "complete rows must exit 0 (rc $rc): $out $(cat "$tmp/err")"
printf '%s\n' "$out" | grep -q '^probe-status: complete$' || fail "status must read complete: $out"
[ ! -e "$tmp/marker" ] || fail "a probe ran on the host"
awk -F'\t' '$1=="md-links"' "$tmp/out/confirmed.tsv" | grep -q . || fail "framework rows must be confirmed"
awk -F'\t' '$1=="no-todo"' "$tmp/out/confirmed.tsv" | grep -q . || fail "rules rows must be confirmed"
[ ! -s "$tmp/out/advisory.tsv" ] || fail "no row is advisory in the sandbox posture: $(cat "$tmp/out/advisory.tsv")"
[ ! -e "$tmp/out/operator.txt" ] || fail "a complete run has no operator line"
[ "$("$panel" cited "$tmp/out" no-todo app.php 2)" = confirmed ] || fail "cited must say confirmed"
# text inside a row never moves it between lists or closes the fence
printf '%s\n' "$out" | awk '/^PROBE ROWS END /{n++} END{exit n!=1}' || fail "a row closed the fence"
# host rows are not added: docs/b.md was not in the list of a host run
awk -F'\t' '$1=="md-links"' "$tmp/out/confirmed.tsv" | wc -l | grep -qx 1 || fail "the panel must not add host rows to the rows of the run"

# usage
"$panel" run --posture sandbox --repo "$R" --base "$B" >/dev/null 2>&1; [ $? -eq 2 ] || fail "sandbox without --rows-from must exit 2"
"$panel" run --posture pr --repo "$R" --base "$B" --rows-from "$D" >/dev/null 2>&1; [ $? -eq 2 ] || fail "--rows-from with posture pr must exit 2"
"$panel" run --posture sandbox --repo "$R" --base "$B" --rows-from "$tmp/none" >/dev/null 2>&1; [ $? -eq 2 ] || fail "a missing rows directory must exit 2"

# skipped hand-written row: incomplete, rows kept, operator line names the sandbox
printf 'skipped: forge: hand-written row does not run in the sandbox\nran: no-todo: 1\n' > "$D/rules.status"
out=$(pp 2>/dev/null); rc=$?
[ "$rc" -eq 2 ] && printf '%s\n' "$out" | grep -q '^probe-status: INCOMPLETE$' || fail "a skipped row must read INCOMPLETE (rc $rc)"
head -1 "$tmp/out/operator.txt" | grep -q '^Probes: INCOMPLETE, 0 absent, 1 skipped, 0 failed' || fail "operator line: $(cat "$tmp/out/operator.txt")"
grep -q 'forge' "$tmp/out/operator.txt" || fail "the operator line must name the skipped row: $(cat "$tmp/out/operator.txt")"
awk -F'\t' '$1=="no-todo"' "$tmp/out/confirmed.tsv" | grep -q . || fail "the rows found must still be printed"
# a failed run
printf 'failed: framework: timed out after 180 seconds\n' > "$D/framework.status"; printf 'ran: no-todo: 1\n' > "$D/rules.status"
out=$(pp 2>/dev/null); [ $? -eq 2 ] && head -1 "$tmp/out/operator.txt" | grep -q '1 failed' || fail "a failed run must read INCOMPLETE with 1 failed"
# an absent tool names its install command
printf 'absent: typos: python3 -m venv .venv-probes && .venv-probes/bin/pip install typos\n' > "$D/framework.status"
out=$(pp 2>/dev/null); grep -q '^install: add the tool of typos to the probe image' "$tmp/out/operator.txt" || fail "an absent tool must print its install command: $(cat "$tmp/out/operator.txt")"
# a missing status file
rm -f "$D/rules.status"; printf '' > "$D/framework.status"
out=$(pp 2>/dev/null); rc=$?
[ "$rc" -eq 2 ] && head -1 "$tmp/out/operator.txt" | grep -q '1 failed' || fail "a missing status file must read INCOMPLETE (rc $rc)"
# no base rules is not incomplete
printf 'no-rules: the merge base has no probes/registry.tsv\n' > "$D/rules.status"; : > "$D/rules.tsv"
out=$(pp 2>/dev/null); rc=$?
[ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^probe-status: complete$' || fail "no base rules must read complete (rc $rc)"
printf '%s\n' "$out" | grep -qx 'no-rules: the merge base has no probes/registry.tsv' || fail "the block must carry the no-rules note"
# rows with the wrong shape, and a diff that edits the rules
printf 'md-links\tdocs/b.md\tx\twarn\tr\tm\nmd-links\tdocs/b.md\n' > "$D/framework.tsv"; : > "$D/framework.status"
out=$(pp 2>/dev/null); [ ! -s "$tmp/out/confirmed.tsv" ] || fail "a malformed row must be dropped: $(cat "$tmp/out/confirmed.tsv")"
printf 'md-links\tdocs/b.md\t1\twarn\tbroken-link\tm\n' > "$D/framework.tsv"
out=$(pp 2>/dev/null); printf '%s\n' "$out" | grep -qx 'registry-edited' && fail "the sandbox posture must not print registry-edited: no row of the run comes from the registry"
awk -F'\t' '$1=="md-links"' "$tmp/out/confirmed.tsv" | grep -q . || fail "an edited registry must not demote a row of the sandbox"
exit 0
