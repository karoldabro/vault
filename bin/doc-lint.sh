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

finding() {
    violations=$((violations + 1))
    [ "$quiet" = 1 ] && return 0
    printf '  %-6s %-8s %s\n' "$1" "$2" "$3"
}

# Quoted text is not a claim. A document that defines these rules has to name the phrases it bans,
# and a plan legitimately quotes an old string it is replacing. So the patterns are matched against
# a copy with fenced blocks and inline `code` spans blanked out, line numbering preserved. Quote the
# thing you are banning and the linter stays quiet; assert it in your own voice and it fires.
matchable_copy() {
    awk '
        /^[[:space:]]*```/ { fence = !fence; print ""; next }
        fence              { print ""; next }
        {
            line = $0
            gsub(/`[^`]*`/, "", line)      # inline code spans
            print line
        }
    ' "$1"
}

# Most rules are about wording, and a sentence-initial capital must not let one through. The three
# exceptions match on case itself: struck-through markup and the shouted markers WITHDRAWN /
# BLOCKER, whose lowercase forms are ordinary English words.
case_flag() {
    case "$1" in HIST3|HIST4|PROC5) echo "-e" ;; *) echo "-i" ;; esac
}

check_patterns() {
    local _target="$1" body_start="$2" want_group="$3"
    local code group regex message lineno
    while IFS=$'	' read -r code group regex message; do
        [ -z "${code:-}" ] && continue
        [ "$group" = "$want_group" ] || continue
        is_skipped "$code" && continue
        while IFS= read -r lineno; do
            [ -z "${lineno:-}" ] && continue
            [ "$lineno" -lt "$body_start" ] && continue
            header
            finding "$code" "L${lineno}" "$message"
        done < <(grep -n $(case_flag "$code") -E "$regex" "$MATCHABLE" 2>/dev/null | cut -d: -f1 || true)
    done <<< "$PATTERNS"
}

# Rule 3 — one rule, one place. A substantial line repeated more than twice has more than one home.
# Twice is tolerated: a heading restated in a summary table is normal and useful.
check_duplicates() {
    local _target="$1" count text
    while read -r count text; do
        [ -z "${count:-}" ] && continue
        header
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
# because a specification sentence legitimately carries more qualifiers than a message does.
check_sentences() {
    local _target="$1" lineno
    while IFS= read -r lineno; do
        [ -z "${lineno:-}" ] && continue
        header
        finding "LONG1" "L${lineno}" "sentence over 30 words — split it; one idea per sentence"
    done < <(
        awk '
            /^[[:space:]]*[|>`]/  { next }
            /^[[:space:]]*(#|---|```)/ { next }
            /^[[:space:]]*<!--/   { next }
            {
                n = split($0, parts, /[.!?]([[:space:]]|$)/)
                for (i = 1; i <= n; i++) {
                    w = split(parts[i], _t, /[[:space:]]+/)
                    if (w > 30) { print NR; break }
                }
            }
        ' "$_target"
    )
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
    doc_type="${doc_type%s}"
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
    matchable_copy "$file" > "$MATCHABLE"

    header_printed=0
    header() { print_header "$file" "$doc_type" "$doc_class" "$lines" "$cap"; }

    if [ "$doc_class" = "contract" ]; then
        if [ "$lines" -gt "$cap" ]; then
            header
            finding "SIZE1" "FILE" "${lines} lines, cap ${cap} for type '${doc_type}' — split out what answers a different question"
        fi
        check_patterns "$file" "$body_start" history
        check_patterns "$file" "$body_start" process
        check_patterns "$file" "$body_start" reference
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
