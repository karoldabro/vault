#!/usr/bin/env bash
# probe-run.sh — runs one registry row inside its limits and checks the rows it prints.
# Sourced by bin/probe.sh after lib/probe-emit.sh, probe-scope.sh, probe-registry.sh and probe-parsers.sh.
# The core exports PROBE_REPO, PROBE_FRAMEWORK, PROBE_FILES and PROBE_SPEC, and sets PROBE_TMP,
# PROBE_MAXRANK, PROBE_NO_REPO_CODE and PROBE_CHANGED_FILE (a newline list of changed files, empty outside diff).
# It counts findings in PROBE_FOUND and sets PROBE_BAD=1 when a probe was absent or failed.
# Contract: commands/_shared/probe-kit.md.

[ -n "${PROBE_RUN_LOADED:-}" ] && return 0
PROBE_RUN_LOADED=1
PROBE_FOUND=0 PROBE_BAD=0 PROBE_N=0 PROBE_JOB="" PROBE_WD=""

probe_rank() { case $1 in S) echo 1 ;; M) echo 2 ;; *) echo 3 ;; esac; }

probe_status() { printf '%s\n' "$*" >&2; }

# probe_abort — stops the running job's process group and its watchdog. bin/probe.sh calls it on a signal.
probe_abort() {
    [ -z "$PROBE_JOB" ] || { kill -TERM -- "-$PROBE_JOB" 2>/dev/null; sleep 1; kill -KILL -- "-$PROBE_JOB" 2>/dev/null; }
    [ -z "$PROBE_WD" ] || kill "$PROBE_WD" 2>/dev/null
    return 0
}

# probe_exec <cwd> <trust> <cell> <outfile> <errfile> — runs a cell with bash in <cwd>, as a job of its own
# process group. A watchdog stops the group after PROBE_TIMEOUT seconds (TERM, then KILL after 2). Standard
# output is written to <outfile> under a size limit of PROBE_OUT_MAX bytes. Sets PROBE_RC: the exit code,
# 124 after a timeout, 153 when the size limit stopped it. Whatever is left of the group is killed afterwards.
probe_exec() {
    local cwd=$1 trust=$2 cell=$3 out=$4 err=$5 to=${PROBE_TIMEOUT:-120} blocks
    blocks=$(( (${PROBE_OUT_MAX:-5000000} + 1023) / 1024 ))
    rm -f "$out.timeout"
    set -m
    (
        cd "$cwd" || exit 127
        PATH=$(probe_path "$trust" "$cwd"); export PATH
        ulimit -f "$blocks" 2>/dev/null
        ulimit -t $((to * 2)) 2>/dev/null
        exec bash -c "$cell"
    ) </dev/null >"$out" 2>"$err" &
    PROBE_JOB=$!
    set +m
    (
        i=0
        while [ "$i" -lt "$to" ]; do
            sleep 1
            kill -0 "$PROBE_JOB" 2>/dev/null || exit 0
            i=$((i + 1))
        done
        : > "$out.timeout"
        kill -TERM -- "-$PROBE_JOB" 2>/dev/null
        sleep 2
        kill -KILL -- "-$PROBE_JOB" 2>/dev/null
    ) >/dev/null 2>&1 &
    PROBE_WD=$!
    wait "$PROBE_JOB" 2>/dev/null
    PROBE_RC=$?
    kill "$PROBE_WD" 2>/dev/null; wait "$PROBE_WD" 2>/dev/null
    kill -KILL -- "-$PROBE_JOB" 2>/dev/null
    PROBE_JOB="" PROBE_WD=""
    [ -e "$out.timeout" ] && PROBE_RC=124
    return 0
}

# probe_detect <cell> <trust> <repo> — 0 when the row's stack is present in the repo.
probe_detect() {
    local d="$PROBE_TMP/detect.$((PROBE_N += 1))"
    probe_exec "$3" "$2" "$1" "$d.out" "$d.err"
    [ "$PROBE_RC" -eq 0 ]
}

# probe_check_rows <id> <infile> <outfile> — validates a probe's rows and writes them with field 1 set to the
# registry id and control bytes removed. Returns 1 when any line is malformed.
probe_check_rows() {
    LC_ALL=C tr '\001-\010\013-\037\177' ' ' < "$2" | LC_ALL=C awk -F'\t' -v id="$1" '
        NF != 6 || $4 !~ /^(error|warn|info)$/ || $3 !~ /^[0-9]+$/ || $2 == "" || length($2) > 500 { bad = 1; exit }
        $2 ~ /^\// || $2 ~ /(^|\/)\.\.(\/|$)/ { bad = 1; exit }
        { print id "\t" $2 "\t" $3 "\t" $4 "\t" substr($5, 1, 60) "\t" substr($6, 1, 240) }
        END { exit bad }
    ' > "$3"
}

