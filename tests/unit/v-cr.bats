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

# --- delivery verification (see vault/indications/cr-delivery-verification.md) ---
# A review that posts inline comments without its summary looks complete and is not. These pin the
# contract that made that failure invisible: the run asserted its own success and nothing re-read it.

@test "post step requires the summary FIRST and aborts the inline set when it is missing" {
    grep -qi 'summary comment first' /code/commands/v-cr/steps/04-post.md
    grep -qi 'post no inline comments' /code/commands/v-cr/steps/04-post.md
}

@test "post step requires a read-back of what was written" {
    grep -q 'cr_verify_posted' /code/commands/v-cr/steps/04-post.md
    grep -qi 'read back' /code/commands/v-cr/steps/04-post.md
}

@test "post step reports verified counts, not asserted ones" {
    grep -q 'verified on forge' /code/commands/v-cr/steps/04-post.md
    # The old self-assertion must be gone, not merely supplemented.
    ! grep -qE '^Posted: <n inline' /code/commands/v-cr/steps/04-post.md
}

@test "capture step records every coverage field" {
    for f in files_changed files_examined files_unexamined unexamined_paths \
             coverage_accepted inline_intended inline_verified \
             summary_verified dropped_over_cap capped_chunked; do
        grep -q "$f" /code/commands/v-cr/steps/05-capture.md
    done
}

@test "capture step surfaces coverage and delivery in the completion report" {
    grep -q '^Coverage:' /code/commands/v-cr/steps/05-capture.md
    grep -q '^Delivery:' /code/commands/v-cr/steps/05-capture.md
}

# --- volume cap (03-review.md 3.4) ---

@test "blocker and major findings are exempt from the inline volume cap" {
    grep -qi 'BLOCKER and MAJOR findings are exempt' /code/commands/v-cr/steps/03-review.md
}

@test "the volume cap applies to the merged post-synthesis set, never per unit" {
    grep -qi 'post-synthesis set for the whole review' /code/commands/v-cr/steps/03-review.md
}

# --- untrusted comments (sec-1, sec-4) ---

@test "PR comments are named in the shared untrusted-input contract" {
    grep -qi 'PR/MR comments' /code/commands/_shared/critic-panel.md
}

@test "the secret scan covers comment bodies, not just the diff" {
    grep -qi 'comment body' /code/commands/v-cr/steps/02-gather.md
}

# --- indication retrieval (02-gather.md 2.4) ---

@test "gather step states the indication retrieval rule" {
    grep -qi 'indication retrieval rule' /code/commands/v-cr/steps/02-gather.md
    grep -qi 'Read .indications/_index.md. only' /code/commands/v-cr/steps/02-gather.md
    grep -qi 'on demand, by slug' /code/commands/v-cr/steps/02-gather.md
}

@test "gather step reports how many rules it loaded" {
    grep -q '^Rules: <r> index rows' /code/commands/v-cr/steps/02-gather.md
}

@test "gather step still loads rules when the index has no scope column" {
    # Five of the seven project indexes have no scope column. A retrieval rule whose fallback is
    # "load nothing" would silently strip every project rule from those reviews.
    grep -qi 'Most indexes have no .scope. column' /code/commands/v-cr/steps/02-gather.md
    grep -qi 'loading nothing is not the safe default' /code/commands/v-cr/steps/02-gather.md
}

@test "the volume-cap exemption does not bypass the --max-comments gate" {
    grep -qi 'exemption does not bypass the gate' /code/commands/v-cr/steps/03-review.md
    grep -qi 'Severity buys no exemption here' /code/commands/v-cr/steps/04-post.md
}

@test "POST is marked completed only on a verified full delivery" {
    grep -qi 'only when the summary was verified' /code/commands/v-cr/steps/04-post.md
}

# --- fork/public vault-text egress (sec-6) ---

@test "fork and public PRs cite a rule by slug, never by its text" {
    grep -qi 'by slug, never by its text' /code/commands/v-cr/steps/03-review.md
}

@test "the write boundary rejects vault text in a public comment, with a real check behind it" {
    # A step file that only asserts a check exists is the instruction it criticises. The named
    # function must be implemented, not merely referenced.
    grep -q 'cr_vault_leak_check' /code/commands/v-cr/steps/04-post.md
    grep -q '^cr_vault_leak_check()' /code/lib/cr-helpers.sh
}

@test "the new indication is registered in the indications index" {
    # 02-gather.md 2.4 reads the index only, so an unregistered rule is unreachable.
    grep -q 'cr-delivery-verification' /code/vault/indications/_index.md
}

# --- learning from operator comments (sec-1, sec-2) ---

@test "comment-derived rules require write permission and skip fork/public targets" {
    grep -q 'collaborators/{login}/permission' /code/commands/v-cr/steps/05-capture.md
    grep -qi 'Skip ingestion entirely when step 1 flagged' /code/commands/v-cr/steps/05-capture.md
}

@test "comment text is never copied into an indication" {
    grep -qi 'Never copy comment text into the indication' /code/commands/v-cr/steps/05-capture.md
}

@test "comment-derived rules are stamped with their provenance" {
    grep -q 'source: pr-comment' /code/commands/v-cr/steps/05-capture.md
}

# --- the framework-repo write path must not exist (sec-3, arch-5) ---

@test "no v-cr file branches, commits, pushes, or opens a pull request" {
    # A proposal file is the whole mechanism; /v-cr holds untrusted PR content and must never
    # hold a write credential for the repo that governs every other project.
    #
    # The negated class must NOT exclude `-`: nearly every instruction in these files is a bullet,
    # so `^[^#|>-]*` exempted the whole corpus and the test passed against a planted `git push`.
    # `#` and `>` stay excluded — a comment or blockquote is prose about the ban, not the ban broken.
    run grep -rnE '^[^#>]*\b(git checkout -b|git commit|git push|gh pr create)\b' \
        /code/commands/v-cr.md /code/commands/v-cr/
    [ "$status" -ne 0 ] || {
        echo "git-write verb found in a v-cr file:"; echo "$output"; false
    }
    grep -q 'proposals/<date>-<slug>.md' /code/commands/v-cr/steps/05-capture.md
}

@test "the anti-write test actually fails on a planted violation" {
    # A guard that cannot fail is not a guard. This proves the pattern above catches a bullet,
    # which is the shape every instruction in these files takes.
    printf -- '- Then run `git push` to publish it.\n' > "$BATS_TEST_TMPDIR/planted.md"
    run grep -qE '^[^#>]*\b(git push)\b' "$BATS_TEST_TMPDIR/planted.md"
    [ "$status" -eq 0 ]
}

# --- sandbox recipe provenance (sec-2) ---

@test "an indication sourced from a PR comment is refused as a sandbox recipe source" {
    grep -q 'source: pr-comment' /code/commands/v-cr/sandbox.md
    grep -q 'cr_is_recipe_key' /code/commands/v-cr/sandbox.md
}
