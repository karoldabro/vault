#!/usr/bin/env bats
# Unit tests for the indication-routing helpers in lib/cr-helpers.sh.
#
# These cover the defect that let a review cite four project rules out of a hundred and forty-nine
# and report nothing about the rest: nothing computed which rules the diff could break, so
# rule-fetching was a side effect of what a file happened to remind a critic of.
#
# Three functions, three jobs. cr_rule_route decides which rules a changed-file list can reach.
# cr_anchor_check decides whether a critic's citation resolves against the real diff. cr_rule_coverage
# turns the two into counts, and refuses only on the bucket an operator can act on.

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    # shellcheck source=/dev/null
    source "$REPO_ROOT/lib/cr-helpers.sh"
    TMP="$BATS_TEST_TMPDIR"

    # A three-column index in the shape bin/vault-init.sh scaffolds.
    {
        printf '| Slug | Rule | Applies-to |\n'
        printf '|------|------|------------|\n'
    } > "$TMP/index-head"
}

index() { cat "$TMP/index-head" - > "$TMP/index"; }

# --- cr_rule_route: the happy path ----------------------------------------

@test "cr_rule_route emits applies with the matched path when a glob hits a changed file" {
    printf '| [[automated-cr-safety]] | PR-review automation | `commands/v-cr/**`, `lib/cr-helpers.sh` |\n' | index
    printf 'lib/cr-helpers.sh\t10\t2\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [ "$status" -eq 0 ]
    [[ "$output" == *"applies	automated-cr-safety	lib/cr-helpers.sh"* ]]
}

@test "cr_rule_route emits no-match when a glob-shaped row reaches nothing in the diff" {
    printf '| [[pin-pipx-python]] | Pin pipx tools | `setup.sh`, `lib/installers.sh` |\n' | index
    printf 'lib/cr-helpers.sh\t10\t2\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [ "$status" -eq 0 ]
    [[ "$output" == *"no-match	pin-pipx-python"* ]]
    [[ "$output" != *"unroutable	pin-pipx-python"* ]]
}

@test "cr_rule_route emits unroutable and rc 1 for a cell holding only prose" {
    printf '| [[queue-jobs-idempotent]] | Every queued job is idempotent | queue jobs |\n' | index
    printf 'lib/cr-helpers.sh\t10\t2\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [ "$status" -eq 1 ]
    [[ "$output" == *"unroutable	queue-jobs-idempotent"* ]]
}

# --- cr_rule_route: the two rows that break a naive parser -----------------
#
# Both are copied verbatim out of vault/indications/_index.md. A fixture written by hand would not
# have found either fault, because the hand writing it is the hand that would have got it wrong.

@test "cr_rule_route keeps a brace group as one row, not six fragments" {
    printf '%s\n' '| [[business-persona-family]] | Business packs are opt-in lenses grounded in installed skills; numbers route to `business/data-evidence`; multi-pack seating keeps one architect seat | `personas/{sales,seo,support,business,startup-eval,marketing}.md`, `personas/_shared/business/**`, `personas/_resolution.md` |' | index
    printf 'personas/seo.md\t4\t0\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [ "$status" -eq 0 ]
    [[ "$output" == *"applies	business-persona-family	personas/seo.md"* ]]
    # The fragments a comma split would leave behind must not appear as rules of their own.
    [[ "$output" != *"unroutable	seo"* ]]
    [ "$(printf '%s\n' "$output" | grep -c 'business-persona-family')" -eq 1 ]
}

@test "cr_rule_route survives an escaped pipe inside the Rule cell" {
    printf '%s\n' '| [[gate-prompts-on-stdin-tty]] | Gate interactive prompts on `[ -t 0 ]` before reading `/dev/tty` — a piped run (`curl \| bash`, CI, bats) has a terminal but no answerer and would hang; the non-interactive branch must be the conservative one, and testing the real prompt needs a pty (`script -qec`) | `setup.sh`, `install.sh`, `bin/*.sh`, `lib/installers.sh` |' | index
    printf 'lib/installers.sh\t3\t1\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [ "$status" -eq 0 ]
    [[ "$output" == *"applies	gate-prompts-on-stdin-tty	lib/installers.sh"* ]]
}

# --- cr_rule_route: the surface channel ------------------------------------

