#!/usr/bin/env bats
# Contracts for the user-facing communication rules (ADR-018).
#
# These are FILE CONTRACTS. They prove the rules are present and coherent; they do NOT prove the
# framework obeys them at runtime. That limit is deliberate and is stated in the ADR — do not let a
# green suite here be read as "the output is actually short".

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    CONTRACT="${VAULT_ROOT}/commands/_shared/communication.md"
    STYLE="${VAULT_ROOT}/output-styles/director.md"
    PROPOSE="${VAULT_ROOT}/commands/v-work/steps/03-propose.md"
    PROPOSE_LOOP="${VAULT_ROOT}/commands/v-team/steps/03-propose-loop.md"
}

# Prose wraps across lines; match against the unwrapped file.
flat() { tr '\n' ' ' < "$1"; }

# --- the contract itself -----------------------------------------------------------------

@test "communication contract exists with all twelve sections" {
    [ -f "${CONTRACT}" ]
    for section in \
        "## Posture" \
        "## Answer first" \
        "## Assume the user has read nothing" \
        "## What to leave out" \
        "## Report exceptions, not normality" \
        "## Words & sentences" \
        "## Asking a question" \
        "## Presenting a decision" \
        "## Verdict first, detail on request" \
        "## When to go deep" \
        "## Outward-facing text" \
        "## Evidence note"
    do
        grep -qF "${section}" "${CONTRACT}" || { echo "missing section: ${section}"; return 1; }
    done
}

@test "contract stays under the 120-line cap it imposes on others" {
    # R-18: a bloated instruction file gets ignored, which would defeat the whole change.
    [ "$(wc -l < "${CONTRACT}")" -le 120 ]
}

@test "contract carries the evidence-honesty note (doctrine is not measured science)" {
    grep -qi 'never controlled-tested\|not present doctrine as validated' "${CONTRACT}"
    grep -qi 'decision-communication'                                     "${CONTRACT}"
}

@test "numeric caps exist AND are scoped to user-facing prose, never to reasoning" {
    grep -qi '25 words'   "${CONTRACT}"
    grep -qi '15 lines'   "${CONTRACT}"
    # The ~15-word average is its own rule; a bare grep for "15" is satisfied by "15 lines" above
    # and would let this one be changed or deleted silently.
    flat "${CONTRACT}" | grep -qi 'average near \*\*15\*\*'
    # the floor: capping reasoning costs accuracy, capping prose does not
    flat "${CONTRACT}" | grep -qi 'never to how much thinking'
    flat "${CONTRACT}" | grep -qi 'Terse reasoning costs accuracy'
}

@test "contract forbids bare file/decision/section references in user-facing text" {
    flat "${CONTRACT}" | grep -qi 'one-line plain gloss'
    flat "${CONTRACT}" | grep -qi 'answerable *from the message alone'
    flat "${CONTRACT}" | grep -qi 'never require opening a file'
    grep -q 'ADR-017' "${CONTRACT}"   # the worked example of a bare reference being a defect
}

@test "contract forbids meta-explanation openers" {
    grep -qi 'in other words' "${CONTRACT}"
    grep -qi 'to clarify'     "${CONTRACT}"
    flat "${CONTRACT}" | grep -qi 'Say it once'
}

@test "contract bans decorative metaphors but allows a structurally sound one" {
    grep -qi 'metaphors'          "${CONTRACT}"
    flat "${CONTRACT}" | grep -qi 'say where it breaks'
}

@test "contract translates framework-internal vocabulary instead of emitting it" {
    grep -q 'BLOCKER'   "${CONTRACT}"
    grep -q 'persona'   "${CONTRACT}"
    grep -qi 'convergence' "${CONTRACT}"
    flat "${CONTRACT}" | grep -qi 'Never use framework-internal words'
}

@test "contract has an ask-gate before the question-shape rules" {
    flat "${CONTRACT}" | grep -qi 'whether to ask at all'
    flat "${CONTRACT}" | grep -qi 'cannot name the consequence'
    flat "${CONTRACT}" | grep -qi 'option without its *consequence is unanswerable'
}

@test "presenting a decision requires Impact and a defined cut order" {
    flat "${CONTRACT}" | grep -qi 'Impact.*what this touches'
    flat "${CONTRACT}" | grep -qi 'Never ask *for approval without stating what will be touched'
    # when the cap binds, consequences and impact are the last things to go
    flat "${CONTRACT}" | grep -qi 'cut options first'
    flat "${CONTRACT}" | grep -qi 'Never cut a consequence'
}

@test "omit-when-empty is scoped to green states and never suppresses warnings" {
    flat "${CONTRACT}" | grep -qi 'Never report that a normal thing *was normal'
    flat "${CONTRACT}" | grep -qi 'cuts good news, never warnings'
    flat "${CONTRACT}" | grep -qi 'unavailable *tool'
    flat "${CONTRACT}" | grep -qi 'open blocker is an exception'
}

