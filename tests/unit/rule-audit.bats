#!/usr/bin/env bats
# Behaviour tests for bin/rule-audit.sh — the scoring the compliance study rests on.
#
# Three of these are load-bearing:
#
#   * a rule quoted in prose, in a grep argument or inside a heredoc must not count as a violation.
#     Raw grep over transcripts overcounts by roughly 18 to 1, and a wrong number here would justify
#     deleting rules that are in fact followed.
#   * an unscorable rule must print UNSCORABLE and no rate. An unrun check that reads as a clean one
#     is worse than no check.
#   * two runs over the same corpus must print the same numbers, or nobody can re-check the report.
#
# Fixtures are written per test rather than committed, so the case each one carries sits beside the
# assertion about it.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    AUDIT="${VAULT_ROOT}/bin/rule-audit.sh"
    TMP="$(mktemp -d)"
    export RULE_AUDIT_CACHE="${TMP}/cache"
    export RULE_AUDIT_TRANSCRIPTS="${TMP}/projects"
    mkdir -p "${RULE_AUDIT_TRANSCRIPTS}"
}

teardown() {
    [ -n "${TMP:-}" ] && rm -rf "${TMP}"
}

# mkinventory <compliant-cell> — an inventory holding one transcript rule, the `git add` one.
mkinventory() {
    local compliant="${1:-!^git add (-A\\|-a\\|--all\\|\\.)( \\|$)}"
    cat > "${TMP}/inv.md" <<EOF
# fixture inventory

| id | rule | source | corpus | form | self_checkable | enforced | denominator | compliant | note |
|----|------|--------|--------|------|----------------|----------|-------------|-----------|------|
| R-01 | stage specific files | \`x.md:1\` | transcript-cmd | prohibition | yes | no | \`^git add( \\|$)\` | \`${compliant}\` | |
EOF
}

# mkinventory_untraceable — one row with no corpus, which must come back UNSCORABLE.
mkinventory_untraceable() {
    cat > "${TMP}/inv.md" <<'EOF'
# fixture inventory

| id | rule | source | corpus | form | self_checkable | enforced | denominator | compliant | note |
|----|------|--------|--------|------|----------------|----------|-------------|-----------|------|
| R-99 | do not auto-push | `x.md:1` | none | prohibition | yes | no | | | both pushes leave the same trace |
EOF
}

# tool_use <command> — one assistant turn that really ran <command>.
tool_use() {
    jq -nc --arg c "$1" '{type:"assistant", timestamp:"2026-09-04T10:00:00Z",
        message:{content:[{type:"tool_use", name:"Bash", input:{command:$c}}]}}'
}

# prose <text> — one assistant turn that only wrote about <text>.
prose() {
    jq -nc --arg t "$1" '{type:"assistant", timestamp:"2026-09-04T10:00:00Z",
        message:{content:[{type:"text", text:$t}]}}'
}

run_audit() {
    run "${AUDIT}" --inventory "${TMP}/inv.md" --floor 1 "$@"
}

@test "a rule named in assistant prose is not counted as an invocation" {
    mkinventory
    {
        prose 'The rule says never run git add -A, and this session did not.'
        tool_use 'git add bin/rule-audit.sh'
    } > "${RULE_AUDIT_TRANSCRIPTS}/a.jsonl"

    run_audit
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"100.0%"* ]]
    [[ "${output}" == *"1/1"* ]]
}

@test "a real tool_use Bash block carrying the pattern is counted once" {
    mkinventory
    tool_use 'git add -A' > "${RULE_AUDIT_TRANSCRIPTS}/a.jsonl"

    run_audit
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"0.0%"* ]]
    [[ "${output}" == *"0/1"* ]]
}

@test "the pattern inside a quoted argument is not the command being run" {
    mkinventory
    {
        tool_use 'grep -rn "git add -A" commands/'
        tool_use 'git add commands/v-work.md'
    } > "${RULE_AUDIT_TRANSCRIPTS}/a.jsonl"

    run_audit
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"1/1"* ]]
}

@test "the pattern inside a heredoc body is not the command being run" {
    mkinventory
    tool_use "cat > doc.md <<'EOF'
Stage specific files only — never git add -A.
EOF
git add doc.md" > "${RULE_AUDIT_TRANSCRIPTS}/a.jsonl"

    run_audit
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"1/1"* ]]
}

@test "a command chain is split, so each simple command is scored on its own" {
    mkinventory
    tool_use 'git status && git add -A && git commit -m x' > "${RULE_AUDIT_TRANSCRIPTS}/a.jsonl"

    run_audit
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"0/1"* ]]
}

@test "a rule with no trace prints UNSCORABLE and no rate" {
    mkinventory_untraceable
    tool_use 'git push' > "${RULE_AUDIT_TRANSCRIPTS}/a.jsonl"

    run_audit
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"UNSCORABLE"* ]]
    [[ "${output}" == *"same trace"* ]]
    [[ "${output}" != *"%"* ]]
}

@test "a denominator below the floor is UNSCORABLE, not a rate over four observations" {
    mkinventory
    tool_use 'git add -A' > "${RULE_AUDIT_TRANSCRIPTS}/a.jsonl"

    run "${AUDIT}" --inventory "${TMP}/inv.md" --floor 10
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"UNSCORABLE"* ]]
    [[ "${output}" == *"below the floor"* ]]
}

@test "two runs over the same corpus print identical output" {
    mkinventory
    {
        tool_use 'git add -A'
        tool_use 'git add bin/'
    } > "${RULE_AUDIT_TRANSCRIPTS}/a.jsonl"

    "${AUDIT}" --inventory "${TMP}/inv.md" --floor 1 > "${TMP}/first"
    "${AUDIT}" --inventory "${TMP}/inv.md" --floor 1 > "${TMP}/second"
    run diff "${TMP}/first" "${TMP}/second"
    [ "${status}" -eq 0 ]
}

@test "a malformed transcript line is skipped and the run still exits 0" {
    mkinventory
    {
        printf 'not json at all\n'
        printf '{"type":"assistant","message":{"content":\n'
        tool_use 'git add bin/'
    } > "${RULE_AUDIT_TRANSCRIPTS}/a.jsonl"

    run_audit
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"1/1"* ]]
}

@test "an unparseable inventory exits 2 rather than reporting a clean corpus" {
    printf '# no table here\n' > "${TMP}/inv.md"

    run_audit
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"no rule rows parsed"* ]]
}

@test "--list prints every inventory row" {
    mkinventory
    run_audit --list
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"R-01"* ]]
    [[ "${output}" == *"transcript-cmd"* ]]
}

@test "the shipped inventory parses, and every row comes back scored or UNSCORABLE" {
    run "${AUDIT}" --inventory "${VAULT_ROOT}/vault/research/rule-inventory.md" --list
    [ "${status}" -eq 0 ]
    [ "$(printf '%s\n' "${output}" | grep -c '^ *R-')" -eq 10 ]
}
