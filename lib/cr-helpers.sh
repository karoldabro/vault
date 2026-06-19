#!/usr/bin/env bash
# lib/cr-helpers.sh — pure helpers for /v-cr: comment fingerprints + task-key extraction.
# No network, no side effects. Sourced into the caller's shell; written to behave identically
# under bash and zsh (no reliance on IFS word-splitting). Unit-tested in tests/unit/v-cr.bats.

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
