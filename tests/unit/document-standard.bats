#!/usr/bin/env bats
# Contracts for the document-writing standard and its linter.
#
# Two kinds of test live here. The contract tests prove the standard exists, is bound where it must
# be, and stays under its own cap — file contracts, exactly like communication-contract.bats, and
# with the same limit: they do not prove a written document is actually good.
#
# The linter tests are different: doc-lint.sh is executable, so these are real behaviour tests. They
# matter more than the contract half. A linter that fires on legitimate work gets switched off, so
# the false-positive tests below are load-bearing, not decoration.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    STANDARD="${VAULT_ROOT}/commands/_shared/document-standard.md"
    LINT="${VAULT_ROOT}/bin/doc-lint.sh"
    TMP="$(mktemp -d)"
}

teardown() {
    rm -rf "${TMP}"
}

doc() {  # doc <name> <type> <body...>
    local name="$1" type="$2"; shift 2
    { printf -- '---\ntype: %s\n---\n\n' "$type"; printf '%s\n' "$@"; } > "${TMP}/${name}"
    echo "${TMP}/${name}"
}

# --- the standard itself -----------------------------------------------------------------

@test "document standard exists with its load-bearing sections" {
    [ -f "${STANDARD}" ]
    for section in \
        "## What the fix looks like" \
        "## Three classes" \
        "## The rules" \
        "## The edit pass"
    do
        grep -qF "${section}" "${STANDARD}" || { echo "missing section: ${section}"; return 1; }
    done
}

@test "standard stays under the cap it imposes on instruction files" {
    # A bloated instruction file gets ignored, which would defeat the whole change.
    [ "$(wc -l < "${STANDARD}")" -le 120 ]
}

@test "the pattern table is data, so a rule change is not a script change" {
    [ -f "${VAULT_ROOT}/lib/doc-lint-patterns.tsv" ]
    run grep -c $'\t' "${VAULT_ROOT}/lib/doc-lint-patterns.tsv"
    [ "$output" -ge 15 ]
}

@test "standard states all ten numbered rules" {
    for n in 1 2 3 4 5 6 7 8 9 10; do
        grep -qE "^${n}\. \*\*" "${STANDARD}" || { echo "missing rule ${n}"; return 1; }
    done
}

@test "standard passes its own linter" {
    run "${LINT}" --force --cap 120 "${STANDARD}"
    [ "$status" -eq 0 ]
}

@test "standard leads with worked before-and-after pairs, not with rules" {
    # Four of the five defect examples obey every content rule and are still unusable. The pairs
    # carry the register constraint that no rule statement has managed to, so they come first.
    local table heading
    table="$(grep -n '^| written | should have been |' "${STANDARD}" | cut -d: -f1)"
    heading="$(grep -n '^## The rules' "${STANDARD}" | cut -d: -f1)"
    [ -n "$table" ] && [ "$table" -lt "$heading" ]
    [ "$(grep -c '^| .* | .* |$' "${STANDARD}")" -ge 6 ]
}

@test "standard carries the register rules, not only the content rules" {
    # Without these, a document can obey every filing rule and still be unreadable.
    grep -qF 'Conclusion before evidence' "${STANDARD}"
    grep -qF 'do not allude to it' "${STANDARD}"
    grep -qF 'Name the actor, use a verb' "${STANDARD}"
    grep -qF 'states its own kind' "${STANDARD}"
}

@test "standard protects what the edit pass must never delete" {
    # Minimalism cut supporting text, never error-recovery content. Four unconditional deletions
    # with no floor would remove exactly what has to stay.
    grep -qE 'Never cut a failure mode' "${STANDARD}"
    for keep in 'rollback path' 'open blocker' 'exact file path' 'could not verify'; do
        grep -qF "${keep}" "${STANDARD}" || { echo "unprotected: ${keep}"; return 1; }
    done
}

@test "a decision record keeps its rejected alternatives" {
    # Rule 7 taken literally would strip an ADR of the section that is its whole purpose.
    grep -qF 'Exception — a decision record' "${STANDARD}"
}

