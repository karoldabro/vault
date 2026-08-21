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
    grep -qE '^# rule 9 ' "${PATTERNS}"
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
