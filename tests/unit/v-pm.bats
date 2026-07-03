#!/usr/bin/env bats
# Tests for the /v-pm cross-project planning command + _features workspace templates + the
# /v-team Step 0 feature-pickup integration — file contracts only.
# (Agent-loop behavior is validated by manual dry-runs, not unit tests.)

load "../helpers/setup.bash"

setup() {
    make_test_home
    PM="${VAULT_ROOT}/commands/v-pm.md"
    STEPS="${VAULT_ROOT}/commands/v-pm/steps"
    PICKUP="${VAULT_ROOT}/commands/v-team/steps/00-feature-pickup.md"
    TPL="${VAULT_ROOT}/templates/_features"
}

teardown() {
    cleanup_test_home
}

@test "install.sh auto-symlinks the v-pm command + steps dir (glob discovery, no hand-edit)" {
    run "${VAULT_ROOT}/install.sh"
    [ "$status" -eq 0 ]
    assert_symlink_to "${HOME}/.claude/commands/v-pm.md" "${VAULT_ROOT}/commands/v-pm.md"
    assert_symlink_to "${HOME}/.claude/commands/v-pm"    "${VAULT_ROOT}/commands/v-pm"
}

@test "v-pm dispatcher has plan/reconcile/status modes and a 'when to use' bar" {
    grep -qi 'plan'                         "${PM}"
    grep -qi 'reconcile'                    "${PM}"
    grep -qi 'status'                       "${PM}"
    grep -qi 'when to use'                  "${PM}"
    grep -qi '2+ repos\|spans 2'            "${PM}"
}

@test "v-pm dispatcher has a tool health-check + fallback table and the search precedence" {
    grep -qi 'memory_health'                "${PM}"
    grep -qi 'fallback'                     "${PM}"
    grep -qi 'claude-mem'                   "${PM}"
    grep -qi 'graphify'                     "${PM}"
    grep -qi 'precedence'                   "${PM}"
}

@test "all seven v-pm step files exist (intake, load-context, plan-panel, seed, capture, reconcile, status)" {
    [ -f "${STEPS}/01-intake.md" ]
    [ -f "${STEPS}/02-load-context.md" ]
    [ -f "${STEPS}/03-plan-panel.md" ]
    [ -f "${STEPS}/04-seed-workspace.md" ]
    [ -f "${STEPS}/05-capture.md" ]
    [ -f "${STEPS}/06-reconcile.md" ]
    [ -f "${STEPS}/07-status.md" ]
}

@test "capture writes a planning-session record, extracts cross-project ADRs, and pushes to OV" {
    grep -qi 'planning-session'             "${STEPS}/05-capture.md"
    grep -qi 'sessions/'                    "${STEPS}/05-capture.md"
    grep -qi 'ADR'                          "${STEPS}/05-capture.md"
    grep -qi 'decisions/'                   "${STEPS}/05-capture.md"
    grep -qi 'memory_store'                 "${STEPS}/05-capture.md"
    grep -qi 'memory_health'                "${STEPS}/05-capture.md"
    grep -qi 'commit'                       "${STEPS}/05-capture.md"
    # cross-project ADRs land in the neutral workspace by default
    grep -qi 'neutral workspace\|_features/<feature>/decisions' "${STEPS}/05-capture.md"
}

@test "load-context is vault-first, OV-first, ACROSS every participant vault, and emits a digest" {
    grep -qi 'memory_recall\|OpenViking'    "${STEPS}/02-load-context.md"
    grep -qi 'every participant\|each participant\|participant' "${STEPS}/02-load-context.md"
    grep -qi '_global'                      "${STEPS}/02-load-context.md"
    grep -qi '_features'                    "${STEPS}/02-load-context.md"
    grep -qi 'digest'                       "${STEPS}/02-load-context.md"
    grep -qi 'fallback'                     "${STEPS}/02-load-context.md"
    # cheapest-first precedence, no source reads here
    grep -qi 'cheapest-first\|precedence'   "${STEPS}/02-load-context.md"
}

@test "intake clarify-hard-blocks and hands a single-participant feature off to /v-team" {
    grep -qi 'clarify'                      "${STEPS}/01-intake.md"
    grep -qi 'wait\|hard-block'             "${STEPS}/01-intake.md"
    grep -qi '1 participant\|single-participant' "${STEPS}/01-intake.md"
    grep -qi 'hand off\|hand-off\|/v-team'  "${STEPS}/01-intake.md"
}

