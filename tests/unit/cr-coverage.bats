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

# --- cr_coverage ------------------------------------------------------------
#
# The review-side read-back. `files_entered_context` was a capture field with no function behind
# it, so it got asserted: one run recorded 33 against a true 41 of 48, and the seven files nobody
# had read held two real findings. These cases exist so the number cannot be invented again.

# Helper: three input files in the shapes cr_coverage reads.
cov_fixture() {
    printf 'a.php\t10\t2\nb.php\t5\t3\nc.php\t1\t1\n' > "$TMP/changed"
    printf 'read\tL12:"foo"\ta.php\nread\tchecked the null path\tb.php\nread\tL3:"x"\tc.php\n' > "$TMP/receipt"
    printf 'a.php\n' > "$TMP/findings"
}

@test "cr_coverage counts the three buckets separately" {
    cov_fixture
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep '^with_findings')" = "$(printf 'with_findings\t1')" ]
    [ "$(printf '%s\n' "$output" | grep '^clean')" = "$(printf 'clean\t2')" ]
    [ "$(printf '%s\n' "$output" | grep "^$(printf 'unexamined\t0')$")" = "$(printf 'unexamined\t0')" ]
}

@test "cr_coverage names every changed file no critic read" {
    cov_fixture
    # c.php was only grepped — a grep is not a read.
    printf 'read\tL12:"foo"\ta.php\nread\tchecked\tb.php\ngrep-only\tsearched for the trait\tc.php\n' > "$TMP/receipt"
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 1 ]
    [ "$(printf '%s\n' "$output" | grep -c '^unexamined')" -eq 2 ]   # the count row + the path row
    printf '%s\n' "$output" | grep -q "$(printf 'unexamined\tc.php')"
}

@test "cr_coverage treats diff-only and skipped as not examined" {
    cov_fixture
    printf 'diff-only\tsaw the hunk\ta.php\nskipped\tran out of budget\tb.php\nread\tL3:"x"\tc.php\n' > "$TMP/receipt"
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 1 ]
    [ "$(printf '%s\n' "$output" | grep "^$(printf 'unexamined\t2')$")" = "$(printf 'unexamined\t2')" ]
}

@test "cr_coverage reports a receipt path outside the changeset as extra" {
    cov_fixture
    printf 'read\tL1:"a"\ta.php\nread\tx\tb.php\nread\tx\tc.php\nread\tx\tstray.php\n' > "$TMP/receipt"
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 1 ]
    printf '%s\n' "$output" | grep -q "$(printf 'extra\tstray.php')"
}

@test "cr_coverage exempts a context row from the extra check" {
    # A subject-under-test read from outside the changeset is deliberate, not a stray path.
    cov_fixture
    printf 'read\tL1:"a"\ta.php\nread\tx\tb.php\nread\tx\tc.php\ncontext\tsubject under test\tsrc/Sub.php\n' > "$TMP/receipt"
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 0 ]
    # `! grep` is exempt from set -e and can never fail a test — assert on the count instead.
    [ "$(printf '%s\n' "$output" | grep -c '^extra')" -eq 0 ]
}

@test "cr_coverage counts a receipt path containing a tab" {
    # The reason is variable-length, so the path is the LAST field. Getting this backwards drops
    # the file and reports it unexamined forever.
    printf 'weird\tname.php\t3\t1\n' > "$TMP/changed"
    printf 'read\twhy it is clean\tweird\tname.php\n' > "$TMP/receipt"
    : > "$TMP/findings"
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep '^clean')" = "$(printf 'clean\t1')" ]
}

@test "cr_coverage counts CRLF receipt rows instead of reporting everything unread" {
    # A trailing \r makes every path mismatch, so the gate reports 100% unexamined on every run
    # and gets switched off as noise. Same class as the cr_diff_stats CRLF case above.
    printf 'a.php\t10\t2\n' > "$TMP/changed"
    printf 'read\tL1:"x"\ta.php\r\n' > "$TMP/receipt"
    : > "$TMP/findings"
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep "^$(printf 'unexamined\t0')$")" = "$(printf 'unexamined\t0')" ]
}

@test "cr_coverage resolves duplicate paths strongest-evidence-wins" {
    printf 'a.php\t10\t2\n' > "$TMP/changed"
    printf 'skipped\tno budget\ta.php\nread\tL9:"token"\ta.php\n' > "$TMP/receipt"
    : > "$TMP/findings"
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep '^clean')" = "$(printf 'clean\t1')" ]
}

@test "cr_coverage returns zero for an empty changeset and flags an empty receipt" {
    : > "$TMP/changed"; : > "$TMP/receipt"; : > "$TMP/findings"
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 0 ]

    # A real changeset with nothing examined must be rc 1, one row per file — never a silent pass.
    printf 'a.php\t1\t1\nb.php\t1\t1\n' > "$TMP/changed"
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 1 ]
    [ "$(printf '%s\n' "$output" | grep "^$(printf 'unexamined\t2')$")" = "$(printf 'unexamined\t2')" ]
}

@test "cr_coverage does not parse receipt rows as changed files when the changeset is empty" {
    # Dispatching on a first-line counter breaks here: an empty file never fires FNR==1, so every
    # receipt row would be read as a changed file and the run would report perfect coverage.
    : > "$TMP/changed"
    printf 'read\tL1:"x"\ta.php\n' > "$TMP/receipt"
    : > "$TMP/findings"
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 1 ]
    [ "$(printf '%s\n' "$output" | grep '^clean')" = "$(printf 'clean\t0')" ]
    printf '%s\n' "$output" | grep -q "$(printf 'extra\ta.php')"
}

