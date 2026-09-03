#!/usr/bin/env bash
# Measure one assistant reply. Reads the reply on stdin, prints one JSON object on stdout.
#
# The terminal half of the pair: bin/doc-lint.sh measures a file the model wrote, this measures a
# reply the model spoke. Both read their rules from the same places — lib/sentence-count.sh for the
# sentence ceiling, lib/doc-lint-patterns.tsv for banned filler.
#
# Two settings differ from the document linter, on purpose:
#   * the sentence ceiling is 25 words, not 30 (commands/_shared/communication.md);
#   * table rows are counted, not skipped. An options table is most of a decision block, which is
#     the reply shape the contract cares about most.
#
# This script measures and nothing else: it never writes a file, never reaches the network, and
# always exits 0. A measuring tool that can fail a turn is worse than no measuring tool.
#
# `is_decision_block` reports whether the reply contains a markdown table. The 15-line cap in
# commands/_shared/communication.md governs a decision block and nothing else, so a caller must not
# apply it to an ordinary answer whose right length is two lines.
#
# Usage:  printf '%s' "$reply" | bin/output-lint.sh
# Output: {"lines":41,"words":612,"long_sentences":4,"phrase_hits":2,"phrases":"PROSE1,REF3",
#          "is_decision_block":1}

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SENTENCE_LIMIT=25

# The fallback must carry every field the normal path emits, or the log has two shapes to read.
tmp="$(mktemp 2>/dev/null)" || {
    printf '{"lines":0,"words":0,"long_sentences":0,"phrase_hits":0,"phrases":"","notes":"","is_decision_block":0}\n'
    exit 0
}
trap 'rm -f "$tmp"' EXIT
cat > "$tmp"

lines="$(wc -l < "$tmp" | tr -d ' ')"
words="$(wc -w < "$tmp" | tr -d ' ')"
# wc -l counts newlines, so a reply with no trailing newline loses its last line.
[ -s "$tmp" ] && [ -n "$(tail -c 1 "$tmp")" ] && lines=$((lines + 1))

long_sentences=0
if [ -r "${SCRIPT_DIR}/../lib/sentence-count.sh" ]; then
    # shellcheck source=../lib/sentence-count.sh
    . "${SCRIPT_DIR}/../lib/sentence-count.sh"
    long_sentences="$(count_long_sentences "$tmp" "$SENTENCE_LIMIT" 0 | grep -c . || true)"
fi

# Banned filler. `prose` rows are written for replies; `reference` and `process` rows already ban
# the same back-references and panel vocabulary, so they are read rather than copied.
#
# Matched through lib/prose-match.sh, the same helpers bin/doc-lint.sh uses: fenced blocks and
# inline code are blanked first (a reply showing `grep BLOCKER file` is quoting, not asserting), and
# the shouted codes match on case (matched loosely, PROSE4 also catches "the major risk is cost",
# which is ordinary English and breaks nothing).
phrases=""
notes=""
phrase_hits=0
PATTERN_FILE="${DOC_LINT_PATTERNS:-${SCRIPT_DIR}/../lib/doc-lint-patterns.tsv}"
if [ -r "$PATTERN_FILE" ] && [ -r "${SCRIPT_DIR}/../lib/prose-match.sh" ]; then
    # shellcheck source=../lib/prose-match.sh
    . "${SCRIPT_DIR}/../lib/prose-match.sh"
    matchable="${tmp}.matchable"
    matchable_copy "$tmp" > "$matchable"
    while IFS=$'\t' read -r code group regex message; do
        [ -z "${code:-}" ] && continue
        case "${group:-}" in prose|reference|process) ;; *) continue ;; esac
        # Unquoted on purpose: the helper prints nothing for a case-sensitive code, and an empty
        # quoted argument would become grep's pattern.
        # shellcheck disable=SC2046
        if grep -q $(pattern_case_flag "$code") -E "$regex" "$matchable" 2>/dev/null; then
            phrases="${phrases:+${phrases},}${code}"
            # The reminder prints this, not the code: a code number tells the reader nothing.
            notes="${notes:+${notes}; }${message%% —*}"
            phrase_hits=$((phrase_hits + 1))
        fi
    done < <(grep -v '^#' "$PATTERN_FILE" | grep -v '^[[:space:]]*$')
    rm -f "$matchable"
fi

# A decision block is what the 15-line cap governs, and the contract defines it by its fields, not
# by a table. Keying on a table gets both halves wrong: a long decision written as prose escapes,
# and a short factual table is flagged for a cap that never applied to it. Two of the six field
# labels is the test — one alone appears in ordinary prose.
labels=0
for label in Recommendation Impact Options 'What I assumed' 'Open points' 'The ask'; do
    grep -qE "^[[:space:]]*(\*\*|[0-9]+\.[[:space:]]*\*\*)?${label}\b" "$tmp" 2>/dev/null \
        && labels=$((labels + 1))
done
is_decision_block=0
[ "${labels}" -ge 2 ] && is_decision_block=1

printf '{"lines":%d,"words":%d,"long_sentences":%d,"phrase_hits":%d,"phrases":"%s","notes":"%s","is_decision_block":%d}\n' \
    "${lines:-0}" "${words:-0}" "${long_sentences:-0}" "${phrase_hits:-0}" "${phrases}" \
    "$(printf '%s' "${notes}" | tr -d '"\\')" "${is_decision_block}"
exit 0
