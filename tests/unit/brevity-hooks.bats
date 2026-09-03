#!/usr/bin/env bats
# Behaviour tests for the reply-measurement pair: bin/output-lint.sh and the two hooks that wrap it.
#
# These are real behaviour tests, not file contracts. Three of them are load-bearing:
#
#   * the Stop hook must never exit 2. Exit 2 blocks the stop and continues the conversation, so a
#     reply that was already too long grows.
#   * the reminder must be silent when the previous reply met every limit. A limit shown after a
#     compliant reply becomes a figure to fill, and a two-line answer drifts up toward fifteen.
#   * bin/doc-lint.sh must survive a missing lib/sentence-count.sh. It runs from a live PostToolUse
#     hook; aborting there returns shell errors to the model as lint findings on every write.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    OUTLINT="${VAULT_ROOT}/bin/output-lint.sh"
    STOP_HOOK="${VAULT_ROOT}/scripts/output-lint-hook.sh"
    ASK_HOOK="${VAULT_ROOT}/scripts/brevity-reminder-hook.sh"
    TMP="$(mktemp -d)"
    export HOME="${TMP}/home"
    mkdir -p "${HOME}/.claude"
}

teardown() {
    rm -rf "${TMP}"
}

words() {  # words <n> — a single sentence of n words, terminated
    local n="$1" out="" i
    for ((i = 0; i < n - 1; i++)); do out+="word "; done
    printf '%s.\n' "${out}end"
}

field() {  # field <json> <key>
    printf '%s' "$1" | jq -r ".${2}"
}

# --- bin/output-lint.sh ------------------------------------------------------------------------

@test "output-lint counts 0, 1, 15 and 16 lines" {
    [ "$(printf '' | "${OUTLINT}" | jq -r .lines)" -eq 0 ]
    [ "$(printf 'one' | "${OUTLINT}" | jq -r .lines)" -eq 1 ]
    [ "$(printf 'x\n%.0s' {1..15} | "${OUTLINT}" | jq -r .lines)" -eq 15 ]
    [ "$(printf 'x\n%.0s' {1..16} | "${OUTLINT}" | jq -r .lines)" -eq 16 ]
}

@test "output-lint flags a 26-word sentence and clears a 25-word one" {
    [ "$(words 25 | "${OUTLINT}" | jq -r .long_sentences)" -eq 0 ]
    [ "$(words 26 | "${OUTLINT}" | jq -r .long_sentences)" -eq 1 ]
}

@test "an over-long sentence inside a table row is counted for a reply and skipped for a document" {
    local row
    row="| $(words 30 | tr -d '\n') |"

    printf '%s\n' "${row}" > "${TMP}/reply.md"
    [ "$("${OUTLINT}" < "${TMP}/reply.md" | jq -r .long_sentences)" -eq 1 ]

    # The document linter's own setting skips table rows, and must keep doing so.
    . "${VAULT_ROOT}/lib/sentence-count.sh"
    [ -z "$(count_long_sentences "${TMP}/reply.md" 30 1)" ]
}

@test "the shared counter honours both word limits from one code path" {
    . "${VAULT_ROOT}/lib/sentence-count.sh"
    words 27 > "${TMP}/s.md"
    [ -n "$(count_long_sentences "${TMP}/s.md" 25 0)" ]   # over the reply ceiling
    [ -z "$(count_long_sentences "${TMP}/s.md" 30 0)" ]   # inside the document ceiling
}

@test "output-lint reports banned filler by code" {
    local out
    out="$(printf 'No issues found. As noted above, it is recommended that we ship.\n' | "${OUTLINT}")"
    [ "$(field "${out}" phrase_hits)" -gt 0 ]
    printf '%s' "${out}" | grep -q 'PROSE1'
    printf '%s' "${out}" | grep -q 'REF2'
}