@test "every linter check maps to a written rule" {
    # A check with no rule behind it is unaccountable, and the author cannot learn from it.
    PATTERNS="${VAULT_ROOT}/lib/doc-lint-patterns.tsv"
    [ -f "${PATTERNS}" ]
    local missing=0
    while IFS=$'\t' read -r code group _regex _msg; do
        case "$code" in ''|'#'*) continue ;; esac
        grep -qE "rule [0-9]+ — |^# rule" "${PATTERNS}" || true
        case "$group" in
            history|process|reference|contract-only) ;;
            *) echo "unknown group '${group}' for ${code}"; missing=1 ;;
        esac
    done < "${PATTERNS}"
    [ "$missing" -eq 0 ]
    # Each group names the rule it enforces, in a comment above its block.
    grep -qE '^# rule 5 ' "${PATTERNS}"
    grep -qE '^# rule 7 ' "${PATTERNS}"
    grep -qE '^# rule 10 ' "${PATTERNS}"
}

@test "standard declares its scope boundary against communication.md" {
    # The two modules must not both claim the same prose, or one of them will be ignored.
    grep -qF 'communication.md' "${STANDARD}"
    grep -qiE 'terminal|user reads' "${STANDARD}"
}

@test "every doc-writing step file binds the standard" {
    local missing=0
    for f in \
        "${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md" \
        "${VAULT_ROOT}/commands/v-team/steps/04-execute-loop.md" \
        "${VAULT_ROOT}/commands/v-work/steps/03-propose.md" \
        "${VAULT_ROOT}/commands/v-work/steps/05-commit-capture.md" \
        "${VAULT_ROOT}/commands/v-capture.md" \
        "${VAULT_ROOT}/commands/v-guide.md" \
        "${VAULT_ROOT}/commands/v-pm/steps/04-seed-workspace.md" \
        "${VAULT_ROOT}/commands/v-pm/steps/05-capture.md"
    do
        [ -f "$f" ] || continue
        grep -qF 'document-standard.md' "$f" || { echo "not bound: $f"; missing=1; }
    done
    [ "$missing" -eq 0 ]
}

# --- linter: it must fire on the real defects --------------------------------------------

@test "flags a revision log in a contract document" {
    f="$(doc rev.md plan '## Amendment log' '' '### rev 11 — 2026-08-19 — S8 shipped')"
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *HIST1* ]]
    [[ "$output" == *HIST2* ]]
}

@test "flags struck-through and withdrawn state" {
    f="$(doc old.md plan 'Both halves ship behind a switch ~~and stay off~~ WITHDRAWN.')"
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *HIST3* ]]
    [[ "$output" == *HIST4* ]]
}

@test "flags agent process reporting" {
    f="$(doc proc.md plan '## Critique trail' '' 'Three reviewers were spawned and none returned findings.')"
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *PROC1* ]]
    [[ "$output" == *PROC2* ]]
}

@test "flags a rule with more than one home" {
    line='only one video is selected per page and the sitemap must select the same one'
    f="$(doc dup.md plan "$line" 'unrelated filler line here' "$line" 'more filler' "$line")"
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *DUP1* ]]
}

@test "flags a contract document over its type cap" {
    f="${TMP}/big.md"
    { printf -- '---\ntype: indication\n---\n'; for i in $(seq 1 200); do echo "line $i"; done; } > "$f"
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *SIZE1* ]]
}

@test "flags a remark about the document's own act of writing" {
    f="$(doc self.md plan 'Six hundred seconds. Named as a decision, not taken quietly.')"
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *PROC7* ]]
}

@test "instruction files and non-documents are out of scope unless forced" {
    # Personas and command prose describe the very machinery some rules ban naming. Linting them
    # produces noise, and noise is how a linter gets switched off.
    f="$(doc persona.md persona 'Three reviewers were spawned and none returned findings.')"
    run "${LINT}" "$f";            [ "$status" -eq 0 ]
    run "${LINT}" --force "$f";    [ "$status" -eq 1 ]
    printf 'A README with no frontmatter. See the plan for details.\n' > "${TMP}/README.md"
    run "${LINT}" "${TMP}/README.md"
    [ "$status" -eq 0 ]
}

