#!/usr/bin/env bats
# Tests for the business persona family (personas/{sales,seo,support,business,startup-eval}.md +
# personas/_shared/business/) — file contracts, resolution wiring, decorrelation guards.
# Selection behavior (multi-pack seating under the cap) is validated by manual dry-runs, not unit tests.

load "../helpers/setup.bash"

setup() {
    # Read-only file-contract tests; no isolated HOME needed, just the repo root.
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    BUSINESS_DIR="${VAULT_ROOT}/personas/_shared/business"
    RESOLUTION="${VAULT_ROOT}/personas/_resolution.md"
    BUSINESS_PACKS="sales seo support business startup-eval"
}

# --- pack file contracts (t1) ---

@test "all five business packs exist with valid pack frontmatter" {
    for p in ${BUSINESS_PACKS}; do
        local f="${VAULT_ROOT}/personas/${p}.md"
        [ -f "${f}" ] || { echo "missing pack: ${f}"; return 1; }
        grep -qE '^type: persona-pack$'      "${f}"
        grep -qE "^pack: ${p}$"              "${f}"
        grep -qE "^project_type: ${p}$"      "${f}"
        grep -qE '^use_shared: \[skeptic, business/data-evidence\]$' "${f}"
    done
}

@test "every business pack declares at least one stack-local persona with the full block shape" {
    for p in ${BUSINESS_PACKS}; do
        local f="${VAULT_ROOT}/personas/${p}.md"
        grep -qE '^## Persona: .+ \(base_agent: [a-z-]+\)$' "${f}" || { echo "${p}: no persona header"; return 1; }
        grep -q '\*\*analyzer:\*\*'  "${f}"
        grep -q '\*\*mandate:\*\*'   "${f}"
        grep -q '\*\*severity:\*\*'  "${f}"
        grep -q '\*\*checklist:\*\*' "${f}"
    done
}

@test "business group dir exists: data-evidence persona + README with group frontmatter" {
    [ -d "${BUSINESS_DIR}" ]
    [ -f "${BUSINESS_DIR}/data-evidence.md" ]
    grep -qE '^type: persona$'        "${BUSINESS_DIR}/data-evidence.md"
    grep -qE '^id: data-evidence$'    "${BUSINESS_DIR}/data-evidence.md"
    grep -qE '^base_agent: '          "${BUSINESS_DIR}/data-evidence.md"
    [ -f "${BUSINESS_DIR}/README.md" ]
    grep -qE '^group: business$'      "${BUSINESS_DIR}/README.md"
}

# --- resolution wiring (t2) ---

@test "_resolution.md wires the business family" {
    # all five slugs named as opt-in packs
    for p in ${BUSINESS_PACKS}; do
        grep -q "\`${p}\`" "${RESOLUTION}" || { echo "resolution missing pack ${p}"; return 1; }
    done
    # group-qualified use_shared loading
    grep -q 'group-qualified'                    "${RESOLUTION}"
    grep -q '_shared/business/data-evidence.md'  "${RESOLUTION}"
    # non-dev packs are opt-in only
    grep -q 'opt-in by design'                   "${RESOLUTION}"
    # personas.use list form + union dedup + dev/business mixing ban
    grep -q 'use: \[sales, marketing\]'          "${RESOLUTION}"
    grep -qi 'union'                             "${RESOLUTION}"
    grep -q 'must not mix'                       "${RESOLUTION}"
    # business selection section exists
    grep -q '### 2.2 Business-pack critic selection' "${RESOLUTION}"
}

@test "business selection section carries the seat rules" {
    # one architect seat, guaranteed domain lens, business cap 4
    grep -q 'ONE architect seat total'           "${RESOLUTION}"
    grep -q 'Guaranteed domain lens'             "${RESOLUTION}"
    grep -q 'team_max_parallel_critics: 4'       "${RESOLUTION}"
    # one-trigger-one-lens + cross-pack suppression
    grep -q 'one trigger selects ONE lens'       "${RESOLUTION}"
    grep -qi 'cross-pack suppression'            "${RESOLUTION}"
    # skeptic-13 guard: the guaranteed lens is trigger-chosen across ALL seated packs — never bound
    # to the primary pack; "primary" has a single definition (first personas.use entry)
    grep -q 'across ALL seated'                  "${RESOLUTION}"
    ! grep -q 'from the deliverable.s primary pack' "${RESOLUTION}"
    grep -q 'single definition'                  "${RESOLUTION}"
}

