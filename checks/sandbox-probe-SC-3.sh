#!/usr/bin/env bash
# SC-3 — nothing the pull request or a container prints is trusted: a hand-written base row never runs and is
# reported skipped, a forged row or ran line is dropped and reported, a missing ran line reads failed, the rules
# come from the merge base and never from the pull request, and a container failure, a timeout or a missing image
# never runs a probe on the host.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
drv=$root/bin/probe-sandbox.sh
[ -x "$drv" ] || { echo "bin/probe-sandbox.sh not written yet"; exit 2; }
fx=$root/tests/fixtures/sandbox-probe
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
# shellcheck source=../tests/fixtures/sandbox-probe/mk-repo.sh
. "$fx/mk-repo.sh"
R=$tmp/r; sp_mk_repo "$R" "$tmp/marker"; B1=$SP_BASE
mkdir -p "$tmp/bin"; cp "$fx/fake-docker.sh" "$tmp/bin/docker"
export VCR_SANDBOX_ROOT=$tmp/sb VCR_SANDBOX_MAP="probe-image=fake-probes:1" FAKE_DOCKER_LOG=$tmp/log PATH="$tmp/bin:$PATH"
name=vcr-test-github-o-r-pr1-abcd1234-1
go() { rm -rf "$FAKE_DOCKER_LOG" "$tmp/out" "$tmp/marker"; "$drv" run --repo "$R" --base "$B1" --sandbox-name "$name" --out "$tmp/out" "$@"; }
S=$tmp/out

# a hand-written base row that runs a script printing a forged template row
FAKE_DOCKER_MODE=exec go >/dev/null 2>&1 || fail "the exec run failed"
[ ! -e "$tmp/marker" ] || fail "the hand-written row's script ran"
grep -q '^skipped: forge: hand-written row does not run in the sandbox' "$S/rules.status" || fail "the hand-written row must read skipped: $(cat "$S/rules.status")"
grep -q 'forged' "$S/rules.tsv" "$S/framework.tsv" && fail "a forged row reached the rows"
awk -F'\t' '$1=="forge"{f=1} END{exit f}' "$S/rules.tsv" || fail "the hand-written row produced a row"

# the rules come from the base: the rule the pull request adds never runs and is never mounted
awk -F'\t' '$1=="evil"{f=1} END{exit f}' "$S/rules.tsv" || fail "a rule added by the pull request produced a row"
grep -q evil "$FAKE_DOCKER_LOG"/probes.*.list && fail "the pull request's rule was mounted"
grep -q -- '--only evil' "$FAKE_DOCKER_LOG"/run.* && fail "the pull request's rule was run"

# a row and a ran line for an id that did not run
FAKE_DOCKER_MODE=forge go >/dev/null 2>&1
grep -q 'ghost' "$S/framework.tsv" "$S/rules.tsv" "$S/framework.status" "$S/rules.status" && fail "a forged id reached a file"
grep -q '^failed: framework: rows named an id that is not a row of this run: 1$' "$S/framework.status" || fail "the forged row must be reported: $(cat "$S/framework.status")"
# a missing ran line
FAKE_DOCKER_MODE=noran go >/dev/null 2>&1
grep -q '^failed: no-todo: no ran line' "$S/rules.status" || fail "a missing ran line must read failed: $(cat "$S/rules.status")"
grep -q '^ran: no-todo' "$S/rules.status" && fail "a ran line appeared without a container printing it"

