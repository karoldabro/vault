#!/usr/bin/env bats
# Behaviour tests for bin/render-human.sh and `bin/gate.sh human` — the page a person reads before
# approving a plan. Contract: commands/_shared/human-plan.md.
#
# Every case renders tests/fixtures/human/plan.md into a temp directory and derives one defect from the
# result, so the assertion sits beside the edit. The golden page is rendered on the host and compared
# here, inside a container whose awk is a different implementation: that comparison is the test that
# the page is the same bytes on every awk.

load "../helpers/setup.bash"

setup() {
    export VAULT_ROOT="${VAULT_ROOT:-/code}"
    RENDER="${VAULT_ROOT}/bin/render-human.sh"
    GATE_SH="${VAULT_ROOT}/bin/gate.sh"
    FX="${VAULT_ROOT}/tests/fixtures"
    TMP="$(mktemp -d)"
}

teardown() {
    rm -rf "${TMP}"
}

# stage — copy the fixture plan and the spec it names into a temp tree, so a case may edit them.
stage() {
    mkdir -p "${TMP}/plans" "${TMP}/arch" "${TMP}/repo"
    cp "${FX}/human/plan.md" "${TMP}/plans/plan.md"
    cp "${FX}/arch/code-complete.arch.md" "${TMP}/arch/code-complete.arch.md"
    printf 'dod_profile: code\n' > "${TMP}/repo/VAULT.md"
    PLAN="${TMP}/plans/plan.md"; PAGE="${TMP}/plans/plan.human.html"; SPEC="${TMP}/arch/code-complete.arch.md"
}

# absent <literal> <file> — fails the test when the file holds the text. A bare `! grep` in the middle of
# a bats test never fails it, so every negative assertion here goes through this function.
absent() { if grep -qF -- "$1" "$2"; then echo "unexpected text in $2: $1"; return 1; fi; }

render() { "${RENDER}" "${PLAN}" --repo "${TMP}/repo" "$@"; }
human()  { "${GATE_SH}" human "${PLAN}" --repo "${TMP}/repo" "$@"; }

# variant <from> <to> <file> — one literal replacement in a file, so the defect is visible in the test.
variant() {
    local c; c=$(<"$3")
    case "${c}" in *"$1"*) ;; *) echo "variant: pattern absent from $3: $1"; return 1 ;; esac
    printf '%s\n' "${c/"$1"/"$2"}" > "$3"
}