@test "plan-panel is a sequential 4-critic pipeline, consumes the LOAD CONTEXT digest, borrows 03-propose-loop NOT critic-panel" {
    grep -qi 'sequential'                   "${STEPS}/03-plan-panel.md"
    grep -qi 'business'                     "${STEPS}/03-plan-panel.md"
    grep -qi 'product owner'                "${STEPS}/03-plan-panel.md"
    grep -qi 'architect'                    "${STEPS}/03-plan-panel.md"
    grep -qi 'contract'                     "${STEPS}/03-plan-panel.md"
    grep -qi 'pm_max_rounds'                "${STEPS}/03-plan-panel.md"
    grep -qi '03-propose-loop'              "${STEPS}/03-plan-panel.md"
    grep -qi 'not.*critic-panel'            "${STEPS}/03-plan-panel.md"
    # each critic reasons from the loaded vault context
    grep -qi 'LOAD CONTEXT digest\|Step 2'  "${STEPS}/03-plan-panel.md"
}

@test "seed-workspace lists the workspace entries and has NO ledger file (derived view)" {
    grep -qi 'header.md'                    "${STEPS}/04-seed-workspace.md"
    grep -qi 'generic-plan.md'              "${STEPS}/04-seed-workspace.md"
    grep -qi 'contracts.md'                 "${STEPS}/04-seed-workspace.md"
    grep -qi 'conversation/'                "${STEPS}/04-seed-workspace.md"
    grep -qi 'projects/'                    "${STEPS}/04-seed-workspace.md"
    grep -qi 'derived view\|no.*ledger'     "${STEPS}/04-seed-workspace.md"
    grep -qi 'symlink'                      "${STEPS}/04-seed-workspace.md"
}

@test "status mode is a no-write cross-feature sweep" {
    grep -qi 'sweep'                        "${STEPS}/07-status.md"
    grep -qi 'no writes\|no write'          "${STEPS}/07-status.md"
    grep -qi 'cross-feature\|every.*_features' "${STEPS}/07-status.md"
}

@test "reconcile drains to:pm threads, flags staleness, and captures at the end" {
    grep -qi 'to: pm\|→pm\|OPEN_→pm'        "${STEPS}/06-reconcile.md"
    grep -qi 'stale'                        "${STEPS}/06-reconcile.md"
    grep -qi '05-capture\|run.*CAPTURE\|Capture' "${STEPS}/06-reconcile.md"
}

@test "all six _features templates exist (incl. planning-session)" {
    [ -f "${TPL}/header.md" ]
    [ -f "${TPL}/generic-plan.md" ]
    [ -f "${TPL}/contracts.md" ]
    [ -f "${TPL}/project-shard.md" ]
    [ -f "${TPL}/THREAD.md" ]
    [ -f "${TPL}/planning-session.md" ]
}

@test "project-shard template is BMAD-self-contained with a consumed-contract section" {
    grep -qi 'self-contained'               "${TPL}/project-shard.md"
    grep -qi 'consumed contract'            "${TPL}/project-shard.md"
}

@test "THREAD template encodes state in the filename with from/to frontmatter" {
    grep -q  'OPEN_→'                       "${TPL}/THREAD.md"
    grep -qi 'ANSWERED_'                    "${TPL}/THREAD.md"
    grep -qi 'RESOLVED'                     "${TPL}/THREAD.md"
    grep -qi '^from:'                       "${TPL}/THREAD.md"
    grep -qi '^to:'                         "${TPL}/THREAD.md"
}

@test "v-team Step 0 feature-pickup exists, is wired in the dispatcher, and does a DETERMINISTIC drift check" {
    [ -f "${PICKUP}" ]
    grep -qi 'feature-pickup\|Step 0'       "${VAULT_ROOT}/commands/v-team.md"
    grep -q  'OPEN_→'                        "${PICKUP}"
    grep -qi 'deterministic'                 "${PICKUP}"
    grep -qi 'drift'                         "${PICKUP}"
    grep -qi 'warn loudly'                   "${PICKUP}"
}

@test "feature-pickup lives in v-team, NOT leaked into shared v-work load-context" {
    ! grep -qi '_features\|feature-pickup' "${VAULT_ROOT}/commands/v-work/steps/02-load-context.md"
}

@test "vault-guide documents the _features workspace (§13) and README carries a one-line entry" {
    grep -qi '## 13'                        "${VAULT_ROOT}/vault-guide.md"
    grep -qi '_features'                     "${VAULT_ROOT}/vault-guide.md"
    grep -qi 'derived view'                  "${VAULT_ROOT}/vault-guide.md"
    grep -qi 'latency contract'              "${VAULT_ROOT}/vault-guide.md"
    grep -q  '/v-pm'                         "${VAULT_ROOT}/README.md"
    grep -q  'v-pm.md'                       "${VAULT_ROOT}/commands/README.md"
}

@test "vault.gitignore ignores the feature workspace symlinks" {
    grep -qi 'features/\*/\|_features'      "${VAULT_ROOT}/templates/vault.gitignore"
}
