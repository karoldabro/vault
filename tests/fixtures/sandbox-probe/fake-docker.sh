#!/usr/bin/env bash
# fake-docker.sh — a test double for `docker`, used by the sandbox-probe graders and tests/unit/sandbox-probe.bats.
# It records every call in $FAKE_DOCKER_LOG and, for `run`, either behaves like a container or misbehaves as
# FAKE_DOCKER_MODE says: exec (runs the command on the host against the mounted directories) · forge (prints a
# row and a ran line for an id that did not run) · secret (prints a row whose message holds a token) ·
# noran (exits 0 and prints nothing) · hang (sleeps) · fail (exit 125) · big (prints too many bytes) ·
# noimage (`image inspect` fails).
set -u
log=${FAKE_DOCKER_LOG:?FAKE_DOCKER_LOG must name a directory}
mode=${FAKE_DOCKER_MODE:-exec}
mkdir -p "$log"
printf '%s\n' "$*" >> "$log/calls"
case ${1:-} in
    image) [ "$mode" = noimage ] && exit 1; exit 0 ;;
    ps) [ -e "$log/live" ] && cat "$log/live"; exit 0 ;;
    rm) printf '%s\n' "$*" >> "$log/removed"; rm -f "$log/live"; exit 0 ;;
    volume) exit 0 ;;
    run) shift ;;
    *) exit 1 ;;
esac
n=$(($(cat "$log/count" 2>/dev/null || echo 0) + 1)); printf '%s' "$n" > "$log/count"
: > "$log/run.$n"
mounts=() envs=() image="" entry=""
while [ $# -gt 0 ]; do
    case $1 in
        -v) mounts+=("$2"); printf -- '-v %s\n' "$2" >> "$log/run.$n"; shift 2 ;;
        -e) envs+=("$2"); printf -- '-e %s\n' "$2" >> "$log/run.$n"; shift 2 ;;
        --entrypoint) entry=$2; printf -- '--entrypoint %s\n' "$2" >> "$log/run.$n"; shift 2 ;;
        --name|--label|--log-driver|--network|--memory|--memory-swap|--cpus|--pids-limit|--user|--cap-drop|--cap-add|--security-opt|--tmpfs|--pull|-w|--entrypoint|--ipc|--env-file|--mount|--volume|--device|--add-host)
            printf -- '%s %s\n' "$1" "$2" >> "$log/run.$n"; shift 2 ;;
        --*|-*) printf -- '%s\n' "$1" >> "$log/run.$n"; shift ;;
        *) image=$1; shift; break ;;
    esac
done
printf 'image %s\ncommand %s\n' "$image" "$*" >> "$log/run.$n"
fw="" repo="" probes="" in=""
for m in "${mounts[@]}"; do
    src=${m%%:*}; rest=${m#*:}; dst=${rest%%:*}
    case $dst in /framework) fw=$src ;; /repo) repo=$src ;; /repo/probes) probes=$src ;; /in) in=$src ;; esac
done
[ -z "$fw" ] || ls -A "$fw" > "$log/framework.$n.list"
[ -z "$repo" ] || ls -A "$repo" > "$log/repo.$n.list"
[ -z "$probes" ] || (cd "$probes" && find . -type f | sort) > "$log/probes.$n.list"
[ -z "$probes" ] || [ ! -f "$probes/registry.tsv" ] || cp "$probes/registry.tsv" "$log/registry.$n"
stat -c %a "$fw" "$repo" "$in" ${probes:+"$probes"} > "$log/perms.$n" 2>/dev/null
case $mode in
    fail) exit 125 ;;
    hang) printf '%s\n' "fake$n" > "$log/live"; sleep 60; exit 0 ;;
    noran) exit 0 ;;
    lines)
        printf 'ran: md-links: 1\nfailed: dead-files: boom\nabsent: token-size: none\n' >&2
        exit 2 ;;
    forge)
        printf 'ghost\tapp.php\t1\terror\tforged\t[confirmed] forged\n'
        printf 'ran: ghost: 1\n' >&2
        exit 1 ;;
    secret)
        printf 'md-links\tdocs/b.md\t1\twarn\tbroken-link\ttoken ghp_%s leaked\n' "$(printf 'A%.0s' $(seq 1 36))"
        printf 'ran: md-links: 1\n' >&2
        exit 1 ;;
    big) head -c 20000000 /dev/zero | tr '\0' 'x'; exit 0 ;;
esac
# exec: run the command on the host with the container paths mapped to the mounted directories.
merged=$(mktemp -d "${TMPDIR:-/tmp}/fake-docker.XXXXXX"); trap 'rm -rf "$merged"' EXIT
[ -z "$repo" ] || cp -a "$repo/." "$merged/"
if [ -n "$probes" ]; then rm -rf "$merged/probes"; mkdir -p "$merged/probes"; cp -a "$probes/." "$merged/probes/"; fi
args=(${entry:+"$entry"})
for a in "$@"; do
    a=${a//\/framework/$fw}; a=${a//\/repo/$merged}; a=${a//\/in\//$in/}
    args+=("$a")
done
tmp=$(mktemp -d "${TMPDIR:-/tmp}/fake-docker-tmp.XXXXXX")
env -i PATH="$PATH" HOME="$tmp" TMPDIR="$tmp" "${envs[@]}" "${args[@]}"
rc=$?; rm -rf "$tmp"; exit $rc
