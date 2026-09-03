#!/usr/bin/env bash
# doc-lint.sh — mechanical check that a vault document obeys commands/_shared/document-standard.md.
#
# Prose rules alone do not shorten documents: the framework has shipped a communication contract
# since ADR-018 and plans still reached 1,500 lines. Numeric, per-artifact limits are the lever that
# works where "be concise" does not. This turns the standard's checkable half into an exit code.
#
# It checks CONTRACT documents (plan, decision, indication, feature, architecture, process, guide,
# requirements) — documents someone acts on, which must carry current truth only. RECORD documents
# (session, research, trail, changelog) are exempt from the history and process checks: chronology
# is their payload. Class comes from frontmatter `type:`, falling back to the parent directory.
#
# Precision-first, deliberately. A linter that fires on a legitimate document gets switched off, so
# every pattern targets a phrase that is wrong in a contract document under any reading. It does not
# try to detect vagueness, verbosity or weak headings — those stay human judgement.
#
# Usage:  bin/doc-lint.sh [--quiet] [--force] [--cap N] [--class contract|record] <file>...
#         bin/doc-lint.sh --changed          only the markdown this working tree has touched
#         bin/doc-lint.sh --list-caps
#         bin/doc-lint.sh --compare <before.md> <after.md>
#
# --compare answers the question that makes shortening safe: did the rewrite drop a constraint?
# It lists every prohibition, requirement, number and code identifier in the long version that no
# longer appears in the short one. Shortening a document is a delete pass, never a rewrite from
# memory, and this is how you prove it was.
# Env:    DOC_LINT=off        skip every check and exit 0 (escape hatch for a deliberate exception)
#         DOC_LINT_SKIP=A,B   suppress named checks; a repo-root `.doc-lint` file does the same,
#                             one code per line with the reason beside it, so the exemption is
#                             reviewable instead of invisible
#
# Exit: 0 clean (or skipped)
#       1 violations found
#       2 usage error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The sentence counter is shared with bin/output-lint.sh. Guard the source: an unreadable library
# must cost one skipped check, never an aborted run under `set -e`.
# An `a && b` list would itself abort under `set -e` when the file is absent, so use `if`.
if [ -r "${SCRIPT_DIR}/../lib/sentence-count.sh" ]; then
    # shellcheck source=../lib/sentence-count.sh
    . "${SCRIPT_DIR}/../lib/sentence-count.sh"
fi
if [ -r "${SCRIPT_DIR}/../lib/prose-match.sh" ]; then
    # shellcheck source=../lib/prose-match.sh
    . "${SCRIPT_DIR}/../lib/prose-match.sh"
fi

quiet=0
cap_override=""
class_override=""
compare=0
show_all=0
force=0
changed=0
skip_codes=""
files=()
violations=0
header_printed=0

# Line caps per document type. A cap is a smell test, not a hard truth: crossing it means the
# document carries something that answers a different question, which is the standard's first rule.
cap_for_type() {
    case "$1" in
        plan)               echo 300 ;;
        decision|adr)       echo 120 ;;
        indication)         echo 80  ;;
        feature)            echo 200 ;;
        architecture)       echo 200 ;;
        process)            echo 250 ;;
        guide)              echo 600 ;;
        requirement)        echo 400 ;;
        integration-guide)  echo 400 ;;
        instruction)        echo 120 ;;
        *)                  echo 400 ;;
    esac
}

# Folder names are plural and type names are not, so one has to be folded onto the other. A trailing
# `s` strip cannot tell the two apart: it turned `process` into `proces` and `corpus` into `corpu`,
# which matched no cap and no known type, so the process cap of 250 never once applied. The table is
# exact, and anything not listed keeps its own name — including in the "unknown type" note, which is
# useless if it reports a name the author never wrote.
singularize_type() {
    case "$1" in
        plans)         echo plan ;;
        decisions)     echo decision ;;
        adrs)          echo adr ;;
        indications)   echo indication ;;
        features)      echo feature ;;
        processes)     echo process ;;
        requirements)  echo requirement ;;
        runbooks)      echo runbook ;;
        sessions)      echo session ;;
        trails)        echo trail ;;
        changelogs)    echo changelog ;;
        logs)          echo log ;;
        guides)        echo guide ;;
        *)             echo "$1" ;;
    esac
}

