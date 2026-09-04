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
#         bin/gate.sh readers  <plan>          every declared identifier has a reader in code
#         bin/gate.sh config   <repo>          the repo declares how to run its own checks
#         bin/gate.sh budget   [file]          no check fires wrongly more than one time in ten
#         bin/gate.sh recurrence [file]        every defect repair has a test that failed before it
#         bin/gate.sh all      <plan> --phase <propose|approve|close>
#         bin/gate.sh --help
#
# A `how: command` criterion names a COMMITTED SCRIPT, never a command typed into the plan. The
# session that writes the work must not also author the thing that grades it, and a script in the
# repo is reviewable at approval, survives the session, and can be re-run by the operator on a clean
# checkout. `criteria` refuses a check cell that is not an existing executable file.
#
# --run executes each such script, compares its exit code to `expect`, and WRITES the verdict and
# the captured output back into the plan itself. The session does not author the verdict; this does.
# Without --run, `verdict` only checks the plan is internally honest: a MET row must carry evidence,
# and evidence must name a command or a path:line.
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

# The directory a check path resolves against: the git root above the plan, else the working
# directory. A check named relative to nothing is a check nobody else can run.
checks_root() {
    local plan=$1 root
    root=$(git -C "$(dirname "$plan")" rev-parse --show-toplevel 2>/dev/null) || root=""
    printf '%s' "${root:-$(cd "$(dirname "$plan")" && pwd)}"
}

# A committed check: an existing executable file, named as a repo-relative path.
check_script() {
    local root=$1 cell=$2 path
    path=$(backticked "$cell")
    [ -n "$path" ] || return 1
    case "$path" in *' '*) return 1 ;; esac        # a path, not a command line
    [ -f "${root}/${path}" ] && [ -x "${root}/${path}" ] || return 1
    printf '%s' "$path"
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

    local root; root=$(checks_root "$plan")
    local saw_delivery=0 count=0
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
        [ "$kind" = delivery ] && saw_delivery=1

        case "$how" in
            command)
                local script
                if ! script=$(check_script "$root" "$check"); then
                    refuse "$id is 'command' and its check is not a committed executable. Write the check as a script in the repo and name its path — a command typed into the plan is authored by the same session the check is meant to grade: $check"
                fi
                ;;
            artifact)
                is_checkable "$check" || \
                    refuse "$id is '$how' but its check names no path: $check"
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

    if [ "$saw_delivery" -eq 0 ]; then
        local why
        why=$(frontmatter_get "$plan" no-runtime)
        if [ -n "$why" ]; then
            note "no end-to-end criterion; the plan declares no-runtime: $why"
        else
            refuse "no criterion has kind 'delivery'. A delivery check runs the real system and finds THIS change in what the run produced. Without one, work passes its own tests and never arrives. Add one, or declare 'no-runtime: <reason>' in frontmatter"
        fi
    fi
    [ "$count" -gt 0 ] || refuse "'## Success criteria' parsed to zero usable rows"
}

# ---------------------------------------------------------------------------- budget

# Refuse a check that fires wrongly more than one time in ten.
#
# Google launches a Tricorder analyzer only below a 10% false-positive rate and disables one that
# climbs above it; their platform runs under 5%. The reason is not tidiness: a check developers stop
# trusting is not ignored selectively, it is switched off wholesale, and every other check goes with
# it. GATE=off is this framework's version of that, so a noisy check costs the whole gate.
cmd_budget() {
    local file=${1:-vault/check-budget.md}
    [ -r "$file" ] || { note "no check budget at $file — nothing recorded yet"; return; }

    local header rows i_check i_fires i_wrong
    header=$(table_header "$file" '## Check budget' || true)
    [ -n "$header" ] || die "$file has no '## Check budget' table"
    i_check=$(col_index "$header" check); i_fires=$(col_index "$header" fires); i_wrong=$(col_index "$header" wrong)
    for pair in "check:$i_check" "fires:$i_fires" "wrong:$i_wrong"; do
        [ -n "${pair#*:}" ] || die "'## Check budget' has no '${pair%%:*}' column"
    done

    rows=$(table_rows "$file" '## Check budget' || true)
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        local name fires wrong
        name=$(cell "$row" "$i_check"); [ -n "$name" ] || continue
        fires=$(cell "$row" "$i_fires"); wrong=$(cell "$row" "$i_wrong")
        case "$fires$wrong" in ''|*[!0-9]*) refuse "$name has a non-numeric fire count"; continue ;; esac
        [ "$fires" -gt 0 ] || continue
        if [ $(( wrong * 100 )) -gt $(( fires * 10 )) ]; then
            refuse "$name fired wrongly $wrong of $fires times, over the one-in-ten budget. Fix it or delete it — a check people stop trusting takes every other check with it"
        fi
    done <<<"$rows"
}

