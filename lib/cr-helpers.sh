#!/usr/bin/env bash
# lib/cr-helpers.sh — pure helpers for /v-cr: comment fingerprints, task-key extraction,
# changeset measurement, and post-delivery verification.
# No network, no side effects. Sourced into the caller's shell; written to behave identically
# under bash and zsh (no reliance on IFS word-splitting). Unit-tested in tests/unit/v-cr.bats
# and tests/unit/cr-coverage.bats.

# cr_code_hash — read hunk/source content on stdin, print a stable sha256. Used as the
# line-number-INDEPENDENT component of a comment fingerprint so a finding survives rebases /
# line shifts (skeptic-2).
cr_code_hash() {
    sha256sum | cut -d' ' -f1
}

# cr_fingerprint <file> <rule> <code_hash> — the idempotency key for a posted comment.
# Keyed ONLY on stable signals (file path, rule id, hashed offending code) — NEVER on the
# LLM-generated message, which varies run-to-run and would defeat dedup (skeptic-2). Two runs
# over the same hunk therefore produce the same fingerprint regardless of comment wording.
cr_fingerprint() {
    printf '%s:%s:%s' "$1" "$2" "$3" | sha256sum | cut -d' ' -f1
}

# cr_jira_keys <text> — extract VALIDATED Jira issue keys from <text> (which the caller must
# limit to the branch name + PR title — never the body or diff; skeptic-4). A candidate
# [A-Z][A-Z0-9]+-[0-9]+ is emitted only if its project prefix is in VCR_JIRA_PROJECTS (a
# ';'-separated allowlist of the user's real project keys). With no allowlist, nothing is
# emitted — this is what stops UTF-8 / SHA-256 / HTTP2-1 / RELEASE-2 from being mistaken for
# tickets and silently grounding the review against the wrong issue. Output is deduped.
cr_jira_keys() {
    local text="$1" allow="${VCR_JIRA_PROJECTS:-}" key proj
    [ -n "$allow" ] || return 0
    printf '%s\n' "$text" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | while IFS= read -r key; do
        proj="${key%%-*}"
        case ";${allow};" in
            *";${proj};"*) printf '%s\n' "$key" ;;
        esac
    done | awk '!seen[$0]++'
}

# cr_asana_gids <text> — extract Asana task GIDs from task URLs in <text> (branch + title +
# body permitted: Asana refs are explicit URLs, not ambient tokens). Handles the legacy
# app.asana.com/0/<project>/<task> and the newer /1/.../task/<task> forms; emits the trailing
# task GID. The Asana task itself is fetched via the Asana MCP (commands/v-cr/tasks/asana.md).
cr_asana_gids() {
    printf '%s\n' "$1" \
        | grep -oE 'app\.asana\.com/[0-9]+/[0-9/a-z]*[0-9]+' \
        | grep -oE '[0-9]+$' \
        | awk '!seen[$0]++'
}

# cr_diff_stats — read a changed-file list on stdin as "<path><TAB><added><TAB><deleted>" rows
# (one per file, the shape `gh api .../pulls/<n>/files --jq` emits) and print
# "<files><TAB><added><TAB><deleted><TAB><changed_lines>".
#
# This is the measurement `03-review.md` §3.2's large-diff guard was written against and never
# had: with no way to compute diff size, the guard could not fire, and a 523-file changeset was
# reviewed as though it were a small one. Blank and malformed rows are ignored rather than
# aborting — a partial file list must still yield a number the caller can act on.
cr_diff_stats() {
    awk -F'\t' '
        { sub(/\r$/, "") }              # a CRLF row would fail the digit test and silently count 0
        # Counts are the LAST two fields, never $2/$3: a path may itself contain a tab, which
        # shifts every field right and drops the file plus its lines from the total in silence.
        NF >= 3 && $(NF-1) ~ /^[0-9]+$/ && $NF ~ /^[0-9]+$/ { n++; a += $(NF-1); d += $NF }
        END { printf "%d\t%d\t%d\t%d\n", n, a, d, a + d }
    '
}

