#!/usr/bin/env bash
# Shared phrase-matching helpers for bin/doc-lint.sh (documents) and bin/output-lint.sh (replies).
#
# Both linters read the same pattern table and must treat text the same way, or the same sentence is
# a finding in one and clean in the other.

# matchable_copy <file>
# Quoted text is not a claim. A document that defines these rules has to name the phrases it bans,
# and a reply legitimately shows a command containing one. So patterns are matched against a copy
# with fenced blocks and inline `code` spans blanked out, line numbering preserved. Quote the thing
# you are banning and the linter stays quiet; assert it in your own voice and it fires.
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

# pattern_case_flag <code>
# Most rules are about wording, and a sentence-initial capital must not let one through, so they
# match case-insensitively. The exceptions match on case itself: struck-through markup and the
# shouted markers WITHDRAWN, BLOCKER and MAJOR, whose lowercase forms are ordinary English words.
#
# Case-sensitive prints **nothing**, because grep is already case-sensitive and every extra token
# here lands unquoted in the caller's command line. Do not emit `-e`: grep reads it as "the next
# argument is the pattern", which silently turns the real pattern into a filename.
pattern_case_flag() {
    case "$1" in
        HIST3|HIST4|PROC5|PROSE4) : ;;
        *)                        printf '%s' '-i' ;;
    esac
}
