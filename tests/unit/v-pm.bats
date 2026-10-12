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

@test "v-pm dispatcher has plan/reconcile/status modes, a 'when to use' bar, and the read-only rule" {
    grep -qi 'reconcile'                    "${PM}"
    grep -qi 'status'                       "${PM}"
    grep -qi 'when to use'                  "${PM}"
    grep -q  'writes no code'               "${PM}"
    grep -q  'holds no opinion of its own'  "${PM}"
    grep -q  '### Step 4 — APPROVAL GATE'   "${PM}"
}

@test "v-pm dispatcher has a tool health-check + fallback table and the search precedence" {
    grep -qi 'fallback'                     "${PM}"
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

@test "capture uses the trail as the record, extracts ADRs, commits, and prints the run order" {
    C="${STEPS}/05-capture.md"
    grep -q  'plan.trail.md'                "${C}"
    grep -qi 'ADR'                          "${C}"
    grep -qi 'neutral workspace'            "${C}"
    grep -q  'vault-sync.sh push'           "${C}"
    grep -q  'pm-plan.sh order'             "${C}"
    grep -qi 'single-repo'                  "${C}"
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
    # The spec→established lifecycle moved with §13 into its own file; the guide keeps the pointer.
    grep -qi 'spec.*established\|established.*spec' "${VAULT_ROOT}/docs/cross-project-workspaces.md"
    [ -f "${VAULT_ROOT}/vault/decisions/ADR-014-vpm-business-knowledge-center.md" ]
    grep -q  'ADR-014'                      "${VAULT_ROOT}/vault/decisions/_inventory.md"
}

@test "v-pm plans one or many repos, proportional to the scale tier" {
    grep -qi 'one repo or several\|one or many repos' "${PM}"
    grep -qi 'scale tier'                   "${PM}"
}

@test "load-context is vault-first, ACROSS every participant vault, and emits a digest" {
    grep -qi 'grep'                         "${STEPS}/02-load-context.md"
    grep -qi 'every participant\|each participant\|participant' "${STEPS}/02-load-context.md"
    grep -qi '_global'                      "${STEPS}/02-load-context.md"
    grep -qi '_features'                    "${STEPS}/02-load-context.md"
    grep -qi 'digest'                       "${STEPS}/02-load-context.md"
    # cheapest-first precedence, no source reads here
    grep -qi 'cheapest-first\|precedence'   "${STEPS}/02-load-context.md"
}

@test "intake refuses without operator success criteria and sets tier, repos and plan home" {
    IN="${STEPS}/01-intake.md"
    grep -q  'I will not plan until you give at least one line' "${IN}"
    grep -q  'WHEN <trigger> THE SYSTEM SHALL <observable>' "${IN}"
    grep -qi 'never write a default in its place' "${IN}"
    grep -q  'absolute path'                "${IN}"
    grep -q  'personas/_shared/planning/README.md' "${IN}"
    grep -q  '<project-vault>/plans/<feature>/' "${IN}"
    grep -q  '<project-vault>/requirements/<feature>.md' "${IN}"
}

@test "plan-panel runs the parallel planning panel through the v-team loop and checks the plan" {
    P="${STEPS}/03-plan-panel.md"
    grep -qi 'parallel'                     "${P}"
    ! grep -qi 'sequential'                 "${P}"
    grep -q  '_resolution.md` §2.3'         "${P}"
    grep -q  '03-propose-loop.md'           "${P}"
    grep -q  'no `(f2)`'                    "${P}"
    grep -q  'pm-plan.sh check'             "${P}"
    grep -q  'templates/handoff.md'         "${P}"
    grep -q  'delivery-planner.md'          "${P}"
}

@test "seed-workspace runs after approval, multi-repo only, and keeps the tracker in plan.md" {
    S="${STEPS}/04-seed-workspace.md"
    grep -qi 'after approval\|approved'     "${S}"
    grep -qi 'single-repo mode skips'       "${S}"
    grep -q  'conversation/'                "${S}"
    grep -q  'symlink'                      "${S}"
    grep -q  'its one home'                 "${S}"
}

@test "plan-panel writes requirements, contracts and briefs with the run line" {
    P="${STEPS}/03-plan-panel.md"
    grep -q  'requirements.md'              "${P}"
    grep -qi 'glossary'                     "${P}"
    grep -q  'contracts.md'                 "${P}"
    grep -q  'claude --add-dir <plan folder> "<command> <absolute plan path>#<id>"' "${P}"
}

@test "status mode sweeps every feature and writes only the done lines" {
    ST="${STEPS}/07-status.md"
    grep -qi 'sweep'                        "${ST}"
    grep -q  'pm-plan.sh order'             "${ST}"
    grep -qi 'legacy'                       "${ST}"
    grep -q  'DD-2 to DD-4'                 "${ST}"
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
    # §13 is a pointer in the guide; the protocol itself lives in docs/cross-project-workspaces.md.
    grep -qi '## 13'                        "${VAULT_ROOT}/vault-guide.md"
    grep -qi '_features'                     "${VAULT_ROOT}/vault-guide.md"
    grep -qF 'docs/cross-project-workspaces.md' "${VAULT_ROOT}/vault-guide.md"
    grep -qi 'derived view'                  "${VAULT_ROOT}/docs/cross-project-workspaces.md"
    grep -qi 'latency contract'              "${VAULT_ROOT}/docs/cross-project-workspaces.md"
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

@test "v-pm decides the sessions and names no appetite" {
    ! grep -rqi 'appetite' "${PM}" "${STEPS}"
    grep -q '/v-pm` decides how many' "${STEPS}/03-plan-panel.md"
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

@test "intake elicits, states defaults, and adds only to the four done lines" {
    IN="${STEPS}/01-intake.md"
    grep -qi 'elicitation.md'           "${IN}"
    grep -q  'DD-1 to DD-4'             "${IN}"
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

# The shard carries the columns `bin/gate.sh master` reads, and three v-pm and v-work steps name them.

@test "the shard has depends after status and a Cross-session contracts section with five columns" {
    SH="${TPL}/project-shard.md"
    grep -q '^| id | scope | command | status | depends | REQ covered | evidence | last touched | deviation |$' "${SH}"
    grep -q '^## Cross-session contracts$' "${SH}"
    grep -q '^| id | contract | produced by | consumed by | shape |$' "${SH}"
    grep -q 'templates/master-plan.md' "${SH}"
}

@test "the status step checks each plan and still reads a legacy shard through the master gate" {
    ST="${STEPS}/07-status.md"
    grep -q 'pm-plan.sh check <plan>' "${ST}"
    grep -q 'bin/gate.sh master <shard>' "${ST}"
    grep -q 'REFUSED master' "${ST}"
    grep -q 'legacy layout: /v-pm reconcile <feature>' "${ST}"
}

@test "step 5.0 of the close step sets the master-plan row through session_of" {
    local s="${VAULT_ROOT}/commands/v-work/steps/05-commit-capture.md"
    grep -q 'session_of' "${s}"
    grep -q 'gate.sh verdict' "${s}"
    grep -q 'gate.sh master' "${s}"
}

@test "a shard instantiated from the template passes the master gate and loses a row on deletion" {
    local TMP; TMP=$(mktemp -d)
    sed 's/{{[a-z]*}}/x/g' "${TPL}/project-shard.md" > "${TMP}/shard.md"
    run "${VAULT_ROOT}/bin/gate.sh" master "${TMP}/shard.md"
    [ "$status" -eq 0 ]
    awk '{print} /^\|----\|-------\|---------\|--------\|---------\|/{print "| S1 | a | \/v-do | done | | | `x` | 2026-09-21 | |"; print "| S2 | b | \/v-do | todo | S1 | | | 2026-09-21 | |"}' "${TMP}/shard.md" > "${TMP}/filled.md"
    run "${VAULT_ROOT}/bin/gate.sh" master "${TMP}/filled.md"
    [ "$status" -eq 1 ]
    grep -q 'S2 depends on S1' <<<"$output"
    rm -rf "${TMP}"
}
