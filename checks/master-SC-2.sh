#!/usr/bin/env bash
# SC-2 of vault/plans/2026-09-21-1940-cross-session-contracts.md — the table check of gate.sh master.
# Exit 0 met, 1 not met, 2 cannot read the question.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
gate="$root/bin/gate.sh"; fx="$root/tests/fixtures/master/complete.md"
[ -r "$root/lib/master-check.sh" ] && [ -r "$fx" ] || { echo "lib/master-check.sh or the fixture is not written yet — cannot say"; exit 2; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { printf '%s\n' "$*"; exit 1; }
# want <name> <exit> <stderr-or-stdout pattern> <file>
want() {
    local name=$1 code=$2 pat=$3 f=$4 out rc
    out=$("$gate" master "$f" 2>&1); rc=$?
    [ "$rc" -eq "$code" ] || fail "$name: exit $rc, wanted $code: $out"
    printf '%s' "$out" | grep -q -- "$pat" || fail "$name: output lacks '$pat': $out"
}
want complete 0 '^master: ok ' "$fx"
sed 's/$/\r/' "$fx" > "$tmp/crlf.md";                           want crlf 0 '^master: ok ' "$tmp/crlf.md"
sed '/^| C-2 /d' "$fx" > "$tmp/a.md";                           want missing-row 1 'S3 depends on S2 and no contract row is produced by S2 and consumed by S3.*\[S3\]' "$tmp/a.md"
sed 's/| S2 | S3 | `bin/| S2 | S9 | `bin/' "$fx" > "$tmp/b.md";  want unknown-consumer 1 'C-2 names session S9 in consumed by' "$tmp/b.md"
sed 's/| C-1 | spec format | S1 |/| C-1 | spec format | S8 |/' "$fx" > "$tmp/c.md"; want unknown-producer 1 'names session S8 in produced by' "$tmp/c.md"
sed 's/| S3 | the reader | \/v-team | todo | S1, S2 |/| S3 | the reader | \/v-team | todo | S1, S7 |/' "$fx" > "$tmp/d.md"; want unknown-depends 1 'S3 depends on S7, and the Sessions table has no S7' "$tmp/d.md"
sed 's/| depends |/| waits |/' "$fx" > "$tmp/e.md";                want no-depends-column 1 'no depends column' "$tmp/e.md"
awk '/^## Cross-session contracts/{skip=1} /^## Refs/{skip=0} !skip' "$fx" > "$tmp/f.md"; want no-contracts-table 1 'needs a ## Cross-session contracts table' "$tmp/f.md"
sed 's/| `docs\/spec.md` sections and columns |/| |/' "$fx" > "$tmp/g.md"; want empty-shape 1 'C-1 has an empty shape cell' "$tmp/g.md"
sed 's/| S4 | the report | \/v-do | todo | S3 | 2026-09-21 | |/| S4 | the report | \/v-do | todo | S3 | 2026-09-21 |/' "$fx" > "$tmp/h.md"; want short-row 1 'a Sessions row has 6 cells and the header has 7.*\[S4\]' "$tmp/h.md"
sed 's/| S4 | the report/| S3 | the report/' "$fx" > "$tmp/i.md";  want dup-session 1 'session id S3 appears twice' "$tmp/i.md"
sed 's/| C-3 | reader output | S3 | S4 |/| C-3 | reader output | S3 | |/' "$fx" > "$tmp/j.md"; want empty-consumed 1 'C-3 has an empty consumed by cell' "$tmp/j.md"
sed 's/^| C-3 \(.*\) |$/| C-3 \1 | extra |/' "$fx" > "$tmp/k.md"; want wide-contract-row 1 'a contract row has 6 cells and the header has 5' "$tmp/k.md"
for col in 'contract:name' 'produced by:made by' 'consumed by:used by' 'shape:form'; do
    sed "s/^| id | ${col%%:*} |/| id | ${col##*:} |/; s/| ${col%%:*} |\$/| ${col##*:} |/; s/| ${col%%:*} | \(.*\)|\$/| ${col##*:} | \1|/" "$fx" > "$tmp/l.md"
    want "no-${col%%:*}-column" 1 "no ${col%%:*} column" "$tmp/l.md"
done
sed 's/| status |/| state |/' "$fx" > "$tmp/m.md"
want no-status-column 1 'the ## Sessions table has no status column' "$tmp/m.md"
sed 's/| id | scope/| ident | scope/' "$fx" > "$tmp/n.md"; want no-id-column 1 'the ## Sessions table has no id column' "$tmp/n.md"
sed 's/| S1, S2 | 2026-09-21 | |/| S1, S3 | 2026-09-21 | |/' "$fx" > "$tmp/o.md"; want self-dependency 1 'S3 depends on itself' "$tmp/o.md"
printf '# plan\n\n## Task\nx\n' > "$tmp/ordinary.md"
out=$("$gate" master "$tmp/ordinary.md" 2>&1); rc=$?; [ "$rc" -eq 0 ] && [ -z "$out" ] || fail "an ordinary plan was not silent: rc=$rc out=$out"
printf '# plan\n\n## Sessions\n- [[a]]\n- [[b]]\n' > "$tmp/bullets.md"
out=$("$gate" master "$tmp/bullets.md" 2>&1); rc=$?; [ "$rc" -eq 0 ] && [ -z "$out" ] || fail "a bullet-list Sessions section was not silent: rc=$rc"
out=$("$gate" master "$tmp/missing.md" 2>&1); rc=$?; [ "$rc" -eq 2 ] || fail "an unreadable file exited $rc, wanted 2"
exit 0
