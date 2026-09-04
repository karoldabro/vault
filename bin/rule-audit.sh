#!/usr/bin/env bash
# rule-audit.sh — measure how often each framework rule is actually followed.
#
# The rule list lives in vault/research/rule-inventory.md, not here. This script parses that table
# and scores every row against one of four corpora: commit subjects, shell commands the model
# really ran, replies it really wrote, and committed versions of documents.
#
# A rule is scored from a real invocation, never from a text match. Raw grep over transcripts
# overcounts by roughly 18 to 1, because the framework's own rule text is read far more often than
# the command it forbids is run. Transcript corpora therefore walk `message.content`, keep only
# `tool_use` blocks named `Bash`, and split each command into simple commands with heredoc bodies
# and quoted strings removed. A rule quoted in prose, in a grep pattern, or inside a document being
# written is not an invocation and is not counted.
#
# A rule that cannot be scored prints UNSCORABLE and its reason. It never prints an estimate, and
# it never prints a rate that could be mistaken for a clean run. A denominator below --floor is
# UNSCORABLE too: a rate over four observations is noise with a decimal point.
#
# Usage:  bin/rule-audit.sh                      score every rule
#         bin/rule-audit.sh --rule R-02          score one rule
#         bin/rule-audit.sh --by-month           add a per-month breakdown under each rate
#         bin/rule-audit.sh --list               print the parsed inventory and exit
#         bin/rule-audit.sh --dump <corpus>      print a corpus as `month<TAB>unit`
#         bin/rule-audit.sh --refresh            rebuild the corpus cache first
#         bin/rule-audit.sh --help
#
# The cache makes a re-run reproducible: transcripts grow while the audit is being read, so two
# runs over the live corpus would otherwise disagree. --refresh rebuilds it; the header line prints
# when it was built and how large each corpus is.
#
# Env:  RULE_AUDIT_CACHE        cache directory (default ${TMPDIR:-/tmp}/rule-audit-cache)
#       RULE_AUDIT_TRANSCRIPTS  transcript root  (default $HOME/.claude/projects)
#       RULE_AUDIT_REPO         repo to read git history from (default this script's repo)
#
# Exit: 0 the audit ran
#       2 usage error, or the inventory is missing or unparseable — never treated as a pass

set -euo pipefail

# A rate must not change with the reader's locale: a decimal comma is a different number.
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

REPO="${RULE_AUDIT_REPO:-${REPO_ROOT}}"
TRANSCRIPTS="${RULE_AUDIT_TRANSCRIPTS:-${HOME}/.claude/projects}"
CACHE="${RULE_AUDIT_CACHE:-${TMPDIR:-/tmp}/rule-audit-cache}"
INVENTORY="${REPO_ROOT}/vault/research/rule-inventory.md"
PATTERNS="${REPO_ROOT}/lib/doc-lint-patterns.tsv"

US=$'\037'          # field separator for parsed rows; never appears in markdown
FLOOR=10            # denominators below this are UNSCORABLE
only_rule=""
by_month=0
refresh=0
dump_corpus=""
mode=score

die() { printf 'rule-audit: %s\n' "$*" >&2; exit 2; }

usage() { sed -n '2,33p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
    case "$1" in
        --rule)      only_rule="${2:-}"; [ -n "${only_rule}" ] || die "--rule needs an id"; shift 2 ;;
        --by-month)  by_month=1; shift ;;
        --list)      mode=list; shift ;;
        --dump)      dump_corpus="${2:-}"; [ -n "${dump_corpus}" ] || die "--dump needs a corpus"; mode=dump; shift 2 ;;
        --refresh)   refresh=1; shift ;;
        --floor)     FLOOR="${2:-}"; shift 2 ;;
        --inventory) INVENTORY="${2:-}"; shift 2 ;;
        -h|--help)   usage; exit 0 ;;
        *)           die "unknown argument: $1" ;;
    esac
done

[ -r "${INVENTORY}" ] || die "inventory not readable: ${INVENTORY}"

# ---------------------------------------------------------------------------- inventory

# Parse the rule table into US-separated rows. Splits on `|` only where it is not backslash-escaped,
# so a cell may hold an ERE alternation. A row whose id does not look like an id is skipped, which
# is how the header, the separator and the two explanatory tables above it are ignored.
parse_inventory() {
    awk -v US="${US}" '
        /^\|/ {
            line = $0
            sub(/^\|/, "", line); sub(/\|[[:space:]]*$/, "", line)
            n = length(line); cur = ""; nf = 0; out = ""
            for (i = 1; i <= n; i++) {
                c = substr(line, i, 1)
                if (c == "\\" && substr(line, i + 1, 1) == "|") { cur = cur "|"; i++; continue }
                if (c == "|") { out = out cur US; nf++; cur = ""; continue }
                cur = cur c
            }
            out = out cur; nf++
            if (nf != 10) next
            if (out !~ /^[[:space:]]*R-[0-9]+[[:space:]]*'"${US}"'/) next
            print out
        }
    ' "${INVENTORY}"
}

