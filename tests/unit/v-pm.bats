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

@test "capture writes a planning-session record and extracts cross-project ADRs" {
    grep -qi 'planning-session'             "${STEPS}/05-capture.md"
    grep -qi 'sessions/'                    "${STEPS}/05-capture.md"
    grep -qi 'ADR'                          "${STEPS}/05-capture.md"
    grep -qi 'decisions/'                   "${STEPS}/05-capture.md"
    grep -qi 'commit'                       "${STEPS}/05-capture.md"
    # cross-project ADRs land in the neutral workspace by default
    grep -qi 'neutral workspace\|_features/<feature>/decisions' "${STEPS}/05-capture.md"
    # the knowledge center is referenced + its glossary/rules recorded
    grep -qi 'requirements.md'              "${STEPS}/05-capture.md"
    grep -qi 'glossary'                     "${STEPS}/05-capture.md"
    # single-repo captures against the project vault
    grep -qi 'single-repo\|project vault'   "${STEPS}/05-capture.md"
}

@test "requirements id-traceability seam is wired at the CONSUMING files, not just feature-pickup" {
    # (i) pickup reads requirements.md into session context (read-only, no capture-time id write)
    grep -qi 'requirements.md'              "${PICKUP}"
    # (ii) propose-loop names requirements.md in the f2 digest + echoes REQ-NN into the backlog source
    grep -qi 'requirements.md'              "${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
    grep -qi 'REQ-'                         "${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
    # (iii) execute-loop / capture writes REQ-NN into the ESTABLISHED dossier Behaviors
    grep -qi 'REQ-'                         "${VAULT_ROOT}/commands/v-team/steps/04-execute-loop.md"
    grep -qi 'established'                  "${VAULT_ROOT}/commands/v-team/steps/04-execute-loop.md"
}

@test "v-work LOAD CONTEXT globs the requirements/ category (single-repo knowledge center is loaded)" {
    grep -qi 'requirements'                 "${VAULT_ROOT}/commands/v-work/steps/02-load-context.md"
}

@test "id chain closes for BOTH /v-work and /v-team — the REQ-NN carry lives in shared /v-capture Step 5b" {
    # the canonical carry is in /v-capture (shared by both lifecycles), not only v-team's execute-loop
    grep -qi 'REQ-'                         "${VAULT_ROOT}/commands/v-capture.md"
    grep -qi 'requirements.md\|requirements/' "${VAULT_ROOT}/commands/v-capture.md"
    grep -qi 'v-work.*v-team\|both'         "${VAULT_ROOT}/commands/v-capture.md"
    # v-team's §5.4a defers to the shared step rather than duplicating it
    grep -qi 'v-capture.*5b\|Step 5b\|shared' "${VAULT_ROOT}/commands/v-team/steps/04-execute-loop.md"
}

@test "single-repo slug-collision check targets requirements/, and capture has a single-repo output branch" {
    # skep-10: §1.4 checks the project vault's requirements/ for single-repo, not just _features/
    grep -qi 'requirements/<feature>\|<project-vault>/requirements' "${STEPS}/01-intake.md"
    # arch-11: 05-capture has a single-repo output/commit branch (project vault), not multi-repo-only
    grep -qi 'single-repo'                  "${STEPS}/05-capture.md"
    grep -qi 'project.vault\|<project-vault>' "${STEPS}/05-capture.md"
}

@test "requirements/ category has an index-maintenance contract in vault-guide §3" {
    grep -q  'requirements/_index.md'       "${VAULT_ROOT}/vault-guide.md"
}

@test "vault-guide documents the requirements knowledge center + spec→established lifecycle; ADR-014 inventoried" {
    grep -qi 'knowledge center'             "${VAULT_ROOT}/vault-guide.md"
    grep -qi 'requirements/'                "${VAULT_ROOT}/vault-guide.md"
    grep -qi 'REQ-'                         "${VAULT_ROOT}/vault-guide.md"
    grep -qi 'spec.*established\|established.*spec' "${VAULT_ROOT}/vault-guide.md"
    [ -f "${VAULT_ROOT}/vault/decisions/ADR-014-vpm-business-knowledge-center.md" ]
    grep -q  'ADR-014'                      "${VAULT_ROOT}/vault/decisions/_inventory.md"
}