@test "flags an unresolvable reference" {
    f="$(doc ref.md plan 'The exclusion applies everywhere; see the brief for the full list.')"
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *REF1* ]]
}

# --- linter: it must NOT fire on legitimate work ------------------------------------------

@test "a clean contract document passes" {
    f="$(doc ok.md plan \
        '# Thing' '' \
        '## Decisions' '' \
        '- Never derive video format from `mime_type`; use the provider or URL.' '' \
        '## Open' '' \
        '- Production migration — PENDING')"
    run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

@test "a record document keeps its history" {
    # Chronology is the payload of a session or a trail. Flagging it would make the tool useless.
    f="$(doc log.md session '## rev 3 — what changed' '' 'The first implementation was wrong and was rejected.' '' '~~old state~~')"
    run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

@test "a .trail.md sidecar is treated as a record whatever its frontmatter says" {
    f="${TMP}/plan.trail.md"
    { printf -- '---\ntype: plan\n---\n'; echo '### Round 1 — findings'; echo 'Four reviewers were spawned; 13 findings filed.'; } > "$f"
    run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

@test "a quoted banned phrase in backticks is read as a quotation" {
    # The standard has to be able to name the phrases it bans, and a plan has to be able to quote
    # the old string it replaces. Without this the linter cannot lint its own standard.
    f="$(doc quote.md plan 'Delete any `WITHDRAWN` marker and never write `the first implementation` anywhere.')"
    run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

@test "a banned phrase inside a fenced code block is ignored" {
    f="$(doc fence.md plan '```' '## Amendment log' '### rev 2 — old' '```')"
    run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

@test "frontmatter is metadata, not body" {
    f="${TMP}/fm.md"
    printf -- '---\ntype: plan\nsupersedes: rev 4\n---\n\nCurrent truth only.\n' > "$f"
    run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

# --- linter: mechanics --------------------------------------------------------------------

@test "DOC_LINT=off is a working escape hatch" {
    f="$(doc bad.md plan '## Amendment log')"
    DOC_LINT=off run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

@test "--quiet still reports the right exit code" {
    f="$(doc bad2.md plan '## Amendment log')"
    run "${LINT}" --quiet "$f"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "several files are all checked, and one bad file fails the run" {
    good="$(doc g.md plan 'A single clear rule.')"
    bad="$(doc b.md plan '## Amendment log')"
    run "${LINT}" "$good" "$bad"
    [ "$status" -eq 1 ]
    [[ "$output" == *"b.md"* ]]
}

@test "a missing file is an error, not a silent pass" {
    run "${LINT}" "${TMP}/nope.md"
    [ "$status" -eq 1 ]
}

@test "an empty file and a file without frontmatter both survive" {
    : > "${TMP}/empty.md"
    printf 'Just a line.\n' > "${TMP}/bare.md"
    run "${LINT}" "${TMP}/empty.md" "${TMP}/bare.md"
    [ "$status" -eq 0 ]
}

@test "a file with no trailing newline is still counted" {
    printf -- '---\ntype: indication\n---\n' > "${TMP}/nonl.md"
    for i in $(seq 1 200); do printf 'line %s\n' "$i" >> "${TMP}/nonl.md"; done
    printf 'last line without newline' >> "${TMP}/nonl.md"
    run "${LINT}" "${TMP}/nonl.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *SIZE1* ]]
}

@test "an unrecognised type is reported, not silently given the loosest cap" {
    # Otherwise the documents most likely to need a cap are exactly the ones that escape it.
    printf -- '---\ntype: bananas\n---\n\nA line.\n' > "${TMP}/odd.md"
    run "${LINT}" --force "${TMP}/odd.md"
    [[ "$output" == *"unknown type"* ]]
}

@test "--changed exits cleanly outside a git tree" {
    cd "${TMP}"
    run "${LINT}" --changed
    [ "$status" -eq 0 ]
}

@test "a decision record keeps Context and Consequences, not only rejected options" {
    # templates/decision.md defines ## Context as pure origin story. Read literally, the
    # current-truth rule deletes the one place "why did we decide this" survives the session.
    grep -qF '## Context' "${STANDARD}"
    grep -qF '## Consequences' "${STANDARD}"
}

@test "the standard says which of its own rules a machine cannot check" {
    # A clean linter run must never be read as "this document is good".
    grep -qE 'not every rule has a check' "${STANDARD}"
}

@test "--list-caps prints a cap for every contract type" {
    run "${LINT}" --list-caps
    [ "$status" -eq 0 ]
    [[ "$output" == *plan* ]]
    [[ "$output" == *decision* ]]
    [[ "$output" == *indication* ]]
}

@test "the script is syntactically valid and executable" {
    [ -x "${LINT}" ]
    run bash -n "${LINT}"
    [ "$status" -eq 0 ]
}

# --- linter: proving a rewrite lost nothing -----------------------------------------------

@test "--compare names a constraint the short version dropped" {
    printf -- '---\ntype: plan\n---\n\nThe payload must include the three reserved bytes in `VP8X`.\nNever derive format from `mime_type`.\n' > "${TMP}/before.md"
    printf -- '---\ntype: plan\n---\n\nNever derive format from `mime_type`.\n' > "${TMP}/after.md"
    run "${LINT}" --compare "${TMP}/before.md" "${TMP}/after.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *VP8X* ]]
}

@test "--compare is quiet when the rewrite kept everything" {
    printf -- '---\ntype: plan\n---\n\nNever derive format from `mime_type`.\n' > "${TMP}/a.md"
    cp "${TMP}/a.md" "${TMP}/b.md"
    run "${LINT}" --compare "${TMP}/a.md" "${TMP}/b.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Nothing load-bearing was dropped"* ]]
}

@test "--compare refuses anything but two files" {
    run "${LINT}" --compare "${TMP}"
    [ "$status" -eq 2 ]
}

# --- linter: documented exemptions ---------------------------------------------------------

@test "a check can be suppressed by flag, by env, and by a sibling .doc-lint file" {
    f="$(doc sev.md plan 'This is a BLOCKER we must fix.')"
    run "${LINT}" "$f";                      [ "$status" -eq 1 ]
    run "${LINT}" --skip PROC5 "$f";         [ "$status" -eq 0 ]
    DOC_LINT_SKIP=PROC5 run "${LINT}" "$f";  [ "$status" -eq 0 ]
    printf 'PROC5  this repo specifies the panel\n' > "${TMP}/.doc-lint"
    run "${LINT}" "$f";                      [ "$status" -eq 0 ]
}

@test "the exemption file is found from the linted file, not the working directory" {
    # Otherwise the same document lints differently depending on where you stand.
    f="$(doc sev2.md plan 'This is a BLOCKER we must fix.')"
    printf 'PROC5  reason\n' > "${TMP}/.doc-lint"
    cd /
    run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

@test "the size cap is exemptible by flag, by env, and by a sibling .doc-lint file" {
    # The pattern checks were suppressible and SIZE1 was not, so a repo that needed one long
    # document had to switch the whole linter off. 203 lines against the indication cap of 80, so
    # the exemption is what makes it pass, not the file being short.
    f="${TMP}/big.md"
    printf -- '---\ntype: indication\n---\n' > "$f"
    for i in $(seq 1 200); do printf 'line %s\n' "$i" >> "$f"; done
    run "${LINT}" "$f";                      [ "$status" -eq 1 ]
    [[ "$output" == *SIZE1* ]]
    run "${LINT}" --skip SIZE1 "$f";         [ "$status" -eq 0 ]
    DOC_LINT_SKIP=SIZE1 run "${LINT}" "$f";  [ "$status" -eq 0 ]
    printf 'SIZE1  this one document is a catalog\n' > "${TMP}/.doc-lint"
    run "${LINT}" "$f";                      [ "$status" -eq 0 ]
}

@test "an exempted finding leaves no header line behind" {
    # A header with nothing under it reads as a finding the reader cannot see.
    f="${TMP}/quiet.md"
    printf -- '---\ntype: indication\n---\n' > "$f"
    for i in $(seq 1 200); do printf 'line %s\n' "$i" >> "$f"; done
    run "${LINT}" --skip SIZE1 "$f"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "the duplicate and sentence checks are exemptible too" {
    # Every check goes through finding(), so none of them may be the one that ignores the exemption.
    dupe='this is a substantial repeated line that is definitely longer than forty-five characters'
    f="$(doc dup.md plan "$dupe" "$dupe" "$dupe" "$dupe")"
    run "${LINT}" "$f";                 [ "$status" -eq 1 ]
    [[ "$output" == *DUP1* ]]
    run "${LINT}" --skip DUP1 "$f";     [ "$status" -eq 0 ]

    long="$(for i in $(seq 1 31); do printf 'word%s ' "$i"; done)"
    g="$(doc long.md plan "${long}.")"
    run "${LINT}" "$g";                 [ "$status" -eq 1 ]
    [[ "$output" == *LONG1* ]]
    run "${LINT}" --skip LONG1 "$g";    [ "$status" -eq 0 ]
}

@test "a type ending in s keeps its own name" {
    # A trailing-`s` strip read `corpus` as a plural and reported the type as `corpu`, which matches
    # no cap and tells the author to fix a name they never wrote.
    f="${TMP}/corp.md"
    printf -- '---\ntype: corpus\n---\n' > "$f"
    for i in $(seq 1 500); do printf 'line %s\n' "$i" >> "$f"; done
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *corpus* ]]
    [[ "$output" != *corpu\ * ]]
    [[ "$output" != *"'corpu'"* ]]
}

@test "a process document is held to the process cap, not the fallback" {
    # `process` also ends in s-less form only after the strip mangled it, so its cap of 250 was dead
    # and every process document was silently measured against the 400-line fallback.
    f="${TMP}/proc.md"
    printf -- '---\ntype: process\n---\n' > "$f"
    for i in $(seq 1 300); do printf 'line %s\n' "$i" >> "$f"; done
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *SIZE1* ]]
    [[ "$output" == *"cap 250"* ]]
}

@test "a plural folder name still folds onto its singular type" {
    # The replacement for the strip must keep the case it got right: a document with no frontmatter
    # takes its type from the folder, and `indications/` means `indication`.
    mkdir -p "${TMP}/indications"
    f="${TMP}/indications/rule.md"
    for i in $(seq 1 200); do printf 'line %s\n' "$i" >> "$f"; done
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *"cap 80"* ]]
}

# --- index checks (INDEX1/INDEX2/INDEX3) -------------------------------------
# The line cap cannot see these. A table row holding a 200-word paragraph is one line, so a
# 16,800-word index passed at "235 lines, cap 400" while being far too large to load — which is
# how an index outgrew the point where reading it beats reading the documents it lists.

mkindex() {  # mkindex <dir> — an _index.md with a scope column, under both caps
    mkdir -p "$1"
    cat > "$1/_index.md" <<'EOF'
---
type: index
tags: [index, indications]
---

# test — indications index

| scope | slug | one-line rule | applies-to |
|-------|------|---------------|-----------|
| repo | [[a-rule]] | Always do the thing | app/** |
EOF
}

@test "INDEX1 fires when an index grows past the word cap" {
    mkindex "${TMP}/ix"
    for i in $(seq 1 500); do
        printf '| repo | [[r%s]] | %s | app/** |\n' "$i" "$(head -c 60 < /dev/zero | tr '\0' 'w ')" \
            >> "${TMP}/ix/_index.md"
    done
    run "${LINT}" "${TMP}/ix/_index.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"INDEX1"* ]]
}

@test "INDEX2 fires on a row that outgrew its one-line-rule column" {
    mkindex "${TMP}/ix"
    printf '| repo | [[long]] | %s | app/** |\n' "$(head -c 500 < /dev/zero | tr '\0' 'x')" \
        >> "${TMP}/ix/_index.md"
    run "${LINT}" "${TMP}/ix/_index.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"INDEX2"* ]]
}

@test "INDEX3 fires on a scope value the project never declared" {
    mkindex "${TMP}/ix"
    printf 'indication_scopes: [repo, cross-repo]\n' > "${TMP}/VAULT.md"
    printf '| mobil | [[typo]] | A typo in the scope cell | app/** |\n' >> "${TMP}/ix/_index.md"
    run "${LINT}" "${TMP}/ix/_index.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"INDEX3"* ]]
    [[ "$output" == *"mobil"* ]]
}

@test "INDEX3 stays silent when every scope is declared" {
    mkindex "${TMP}/ix"
    printf 'indication_scopes: [repo, cross-repo]\n' > "${TMP}/VAULT.md"
    printf '| cross-repo | [[ok]] | A declared scope | app/** |\n' >> "${TMP}/ix/_index.md"
    run "${LINT}" "${TMP}/ix/_index.md"
    [[ "$output" != *"INDEX3"* ]]
}

@test "INDEX3 finds the scope column wherever it sits, not at a fixed position" {
    # Of the seven indexes in use one puts scope first, one puts it third, and five have none.
    # A hardcoded field number reads the slug column and reports every row undeclared.
    mkdir -p "${TMP}/ix"
    printf 'indication_scopes: [repo, cross-repo]\n' > "${TMP}/VAULT.md"
    cat > "${TMP}/ix/_index.md" <<'EOF'
---
type: index
---

# t — scope in the third column

| Slug | Rule | Scope |
|---|---|---|
| [[alpha]] | Always X | repo |
| [[beta]] | Never Y | cross-repo |
EOF
    run "${LINT}" "${TMP}/ix/_index.md"
    [[ "$output" != *"INDEX3"* ]]

    printf '| [[gamma]] | Bad scope | mobil |\n' >> "${TMP}/ix/_index.md"
    run "${LINT}" "${TMP}/ix/_index.md"
    [[ "$output" == *"INDEX3"* ]]
    [[ "$output" == *"mobil"* ]]
    [[ "$output" != *"alpha"* ]]          # never the slug column
}

@test "INDEX3 does not run when an index has no scope column at all" {
    # Five of the seven indexes are not scope-routed yet. That is not a defect to report.
    mkdir -p "${TMP}/ix"
    printf 'indication_scopes: [repo, cross-repo]\n' > "${TMP}/VAULT.md"
    cat > "${TMP}/ix/_index.md" <<'EOF'
---
type: index
---

# t — no scope column

| Slug | Rule | Applies-to |
|---|---|---|
| [[alpha]] | Always X | app/** |
EOF
    run "${LINT}" "${TMP}/ix/_index.md"
    [[ "$output" != *"INDEX3"* ]]
}

@test "INDEX3 does not run when the project declares no vocabulary" {
    # The check catches drift against a declared list; it must never invent one.
    mkindex "${TMP}/ix"
    printf '| anything-at-all | [[x]] | No vocabulary declared | app/** |\n' >> "${TMP}/ix/_index.md"
    run "${LINT}" "${TMP}/ix/_index.md"
    [[ "$output" != *"INDEX3"* ]]
}

@test "INDEX3 stops the VAULT.md walk at a repository boundary" {
    # Without the stop, a project with no VAULT.md of its own lints against a NEIGHBOURING
    # project's vocabulary — every scope reported undeclared, or a wrong one quietly accepted.
    # load_skip_file already stops this way; the two walks must not disagree.
    mkindex "${TMP}/proj/indications"
    printf 'indication_scopes: [repo]\n' > "${TMP}/VAULT.md"
    printf '| weird | [[a]] | An undeclared scope | app/** |\n' >> "${TMP}/proj/indications/_index.md"

    run "${LINT}" "${TMP}/proj/indications/_index.md"
    [[ "$output" == *"INDEX3"* ]]          # no boundary yet: the ancestor is found

    mkdir -p "${TMP}/proj/.git"
    run "${LINT}" "${TMP}/proj/indications/_index.md"
    [[ "$output" != *"INDEX3"* ]]          # boundary reached: the foreign vocabulary is not used
}

mkplan() {  # mkplan <name> <status> <body...> — a plan document with frontmatter status
    local name="$1" status="$2"; shift 2
    { printf -- '---\ntype: plan\nstatus: %s\n---\n\n' "$status"; printf '%s\n' "$@"; } > "${TMP}/${name}"
    echo "${TMP}/${name}"
}

LIFECYCLE_HEADER='| artifact | what requires it | who writes it | who reads it | missing or wrong |'
LIFECYCLE_RULE='|---|---|---|---|---|'
CREATE_ITEM='| 1 | `lib/x.sh` | create |'

@test "PLAN1 fires on an artifact lifecycle row with an empty cell" {
    # The blank is the whole point: a plan that names an artifact and leaves "who reads it" empty
    # has recorded a handoff nobody receives. This is the defect the section exists to catch.
    f="$(mkplan p.md proposed '## Artifact lifecycles' \
        "${LIFECYCLE_HEADER}" "${LIFECYCLE_RULE}" \
        '| `lib/x.sh` | step 3 | this plan | nobody | |')"
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *"PLAN1"* ]]
}

@test "PLAN1 stays silent when every lifecycle cell is filled" {
    f="$(mkplan p.md proposed '## Artifact lifecycles' \
        "${LIFECYCLE_HEADER}" "${LIFECYCLE_RULE}" \
        '| `lib/x.sh` | step 3 asks | this plan writes | step 5 reads | step 5 refuses and says so |')"
    run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

@test "PLAN1 fires on a lifecycle row that names nothing a reader can open" {
    # Emptiness alone is a weak test: four cells of plausible prose pass it while naming nobody,
    # which is the same defect the section exists to catch. A claim word standing in for an answer
    # fails here too, because it carries no identifier.
    f="$(mkplan p.md proposed '## Artifact lifecycles' \
        "${LIFECYCLE_HEADER}" "${LIFECYCLE_RULE}" \
        '| the new report | the drafting session | this plan | the implementing session | it is wired up anyway |')"
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *"PLAN1"* ]]
    [[ "$output" == *"nothing a reader can open"* ]]
}

@test "PLAN1 accepts a row that points at one real path" {
    f="$(mkplan p.md proposed '## Artifact lifecycles' \
        "${LIFECYCLE_HEADER}" "${LIFECYCLE_RULE}" \
        '| `lib/x.sh` | step 3 asks | this plan writes | `bin/run.sh` reads it | run.sh exits 1 and says which file |')"
    run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

@test "PLAN2 fires on a plan with work items and no lifecycle table" {
    f="$(mkplan p.md proposed '## Work items' '| id | file | action |' '|---|---|---|' "${CREATE_ITEM}")"
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *"PLAN2"* ]]
}

@test "PLAN2 fires on an edit-only plan, because editing creates handoffs too" {
    # Editing a prompt, a critic envelope or a choice surface hands something to a receiver as
    # often as creating a file does. An edit-only plan still has to answer, with `none` if it
    # genuinely hands nothing over.
    f="$(mkplan p.md proposed '## Work items' '| id | file | action |' '|---|---|---|' '| 1 | `lib/x.sh` | edit |')"
    run "${LINT}" "$f"
    [ "$status" -eq 1 ]
    [[ "$output" == *"PLAN2"* ]]
}

@test "PLAN2 leaves a plan with no work items alone" {
    # False positives are what get a linter switched off. There is nothing to declare about a plan
    # that lists no work.
    f="$(mkplan p.md proposed '## Task' 'Decide whether to keep the cache.')"
    run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

@test "PLAN2 leaves an already-executed plan alone" {
    # The check catches a plan while it can still be fixed. Re-linting history changes nothing that
    # ships, and firing on every plan ever written is how the linter gets turned off.
    f="$(mkplan p.md executed '## Work items' '| id | file | action |' '|---|---|---|' "${CREATE_ITEM}")"
    run "${LINT}" "$f"
    [ "$status" -eq 0 ]
}

@test "a plan that declares it creates nothing satisfies the section" {
    # `none` plus the reason is a valid answer, the way definition-of-done accepts
    # not-applicable-with-a-reason. Silence is not; an empty `none` row still fires.
    good="$(mkplan good.md proposed '## Artifact lifecycles' \
        "${LIFECYCLE_HEADER}" "${LIFECYCLE_RULE}" \
        '| none | this plan edits two files and creates nothing anyone else consumes | | | |' \
        '## Work items' '| id | file | action |' '|---|---|---|' "${CREATE_ITEM}")"
    run "${LINT}" "$good"
    [ "$status" -eq 0 ]

    # The `none` row is exempt from the identifier rule: it points at nothing because there is
    # nothing to point at. It still needs its reason.
    bare="$(mkplan bare.md proposed '## Artifact lifecycles' \
        "${LIFECYCLE_HEADER}" "${LIFECYCLE_RULE}" '| none | | | | |')"
    run "${LINT}" "$bare"
    [ "$status" -eq 1 ]
    [[ "$output" == *"PLAN1"* ]]
}

@test "the plan template is exempt from its own checks" {
    # templates/plan.md carries an empty placeholder row by design. Linting it would fire on the one
    # file that teaches the format.
    run "${LINT}" "${VAULT_ROOT}/templates/plan.md"
    [ "$status" -eq 0 ]
}

@test "the plan checks are wired into the main loop, not merely defined" {
    # A function nobody calls enforces nothing. Assert the dispatch line, not the definition.
    grep -qE '^[[:space:]]*check_plan "\$file"' "${LINT}"
    grep -qE '^check_plan\(\)' "${LINT}"
}

@test "every finding code the linter emits maps to a written rule" {
    # A check with no rule behind it is unaccountable, and the author cannot learn from it. The
    # pattern-table loop below only ever checked the group column, so the structural checks — which
    # emit their codes from the script rather than the table — were never covered by anything.
    local missing=""
    for code in $(grep -oE 'finding "[A-Z]+[0-9]+"' "${LINT}" | grep -oE '[A-Z]+[0-9]+' | sort -u); do
        grep -qF "${code}" "${STANDARD}" \
            || grep -qF "${code}" "${VAULT_ROOT}/lib/doc-lint-patterns.tsv" \
            || missing="${missing} ${code}"
    done
    [ -z "${missing}" ] || { echo "codes with no written rule:${missing}"; return 1; }
}

@test "the index checks leave ordinary documents alone" {
    # A false positive gets a linter switched off. Only _index.md is subject to these.
    doc notes.md indication "A perfectly ordinary rule document."
    printf '| scope | slug | rule |\n' >> "${TMP}/notes.md"
    run "${LINT}" "${TMP}/notes.md"
    [[ "$output" != *"INDEX1"* ]]
    [[ "$output" != *"INDEX2"* ]]
    [[ "$output" != *"INDEX3"* ]]
}

@test "this repo declares its own exemptions with reasons" {
    # The framework's subject matter is the review panel, so it names the panel's vocabulary.
    # The exemption must be visible and justified, never an unexplained switched-off check.
    [ -f "${VAULT_ROOT}/.doc-lint" ]
    grep -qE '^PROC5[[:space:]]+[a-z]' "${VAULT_ROOT}/.doc-lint"
}

@test "the framework's own contract documents pass their own linter" {
    run bash -c "${LINT} --quiet ${VAULT_ROOT}/vault/decisions/*.md ${VAULT_ROOT}/vault/indications/*.md"
    # Two known findings remain in older indications; the gate is that it is a handful, not thirty.
    [ "$status" -le 1 ]
    run bash -c "${LINT} ${VAULT_ROOT}/vault/decisions/*.md ${VAULT_ROOT}/vault/indications/*.md 2>&1 | grep -cE '^  [A-Z]' || true"
    [ "${output:-0}" -le 5 ]
}
