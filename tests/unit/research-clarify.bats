#!/usr/bin/env bats
# Contracts for the two PROPOSE front gates shared by /v-work and /v-team:
#   §3a.0a — clarify (understand-before-planning, AskUserQuestion)
#   §3a.0b — external research (ground the design, reconcile contradictions)
# File contracts only — agent-loop behavior is validated by manual dry-runs.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    PROPOSE="${VAULT_ROOT}/commands/v-work/steps/03-propose.md"
    PROPOSE_LOOP="${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
    ANALYZE="${VAULT_ROOT}/commands/v-work/steps/01-analyze.md"
    PLAYBOOK="${VAULT_ROOT}/tool-playbook.md"
}

@test "shared PROPOSE has a clarify gate (§3a.0a) that asks the user via AskUserQuestion" {
    grep -q  '3a.0a'                 "${PROPOSE}"
    grep -qi 'clarify'               "${PROPOSE}"
    grep -q  'AskUserQuestion'       "${PROPOSE}"
    grep -qi 'assumption'            "${PROPOSE}"
    # only plan-changing doubts warrant a question — not busywork
    grep -qi 'plan-changing\|would change the design' "${PROPOSE}"
}

@test "clarify gate hard-blocks on a fork with no safe default (always waits)" {
    grep -qi 'do not paper over\|don.t paper over\|paper over real ambiguity' "${PROPOSE}"
    # a plan-changing fork with no safe default HALTS until the user answers — never guessed
    grep -qi 'always waits\|halts the lifecycle\|wait for the answer' "${PROPOSE}"
    grep -qi 'unanswered fork\|never fall back to a guess' "${PROPOSE}"
    # stated safe-default assumptions are still surfaced at the approval gate
    grep -qi 'flag.*approval gate\|approval gate' "${PROPOSE}"
}

@test "shared PROPOSE has an external-research gate (§3a.0b) with the anti-hallucination framing" {
    grep -q  '3a.0b'                 "${PROPOSE}"
    grep -qi 'research'              "${PROPOSE}"
    grep -qi 'WebSearch'             "${PROPOSE}"
    # your prior is weaker than practitioners who solved it
    grep -qi 'prior is weaker\|first instinct as a hypothesis\|hypothesis to test' "${PROPOSE}"
}

@test "research gate is gated (skips trivial) and reconciles contradictions explicitly" {
    grep -qi 'skip for.*refactor\|Skip for:' "${PROPOSE}"
    # a contradicting consensus must be adopted or refuted in writing — never ignored
    grep -qi 'adopt it\|written reason'       "${PROPOSE}"
    grep -qi 'silently ignoring\|never silently' "${PROPOSE}"
    grep -qi 'cite'                           "${PROPOSE}"
}

@test "PROPOSE output contract surfaces Assumptions, Clarifications, and Research" {
    grep -qi 'Assumptions:'    "${PROPOSE}"
    grep -qi 'Clarifications:' "${PROPOSE}"
    grep -qi 'Research:'       "${PROPOSE}"
}

@test "ANALYZE seeds doubts early and routes them to the clarify gate" {
    grep -qi 'doubt'   "${ANALYZE}"
    grep -q  '3a.0a'   "${ANALYZE}"
}

@test "v-team v0 draft runs both front gates before the panel spawns" {
    grep -q  '3a.0a'                       "${PROPOSE_LOOP}"
    grep -q  '3a.0b'                       "${PROPOSE_LOOP}"
    grep -qi 'before the panel spawns'     "${PROPOSE_LOOP}"
    # unresearched design / unsound assumption is a legitimate critic finding
    grep -qi 'unresearched design'         "${PROPOSE_LOOP}"
    grep -qi 'unsound assumption'          "${PROPOSE_LOOP}"
}

@test "v-team PROPOSE output contract surfaces clarifications + research" {
    grep -qi 'Assumptions / clarifications:' "${PROPOSE_LOOP}"
    grep -qi 'Research:'                      "${PROPOSE_LOOP}"
}

@test "tool-playbook documents web research as §7 (correctness, not token-saving)" {
    grep -qE '^## 7\. Web research' "${PLAYBOOK}"
    grep -qi 'WebSearch'            "${PLAYBOOK}"
    grep -qi 'WebFetch'             "${PLAYBOOK}"
    grep -qi 'deep-research'        "${PLAYBOOK}"
    grep -qi 'hypothesis'           "${PLAYBOOK}"
}

@test "both dispatchers advertise the clarify + research front gates" {
    grep -qi 'clarify'  "${VAULT_ROOT}/commands/v-work.md"
    grep -qi 'research' "${VAULT_ROOT}/commands/v-work.md"
    grep -qi 'clarify'  "${VAULT_ROOT}/commands/v-team.md"
    grep -qi 'research' "${VAULT_ROOT}/commands/v-team.md"
}
