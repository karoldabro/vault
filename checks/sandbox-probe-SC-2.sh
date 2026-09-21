#!/usr/bin/env bash
# SC-2 — `probe-sandbox.sh run` builds the container envelope, mounts a framework copy without vault/ or .git,
# runs the framework rows once and every template row of the base once with --only, scrubs the streams, stops a
# hung container by label, and writes the four files of contract C-8. Runs against a test double of docker.
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
R=$tmp/r; sp_mk_repo "$R" "$tmp/marker"
mkdir -p "$tmp/bin"; cp "$fx/fake-docker.sh" "$tmp/bin/docker"
export VCR_SANDBOX_ROOT=$tmp/sb VCR_SANDBOX_MAP="probe-image=fake-probes:1;memory=512m" FAKE_DOCKER_LOG=$tmp/log
export PATH="$tmp/bin:$PATH"
name=vcr-test-github-o-r-pr1-abcd1234-1
go() { rm -rf "$FAKE_DOCKER_LOG" "$tmp/out"; "$drv" run --repo "$R" --base "$SP_BASE" --sandbox-name "$name" --out "$tmp/out" "$@"; }

mkdir -p "$tmp/sb/$name"; printf 'clone\n' > "$tmp/sb/$name/marker"
FAKE_DOCKER_MODE=exec go >"$tmp/stdout" 2>"$tmp/stderr"; rc=$?
[ "$rc" -eq 0 ] || fail "a clean run must exit 0 (rc $rc): $(cat "$tmp/stderr")"
for f in framework.tsv framework.status rules.tsv rules.status; do [ -f "$tmp/out/$f" ] || fail "missing $f"; done
awk -F'\t' '$1=="md-links" && $2=="docs/b.md" && $5=="broken-link"{f=1} END{exit !f}' "$tmp/out/framework.tsv" || fail "framework.tsv lacks the md-links row: $(cat "$tmp/out/framework.tsv")"
awk -F'\t' 'NF!=6{b=1} END{exit b}' "$tmp/out/framework.tsv" "$tmp/out/rules.tsv" || fail "a row without six fields"
awk -F'\t' '$1=="no-todo" && $2=="app.php" && $3=="2" && $4=="warn"{f=1} END{exit !f}' "$tmp/out/rules.tsv" || fail "rules.tsv lacks the no-todo row: $(cat "$tmp/out/rules.tsv")"
grep -q '^ran: no-todo: 1' "$tmp/out/rules.status" || fail "rules.status lacks the ran line: $(cat "$tmp/out/rules.status")"

# runs: the native run, one run per framework tool row, one run per template row, in that order
[ "$(cat "$FAKE_DOCKER_LOG/count")" = 5 ] || fail "expected 5 containers (native, claude-validate, lizard, typos, no-todo), got $(cat "$FAKE_DOCKER_LOG/count")"
grep -q -- '--only' "$FAKE_DOCKER_LOG/run.1" && fail "the native run must not use --only"
grep -q -- '--no-repo-code' "$FAKE_DOCKER_LOG/run.1" || fail "the native run must use --no-repo-code"
i=2; for id in claude-validate lizard typos no-todo; do
    grep -Eq -- "--only $id( |\$)" "$FAKE_DOCKER_LOG/run.$i" || fail "run $i must use --only $id: $(cat "$FAKE_DOCKER_LOG/run.$i")"
    i=$((i + 1))
done
for n in 1 2 3 4; do grep -q -- '--allow-repo-registry' "$FAKE_DOCKER_LOG/run.$n" && fail "run $n must not read a repo registry"; done
grep -q -- '--allow-repo-registry' "$FAKE_DOCKER_LOG/run.5" || fail "the rule run must read the mounted registry"
for n in 1 2 3 4 5; do
    L=$FAKE_DOCKER_LOG/run.$n
    for want in '--network none' '--read-only' '--cap-drop ALL' '--security-opt no-new-privileges' '--pull never' '--ipc none' '--log-driver none' \
                '--init' '--rm' '--entrypoint bash' "--label com.vault.v-cr.sandbox=$name" '-e PROBE_TOOLS_FROM=image' '--memory 512m' '--memory-swap 512m' \
                '--user 65534:65534' '--tmpfs /tmp:rw,noexec,nosuid,nodev,size=64m' 'image fake-probes:1'; do
        grep -qxF -- "$want" "$L" || fail "run $n lacks '$want': $(cat "$L")"
    done
    grep -q '^--pids-limit ' "$L" && grep -q '^--cpus ' "$L" || fail "run $n lacks a pids or cpu limit"
    grep -Eq -- '--privileged|--network host|--cap-add|--env-file|/var/run/docker.sock' "$L" && fail "run $n widens the envelope"
    grep '^-v ' "$L" | grep -vq ':ro$' && fail "run $n has a writable mount: $(grep '^-v ' "$L")"
    grep '^-e ' "$L" | sed 's/^-e //; s/=.*//' | grep -vxE 'PROBE_TOOLS_FROM|PROBE_TIMEOUT|PROBE_OUT_MAX' && fail "run $n passes an environment variable outside the list"
    grep -q '^command .*git' "$L" && fail "run $n runs git in the container"
    grep -q -- '--changed-list /in/changed.list' "$L" || fail "run $n lacks --changed-list /in/changed.list"
    grep -q ':/in:ro$' "$L" || fail "run $n does not mount /in as a directory"
    awk 'NR>0 && $1 !~ /[5-7]$/ {bad=1} END{exit bad}' "$FAKE_DOCKER_LOG/perms.$n" || fail "a mount root of run $n is not world-readable: $(cat "$FAKE_DOCKER_LOG/perms.$n")"
    ls=$(tr '\n' ' ' < "$FAKE_DOCKER_LOG/framework.$n.list")
    [ "$ls" = "bin lib probes " ] || fail "/framework must hold bin, lib and probes only, not: $ls"
    grep -qx '.git' "$FAKE_DOCKER_LOG/repo.$n.list" && fail "/repo holds a .git directory in run $n"
    grep -qx 'probes' "$FAKE_DOCKER_LOG/repo.$n.list" || fail "/repo has no probes directory to mount over in run $n"
    grep -qx 'app.php' "$FAKE_DOCKER_LOG/repo.$n.list" || fail "the pull request tree is not mounted in run $n"