@test "cr_rule_route routes a declared scope value on the surface channel, never unroutable" {
    printf '| [[api-contract-versioning]] | Version every published contract | api.givore.com |\n' | index
    printf 'lib/cr-helpers.sh\t10\t2\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed" 'api.givore.com,cross-repo'
    [ "$status" -eq 0 ]
    [[ "$output" == *"applies	api-contract-versioning	-"* ]]
    [[ "$output" != *"unroutable"* ]]
}

@test "cr_rule_route buckets an unmatched glob row on the surface channel when a scope value is also present" {
    printf '| [[cross-repo-enums]] | Enums stay in sync across repos | `app/Enums/**`, cross-repo |\n' | index
    printf 'lib/cr-helpers.sh\t10\t2\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed" 'cross-repo'
    [ "$status" -eq 0 ]
    [[ "$output" == *"applies	cross-repo-enums	-"* ]]
}

# --- cr_rule_route: input handling ----------------------------------------

@test "cr_rule_route exits 2 and names the reason when no applies-to header exists" {
    {
        printf '| Slug | Rule | Notes |\n'
        printf '|------|------|-------|\n'
        printf '| [[a-rule]] | something | `lib/**` |\n'
    } > "$TMP/index"
    printf 'lib/cr-helpers.sh\t1\t0\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [ "$status" -eq 2 ]
    [[ "$output" == *"applies-to"* ]]
}

@test "cr_rule_route finds the column under any of its three spellings" {
    for header in 'Applies-to' 'applies-to' 'scope'; do
        {
            printf '| Slug | Rule | %s |\n' "$header"
            printf '|------|------|------|\n'
            printf '| [[a-rule]] | something | `lib/**` |\n'
        } > "$TMP/index"
        printf 'lib/cr-helpers.sh\t1\t0\n' > "$TMP/changed"

        run cr_rule_route "$TMP/index" "$TMP/changed"
        [ "$status" -eq 0 ]
        [[ "$output" == *"applies	a-rule	lib/cr-helpers.sh"* ]]
    done
}

@test "cr_rule_route tolerates CRLF line endings" {
    printf '| Slug | Rule | Applies-to |\r\n|---|---|---|\r\n| [[a-rule]] | x | `lib/**` |\r\n' > "$TMP/index"
    printf 'lib/cr-helpers.sh\t1\t0\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [ "$status" -eq 0 ]
    [[ "$output" == *"applies	a-rule	lib/cr-helpers.sh"* ]]
}

@test "cr_rule_route reads a changed-file path containing a tab" {
    printf '| [[a-rule]] | x | `lib/**` |\n' | index
    printf 'lib/od%sd.sh\t1\t0\n' "$(printf '\t')" > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [ "$status" -eq 0 ]
    [[ "$output" == *"applies	a-rule	lib/od$(printf '\t')d.sh"* ]]
}

@test "cr_rule_route returns zero counts for an empty index and an empty changed list" {
    cat "$TMP/index-head" > "$TMP/index"
    : > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [ "$status" -eq 0 ]
    [ -z "$(printf '%s' "$output" | tr -d '[:space:]')" ]
}

@test "cr_rule_route returns 2 on unreadable input" {
    run cr_rule_route "$TMP/nope" "$TMP/also-nope"
    [ "$status" -eq 2 ]
}

@test "cr_rule_route puts every row in exactly one bucket" {
    {
        printf '| [[hit]] | x | `lib/**` |\n'
        printf '| [[miss]] | x | `app/**` |\n'
        printf '| [[prose]] | x | queue jobs |\n'
        printf '| [[both]] | x | `app/**`, cross-repo |\n'
    } | index
    printf 'lib/cr-helpers.sh\t1\t0\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed" 'cross-repo'
    [ "$(printf '%s\n' "$output" | grep -cE '^(applies|no-match|unroutable)\b')" -eq 4 ]
}

@test "cr_rule_route never shrinks the applies set when an unrelated file is added" {
    printf '| [[a-rule]] | x | `lib/**` |\n' | index
    printf 'lib/cr-helpers.sh\t1\t0\n' > "$TMP/changed"
    run cr_rule_route "$TMP/index" "$TMP/changed"
    before=$(printf '%s\n' "$output" | grep -c '^applies')

    printf 'README.md\t1\t0\n' >> "$TMP/changed"
    run cr_rule_route "$TMP/index" "$TMP/changed"
    after=$(printf '%s\n' "$output" | grep -c '^applies')
    [ "$before" -eq 1 ]
    [ "$after" -ge "$before" ]
}

