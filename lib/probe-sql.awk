# probe-sql.awk — reads SQL text on stdin and prints facts. Run by sql_facts in lib/probe-sql.sh, with the file
# label in the environment variable PROBE_SQL_LABEL. Statements other than CREATE and ALTER are skipped
# without being kept in memory. Nothing is executed.
function trim(s) { gsub(/^[ \t\n]+/, "", s); gsub(/[ \t\n]+$/, "", s); return s }
function unquote(s) { gsub(/[`"]/, "", s); gsub(/\[/, "", s); gsub(/\]/, "", s); sub(/^.*\./, "", s); return s }
function fact(k, tb, ln, a, b, c, d) { printf "%s\t%s\t%s\t%s\t%s\t%s\t%s%s\n", k, file, tb, ln, a, b, c, (d == "" ? "" : "\t" d) }
function linefrom(pos,   k) { for (k = pos; k <= slen; k++) if (substr(stmt, k, 1) !~ /[ \t\n]/) return sl[k]; return sl[slen] }
function readname(pos,   k) { k = pos; while (k <= slen && substr(stmt, k, 1) !~ /[ \t\n(]/) k++; NAMEEND = k; return substr(stmt, pos, k - pos) }
function firstcol(list,   c) {
    split(list, c, ","); list = trim(c[1]); sub(/[ \t\n].*$/, "", list); sub(/\(.*$/, "", list); return unquote(list)
}
function parenlist(s, from,   i, d, out, ch) {
    i = index(substr(s, from), "("); if (i == 0) return ""
    i = from + i; d = 1; out = ""
    while (i <= length(s)) { ch = substr(s, i, 1); if (ch == "(") d++; else if (ch == ")") { d--; if (d == 0) break }; out = out ch; i++ }
    return out
}
function split_parts(from, stopclose,   k, d, ins, ch, cur, cstart) {
    np = 0; d = 0; ins = 0; cur = ""; cstart = 0
    for (k = from; k <= slen; k++) {
        ch = substr(stmt, k, 1)
        if (ch == "\047") ins = !ins
        if (!ins) {
            if (ch == "(") d++
            else if (ch == ")") { if (d == 0 && stopclose) break; d-- }
            else if (ch == "," && d == 0) { np++; part[np] = trim(cur); pline[np] = linefrom(cstart ? cstart : k); cur = ""; cstart = 0; continue }
        }
        if (cstart == 0 && ch !~ /[ \t\n]/) cstart = k
        cur = cur ch
    }
    if (trim(cur) != "") { np++; part[np] = trim(cur); pline[np] = linefrom(cstart ? cstart : k) }
}
function refof(p, up,   r, rest, rt, rc) {
    if (!match(up, /REFERENCES[ \t\n]+/)) return "-"
    rest = substr(p, RSTART + RLENGTH); rt = rest; sub(/[ \t\n(].*$/, "", rt)
    rc = firstcol(parenlist(rest, 1)); return unquote(rt) "." (rc == "" ? "-" : rc)
}
function emit_part(t, p, ln, decl,   up, cols, tok, rest, upr, pos, kw, i, best, typ, rf) {
    up = toupper(p)
    if (up ~ /^(CHECK|LIKE|PERIOD|EXCLUDE|OF)[ \t\n(]/) return
    if (match(up, /^(CONSTRAINT[ \t\n]+[^ \t\n]+[ \t\n]+)?PRIMARY[ \t\n]+KEY/)) { fact("K", t, ln, firstcol(parenlist(p, RLENGTH)), "PK", "-"); return }
    if (match(up, /^(CONSTRAINT[ \t\n]+[^ \t\n]+[ \t\n]+)?UNIQUE[ \t\n(]/)) { fact("K", t, ln, firstcol(parenlist(p, RLENGTH)), "UQ", "-"); return }
    if (match(up, /^(CONSTRAINT[ \t\n]+[^ \t\n]+[ \t\n]+)?FOREIGN[ \t\n]+KEY/)) { fact("K", t, ln, firstcol(parenlist(p, RLENGTH)), "FK", refof(p, up)); return }
    if (match(up, /^(FULLTEXT[ \t\n]+|SPATIAL[ \t\n]+)?(KEY|INDEX)[ \t\n(]/)) { fact("K", t, ln, firstcol(parenlist(p, RLENGTH)), "IX", "-"); return }
    tok = p; sub(/[ \t\n].*$/, "", tok)
    if (substr(tok, 1, 1) == "\"" || substr(tok, 1, 1) == "`") { tok = p; match(tok, /^["`][^"`]*["`]/); tok = substr(p, 1, RLENGTH) }
    rest = trim(substr(p, length(tok) + 1)); upr = " " toupper(rest) " "; best = length(upr) + 1
    n_kw = split("NOT NULL,NULL,DEFAULT,PRIMARY,UNIQUE,REFERENCES,AUTO_INCREMENT,AUTOINCREMENT,COMMENT,CHECK,COLLATE,GENERATED,CONSTRAINT,IDENTITY,AS", kws, ",")
    for (i = 1; i <= n_kw; i++) { pos = index(upr, " " kws[i] " "); if (pos == 0) pos = index(upr, " " kws[i] "("); if (pos > 0 && pos < best) best = pos }
    typ = tolower(trim(substr(rest, 1, best - 2))); gsub(/[ \t\n]+/, " ", typ)
    if (typ ~ /^(tiny|small|medium|big)?int/) gsub(/\([0-9]+\)/, "", typ)
    fact("C", t, ln, unquote(tok), typ, (upr ~ / NOT NULL / || upr ~ / PRIMARY KEY /) ? 1 : 0, decl)
    if (upr ~ / PRIMARY KEY /) fact("K", t, ln, unquote(tok), "PK", "-")
    else if (upr ~ / UNIQUE /) fact("K", t, ln, unquote(tok), "UQ", "-")
    rf = refof(rest, toupper(rest)); if (rf != "-") fact("K", t, ln, unquote(tok), "FK", rf)
}
function create_table(off,   t, k, i, decl) {
    decl = linefrom(1); t = unquote(readname(off + 1)); fact("T", t, decl, "-", "-", "-")
    k = NAMEEND; while (k <= slen && substr(stmt, k, 1) != "(") k++
    if (k > slen) return
    split_parts(k + 1, 1)
    for (i = 1; i <= np; i++) emit_part(t, part[i], pline[i], decl)
}
function create_index(u,   pos, t, rest, kind) {
    kind = (u ~ /^[ \t\n]*CREATE[ \t\n]+UNIQUE/) ? "UQ" : "IX"
    if (!match(u, /[ \t\n]ON[ \t\n]+(ONLY[ \t\n]+)?/)) return
    rest = substr(stmt, RSTART + RLENGTH); t = rest; sub(/[ \t\n(].*$/, "", t)
    fact("K", unquote(t), linefrom(1), firstcol(parenlist(rest, 1)), kind, "-")
}
function alter_table(off,   t, i, p, up, ln) {
    t = unquote(readname(off + 1)); split_parts(NAMEEND, 0)
    for (i = 1; i <= np; i++) {
        p = part[i]; up = toupper(p)
        if (!match(up, /^ADD[ \t\n]+/)) continue
        p = trim(substr(p, RLENGTH + 1)); up = toupper(p)
        if (match(up, /^COLUMN[ \t\n]+(IF[ \t\n]+NOT[ \t\n]+EXISTS[ \t\n]+)?/)) p = trim(substr(p, RLENGTH + 1))
        emit_part(t, p, pline[i], 0)
    }
}
function process(   u) {
    u = toupper(stmt)
    if (match(u, /^[ \t\n]*CREATE[ \t\n]+(TEMP[ \t\n]+|TEMPORARY[ \t\n]+|UNLOGGED[ \t\n]+)?TABLE[ \t\n]+(IF[ \t\n]+NOT[ \t\n]+EXISTS[ \t\n]+)?/)) create_table(RLENGTH)
    else if (match(u, /^[ \t\n]*CREATE[ \t\n]+(UNIQUE[ \t\n]+)?INDEX[ \t\n]+/)) create_index(u)
    else if (match(u, /^[ \t\n]*ALTER[ \t\n]+TABLE[ \t\n]+(ONLY[ \t\n]+)?(IF[ \t\n]+EXISTS[ \t\n]+)?/)) alter_table(RLENGTH)
}
function feed(c, ln,   u) {
    if (c == ";" && !ins && depth == 0) { if (!skip) process(); stmt = ""; slen = 0; skip = 0; return }
    if (!ins) { if (c == "(") depth++; else if (c == ")" && depth > 0) depth-- }
    if (skip) return
    if (slen == 0 && c ~ /[ \t\n]/) return
    slen++; stmt = stmt c; sl[slen] = ln
    if (slen == 40) { u = toupper(stmt); if (u !~ /^[ \t\n]*(CREATE|ALTER)/) { skip = 1; stmt = ""; slen = 0 } }
}
BEGIN { file = ENVIRON["PROBE_SQL_LABEL"]; ins = 0; inc = 0; depth = 0; slen = 0; stmt = ""; skip = 0 }
{
    gsub(/\r/, ""); n = split($0, ch, "")
    for (i = 1; i <= n; i++) {
        c = ch[i]
        if (inc) { if (c == "*" && ch[i + 1] == "/") { inc = 0; i++ } ; continue }
        if (!ins && c == "-" && ch[i + 1] == "-") break
        if (!ins && c == "/" && ch[i + 1] == "*") { inc = 1; i++; continue }
        if (c == "\047") ins = !ins
        feed(c, NR)
    }
    feed("\n", NR)
}
END { if (!skip && trim(stmt) != "") process() }