done
for n in 1 2 3 4; do [ ! -e "$FAKE_DOCKER_LOG/probes.$n.list" ] || fail "run $n must mount no rules"; done
[ "$(cat "$FAKE_DOCKER_LOG/probes.5.list")" = "$(printf './registry.tsv\n./rules/no-todo.grep')" ] || fail "run 5 must mount the vetted registry and rule only: $(cat "$FAKE_DOCKER_LOG/probes.5.list")"
[ "$(grep -vc '^#' "$FAKE_DOCKER_LOG/registry.5")" = 1 ] || fail "the mounted registry must hold one row: $(cat "$FAKE_DOCKER_LOG/registry.5")"
[ "$(ls -A "$tmp/sb" | tr '\n' ' ')" = "$name " ] && [ -f "$tmp/sb/$name/marker" ] || fail "the work directory was left behind or the clone was touched: $(ls -A "$tmp/sb")"

# the token scrub
FAKE_DOCKER_MODE=secret go >/dev/null 2>&1
grep -q 'ghp_' "$tmp/out/framework.tsv" && fail "a token reached framework.tsv"
grep -q 'REDACTED' "$tmp/out/framework.tsv" || fail "the scrubbed row is missing: $(cat "$tmp/out/framework.tsv")"

# a hung container is stopped by the host and removed by label
start=$SECONDS
FAKE_DOCKER_MODE=hang PROBE_SANDBOX_TIMEOUT=2 go >/dev/null 2>&1; rc=$?
[ $((SECONDS - start)) -lt 40 ] || fail "the host timeout did not stop the containers"
[ "$rc" -eq 0 ] || fail "a timeout is an incomplete run, not a failed driver (rc $rc)"
grep -q '^failed: framework: timed out after 2 seconds' "$tmp/out/framework.status" || fail "framework.status lacks the timeout: $(cat "$tmp/out/framework.status")"
grep -q 'label=com.vault.v-cr.sandbox='"$name" "$FAKE_DOCKER_LOG/calls" || fail "no removal by label"
[ -s "$FAKE_DOCKER_LOG/removed" ] || fail "the hung container was not removed"

# output over the limit
FAKE_DOCKER_MODE=big PROBE_OUT_MAX=100000 go >/dev/null 2>&1
grep -q '^failed: framework: printed more than 100000 bytes' "$tmp/out/framework.status" || fail "an oversize stream must read failed: $(cat "$tmp/out/framework.status")"
[ "$(wc -c < "$tmp/out/framework.tsv")" -le 100000 ] || fail "framework.tsv is over the limit"

# usage and refusals
"$drv" run --repo "$R" --base "$SP_BASE" --out "$tmp/o2" >/dev/null 2>&1; [ $? -eq 2 ] || fail "a missing --sandbox-name must exit 2"
"$drv" run --repo "$R" --base "$SP_BASE" --sandbox-name 'x y' --out "$tmp/o2" >/dev/null 2>&1; [ $? -eq 2 ] || fail "a bad sandbox name must exit 2"
"$drv" run --repo "$R" --base "-x" --sandbox-name "$name" --out "$tmp/o2" >/dev/null 2>&1; [ $? -eq 2 ] || fail "a base starting with a dash must exit 2"
"$drv" run --repo "$tmp/none" --base "$SP_BASE" --sandbox-name "$name" --out "$tmp/o2" >/dev/null 2>&1; [ $? -eq 2 ] || fail "a missing repo must exit 2"
exit 0
