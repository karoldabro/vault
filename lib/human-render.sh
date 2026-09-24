#!/usr/bin/env bash
# human-render.sh — the functions behind bin/render-human.sh. Sourced, never run on its own.
#
# Contract: commands/_shared/human-plan.md owns the page structure, the escaping rules and the graph
# format. This file implements them and states none of them again.
#
# It uses these from gate.sh and lib/arch-check.sh: GATE_VAULT_ROOT, die, frontmatter_get,
# arch_fm_value.
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
function want(name) { return colsel == "*" || index(" " tolower(colsel) " ", " " tolower(name) " ") > 0 }
function emit(s) { OUT = OUT s "\n" }
function tok(s,   out, i, c, ok) {
    ok = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"
    out = ""
    for (i = 1; i <= length(s); i++) { c = substr(s, i, 1); out = out ((index(ok, c) > 0) ? c : "_") }
    return (out == "") ? "_" : out
}
# norm: lower case, without * and backticks, for matching a status.
function norm(s) { s = tolower(s); gsub(/[*`]/, "", s); return s }
function hasword(s,   n, w, i) {
    s = norm(s); n = split(mwords, w, "|")
    for (i = 1; i <= n; i++) if (w[i] != "" && index(s, tolower(w[i])) > 0) return 1
    return 0
}
# keep_item: whether a bullet or paragraph passes the match mode, judged on its text before the first colon.
function keep_item(s,   i) {
    if (mode != "match") return 1
    s = norm(s); i = index(s, ":"); if (i > 0) s = substr(s, 1, i - 1)
    return hasword(s)
}
# strip_params: inside double quotes, drop a parenthesis group that follows a letter, digit or _.
function strip_params(ln,   out, i, c, inq, d, prev) {
    out = ""; inq = 0; prev = ""
    for (i = 1; i <= length(ln); i++) {
        c = substr(ln, i, 1)
        if (c == "\"") inq = !inq
        if (inq && c == "(" && prev ~ /[A-Za-z0-9_]/) {
            d = 1; i++
            while (i <= length(ln) && d > 0) { c = substr(ln, i, 1); if (c == "(") d++; else if (c == ")") d--; else if (c == "\"") break ; i++ }
            i--; out = out "()"; prev = ")"; continue
        }
        out = out c; prev = c
    }
    return out
}
function flush_para() {
    if (para == "") return
    if (mode == "task" && index(para, "Keywords:") > 0) { para = substr(para, 1, index(para, "Keywords:") - 1); sub(/[ \t]+$/, "", para) }
    if (para != "" && keep_item(para)) { emit("<p>" inline(para) "</p>"); shown++ }
    para = ""
}
function flush_item() {
    if (item == "") return
    if (keep_item(item)) {
        if (kind != "" && !lopen) { emit("<" kind ">"); lopen = 1 }
        emit("<li>" inline(item) "</li>"); shown++
    }
    item = ""
}
function close_list() { flush_item(); if (kind != "" && lopen) emit("</" kind ">"); kind = ""; lopen = 0 }
function emit_graph(   i, j, n, d, id, key, sc, lbl, dep, seen, node) {
    emit("<pre class=\"mermaid\">")
    emit("flowchart TD")
    split("", node)
    for (i = 1; i <= gn; i++) {
        id = gid[i]
        if (id !~ /^[A-Za-z0-9_-]+$/ || (id in node)) continue
        node[id] = 1
        sc = plain(gscope[i], 48); lbl = id
        if (sc != "") lbl = id " " sc
        emit("    " safe_id(id) "[\"" lbl "\"]")
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
            emit("    " safe_id(d) " --> " safe_id(id))
        }
    }
    emit("</pre>")
}
function close_table() {
    if (!tbl) return
    if (topen) { emit("</tbody>"); emit("</table>"); emit("</div>") }
    tbl = 0; topen = 0
    if (tolower(secname) == "sessions" && gdcol > 0 && gicol > 0 && gn > 0) emit_graph()
}
function flush_all() { flush_para(); close_list(); close_table() }
function table_row(line,   n, i, s, cn, want_c, mc) {
    n = cells(line, C)
    if (!tbl) {
        tbl = 1; tstage = 1; topen = 0; nh = n; gn = 0; gicol = 0; gscol = 0; gdcol = 0; mcol = 0
        thead = "<tr>"
        cn = split(mcols, want_c, "|")
        for (i = 1; i <= n; i++) {
            H[i] = tolower(C[i])
            sel[i] = want(C[i])
            if (H[i] == "id") gicol = i
            if (H[i] == "scope") gscol = i
            if (H[i] == "depends") gdcol = i
            if (sel[i]) thead = thead "<th>" esc(C[i]) "</th>"
        }
        for (mc = 1; mc <= cn && !mcol; mc++) for (i = 1; i <= n; i++) if (H[i] == tolower(want_c[mc])) { mcol = i; break }
        thead = thead "</tr>"
        return
    }
    if (tstage == 1) {
        tstage = 2
        if (line ~ /^\|[- |:]*\|[ \t]*$/) return
    }
    if (mode == "er") { er_row(n); return }
    if (mode == "signatures") { sig_row(n); return }
    if (mode == "match") {
        if (mcol > 0) { if (!hasword(C[mcol])) return }
        else if (!hasword(line)) return
    }
    if (!topen) { emit("<div class=\"scroll\">"); emit("<table>"); emit("<thead>"); emit(thead); emit("</thead>"); emit("<tbody>"); topen = 1 }
    s = "<tr>"
    for (i = 1; i <= ((n > nh) ? n : nh); i++) if (i > nh || sel[i]) s = s "<td>" inline(C[i]) "</td>"
    emit(s "</tr>"); shown++
    if (gicol > 0 && gdcol > 0) {
        gn++; gid[gn] = C[gicol]; gdep[gn] = C[gdcol]
        gscope[gn] = (gscol > 0) ? C[gscol] : ""
    }
}
function colval(name,   i) { for (i = 1; i <= nh; i++) if (H[i] == name) return C[i]; return "" }
# er_row: collect one Data model row; er_emit draws the diagram.
function er_row(n,   t, k, r) {
    t = tok(colval("table")); if (colval("table") == "") return
    if (!(t in ent)) { ent[t] = ++ne; entn[ne] = t; natt[t] = 0 }
    k = toupper(trim(colval("key"))); if (k == "UQ") k = "UK"; if (k != "PK" && k != "FK" && k != "UK") k = ""
    natt[t]++; att[t, natt[t]] = "        " tok(colval("type")) " " tok(colval("column")) ((k != "") ? " " k : "")
    r = trim(colval("references"))
    if (r ~ /^[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*$/) { nrel++; rel[nrel] = "    " substr(r, 1, index(r, ".") - 1) " ||--o{ " t " : " tok(colval("column")) }
}
function er_emit(   i, j, t) {
    if (ne == 0) { if (HW != "") { OUT = OUT HW; shown++ }; return }
    emit("<pre class=\"mermaid\">"); emit("erDiagram")
    for (i = 1; i <= nrel; i++) emit(rel[i])
    for (i = 1; i <= ne; i++) {
        t = entn[i]; emit("    " t " {")
        for (j = 1; j <= natt[t]; j++) emit(att[t, j])
        emit("    }")
    }
    emit("</pre>"); shown++
}
function sig_row(n,   p, s, th) {
    p = trim(colval("params")); if (p == "-") p = ""
    s = colval("interface") "." colval("method") "(" p "): " colval("returns")
    th = trim(colval("throws"))
    if (!sopen) { emit("<ul>"); sopen = 1 }
    emit("<li><code>" esc(s) "</code>" ((th != "" && th != "-") ? ", throws <code>" esc(th) "</code>" : "") "</li>"); shown++
}
# block: render lines L[1..NL] under `mode` into OUT. Mermaid blocks always render, except in er mode.
function block(   i, ln, t, fence) {
    para = ""; item = ""; kind = ""; lopen = 0; tbl = 0; topen = 0; fence = 0; sopen = 0
    ne = 0; nrel = 0; split("", ent); HW = ""
    for (i = 1; i <= NL; i++) {
        ln = L[i]
        if (fence) {
            if (ln ~ /^```/) { if (fence == 1) emit("</pre>"); else if (fence == 2) emit("</code></pre>"); else if (fence == 4) HW = HW "</pre>\n"; fence = 0; continue }
            if (fence == 4) { if (!hostile(ln)) HW = HW escm(ln) "\n"; continue }
            if (fence == 1) {
                if (hostile(ln)) continue
                if (mode == "labels") ln = strip_params(ln)
                emit(escm(ln))
            } else if (fence == 2) emit(esc(ln))
            continue
        }
        if (ln ~ /^```/) {
            flush_all()
            t = trim(substr(ln, 4))
            if (mode == "er") { if (index(t, "mermaid") == 1 && !skipdiag) { fence = 4; HW = HW "<pre class=\"mermaid\">\n" } else fence = 3 }
            else if (index(t, "mermaid") == 1) { if (skipdiag) fence = 3; else { fence = 1; emit("<pre class=\"mermaid\">"); shown++ } }
            else if (mode == "diagrams" || mode == "match") fence = 3
            else { fence = 2; emit("<pre><code>"); shown++ }
            continue
        }
        if (mode == "diagrams") continue
        if (ln ~ /^[ \t]*$/) { flush_all(); continue }
        if (ln ~ /^\|/) { flush_para(); close_list(); table_row(ln); continue }
        close_table()
        if (mode == "er" || mode == "signatures") continue
        if (ln ~ /^###+ /) { flush_all(); if (mode != "match") { emit("<h3>" inline(substr(ln, index(ln, " ") + 1)) "</h3>"); shown++ }; continue }
        if (ln ~ /^[ \t]*[-*][ \t]+/) {
            flush_para()
            if (kind != "ul") { close_list(); kind = "ul" }
            flush_item(); item = ln; sub(/^[ \t]*[-*][ \t]+/, "", item)
            continue
        }
        if (ln ~ /^[ \t]*[0-9]+\.[ \t]+/) {
            flush_para()
            if (kind != "ol") { close_list(); kind = "ol" }
            flush_item(); item = ln; sub(/^[ \t]*[0-9]+\.[ \t]+/, "", item)
            continue
        }
        if (ln ~ /^[ \t]+[^ \t]/ && kind != "") { item = item " " trim(ln); continue }
        close_list()
        para = (para == "") ? trim(ln) : para " " trim(ln)
    }
    if (fence == 1) emit("</pre>")
    else if (fence == 2) emit("</code></pre>")
    else if (fence == 4) HW = HW "</pre>\n"
    flush_all()
    if (sopen) emit("</ul>")
    if (mode == "er") er_emit()
}
# section: render one block under a TSV row and print it with its heading when it shows anything.
function section(heading, m,   f, n) {
    n = split(m, f, ":")
    mode = f[1]; mcols = ""; mwords = ""
    if (mode == "match") { mcols = f[2]; mwords = f[3] }
    if (mode != "all" && mode != "task" && mode != "match" && mode != "er" && mode != "signatures" && mode != "labels" && mode != "diagrams") { print "unknown mode " m " for " secname > "/dev/stderr"; exit 4 }
    OUT = ""; shown = 0
    block()
    if (shown > 0) { print "<h2>" esc(heading) "</h2>"; printf "%s", OUT }
}
function load_tsv(src,   l, f, n) {
    while ((getline l < SECTSV) > 0) {
        if (l ~ /^#/ || l ~ /^[ \t]*$/) continue
        n = split(l, f, "\t")
        if (f[1] != src) continue
        nr++; rsec[nr] = f[2]; rmode[nr] = f[3]
        rcols[nr] = (n >= 4 && f[4] != "") ? subst(f[4], "_", " ") : "*"
        rhead[nr] = (n >= 5 && f[5] != "") ? f[5] : f[2]
        listed[f[2]] = 1
    }
    close(SECTSV)
}
# render_all: every TSV row whose section exists, then the diagrams of every unlisted section.
function render_all(   k, i, name, nb) {
    for (k = 1; k <= nr; k++) {
        name = rsec[k]
        if (!(name in secidx)) continue
        load_sec(secidx[name])
        colsel = rcols[k]; secname = name; skipdiag = (name in drawn); drawn[name] = 1
        section(rhead[k], rmode[k])
    }
    for (k = 1; k <= no; k++) {
        if (ordn[k] in listed) continue
        load_sec(k); colsel = "*"; secname = ordn[k]; skipdiag = 0
        section(ordn[k], "diagrams")
    }
}
function load_sec(k,   i) { NL = cnt[k] + 0; for (i = 1; i <= NL; i++) L[i] = bodyl[k, i] }
'

# The plan: every block of templates/human-plan-sections.tsv whose source is plan. Exit 3 means no Task text.
HUMAN_AWK_PLAN='
BEGIN { load_tsv("plan") }
/^```/ { fenced = !fenced }
!fenced && /^## / { cur = substr($0, 4); sub(/[ \t]+$/, "", cur); if (!(cur in secidx)) { secidx[cur] = ++no; ordn[no] = cur }; k = secidx[cur]; next }
cur != "" { cnt[k]++; bodyl[k, cnt[k]] = $0; if (cur == "Task" && $0 !~ /^[ \t]*$/) task_ok = 1 }
END {
    if (!task_ok) exit 3
    render_all()
}
'

# The spec: every block whose source is spec, then the diagrams of the sections the TSV does not list.
HUMAN_AWK_SPEC='
BEGIN { load_tsv("spec") }
/^```/ { fenced = !fenced }
!fenced && /^## / { cur = substr($0, 4); sub(/[ \t]+$/, "", cur); if (!(cur in secidx)) { secidx[cur] = ++no; ordn[no] = cur }; k = secidx[cur]; next }
no > 0 { cnt[k]++; bodyl[k, cnt[k]] = $0 }
END { render_all() }
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
    local plan=$1 repo=$2 to_stdout=$3 tmp raw specraw spec as title page rc
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


    title=$(awk '
        NR == 1 && $0 == "---" { fm = 1; next }
        fm && $0 == "---"      { fm = 0; next }
        !fm && /^# /           { print substr($0, 3); exit }' "$raw")
    [ -n "$title" ] || title=$(basename "$plan" .md)
    printf '%s\n' "$title" > "$tmp/title.txt"

    printf '%s\n%s\n' "$HUMAN_AWK_LIB" "$HUMAN_AWK_PLAN" > "$tmp/plan.awk"
    printf '%s\n%s\n' "$HUMAN_AWK_LIB" "$HUMAN_AWK_SPEC" > "$tmp/spec.awk"
    printf '%s\n%s\n' "$HUMAN_AWK_LIB" "$HUMAN_AWK_ASSEMBLE" > "$tmp/assemble.awk"

    : > "$tmp/body.html"
    printf '%s\n%s\n' "$HUMAN_AWK_LIB" 'BEGIN { getline t < TITLEFILE; print "<h1>" esc(t) "</h1>" }' > "$tmp/h1.awk"
    awk -v TITLEFILE="$tmp/title.txt" -f "$tmp/h1.awk" >> "$tmp/body.html"
    rc=0
    awk -v SECTSV="$GATE_VAULT_ROOT/templates/human-plan-sections.tsv" -f "$tmp/plan.awk" "$raw" \
        >> "$tmp/body.html" || rc=$?
    [ "$rc" -ne 3 ] || die "plan has no text under ## Task"
    [ "$rc" -ne 4 ] || die "templates/human-plan-sections.tsv names an unknown mode"
    [ "$rc" -eq 0 ] || die "the renderer failed on $plan"
    awk -v SECTSV="$GATE_VAULT_ROOT/templates/human-plan-sections.tsv" -f "$tmp/spec.awk" "$specraw" \
        >> "$tmp/body.html" || rc=$?
    [ "$rc" -ne 4 ] || die "templates/human-plan-sections.tsv names an unknown mode"
    [ "$rc" -eq 0 ] || die "the renderer failed on $spec"
    printf '%s\n%s\n' "$(basename "$plan")" "$as" > "$tmp/footer.txt"
    printf '%s\n%s\n' "$HUMAN_AWK_LIB" 'NR == 1 { p = $0 } NR == 2 { print "<p class=\"source\">Full plan: <code>" esc(p) "</code> · architecture spec: <code>" esc($0) "</code></p>" }' > "$tmp/footer.awk"
    awk -f "$tmp/footer.awk" "$tmp/footer.txt" >> "$tmp/body.html"
    awk -v TITLEFILE="$tmp/title.txt" -v BODYFILE="$tmp/body.html" -f "$tmp/assemble.awk" \
        "$GATE_VAULT_ROOT/templates/human-plan.html" > "$tmp/page.html"

    if [ "$to_stdout" = 1 ]; then
        cat "$tmp/page.html"
    else
        page="${plan%.md}.human.html"
        cat "$tmp/page.html" > "$page"
    fi
}