# cr_verify_posted <intended_file> <actual_file> — the delivery read-back.
# Both arguments are files of fingerprints, one per line (<intended> = what the run meant to
# post; <actual> = what listing the PR afterwards returned). Prints one row per discrepancy:
#   "missing<TAB><fp>"  — intended but absent from the forge (a post that silently failed)
#   "extra<TAB><fp>"    — present on the forge but not intended this run
# Exit status 0 when the two sets match exactly, 1 when they do not.
#
# The caller MUST treat rc 1 as an error. `/v-cr` previously asserted its own success
# ("Posted: <n> inline + summary"), so a failed post was recorded in the vault as delivered.
# cr_vault_leak_check <comment_body_file> <indication_file>... — the fork/public egress control.
# Prints "leak<TAB><indication_file><TAB><matched text>" for each rule file whose wording appears
# verbatim in the comment body; exit 0 when clean, 1 when anything leaked, 2 on unreadable input.
#
# On a fork or public PR a critic may cite a project rule by slug but never by its text
# (03-review.md §3.3), because the rule bodies are private vault content and the comment is public.
# An instruction alone does not stop a critic that quotes the rule anyway, so this runs at the
# write boundary (04-post.md §4.2).
#
# Method: slide a window of $CR_LEAK_SHINGLE (default 40) characters over each indication's prose
# and look for any window occurring literally in the comment. Whitespace is collapsed first so a
# re-wrapped quote still matches. Short shared phrases stay under the window and do not trip it.
cr_vault_leak_check() {
    local body="${1:-}"; shift 2>/dev/null || true
    [ -r "$body" ] || return 2
    [ "$#" -gt 0 ] || return 0

    local n="${CR_LEAK_SHINGLE:-40}" rc=0 rule flat rflat len i win
    flat="$(tr -s '[:space:]' ' ' < "$body")"

    for rule in "$@"; do
        [ -r "$rule" ] || continue
        # Frontmatter and markdown syntax are shared by every file; compare prose only.
        rflat="$(sed '1{/^---$/,/^---$/d}' "$rule" | tr -s '[:space:]' ' ' | tr -d '`*#|[]')"
        len=${#rflat}
        [ "$len" -ge "$n" ] || continue
        i=0
        while [ "$i" -le $((len - n)) ]; do
            win="${rflat:$i:$n}"
            case "$flat" in
                *"$win"*)
                    printf 'leak\t%s\t%s\n' "$rule" "$win"
                    rc=1
                    break ;;
            esac
            i=$((i + 8))                 # stride: a real quote is far longer than the window
        done
    done
    return "$rc"
}

cr_verify_posted() {
    local intended="${1:-}" actual="${2:-}" rc=0 fp
    [ -r "$intended" ] && [ -r "$actual" ] || return 2

    local i_sorted a_sorted
    i_sorted="$(sort -u "$intended")"
    a_sorted="$(sort -u "$actual")"

    # `while read` rather than an unquoted expansion: zsh does not word-split unquoted
    # parameters, so `printf ... $missing` would emit one blob under zsh and N rows under bash.
    while IFS= read -r fp; do
        [ -n "$fp" ] || continue
        printf 'missing\t%s\n' "$fp"
        rc=1
    done <<EOF
$(printf '%s\n' "$i_sorted" | comm -23 - <(printf '%s\n' "$a_sorted"))
EOF

    while IFS= read -r fp; do
        [ -n "$fp" ] || continue
        printf 'extra\t%s\n' "$fp"
        rc=1
    done <<EOF
$(printf '%s\n' "$i_sorted" | comm -13 - <(printf '%s\n' "$a_sorted"))
EOF

    return "$rc"
}