trim() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^`//' -e 's/`$//'; }

# @doc-lint:GROUP — the group's regexes from lib/doc-lint-patterns.tsv, joined. Keeping one copy of
# those patterns means a rule change in the linter reaches this audit without a second edit.
expand_tokens() {
    local expr="$1" group joined
    case "${expr}" in
        *@doc-lint:*)
            group="${expr##*@doc-lint:}"
            [ -r "${PATTERNS}" ] || die "pattern table not readable: ${PATTERNS}"
            joined="$(awk -F'\t' -v g="${group}" '$1 ~ ("^" g "[0-9]") { printf "%s%s", (n++ ? "|" : ""), $3 }' "${PATTERNS}")"
            [ -n "${joined}" ] || die "no patterns for group ${group} in ${PATTERNS}"
            printf '%s' "${expr%%@doc-lint:*}${joined}"
            ;;
        *) printf '%s' "${expr}" ;;
    esac
}

# ---------------------------------------------------------------------------- corpora

# Split a shell command into simple commands. Heredoc bodies are dropped and separators inside
# quotes are not separators, so `grep "git add -A" f` yields the command `grep`, not `git add`.
NORMALIZER='
function unescape(s,   out, i, c, n) {
    out = ""; n = length(s)
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (c == "\\" && i < n) {
            i++; c = substr(s, i, 1)
            if (c == "n") out = out "\n"
            else if (c == "t") out = out " "
            else if (c == "r") out = out " "
            else out = out c
        } else out = out c
    }
    return out
}
function strip_heredocs(t,   lines, k, i, out, term, inbody, line, m) {
    k = split(t, lines, "\n"); out = ""; inbody = 0; term = ""
    for (i = 1; i <= k; i++) {
        line = lines[i]
        if (inbody) { m = line; gsub(/^[ \t]+|[ \t]+$/, "", m); if (m == term) inbody = 0; continue }
        out = out line "\n"
        if (match(line, /<<-?[ ]*['"'"'"]?[A-Za-z_][A-Za-z0-9_]*['"'"'"]?/)) {
            term = substr(line, RSTART, RLENGTH)
            sub(/^<<-?[ ]*/, "", term); gsub(/['"'"'"]/, "", term)
            inbody = 1
        }
    }
    return out
}
function flush(m, cur) {
    gsub(/[\n\t]/, " ", cur)
    gsub(/^[ ]+|[ ]+$/, "", cur)
    sub(/^[A-Za-z_][A-Za-z0-9_]*=[^ ]*[ ]+/, "", cur)
    if (cur != "") printf "%s\t%s\n", m, cur
}
function emit(m, t,   i, n, c, q, cur) {
    n = length(t); q = ""; cur = ""
    for (i = 1; i <= n; i++) {
        c = substr(t, i, 1)
        if (q != "") {
            if (c == "\\" && q == "\"") { cur = cur c substr(t, i + 1, 1); i++; continue }
            if (c == q) q = ""
            cur = cur c; continue
        }
        if (c == "'"'"'" || c == "\"") { q = c; cur = cur c; continue }
        if (c == "\\") { cur = cur c substr(t, i + 1, 1); i++; continue }
        if (c == "$" && substr(t, i + 1, 1) == "(") { flush(m, cur); cur = ""; i++; continue }
        if (c == "\n" || c == ";" || c == "&" || c == "|" || c == "(" || c == ")" || c == "`" || c == "{" || c == "}") {
            flush(m, cur); cur = ""; continue
        }
        cur = cur c
    }
    flush(m, cur)
}
{
    line = $0; month = line; sub(/\t.*$/, "", month); sub(/^[^\t]*\t/, "", line)
    if (month == line) next
    emit(month, strip_heredocs(unescape(line)))
}'

build_git_subject() {
    git -C "${REPO}" log --format='%ad%x09%s' --date=format:'%Y-%m' 2>/dev/null || true
}

