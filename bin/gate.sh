#!/usr/bin/env bash
# gate.sh — the checks a /v-* session must pass before it may plan, approve or close work.
#
# Contract: vault/architecture/session-gates.md. Every subcommand returns exit 1 with the missing
# thing named. A command step that reaches a nonzero exit stops the lifecycle; it never proceeds
# with a warning. doc-lint.sh checks that a document is well formed; this checks that a session did
# the work the document claims.
#
# The plan artifact is the session's machine-readable state. Every check reads its markdown tables;
# there is no second state file to drift out of sync with the plan nobody updated.
#
# Usage:  bin/gate.sh criteria <plan>          success criteria exist and can be decided
#         bin/gate.sh verdict  <plan> [--run]  every criterion is MET with evidence
#         bin/gate.sh all      <plan> --phase <propose|approve|close>
#         bin/gate.sh --help
#
# --run executes each `how: command` criterion's check and compares the real exit code to the
# verdict the plan claims. It runs commands written in a markdown file, so it is opt-in and prints
# every command before running it. Without --run, `verdict` only checks that the plan is internally
# honest: a MET row must carry evidence, and evidence must be a command or a path:line.
#
# `expect` is prose and is not parsed, with one exception: `exit N` in an expect cell sets the exit
# code that counts as met. Everything else treats exit 0 as met.
#
# Env:    GATE=off   skip every check and exit 0. Whole-run only, no per-check suppression: a gate
#                    that can be silenced one check at a time gets silenced.
#
# Exit: 0 clean (or skipped)
#       1 the gate refuses — the session may not continue
#       2 usage error, or a table this script cannot parse (never treated as a pass)

set -euo pipefail

US=$'\037'          # cell separator for parsed rows; never appears in markdown
violations=0
notes=0

# ---------------------------------------------------------------------------- output

refuse() { printf '  REFUSED  %s\n' "$*" >&2; violations=$((violations + 1)); }
note()   { printf '  note     %s\n' "$*" >&2; notes=$((notes + 1)); }
die()    { printf 'gate: %s\n' "$*" >&2; exit 2; }

usage() {
    sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------------------- parsing

# Read a frontmatter key. Prints the value, or nothing when the key is absent.
frontmatter_get() {
    local file=$1 key=$2
    awk -v k="$key" '
        NR == 1 && $0 == "---" { inside = 1; next }
        inside && $0 == "---"  { exit }
        inside && index($0, k ":") == 1 {
            sub(/^[^:]*: */, "")
            print
            exit
        }
    ' "$file"
}

# Emit the rows of the markdown table under <heading>, one per line, cells joined by $US.
# The header row and the |---| separator are dropped. A cell's escaped pipe (\|) is restored
# after splitting, so a command containing a pipe survives.
table_rows() {
    local file=$1 heading=$2
    awk -v h="$heading" -v us="$US" '
        $0 == h            { in_sec = 1; next }
        in_sec && /^## /   { exit }
        !in_sec            { next }
        !/^\|/             { next }
        /^\|[- |:]*\|$/    { seen_sep = 1; next }
        !seen_sep          { next }
        {
            line = $0
            gsub(/\\\|/, "\001", line)          # protect escaped pipes
            sub(/^\|/, "", line); sub(/\|[ \t]*$/, "", line)
            n = split(line, cell, "|")
            out = ""
            for (i = 1; i <= n; i++) {
                gsub(/^[ \t]+|[ \t]+$/, "", cell[i])
                gsub(/\001/, "|", cell[i])
                out = out (i > 1 ? us : "") cell[i]
            }
            print out
        }
    ' "$file"
}

# Emit the header row of the table under <heading>, cells joined by $US.
table_header() {
    local file=$1 heading=$2
    awk -v h="$heading" -v us="$US" '
        $0 == h          { in_sec = 1; next }
        in_sec && /^## / { exit }
        !in_sec          { next }
        !/^\|/           { next }
        {
            line = $0
            sub(/^\|/, "", line); sub(/\|[ \t]*$/, "", line)
            n = split(line, cell, "|")
            out = ""
            for (i = 1; i <= n; i++) {
                gsub(/^[ \t]+|[ \t]+$/, "", cell[i])
                out = out (i > 1 ? us : "") cell[i]
            }
            print out
            exit
        }
    ' "$file"
}

# Print the 1-based index of a named column, or nothing when the table has no such column.
col_index() {
    local header=$1 name=$2
    awk -v us="$US" -v want="$name" 'BEGIN {
        n = split(ARGV[1], c, us)
        for (i = 1; i <= n; i++) if (tolower(c[i]) == tolower(want)) { print i; exit }
    }' "$header"
}

