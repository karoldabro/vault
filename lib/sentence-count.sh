#!/usr/bin/env bash
# Shared sentence-length counter. Sourced by bin/doc-lint.sh (documents, 30 words) and
# bin/output-lint.sh (replies, 25 words).
#
# The two callers disagree about tables on purpose. A document's tables carry settled facts and
# their rows are not prose, so the document linter skips them. A reply's options table is most of a
# decision block, which is the shape the communication contract cares about most, so the reply
# linter counts it.
#
# Sourcing this file must never be able to kill its caller: bin/doc-lint.sh runs from a live
# PostToolUse hook under `set -euo pipefail`, and an abort there reaches the model as lint findings
# on every write. Callers guard the source and fall back to skipping the check.

# count_long_sentences <file> <word_limit> <skip_tables:0|1>
# Prints one line number per line holding a sentence over the limit. Prints nothing when clean.
count_long_sentences() {
    local _target="$1" _limit="$2" _skip_tables="${3:-1}"

    awk -v limit="${_limit}" -v skip_tables="${_skip_tables}" '
        skip_tables == 1 && /^[[:space:]]*[|>`]/ { next }
        skip_tables != 1 && /^[[:space:]]*[>`]/   { next }
        /^[[:space:]]*(#|---|```)/ { next }
        /^[[:space:]]*<!--/        { next }
        {
            line = $0
            if (skip_tables != 1) { gsub(/\|/, " ", line) }
            n = split(line, parts, /[.!?]([[:space:]]|$)/)
            for (i = 1; i <= n; i++) {
                w = split(parts[i], _t, /[[:space:]]+/)
                if (w > limit) { print NR; break }
            }
        }
    ' "$_target"
}