@test "a decision block is recognised by its fields, not by containing a table" {
    # The 15-line cap governs a decision presentation. Keying on a table gets both halves wrong:
    # a long decision written as prose escapes, and a short factual table is flagged for a cap
    # that never applied to it.
    [ "$(printf 'text only\n' | "${OUTLINT}" | jq -r .is_decision_block)" -eq 0 ]
    [ "$(printf '| a | b |\n| c | d |\n' | "${OUTLINT}" | jq -r .is_decision_block)" -eq 0 ]

    local prose numbered
    prose="$(printf '**Recommendation** — do X.\n**Impact** — two files.\n')"
    numbered="$(printf '1. **Recommendation** — do X.\n2. **Impact** — two files.\n')"
    [ "$(printf '%s\n' "${prose}"    | "${OUTLINT}" | jq -r .is_decision_block)" -eq 1 ]
    [ "$(printf '%s\n' "${numbered}" | "${OUTLINT}" | jq -r .is_decision_block)" -eq 1 ]

    # One label alone appears in ordinary prose and must not count.
    [ "$(printf 'Impact was minimal.\n' | "${OUTLINT}" | jq -r .is_decision_block)" -eq 0 ]
}

@test "the shouty codes match case-sensitively, so ordinary English does not trip them" {
    # "the major risk is cost" breaks nothing. A linter that fires on legitimate work gets
    # switched off, and then it enforces nothing at all.
    [ "$(printf 'The major risk is cost.\n' | "${OUTLINT}" | jq -r .phrase_hits)" -eq 0 ]
    [ "$(printf 'One BLOCKER remains.\n'    | "${OUTLINT}" | jq -r .phrase_hits)" -gt 0 ]
}

@test "the case-sensitive flag prints nothing, never a grep option" {
    # `-e` tells grep the NEXT argument is the pattern, which silently turns the real pattern into
    # a filename and the filename into a pattern. The original code emitted it via `echo "-e"`,
    # which bash swallowed as its own flag, so the bug was invisible until the call was rewritten.
    . "${VAULT_ROOT}/lib/prose-match.sh"
    [ -z "$(pattern_case_flag PROSE4)" ]
    [ -z "$(pattern_case_flag PROC5)" ]
    [ "$(pattern_case_flag REF2)" = "-i" ]
}

@test "quoted text is not a claim — code blocks and inline code never fire" {
    # A reply legitimately shows the command or the token it is talking about. Firing on that is
    # the false positive that gets a linter switched off.
    [ "$(printf 'Run:\n\n```\ngrep BLOCKER file.txt\n```\n' | "${OUTLINT}" | jq -r .phrase_hits)" -eq 0 ]
    [ "$(printf 'Use `BLOCKER` as the severity token.\n'    | "${OUTLINT}" | jq -r .phrase_hits)" -eq 0 ]
    # Asserted in your own voice, it still fires.
    [ "$(printf 'One BLOCKER remains.\n'                    | "${OUTLINT}" | jq -r .phrase_hits)" -gt 0 ]
    # And an ordinary sentence with a code block nearby stays clean.
    [ "$(printf 'I refactored the major loop.\n\n```\nx\n```\n' | "${OUTLINT}" | jq -r .phrase_hits)" -eq 0 ]
}

@test "the file the Stop hook writes is the file the reminder reads" {
    # Both build the path through one function; two copies would drift and the reminder would
    # silently never speak again.
    . "${VAULT_ROOT}/lib/hook-common.sh"
    local expected
    expected="$(hook_state_path pairing)"
    printf '%s' '{"session_id":"pairing","last_assistant_message":"one two three."}' | "${STOP_HOOK}"
    [ -f "${expected}" ]
    run hook_state_path '../evil'
    [ "$status" -ne 0 ]
    [ -z "$output" ]
}

@test "the no-temp-file fallback emits every field the normal path does" {
    local normal fallback
    normal="$(printf 'x\n' | "${OUTLINT}" | jq -r 'keys | join(",")')"
    fallback="$(grep -o '{"lines":0[^}]*}' "${OUTLINT}" | head -1 | jq -r 'keys | join(",")')"
    [ "${normal}" = "${fallback}" ] \
        || { echo "normal: ${normal}"; echo "fallback: ${fallback}"; return 1; }
}

@test "output-lint reports the pattern's plain-words message, not its code" {
    # A code number in the reminder tells the reader nothing it can act on.
    local notes
    notes="$(printf 'No issues found here.\n' | "${OUTLINT}" | jq -r .notes)"
    [ -n "${notes}" ]
    printf '%s' "${notes}" | grep -qv 'PROSE'
    printf '%s' "${notes}" | grep -q 'normal'
}