build_transcript_cmd() {
    [ -d "${TRANSCRIPTS}" ] || return 0
    find "${TRANSCRIPTS}" -name '*.jsonl' -exec jq -rc '
        select(.type=="assistant") as $a
        | $a.message.content[]?
        | select(.type=="tool_use" and .name=="Bash")
        | [(($a.timestamp // "")[0:7]), (.input.command // "")] | @tsv
    ' {} + 2>/dev/null | awk "${NORMALIZER}"
}

build_reply_text() {
    [ -d "${TRANSCRIPTS}" ] || return 0
    find "${TRANSCRIPTS}" -name '*.jsonl' -exec jq -rc '
        select(.type=="assistant" and (.isSidechain != true)) as $a
        | $a.message.content[]?
        | select(.type=="text")
        | [(($a.timestamp // "")[0:7]), (.text // "")] | @tsv
    ' {} + 2>/dev/null
}

# month <TAB> blob <TAB> path, oldest appearance first, one row per distinct version of a document.
build_doc_blob() {
    git -C "${REPO}" rev-list --all --reverse 2>/dev/null | while read -r rev; do
        month="$(git -C "${REPO}" log -1 --format='%ad' --date=format:'%Y-%m' "${rev}")"
        git -C "${REPO}" ls-tree -r --format='%(objectname) %(path)' "${rev}" 2>/dev/null \
            | awk -v m="${month}" '$2 ~ /^vault\/.*\.md$/ && $2 !~ /\.trail\.md$/ { print m "\t" $1 "\t" $2 }'
    done | awk -F'\t' '!seen[$2]++'
}

corpus_file() { printf '%s/%s.tsv' "${CACHE}" "$1"; }

ensure_corpus() {
    local name="$1" f
    f="$(corpus_file "${name}")"
    if [ "${refresh}" = 1 ] || [ ! -s "${f}" ]; then
        mkdir -p "${CACHE}"
        case "${name}" in
            git-subject)    build_git_subject    > "${f}.part" ;;
            transcript-cmd) build_transcript_cmd > "${f}.part" ;;
            reply-text)     build_reply_text     > "${f}.part" ;;
            doc-blob)       build_doc_blob       > "${f}.part" ;;
            *) die "unknown corpus: ${name}" ;;
        esac
        mv "${f}.part" "${f}"
    fi
    printf '%s' "${f}"
}

# ---------------------------------------------------------------------------- scoring

# Counts a line-oriented corpus. Prints `month<TAB>denominator<TAB>compliant` per month, then ALL.
score_lines() {
    local file="$1" denom="$2" compliant="$3" negate=0
    case "${compliant}" in !*) negate=1; compliant="${compliant#!}" ;; esac
    awk -F'\t' -v denom="${denom}" -v ok="${compliant}" -v neg="${negate}" '
        {
            if ($0 !~ /\t/) next
            unit = $0; sub(/^[^\t]*\t/, "", unit)
            if (unit !~ denom) next
            m = $1; d[m]++; dall++
            hit = (unit ~ ok)
            if (neg == 1) hit = !hit
            if (hit) { c[m]++; call++ }
        }
        END {
            for (m in d) printf "%s\t%d\t%d\n", m, d[m], c[m]
            printf "ALL\t%d\t%d\n", dall, call
        }
    ' "${file}"
}

# Same shape, but the unit is a reply and compliance is "no sentence over N words". Table rows,
# code fences, quotes and headings are skipped, matching lib/sentence-count.sh.
score_sentences() {
    local file="$1" denom="$2" limit="$3"
    awk -F'\t' -v denom="${denom}" -v limit="${limit}" '
        {
            if ($0 !~ /\t/) next
            unit = $0; sub(/^[^\t]*\t/, "", unit)
            if (unit !~ denom) next
            m = $1
            gsub(/\\t/, " ", unit)
            n = split(unit, L, /\\n/); prose = 0; bad = 0
            for (i = 1; i <= n; i++) {
                line = L[i]
                if (line ~ /^[[:space:]]*(#|---|```|>|`)/) continue
                if (line !~ /[A-Za-z]/) continue
                prose = 1
                k = split(line, parts, /[.!?]([[:space:]]|$)/)
                for (j = 1; j <= k; j++) {
                    w = split(parts[j], _t, /[[:space:]]+/)
                    if (w > limit && parts[j] ~ /[A-Za-z]/) bad = 1
                }
            }
            if (!prose) next
            d[m]++; dall++
            if (!bad) { c[m]++; call++ }
        }
        END {
            for (m in d) printf "%s\t%d\t%d\n", m, d[m], c[m]
            printf "ALL\t%d\t%d\n", dall, call
        }
    ' "${file}"
}

# Unit is a committed version of a document, so compliance reads the blob rather than the row.
score_blobs() {
    local file="$1" denom="$2" compliant="$3" negate=0 limit="" month blob path body
    case "${compliant}" in !*) negate=1; compliant="${compliant#!}" ;; esac
    case "${compliant}" in @lines\<=*) limit="${compliant#@lines<=}" ;; esac
    while IFS=$'\t' read -r month blob path; do
        [ -n "${path:-}" ] || continue
        printf '%s' "${path}" | grep -qE "${denom}" || continue
        body="$(git -C "${REPO}" cat-file -p "${blob}" 2>/dev/null || true)"
        local hit=0
        if [ -n "${limit}" ]; then
            [ "$(printf '%s\n' "${body}" | wc -l)" -le "${limit}" ] && hit=1
        else
            printf '%s\n' "${body}" | grep -qE "${compliant}" && hit=1 || hit=0
            [ "${negate}" = 1 ] && hit=$((1 - hit))
        fi
        printf '%s\t%d\n' "${month}" "${hit}"
    done < "${file}" | awk -F'\t' '
        { d[$1]++; dall++; if ($2 == 1) { c[$1]++; call++ } }
        END {
            for (m in d) printf "%s\t%d\t%d\n", m, d[m], c[m]
            printf "ALL\t%d\t%d\n", dall, call
        }
    '
}

