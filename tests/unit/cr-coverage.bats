#!/usr/bin/env bats
# Unit tests for the /v-cr measurement + delivery-verification helpers in lib/cr-helpers.sh.
#
# These cover the two defects that let a review be recorded as delivered when it was not:
# no way to measure a changeset (so 03-review.md §3.2's large-diff guard could never fire),
# and no read-back after posting (so a failed post was written to the vault as a success).

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    # shellcheck source=/dev/null
    source "$REPO_ROOT/lib/cr-helpers.sh"
    TMP="$BATS_TEST_TMPDIR"
}

# --- cr_diff_stats ---------------------------------------------------------

@test "cr_diff_stats sums files, additions, deletions and changed lines" {
    printf 'a.php\t10\t2\nb.php\t5\t3\n' > "$TMP/files"
    run cr_diff_stats < "$TMP/files"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '2\t15\t5\t20')" ]
}

@test "cr_diff_stats returns zeroes for an empty file list" {
    : > "$TMP/files"
    run cr_diff_stats < "$TMP/files"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '0\t0\t0\t0')" ]
}

@test "cr_diff_stats ignores malformed rows instead of aborting" {
    # A partial or garbled file list must still yield a usable number — the guard needs a
    # measurement more than it needs a clean input.
    printf 'a.php\t10\t2\ngarbage\nb.php\tx\ty\nc.php\t1\t1\n' > "$TMP/files"
    run cr_diff_stats < "$TMP/files"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '2\t11\t3\t14')" ]
}

@test "cr_diff_stats counts CRLF rows instead of silently returning zero" {
    # A carriage return fails the digit test on the last field, so every row is skipped and the
    # guard reads "0 changed lines" on a large diff — the precise failure this measurement exists
    # to prevent, and silent.
    printf 'a.php\t10\t2\r\nb.php\t5\t3\r\n' > "$TMP/files"
    run cr_diff_stats < "$TMP/files"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '2\t15\t5\t20')" ]
}

@test "cr_diff_stats handles a file list with no trailing newline" {
    printf 'a.php\t10\t2\nb.php\t5\t3' > "$TMP/files"
    run cr_diff_stats < "$TMP/files"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '2\t15\t5\t20')" ]
}

@test "cr_diff_stats reproduces the PR #190 scale that the guard failed to catch" {
    # 523 files / 50,817 changed lines against 03-review.md §3.2's ~1500-line threshold.
    : > "$TMP/files"
    for i in $(seq 1 523); do printf 'f%s.php\t91\t6\n' "$i" >> "$TMP/files"; done
    run cr_diff_stats < "$TMP/files"
    [ "$status" -eq 0 ]
    files=$(printf '%s' "$output" | cut -f1)
    changed=$(printf '%s' "$output" | cut -f4)
    [ "$files" -eq 523 ]
    [ "$changed" -gt 1500 ]
}

@test "cr_diff_stats counts a path containing a tab" {
    # Counts are the last two fields. Reading $2/$3 loses the file AND its lines silently —
    # an undercount in the one number the large-diff guard reads.
    printf 'we\tird.php\t10\t2\nb.php\t5\t3\n' > "$TMP/files"
    run cr_diff_stats < "$TMP/files"
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '2\t15\t5\t20')" ]
}

# --- cr_vault_leak_check ---------------------------------------------------
# The fork/public egress control. Critics hold private rule text, so the natural way to justify a
# finding is to quote the rule — which publishes vault content to a public PR.