@test "depth-on-request names the ill-structured counter-condition" {
    flat "${CONTRACT}" | grep -qi 'Depth on request is never penalized'
    # expertise reversal does NOT hold on ill-structured work — keep the worked reasoning there
    flat "${CONTRACT}" | grep -qi 'ill-structured'
    flat "${CONTRACT}" | grep -qi 'impossible to check'
}

@test "contract defers outward-facing text to its own command file" {
    flat "${CONTRACT}" | grep -qi 'different reader'
    flat "${CONTRACT}" | grep -qi 'someone else.s inbox'
}

@test "contract exempts fixed output templates from rewording" {
    flat "${CONTRACT}" | grep -qi 'own contract .* do not reword them'
}

# --- binding: every command and every output-producing step file -------------------------

@test "every v-* command and every Required-output step file binds the contract" {
    local bind='~/.claude/commands/_shared/communication.md'
    local missing=0 f

    for f in "${VAULT_ROOT}"/commands/v-*.md; do
        grep -qF "${bind}" "${f}" || { echo "unbound command: ${f}"; missing=1; }
    done

    # Prefix match on purpose: one heading is suffixed
    # ("## Required output — the LOAD CONTEXT digest").
    while IFS= read -r f; do
        grep -qF "${bind}" "${f}" || { echo "unbound step file: ${f}"; missing=1; }
    done < <(grep -rl '^## Required output' "${VAULT_ROOT}/commands" | grep -v '/attic/')

    [ "${missing}" -eq 0 ]
}

@test "the Required-output file set is exactly 15 — a new one cannot silently fall out" {
    local n
    n="$(grep -rl '^## Required output' "${VAULT_ROOT}/commands" | grep -vc '/attic/')"
    [ "${n}" -eq 15 ] || { echo "expected 15 Required-output files, found ${n}"; return 1; }
}

@test "no brevity rule survives outside the contract, except the forge-comment one" {
    # The contract is allowed its own phrasing; v-cr's rule governs a DIFFERENT reader and stays.
    run grep -rn "Lead with the answer\|Keep it tight" \
        --exclude-dir=attic --exclude=communication.md "${VAULT_ROOT}/commands"
    [ "$status" -ne 0 ] || { echo "duplicate brevity rule: ${output}"; return 1; }
}

@test "the forge-comment brevity rule is kept and marked non-superseded" {
    local review="${VAULT_ROOT}/commands/v-cr/steps/03-review.md"
    grep -qi 'Be short, concise, precise'   "${review}"
    flat "${review}" | grep -qi 'deliberately local and is not superseded'
    flat "${review}" | grep -qi 'Do not delete this as a duplicate'
}

# --- the output style --------------------------------------------------------------------

@test "director output style exists with the three required frontmatter keys" {
    [ -f "${STYLE}" ]
    grep -q '^name: director'                 "${STYLE}"
    grep -q '^description: '                  "${STYLE}"
    grep -q '^keep-coding-instructions: true' "${STYLE}"
}

@test "output style is self-contained — it cannot read the command tree" {
    # A style is injected into the system prompt; it can't Read repo files, so a pointer is a no-op.
    run grep -n '_shared/communication.md\|commands/v-' "${STYLE}"
    [ "$status" -ne 0 ] || { echo "style delegates to unreachable files: ${output}"; return 1; }
}

@test "style and contract state the same numbers with the same strength" {
    # These two files are deliberate duplicates — a style is injected into the system prompt and
    # cannot read the contract — so nothing but this test keeps them from drifting apart.
    for phrase in "25 words" "capped at 15 lines"; do
        grep -qi "${phrase}" "${CONTRACT}" || { echo "contract lost: ${phrase}"; return 1; }
        grep -qi "${phrase}" "${STYLE}"    || { echo "style drifted on: ${phrase}"; return 1; }
    done
    # A soft restatement ("about 15 lines") is the drift this catches.
    run grep -i 'about 15 lines' "${STYLE}"
    [ "$status" -ne 0 ] || { echo "style softened the cap: ${output}"; return 1; }
}

@test "style keeps the verdict-first disclosure rule, not just verifiability" {
    flat "${STYLE}" | grep -qi 'Verdict first'
    flat "${STYLE}" | grep -qi 'do not paste it'
}

@test "output style restates every contract rule, one probe per section" {
    # The style is a deliberate duplicate (it cannot read the contract), so parity is guarded
    # rule-by-rule rather than by diff — the wording must differ, the rules must not.
    local probe
    for probe in \
        "you execute" \
        "first sentence" \
        "never require opening a file" \
        "Say it once" \
        "cuts good news, never warnings" \
        "25 words" \
        "cannot name the consequence" \
        "capped at 15 lines" \
        "do not paste it" \
        "Depth on request is never penalized" \
        "different reader" \
        "what this touches"
    do
        flat "${STYLE}" | grep -qi "${probe}" \
            || { echo "style dropped a contract rule: ${probe}"; return 1; }
    done
}