# probe_skip_reason <trust> <cost> — prints why a detected row must not run under the current options.
probe_skip_reason() {
    if [ "$1" = yes ] && [ "${PROBE_NO_REPO_CODE:-0}" = 1 ]; then echo "runs repo code"
    elif [ "$(probe_rank "$2")" -gt "${PROBE_MAXRANK:-3}" ]; then echo "cost $2 is above the limit"
    fi
}

# probe_exit_reason <parser> — prints why the exit code in PROBE_RC means the probe failed. A tool row
# survives any exit code below 126, because tools such as lizard and typos exit nonzero on findings.
probe_exit_reason() {
    if [ "$PROBE_RC" -eq 124 ]; then echo "timed out after ${PROBE_TIMEOUT:-120} seconds"
    elif [ "$PROBE_RC" -eq 153 ]; then echo "printed more than ${PROBE_OUT_MAX:-5000000} bytes"
    elif [ "$1" = native ] && [ "$PROBE_RC" -ge 2 ]; then echo "exit $PROBE_RC"
    elif [ "$1" != native ] && [ "$PROBE_RC" -ge 126 ]; then echo "exit $PROBE_RC"
    fi
}

# probe_collect <id> <parser> <outfile> <rowsfile> — runs the row's parser on its output, then checks the rows.
# Prints a failure reason, or `@absent` when the parser needs jq and it is missing.
probe_collect() {
    local id=$1 parser=$2 out=$3 rows=$4
    if [ "$parser" != native ]; then
        if [ "$PROBE_RC" -ne 0 ] && [ ! -s "$out" ]; then echo "exit $PROBE_RC with no output"; return 0; fi
        if [[ $parser =~ ^parse_[a-z0-9_]+$ ]] && declare -F "$parser" >/dev/null; then
            "$parser" "$id" "$PROBE_REPO" < "$out" > "$rows.raw" 2>/dev/null
            case $? in
                0) mv "$rows.raw" "$out" ;;
                3) echo "@absent"; return 0 ;;
                *) echo "the parser $parser failed"; return 0 ;;
            esac
        else
            echo "the parser $parser is not a function of lib/probe-parsers.sh"; return 0
        fi
    fi
    probe_check_rows "$id" "$out" "$rows" || echo "printed a malformed row"
}

# probe_run_row <origin> <id> <stack> <stage> <detect> <run> <parser> <cost> <trust> <install>
probe_run_row() {
    local origin=$1 id=$2 detect=$5 run=$6 parser=$7 cost=$8 trust=$9 install=${10} n out err rows reason
    n=$((PROBE_N += 1)); out="$PROBE_TMP/run.$n.out"; err="$PROBE_TMP/run.$n.err"; rows="$PROBE_TMP/run.$n.rows"
    [ "$origin" = repo ] && trust=yes
    if [ "$origin" = repo ] && [ "${PROBE_NO_REPO_CODE:-0}" = 1 ]; then
        probe_status "skipped: $id: repo registry rows run repo code"; return 0
    fi
    probe_detect "$detect" "$trust" "$PROBE_REPO" || return 0
    reason=$(probe_skip_reason "$trust" "$cost")
    if [ -n "$reason" ]; then probe_status "skipped: $id: $reason"; return 0; fi
    if ! probe_tool_present "$run" "$trust" "$PROBE_REPO"; then
        install=$(probe_sanitize "$install"); probe_status "absent: $id: ${install:0:300}"; PROBE_BAD=1; return 0
    fi
    probe_exec "$PROBE_REPO" "$trust" "$run" "$out" "$err"
    reason=$(probe_exit_reason "$parser")
    [ -n "$reason" ] || reason=$(probe_collect "$id" "$parser" "$out" "$rows")
    if [ "$reason" = "@absent" ]; then probe_status "absent: $id: jq"; PROBE_BAD=1; return 0; fi
    if [ -n "$reason" ]; then
        probe_status "failed: $id: $reason $(head -c 200 "$err" 2>/dev/null | head -1 | LC_ALL=C tr '\000-\037\177' ' ')"
        PROBE_BAD=1; return 0
    fi
    probe_keep_changed "$rows"
    n=$(grep -c '' "$rows")
    PROBE_FOUND=$((PROBE_FOUND + n))
    cat "$rows"
    probe_status "ran: $id: $n"
}

# probe_keep_changed <rowsfile> — under diff, keeps the rows whose file is in the changed list.
probe_keep_changed() {
    [ -n "${PROBE_CHANGED_FILE:-}" ] || return 0
    if [ ! -s "$PROBE_CHANGED_FILE" ]; then : > "$1"; return 0; fi
    LC_ALL=C awk -F'\t' 'NR == FNR { keep[$0] = 1; next } $2 in keep' "$PROBE_CHANGED_FILE" "$1" > "$1.kept" && mv "$1.kept" "$1"
}