# ---------------------------------------------------------------------------- recurrence

# Refuse a defect repair that has no test which failed before it.
#
# A repair with no failing-before test is a claim that the defect is gone. The ledger's purpose is
# the only measurement that shows whether a repair worked: did this defect class come back?
cmd_recurrence() {
    local file=${1:-vault/defect-ledger.md}
    [ -r "$file" ] || { note "no defect ledger at $file — nothing recorded yet"; return; }

    local header rows i_id i_test i_again
    header=$(table_header "$file" '## Defect ledger' || true)
    [ -n "$header" ] || die "$file has no '## Defect ledger' table"
    i_id=$(col_index "$header" id); i_test=$(col_index "$header" test); i_again=$(col_index "$header" recurrences)
    for pair in "id:$i_id" "test:$i_test" "recurrences:$i_again"; do
        [ -n "${pair#*:}" ] || die "'## Defect ledger' has no '${pair%%:*}' column"
    done

    rows=$(table_rows "$file" '## Defect ledger' || true)
    local total=0 repeated=0
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        local id test again
        id=$(cell "$row" "$i_id"); [ -n "$id" ] || continue
        test=$(cell "$row" "$i_test"); again=$(cell "$row" "$i_again")
        total=$((total + 1))
        is_evidence "$test" || refuse "$id names no test that failed before its repair. Without one, the repair is a claim"
        case "$again" in ''|*[!0-9]*) refuse "$id has a non-numeric recurrence count" ;; *)
            [ "$again" -gt 0 ] && repeated=$((repeated + 1)) ;;
        esac
    done <<<"$rows"
    [ "$total" -gt 0 ] && printf '  recurrence  %d of %d defect classes came back\n' "$repeated" "$total" >&2
    return 0
}

# ---------------------------------------------------------------------------- config

# Refuse a repo that never declared how to run its own checks.
#
# Runs at ANALYZE, before anything is loaded, so a repo nobody onboarded fails at the start of a
# session rather than at its close. An OMITTED key is the refusal; `absent: <reason>` is legal. A
# missing duplication detector is a fact worth recording; a silently skipped line is how the next
# session comes to believe a question was settled.
DOD_KEYS="test_command lint_command delivery_command"