@test "v-pm dispatcher reframes 'when to use' for 1+ repos (knowledge center) with coordination as the 2+ delta" {
    grep -qi 'requirements'                 "${PM}"
    grep -qi '1 repo\|single-repo\|1+ repos\|any.*feature' "${PM}"
    grep -qi '2+ repos'                     "${PM}"
}

@test "load-context is vault-first, ACROSS every participant vault, and emits a digest" {
    grep -qi 'claude-mem\|grep'             "${STEPS}/02-load-context.md"
    grep -qi 'every participant\|each participant\|participant' "${STEPS}/02-load-context.md"
    grep -qi '_global'                      "${STEPS}/02-load-context.md"
    grep -qi '_features'                    "${STEPS}/02-load-context.md"
    grep -qi 'digest'                       "${STEPS}/02-load-context.md"
    grep -qi 'fallback'                     "${STEPS}/02-load-context.md"
    # cheapest-first precedence, no source reads here
    grep -qi 'cheapest-first\|precedence'   "${STEPS}/02-load-context.md"
}

@test "intake clarify-hard-blocks; single-repo authors requirements.md into the project vault (not a bare hand-off) then hands execution off" {
    grep -qi 'clarify'                      "${STEPS}/01-intake.md"
    grep -qi 'wait\|hard-block'             "${STEPS}/01-intake.md"
    grep -qi '1 participant\|single-participant\|single-repo' "${STEPS}/01-intake.md"
    grep -qi 'hand off\|hand-off\|/v-team'  "${STEPS}/01-intake.md"
    # single-repo still authors the knowledge center into the project's OWN vault, skipping the workspace
    grep -qi 'requirements.md'              "${STEPS}/01-intake.md"
    grep -qi 'requirements/<feature>\|<project-vault>/requirements' "${STEPS}/01-intake.md"
    grep -qi 'skip.*workspace\|no.*_features/ workspace\|not.*seed' "${STEPS}/01-intake.md"
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

@test "seed-workspace scaffolds requirements.md, seeds shard rule-ids, and has NO ledger file (derived view)" {
    grep -qi 'requirements.md'              "${STEPS}/04-seed-workspace.md"
    grep -qi 'generic-plan.md'              "${STEPS}/04-seed-workspace.md"
    grep -qi 'contracts.md'                 "${STEPS}/04-seed-workspace.md"
    grep -qi 'conversation/'                "${STEPS}/04-seed-workspace.md"
    grep -qi 'projects/'                    "${STEPS}/04-seed-workspace.md"
    grep -qi 'derived view\|no.*ledger'     "${STEPS}/04-seed-workspace.md"
    grep -qi 'symlink'                      "${STEPS}/04-seed-workspace.md"
    # v-pm seeds REQ ids into the shard's owned section, NOT into Consumed contract
    grep -qi 'Business rules to satisfy\|REQ-'  "${STEPS}/04-seed-workspace.md"
    # multi-repo only — single-repo is handled in intake §1.3
    grep -qi 'single-repo'                  "${STEPS}/04-seed-workspace.md"
}

@test "plan-panel emits the requirements.md knowledge center (rules + glossary), single source of why" {
    grep -qi 'requirements.md'              "${STEPS}/03-plan-panel.md"
    grep -qi 'business rules\|REQ-'         "${STEPS}/03-plan-panel.md"
    grep -qi 'glossary'                     "${STEPS}/03-plan-panel.md"
    grep -qi 'single source of .why.\|why.*requirements' "${STEPS}/03-plan-panel.md"
    # single-repo mode emits requirements only (skips contracts + generic-plan)
    grep -qi 'single-repo'                  "${STEPS}/03-plan-panel.md"
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

@test "all seven _features templates exist (incl. planning-session + requirements)" {
    [ -f "${TPL}/header.md" ]
    [ -f "${TPL}/requirements.md" ]
    [ -f "${TPL}/generic-plan.md" ]
    [ -f "${TPL}/contracts.md" ]
    [ -f "${TPL}/project-shard.md" ]
    [ -f "${TPL}/THREAD.md" ]
    [ -f "${TPL}/planning-session.md" ]
}

@test "requirements.md template is the business knowledge center with test-shaped rules + glossary + REQ ids" {
    grep -qi 'knowledge center\|business rules'   "${TPL}/requirements.md"
    grep -qi 'REQ-'                               "${TPL}/requirements.md"
    grep -qi 'precondition'                        "${TPL}/requirements.md"
    grep -qi 'glossary'                            "${TPL}/requirements.md"
    grep -qi 'user stories'                        "${TPL}/requirements.md"
    grep -qi 'variant.*state\|decision table\|state-transition' "${TPL}/requirements.md"
    # it is a SPEC, distinct from the established feature dossier
    grep -qi 'spec\|aspirational'                  "${TPL}/requirements.md"
    grep -qi 'axis\|\[authz\]\|\[error\]\|\[nfr\]' "${TPL}/requirements.md"
}

@test "project-shard has a v-pm-owned 'Business rules to satisfy' REQ-id section (single-writer carve-out)" {
    grep -qi 'Business rules to satisfy'           "${TPL}/project-shard.md"
    grep -qi 'REQ-'                                "${TPL}/project-shard.md"
    grep -qi 'seeded by /v-pm\|/v-pm seeds\|SEEDED BY /v-pm\|v-pm owns\|v-pm-seeded' "${TPL}/project-shard.md"
    grep -qi 'preserve\|not overwrite\|never overwrite\|append' "${TPL}/project-shard.md"
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
    grep -q  'v-pm.md'                       "${VAULT_ROOT}/docs/commands.md"
}

@test "vault.gitignore ignores the feature workspace symlinks" {
    grep -qi 'features/\*/\|_features'      "${VAULT_ROOT}/templates/vault.gitignore"
}

# --- ADR-024: elicitation, definition of done, appetite, tracking -------------

@test "elicitation module exists, stays under its cap, and carries a checkable stopping rule" {
    EL="${VAULT_ROOT}/commands/_shared/elicitation.md"
    [ -f "${EL}" ]
    [ "$(wc -l < "${EL}")" -le 250 ]
    grep -qi '5 whys\|five whys'        "${EL}"
    grep -qi 'document analysis'        "${EL}"
    grep -qi 'scenario walkthrough'     "${EL}"
    grep -qi 'judgement call, no evidence' "${EL}"
    # the stopping rule, and the promise that it never blocks
    grep -qi 'stopping'                 "${EL}"
    grep -qi 'definition of ready'      "${EL}"
    grep -qi 'stated default'           "${EL}"
    # the ledger has ONE home, not a new store
    grep -q  '## Open questions'        "${EL}"
    grep -q  '## Assumptions to test'   "${EL}"
    # question shape is referenced, never restated
    grep -qi 'communication.md'         "${EL}"
}

@test "definition-of-done module is two-tier, three-state, and honest about missing tooling" {
    DOD="${VAULT_ROOT}/commands/_shared/definition-of-done.md"
    [ -f "${DOD}" ]
    [ "$(wc -l < "${DOD}")" -le 250 ]
    grep -qi 'not-applicable'           "${DOD}"
    grep -qi 'baseline'                 "${DOD}"
    grep -qi 'feature extension\|feature-mode extension' "${DOD}"
    # §5.2's characterization-check alternative must survive verbatim, or the gate is unmeetable here
    grep -qi 'characterization check'   "${DOD}"
    grep -qi 'temporarily break the code' "${DOD}"
    # evidence and the stale-row date are what make a `done` row trustworthy
    grep -qi 'evidence'                 "${DOD}"
    grep -qi 'last touched'             "${DOD}"
}

@test "the done gate runs BEFORE staging, not after the commit" {
    CC="${VAULT_ROOT}/commands/v-work/steps/05-commit-capture.md"
    grep -qi 'definition-of-done.md'    "${CC}"
    dod_line=$(grep -n 'definition-of-done.md' "${CC}" | head -1 | cut -d: -f1)
    stage_line=$(grep -n '^## 5.1 Code commit' "${CC}" | head -1 | cut -d: -f1)
    [ "${dod_line}" -lt "${stage_line}" ]
    # a plain session must not be blocked by a feature-mode row it does not have
    grep -qi 'plain session'            "${CC}"
}

@test "/v-do carries the done gate itself, since it never reads the capture step" {
    grep -qi 'definition-of-done.md'    "${VAULT_ROOT}/commands/v-do.md"
    ! grep -qi '05-commit-capture'      "${VAULT_ROOT}/commands/v-do.md"
}

@test "v-pm emits an appetite and a first slice, never a task list" {
    grep -qi 'appetite'                 "${PM}"
    grep -qi 'appetite'                 "${STEPS}/03-plan-panel.md"
    grep -qi 'first slice'              "${STEPS}/03-plan-panel.md"
    grep -qi 'never a task list\|not a task list\|never write session-sized\|not enumerate' "${STEPS}/03-plan-panel.md"
    grep -q  '## Appetite'              "${TPL}/generic-plan.md"
    grep -q  '## First slice'           "${TPL}/generic-plan.md"
    grep -q  '## Options considered'    "${TPL}/generic-plan.md"
}

@test "the shard carries a Sessions tracker with evidence, a date, and a bounded vocabulary" {
    SH="${TPL}/project-shard.md"
    grep -q  '## Sessions'              "${SH}"
    grep -qi 'evidence'                 "${SH}"
    grep -qi 'last touched'             "${SH}"
    grep -qi 'todo | doing | done | dropped' "${SH}"
    # /v-ask writes nothing, so it can never close a row
    grep -qi 'NOT /v-ask\|not /v-ask'   "${SH}"
    # the drift check is a mechanical table compare — keep this table out of its way
    grep -qi 'Consumed contract'        "${SH}"
    # coverage has ONE home: the table, not the REQ id list
    ! grep -qi 'annotates coverage'     "${SH}"
}

@test "v-pm seeds the Sessions header and appetite but never a row" {
    grep -q  '## Sessions'              "${STEPS}/04-seed-workspace.md"
    grep -qi 'no rows\|NO rows'         "${STEPS}/04-seed-workspace.md"
    grep -qi 'Consumed contract'        "${STEPS}/04-seed-workspace.md"
}

@test "status derives progress from shard rows, not the header field that goes stale" {
    ST="${STEPS}/07-status.md"
    grep -qi 'shard'                    "${ST}"
    grep -qi 'REQ coverage\|REQ COVERED' "${ST}"
    grep -qi 'never started'            "${ST}"
    grep -qi 'disagree'                 "${ST}"
    grep -qi 'evidence'                 "${ST}"
}

@test "capture rolls the feature status up from the rows instead of leaving two copies" {
    VC="${VAULT_ROOT}/commands/v-capture.md"
    grep -qi 'Step 4e'                  "${VC}"
    grep -qi 'header.md'                "${VC}"
    grep -qi 'derive it, never ask\|Derive it, never ask' "${VC}"
}

@test "intake elicits rather than merely clarifying, and never blocks on a non-fork" {
    IN="${STEPS}/01-intake.md"
    grep -qi 'elicitation.md'           "${IN}"
    grep -qi 'success metric'           "${IN}"
    grep -qi 'definition-of-done.md'    "${IN}"
    tr '\n' ' ' < "${IN}" | grep -qi 'stated *default'
}

@test "requirements template keeps ONE home for the success metric and marks rule priority" {
    RQ="${TPL}/requirements.md"
    grep -qi 'MEASURABLE'               "${RQ}"
    grep -q  '## Assumptions to test'   "${RQ}"
    grep -qi '\[must\]'                 "${RQ}"
    # a second acceptance-shaped section is the duplication this avoids
    ! grep -q '## Success criteria'     "${RQ}"
}

@test "the appetite rule and ADR-024 are recorded in the vault" {
    grep -q 'plan-appetite-not-tasks' "${VAULT_ROOT}/vault/indications/plan-appetite-not-tasks.md"
    grep -qi 'amends' "${VAULT_ROOT}/vault/decisions/ADR-024-vpm-pm-discipline.md"
    grep -qi 'ADR-012' "${VAULT_ROOT}/vault/decisions/ADR-024-vpm-pm-discipline.md"
}

@test "requirements-spec-vs-established points at the step that actually exists" {
    IND="${VAULT_ROOT}/vault/indications/requirements-spec-vs-established.md"
    grep -q 'Step 4d'  "${IND}"
    ! grep -q 'Step 5b' "${IND}"
    grep -q '^## Step 4d' "${VAULT_ROOT}/commands/v-capture.md"
}
