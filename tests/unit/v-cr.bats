#!/usr/bin/env bats
# Tests for /v-cr: the cr-helpers pure logic (fingerprint stability, Jira-key allowlisting)
# plus structural checks that the command + steps + adapters + persona are wired correctly.
# Guards skeptic-t1 (fingerprint), skeptic-t2 (task-key false positives), and the file contract.

setup() {
    source /code/lib/cr-helpers.sh
}

# --- fingerprint (skeptic-2 / skeptic-t1) ---

@test "fingerprint is stable across runs and independent of message text" {
    local h fp1 fp2
    h="$(printf 'if (user == null) return;' | cr_code_hash)"
    fp1="$(cr_fingerprint 'src/a.ts' 'null-deref' "$h")"
    fp2="$(cr_fingerprint 'src/a.ts' 'null-deref' "$h")"
    [ -n "$fp1" ]
    [ "$fp1" = "$fp2" ]
}

@test "fingerprint differs when file, rule, or code-hash differ" {
    local h hp
    h="$(printf 'x' | cr_code_hash)"
    hp="$(printf 'y' | cr_code_hash)"
    [ "$(cr_fingerprint a r "$h")" != "$(cr_fingerprint b r "$h")" ]   # file
    [ "$(cr_fingerprint a r "$h")" != "$(cr_fingerprint a q "$h")" ]   # rule
    [ "$(cr_fingerprint a r "$h")" != "$(cr_fingerprint a r "$hp")" ]  # code
}

# --- Jira key extraction (skeptic-4 / skeptic-t2) ---

@test "Jira extraction emits only allowlisted project keys" {
    export VCR_JIRA_PROJECTS="PROJ;ABC"
    run cr_jira_keys "feature/PROJ-123-login fixes UTF-8 SHA-256 RELEASE-2 ABC-9"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PROJ-123"* ]]
    [[ "$output" == *"ABC-9"* ]]
    [[ "$output" != *"UTF-8"* ]]
    [[ "$output" != *"SHA-256"* ]]
    [[ "$output" != *"RELEASE-2"* ]]
}

@test "Jira extraction emits nothing without an allowlist" {
    unset VCR_JIRA_PROJECTS
    run cr_jira_keys "PROJ-123 ABC-9"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "Jira extraction dedups repeated keys" {
    export VCR_JIRA_PROJECTS="PROJ"
    run cr_jira_keys "PROJ-1 PROJ-1 PROJ-1"
    [ "$(printf '%s\n' "$output" | grep -c 'PROJ-1')" -eq 1 ]
}

# --- structural contract ---

@test "v-cr dispatcher exists and references all five steps" {
    [ -f /code/commands/v-cr.md ]
    for n in 01-detect 02-gather 03-review 04-post 05-capture; do
        grep -q "$n" /code/commands/v-cr.md
    done
}

@test "all five step files exist" {
    for n in 01-detect 02-gather 03-review 04-post 05-capture; do
        [ -f "/code/commands/v-cr/steps/${n}.md" ]
    done
}

@test "shared single-pass critic-panel module exists and has no fix/reloop directives" {
    [ -f /code/commands/_shared/critic-panel.md ]
    # The whole point of extracting it (arch-1/skeptic-1): single pass, no between-round fixes.
    ! grep -qiE 'apply fixes between rounds|re-spawn for the next round' /code/commands/_shared/critic-panel.md
}

@test "forge + task adapters exist for the v0 scope (GitHub, Bitbucket, Jira, Asana)" {
    [ -f /code/commands/v-cr/adapters.md ]
    [ -f /code/commands/v-cr/adapters/github.md ]
    [ -f /code/commands/v-cr/adapters/bitbucket-cloud.md ]
    [ -f /code/commands/v-cr/adapters/bitbucket-server.md ]
    [ -f /code/commands/v-cr/tasks/jira.md ]
    [ -f /code/commands/v-cr/tasks/asana.md ]
}

@test "correctness lens is a first-class shared persona and is wired into resolution" {
    [ -f /code/personas/_shared/correctness.md ]
    grep -q "correctness" /code/personas/_resolution.md
}

@test "the never-commit invariant is documented in the post step" {
    grep -qiE 'never (commit|push|appl)' /code/commands/v-cr/steps/04-post.md
}