# cr_coverage <changed_file_list> <receipt_file> <findings_paths_file> — the review-side
# read-back, the mirror of cr_verify_posted.
#
#   <changed_file_list>   cr_diff_stats rows: <path><TAB><added><TAB><deleted>
#   <receipt_file>        merged critic FILES_EXAMINED rows: <evidence><TAB><reason><TAB><path>
#   <findings_paths_file> one bare path per line, each carrying a confirmed finding
#
# Prints three counts, then one row per problem path:
#   with_findings<TAB>n · clean<TAB>n · unexamined<TAB>n
#   unexamined<TAB><path>   — a changed file no critic read
#   extra<TAB><path>        — a receipt path outside the changeset (context rows are exempt)
# Exit 0 when every changed file was read and nothing is extra, 1 otherwise, 2 on unreadable input.
#
# Why this exists: the panel's finding schema returns findings, so "no comment on this file" meant
# both "examined and clean" and "never opened". `files_entered_context` was a field with no
# measurement behind it and got asserted — one run recorded 33 against a true 41 of 48, and the
# seven files nobody had read held two real findings.
#
# Only `read` counts as examined. `diff-only`, `grep-only` and `skipped` report unexamined with
# their reason, because the rule that a grep is not a read has to reach the number the gate reads.
# `context` marks a subject-under-test pulled in from outside the changeset — never `extra`, never
# examined-coverage for a changed file.
cr_coverage() {
    local changed="${1:-}" receipt="${2:-}" findings="${3:-}" bad="${4:-}"
    [ -r "$changed" ] && [ -r "$receipt" ] && [ -r "$findings" ] || return 2
    # Optional fourth input: cr_anchor_check's output. Without it a critic that fabricates a
    # read anchor is flagged and still counted examined, and the anchor rule measures nothing.
    if [ -z "$bad" ] || [ ! -r "$bad" ]; then
        bad=$(mktemp) || return 2
        # shellcheck disable=SC2064
        trap "rm -f '$bad'" RETURN
    fi

    # Files are identified by FILENAME, never by a first-line counter: an empty changed-file
    # list never fires FNR==1, and every receipt row would then be parsed as a changed file.
    awk -F'\t' -v C="$changed" -v R="$receipt" -v F="$findings" -v B="$bad" '
        function rank(e) {
            if (e == "read")      return 5
            if (e == "context")   return 4
            if (e == "diff-only") return 3
            if (e == "grep-only") return 2
            if (e == "skipped")   return 1
            return 0
        }
        { sub(/\r$/, "") }          # a CRLF row would mismatch every path and report 100% unread

        # The changed-file list: counts are the LAST two fields, so a path containing a tab keeps
        # its own tabs instead of shifting the row and vanishing (same rule as cr_diff_stats).
        FILENAME == C && NF >= 3 && $(NF-1) ~ /^[0-9]+$/ && $NF ~ /^[0-9]+$/ {
            p = $1
            for (i = 2; i <= NF - 2; i++) p = p FS $i
            if (!(p in isChanged)) { isChanged[p] = 1; order[++n] = p }
            next
        }

        # A receipt row: the reason is variable-length, so the path is last and unbounded.
        # Duplicate paths across critics resolve strongest-evidence-wins.
        FILENAME == B && $1 == "bad-anchor" { rejected[$2, $3] = 1; next }

        FILENAME == R && NF >= 3 {
            p = $3
            for (i = 4; i <= NF; i++) p = p FS $i
            r = rank($1)
            if ((p SUBSEP $2) in rejected) r = 0
            if (!(p in best)) { rorder[++m] = p; best[p] = r }
            else if (r > best[p]) best[p] = r
            next
        }

        FILENAME == F && $0 != "" { hasFinding[$0] = 1; next }

        END {
            withFindings = 0; clean = 0; unexamined = 0
            for (i = 1; i <= n; i++) {
                p = order[i]
                if (best[p] == 5) {
                    if (p in hasFinding) withFindings++; else clean++
                } else {
                    unexamined++; miss[++u] = p
                }
            }
            printf "with_findings\t%d\n", withFindings
            printf "clean\t%d\n",         clean
            printf "unexamined\t%d\n",    unexamined
            for (i = 1; i <= u; i++) printf "unexamined\t%s\n", miss[i]

            extra = 0
            for (i = 1; i <= m; i++) {
                p = rorder[i]
                # A context row is a deliberate out-of-changeset read, not a stray path.
                if (!(p in isChanged) && best[p] != 4) { printf "extra\t%s\n", p; extra++ }
            }
            exit (unexamined > 0 || extra > 0) ? 1 : 0
        }
    ' "$bad" "$changed" "$receipt" "$findings"
}