# Print the nth cell of a row.
cell() {
    local row=$1 idx=$2
    awk -v us="$US" -v i="$idx" 'BEGIN { split(ARGV[1], c, us); print c[i] }' "$row"
}

# A checkable reference: a backticked span, or something that reads as a path.
is_checkable() {
    local v=$1
    [[ $v == *'`'*'`'* ]] && return 0
    [[ $v =~ (^|[[:space:]])[A-Za-z0-9_./-]+/[A-Za-z0-9_.-]+ ]] && return 0
    return 1
}

# Evidence must name what produced it: a backticked command, or a path:line.
is_evidence() {
    local v=$1
    [[ $v == *'`'*'`'* ]] && return 0
    [[ $v =~ [A-Za-z0-9_./-]+:[0-9]+ ]] && return 0
    return 1
}

# The first backticked span of a cell, unquoted. Empty when there is none.
backticked() {
    local v=$1
    [[ $v =~ \`([^\`]+)\` ]] && printf '%s' "${BASH_REMATCH[1]}"
}

require_plan() {
    [ -n "${1:-}" ] || die "no plan file given"
    [ -r "$1" ]     || die "cannot read plan: $1"
}

# ---------------------------------------------------------------------------- criteria

cmd_criteria() {
    local plan=$1
    require_plan "$plan"

    local header rows
    header=$(table_header "$plan" '## Success criteria' || true)
    [ -n "$header" ] || { refuse "no '## Success criteria' table — nothing says what this work must achieve"; return; }

    local i_id i_crit i_kind i_how i_check i_expect
    i_id=$(col_index "$header" id)
    i_crit=$(col_index "$header" criterion)
    i_kind=$(col_index "$header" kind)
    i_how=$(col_index "$header" how)
    i_check=$(col_index "$header" check)
    i_expect=$(col_index "$header" expect)
    for pair in "id:$i_id" "criterion:$i_crit" "kind:$i_kind" "how:$i_how" "check:$i_check" "expect:$i_expect"; do
        [ -n "${pair#*:}" ] || die "'## Success criteria' has no '${pair%%:*}' column"
    done

    rows=$(table_rows "$plan" '## Success criteria' || true)
    [ -n "$rows" ] || { refuse "'## Success criteria' has no rows — planning may not start without them"; return; }

    local saw_e2e=0 count=0
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        local id crit kind how check expect
        id=$(cell "$row" "$i_id");       [ -n "$id" ] || continue
        crit=$(cell "$row" "$i_crit")
        kind=$(cell "$row" "$i_kind")
        how=$(cell "$row" "$i_how")
        check=$(cell "$row" "$i_check")
        expect=$(cell "$row" "$i_expect")
        count=$((count + 1))

        [ -n "$crit" ]   || refuse "$id has no criterion"
        [ -n "$check" ]  || refuse "$id has no check — nothing can decide it"
        [ -n "$expect" ] || refuse "$id has no expected outcome"
        [ "$kind" = e2e ] && saw_e2e=1

        case "$how" in
            command|artifact)
                is_checkable "$check" || \
                    refuse "$id is '$how' but its check names no command and no path: $check"
                ;;
            observed)
                # A judgement is legal. Closing on "it looked fine" is not.
                grep -qiE "fails? (when|if)|not met (when|if)|would make it fail" <<<"$check$expect" || \
                    refuse "$id is 'observed' and names no condition that would make it fail"
                grep -q 'no-command:' <<<"$check$expect" || \
                    refuse "$id is 'observed' and gives no 'no-command:' reason for why no detector exists"
                ;;
            '')
                refuse "$id has no 'how' — say whether a command, an artifact check or an observation decides it"
                ;;
            *)
                refuse "$id has how='$how'; the only values are command, artifact, observed"
                ;;
        esac

        grep -qE 'WHEN .*SHALL|WHEN .*THE SYSTEM' <<<"$crit" || \
            note "$id reads as a statement, not a rule. 'WHEN <trigger> THE SYSTEM SHALL <observable>' is what makes it testable"
    done <<<"$rows"

    if [ "$saw_e2e" -eq 0 ]; then
        local why
        why=$(frontmatter_get "$plan" no-runtime)
        if [ -n "$why" ]; then
            note "no end-to-end criterion; the plan declares no-runtime: $why"
        else
            refuse "no criterion has kind 'e2e'. A component proven only in isolation is how work gets built and never integrated. Add one, or declare 'no-runtime: <reason>' in frontmatter"
        fi
    fi
    [ "$count" -gt 0 ] || refuse "'## Success criteria' parsed to zero usable rows"
}

# ---------------------------------------------------------------------------- due-ness

# Print the criterion ids whose covering work items are ALL done, one per line.
#
# A multi-session plan is the tracker for work that spans sessions, so most of its criteria are not
# yet due. Refusing on those would make the close gate unusable on the first checkpoint, and a gate
# that is unusable gets switched off. A criterion becomes due when every work item naming it in
# `covers` has status DONE. A plan whose work-item table has no `covers` column has no way to say
# this, so every criterion is due — that is the safe direction.
due_criteria() {
    local plan=$1
    local wheader wrows i_covers i_status
    wheader=$(table_header "$plan" '## Work items' || true)
    [ -n "$wheader" ] || return 0
    i_covers=$(col_index "$wheader" covers)
    i_status=$(col_index "$wheader" status)
    { [ -n "$i_covers" ] && [ -n "$i_status" ]; } || return 0

    wrows=$(table_rows "$plan" '## Work items' || true)
    [ -n "$wrows" ] || return 0

    # For each criterion id seen in a covers cell: due only when no covering row is unfinished.
    {
        while IFS= read -r wrow; do
            [ -n "$wrow" ] || continue
            local covers status
            covers=$(cell "$wrow" "$i_covers")
            status=$(cell "$wrow" "$i_status")
            [ -n "$covers" ] || continue
            local ids
            ids=$(tr ',' '\n' <<<"$covers" | tr -d ' ')
            while IFS= read -r cid; do
                [ -n "$cid" ] || continue
                if [ "$status" = DONE ]; then printf '%s done\n' "$cid"; else printf '%s open\n' "$cid"; fi
            done <<<"$ids"
        done <<<"$wrows"
    } | awk '{ seen[$1]=1; if ($2 == "open") blocked[$1]=1 }
             END { for (c in seen) if (!(c in blocked)) print c }'
}

# ---------------------------------------------------------------------------- verdict

cmd_verdict() {
    local plan=$1 run=${2:-}
    require_plan "$plan"

    local header rows
    header=$(table_header "$plan" '## Success criteria' || true)
    [ -n "$header" ] || { refuse "no '## Success criteria' table — nothing to verify against"; return; }

    local i_id i_how i_check i_expect i_verdict i_evidence
    i_id=$(col_index "$header" id)
    i_how=$(col_index "$header" how)
    i_check=$(col_index "$header" check)
    i_expect=$(col_index "$header" expect)
    i_verdict=$(col_index "$header" verdict)
    i_evidence=$(col_index "$header" evidence)
    for pair in "id:$i_id" "verdict:$i_verdict" "evidence:$i_evidence"; do
        [ -n "${pair#*:}" ] || die "'## Success criteria' has no '${pair%%:*}' column"
    done

    rows=$(table_rows "$plan" '## Success criteria' || true)
    [ -n "$rows" ] || { refuse "'## Success criteria' has no rows"; return; }

    # Which criteria are due depends on whether every work item covering them is done.
    local due_list scoped=0
    due_list=$(due_criteria "$plan")
    grep -q covers <<<"$(table_header "$plan" '## Work items' || true)" && scoped=1

    while IFS= read -r row; do
        [ -n "$row" ] || continue
        local id how check expect verdict evidence
        id=$(cell "$row" "$i_id"); [ -n "$id" ] || continue
        how=$(cell "$row" "$i_how")
        check=$(cell "$row" "$i_check")
        expect=$(cell "$row" "$i_expect")
        verdict=$(cell "$row" "$i_verdict")
        evidence=$(cell "$row" "$i_evidence")

        if [ "$scoped" -eq 1 ] && ! grep -qx "$id" <<<"$due_list"; then
            note "$id is not due yet — a work item covering it is still open"
            continue
        fi

        if [ "$run" = --run ] && [ "$how" = command ]; then
            local cmdline want actual
            cmdline=$(backticked "$check")
            if [ -z "$cmdline" ]; then
                refuse "$id is 'command' and its check has no backticked command to run"
                continue
            fi
            want=0
            [[ $expect =~ exit[[:space:]]+([0-9]+) ]] && want=${BASH_REMATCH[1]}
            printf '  running  %s: %s\n' "$id" "$cmdline" >&2
            set +e
            bash -c "$cmdline" >/dev/null 2>&1
            actual=$?
            set -e
            if [ "$actual" -ne "$want" ]; then
                refuse "$id exited $actual, expected $want — the check disagrees with the plan"
                continue
            fi
            [ "$verdict" = MET ] || refuse "$id passed its check and the plan does not say MET"
            continue
        fi

        case "$verdict" in
            MET)
                [ -n "$evidence" ] || { refuse "$id claims MET with no evidence"; continue; }
                is_evidence "$evidence" || \
                    refuse "$id gives evidence that names no command and no path:line: $evidence"
                ;;
            'NOT MET')
                refuse "$id is NOT MET — the work cannot close"
                ;;
            '')
                refuse "$id has no verdict — nothing checked whether the work achieved it"
                ;;
            *)
                refuse "$id has verdict '$verdict'; the only values are MET and NOT MET"
                ;;
        esac
    done <<<"$rows"
}

# ---------------------------------------------------------------------------- dispatch

main() {
    if [ "${GATE:-on}" = off ]; then
        printf 'gate: GATE=off — every check skipped\n' >&2
        exit 0
    fi

    local sub=${1:-}
    case "$sub" in
        -h|--help|'') usage; exit 0 ;;
    esac
    shift

    case "$sub" in
        criteria) cmd_criteria "${1:-}" ;;
        verdict)  cmd_verdict "${1:-}" "${2:-}" ;;
        all)
            local plan=${1:-} phase=""
            shift || true
            while [ $# -gt 0 ]; do
                case "$1" in
                    --phase) phase=${2:-}; shift 2 ;;
                    *) die "unknown option: $1" ;;
                esac
            done
            case "$phase" in
                propose) cmd_criteria "$plan" ;;
                approve) cmd_criteria "$plan" ;;
                close)   cmd_criteria "$plan"; cmd_verdict "$plan" ;;
                *) die "--phase must be propose, approve or close" ;;
            esac
            ;;
        *) die "unknown subcommand: $sub" ;;
    esac

    if [ "$violations" -gt 0 ]; then
        printf 'gate: %d refusal(s). The session may not continue until each is resolved.\n' "$violations" >&2
        exit 1
    fi
    exit 0
}

main "$@"
