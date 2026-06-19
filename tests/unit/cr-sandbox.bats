#!/usr/bin/env bats
# Tests for lib/cr-sandbox.sh — the PURE core of /v-cr's optional --sandbox path.
# Guards the data-loss teardown guard (arch-t2 / sec-t3), the isolation-envelope carve-out (sec-t2),
# recipe precedence (arch-t3 / skeptic-t1), and runtime-output redaction (sec-t1).

setup() {
    source /code/lib/cr-sandbox.sh
    export VCR_SANDBOX_ROOT=/tmp/vcr-test-root
}

# --- cr_sandbox_root ---------------------------------------------------------

@test "cr_sandbox_root honours VCR_SANDBOX_ROOT" {
    run cr_sandbox_root
    [ "$status" -eq 0 ]
    [ "$output" = "/tmp/vcr-test-root" ]
}

@test "cr_sandbox_root defaults under the temp tree when unset" {
    unset VCR_SANDBOX_ROOT
    run cr_sandbox_root
    [ "$status" -eq 0 ]
    [[ "$output" == */v-cr-sandbox ]]
}

# --- cr_sandbox_name ---------------------------------------------------------

@test "cr_sandbox_name is deterministic for the same inputs" {
    a="$(cr_sandbox_name github.com acme web 42 abcdef1234567890 111)"
    b="$(cr_sandbox_name github.com acme web 42 abcdef1234567890 111)"
    [ "$a" = "$b" ]
    [ "$a" = "vcr-github-com-acme-web-pr42-abcdef12-111" ]
}

@test "cr_sandbox_name varies by nonce so concurrent runs do not collide" {
    a="$(cr_sandbox_name github.com acme web 42 abcdef1234567890 111)"
    b="$(cr_sandbox_name github.com acme web 42 abcdef1234567890 222)"
    [ "$a" != "$b" ]
}

@test "cr_sandbox_name sanitises unsafe characters in identity" {
    run cr_sandbox_name "git.ACME.com" "My/Org" "re po" 7 DEADBEEFcafe 9
    [ "$status" -eq 0 ]
    [ "$output" = "vcr-git-acme-com-my-org-re-po-pr7-deadbeef-9" ]
}

# --- cr_sandbox_path_is_safe (the data-loss guard) ---------------------------

@test "path_is_safe accepts a well-formed sandbox path" {
    run cr_sandbox_path_is_safe "/tmp/vcr-test-root/vcr-github-com-acme-web-pr42-abcdef12-111"
    [ "$status" -eq 0 ]
}

@test "path_is_safe rejects an empty/unset path" {
    run cr_sandbox_path_is_safe ""
    [ "$status" -ne 0 ]
    run cr_sandbox_path_is_safe
    [ "$status" -ne 0 ]
}

@test "path_is_safe rejects the filesystem root" {
    run cr_sandbox_path_is_safe "/"
    [ "$status" -ne 0 ]
}

@test "path_is_safe rejects HOME" {
    HOME=/home/someone run cr_sandbox_path_is_safe "/home/someone"
    [ "$status" -ne 0 ]
}

@test "path_is_safe rejects the sandbox root itself (only children)" {
    run cr_sandbox_path_is_safe "/tmp/vcr-test-root"
    [ "$status" -ne 0 ]
}

@test "path_is_safe rejects a child whose leaf lacks the vcr- prefix" {
    run cr_sandbox_path_is_safe "/tmp/vcr-test-root/not-a-sandbox"
    [ "$status" -ne 0 ]
}

@test "path_is_safe rejects a path outside the sandbox root" {
    run cr_sandbox_path_is_safe "/etc/vcr-github-com-acme-web-pr42-abcdef12-111"
    [ "$status" -ne 0 ]
}

@test "path_is_safe rejects path traversal" {
    run cr_sandbox_path_is_safe "/tmp/vcr-test-root/../vcr-evil"
    [ "$status" -ne 0 ]
}

@test "path_is_safe rejects a path nested deeper than a direct child (corr-d1)" {
    # only the leaf was prefix-checked before — a deep path with a vcr- leaf must NOT pass
    run cr_sandbox_path_is_safe "/tmp/vcr-test-root/realdir/vcr-fake"
    [ "$status" -ne 0 ]
}

@test "path_is_safe rejects a double-separator path (corr-d3)" {
    run cr_sandbox_path_is_safe "/tmp/vcr-test-root//vcr-x"
    [ "$status" -ne 0 ]
}

# --- cr_is_envelope_key (sec-2 carve-out) ------------------------------------