# an id that names a framework probe, and a rule file that is a link
R2=$tmp/r2; sp_mk_repo "$R2" "$tmp/marker"
git -C "$R2" checkout -q "$SP_BASE"
"$root/bin/rule-check.sh" row --slug md-links --stack any >> "$R2/probes/registry.tsv"
printf 'no-todo\tany\tdiff\ttrue\t./forge.sh\tnative\tS\tyes\tnone\n' >> "$R2/probes/registry.tsv"
ln -s no-todo.grep "$R2/probes/rules/linked.grep"; "$root/bin/rule-check.sh" row --slug linked --stack any >> "$R2/probes/registry.tsv"
git -C "$R2" add -A; git -C "$R2" -c user.name=t -c user.email=t@t commit -qm more; b2=$(git -C "$R2" rev-parse HEAD)
git -C "$R2" checkout -q main 2>/dev/null
rm -rf "$FAKE_DOCKER_LOG" "$tmp/out2"
FAKE_DOCKER_MODE=exec "$drv" run --repo "$R2" --base "$b2" --sandbox-name "$name" --out "$tmp/out2" >/dev/null 2>&1
grep -q '^skipped: md-links: the id also names a framework probe' "$tmp/out2/rules.status" || fail "a shared id must read skipped: $(cat "$tmp/out2/rules.status")"
grep -q '^skipped: linked: the rule file is not a regular file' "$tmp/out2/rules.status" || fail "a linked rule file must read skipped: $(cat "$tmp/out2/rules.status")"
grep -q -- '--only md-links' "$FAKE_DOCKER_LOG"/run.* && fail "a row with a framework id was run"
[ ! -e "$tmp/marker" ] || fail "a hand-written row that reuses a template id ran"
grep -q '^skipped: no-todo: hand-written row does not run in the sandbox' "$tmp/out2/rules.status" || fail "the same-id hand-written row must read skipped: $(cat "$tmp/out2/rules.status")"
grep -q '^ran: no-todo: ' "$tmp/out2/rules.status" || fail "the template row must still run: $(cat "$tmp/out2/rules.status")"

# a base without probes/
R3=$tmp/r3; mkdir -p "$R3"; git -C "$R3" init -q -b main; printf 'x\n' > "$R3/a.md"; git -C "$R3" add -A
git -C "$R3" -c user.name=t -c user.email=t@t commit -qm base; b3=$(git -C "$R3" rev-parse HEAD)
printf '[m](nope.md)\n' > "$R3/b.md"; git -C "$R3" add -A; git -C "$R3" -c user.name=t -c user.email=t@t commit -qm head
rm -rf "$FAKE_DOCKER_LOG"
FAKE_DOCKER_MODE=exec "$drv" run --repo "$R3" --base "$b3" --sandbox-name "$name" --out "$tmp/out3" >/dev/null 2>&1 || fail "a base without probes/ must not fail the driver"
grep -qx 'no-rules: the merge base has no probes/registry.tsv' "$tmp/out3/rules.status" || fail "a base without probes/ must read no-rules: $(cat "$tmp/out3/rules.status")"
grep -Eq '^(skipped|failed|absent): ' "$tmp/out3/rules.status" && fail "a base without probes/ is not incomplete"
[ "$(cat "$FAKE_DOCKER_LOG/count")" = 4 ] || fail "a base without rules runs the four framework containers only"

# nothing runs on the host when the container cannot run
for mode in fail noimage; do
    rm -rf "$tmp/out" "$FAKE_DOCKER_LOG" "$tmp/marker"
    FAKE_DOCKER_MODE=$mode "$drv" run --repo "$R" --base "$B1" --sandbox-name "$name" --out "$tmp/out" >/dev/null 2>&1; rc=$?
    [ ! -e "$tmp/marker" ] || fail "mode $mode: a repo tool ran on the host"
    if [ "$mode" = noimage ]; then
        [ "$rc" -eq 3 ] || fail "a missing image must exit 3, not start (rc $rc)"
        grep -q '^run ' "$FAKE_DOCKER_LOG/calls" 2>/dev/null && fail "a container started without an image"
        [ ! -s "$tmp/out/framework.tsv" ] || fail "rows appeared without a container"
    else
        [ "$rc" -eq 0 ] || fail "a container failure is an incomplete run (rc $rc)"
        grep -q '^failed: framework: container exit 125' "$tmp/out/framework.status" || fail "the failure must be reported: $(cat "$tmp/out/framework.status")"
        [ ! -s "$tmp/out/framework.tsv" ] || fail "the host filled framework.tsv after a container failure: $(cat "$tmp/out/framework.tsv")"
    fi
done
# no docker at all, and no image configured
rm -rf "$tmp/out"
PROBE_SANDBOX_DOCKER=/nonexistent/docker "$drv" run --repo "$R" --base "$B1" --sandbox-name "$name" --out "$tmp/out" >/dev/null 2>&1
[ $? -eq 3 ] || fail "no docker binary must exit 3"
VCR_SANDBOX_MAP="memory=512m" FAKE_DOCKER_MODE=exec "$drv" run --repo "$R" --base "$B1" --sandbox-name "$name" --out "$tmp/out" >/dev/null 2>"$tmp/err"
[ $? -eq 3 ] && grep -q 'probe-image' "$tmp/err" || fail "no probe-image in VCR_SANDBOX_MAP must exit 3 and name the key: $(cat "$tmp/err")"
exit 0
