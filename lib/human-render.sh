#!/usr/bin/env bash
# human-render.sh — the functions behind bin/render-human.sh. Sourced, never run on its own.
#
# Contract: commands/_shared/human-plan.md owns the page structure, the escaping rules and the graph
# format. This file implements them and states none of them again.
#
# It uses these from gate.sh and lib/arch-check.sh: GATE_VAULT_ROOT, die, frontmatter_get,
# arch_fm_value, arch_profile_file, arch_trim.
#
# The awk below is POSIX: no gensub, no \s, no dynamic regex, no `for (k in a)`, no locale call.

# The text functions shared by the plan, spec and review programs.
HUMAN_AWK_LIB='
function esc(s,   out, i, c) {
    out = ""
    while ((i = match(s, /[&<>]/)) > 0) {
        c = substr(s, i, 1)
        out = out substr(s, 1, i - 1)
        if (c == "&") out = out "&amp;"; else if (c == "<") out = out "&lt;"; else out = out "&gt;"
        s = substr(s, i + 1)
    }
    return out s
}
function escm(s,   out, i, c) {
    out = ""
    while ((i = match(s, /[&<]/)) > 0) {
        c = substr(s, i, 1)
        out = out substr(s, 1, i - 1)
        if (c == "&") out = out "&amp;"; else out = out "&lt;"
        s = substr(s, i + 1)
    }
    return out s
}
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function subst(s, from, to,   out, i, n) {
    n = length(from); out = ""
    while ((i = index(s, from)) > 0) { out = out substr(s, 1, i - 1) to; s = substr(s, i + n) }
    return out s
}
function bold(s,   out, i, j) {
    out = ""
    while ((i = index(s, "**")) > 0) {
        j = index(substr(s, i + 2), "**")
        if (j == 0) break
        out = out substr(s, 1, i - 1) "<strong>" substr(s, i + 2, j - 1) "</strong>"
        s = substr(s, i + 2 + j + 1)
    }
    return out s
}
function inline(s,   n, p, i, out) {
    n = split(s, p, "`")
    out = ""
    for (i = 1; i <= n; i++) {
        if (i % 2 == 1) out = out bold(esc(p[i]))
        else if (i < n) out = out "<code>" esc(p[i]) "</code>"
        else out = out "`" bold(esc(p[i]))
    }
    return out
}
function plain(s, max,   ok, out, i, c) {
    ok = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:/_-"
    out = ""
    for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (index(ok, c) == 0) continue
        if (c == " " && (out == "" || substr(out, length(out), 1) == " ")) continue
        out = out c
    }
    sub(/ $/, "", out)
    if (length(out) > max) {
        c = substr(out, max + 1, 1)
        out = substr(out, 1, max)
        if (c != " " && index(out, " ") > 0) sub(/ [^ ]*$/, "", out)
    }
    return out
}
function safe_id(id,   low) {
    low = tolower(id)
    if (low == "end" || low == "graph" || low == "subgraph" || low == "style" || low == "class" || low == "click" || low == "default" || low == "flowchart" || low == "linkstyle") return "n_" id
    return id
}
function hostile(ln,   low) {
    low = tolower(ln)
    return index(low, "click") > 0 || index(low, "%%") > 0 || index(low, "href") > 0 || index(low, "javascript") > 0 || index(low, "vbscript") > 0
}
function cells(line, arr,   s, n, i) {
    s = subst(line, "\001", "")
    sub(/^[ \t]*\|/, "", s)
    if (s !~ /\\\|[ \t]*$/) sub(/\|[ \t]*$/, "", s)
    s = subst(s, "\\|", "\001")
    n = split(s, arr, "|")
    for (i = 1; i <= n; i++) arr[i] = trim(subst(arr[i], "\001", "|"))
    return n
}
function want(name) { return colsel == "*" || index(" " colsel " ", " " name " ") > 0 }
function flush_para() { if (para != "") { print "<p>" inline(para) "</p>"; para = "" } }
function flush_item() { if (item != "") { print "<li>" inline(item) "</li>"; item = "" } }
function close_list() { flush_item(); if (kind != "") { print "</" kind ">"; kind = "" } }
function emit_graph(   i, j, n, d, id, key, sc, lbl, dep, seen, node) {
    print "<pre class=\"mermaid\">"
    print "flowchart TD"
    split("", node)
    for (i = 1; i <= gn; i++) {
        id = gid[i]
        if (id !~ /^[A-Za-z0-9_-]+$/ || (id in node)) continue
        node[id] = 1
        sc = plain(gscope[i], 48); lbl = id
        if (sc != "") lbl = id " " sc
        print "    " safe_id(id) "[\"" lbl "\"]"
    }
    split("", seen)
    for (i = 1; i <= gn; i++) {
        id = gid[i]
        if (id !~ /^[A-Za-z0-9_-]+$/) continue
        n = split(gdep[i], dep, ",")
        for (j = 1; j <= n; j++) {
            d = trim(dep[j])
            if (d == "" || d == id || d !~ /^[A-Za-z0-9_-]+$/) continue
            key = d " " id
            if (key in seen) continue
            seen[key] = 1
            print "    " safe_id(d) " --> " safe_id(id)
        }
    }
    print "</pre>"
}
function close_table() {
    if (tbl) {
        print "</tbody>"; print "</table>"; print "</div>"
        tbl = 0
        if (secname == "Sessions" && gdcol > 0 && gicol > 0) emit_graph()
    }
}
function flush_all() { flush_para(); close_list(); close_table() }
function table_row(line,   n, i, s) {
    n = cells(line, C)
    if (!tbl) {
        tbl = 1; tstage = 1; nh = n; gn = 0; gicol = 0; gscol = 0; gdcol = 0
        print "<div class=\"scroll\">"; print "<table>"; print "<thead>"
        s = "<tr>"
        for (i = 1; i <= n; i++) {
            sel[i] = want(C[i])
            if (C[i] == "id") gicol = i
            if (C[i] == "scope") gscol = i
            if (C[i] == "depends") gdcol = i
            if (sel[i]) s = s "<th>" esc(C[i]) "</th>"
        }
        print s "</tr>"; print "</thead>"
        return
    }
    if (tstage == 1) {
        tstage = 2; print "<tbody>"
        if (line ~ /^\|[- |:]*\|[ \t]*$/) return
    }
    s = "<tr>"
    for (i = 1; i <= ((n > nh) ? n : nh); i++) if (i > nh || sel[i]) s = s "<td>" inline(C[i]) "</td>"
    print s "</tr>"
    if (gicol > 0 && gdcol > 0) {
        gn++; gid[gn] = C[gicol]; gdep[gn] = C[gdcol]
        gscope[gn] = (gscol > 0) ? C[gscol] : ""
    }
}
function block(   i, ln, t, fence) {
    para = ""; item = ""; kind = ""; tbl = 0; fence = 0
    for (i = 1; i <= NL; i++) {
        ln = L[i]
        if (fence) {
            if (ln ~ /^```/) { if (fence == 1) print "</pre>"; else print "</code></pre>"; fence = 0; continue }
            if (fence == 1) {
                if (hostile(ln)) continue
                print escm(ln)
            } else print esc(ln)
            continue
        }
        if (ln ~ /^```/) {
            flush_all()
            t = trim(substr(ln, 4))
            if (index(t, "mermaid") == 1) { fence = 1; print "<pre class=\"mermaid\">" }
            else { fence = 2; print "<pre><code>" }
            continue
        }
        if (ln ~ /^[ \t]*$/) { flush_all(); continue }
        if (ln ~ /^\|/) { flush_para(); close_list(); table_row(ln); continue }
        close_table()
        if (ln ~ /^###+ /) { flush_all(); print "<h3>" inline(substr(ln, index(ln, " ") + 1)) "</h3>"; continue }
        if (ln ~ /^[ \t]*[-*][ \t]+/) {
            flush_para()
            if (kind != "ul") { close_list(); print "<ul>"; kind = "ul" }
            flush_item(); item = ln; sub(/^[ \t]*[-*][ \t]+/, "", item)
            continue
        }
        if (ln ~ /^[ \t]*[0-9]+\.[ \t]+/) {
            flush_para()
            if (kind != "ol") { close_list(); print "<ol>"; kind = "ol" }
            flush_item(); item = ln; sub(/^[ \t]*[0-9]+\.[ \t]+/, "", item)
            continue
        }
        if (ln ~ /^[ \t]+[^ \t]/ && kind != "") { item = item " " trim(ln); continue }
        close_list()
        para = (para == "") ? trim(ln) : para " " trim(ln)
    }
    if (fence == 1) print "</pre>"
    else if (fence == 2) print "</code></pre>"
    flush_all()
}
'

# The plan sections, in the order of templates/human-plan-sections.tsv.
HUMAN_AWK_PLAN='
BEGIN {
    while ((getline l < SECTSV) > 0) {
        if (l ~ /^#/ || l ~ /^[ \t]*$/) continue
        n = split(l, f, "\t")
        ord[++no] = f[1]
        cols[f[1]] = (n >= 2) ? subst(f[2], "_", " ") : "*"
    }
    close(SECTSV)
}
/^```/ { fenced = !fenced }
!fenced && /^## / { cur = substr($0, 4); sub(/[ \t]+$/, "", cur); next }
cur != "" { cnt[cur]++; bodyl[cur, cnt[cur]] = $0 }
END {
    for (k = 1; k <= no; k++) {
        name = ord[k]
        if (!(name in cnt)) continue
        nb = 0
        for (i = 1; i <= cnt[name]; i++) { L[i] = bodyl[name, i]; if (L[i] !~ /^[ \t]*$/) nb = 1 }
        if (name == "Task" && nb) task_ok = 1
        if (!nb) continue
        NL = cnt[name]; colsel = cols[name]; secname = name
        print "<h2>" esc(name) "</h2>"
        block()
    }
    if (!task_ok) exit 3
}
'

# Every `## ` section of the spec, in file order, every column shown.
HUMAN_AWK_SPEC='
/^```/ { fenced = !fenced }
!fenced && /^## / { cur = substr($0, 4); sub(/[ \t]+$/, "", cur); ordn[++no] = cur; next }
no > 0 { cnt[no]++; bodyl[no, cnt[no]] = $0 }
END {
    for (k = 1; k <= no; k++) {
        nb = 0
        for (i = 1; i <= cnt[k] + 0; i++) { L[i] = bodyl[k, i]; if (L[i] !~ /^[ \t]*$/) nb = 1 }
        if (!nb) continue
        NL = cnt[k]; colsel = "*"; secname = ordn[k]
        print "<h2>" esc(ordn[k]) "</h2>"
        block()
    }
}
'

# The profile checklist: one list item per @review line.
HUMAN_AWK_REVIEW='
$1 == "@review" {
    if (!n++) { print "<h2>Check these yourself</h2>"; print "<ul>" }
    print "<li>" esc(substr($0, 9)) "</li>"
}
END { if (n) print "</ul>" }
'

# Fill the skeleton: the title file into <!--TITLE--> and the body file in place of <!--BODY-->.
HUMAN_AWK_ASSEMBLE='
BEGIN { getline title < TITLEFILE; close(TITLEFILE) }
$0 == "<!--BODY-->" { while ((getline l < BODYFILE) > 0) print l; close(BODYFILE); next }
{
    i = index($0, "<!--TITLE-->")
    if (i > 0) $0 = substr($0, 1, i - 1) esc(title) substr($0, i + 12)
    print
}
'

# human_render <plan> <repo> <stdout 0|1>
human_render() {
    local plan=$1 repo=$2 to_stdout=$3 tmp raw specraw spec as prof pf title page rc
    { [ -f "$plan" ] && [ -r "$plan" ]; } || die "cannot read: $plan"
    [ -r "$GATE_VAULT_ROOT/templates/human-plan.html" ] || die "missing: templates/human-plan.html"
    [ -r "$GATE_VAULT_ROOT/templates/human-plan-sections.tsv" ] || die "missing: templates/human-plan-sections.tsv"
    HUMAN_RENDER_TMP=$(mktemp -d)
    tmp=$HUMAN_RENDER_TMP
    trap 'rm -rf "$HUMAN_RENDER_TMP"' EXIT
    raw="$tmp/plan.md"; specraw="$tmp/spec.md"
    tr -d '\r' < "$plan" > "$raw"

    as=$(arch_fm_value "$raw" arch_spec)
    [ -n "$as" ] || die "plan names no arch_spec"
    if [[ $as == /* ]]; then spec=$as; else spec="$(dirname "$plan")/$as"; fi
    [ -f "$spec" ] && [ -r "$spec" ] || die "arch_spec names a file that does not exist: $as"
    tr -d '\r' < "$spec" > "$specraw"

    prof=$(arch_trim "$(frontmatter_get "$specraw" profile)")
    pf=""
    if [ -n "$prof" ]; then pf=$(arch_profile_file "$prof" "$repo") || pf=""; fi

    title=$(awk '
        NR == 1 && $0 == "---" { fm = 1; next }
        fm && $0 == "---"      { fm = 0; next }
        !fm && /^# /           { print substr($0, 3); exit }' "$raw")
    [ -n "$title" ] || title=$(basename "$plan" .md)
    printf '%s\n' "$title" > "$tmp/title.txt"

    printf '%s\n%s\n' "$HUMAN_AWK_LIB" "$HUMAN_AWK_PLAN" > "$tmp/plan.awk"
    printf '%s\n%s\n' "$HUMAN_AWK_LIB" "$HUMAN_AWK_SPEC" > "$tmp/spec.awk"
    printf '%s\n%s\n' "$HUMAN_AWK_LIB" "$HUMAN_AWK_REVIEW" > "$tmp/review.awk"
    printf '%s\n%s\n' "$HUMAN_AWK_LIB" "$HUMAN_AWK_ASSEMBLE" > "$tmp/assemble.awk"

    : > "$tmp/body.html"
    printf '%s\n%s\n' "$HUMAN_AWK_LIB" 'BEGIN { getline t < TITLEFILE; print "<h1>" esc(t) "</h1>" }' > "$tmp/h1.awk"
    awk -v TITLEFILE="$tmp/title.txt" -f "$tmp/h1.awk" >> "$tmp/body.html"
    if [ -n "$pf" ]; then awk -F'\t' -f "$tmp/review.awk" "$pf" >> "$tmp/body.html"; fi
    rc=0
    awk -v SECTSV="$GATE_VAULT_ROOT/templates/human-plan-sections.tsv" -f "$tmp/plan.awk" "$raw" \
        >> "$tmp/body.html" || rc=$?
    [ "$rc" -ne 3 ] || die "plan has no text under ## Task"
    [ "$rc" -eq 0 ] || die "the renderer failed on $plan"
    awk -f "$tmp/spec.awk" "$specraw" >> "$tmp/body.html"
    awk -v TITLEFILE="$tmp/title.txt" -v BODYFILE="$tmp/body.html" -f "$tmp/assemble.awk" \
        "$GATE_VAULT_ROOT/templates/human-plan.html" > "$tmp/page.html"

    if [ "$to_stdout" = 1 ]; then
        cat "$tmp/page.html"
    else
        page="${plan%.md}.human.html"
        cat "$tmp/page.html" > "$page"
    fi
}