@test "every marketing domain lens has a trigger and the suppression list names the overlap pairs" {
    # quality-10: all eight marketing lenses reachable via the §2.2 trigger table
    for lens in 'Outreach & Sequencing' 'Paid Media' 'PR & Community' 'Brand & Copy' \
                'Social & Content' 'Conversion & Retention' 'Market & Compliance'; do
        grep -q "${lens}" "${RESOLUTION}" || { echo "trigger table missing: ${lens}"; return 1; }
    done
    grep -q 'falls through to a relevance pick' "${RESOLUTION}"
    # quality-11: the three declared overlap pairs are in the suppression list
    grep -q 'SEO & Discoverability'   "${RESOLUTION}"
    grep -q 'Unit Economics & Pricing' "${RESOLUTION}"
    grep -q 'cedes the spend-math'     "${RESOLUTION}"
    # and Paid Media's own conditional cede is declared in the pack
    grep -q 'cede the spend-math recompute to data-evidence' "${VAULT_ROOT}/personas/marketing.md"
}

# --- marketing integration (t3) ---

@test "marketing pack extended to eight lenses with the two new personas" {
    local f="${VAULT_ROOT}/personas/marketing.md"
    grep -q 'eight marketing-domain lenses'      "${f}"
    ! grep -q 'six marketing-domain lenses'      "${f}"
    grep -q '^## Persona: Paid Media'            "${f}"
    grep -q '^## Persona: PR & Community'        "${f}"
    # reciprocal boundary to the deep seo pack
    grep -q 'personas/seo.md'                    "${f}" || grep -q '`personas/seo.md`' "${f}"
}

# --- decorrelation guards (q2, q3, s3, s6) ---

@test "business README carries no slug-keyed per-pack overlay table (single source of truth)" {
    # per-pack bindings live only in the packs' inline overlays (quality-1 regression)
    ! grep -qE '^\s*(sales|seo|support|business|startup-eval):\s+"' "${BUSINESS_DIR}/README.md"
}

@test "no stack-local persona name collides with a shared critic id" {
    # exact + near-collision guard (quality-2/9 regression): no local persona may be named like
    # skeptic or data-evidence
    for p in ${BUSINESS_PACKS}; do
        local f="${VAULT_ROOT}/personas/${p}.md"
        ! grep -qiE '^## Persona: (skeptic|market skeptic|data.?evidence|demand evidence)' "${f}" \
            || { echo "${p}: colliding persona name"; return 1; }
    done
}

@test "SoV method audit is owned exactly once (data-evidence, not GEO)" {
    # seo.md GEO routes the method audit; data-evidence owns it (skeptic-3/4 regression)
    grep -q 'routed to `business/data-evidence`'   "${VAULT_ROOT}/personas/seo.md"
    grep -q 'single owner of the method audit'     "${BUSINESS_DIR}/data-evidence.md"
}

@test "data-evidence one-cluster waiver + split trigger are documented" {
    grep -q 'One-cluster waiver'   "${BUSINESS_DIR}/data-evidence.md"
    grep -qi 'split trigger'       "${BUSINESS_DIR}/README.md"
}

# --- docs propagation (t4, t5) ---

@test "VAULT.md template documents the use-list form and the extended project_type enum" {
    local f="${VAULT_ROOT}/templates/VAULT.md"
    grep -q 'use: \[sales, marketing\]' "${f}"
    grep -q 'startup-eval'              "${f}"
    grep -q 'business packs default 4'  "${f}"
}

@test "propose-loop step states the business cap where the loop reads it" {
    grep -q 'business packs' "${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
}

@test "business family is indexed in README and indications" {
    grep -q '_shared/business'          "${VAULT_ROOT}/README.md"
    grep -q 'business-persona-family'   "${VAULT_ROOT}/vault/indications/_index.md"
    [ -f "${VAULT_ROOT}/vault/indications/business-persona-family.md" ]
}