@test "vault_leak_check passes a comment that cites a rule by slug only" {
    printf -- '---\ntype: indication\n---\n\n## Rule\nNever query Eloquent from a controller, job or service — always go through a repository class.\n' > "$TMP/rule.md"
    printf 'This violates repository-pattern-for-data-access. Route it through the repo.\n' > "$TMP/body"
    run cr_vault_leak_check "$TMP/body" "$TMP/rule.md"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "vault_leak_check catches a comment that quotes the rule text" {
    printf -- '---\ntype: indication\n---\n\n## Rule\nNever query Eloquent from a controller, job or service — always go through a repository class.\n' > "$TMP/rule.md"
    printf 'Per our rules: Never query Eloquent from a controller, job or service — always go through a repository class.\n' > "$TMP/body"
    run cr_vault_leak_check "$TMP/body" "$TMP/rule.md"
    [ "$status" -eq 1 ]
    [[ "$output" == leak* ]]
}

@test "vault_leak_check still catches a re-wrapped quote" {
    # A critic that reflows the rule across lines has still published it.
    printf -- '---\ntype: indication\n---\n\n## Rule\nNever query Eloquent from a controller, job or service — always go through a repository class.\n' > "$TMP/rule.md"
    printf 'Per our rules:\nNever query Eloquent from a\ncontroller, job or service — always go\nthrough a repository class.\n' > "$TMP/body"
    run cr_vault_leak_check "$TMP/body" "$TMP/rule.md"
    [ "$status" -eq 1 ]
}

@test "vault_leak_check does not trip on a short shared phrase" {
    # A false positive here silently drops a legitimate finding, so the window must be wide.
    printf -- '---\ntype: indication\n---\n\n## Rule\nNever query Eloquent from a controller, job or service — always go through a repository class.\n' > "$TMP/rule.md"
    printf 'Use a repository here.\n' > "$TMP/body"
    run cr_vault_leak_check "$TMP/body" "$TMP/rule.md"
    [ "$status" -eq 0 ]
}

@test "vault_leak_check returns 2 on an unreadable body and 0 with no rules to check" {
    printf 'x\n' > "$TMP/body"
    run cr_vault_leak_check "$TMP/missing" "$TMP/rule.md"
    [ "$status" -eq 2 ]
    run cr_vault_leak_check "$TMP/body"
    [ "$status" -eq 0 ]
}

# --- cr_verify_posted ------------------------------------------------------

@test "cr_verify_posted succeeds and prints nothing when the sets match" {
    printf 'aaa\nbbb\n' > "$TMP/intended"
    printf 'bbb\naaa\n' > "$TMP/actual"
    run cr_verify_posted "$TMP/intended" "$TMP/actual"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "cr_verify_posted reports a fingerprint that never reached the forge" {
    # The PR #190 case: an intended inline comment absent from the PR afterwards.
    printf 'aaa\nbbb\na6476f225b9f16bb\n' > "$TMP/intended"
    printf 'aaa\nbbb\n' > "$TMP/actual"
    run cr_verify_posted "$TMP/intended" "$TMP/actual"
    [ "$status" -eq 1 ]
    [ "$output" = "$(printf 'missing\ta6476f225b9f16bb')" ]
}

@test "cr_verify_posted reports a fingerprint on the forge that this run did not intend" {
    printf 'aaa\n' > "$TMP/intended"
    printf 'aaa\nzzz\n' > "$TMP/actual"
    run cr_verify_posted "$TMP/intended" "$TMP/actual"
    [ "$status" -eq 1 ]
    [ "$output" = "$(printf 'extra\tzzz')" ]
}

@test "cr_verify_posted reports missing and extra together" {
    printf 'aaa\nbbb\n' > "$TMP/intended"
    printf 'aaa\nzzz\n' > "$TMP/actual"
    run cr_verify_posted "$TMP/intended" "$TMP/actual"
    [ "$status" -eq 1 ]
    [[ "$output" == *"missing"*"bbb"* ]]
    [[ "$output" == *"extra"*"zzz"* ]]
}

@test "cr_verify_posted flags every intended comment when nothing was posted at all" {
    # The whole-delivery failure: the run believed it posted, the forge has nothing.
    printf 'aaa\nbbb\n' > "$TMP/intended"
    : > "$TMP/actual"
    run cr_verify_posted "$TMP/intended" "$TMP/actual"
    [ "$status" -eq 1 ]
    [ "$(printf '%s\n' "$output" | grep -c '^missing')" -eq 2 ]
}

@test "cr_verify_posted succeeds when nothing was intended and nothing was posted" {
    : > "$TMP/intended"
    : > "$TMP/actual"
    run cr_verify_posted "$TMP/intended" "$TMP/actual"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "cr_verify_posted matches files that lack a trailing newline" {
    printf 'aaa' > "$TMP/intended"
    printf 'aaa' > "$TMP/actual"
    run cr_verify_posted "$TMP/intended" "$TMP/actual"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "cr_verify_posted returns 2 when an input file is unreadable" {
    printf 'aaa\n' > "$TMP/intended"
    run cr_verify_posted "$TMP/intended" "$TMP/does-not-exist"
    [ "$status" -eq 2 ]
}

@test "cr_verify_posted behaves identically under zsh" {
    # lib/cr-helpers.sh must not rely on IFS word-splitting: zsh does not split unquoted
    # parameters, so a splitting implementation emits one blob here and N rows under bash.
    if ! command -v zsh >/dev/null 2>&1; then
        skip "zsh not installed"
    fi
    printf 'aaa\nbbb\nccc\n' > "$TMP/intended"
    printf 'aaa\n' > "$TMP/actual"
    run zsh -c "source '$REPO_ROOT/lib/cr-helpers.sh'; cr_verify_posted '$TMP/intended' '$TMP/actual'"
    [ "$status" -eq 1 ]
    [ "$(printf '%s\n' "$output" | grep -c '^missing')" -eq 2 ]
}