# ---------------------------------------------------------------------------
# Indication routing — which project rules can this changeset break, and did
# anyone actually decide?
#
# The indication index carries an Applies-to column that nothing read. Rule
# bodies were therefore fetched when a file happened to remind a critic of one,
# so a review that cited four rules out of a hundred and forty-nine reported
# nothing about the other hundred and forty-five and looked identical to a
# review that had checked them all.
# ---------------------------------------------------------------------------

# cr_rule_route <index> <changed_files> [scopes_csv]
#
# Buckets every index row exactly once: `applies` (a glob reached a changed
# path, or the cell names a declared surface), `no-match` (glob-shaped and
# reached nothing) or `unroutable` (neither). rc 0 all routed · 1 some row is
# unroutable · 2 bad input.
#
# Written for mawk: no gensub, no GNU extensions. The column is found by header
# name, never by position — the header is spelled `Applies-to` in three project
# indexes, `applies-to` in seven and `scope` in one, and falling through to a
# position would route the slug column on the eighth.
cr_rule_route() {
    local index="${1:-}" changed="${2:-}" scopes="${3:-}"
    [ -r "$index" ] && [ -r "$changed" ] || return 2

    awk -F'\t' -v IDX="$index" -v SCOPES="$scopes" '
        function esc(c) { return (index(".^$+(){}[]|\\", c) > 0) ? "\\" c : c }

        # A glob is translated once, here, so two readings of `commands/v-cr/**`
        # cannot produce two different route sets: ** crosses a slash, * does not.
        function glob2re(g,   i, n, c, out) {
            out = "^"; n = length(g)
            for (i = 1; i <= n; i++) {
                c = substr(g, i, 1)
                if (c == "*") {
                    if (substr(g, i + 1, 1) == "*") { out = out ".*"; i++ }
                    else out = out "[^/]*"
                }
                else if (c == "?") out = out "[^/]"
                else out = out esc(c)
            }
            return out "$"
        }

        # Split the cell on commas, semicolons and spaces that are NOT inside a
        # brace group, so `personas/{sales,seo}.md` survives as one token.
        function splitcell(cell, toks,   i, n, c, depth, cur, k) {
            k = 0; cur = ""; depth = 0; n = length(cell)
            for (i = 1; i <= n; i++) {
                c = substr(cell, i, 1)
                if (c == "{") depth++
                else if (c == "}") { if (depth > 0) depth-- }
                if ((c == "," || c == ";" || c == " ") && depth == 0) {
                    if (cur != "") { toks[++k] = cur; cur = "" }
                } else cur = cur c
            }
            if (cur != "") toks[++k] = cur
            # A malformed cell (an unterminated group) would otherwise swallow every later
            # token into one unmatchable string, and report the rules it names unreachable.
            if (depth != 0) {
                k = split(cell, toks, /[ ,;]+/)
                while (k > 0 && toks[k] == "") k--
            }
            return k
        }

        # personas/{a,b}.md -> personas/a.md personas/b.md
        function expand(tok, out,   p1, p2, pre, mid, post, i, n, parts, k, work, nw, j, guard) {
            work[1] = tok; nw = 1; guard = 0
            # Loop until no token still holds a group: one pass expands only the first
            # group, and a two-group cell would silently miss the rule it names.
            while (guard++ < 12) {
                k = 0; delete out
                for (j = 1; j <= nw; j++) {
                    p1 = index(work[j], "{")
                    p2 = (p1 ? index(substr(work[j], p1), "}") : 0)
                    if (p1 == 0 || p2 == 0) { out[++k] = work[j]; continue }
                    p2 = p1 + p2 - 1
                    pre = substr(work[j], 1, p1 - 1)
                    mid = substr(work[j], p1 + 1, p2 - p1 - 1)
                    post = substr(work[j], p2 + 1)
                    n = split(mid, parts, ",")
                    for (i = 1; i <= n; i++) out[++k] = pre parts[i] post
                }
                if (k == nw) return k
                nw = k
                for (j = 1; j <= k; j++) work[j] = out[j]
            }
            return nw
        }

        function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

        BEGIN {
            hdr = -1
            ns = split(SCOPES, sc, ",")
            for (i = 1; i <= ns; i++) { v = trim(sc[i]); if (v != "") isScope[v] = 1 }
        }

        { sub(/\r$/, "") }

        # The changed-file list. Counts are the last two fields, so a path
        # containing a tab keeps its own tabs (same rule as cr_diff_stats).
        FILENAME != IDX {
            if (NF < 3) next
            if ($(NF-1) !~ /^[0-9]+$/ || $NF !~ /^[0-9]+$/) next
            p = $1
            for (i = 2; i <= NF - 2; i++) p = p FS $i
            paths[++np] = p
            next
        }

        # The index. An escaped pipe inside a Rule cell would shift every field
        # after it, so it is neutralised before the row is split at all.
        FILENAME == IDX {
            line = $0
            if (line !~ /^[ \t]*\|/) next
            gsub(/\\\|/, " ", line)
            nf = split(line, f, "|")

            # A header row: the first one, and every later one too. An index often holds several
            # tables, and treating a later header as data invents a rule named `slug` and then
            # reports it unroutable — an unreachable rule that does not exist.
            first = trim(f[2]); gsub(/`/, "", first); first = tolower(first)
            if (hdr < 0 || first == "slug" || first == "rule" || first == "name" || first == "id") {
                for (i = 1; i <= nf; i++) {
                    h = trim(f[i]); gsub(/`/, "", h); h = tolower(h)
                    if (h == "applies-to" || h == "applies to" || h == "scope") { hdr = i; break }
                }
                next
            }

            sep = 1
            for (i = 2; i < nf; i++) if (trim(f[i]) !~ /^:?-+:?$/) sep = 0
            if (sep && nf > 2) next

            slug = trim(f[2]); gsub(/`/, "", slug)
            sub(/^\[\[/, "", slug); sub(/\]\]$/, "", slug)
            if (slug == "") next

            cell = (hdr <= nf) ? trim(f[hdr]) : ""
            gsub(/`/, "", cell)

            nt = splitcell(cell, toks)
            hasGlob = 0; hasSurface = 0; hit = ""
            for (t = 1; t <= nt; t++) {
                ne = expand(toks[t], ex)
                for (e = 1; e <= ne; e++) {
                    tok = trim(ex[e])
                    if (tok == "") continue
                    if (tok in isScope) { hasSurface = 1; continue }
                    if (tok !~ /[\/*.]/) continue
                    hasGlob = 1
                    if (hit != "") continue
                    re = glob2re(tok)
                    for (q = 1; q <= np; q++) if (paths[q] ~ re) { hit = paths[q]; break }
                }
            }

            if (hit != "")          printf "applies\t%s\t%s\n", slug, hit
            else if (hasSurface)    printf "applies\t%s\t-\n", slug
            else if (hasGlob)     { printf "no-match\t%s\n", slug }
            else                  { printf "unroutable\t%s\n", slug; unroutable++ }
            next
        }

        END {
            if (hdr < 0) {
                printf "no applies-to column: the header names none of applies-to, applies to, scope\n" > "/dev/stderr"
                exit 2
            }
            exit (unroutable > 0) ? 1 : 0
        }
    ' "$changed" "$index"
}

# cr_anchor_check <diff> <receipt>...
#
# Decides whether a citation resolves. Emits one
# `bad-anchor<TAB><slug-or-path><TAB><anchor><TAB><reason>` row per failure.
# rc 0 every anchor resolves · 1 some do not · 2 bad input.
#
# It takes MORE THAN ONE receipt because the panel produces two — FILES_EXAMINED
# and RULES_CHECKED — and they share one failure: a critic that echoes back the
# list it was given scores perfect coverage. Verifying only the first receipt
# leaves every rule verdict unchecked and the rule-coverage gate permanently
# green, which is the whole defect this pair of functions exists to close.
#
# A `read` row and a `breaks`/`holds` row must each name a line that exists in
# the diff and quote a token really on it. `n/a` is the exception — it asserts
# the rule never fired, so it carries the rule's own trigger clause instead.
cr_anchor_check() {
    local diff="${1:-}"
    shift 2>/dev/null || return 2
    [ "$#" -ge 1 ] || return 2
    [ -r "$diff" ] || return 2
    local r
    for r in "$@"; do [ -r "$r" ] || return 2; done

    awk -F'\t' -v D="$diff" '
        function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
        function bad(who, anchor, why) {
            printf "bad-anchor\t%s\t%s\t%s\n", who, anchor, why
            fail = 1
        }
        # <path>:L<n>:"<token>"  or  L<n>:"<token>" when the path is elsewhere.
        function split_anchor(a, want_path, out,   m) {
            m = match(a, /:?L[0-9]+:"/)
            if (m == 0) return 0
            if (want_path) {
                if (substr(a, m, 1) != ":") return 0
                out["path"] = substr(a, 1, m - 1)
                if (out["path"] == "") return 0
            } else {
                if (m != 1) return 0
                out["path"] = ""
            }
            out["line"] = substr(a, m + (want_path ? 2 : 1), RLENGTH - (want_path ? 4 : 3))
            out["tok"] = substr(a, m + RLENGTH)
            sub(/"[ \t]*$/, "", out["tok"])
            return (out["line"] ~ /^[0-9]+$/ && out["tok"] != "")
        }
        function verify(who, anchor, path, line, tok) {
            if (!(path in seen))                 { bad(who, anchor, "path is not in the diff: " path); return }
            if (!((path SUBSEP line) in content)) { bad(who, anchor, "line " line " is outside every hunk of " path); return }
            if (index(content[path, line], tok) == 0) { bad(who, anchor, "token is not on line " line " of " path); return }
        }

        { sub(/\r$/, "") }

        FILENAME == D {
            if ($0 ~ /^\+\+\+ /) {
                p = substr($0, 5)
                sub(/^[ab]\//, "", p)
                sub(/\t.*$/, "", p)
                cur = p; seen[cur] = 1; next
            }
            if ($0 ~ /^@@+ /) {
                # A combined diff carries one range per parent; the NEW-file range is the last.
                h = $0; sub(/^@+ /, "", h); sub(/ @+.*$/, "", h)
                nn = split(h, hp, " ")
                for (hi = nn; hi >= 1; hi--) if (hp[hi] ~ /^\+[0-9]/) { sub(/,.*$/, "", hp[hi]); n = substr(hp[hi], 2) + 0; break }
                next
            }
            if (cur == "") next
            c = substr($0, 1, 1)
            if (c == "+" || c == " ") { content[cur, n] = substr($0, 2); n++ }
            next
        }

        # The receipt. Field 1 says which of the two schemas this row is.
        {
            v = $1
            if (v == "context" || v == "diff-only" || v == "grep-only" || v == "skipped") next

            if (v == "read") {
                path = $3
                for (i = 4; i <= NF; i++) path = path FS $i
                if (!split_anchor(trim($2), 0, A)) { bad(path, $2, "read row carries no L<n>:\"token\" anchor"); next }
                verify(path, $2, path, A["line"], A["tok"])
                next
            }

            if (v == "breaks" || v == "holds" || v == "n/a") {
                slug = $3
                for (i = 4; i <= NF; i++) slug = slug FS $i
                if (v == "n/a") {
                    if (trim($2) == "") bad(slug, $2, "n/a carries no trigger clause saying why the rule never fired")
                    next
                }
                if (trim($2) == "") { bad(slug, $2, v " carries no anchor"); next }
                if (!split_anchor(trim($2), 1, A)) { bad(slug, $2, v " anchor is not <path>:L<n>:\"token\""); next }
                verify(slug, $2, A["path"], A["line"], A["tok"])
                next
            }
        }

        END { exit fail ? 1 : 0 }
    ' "$diff" "$@"
}

# cr_rule_coverage <routes> <rules_checked> <bad_anchors>
#
# Turns the routes and the receipts into the counts the summary comment prints.
# rc 1 ONLY when a routed rule got no usable verdict — the one bucket an
# operator can act on inside a review. `no-match` and `unroutable` print and
# never gate, for the reason vault/indications/rules-routed-not-recalled.md
# states.
cr_rule_coverage() {
    local routes="${1:-}" checked="${2:-}" bad="${3:-}"
    [ -r "$routes" ] && [ -r "$checked" ] && [ -r "$bad" ] || return 2

    awk -F'\t' -v R="$routes" -v C="$checked" -v B="$bad" '
        function rank(v) {
            if (v == "breaks") return 3
            if (v == "holds")  return 2
            if (v == "n/a")    return 1
            return 0
        }
        { sub(/\r$/, "") }

        # A bad anchor disqualifies the ROW that carried it, not every row for
        # that slug: one critic may cite badly while another cites well.
        FILENAME == B && $1 == "bad-anchor" { rejected[$2, $3] = 1; next }

        FILENAME == R {
            if ($1 == "applies")         { if (!($2 in isRouted)) { isRouted[$2] = 1; routed[++nr] = $2 } }
            else if ($1 == "no-match")   nm++
            else if ($1 == "unroutable") { un++; unroutableSlug[++nu] = $2 }
            next
        }

        FILENAME == C {
            v = $1
            if (rank(v) == 0) next
            slug = $3
            for (i = 4; i <= NF; i++) slug = slug FS $i
            if ((slug SUBSEP $2) in rejected) next
            if (rank(v) > best[slug]) { best[slug] = rank(v); verdict[slug] = v }
            next
        }

        END {
            ok = 0; na = 0; unchecked = 0
            for (i = 1; i <= nr; i++) {
                s = routed[i]
                if (best[s] >= 2)      ok++
                else if (best[s] == 1) na++
                else                   miss[++nmiss] = s
            }
            unchecked = nmiss + 0
            printf "checked\t%d\n",          ok
            printf "routed-unchecked\t%d\n", unchecked
            printf "n-a\t%d\n",              na
            printf "no-match\t%d\n",         nm + 0
            printf "unroutable\t%d\n",       un + 0
            for (i = 1; i <= nr; i++) { s = routed[i]; if (best[s] > 0) printf "%s\t%s\n", verdict[s], s }
            for (i = 1; i <= nmiss; i++)  printf "routed-unchecked\t%s\n", miss[i]
            for (i = 1; i <= nu; i++)     printf "unroutable\t%s\n", unroutableSlug[i]
            exit (unchecked > 0) ? 1 : 0
        }
    ' "$bad" "$routes" "$checked"
}