cmd_config() {
    local repo=${1:-$PWD}
    [ -d "$repo" ] || die "not a directory: $repo"
    local vm="${repo}/VAULT.md"
    if [ ! -r "$vm" ]; then
        refuse "$repo has no VAULT.md. Run vault-init.sh so this repo declares how to run its own checks"
        return
    fi
    local profile
    profile=$(sed -n 's/^dod_profile:[[:space:]]*//p' "$vm" | head -1 | tr -d '\r')
    [ -n "$profile" ] || refuse "VAULT.md declares no dod_profile. One of: code, ai-instructions"

    local key val
    for key in $DOD_KEYS; do
        val=$(sed -n "s/^${key}:[[:space:]]*//p" "$vm" | head -1 | tr -d '\r')
        if [ -z "$val" ]; then
            refuse "VAULT.md omits ${key}. Give the command, or write 'absent: <reason>' — an omitted key reads as settled and is not"
        elif [ "${val#absent:}" != "$val" ]; then
            [ -n "$(printf '%s' "${val#absent:}" | tr -d '[:space:]')" ] || \
                refuse "${key} is marked absent with no reason"
        fi
    done
}

# ---------------------------------------------------------------------------- readers

# Refuse a declared identifier that no code reads.
#
# A config key, flag or field that exists with no reader is worse than one that does not exist: the
# next session finds it, believes the question is settled, and has no way to discover otherwise. One
# such key sat in a channel config with zero readers while the operator asked repeatedly why the
# feature did nothing. No mainstream tool detects this — dead-code detectors find unused code paths,
# which is a different question — so it is built here.
cmd_readers() {
    local plan=$1
    require_plan "$plan"
    local root; root=$(checks_root "$plan")

    local header rows i_artifact
    header=$(table_header "$plan" '## Artifact lifecycles' || true)
    [ -n "$header" ] || { note "no '## Artifact lifecycles' table — nothing to check for readers"; return; }
    i_artifact=$(col_index "$header" artifact)
    [ -n "$i_artifact" ] || die "'## Artifact lifecycles' has no 'artifact' column"

    rows=$(table_rows "$plan" '## Artifact lifecycles' || true)
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        local cellv ident
        cellv=$(cell "$row" "$i_artifact")
        [ -n "$cellv" ] || continue
        [ "$cellv" = none ] && continue
        ident=$(backticked "$cellv")
        [ -n "$ident" ] || continue
        # A path is checked for existence; a bare identifier is checked for a reader.
        case "$ident" in
            */*|*.sh|*.md|*.json)
                [ -e "${root}/${ident}" ] || note "$ident is declared and does not exist yet"
                continue ;;
        esac
        # grep exits 1 when it finds nothing, and `set -o pipefail` would abort the whole run on
        # exactly the case this check exists to report. Guard it.
        local hits
        hits=$(grep -rIl --exclude-dir=.git --exclude='*.md' -e "$ident" "$root" 2>/dev/null || true)
        hits=$(printf '%s' "$hits" | grep -c . || true)
        if [ "$hits" -eq 0 ]; then
            refuse "\`$ident\` is declared and no code reads it. A binding nothing reads makes the next session believe the question is settled and gives it no way to find out otherwise"
        fi
    done <<<"$rows"
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

# Write the verdict and the evidence into the plan row itself, replacing whatever was there.
#
# This is the point of --run. A session that authors its own verdict has verified nothing; a
# measurement across 1,879 trajectories found 75.8% of failures in self-assessing coding agents
# reported as success. Here the exit code decides and this function records it, so the two cells
# are the only part of a plan the session never writes.
record_verdict() {
    local plan=$1 id=$2 actual=$3 want=$4 script=$5 captured=$6
    local verdict evidence
    if [ "$actual" -eq "$want" ]; then verdict="MET"; else verdict="NOT MET"; fi
    evidence="\`${script}\` exited ${actual}"
    if [ -n "$captured" ]; then
        # A raw pipe in captured output would split the markdown row it lands in.
        captured=${captured//|/\\|}
        captured=${captured//$'\n'/ }
        evidence="${evidence} · ${captured:0:120}"
    fi
    python3 - "$plan" "$id" "$verdict" "$evidence" <<'PYEOF'
import sys, pathlib
plan, cid, verdict, evidence = sys.argv[1:5]
p = pathlib.Path(plan); out = []
for line in p.read_text().split('\n'):
    if line.startswith(f'| {cid} |') and line.rstrip().endswith('|'):
        cells = line.split('|')
        if len(cells) >= 4:
            cells[-3] = f' {verdict} '
            cells[-2] = f' {evidence} '
            line = '|'.join(cells)
    out.append(line)
p.write_text('\n'.join(out))
PYEOF
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

    local root; root=$(checks_root "$plan")
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
            local script want actual captured
            if ! script=$(check_script "$root" "$check"); then
                refuse "$id is 'command' and its check is not a committed executable: $check"
                continue
            fi
            want=0
            [[ $expect =~ exit[[:space:]]+([0-9]+) ]] && want=${BASH_REMATCH[1]}
            printf '  running  %s: %s\n' "$id" "$script" >&2
            set +e
            captured=$(cd "$root" && "./${script}" 2>&1 | tail -1)
            actual=${PIPESTATUS[0]}
            set -e
            # The gate writes the verdict. The session does not get to.
            record_verdict "$plan" "$id" "$actual" "$want" "$script" "$captured"
            if [ "$actual" -ne "$want" ]; then
                refuse "$id exited $actual, expected $want — recorded NOT MET"
                continue
            fi
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
        readers)  cmd_readers "${1:-}" ;;
        config)   cmd_config "${1:-}" ;;
        budget)   cmd_budget "${1:-}" ;;
        recurrence) cmd_recurrence "${1:-}" ;;
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
                close)   cmd_criteria "$plan"; cmd_readers "$plan"; cmd_verdict "$plan" ;;
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