# Folders whose contents are documents by convention, even without frontmatter.
is_document_folder() {
    case "$(dirname "$1")" in
        */plans|*/plans/*|*/features|*/features/*|*/decisions|*/decisions/*|*/indications|*/indications/*|\
        */sessions|*/sessions/*|*/architecture|*/architecture/*|*/processes|*/processes/*|\
        */requirements|*/requirements/*|*/runbooks|*/runbooks/*) return 0 ;;
    esac
    return 1
}

# Instruction files — personas, templates for instructions, command prose. They tell an agent how to
# work; they are not documents about a project, and several of them legitimately describe the very
# machinery a rule bans naming. Skipped entirely unless --force.
is_instruction_type() {
    case "$1" in persona|command|skill|output-style) return 0 ;; esac
    return 1
}

is_known_type() {
    case "$1" in
        plan|decision|adr|indication|feature|architecture|process|guide|requirement|\
        integration-guide|instruction|session|research|trail|changelog|log|planning-session) return 0 ;;
    esac
    return 1
}

is_record_type() {
    case "$1" in
        session|research|trail|changelog|log|planning-session) return 0 ;;
        *) return 1 ;;
    esac
}

# Word cap for index documents. The line cap cannot see these: an `_index.md` row carrying a
# 200-word paragraph is one line, so a 16,800-word index passed at "235 lines, cap 400" while
# being far too large to load. An index earns its keep only while reading it is cheaper than
# reading the documents it lists, and ~4,000 words (~5k tokens) is where that stops.
INDEX_WORD_CAP=4000

# Longest a single `_index.md` table row may be. The column is called "one-line rule"; a row that
# needs more than this is a document, and belongs in the file the row points at.
INDEX_ROW_CHAR_CAP=400

is_index_file() {
    case "$(basename "$1")" in _index.md) return 0 ;; esac
    return 1
}

# INDEX1/INDEX2/INDEX3 — checks that apply only to an `_index.md`.
#   INDEX1  the whole file is too large to be worth loading instead of the bodies
#   INDEX2  an individual row has outgrown its "one-line rule" column
#   INDEX3  a row's scope cell is not one of the values the project declared in VAULT.md
# INDEX3 is skipped when the project declares no vocabulary — the check exists to catch drift
# against a declared list, not to invent one.
check_index() {
    local file="$1" words rows long_rows scope declared bad_scopes=""
    words="$(wc -w < "$file" | tr -d ' ')"
    if [ "$words" -gt "$INDEX_WORD_CAP" ]; then
        finding "INDEX1" "FILE" "${words} words, cap ${INDEX_WORD_CAP} — an index this large costs more to load than the documents it lists"
    fi

    long_rows="$(awk -v cap="$INDEX_ROW_CHAR_CAP" '/^\|/ && length($0) > cap {n++} END {print n+0}' "$file")"
    if [ "$long_rows" -gt 0 ]; then
        finding "INDEX2" "FILE" "${long_rows} table row(s) over ${INDEX_ROW_CHAR_CAP} chars — the column is a one-line rule, move the prose into the linked document"
    fi

    declared="$(index_scope_vocabulary "$file")"
    [ -n "$declared" ] || return 0

    # Which column holds the scope is per-index, not fixed: of the seven indexes in use, one puts
    # it first, one puts it third, and five have no scope column at all. A hardcoded field number
    # reads the slug column and reports every row undeclared, so find it from the header instead.
    local col; col="$(index_scope_column "$file")"
    [ -n "$col" ] || return 0

    while IFS= read -r scope; do
        [ -n "$scope" ] || continue
        case "
$declared
" in *"
$scope
"*) ;; *) bad_scopes="${bad_scopes}${scope} " ;; esac
    done <<EOF
$(awk -F'|' -v c="$col" '
    /^\|/ {
        v = $(c + 1)                                   # leading "|" makes field 1 empty
        gsub(/^[ \t]+|[ \t]+$/, "", v)
        if (v == "" || v ~ /^:?-+:?$/) next            # separator row
        if (tolower(v) == "scope") next                # header row
        print v
    }' "$file" | sort -u)
EOF
    if [ -n "$bad_scopes" ]; then
        finding "INDEX3" "FILE" "undeclared scope value(s): ${bad_scopes}— add them to VAULT.md \`indication_scopes\` or fix the rows"
    fi
}

# Print the 1-based position of the `scope` column in an index's header row, or nothing when the
# index has no scope column. Empty output disables INDEX3 for that file: an index without the
# column is not broken, it simply is not scope-routed yet.
index_scope_column() {
    awk -F'|' '
        /^\|/ {
            for (i = 2; i <= NF; i++) {
                v = $i
                gsub(/^[ \t]+|[ \t]+$/, "", v)
                if (tolower(v) == "scope") { print i - 1; exit }
            }
            exit                                       # header is the first table row; stop there
        }' "$1"
}

# Read the project's declared scope vocabulary from the nearest VAULT.md above the index file.
# Format: `indication_scopes: [a, b, c]`. Absent → empty, and INDEX3 does not run.
#
# The walk stops at a repository boundary, exactly as load_skip_file does. Without that stop a
# project with no VAULT.md of its own keeps climbing and lints against a NEIGHBOURING project's
# vocabulary — every scope reported undeclared, or worse, a wrong one quietly accepted.
index_scope_vocabulary() {
    local dir; dir="$(cd "$(dirname "$1")" 2>/dev/null && pwd)" || return 0
    while [ -n "$dir" ] && [ "$dir" != "/" ]; do
        if [ -r "$dir/VAULT.md" ]; then
            sed -n 's/^indication_scopes:[[:space:]]*\[\(.*\)\][[:space:]]*$/\1/p' "$dir/VAULT.md" \
                | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$'
            return 0
        fi
        [ -d "${dir}/.git" ] && return 0
        dir="$(dirname "$dir")"
    done
}

# PLAN1/PLAN2 — checks that apply only to a plan document.
#   PLAN1  a row of `## Artifact lifecycles` has an empty cell — a lifecycle nobody filled in
#   PLAN2  the plan's work items create files and the plan carries no `## Artifact lifecycles` table
#
# PLAN2 keys off a work item whose action cell reads `create`, so it fires on plans written against
# the current template and stays silent on the ones already in `vault/plans/`, whose work-item
# tables predate the section. A plan that creates nothing anyone else consumes writes one row whose
# first cell is `none`, plus the reason: the check exists to make the answer explicit, not to force
# a table onto a plan that has no artifacts. Templates are exempt — their placeholder row is empty
# by design, and linting it would fire on the very file that teaches the format.
check_plan() {
    local file="$1" blanks vague items
    case "$file" in */templates/*|templates/*) return 0 ;; esac

    if grep -qE '^##[[:space:]]+[Aa]rtifact lifecycles[[:space:]]*$' "$file"; then
        blanks="$(awk '
            /^##[[:space:]]+[Aa]rtifact lifecycles[[:space:]]*$/ { inside = 1; body = 0; next }
            inside && /^##[[:space:]]/                           { inside = 0 }
            !inside                                              { next }
            !/^[[:space:]]*\|/                                   { next }
            /^[[:space:]]*\|[[:space:]]*:?-{2,}/                 { body = 1; next }
            !body                                                { next }
            {
                row = $0
                sub(/^[[:space:]]*\|/, "", row)
                sub(/\|[[:space:]]*$/, "", row)
                m = split(row, cell, "|")
                blank = 0
                for (i = 1; i <= m; i++) {
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell[i])
                    if (cell[i] == "") blank++
                }
                if (tolower(cell[1]) == "none") {
                    reason = 0
                    for (i = 2; i <= m; i++) if (cell[i] != "") reason++
                    if (reason == 0) bad++
                    next
                }
                if (blank > 0) { bad++; next }
                # A row whose four cells are all prose named nobody. "the drafting session" in every
                # cell passes an emptiness test and is the same defect the section exists to catch,
                # so a row must point at something a reader can open: a path or a backticked name.
                # This is also what stops a claim word standing in for an answer — `wired` alone in
                # a cell carries no identifier.
                if (index($0, "`") == 0) vague++
            }
            END { print bad + 0 ": " vague + 0 }
        ' "$file")"
        vague="${blanks#*: }"
        blanks="${blanks%%:*}"
        if [ "$blanks" -gt 0 ]; then
            finding "PLAN1" "FILE" "${blanks} artifact lifecycle row(s) with an empty cell — name what requires it, who writes it, who reads it, and what happens when it is missing or wrong"
        fi
        if [ "$vague" -gt 0 ]; then
            finding "PLAN1" "FILE" "${vague} artifact lifecycle row(s) name nothing a reader can open — give each row at least one path or backticked identifier, not four cells of prose"
        fi
        return 0
    fi

    # A plan that has already been built is history: rewriting its lifecycle table changes nothing
    # that ships, and firing on it turns every historical plan into noise. PLAN2 catches a plan while
    # it can still be fixed — `proposed` or `approved`. PLAN1 has no such gate: a table with a blank
    # cell is wrong in any state, and only a plan carrying the section can trip it.
    case "$(sed -n 's/^status:[[:space:]]*\([a-z]*\).*/\1/p' "$file" | head -1)" in
        proposed|approved) ;;
        *) return 0 ;;
    esac

    # Any work item can create a handoff, not only one whose action is `create`: editing a prompt,
    # a critic envelope or a choice surface hands something to a receiver just as often. So the
    # trigger is a work-items table with at least one row. A plan that genuinely hands nothing to
    # anyone answers with one `none` row, which is a line of typing and a decision on the record.
    items="$(awk '
        /^##[[:space:]]+[Ww]ork items[[:space:]]*$/ { inside = 1; body = 0; next }
        inside && /^##[[:space:]]/                  { inside = 0 }
        !inside                                     { next }
        !/^[[:space:]]*\|/                          { next }
        /^[[:space:]]*\|[[:space:]]*:?-{2,}/        { body = 1; next }
        !body                                       { next }
        {
            row = $0
            gsub(/[|[:space:]]/, "", row)
            if (row != "") rows++
        }
        END { print rows + 0 }
    ' "$file")"
    if [ "$items" -gt 0 ]; then
        finding "PLAN2" "FILE" "${items} work item(s) and no \`## Artifact lifecycles\` table — for everything this creates, say who reads it and what happens when it is missing, or write one \`none\` row with the reason"
    fi
    return 0
}