# --- cr_anchor_check -------------------------------------------------------

diff_fixture() {
    cat > "$TMP/diff" <<'DIFF'
--- a/lib/cr-helpers.sh
+++ b/lib/cr-helpers.sh
@@ -10,0 +11,2 @@
+cr_rule_route() {
+    local index="${1:-}"
DIFF
}

@test "cr_anchor_check accepts an anchor whose token really is on the named line" {
    diff_fixture
    printf 'holds\tlib/cr-helpers.sh:L11:"cr_rule_route() {"\tautomated-cr-safety\n' > "$TMP/receipt"

    run cr_anchor_check "$TMP/diff" "$TMP/receipt"
    [ "$status" -eq 0 ]
    [[ "$output" != *"bad-anchor"* ]]
}

@test "cr_anchor_check rejects a token that is not on the line it names" {
    diff_fixture
    printf 'holds\tlib/cr-helpers.sh:L11:"cr_anchor_check"\tautomated-cr-safety\n' > "$TMP/receipt"

    run cr_anchor_check "$TMP/diff" "$TMP/receipt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"bad-anchor	automated-cr-safety"* ]]
}

@test "cr_anchor_check rejects a line number outside every hunk" {
    diff_fixture
    printf 'holds\tlib/cr-helpers.sh:L900:"cr_rule_route() {"\tautomated-cr-safety\n' > "$TMP/receipt"

    run cr_anchor_check "$TMP/diff" "$TMP/receipt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"bad-anchor	automated-cr-safety"* ]]
}

@test "cr_anchor_check rejects a path the diff never touched" {
    diff_fixture
    printf 'holds\tbin/doc-lint.sh:L11:"cr_rule_route() {"\tautomated-cr-safety\n' > "$TMP/receipt"

    run cr_anchor_check "$TMP/diff" "$TMP/receipt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"bad-anchor	automated-cr-safety"* ]]
}

@test "cr_anchor_check requires a trigger clause on an n/a verdict but no code anchor" {
    diff_fixture
    printf 'n/a\tthe rule fires only on a migration under database/migrations, and none changed\tpin-pipx-python\n' > "$TMP/ok"
    run cr_anchor_check "$TMP/diff" "$TMP/ok"
    [ "$status" -eq 0 ]

    printf 'n/a\t\tpin-pipx-python\n' > "$TMP/empty"
    run cr_anchor_check "$TMP/diff" "$TMP/empty"
    [ "$status" -eq 1 ]
    [[ "$output" == *"bad-anchor	pin-pipx-python"* ]]
}

@test "cr_anchor_check verifies a FILES_EXAMINED read row against the same diff" {
    diff_fixture
    printf 'read\tL11:"cr_rule_route() {"\tlib/cr-helpers.sh\n' > "$TMP/good"
    run cr_anchor_check "$TMP/diff" "$TMP/good"
    [ "$status" -eq 0 ]

    printf 'read\tL11:"never appeared"\tlib/cr-helpers.sh\n' > "$TMP/bad"
    run cr_anchor_check "$TMP/diff" "$TMP/bad"
    [ "$status" -eq 1 ]
    [[ "$output" == *"bad-anchor	lib/cr-helpers.sh"* ]]
}

@test "cr_anchor_check leaves non-read FILES_EXAMINED rows alone" {
    diff_fixture
    printf 'skipped\tout of my assignment\tlib/cr-helpers.sh\n' > "$TMP/receipt"
    run cr_anchor_check "$TMP/diff" "$TMP/receipt"
    [ "$status" -eq 0 ]
}

# --- cr_rule_coverage ------------------------------------------------------

routes_fixture() {
    printf 'applies\tautomated-cr-safety\tlib/cr-helpers.sh\n' > "$TMP/routes"
    printf 'applies\tpin-pipx-python\tsetup.sh\n' >> "$TMP/routes"
    printf 'no-match\tguard-home-derived-deletes\n' >> "$TMP/routes"
    printf 'unroutable\tqueue-jobs-idempotent\n' >> "$TMP/routes"
}

@test "cr_rule_coverage counts a routed rule with no verdict as routed-unchecked and returns 1" {
    routes_fixture
    printf 'holds\tlib/cr-helpers.sh:L11:"x"\tautomated-cr-safety\n' > "$TMP/checked"
    : > "$TMP/bad"

    run cr_rule_coverage "$TMP/routes" "$TMP/checked" "$TMP/bad"
    [ "$status" -eq 1 ]
    [[ "$output" == *"routed-unchecked	1"* ]]
    [[ "$output" == *"routed-unchecked	pin-pipx-python"* ]]
}

@test "cr_rule_coverage returns 0 when every routed rule is verdicted, even with unroutable rows present" {
    routes_fixture
    {
        printf 'holds\tlib/cr-helpers.sh:L11:"x"\tautomated-cr-safety\n'
        printf 'breaks\tsetup.sh:L4:"y"\tpin-pipx-python\n'
    } > "$TMP/checked"
    : > "$TMP/bad"

    run cr_rule_coverage "$TMP/routes" "$TMP/checked" "$TMP/bad"
    [ "$status" -eq 0 ]
    [[ "$output" == *"unroutable	1"* ]]
    [[ "$output" == *"checked	2"* ]]
}

@test "cr_rule_coverage counts a bad-anchored verdict as unchecked" {
    routes_fixture
    {
        printf 'holds\tlib/cr-helpers.sh:L11:"x"\tautomated-cr-safety\n'
        printf 'holds\tsetup.sh:L4:"y"\tpin-pipx-python\n'
    } > "$TMP/checked"
    printf 'bad-anchor\tpin-pipx-python\tsetup.sh:L4:"y"\ttoken not on line\n' > "$TMP/bad"

    run cr_rule_coverage "$TMP/routes" "$TMP/checked" "$TMP/bad"
    [ "$status" -eq 1 ]
    [[ "$output" == *"routed-unchecked	pin-pipx-python"* ]]
}

@test "cr_rule_coverage does not let an all-n/a receipt reach full checked" {
    routes_fixture
    {
        printf 'n/a\ttrigger is a migration; none changed\tautomated-cr-safety\n'
        printf 'n/a\ttrigger is a pipx install; none changed\tpin-pipx-python\n'
    } > "$TMP/checked"
    : > "$TMP/bad"

    run cr_rule_coverage "$TMP/routes" "$TMP/checked" "$TMP/bad"
    [ "$status" -eq 0 ]
    [[ "$output" == *"checked	0"* ]]
    [[ "$output" == *"n-a	2"* ]]
}

@test "cr_rule_coverage resolves one slug verdicted twice as the stronger verdict" {
    printf 'applies\tautomated-cr-safety\tlib/cr-helpers.sh\n' > "$TMP/routes"
    {
        printf 'holds\tlib/cr-helpers.sh:L11:"x"\tautomated-cr-safety\n'
        printf 'breaks\tlib/cr-helpers.sh:L12:"y"\tautomated-cr-safety\n'
    } > "$TMP/checked"
    : > "$TMP/bad"

    run cr_rule_coverage "$TMP/routes" "$TMP/checked" "$TMP/bad"
    [ "$status" -eq 0 ]
    [[ "$output" == *"breaks	automated-cr-safety"* ]]
}

@test "cr_rule_coverage lets an anchored holds outrank a bad-anchored breaks" {
    printf 'applies\tautomated-cr-safety\tlib/cr-helpers.sh\n' > "$TMP/routes"
    {
        printf 'breaks\t\tautomated-cr-safety\n'
        printf 'holds\tlib/cr-helpers.sh:L11:"x"\tautomated-cr-safety\n'
    } > "$TMP/checked"
    printf 'bad-anchor\tautomated-cr-safety\t\tno anchor on a breaks verdict\n' > "$TMP/bad"

    run cr_rule_coverage "$TMP/routes" "$TMP/checked" "$TMP/bad"
    [ "$status" -eq 0 ]
    [[ "$output" == *"checked	1"* ]]
    [[ "$output" != *"breaks	automated-cr-safety"* ]]
}

@test "cr_rule_coverage returns 2 on unreadable input" {
    run cr_rule_coverage "$TMP/nope" "$TMP/nope2" "$TMP/nope3"
    [ "$status" -eq 2 ]
}

@test "cr_rule_route skips the header of a second table instead of inventing a rule called slug" {
    {
        printf '| Slug | Rule | Applies-to |\n'
        printf '|------|------|------------|\n'
        printf '| [[a-rule]] | x | `lib/**` |\n'
        printf '\n## A second table\n\n'
        printf '| slug | one-line rule | applies-to |\n'
        printf '|------|---------------|------------|\n'
        printf '| [[b-rule]] | y | `bin/**` |\n'
    } > "$TMP/index"
    printf 'lib/cr-helpers.sh\t1\t0\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [ "$status" -eq 0 ]
    [[ "$output" != *"slug"* ]]
    [[ "$output" == *"applies	a-rule	lib/cr-helpers.sh"* ]]
    [[ "$output" == *"no-match	b-rule"* ]]
}

@test "cr_anchor_check verifies BOTH receipts when given both" {
    diff_fixture
    printf 'read\tL11:"cr_rule_route() {"\tlib/cr-helpers.sh\n' > "$TMP/files"
    printf 'holds\tlib/cr-helpers.sh:L11:"never appeared"\tautomated-cr-safety\n' > "$TMP/rules"

    # The rule receipt alone is rejected.
    run cr_anchor_check "$TMP/diff" "$TMP/rules"
    [ "$status" -eq 1 ]

    # Given both, the bad rule anchor must still be caught — checking only the first receipt would
    # leave every rule verdict unverified and the rule-coverage gate permanently green.
    run cr_anchor_check "$TMP/diff" "$TMP/files" "$TMP/rules"
    [ "$status" -eq 1 ]
    [[ "$output" == *"bad-anchor	automated-cr-safety"* ]]
}

@test "cr_anchor_check returns 2 when given a diff and no receipt at all" {
    diff_fixture
    run cr_anchor_check "$TMP/diff"
    [ "$status" -eq 2 ]
}

# --- the defects a whitespace anchor and a merge diff used to slip through ----

@test "cr_rule_coverage rejects a whitespace-only anchor, not just an empty one" {
    diff_fixture
    printf 'applies\tautomated-cr-safety\tlib/cr-helpers.sh\n' > "$TMP/routes"
    printf 'breaks\t \tautomated-cr-safety\n' > "$TMP/checked"      # anchor is one space
    cr_anchor_check "$TMP/diff" "$TMP/checked" > "$TMP/bad" || true

    run cr_rule_coverage "$TMP/routes" "$TMP/checked" "$TMP/bad"
    [ "$status" -eq 1 ]
    [[ "$output" == *"routed-unchecked	automated-cr-safety"* ]]
}

@test "cr_anchor_check reads the new-file line numbers of a combined merge diff" {
    cat > "$TMP/mdiff" <<'DIFF'
--- a/m.txt
+++ b/m.txt
@@@ -1,2 -1,2 +1,2 @@@
++merged line
DIFF
    printf 'holds\tm.txt:L1:"merged line"\ta-rule\n' > "$TMP/receipt"
    run cr_anchor_check "$TMP/mdiff" "$TMP/receipt"
    [ "$status" -eq 0 ]
}

@test "cr_rule_route expands a token holding two brace groups" {
    printf '| [[two-group]] | x | `personas/{a,seo}/{b,c}.md` |\n' | index
    printf 'personas/a/b.md\t1\t0\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [ "$status" -eq 0 ]
    [[ "$output" == *"applies	two-group	personas/a/b.md"* ]]
}

@test "cr_rule_route still reaches the later tokens of a cell with an unterminated brace" {
    printf '| [[unterm]] | x | `personas/{a,b.md`, `lib/cr-helpers.sh` |\n' | index
    printf 'lib/cr-helpers.sh\t1\t0\n' > "$TMP/changed"

    run cr_rule_route "$TMP/index" "$TMP/changed"
    [[ "$output" == *"applies	unterm	lib/cr-helpers.sh"* ]]
}

@test "cr_coverage drops a read row whose anchor cr_anchor_check rejected" {
    diff_fixture
    printf 'lib/cr-helpers.sh\t2\t0\n' > "$TMP/changed"
    printf 'read\tL11:"never appeared"\tlib/cr-helpers.sh\n' > "$TMP/receipt"
    : > "$TMP/findings"
    cr_anchor_check "$TMP/diff" "$TMP/receipt" > "$TMP/bad" || true

    # Without the bad-anchor set the fabricated row still counts as examined.
    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings"
    [[ "$output" == *"clean	1"* ]]

    run cr_coverage "$TMP/changed" "$TMP/receipt" "$TMP/findings" "$TMP/bad"
    [ "$status" -eq 1 ]
    [[ "$output" == *"unexamined	1"* ]]
}

@test "T-12 the audit checks an indication's probe key against the registries" {
    run "${VAULT_ROOT:-/code}/checks/probe-panel-SC-5.sh"
    [ "$status" -eq 0 ] || { echo "$output"; false; }
}
