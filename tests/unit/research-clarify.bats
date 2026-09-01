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

@test "PROPOSE output contract is two-layer: decision to the user, design to the artifact" {
    # Layer 1 — what the user reads.
    grep -qi 'Recommendation:' "${PROPOSE}"
    grep -qi 'Assumed:'        "${PROPOSE}"
    grep -qi 'Open:'           "${PROPOSE}"
    # Layer 2 — research and the design live in the artifact, not the terminal.
    grep -qi 'to the plan artifact'          "${PROPOSE}"
    grep -qi 'Research sources'              "${PROPOSE}"
    # The gate's own front-matter is still reachable from the clarify gate.
    grep -q  '3a.0a'                         "${PROPOSE}"
}

@test "PROPOSE user layer always carries Impact — no approving an unstated blast radius" {
    grep -qi 'Impact:' "${PROPOSE}"
    grep -qi 'migrations' "${PROPOSE}"
    grep -qi 'coupled projects' "${PROPOSE}"
    grep -qi 'never ask for approval without' "${PROPOSE}"
}

@test "PROPOSE omit-when-empty rule cuts green but never amber" {
    grep -qi 'omit any line with nothing to say\|omit when' "${PROPOSE}"
    grep -qi 'cuts good news, never warnings'    "${PROPOSE}"
    # the four exception notes must survive the omit rule
    grep -qi 'research: unavailable'      "${PROPOSE}"
    grep -qi 'safe-default'               "${PROPOSE}"
    grep -qi 'open blocker'               "${PROPOSE}"
}

@test "clarify gate has an ask-gate that decides WHETHER to ask, not just how" {
    grep -qi 'ask gate\|whether to ask'                  "${PROPOSE}"
    grep -qi 'changes what actually gets built'          "${PROPOSE}"
    # naming each option's consequence is the precondition for asking at all
    grep -qi 'cannot name the consequence'               "${PROPOSE}"
    # question shape
    grep -qi 'two to four options'                       "${PROPOSE}"
    grep -qi 'recommended option first'                  "${PROPOSE}"
    # tolerant of line wrapping in the prose
    tr '\n' ' ' < "${PROPOSE}" | grep -qi 'confident wrong *answer'
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

@test "v-team PROPOSE output contract is two-layer and translates panel vocabulary" {
    grep -qi 'two layers'                    "${PROPOSE_LOOP}"
    grep -qi 'to the plan artifact'          "${PROPOSE_LOOP}"
    tr '\n' ' ' < "${PROPOSE_LOOP}" | grep -qi 'research *sources'
    # the panel's internal vocabulary must never reach the user verbatim
    grep -qi 'translate, never transcribe'   "${PROPOSE_LOOP}"
    # capped convergence + minority flags are exceptions and always surface
    grep -qi 'capped with N open blockers'   "${PROPOSE_LOOP}"
    grep -qi 'minority flag'                 "${PROPOSE_LOOP}"
}

@test "v-team synthesizer caps what reaches the user (the only subagent-text control)" {
    grep -qi 'Cap what reaches the user'     "${PROPOSE_LOOP}"
    # the documented reason this control has to live here
    grep -qi 'does .*not.* reach spawned subagents\|not.*reach spawned subagents' "${PROPOSE_LOOP}"
    # critic free-text is user-facing prose when surfaced
    grep -qi 'free-text'                     "${PROPOSE_LOOP}"
    grep -q  '_shared/communication.md'      "${PROPOSE_LOOP}"
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

@test "v-pm runs research by default while v-work and v-team keep the novel-only gate" {
    PM="${VAULT_ROOT}/commands/v-pm.md"
    grep -qi 'by default'   "${PM}"
    grep -qi 'no-research'  "${PM}"
    # the panel step must agree with the dispatcher, and must not still call it "soft"
    PANEL="${VAULT_ROOT}/commands/v-pm/steps/03-plan-panel.md"
    grep -qi 'by default'   "${PANEL}"
    ! grep -qi 'soft — the AI decides' "${PANEL}"
    # the shared gate is unchanged for the execution lifecycles
    grep -qi 'novel'        "${VAULT_ROOT}/commands/v-work/steps/03-propose.md"
}
