#!/usr/bin/env bash
# lib/cr-helpers.sh — pure helpers for /v-cr: comment fingerprints, task-key extraction,
# changeset measurement, and post-delivery verification.
# No network, no side effects. Sourced into the caller's shell; written to behave identically
# under bash and zsh (no reliance on IFS word-splitting). Unit-tested in tests/unit/v-cr.bats
# and tests/unit/cr-coverage.bats.

# cr_code_hash — read hunk/source content on stdin, print a stable sha256. Used as the
# line-number-INDEPENDENT component of a comment fingerprint so a finding survives rebases /
# line shifts (skeptic-2).
cr_code_hash() {
    sha256sum | cut -d' ' -f1
}

# cr_fingerprint <file> <rule> <code_hash> — the idempotency key for a posted comment.
# Keyed ONLY on stable signals (file path, rule id, hashed offending code) — NEVER on the
# LLM-generated message, which varies run-to-run and would defeat dedup (skeptic-2). Two runs
# over the same hunk therefore produce the same fingerprint regardless of comment wording.
cr_fingerprint() {
    printf '%s:%s:%s' "$1" "$2" "$3" | sha256sum | cut -d' ' -f1
}

# cr_jira_keys <text> — extract VALIDATED Jira issue keys from <text> (which the caller must
# limit to the branch name + PR title — never the body or diff; skeptic-4). A candidate
# [A-Z][A-Z0-9]+-[0-9]+ is emitted only if its project prefix is in VCR_JIRA_PROJECTS (a
# ';'-separated allowlist of the user's real project keys). With no allowlist, nothing is
# emitted — this is what stops UTF-8 / SHA-256 / HTTP2-1 / RELEASE-2 from being mistaken for
# tickets and silently grounding the review against the wrong issue. Output is deduped.
cr_jira_keys() {
    local text="$1" allow="${VCR_JIRA_PROJECTS:-}" key proj
    [ -n "$allow" ] || return 0
    printf '%s\n' "$text" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | while IFS= read -r key; do
        proj="${key%%-*}"
        case ";${allow};" in
            *";${proj};"*) printf '%s\n' "$key" ;;
        esac
    done | awk '!seen[$0]++'
}

# cr_asana_gids <text> — extract Asana task GIDs from task URLs in <text> (branch + title +
# body permitted: Asana refs are explicit URLs, not ambient tokens). Handles the legacy
# app.asana.com/0/<project>/<task> and the newer /1/.../task/<task> forms; emits the trailing
# task GID. The Asana task itself is fetched via the Asana MCP (commands/v-cr/tasks/asana.md).
cr_asana_gids() {
    printf '%s\n' "$1" \
        | grep -oE 'app\.asana\.com/[0-9]+/[0-9/a-z]*[0-9]+' \
        | grep -oE '[0-9]+$' \
        | awk '!seen[$0]++'
}

# cr_diff_stats — read a changed-file list on stdin as "<path><TAB><added><TAB><deleted>" rows
# (one per file, the shape `gh api .../pulls/<n>/files --jq` emits) and print
# "<files><TAB><added><TAB><deleted><TAB><changed_lines>".
#
# This is the measurement `03-review.md` §3.2's large-diff guard was written against and never
# had: with no way to compute diff size, the guard could not fire, and a 523-file changeset was
# reviewed as though it were a small one. Blank and malformed rows are ignored rather than
# aborting — a partial file list must still yield a number the caller can act on.
cr_diff_stats() {
    awk -F'\t' '
        { sub(/\r$/, "") }              # a CRLF row would fail the digit test and silently count 0
        # Counts are the LAST two fields, never $2/$3: a path may itself contain a tab, which
        # shifts every field right and drops the file plus its lines from the total in silence.
        NF >= 3 && $(NF-1) ~ /^[0-9]+$/ && $NF ~ /^[0-9]+$/ { n++; a += $(NF-1); d += $NF }
        END { printf "%d\t%d\t%d\t%d\n", n, a, d, a + d }
    '
}

# cr_verify_posted <intended_file> <actual_file> — the delivery read-back.
# Both arguments are files of fingerprints, one per line (<intended> = what the run meant to
# post; <actual> = what listing the PR afterwards returned). Prints one row per discrepancy:
#   "missing<TAB><fp>"  — intended but absent from the forge (a post that silently failed)
#   "extra<TAB><fp>"    — present on the forge but not intended this run
# Exit status 0 when the two sets match exactly, 1 when they do not.
#
# The caller MUST treat rc 1 as an error. `/v-cr` previously asserted its own success
# ("Posted: <n> inline + summary"), so a failed post was recorded in the vault as delivered.
# cr_vault_leak_check <comment_body_file> <indication_file>... — the fork/public egress control.
# Prints "leak<TAB><indication_file><TAB><matched text>" for each rule file whose wording appears
# verbatim in the comment body; exit 0 when clean, 1 when anything leaked, 2 on unreadable input.
#
# On a fork or public PR a critic may cite a project rule by slug but never by its text
# (03-review.md §3.3), because the rule bodies are private vault content and the comment is public.
# An instruction alone does not stop a critic that quotes the rule anyway, so this runs at the
# write boundary (04-post.md §4.2).
#
# Method: slide a window of $CR_LEAK_SHINGLE (default 40) characters over each indication's prose
# and look for any window occurring literally in the comment. Whitespace is collapsed first so a
# re-wrapped quote still matches. Short shared phrases stay under the window and do not trip it.
cr_vault_leak_check() {
    local body="${1:-}"; shift 2>/dev/null || true
    [ -r "$body" ] || return 2
    [ "$#" -gt 0 ] || return 0

    local n="${CR_LEAK_SHINGLE:-40}" rc=0 rule flat rflat len i win
    flat="$(tr -s '[:space:]' ' ' < "$body")"

    for rule in "$@"; do
        [ -r "$rule" ] || continue
        # Frontmatter and markdown syntax are shared by every file; compare prose only.
        rflat="$(sed '1{/^---$/,/^---$/d}' "$rule" | tr -s '[:space:]' ' ' | tr -d '`*#|[]')"
        len=${#rflat}
        [ "$len" -ge "$n" ] || continue
        i=0
        while [ "$i" -le $((len - n)) ]; do
            win="${rflat:$i:$n}"
            case "$flat" in
                *"$win"*)
                    printf 'leak\t%s\t%s\n' "$rule" "$win"
                    rc=1
                    break ;;
            esac
            i=$((i + 8))                 # stride: a real quote is far longer than the window
        done
    done
    return "$rc"
}

cr_verify_posted() {
    local intended="${1:-}" actual="${2:-}" rc=0 fp
    [ -r "$intended" ] && [ -r "$actual" ] || return 2

    local i_sorted a_sorted
    i_sorted="$(sort -u "$intended")"
    a_sorted="$(sort -u "$actual")"

    # `while read` rather than an unquoted expansion: zsh does not word-split unquoted
    # parameters, so `printf ... $missing` would emit one blob under zsh and N rows under bash.
    while IFS= read -r fp; do
        [ -n "$fp" ] || continue
        printf 'missing\t%s\n' "$fp"
        rc=1
    done <<EOF
$(printf '%s\n' "$i_sorted" | comm -23 - <(printf '%s\n' "$a_sorted"))
EOF

    while IFS= read -r fp; do
        [ -n "$fp" ] || continue
        printf 'extra\t%s\n' "$fp"
        rc=1
    done <<EOF
$(printf '%s\n' "$i_sorted" | comm -13 - <(printf '%s\n' "$a_sorted"))
EOF

    return "$rc"
}