# --- scripts/output-lint-hook.sh (Stop) --------------------------------------------------------

@test "the Stop hook exits 0 on every path, including a missing linter" {
    run bash -c "printf '%s' '{\"session_id\":\"s1\",\"last_assistant_message\":\"hi\"}' | '${STOP_HOOK}'"
    [ "$status" -eq 0 ]

    run bash -c "printf '%s' 'not json' | '${STOP_HOOK}'"
    [ "$status" -eq 0 ]

    run bash -c "printf '%s' '{\"session_id\":\"s1\"}' | '${STOP_HOOK}'"
    [ "$status" -eq 0 ]

    # No linter on disk: still exit 0, still write nothing.
    run bash -c "CLAUDE_PLUGIN_ROOT='${TMP}/nowhere' bash -c \"printf '%s' '{\\\"session_id\\\":\\\"s1\\\",\\\"last_assistant_message\\\":\\\"hi\\\"}' | '${STOP_HOOK}'\""
    [ "$status" -eq 0 ]
}

@test "the state filename carries the session id, so two sessions never share one" {
    printf '%s' '{"session_id":"alpha","last_assistant_message":"one two three."}' | "${STOP_HOOK}"
    printf '%s' '{"session_id":"beta","last_assistant_message":"a b."}' | "${STOP_HOOK}"
    [ -f "${HOME}/.claude/brevity-state.alpha.json" ]
    [ -f "${HOME}/.claude/brevity-state.beta.json" ]
    [ "$(jq -r .words "${HOME}/.claude/brevity-state.alpha.json")" -eq 3 ]
    [ "$(jq -r .words "${HOME}/.claude/brevity-state.beta.json")" -eq 2 ]
}

@test "a session id that is not a plain token writes no file" {
    printf '%s' '{"session_id":"../evil","last_assistant_message":"hi"}' | "${STOP_HOOK}"
    [ -z "$(find "${HOME}/.claude" -name 'brevity-state*' 2>/dev/null)" ]
}

@test "the Stop hook appends one log row per turn" {
    printf '%s' '{"session_id":"s1","last_assistant_message":"one."}' | "${STOP_HOOK}"
    printf '%s' '{"session_id":"s1","last_assistant_message":"two."}' | "${STOP_HOOK}"
    [ "$(wc -l < "${HOME}/.claude/brevity-log.jsonl")" -eq 2 ]
}

# --- scripts/brevity-reminder-hook.sh (UserPromptSubmit) ---------------------------------------

