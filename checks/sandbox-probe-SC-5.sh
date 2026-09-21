#!/usr/bin/env bash
# SC-5 — delivery: with real docker and a probe image, `probe-sandbox.sh run` on a fixture repo writes the four
# files with a framework row and a template-rule row, leaves no container behind, and `probe-panel.sh` prints
# both rows as confirmed.
# Exit 0 met, 1 not met, 2 cannot read the question (no docker, or the image cannot be built).
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
drv=$root/bin/probe-sandbox.sh
[ -x "$drv" ] || { echo "bin/probe-sandbox.sh not written yet"; exit 2; }
command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 || { echo "docker is not usable here"; exit 2; }
docker build --quiet -t vault-tests:local "$root/tests" >/dev/null 2>&1 || { echo "cannot build vault-tests:local from tests/Dockerfile"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
# shellcheck source=../tests/fixtures/sandbox-probe/mk-repo.sh
. "$root/tests/fixtures/sandbox-probe/mk-repo.sh"
R=$tmp/r; sp_mk_repo "$R" "$tmp/marker"
name=vcr-test-github-o-r-pr1-abcd1234-$$
export VCR_SANDBOX_ROOT=$tmp/sb VCR_SANDBOX_MAP="probe-image=vault-tests:local"
"$drv" run --repo "$R" --base "$SP_BASE" --sandbox-name "$name" --out "$tmp/out" >"$tmp/stdout" 2>"$tmp/stderr"; rc=$?
[ "$rc" -eq 0 ] || fail "the driver exited $rc: $(cat "$tmp/stderr")"
for f in framework.tsv framework.status rules.tsv rules.status; do [ -f "$tmp/out/$f" ] || fail "missing $f"; done
awk -F'\t' '$1=="md-links" && $2=="docs/b.md"{f=1} END{exit !f}' "$tmp/out/framework.tsv" || fail "no md-links row: $(cat "$tmp/out/framework.tsv") / $(cat "$tmp/out/framework.status")"
awk -F'\t' '$1=="no-todo" && $2=="app.php"{f=1} END{exit !f}' "$tmp/out/rules.tsv" || fail "no rule row: $(cat "$tmp/out/rules.tsv") / $(cat "$tmp/out/rules.status")"
grep -q '^failed: ' "$tmp/out/framework.status" "$tmp/out/rules.status" && fail "a container failed: $(cat "$tmp/out/framework.status" "$tmp/out/rules.status")"
grep -q '^skipped: forge: ' "$tmp/out/rules.status" || fail "the hand-written row must read skipped"
[ -z "$(docker ps -aq --filter "label=com.vault.v-cr.sandbox=$name")" ] || fail "a container is left behind"
[ ! -e "$tmp/sb" ] || [ -z "$(ls -A "$tmp/sb")" ] || fail "the work directory is left behind"
grep -q '^absent: typos: ' "$tmp/out/framework.status" || fail "the repo-local typos ran or was not reported absent: $(cat "$tmp/out/framework.status")"
# a head that deletes probes/ still mounts the base rules
git -C "$R" rm -rq probes; git -C "$R" -c user.name=t -c user.email=t@t commit -qm "drop probes"
"$drv" run --repo "$R" --base "$SP_BASE" --sandbox-name "$name" --out "$tmp/out2" >/dev/null 2>"$tmp/stderr2" || fail "a head without probes/ failed: $(cat "$tmp/stderr2")"
awk -F'\t' '$1=="no-todo" && $2=="app.php"{f=1} END{exit !f}' "$tmp/out2/rules.tsv" || fail "a head without probes/ lost the rule row: $(cat "$tmp/out2/rules.status")"
out=$("$root/bin/probe-panel.sh" run --posture sandbox --repo "$R" --base "$SP_BASE" --rows-from "$tmp/out" --out "$tmp/panel" 2>/dev/null)
awk -F'\t' '$1=="md-links"' "$tmp/panel/confirmed.tsv" | grep -q . && awk -F'\t' '$1=="no-todo"' "$tmp/panel/confirmed.tsv" | grep -q . || fail "the panel must print both rows as confirmed: $out"
exit 0
