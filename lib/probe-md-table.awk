# probe-md-table.awk — see lib/probe-md-table.sh. Reads a markdown file on stdin (CRLF already
# stripped by the caller) and splits the pipe table under a heading into tab-separated cells.
# variable "heading": an ERE matched against the whole line (anchor it yourself, e.g. "^## Data model").
#
# Output: one header line "0<TAB>col1<TAB>col2..." (lowercased, trimmed, _ -> space), then one line
# per data row "<source line><TAB>cell1<TAB>cell2...", in the header's own column order. A leading and
# trailing pipe on every row are dropped positionally (fields 1 and n of the "|" split), never by an
# emptiness check, so a legitimately empty last column (e.g. an unset "references" cell) is kept.
# A cell's escaped pipe (\|) round-trips through \001 so it never splits the row.
BEGIN { on = 0; hdr = 0 }
$0 ~ heading { on = 1; next }
on && /^## / { exit }
on && /^\|/ {
    line = $0; gsub(/\\\|/, "\001", line)
    n = split(line, c, "|")
    if (!hdr) {
        out = "0"
        for (i = 2; i <= n - 1; i++) {
            h = tolower(c[i]); gsub(/^[ \t]+|[ \t]+$/, "", h); gsub(/_/, " ", h)
            out = out "\t" h
        }
        print out
        hdr = 1
        next
    }
    if (line ~ /^\|[- |:]*\|$/) next
    out = NR
    for (i = 2; i <= n - 1; i++) {
        v = c[i]
        gsub(/^[ \t]+|[ \t]+$/, "", v); gsub(/\001/, "|", v)
        out = out "\t" v
    }
    print out
}