@test "the reminder is silent when the previous reply met every limit" {
    printf '%s' '{"session_id":"s1","last_assistant_message":"Short answer. Done."}' | "${STOP_HOOK}"
    run bash -c "printf '%s' '{\"session_id\":\"s1\"}' | '${ASK_HOOK}'"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "the reminder is silent with no state file and with a corrupt one" {
    run bash -c "printf '%s' '{\"session_id\":\"never-seen\"}' | '${ASK_HOOK}'"
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    printf 'not json' > "${HOME}/.claude/brevity-state.bad.json"
    run bash -c "printf '%s' '{\"session_id\":\"bad\"}' | '${ASK_HOOK}'"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "every number the reminder prints names the limit it broke" {
    words 40 > "${TMP}/long.txt"
    printf '%s' "$(jq -Rs --arg s over '{session_id:$s,last_assistant_message:.}' < "${TMP}/long.txt")" \
        | "${STOP_HOOK}"
    run bash -c "printf '%s' '{\"session_id\":\"over\"}' | '${ASK_HOOK}'"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    echo "$output" | grep -q '25-word'
    # No bare target, and nothing that licenses more text.
    echo "$output" | grep -qv 'concise'
    run bash -c "printf '%s' '{\"session_id\":\"over\"}' | '${ASK_HOOK}' | grep -ci 'cap yields\|runs longer'"
    [ "$output" -eq 0 ]
}

@test "the reminder protects warnings and stays within four lines" {
    words 40 > "${TMP}/long.txt"
    printf '%s' "$(jq -Rs --arg s over '{session_id:$s,last_assistant_message:.}' < "${TMP}/long.txt")" \
        | "${STOP_HOOK}"
    run bash -c "printf '%s' '{\"session_id\":\"over\"}' | '${ASK_HOOK}'"
    echo "$output" | grep -qi 'not warnings'
    [ "$(echo "$output" | wc -l)" -le 4 ]
}

@test "the 15-line cap fires only on a reply that is actually a decision block" {
    local plain block
    plain="$(printf 'x\n%.0s' {1..20})"
    block="$(printf '**Recommendation** — do X.\n**Impact** — two files.\n'; printf 'x\n%.0s' {1..20})"

    printf '%s' "$(jq -Rs --arg s plain '{session_id:$s,last_assistant_message:.}' <<< "${plain}")" | "${STOP_HOOK}"
    run bash -c "printf '%s' '{\"session_id\":\"plain\"}' | '${ASK_HOOK}'"
    [ -z "$output" ]

    printf '%s' "$(jq -Rs --arg s blk '{session_id:$s,last_assistant_message:.}' <<< "${block}")" | "${STOP_HOOK}"
    run bash -c "printf '%s' '{\"session_id\":\"blk\"}' | '${ASK_HOOK}'"
    echo "$output" | grep -q 'capped at 15'
}

@test "the reminder names what the filler was, never a pattern code" {
    printf '%s' "$(jq -Rs --arg s filler '{session_id:$s,last_assistant_message:.}' \
        <<< 'No issues found here.')" | "${STOP_HOOK}"
    run bash -c "printf '%s' '{\"session_id\":\"filler\"}' | '${ASK_HOOK}'"
    [ -n "$output" ]
    echo "$output" | grep -q 'normal'
    echo "$output" | grep -qv 'PROSE1'
}

@test "BREVITY=off silences both hooks" {
    run bash -c "BREVITY=off bash -c \"printf '%s' '{\\\"session_id\\\":\\\"s1\\\",\\\"last_assistant_message\\\":\\\"hi\\\"}' | '${STOP_HOOK}'\""
    [ "$status" -eq 0 ]
    [ ! -f "${HOME}/.claude/brevity-log.jsonl" ]

    run bash -c "BREVITY=off bash -c \"printf '%s' '{\\\"session_id\\\":\\\"s1\\\"}' | '${ASK_HOOK}'\""
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- the extraction that touches a live hook ---------------------------------------------------

@test "doc-lint skips a check and exits normally when a shared library is missing" {
    # It runs from a live PostToolUse hook. Aborting there returns shell errors to the model as
    # lint findings on every write, so a missing library must cost one skipped check and no more.
    local fake="${TMP}/fake"
    mkdir -p "${fake}/bin" "${fake}/lib"
    cp "${VAULT_ROOT}/bin/doc-lint.sh" "${fake}/bin/"
    cp "${VAULT_ROOT}/lib/doc-lint-patterns.tsv" "${fake}/lib/"
    # lib/sentence-count.sh and lib/prose-match.sh deliberately absent.

    printf -- '---\ntype: indication\n---\n\n# t\n\n%s\n' "$(words 40 | tr -d '\n')" > "${TMP}/d.md"

    run bash "${fake}/bin/doc-lint.sh" "${TMP}/d.md"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qv 'LONG1'

    # And with only the counter restored, the phrase checks still stand down rather than firing
    # unblanked on a document that quotes a phrase it bans.
    cp "${VAULT_ROOT}/lib/sentence-count.sh" "${fake}/lib/"
    printf -- '---\ntype: indication\n---\n\n# t\n\nas noted above, this is fine.\n' > "${TMP}/q.md"
    run bash "${fake}/bin/doc-lint.sh" "${TMP}/q.md"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qv 'REF2'
}

@test "the same document does report a long sentence when the counter is present" {
    printf -- '---\ntype: indication\n---\n\n# t\n\n%s\n' "$(words 40 | tr -d '\n')" > "${TMP}/d.md"
    run bash "${VAULT_ROOT}/bin/doc-lint.sh" "${TMP}/d.md"
    [ "$status" -eq 1 ]
    echo "$output" | grep -q 'LONG1'
}