@test "render: every spec section, diagram, table value and the review checklist reach the page" {
    stage; render
    [ -f "${PAGE}" ]
    while IFS= read -r h; do
        esc=${h#\#\# }; esc=${esc//&/&amp;}
        grep -qF "<h2>${esc}</h2>" "${PAGE}" || { echo "heading missing: ${h}"; return 1; }
    done < <(grep '^## ' "${SPEC}")
    [ "$(grep -c '<pre class="mermaid">' "${PAGE}")" -ge "$(grep -c '^```mermaid' "${SPEC}")" ]
    for v in orders order_lines OrderController OrderService OrderRepository; do grep -qF "${v}" "${PAGE}"; done
    grep -qF 'Check these yourself' "${PAGE}"
    grep -qF 'Does each piece of logic sit in the layer where it belongs?' "${PAGE}"
}

@test "render: markup in a cell or a plan line is shown as text and no script tag reaches the page" {
    stage
    variant '| orders | status |' '| orders | <script>alert(1)</script> & "q" |' "${SPEC}"
    variant 'Session S3 fixture.' 'Session <b>x</b> <script>y</script>.' "${PLAN}"
    render
    absent '<script' "${PAGE}"
    grep -qF '&lt;script&gt;alert(1)&lt;/script&gt;' "${PAGE}"
    grep -qF '&lt;b&gt;x&lt;/b&gt;' "${PAGE}"
    grep -qF '&amp;' "${PAGE}"
}

@test "render: a mermaid body keeps --> readable, escapes < and &, and stays in its pre block" {
    stage
    variant 'flowchart LR' 'flowchart LR
    Z["x < y & z"] --> Y' "${SPEC}"
    render
    grep -qF 'Z["x &lt; y &amp; z"] --> Y' "${PAGE}"
    awk '/<pre class="mermaid">/{o=1} o&&/Z\["x/{f=1} /<\/pre>/{o=0} END{exit f?0:1}' "${PAGE}"
}

@test "human: a spec changed after the page was rendered makes the page stale" {
    stage; render
    run human; [ "$status" -eq 0 ]; [ "$output" = "human: ok ${PAGE}" ]
    variant '| orders | status |' '| orders | state |' "${SPEC}"
    run human
    [ "$status" -eq 1 ]
    [[ "$output" == *"human page is stale: first difference at line "* ]]
}

@test "human: one changed byte in the page names the line it is on" {
    stage; render
    sed '3s/$/x/' "${PAGE}" > "${TMP}/changed.html"; cp "${TMP}/changed.html" "${PAGE}"
    run human
    [ "$status" -eq 1 ]
    [[ "$output" == *"first difference at line 3"* ]]
}

@test "human: human_plan values — empty, wrong scheme, empty id, another file name and a missing page are refused" {
    stage; render
    for v in "" "http://claude.ai/artifact/abc" "https://claude.ai/artifact/" "https://example.com/artifact/abc" "file:other.html"; do
        sed "s|^human_plan:.*|human_plan: ${v}|" "${FX}/human/plan.md" > "${PLAN}"
        run human
        [ "$status" -eq 1 ]
        [[ "$output" == *"human_plan"* ]]
    done
    sed "s|^human_plan:.*|human_plan: file:plan.human.html|" "${FX}/human/plan.md" > "${PLAN}"
    run human; [ "$status" -eq 0 ]
    rm -f "${PAGE}"
    run human; [ "$status" -eq 1 ]; [[ "$output" == *"human page is missing"* ]]
}

@test "render: a Sessions table with depends yields one edge per dependency and a lone node for none" {
    stage; render
    grep -qF '    S1["S1 first"]' "${PAGE}"
    grep -qF '    S1 --> S2' "${PAGE}"
    grep -qF '    S1 --> S3' "${PAGE}"
    grep -qF '    S2 --> S3' "${PAGE}"
    absent '--> S1' "${PAGE}"
    [ "$(grep -cF -- ' --> ' "${PAGE}")" -eq 3 ]
}

@test "render: a profile with no @review line yields a page with no checklist" {
    stage
    mkdir -p "${TMP}/repo/arch-profiles"
    grep -v '^@review' "${VAULT_ROOT}/arch-profiles/code.tsv" > "${TMP}/repo/arch-profiles/code.tsv"
    render
    absent 'Check these yourself' "${PAGE}"
}

@test "render: two renders are identical whatever the working directory, and equal the golden page" {
    stage
    render --stdout > "${TMP}/one.html"
    (cd / && "${RENDER}" "${PLAN}" --repo "${TMP}/repo" --stdout) > "${TMP}/two.html"
    cmp "${TMP}/one.html" "${TMP}/two.html"
    "${RENDER}" "${FX}/human/plan.md" --repo "${TMP}/repo" --stdout > "${TMP}/golden.html"
    cmp "${TMP}/golden.html" "${FX}/human/expected.html"
    [ "$(tail -c 1 "${TMP}/one.html" | od -An -c | tr -d ' ')" = '\n' ]
}

@test "render: a plan missing one of the listed sections renders no heading for it" {
    stage
    awk '/^## Decisions$/{s=1;next} /^## /{s=0} !s' "${PLAN}" > "${TMP}/nodec.md"; cp "${TMP}/nodec.md" "${PLAN}"
    render
    absent '<h2>Decisions</h2>' "${PAGE}"
    grep -qF '<h2>Success criteria</h2>' "${PAGE}"
}

@test "render: an escaped pipe stays one cell, and the renderer and the gate split the row the same way" {
    stage
    variant 'D-1 A script renders the page' 'D-1 a \| b' "${PLAN}"
    render
    grep -qF '<td>D-1 a | b</td>' "${PAGE}"
    first=$(bash -c 'source "$1"; table_rows "$2" "## Decisions" | head -1 | cut -d"$(printf "\037")" -f1' _ "${GATE_SH}" "${PLAN}")
    [ "${first}" = "D-1 a | b" ]
}

@test "render: bold, a numbered list, a nested bullet and a very long line render without breaking the page" {
    stage
    long=$(printf 'w%.0s' $(seq 1 400))
    variant 'Second paragraph with `code` and a second line.' "Text with **bold** and a \`code\` span.

1. first
2. second
   - nested bullet
${long}" "${PLAN}"
    render
    grep -qF '<strong>bold</strong>' "${PAGE}"
    grep -qF '<ol>' "${PAGE}"
    grep -qF '<li>first</li>' "${PAGE}"
    grep -qF '<li>nested bullet</li>' "${PAGE}"
    grep -qF "${long}" "${PAGE}"
    [ "$(grep -c '<h2>' "${PAGE}")" -ge 6 ]
}

@test "render: click, %% and javascript: lines of a spec diagram are left out and the rest is kept" {
    stage
    variant 'flowchart LR' 'flowchart LR
click A href "javascript:alert(1)"
%%{init: {"securityLevel": "loose"}}%%
A --> B %% see javascript:x' "${SPEC}"
    render
    absent 'click A' "${PAGE}"
    absent '%%{' "${PAGE}"
    absent 'javascript:' "${PAGE}"
    grep -qF 'orders ||--o{ order_lines : has' "${PAGE}"
}

@test "render: a diagram line is left out whatever its letter case or position" {
    stage
    variant 'flowchart LR' 'flowchart LR
A-->B; click A href "http://evil.example" _blank
CLICK A call cb()
Click A "x"
A-->B %%{init: {"securityLevel":"loose"}}%%
JAVASCRIPT:alert(1)
vbscript:x' "${SPEC}"
    render
    for t in 'evil.example' 'CLICK' 'Click' '%%{' 'JAVASCRIPT' 'vbscript'; do absent "$t" "${PAGE}"; done
    grep -qF 'orders ||--o{ order_lines : has' "${PAGE}"
}

@test "render: a repeated session id, the keyword end, a long scope and extra table cells are handled" {
    stage
    variant '| S3 | third | /v-team | todo | S1, S2 |' '| S3 | third | /v-team | todo | S1, S2 |
| S1 | duplicate | /v-team | todo | |
| end | closing scope with a very long description that must be cut at a word boundary somewhere | /v-team | todo | S3 |' "${PLAN}"
    variant '| D-1 A script renders the page | a function of the plan cannot omit a diagram | local |' '| D-1 A script renders the page | a function of the plan cannot omit a diagram | local | extra cell |' "${PLAN}"
    render
    [ "$(grep -c '    S1\["' "${PAGE}")" -eq 1 ]
    grep -qF '    S1["S1 first"]' "${PAGE}"
    grep -qF '    n_end["end closing scope with a very long description' "${PAGE}"
    grep -qF '    S3 --> n_end' "${PAGE}"
    grep -qF '<td>extra cell</td>' "${PAGE}"
    line=$(grep -F '    n_end["' "${PAGE}")
    [ "${#line}" -le 70 ]
}

@test "human: a valid artifact URL alone passes, an unreadable plan exits 2, and arch is reported before human" {
    stage; render
    sed "s|^human_plan:.*|human_plan: https://claude.ai/artifact/AbC123xyz|" "${FX}/human/plan.md" > "${PLAN}"
    run human
    [ "$status" -eq 0 ]
    [ "$output" = "human: ok ${PAGE}" ]
    run "${GATE_SH}" human "${TMP}/absent.md" --repo "${TMP}/repo"
    [ "$status" -eq 2 ]
    printf '#!/usr/bin/env bash\nexit 0\n' > "${TMP}/plans/x.sh"; chmod +x "${TMP}/plans/x.sh"
    run "${GATE_SH}" all "${PLAN}" --phase approve --repo "${TMP}/repo"
    a=${output%%human: ok*}
    [[ "${a}" == *"arch: ok"* ]]
}

@test "human: a page that differs only in its final newline names the last line, and a failing render is one message" {
    stage; render
    truncate -s -1 "${PAGE}"
    run human
    [ "$status" -eq 1 ]
    lines=$(wc -l < "${TMP}/plans/plan.human.html" | tr -d ' ')
    [[ "$output" == *"first difference at line ${lines}"* ]] || [[ "$output" == *"first difference at line $((lines + 1))"* ]]
    awk '/^## Task$/{s=1;next} /^## /{s=0} !s' "${PLAN}" > "${TMP}/notask.md"; cp "${TMP}/notask.md" "${PLAN}"
    render_page=$(cat "${PAGE}"); printf '%s\n' "${render_page}" > "${PAGE}"
    run human
    [ "$status" -eq 2 ]
    [[ "$output" == *"render failed: plan has no text under ## Task"* ]]
    [[ "$output" != *"gate: plan"* ]]
}

@test "human: a plan that names no arch_spec is skipped silently" {
    stage
    grep -v '^arch_spec:' "${FX}/human/plan.md" > "${PLAN}"
    run human
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "human: a status flip, a date or a written verdict does not change the page" {
    stage; render
    variant '| S3 | third | /v-team | todo |' '| S3 | third | /v-team | done |' "${PLAN}"
    variant '| SC-1 | WHEN it runs THE SYSTEM SHALL render | functional | command | `checks/x.sh` | exit 0 | | |' '| SC-1 | WHEN it runs THE SYSTEM SHALL render | functional | command | `checks/x.sh` | exit 0 | MET | `checks/x.sh` exited 0 |' "${PLAN}"
    run human
    [ "$status" -eq 0 ]
}

@test "render: an unreadable plan and a plan with no Task exit 2" {
    stage
    run "${RENDER}" "${TMP}/absent.md" --repo "${TMP}/repo"
    [ "$status" -eq 2 ]
    awk '/^## Task$/{s=1;next} /^## /{s=0} !s' "${PLAN}" > "${TMP}/notask.md"; cp "${TMP}/notask.md" "${PLAN}"
    run render
    [ "$status" -eq 2 ]
    [[ "$output" == *"no text under ## Task"* ]]
}

@test "render: a session scope with a backtick, a quote or markup gives a node label of plain characters only" {
    stage
    variant '| S1 | first |' '| S1 | a `x` "q" <b>y</b> z |' "${PLAN}"
    render
    line=$(grep -F '    S1["' "${PAGE}")
    [[ "${line}" =~ ^\ \ \ \ S1\[\"S1\ [A-Za-z0-9\ .,:/_-]*\"\]$ ]]
}

@test "render and gate: all --phase approve reaches the human check after arch" {
    stage; render
    printf '#!/usr/bin/env bash\nexit 0\n' > "${TMP}/plans/x.sh"; chmod +x "${TMP}/plans/x.sh"
    run "${GATE_SH}" all "${PLAN}" --phase approve --repo "${TMP}/repo"
    [[ "$output" == *"arch: ok"* ]]
    [[ "$output" == *"human: ok"* ]]
}