# The re-runnable pipeline printed beside a rate. Where the check is a plain grep it is the grep;
# where it is a word or line count it is this script, which prints the same number.
command_for() {
    local id="$1" corpus="$2" denom="$3" compliant="$4"
    case "${corpus}" in
        doc-blob) printf "bin/rule-audit.sh --rule %s" "${id}"; return ;;
    esac
    case "${compliant}" in
        @*|!@*) printf "bin/rule-audit.sh --rule %s" "${id}"; return ;;
    esac
    local pipeline="bin/rule-audit.sh --dump ${corpus} | cut -f2-"
    [ "${denom}" = "." ] || pipeline="${pipeline} | grep -E '${denom}'"
    case "${compliant}" in
        !*) printf "%s | grep -vcE '%s'" "${pipeline}" "${compliant#!}" ;;
        *)  printf "%s | grep -cE '%s'"  "${pipeline}" "${compliant}" ;;
    esac
}

rate() { awk -v n="$1" -v d="$2" 'BEGIN { if (d == 0) print "n/a"; else printf "%.1f%%", 100 * n / d }'; }

# ---------------------------------------------------------------------------- run

rows="$(parse_inventory)"
[ -n "${rows}" ] || die "no rule rows parsed from ${INVENTORY}"

if [ "${mode}" = list ]; then
    printf '%s\n' "${rows}" | tr "${US}" '\t' | sed 's/[[:space:]]\{1,\}/ /g'
    exit 0
fi

if [ "${mode}" = dump ]; then
    cat "$(ensure_corpus "${dump_corpus}")"
    exit 0
fi

printf 'corpus cache %s\n' "${CACHE}"

printf '%s\n' "${rows}" | while IFS="${US}" read -r id rule source corpus form selfck enforced denom compliant note; do
    id="$(trim "${id}")"
    [ -z "${only_rule}" ] || [ "${id}" = "${only_rule}" ] || continue
    corpus="$(trim "${corpus}")"; form="$(trim "${form}")"
    selfck="$(trim "${selfck}")"; enforced="$(trim "${enforced}")"
    denom="$(trim "${denom}")"; compliant="$(trim "${compliant}")"; note="$(trim "${note}")"

    if [ "${corpus}" = none ] || [ -z "${denom}" ]; then
        printf '%-5s UNSCORABLE  reason=%s\n' "${id}" "${note:-no mechanical trace}"
        continue
    fi

    denom="$(expand_tokens "${denom}")"
    compliant="$(expand_tokens "${compliant}")"
    file="$(ensure_corpus "${corpus}")"

    case "${corpus}" in
        doc-blob)   counts="$(score_blobs "${file}" "${denom}" "${compliant}")" ;;
        reply-text)
            case "${compliant}" in
                @sentence\<=*) counts="$(score_sentences "${file}" "${denom}" "${compliant#@sentence<=}")" ;;
                *)             counts="$(score_lines "${file}" "${denom}" "${compliant}")" ;;
            esac ;;
        *)          counts="$(score_lines "${file}" "${denom}" "${compliant}")" ;;
    esac

    all="$(printf '%s\n' "${counts}" | awk -F'\t' '$1 == "ALL" { print $2 "\t" $3 }')"
    d="$(printf '%s' "${all}" | cut -f1)"; n="$(printf '%s' "${all}" | cut -f2)"
    d="${d:-0}"; n="${n:-0}"

    if [ "${d}" -lt "${FLOOR}" ]; then
        printf '%-5s UNSCORABLE  reason=denominator %s is below the floor of %s\n' "${id}" "${d}" "${FLOOR}"
        continue
    fi

    printf '%-5s %-7s %s/%s  %s  %s  self-check=%s  enforced=%s  cmd=%s\n' \
        "${id}" "$(rate "${n}" "${d}")" "${n}" "${d}" "${corpus}" "${form}" \
        "${selfck}" "${enforced}" "$(command_for "${id}" "${corpus}" "${denom}" "${compliant}")"

    if [ "${by_month}" = 1 ]; then
        printf '%s\n' "${counts}" | awk -F'\t' '$1 != "ALL"' | sort | while IFS=$'\t' read -r m md mc; do
            printf '        %s  %-7s %s/%s\n' "${m}" "$(rate "${mc}" "${md}")" "${mc}" "${md}"
        done
    fi
done