@test "is_envelope_key flags isolation-boundary keys (must never come from repo/indication)" {
    for k in network network_mode cap_add privileged cpus memory pids_limit volumes environment http_proxy registry; do
        run cr_is_envelope_key "$k"
        [ "$status" -eq 0 ]
    done
}

@test "is_envelope_key allows benign project recipe keys" {
    for k in install test lint ports build image; do
        run cr_is_envelope_key "$k"
        [ "$status" -ne 0 ]
    done
}

# --- cr_recipe_resolve (precedence) ------------------------------------------

@test "recipe_resolve prefers a project indication over all others" {
    run cr_recipe_resolve "IND" "VAULT" "REPO" "DEF"
    [ "$status" -eq 0 ]
    [ "$output" = "indication	IND" ]
}

@test "recipe_resolve falls through indication -> vault -> repo -> stack-default" {
    run cr_recipe_resolve "" "VAULT" "REPO" "DEF"
    [ "$output" = "vault	VAULT" ]
    run cr_recipe_resolve "" "" "REPO" "DEF"
    [ "$output" = "repo	REPO" ]
    run cr_recipe_resolve "" "" "" "DEF"
    [ "$output" = "stack-default	DEF" ]
}

@test "recipe_resolve fails when every source is absent" {
    run cr_recipe_resolve "" "" "" ""
    [ "$status" -ne 0 ]
}

# --- cr_stack_default_recipe -------------------------------------------------

@test "stack_default_recipe returns a 4-field recipe for a known stack" {
    run cr_stack_default_recipe node
    [ "$status" -eq 0 ]
    [ "$(printf '%s' "$output" | awk -F'\t' '{print NF}')" -eq 4 ]
}

@test "stack_default_recipe install command disables lifecycle scripts (sec-4)" {
    run cr_stack_default_recipe node
    [[ "$output" == *"--ignore-scripts"* ]]
    run cr_stack_default_recipe php
    [[ "$output" == *"--no-scripts"* ]]
}

@test "stack_default_recipe fails for an unknown stack" {
    run cr_stack_default_recipe brainfuck
    [ "$status" -ne 0 ]
}

# --- cr_redact_runtime (sec-1) -----------------------------------------------

@test "redact_runtime scrubs a github token shape from runtime output" {
    run bash -c 'source /code/lib/cr-sandbox.sh; printf "out: ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ012345\n" | cr_redact_runtime'
    [ "$status" -eq 0 ]
    [[ "$output" == *"[REDACTED]"* ]]
    [[ "$output" != *"ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ012345"* ]]
}

@test "redact_runtime scrubs a known host-env value via CR_REDACT_VALUES" {
    run bash -c 'source /code/lib/cr-sandbox.sh; export CR_REDACT_VALUES="s3cr3t-host-value"; printf "DB_PASSWORD=s3cr3t-host-value\n" | cr_redact_runtime'
    [ "$status" -eq 0 ]
    [[ "$output" != *"s3cr3t-host-value"* ]]
    [[ "$output" == *"[REDACTED]"* ]]
}

@test "redact_runtime leaves ordinary output intact" {
    run bash -c 'source /code/lib/cr-sandbox.sh; printf "12 tests passed, 0 failed\n" | cr_redact_runtime'
    [ "$status" -eq 0 ]
    [ "$output" = "12 tests passed, 0 failed" ]
}

@test "redact_runtime treats CR_REDACT_VALUES as a LITERAL (glob/regex chars; corr-t4)" {
    run bash -c 'source /code/lib/cr-sandbox.sh; export CR_REDACT_VALUES="a*b"; printf "x=a*b and axb stays\n" | cr_redact_runtime'
    [ "$status" -eq 0 ]
    [[ "$output" != *"a*b"* ]]          # the literal secret is gone
    [[ "$output" == *"axb stays"* ]]    # a glob-expansion of it is NOT redacted
    [[ "$output" == *"[REDACTED]"* ]]
}

@test "redact_runtime does not hang on empty or newline-only CR_REDACT_VALUES (corr-t6, the fixed loop class)" {
    run bash -c 'source /code/lib/cr-sandbox.sh; export CR_REDACT_VALUES=""; printf "ok\n" | cr_redact_runtime'
    [ "$status" -eq 0 ]
    run bash -c 'source /code/lib/cr-sandbox.sh; export CR_REDACT_VALUES="$(printf "\n\n")"; printf "ok\n" | cr_redact_runtime'
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "redact_runtime normalises to a single trailing newline (corr-d2 contract pin)" {
    run bash -c 'source /code/lib/cr-sandbox.sh; printf "a\nb\n\n\n" | cr_redact_runtime | wc -l'
    [ "$status" -eq 0 ]
    [ "$output" = "2" ]                  # a, b — trailing blank lines collapsed, by documented contract
}