@test "cr_coverage returns 2 on unreadable input, distinct from examining nothing" {
    printf 'a.php\t1\t1\n' > "$TMP/changed"
    : > "$TMP/findings"
    run cr_coverage "$TMP/changed" "$TMP/does-not-exist" "$TMP/findings"
    [ "$status" -eq 2 ]
}

@test "cr_coverage round-trips a receipt written in the documented row format" {
    # Built from critic-panel.md's own row shape rather than a hand-tuned fixture, so the schema
    # and the parser cannot drift apart while both look correct in isolation.
    printf 'app/Api/Repo.php\t40\t3\ntests/Feature/ListTest.php\t12\t0\n' > "$TMP/changed"
    {
        printf 'read\tL48:"entitlement"\tapp/Api/Repo.php\n'
        printf 'read\tasserts the 500 as expected\ttests/Feature/ListTest.php\n'
    } > "$TMP/receipt"
    printf 'app/Api/Repo.php\n' > "$TMP/findings"
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep '^with_findings')" = "$(printf 'with_findings\t1')" ]
    [ "$(printf '%s\n' "$output" | grep '^clean')" = "$(printf 'clean\t1')" ]
}

@test "cr_coverage behaves identically under zsh" {
    if ! command -v zsh >/dev/null 2>&1; then
        skip "zsh not installed"
    fi
    printf 'a.php\t1\t1\nb.php\t1\t1\n' > "$TMP/changed"
    printf 'read\tL1:"x"\ta.php\n' > "$TMP/receipt"
    : > "$TMP/findings"
    run zsh -c "source '$REPO_ROOT/lib/cr-helpers.sh'; cr_coverage '$TMP/changed' '$TMP/receipt' '$TMP/findings'"
    [ "$status" -eq 1 ]
    printf '%s\n' "$output" | grep -q "$(printf 'unexamined\tb.php')"
}

# --- the contracts these helpers are wired into -----------------------------
#
# enforced-not-just-stated: a step file naming a function is not enough — the function must exist,
# or the step states a measurement nothing can take. Both halves are asserted together here,
# because the half that shipped alone is exactly how cr_diff_stats sat uncalled for a day.

@test "the large-diff guard names cr_diff_stats AND the function exists" {
    grep -qE 'cr_diff_stats < "\$CR_CHANGED_FILES"' /code/commands/v-cr/steps/03-review.md
    grep -qE '^cr_diff_stats\(\)' /code/lib/cr-helpers.sh
}

@test "the coverage gate names cr_coverage AND the function exists" {
    # The fenced call, not the bare token: the name also appears in prose, so a token grep still
    # passes after the actual invocation is deleted.
    grep -qE '^cr_coverage "\$CR_CHANGED_FILES"' /code/commands/v-cr/steps/03-review.md
    grep -qE '^cr_coverage\(\)' /code/lib/cr-helpers.sh
}

@test "gather writes the changed-file list the two guards read" {
    grep -q 'CR_CHANGED_FILES' /code/commands/v-cr/steps/02-gather.md
    grep -q 'CR_CHANGED_FILES' /code/commands/v-cr/steps/03-review.md
}

@test "the panel schema carries FILES_EXAMINED with the path last" {
    grep -q 'FILES_EXAMINED' /code/commands/_shared/critic-panel.md
    # The path must be the LAST field: the reason is variable-length, so any other order drops a
    # path containing a tab.
    grep -q '<evidence><TAB><reason><TAB><path>' /code/commands/_shared/critic-panel.md
}

@test "a read row must carry an anchor and a clean file must say what was checked" {
    grep -qi 'anchor' /code/commands/_shared/critic-panel.md
    grep -qi 'anchor' /code/commands/v-cr/steps/03-review.md
    grep -qi 'states what was checked' /code/commands/_shared/critic-panel.md
}

@test "the two-bucket coverage wording is gone everywhere it was mandated" {
    # Superseded wording must be ABSENT, not merely supplemented — a positive grep for the new
    # sentence passes while the old one still sits three lines above it.
    #
    # Absence goes through `run`, never `! grep`: a command prefixed with `!` is exempt from
    # set -e, so `! grep -q <present string>` returns success and the assertion is decorative.
    run grep -q 'silent (no confirmed' /code/commands/v-cr/steps/03-review.md
    [ "$status" -ne 0 ]
    run grep -q 'N−M silent' /code/vault/indications/cr-panel-spawn-and-visibility.md
    [ "$status" -ne 0 ]
    grep -q 'NOT EXAMINED' /code/commands/v-cr/steps/03-review.md
}

@test "the capture block records computed coverage fields and drops the asserted one" {
    for f in files_examined files_unexamined unexamined_paths coverage_accepted; do
        grep -q "$f" /code/commands/v-cr/steps/05-capture.md
    done
    for f in /code/commands/v-cr/steps/05-capture.md \
             /code/vault/indications/cr-delivery-verification.md \
             /code/tests/unit/v-cr.bats; do
        run grep -q 'files_entered_context' "$f"
        [ "$status" -ne 0 ]
    done
}

@test "the post gate requires fresh confirmation when files went unexamined" {
    grep -qi 'unexamined set requires its own fresh confirmation' /code/commands/v-cr/steps/04-post.md
    grep -q 'coverage_accepted' /code/commands/v-cr/steps/04-post.md
}

@test "the testing critic owns every changed test file and reports its own gap count" {
    grep -qi 'owns every changed test file' /code/commands/v-cr/steps/03-review.md
    grep -qi 'unexamined test files' /code/commands/v-cr/steps/03-review.md
}

@test "critics must write their findings block to a file before reporting it" {
    # A long report is truncated in transit and FILES_EXAMINED sits at its tail, so a caller
    # holding only the visible part has no receipt at all.
    grep -qi 'writes its findings block to a file' /code/commands/_shared/critic-panel.md
}