usage() {
    sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit "${1:-2}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --quiet)      quiet=1; shift ;;
        --compare)    compare=1; shift ;;
        --all)        show_all=1; shift ;;
        --skip)       skip_codes="${skip_codes},$2"; shift 2 ;;
        --force)      force=1; shift ;;
        --changed)    changed=1; shift ;;
        --cap)        cap_override="$2"; shift 2 ;;
        --class)      class_override="$2"; shift 2 ;;
        --list-caps)  for t in plan decision indication feature architecture process requirement; do
                          printf '%-20s %s\n' "$t" "$(cap_for_type "$t")"
                      done
                      exit 0 ;;
        -h|--help)    usage 0 ;;
        -*)           echo "doc-lint: unknown option $1" >&2; usage 2 ;;
        *)            files+=("$1"); shift ;;
    esac
done

[ "${DOC_LINT:-}" = "off" ] && exit 0

# --changed: only what this session actually touched. A first sweep over an existing vault reports
# hundreds of findings on documents nobody is going to rewrite, and that is how a linter earns a
# permanent DOC_LINT=off. /v-reconcile is the deliberate sweep; this is the everyday default.
if [ "$changed" = 1 ]; then
    while IFS= read -r m; do
        case "$m" in *.md|*.markdown) [ -f "$m" ] && files+=("$m") ;; esac
    done < <(git diff --name-only HEAD 2>/dev/null; git diff --cached --name-only 2>/dev/null;
             git ls-files --others --exclude-standard 2>/dev/null)
    [ ${#files[@]} -eq 0 ] && exit 0
fi

[ ${#files[@]} -eq 0 ] && usage 2

# A repo whose subject matter is the thing a rule bans needs a documented exemption, not a switched-
# off linter. `.doc-lint` lists one code per line with the reason beside it. It is looked up from the
# linted file upwards, not from the working directory, so the same file lints the same way whatever
# directory you happen to be standing in.
load_skip_file() {
    local dir; dir="$(cd "$(dirname "$1")" 2>/dev/null && pwd)" || return 0
    while [ -n "$dir" ] && [ "$dir" != "/" ]; do
        if [ -f "${dir}/.doc-lint" ]; then
            while read -r code _rest; do
                case "$code" in ''|'#'*) continue ;; esac
                skip_codes="${skip_codes},${code}"
            done < "${dir}/.doc-lint"
            return 0
        fi
        [ -d "${dir}/.git" ] && return 0
        dir="$(dirname "$dir")"
    done
}
skip_codes="${skip_codes},${DOC_LINT_SKIP:-}"
base_skip_codes="$skip_codes"

is_skipped() {
    case ",${skip_codes}," in *",$1,"*) return 0 ;; esac
    return 1
}

# --- patterns -----------------------------------------------------------------
# The pattern table is data, in lib/doc-lint-patterns.tsv, so a rule change is a data edit.

PATTERN_FILE="${DOC_LINT_PATTERNS:-${SCRIPT_DIR}/../lib/doc-lint-patterns.tsv}"
if [ ! -f "$PATTERN_FILE" ]; then
    echo "doc-lint: pattern table not found: $PATTERN_FILE" >&2
    exit 2
fi
PATTERNS="$(grep -v '^#' "$PATTERN_FILE" | grep -v '^[[:space:]]*$')"

# --- reporting ----------------------------------------------------------------

print_header() {
    [ "$header_printed" = 1 ] && return 0
    header_printed=1
    [ "$quiet" = 1 ] && return 0
    printf '%s  [%s/%s, %s lines, cap %s%s]\n' "$1" "$2" "$3" "$4" "$5" "${type_note:-}"
}

# Every finding passes through here, so the exemption is checked here and nowhere else. A guard at
# the call site is one the next check added will forget: the size, duplicate and sentence checks all
# shipped without one, and `DOC_LINT_SKIP=SIZE1` did nothing. Printing the header from here too keeps
# a fully-exempted file silent instead of leaving a header line with no findings under it.
finding() {
    is_skipped "$1" && return 0
    violations=$((violations + 1))
    header
    [ "$quiet" = 1 ] && return 0
    printf '  %-6s %-8s %s\n' "$1" "$2" "$3"
}

# `matchable_copy` (fenced blocks and inline code blanked) and `pattern_case_flag` (the shouted
# markers matched on case) live in lib/prose-match.sh, shared with bin/output-lint.sh so the same
# sentence is not a finding in one linter and clean in the other.
#
# Without that library the phrase checks cannot run correctly — unblanked, they would fire on every
# document that quotes a phrase it bans. Skipping them beats running them wrong, and this script
# runs from a live PostToolUse hook, so it must not abort either.
case_flag() { pattern_case_flag "$1"; }

check_patterns() {
    local _target="$1" body_start="$2" want_group="$3"
    local code group regex message lineno
    command -v matchable_copy   >/dev/null 2>&1 || return 0
    command -v pattern_case_flag >/dev/null 2>&1 || return 0
    while IFS=$'	' read -r code group regex message; do
        [ -z "${code:-}" ] && continue
        [ "$group" = "$want_group" ] || continue
        is_skipped "$code" && continue
        while IFS= read -r lineno; do
            [ -z "${lineno:-}" ] && continue
            [ "$lineno" -lt "$body_start" ] && continue
            finding "$code" "L${lineno}" "$message"
        # Unquoted on purpose: case_flag prints nothing for a case-sensitive code, and an empty
        # quoted argument would become grep's pattern.
        # shellcheck disable=SC2046
        done < <(grep -n $(case_flag "$code") -E "$regex" "$MATCHABLE" 2>/dev/null | cut -d: -f1 || true)
    done <<< "$PATTERNS"
}

# Rule 3 — one rule, one place. A substantial line repeated more than twice has more than one home.
# Twice is tolerated: a heading restated in a summary table is normal and useful.
check_duplicates() {
    local _target="$1" count text
    while read -r count text; do
        [ -z "${count:-}" ] && continue
        finding "DUP1" "x${count}" "repeated line — define it once and reference it: \"$(printf '%s' "$text" | cut -c1-56)…\""
    done < <(
        sed -e 's/^[[:space:]#>*|+-]*//' -e 's/[[:space:]]*$//' -e 's/[*_`]//g' "$_target" \
        | tr '[:upper:]' '[:lower:]' \
        | awk 'length($0) >= 45' \
        | sort | uniq -c \
        | awk '$1 > 2 { c=$1; $1=""; sub(/^ /,""); print c, $0 }'
    )
}

# Sentence ceiling. communication.md caps prose the user reads at 25 words; a document gets 30,
# because a specification sentence legitimately carries more qualifiers than a message does. The
# counter itself lives in lib/sentence-count.sh so bin/output-lint.sh uses the same one at 25.
check_sentences() {
    local _target="$1" lineno
    # No counter available: skip the check and let every other check run. This script is wired into
    # a live PostToolUse hook, so aborting here would return shell errors to the model as findings.
    command -v count_long_sentences >/dev/null 2>&1 || return 0
    while IFS= read -r lineno; do
        [ -z "${lineno:-}" ] && continue
        finding "LONG1" "L${lineno}" "sentence over 30 words — split it; one idea per sentence"
    done < <(count_long_sentences "$_target" 30 1)
}

# --- comparison ---------------------------------------------------------------
# A load-bearing line is one that constrains someone: a prohibition, a requirement, a threshold, or
# a named identifier. Those are the lines a rewrite must carry over. Prose, rationale and narration
# are exactly what the edit pass is supposed to remove, so they are not compared.

load_bearing_terms() {
    # Only things that name something in the system: a symbol, a path, a config key, a constant.
    # Raw numbers are deliberately not compared — line numbers, versions and commit hashes swamp
    # the signal, and a threshold that matters is almost always written next to its key.
    grep -oE '`[^`]+`' "$1" 2>/dev/null | tr -d '`' \
      | grep -aE '(_|::|\(\)|->|\.[a-z]{2,4}$|/)' \
      | grep -avE '^(https?|and|the|or)' \
      | sed 's/[[:punct:]]*$//' \
      | awk 'length($0) >= 4 && length($0) <= 60' \
      | sort -u
}

prohibitions() {
    grep -inE '\b(never|must not|do not|don.t|cannot|must|always|required)\b' "$1" 2>/dev/null \
      | sed -e 's/^[0-9]*://' -e 's/^[[:space:]#>*|+-]*//' \
      | tr '[:upper:]' '[:lower:]' | sort -u
}

run_compare() {
    local before="$1" after="$2" lost=0
    for f in "$before" "$after"; do
        [ -f "$f" ] || { echo "doc-lint: no such file: $f" >&2; exit 1; }
    done

    printf '%s (%s lines)  ->  %s (%s lines)\n\n' \
        "$before" "$(wc -l < "$before" | tr -d ' ')" \
        "$after"  "$(wc -l < "$after"  | tr -d ' ')"

    local dropped
    dropped="$(comm -23 <(load_bearing_terms "$before") <(load_bearing_terms "$after") || true)"
    if [ -n "$dropped" ]; then
        lost=$(printf '%s\n' "$dropped" | wc -l | tr -d ' ')
        echo "Named things present before, absent after (${lost}):"
        if [ "$show_all" = 1 ]; then printf '%s\n' "$dropped" | sed 's/^/  /'
        else
            printf '%s\n' "$dropped" | head -30 | sed 's/^/  /'
            [ "$lost" -gt 30 ] && printf '  … and %s more (rerun with --all)\n' "$((lost - 30))"
        fi
        echo
    fi

    # Prohibitions are compared by their key words, not verbatim: the rewrite is allowed to rephrase
    # "never do X" as "X must not happen", but it is not allowed to lose X.
    local missing=""
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local key
        key="$(printf '%s' "$line" | tr -cs '[:alnum:]' ' ' \
              | tr ' ' '\n' | awk 'length($0) >= 6' | sort -u | head -4 | paste -sd' ' -)"
        [ -z "$key" ] && continue
        local hit=1
        for w in $key; do
            grep -qi -- "$w" "$after" || { hit=0; break; }
        done
        [ "$hit" = 0 ] && missing="${missing}  ${line}"$'\n'
    done < <(prohibitions "$before")

    if [ -n "$missing" ]; then
        local nrules
        nrules=$(printf '%s' "$missing" | grep -c . || true)
        echo "Rules present before, with no trace after (${nrules}):"
        printf '%s' "$missing" | cut -c1-110 | head -25
        [ "$nrules" -gt 25 ] && printf '  … and %s more\n' "$((nrules - 25))"
        echo
        lost=$((lost + nrules))
    fi

    if [ "$lost" -eq 0 ]; then
        echo "Nothing load-bearing was dropped."
        return 0
    fi
    printf 'doc-lint: %s item(s) present in the long version and missing from the short one.\n' "$lost"
    printf 'Each is either a constraint to restore, or a deliberate cut you should be able to name.\n'
    return 1
}

if [ "$compare" = 1 ]; then
    [ ${#files[@]} -eq 2 ] || { echo "doc-lint: --compare needs exactly two files" >&2; exit 2; }
    run_compare "${files[0]}" "${files[1]}"
    exit $?
fi

# --- main ---------------------------------------------------------------------

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "doc-lint: no such file: $file" >&2
        violations=$((violations + 1))
        continue
    fi

    skip_codes="$base_skip_codes"
    load_skip_file "$file"

    doc_type="$(awk 'NR==1 && $0=="---"{fm=1;next} fm && /^---/{exit} fm && /^type:[[:space:]]*/{print $2; exit}' "$file" || true)"
    has_type=1
    [ -z "$doc_type" ] && { has_type=0; doc_type="$(basename "$(dirname "$file")")"; }
    doc_type="$(singularize_type "$doc_type")"
    case "$file" in *.trail.md) doc_type="trail" ;; esac

    # Scope. The standard governs vault DOCUMENTS, not command instructions, READMEs or generated
    # output. A file that declares no `type:` and sits in no document folder is not a document, and
    # linting it produces noise that gets the whole tool switched off. --force overrides.
    if [ "$force" = 0 ] && [ "$has_type" = 0 ] && ! is_document_folder "$file"; then
        continue
    fi
    if [ "$force" = 0 ] && is_instruction_type "$doc_type"; then
        continue
    fi

    doc_class="contract"
    is_record_type "$doc_type" && doc_class="record"
    [ -n "$class_override" ] && doc_class="$class_override"

    body_start=1
    if head -1 "$file" | grep -q '^---$'; then
        body_start="$(awk 'NR>1 && /^---$/{print NR+1; exit}' "$file")"
        [ -z "$body_start" ] && body_start=1
    fi

    lines="$(wc -l < "$file" | tr -d ' ')"
    cap="${cap_override:-$(cap_for_type "$doc_type")}"

    # An unrecognised type takes the loosest cap, which silently exempts exactly the documents most
    # likely to need one — so the header says so. It rides along with a real finding rather than
    # printing on its own: a notice on an otherwise-clean file is noise, and noise gets a linter
    # switched off.
    type_note=""
    if [ -z "$cap_override" ] && ! is_known_type "$doc_type"; then
        type_note=" — unknown type, set \`type:\` in frontmatter"
    fi

    MATCHABLE="$(mktemp)"
    trap 'rm -f "$MATCHABLE"' EXIT
    if command -v matchable_copy >/dev/null 2>&1; then
        matchable_copy "$file" > "$MATCHABLE"
    else
        # No blanking available. check_patterns skips itself in this state; the sentence check
        # still runs, on the raw file, because its own awk rules already skip fences.
        cat "$file" > "$MATCHABLE"
    fi

    header_printed=0
    header() { print_header "$file" "$doc_type" "$doc_class" "$lines" "$cap"; }

    if [ "$doc_class" = "contract" ]; then
        if [ "$lines" -gt "$cap" ]; then
            finding "SIZE1" "FILE" "${lines} lines, cap ${cap} for type '${doc_type}' — split out what answers a different question"
        fi
        check_patterns "$file" "$body_start" history
        check_patterns "$file" "$body_start" process
        check_patterns "$file" "$body_start" reference
    fi

    is_index_file "$file" && check_index "$file"
    if [ "$doc_type" = "plan" ] && [ "$doc_class" = "contract" ]; then
        check_plan "$file"
    fi

    check_duplicates "$file"
    check_sentences "$MATCHABLE"
    rm -f "$MATCHABLE"
done

if [ "$violations" -gt 0 ]; then
    [ "$quiet" = 0 ] && printf '\ndoc-lint: %s violation(s). Fix them, or set DOC_LINT=off for a deliberate exception.\n' "$violations"
    exit 1
fi
exit 0
