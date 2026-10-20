#!/usr/bin/env bats
# Tests for the agent skills (skills/agent-*/SKILL.md) and their links from the planning lens
# personas/_shared/planning/agent-systems.md. Fail fixtures live in tests/fixtures/agent-skills/.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    LENS="${VAULT_ROOT}/personas/_shared/planning/agent-systems.md"
    FX="${VAULT_ROOT}/tests/fixtures/agent-skills"
    SKILLS="agent-shape agent-trust-boundaries agent-tools-mcp agent-output-validation agent-knowledge-context agent-evals agent-self-improvement agent-runtime-ops"
}

# check_skill <SKILL.md> <expected name> — exit 1 with a reason on any broken contract.
check_skill() {
    local f="$1" want="$2" name desc
    [ -f "${f}" ] || { echo "missing: ${f}"; return 1; }
    [ "$(sed -n 1p "${f}")" = "---" ] || { echo "${f}: no frontmatter"; return 1; }
    name="$(sed -n '2,/^---$/p' "${f}" | sed -n 's/^name: *//p' | head -1)"
    [ "${name}" = "${want}" ] || { echo "${f}: name '${name}' is not '${want}'"; return 1; }
    desc="$(sed -n '2,/^---$/p' "${f}" | sed -n 's/^description: *//p' | head -1)"
    [ -n "${desc}" ] || { echo "${f}: no description"; return 1; }
    [ "${#desc}" -le 300 ] || { echo "${f}: description is ${#desc} characters"; return 1; }
    [ "$(wc -l < "${f}")" -le 160 ] || { echo "${f}: over 160 lines"; return 1; }
    [ "$(wc -c < "${f}")" -le 12000 ] || { echo "${f}: over 12000 bytes"; return 1; }
}

# check_links <lens> <root> — each checklist item is followed by exactly one existing skill path.
check_links() {
    local lens="$1" root="$2" items next path
    items="$(grep -c '^- \[ \]' "${lens}")"
    [ "${items}" -gt 0 ] || { echo "${lens}: no checklist"; return 1; }
    while IFS= read -r n; do
        next="$(sed -n "$((n + 1))p" "${lens}")"
        path="$(printf '%s' "${next}" | sed -nE 's#^[[:space:]]+skill: (skills/agent-[a-z-]+/SKILL\.md) · https?://.*#\1#p')"
        [ -n "${path}" ] || { echo "${lens}:${n}: item has no skill line"; return 1; }
        [ -f "${root}/${path}" ] || { echo "${lens}:${n}: ${path} does not exist"; return 1; }
    done < <(grep -n '^- \[ \]' "${lens}" | cut -d: -f1)
}

@test "every agent skill has a matching name, a short description and stays under its caps" {
    for s in ${SKILLS}; do check_skill "${VAULT_ROOT}/skills/${s}/SKILL.md" "${s}"; done
}

@test "the skills folder holds only the listed agent skills" {
    for d in "${VAULT_ROOT}"/skills/agent-*/; do
        s="$(basename "${d}")"
        [[ " ${SKILLS} " == *" ${s} "* ]] || { echo "unlisted skill: ${s}"; return 1; }
    done
}

@test "every lens checklist item names exactly one existing skill" {
    check_links "${LENS}" "${VAULT_ROOT}"
}

@test "every agent skill is named by the lens" {
    for s in ${SKILLS}; do
        grep -q "skill: skills/${s}/SKILL.md" "${LENS}" || { echo "lens never names ${s}"; return 1; }
    done
}

@test "skill fixtures with a broken contract fail" {
    run check_skill "${FX}/bad-name/SKILL.md" bad-name
    [ "$status" -eq 1 ]
    run check_skill "${FX}/no-description/SKILL.md" no-description
    [ "$status" -eq 1 ]
    run check_skill "${FX}/too-long/SKILL.md" too-long
    [ "$status" -eq 1 ]
    run check_skill "${FX}/oversize/SKILL.md" oversize
    [ "$status" -eq 1 ]
    run check_skill "${FX}/long-description/SKILL.md" long-description
    [ "$status" -eq 1 ]
}

@test "a checklist item with no skill line, or a dangling skill path, fails" {
    run check_links "${FX}/lens-no-skill.md" "${VAULT_ROOT}"
    [ "$status" -eq 1 ]
    run check_links "${FX}/lens-dangling.md" "${VAULT_ROOT}"
    [ "$status" -eq 1 ]
}
