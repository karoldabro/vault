#!/usr/bin/env bash
# probe-sandbox.sh — runs the probes of a review inside containers and writes the rows for bin/probe-panel.sh.
#
# Usage:  bin/probe-sandbox.sh run --repo <clone> --base <commit id> --sandbox-name <vcr-...> --out <dir>
#
# Runs the native framework rows in one container, each framework row that executes repo code in a container of its
# own, and each template rule row of the merge base in a container of its own. It writes framework.tsv,
# framework.status, rules.tsv and rules.status into <dir> (contract C-8). Nothing runs on the host: a failed
# container becomes a `failed:` line. Contract: commands/v-cr/sandbox.md section S8.
#
# Exit: 0 ran (a failed container is an incomplete run, not a failed driver) · 2 usage · 3 not started,
#       with `probe-sandbox: <reason>` on stderr

set -uo pipefail
export LC_ALL=C
IFS=$' \t\n'
unset BASH_ENV ENV CDPATH GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES \
    GIT_EXEC_PATH GIT_CONFIG_PARAMETERS GIT_COMMON_DIR GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0
clean=""; IFS=: read -ra parts <<< "$PATH"
for p in "${parts[@]}"; do case $p in /*) clean="${clean:+$clean:}$p" ;; esac; done
PATH=${clean:-/usr/bin:/bin}; unset clean parts p; IFS=$' \t\n'

root=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)
# shellcheck source=../lib/cr-sandbox.sh
. "$root/lib/cr-sandbox.sh"; . "$root/lib/probe-scope.sh"; . "$root/lib/probe-run.sh"
PROBE_GIT_BIN=$(command -v git || true)
T=$'\t'
dk=${PROBE_SANDBOX_DOCKER:-docker}
work="" name="" child="" started=$SECONDS

usage() { sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { printf 'probe-sandbox: %s\n' "$*" >&2; exit 2; }
notstarted() { printf 'probe-sandbox: %s\n' "$*" >&2; exit 3; }
num() { case ${1:-} in ''|*[!0-9]*) return 1 ;; esac; }
label() { printf 'com.vault.v-cr.sandbox=%s' "$name"; }
rm_by_label() { [ -n "$name" ] || return 0; "$dk" ps -aq --filter "label=$(label)" 2>/dev/null | xargs -r "$dk" rm -f >/dev/null 2>&1; return 0; }
cleanup() {
    [ -z "$child" ] || kill -TERM "$child" 2>/dev/null
    rm_by_label
    if [ -n "$work" ] && cr_sandbox_path_is_safe "$work"; then rm -rf -- "$work"; fi
}
trap cleanup EXIT
trap 'exit 143' INT TERM HUP

case ${1:-} in run) shift ;; -h|--help|help) usage; exit 0 ;; *) usage >&2; exit 2 ;; esac
repo="" base="" out=""
while [ $# -gt 0 ]; do
    [ $# -ge 2 ] || die "$1 needs a value"
    case $1 in --repo) repo=$2 ;; --base) base=$2 ;; --sandbox-name) name=$2 ;; --out) out=$2 ;; *) die "unknown option: $1" ;; esac
    shift 2
done
[[ $name =~ ^vcr-[a-z0-9-]+$ ]] || { name=""; die "--sandbox-name must match vcr-[a-z0-9-]+"; }
[[ $base =~ ^([0-9a-f]{40}|[0-9a-f]{64})$ ]] || die "--base must be a full commit id"
[ -d "$repo" ] || die "--repo needs a directory"
[ -n "$out" ] || die "--out is required"
repo=$(cd "$repo" && pwd); mkdir -p "$out" || die "cannot create $out"; out=$(cd "$out" && pwd)
rm -f "$out/framework.tsv" "$out/framework.status" "$out/rules.tsv" "$out/rules.status"
sroot=$(cr_sandbox_root)
case $sroot$out in *[:,]*) die "a path holding : or , cannot be mounted" ;; esac

# --- settings
TIMEOUT=${PROBE_SANDBOX_TIMEOUT:-180}; RULES_MAX=${PROBE_SANDBOX_RULES_MAX:-20}; TOTAL=${PROBE_SANDBOX_TOTAL:-900}
FILES_MAX=${PROBE_SANDBOX_FILES_MAX:-20000}; BYTES_MAX=${PROBE_SANDBOX_BYTES_MAX:-200000000}
OUT_MAX=${PROBE_OUT_MAX:-5000000}; PTIME=${PROBE_TIMEOUT:-120}
for v in "$TIMEOUT" "$RULES_MAX" "$TOTAL" "$FILES_MAX" "$BYTES_MAX" "$OUT_MAX" "$PTIME"; do num "$v" || die "a PROBE_* limit is not a number"; done
limit() { # limit <key> <default> — a positive number with an optional unit, else the default
    local v n; v=$(cr_sandbox_map_get "$1" | tr 'A-Z' 'a-z') || v=""
    case $v in ''|*[!0-9a-z.]*) printf '%s' "$2"; return ;; esac
    n=${v%%[a-z]*}
    awk -v n="$n" 'BEGIN{exit !(n + 0 > 0)}' && printf '%s' "$v" || printf '%s' "$2"
}
mem=$(limit memory 1g); cpus=$(limit cpus 1); pids=$(limit pids 256)
case $mem in *[!0-9gm]*) mem=1g ;; esac
case $cpus in *[!0-9.]*) cpus=1 ;; esac
case $pids in *[!0-9]*) pids=256 ;; esac
case $mem in *g) [ "${mem%g}" -le 8 ] || mem=8g ;; *m) [ "${mem%m}" -le 8192 ] || mem=8g ;; *) mem=1g ;; esac
awk -v c="$cpus" 'BEGIN{exit !(c>4)}' && cpus=4
[ "$pids" -le 1024 ] || pids=1024

# --- preconditions: nothing starts when one fails
command -v "$dk" >/dev/null 2>&1 || notstarted "docker is not installed"
image=$(cr_probe_image) || notstarted "no usable probe-image in VCR_SANDBOX_MAP"
"$dk" image inspect "$image" >/dev/null 2>&1 || notstarted "the probe image $image is not present"
[ "$(probe_git "$repo" cat-file -t "$base" 2>/dev/null)" = commit ] || notstarted "the merge base is not in the clone"

mkdir -p "$sroot" || die "cannot create $sroot"
work=$(mktemp -d "$sroot/$name-probe.XXXXXX") || die "cannot create a work directory"
cr_sandbox_path_is_safe "$work" || { work=""; die "the work directory is not a safe path"; }
chmod 755 "$work"; mkdir "$work/repo" "$work/fw" "$work/in" "$work/rules" "$work/o"

# --- the copies: the files a probe may read, and the framework code
probe_files "$repo" "$work/files" || notstarted "git cannot read the repository"
nfiles=$(tr -cd '\0' < "$work/files" | wc -c | tr -d ' ')
[ "$nfiles" -le "$FILES_MAX" ] || notstarted "the tree has $nfiles files, over the limit of $FILES_MAX"
nbytes=$( (cd "$repo" && xargs -0 -r stat -c %s -- < "$work/files") | awk '{s+=$1} END{print s+0}') || notstarted "cannot measure the tree"
[ "$nbytes" -le "$BYTES_MAX" ] || notstarted "the tree has $nbytes bytes, over the limit of $BYTES_MAX"
(cd "$repo" && timeout 300 xargs -0 -r cp --parents --no-dereference --no-preserve=all -t "$work/repo" -- < "$work/files") || notstarted "cannot copy the tree"
rm -rf -- "$work/repo/probes"; mkdir "$work/repo/probes"
(cd "$root" && cp -RL --preserve=mode bin lib probes "$work/fw/") || notstarted "cannot copy the framework"
probe_changed "$repo" "$base" "$work/changed.list" 2>"$work/changed.err" || notstarted "git could not list the changed files: $(head -c 200 "$work/changed.err" | tr '\000-\037\177' ' ')"
cp "$work/changed.list" "$work/in/changed.list"
chmod -R a+rX,go-w "$work/repo" "$work/fw" "$work/in"

# --- framework ids, split by whether the row executes repo code
fwreg=$work/fw/probes/registry.tsv
awk -F'\t' '!/^[ \t]*(#|$)/ && $8=="no" {print $1}' "$fwreg" | sort -u > "$work/ids.native"
awk -F'\t' '!/^[ \t]*(#|$)/ && $8=="yes" && !seen[$1]++ {print $1}' "$fwreg" > "$work/ids.tools"
awk -F'\t' '!/^[ \t]*(#|$)/ {print $1}' "$fwreg" | sort -u > "$work/ids.all"

: > "$work/framework.tsv"; : > "$work/framework.status"; : > "$work/rules.tsv"; : > "$work/rules.status"
count=0
blocks=$(( OUT_MAX / 1024 + 2 ))

# run_one <rows file> <status file> <run name> <allowed ids file> <extra -v mount, or -> <probe options...>
run_one() {
    local rows=$1 status=$2 run=$3 allowed=$4 mount=$5; shift 5
    local o=$work/o/$run.$((count + 1)).out e=$work/o/$run.$((count + 1)).err rc size id bad grp
    count=$((count + 1))
    if [ $((SECONDS - started)) -ge "$TOTAL" ]; then printf 'skipped: %s: the time budget is spent\n' "$run" >> "$status"; return 0; fi
    local -a mounts=(-v "$work/fw:/framework:ro" -v "$work/repo:/repo:ro" -v "$work/in:/in:ro")
    [ "$mount" = - ] || mounts+=(-v "$mount")
    ( ulimit -f "$blocks"
      exec timeout -k 5 "$TIMEOUT" "$dk" run --rm --init --name "$name-$count" --label "$(label)" \
          --entrypoint bash --network none --read-only --cap-drop ALL --security-opt no-new-privileges --ipc none --log-driver none --pull never \
          --user 65534:65534 --memory "$mem" --memory-swap "$mem" --cpus "$cpus" --pids-limit "$pids" \
          --tmpfs /tmp:rw,noexec,nosuid,nodev,size=64m \
          -e PROBE_TOOLS_FROM=image -e "PROBE_TIMEOUT=$PTIME" -e "PROBE_OUT_MAX=$OUT_MAX" \
          "${mounts[@]}" "$image" /framework/bin/probe.sh diff --repo /repo --changed-list /in/changed.list "$@"
    ) </dev/null >"$o" 2>"$e" &
    child=$!
    wait "$child"
    rc=$?
    child=""
    rm_by_label
    size=$(( $(wc -c < "$o") > $(wc -c < "$e") ? $(wc -c < "$o") : $(wc -c < "$e") ))
    if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then printf 'failed: %s: timed out after %s seconds\n' "$run" "$TIMEOUT" >> "$status"; return 0; fi
    if [ "$rc" -eq 153 ] || [ "$size" -gt "$OUT_MAX" ]; then printf 'failed: %s: printed more than %s bytes\n' "$run" "$OUT_MAX" >> "$status"; return 0; fi
    if [ "$rc" -gt 2 ]; then printf 'failed: %s: container exit %s\n' "$run" "$rc" >> "$status"; return 0; fi
    # rows: keep an id of this run, check the six fields, and report any other id
    LC_ALL=C tr '\001-\010\013-\037\177' ' ' < "$o" | awk 'NF' > "$o.clean"
    bad=$(awk -F'\t' 'NR==FNR {ok[$0]=1; next} !($1 in ok)' "$allowed" "$o.clean" | wc -l | tr -d ' ')
    while IFS= read -r id; do
        awk -F'\t' -v i="$id" '$1==i' "$o.clean" > "$o.grp"
        [ -s "$o.grp" ] || continue
        if probe_check_rows "$id" "$o.grp" "$o.grp.ok"; then cat "$o.grp.ok" >> "$rows"
        else printf 'failed: %s: malformed row\n' "$id" >> "$status"; fi
    done < "$allowed"
    [ "$bad" -eq 0 ] || printf 'failed: %s: rows named an id that is not a row of this run: %s\n' "$run" "$bad" >> "$status"
    # status lines: the kit's vocabulary, and only for an id of this run
    LC_ALL=C tr '\r' ' ' < "$e" | LC_ALL=C tr -d '\000-\010\013-\037\177' | cut -c1-400 | awk -v allowed="$allowed" '
        BEGIN { while ((getline l < allowed) > 0) ok[l] = 1; ok["files"] = 1 }
        /^probe: / { print; next }
        /^(ran|skipped|absent|failed): [a-z0-9-]+:/ { id = $2; sub(/:$/, "", id); if (id in ok) print }' \
        | grep -Ev '^skipped: [a-z0-9-]+: runs repo code *$' | head -n 200 > "$o.status"
    cat "$o.status" >> "$status"
    # a kit exit of 2 always prints a status line, and an exit of 1 always prints a row
    if [ "$rc" -eq 2 ] && [ ! -s "$o.status" ]; then printf 'failed: %s: exit 2 with no status line\n' "$run" >> "$status"
    elif [ "$rc" -eq 1 ] && [ ! -s "$o.clean" ]; then printf 'failed: %s: exit 1 with no row\n' "$run" >> "$status"; fi
    return 0
}

# --- run 1: native framework rows, one container
run_one "$work/framework.tsv" "$work/framework.status" framework "$work/ids.native" - --no-repo-code
# --- run 1b: each framework row that executes repo code, one container each
while IFS= read -r id; do
    printf '%s\n' "$id" > "$work/allow.$id"
    run_one "$work/framework.tsv" "$work/framework.status" "$id" "$work/allow.$id" - --only "$id"
done < "$work/ids.tools"

# --- run 2: the template rows of the merge base, one container each
tree_entry() { # tree_entry <path> — prints `mode oid size` of a blob of the base, or nothing
    local meta
    meta=$(probe_git "$repo" ls-tree -z -l "$base" -- "$1" 2>/dev/null | tr '\0' '\n' | head -n 1)
    [ -n "$meta" ] || return 1
    printf '%s\n' "$meta" | awk '{ if ($2 == "blob") print $1, $3, $4 }'
}
rst=$work/rules.status
ent=$(tree_entry probes/registry.tsv || true)
if [ -z "$ent" ]; then
    printf 'no-rules: the merge base has no probes/registry.tsv\n' >> "$rst"
else
    read -r mode oid size <<< "$ent"
    if { [ "$mode" != 100644 ] && [ "$mode" != 100755 ]; } || [ "${size:-0}" -gt 262144 ]; then
        printf 'skipped: rules: the base registry is not a regular file\n' >> "$rst"
    else
        probe_git "$repo" cat-file blob "$oid" 2>/dev/null | tr -d '\r' > "$work/base.registry"
        seen=" "; n=0; lines=0
        while IFS= read -r line || [ -n "$line" ]; do
            case $line in ''|'#'*) continue ;; esac
            lines=$((lines + 1))
            if [ "$lines" -gt $((RULES_MAX * 4 + 20)) ]; then printf 'skipped: rules: the registry has too many rows\n' >> "$rst"; break; fi
            id=${line%%"$T"*}; stack=${line#*"$T"}; stack=${stack%%"$T"*}
            shown=$(printf '%s' "$id" | tr -c 'a-z0-9-' '?' | cut -c1-40)
            if ! [[ $id =~ ^[a-z0-9][a-z0-9-]{0,39}$ ]] || [ "$line" != "$("$root/bin/rule-check.sh" row --slug "$id" --stack "$stack" 2>/dev/null)" ]; then
                printf 'skipped: %s: hand-written row does not run in the sandbox\n' "$shown" >> "$rst"; continue
            fi
            if grep -qx -- "$id" "$work/ids.all"; then printf 'skipped: %s: the id also names a framework probe\n' "$id" >> "$rst"; continue; fi
            case $seen in *" $id "*) printf 'skipped: %s: the id repeats\n' "$id" >> "$rst"; continue ;; esac
            seen="$seen$id "
            if [ "$n" -ge "$RULES_MAX" ]; then printf 'skipped: %s: over the limit of %s rule rows\n' "$id" "$RULES_MAX" >> "$rst"; continue; fi
            rent=$(tree_entry "probes/rules/$id.grep" || true); rmode="" roid="" rsize=0
            [ -z "$rent" ] || read -r rmode roid rsize <<< "$rent"
            if { [ "$rmode" != 100644 ] && [ "$rmode" != 100755 ]; } || [ "${rsize:-0}" -gt 8192 ]; then
                printf 'skipped: %s: the rule file is not a regular file\n' "$id" >> "$rst"; continue
            fi
            mkdir -p "$work/rules/$id/rules"
            printf '%s\n' "$line" > "$work/rules/$id/registry.tsv"
            probe_git "$repo" cat-file blob "$roid" > "$work/rules/$id/rules/$id.grep" 2>/dev/null
            chmod -R a+rX,go-w "$work/rules/$id"
            printf '%s\n' "$id" > "$work/allow.$id"
            n=$((n + 1))
            before=$(wc -l < "$rst")
            run_one "$work/rules.tsv" "$rst" "$id" "$work/allow.$id" "$work/rules/$id:/repo/probes:ro" --only "$id" --allow-repo-registry
            tail -n +"$((before + 1))" "$rst" | grep -Eq "^(ran|failed|absent|skipped): $id:" || printf 'failed: %s: no ran line\n' "$id" >> "$rst"
        done < "$work/base.registry"
    fi
fi

# --- write the four files, scrubbed
for f in framework.tsv framework.status rules.tsv rules.status; do
    if [ -s "$work/$f" ]; then cr_redact_runtime < "$work/$f" > "$out/$f"; else : > "$out/$f"; fi
done
exit 0
