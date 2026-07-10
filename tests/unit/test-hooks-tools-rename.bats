#!/usr/bin/env bats
# Doc-consistency contracts for lifecycle hooks, per-project tools, and session-rename.
# The features are markdown honored by the model — not runtime-testable — so these guard the
# documented contract against drift (grep-only; no agent behavior asserted).

load "../helpers/setup.bash"

setup() {
    make_test_home
}

teardown() {
    cleanup_test_home
}

# arch-t1 — vault-guide §1.1 documents the hooks + tools sections and the failure-mode rules.
@test "vault-guide documents hooks + tools sections and the phase/precedence contract" {
    local f="${VAULT_ROOT}/vault-guide.md"
    [ -f "${f}" ]
    grep -q '| `hooks` |' "${f}"
    grep -q '| `tools` |' "${f}"
    grep -qi 'Lifecycle hooks' "${f}"
    # bookends + a representative pre_/post_ pair
    grep -q 'on_start'  "${f}"
    grep -q 'on_end'    "${f}"
    grep -q 'post_commit' "${f}"
    grep -q 'pre_capture' "${f}"
    # precedence / failure-mode wording
    grep -qi 'never run as a shell command' "${f}"
    grep -qi 'never halt' "${f}"
}

# arch-t2 — drift guard: template VAULT.md and the repo VAULT.md expose the same section set.
@test "templates/VAULT.md and repo VAULT.md expose the same top-level sections" {
    local tmpl="${VAULT_ROOT}/templates/VAULT.md"
    local repo="${VAULT_ROOT}/VAULT.md"
    [ -f "${tmpl}" ] && [ -f "${repo}" ]
    local a b
    a="$(grep -oE '^## [a-z]+' "${tmpl}" | sort -u)"
    b="$(grep -oE '^## [a-z]+' "${repo}" | sort -u)"
    [ "${a}" = "${b}" ] || {
        echo "section drift between template and repo VAULT.md:"
        echo "template:"; echo "${a}"
        echo "repo:";     echo "${b}"
        return 1
    }
    # and both carry the two new sections
    echo "${a}" | grep -q '## hooks'
    echo "${a}" | grep -q '## tools'
}

# skep-t3 — 01-analyze carries the hook-load, on_start fire, and session-rename sub-step.
@test "01-analyze loads hooks, fires on_start, and suggests a /rename" {
    local f="${VAULT_ROOT}/commands/v-work/steps/01-analyze.md"
    [ -f "${f}" ]
    grep -q 'all five sections' "${f}"           # carry-forward of full config incl. hooks/tools
    grep -q '1.4b' "${f}"
    grep -q 'on_start' "${f}"
    grep -q '1.5 Suggest session rename' "${f}"
    grep -q '/rename <slug>' "${f}"
    grep -q 'suggest_rename' "${f}"
    grep -q 'post_analyze' "${f}"
}

# skep-t4 — every lifecycle step file carries its pre_/post_ honor markers.
@test "each lifecycle step honors its pre_/post_ hooks" {
    local s="${VAULT_ROOT}/commands/v-work/steps"
    grep -q 'pre_load_context'  "${s}/02-load-context.md"
    grep -q 'post_load_context' "${s}/02-load-context.md"
    grep -q 'pre_propose'  "${s}/03-propose.md"
    grep -q 'post_propose' "${s}/03-propose.md"
    grep -q 'pre_execute'  "${s}/04-execute.md"
    grep -q 'post_execute' "${s}/04-execute.md"
    grep -q 'pre_commit'   "${s}/05-commit-capture.md"
    grep -q 'post_commit'  "${s}/05-commit-capture.md"
    grep -q 'pre_capture'  "${s}/05-commit-capture.md"
    grep -q 'post_capture' "${s}/05-commit-capture.md"
    grep -q 'on_end'       "${s}/05-commit-capture.md"
    # v-team loop variants honor the same outer-boundary hooks
    grep -q 'pre_propose'  "${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
    grep -q 'pre_execute'  "${VAULT_ROOT}/commands/v-team/steps/04-execute-loop.md"
}

# skep-t7 — 02-load-context has the project-task-tracker step.
@test "02-load-context has the project task-tracker step" {
    local f="${VAULT_ROOT}/commands/v-work/steps/02-load-context.md"
    grep -q '2.3c' "${f}"
    grep -qi 'task tracker' "${f}"
    grep -q 'task_tracker_mcp' "${f}"
}

# arch-t5 — tool-playbook gains a Project tools section, framed as suggestions, no layer-rule dup.
@test "tool-playbook has a suggestion-framed Project tools section" {
    local f="${VAULT_ROOT}/tool-playbook.md"
    grep -q '## 6. Project tools' "${f}"
    grep -qi 'suggestions, not rules' "${f}"
    grep -q 'task_tracker' "${f}"
}

# skep-t6 — the dispatchers point at the hooks contract.
@test "both dispatchers point at the hooks + tools contract" {
    grep -qi 'Per-project hooks + tools' "${VAULT_ROOT}/commands/v-work.md"
    grep -qi 'Per-project hooks + tools' "${VAULT_ROOT}/commands/v-team.md"
}
