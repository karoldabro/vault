#!/usr/bin/env bash
# SC-4 — bin/doc-lint.sh grades a handoff and a report as their own contract types.
#
# Fails when either type is unregistered in any of the four functions that decide its treatment.
# An unregistered type takes the loosest cap in the table, which silently exempts exactly the
# documents most likely to need one.
#
# Every assertion reads the source. A probe file alone proves nothing: doc-lint prints its header
# only alongside a real finding, so a clean probe is silent whether the type is registered or not.
# The probe below therefore carries a deliberate over-long sentence, and the header it forces is
# read back for the cap.
set -uo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lint="$root/bin/doc-lint.sh"
fail=0

[ -x "$lint" ] || { printf '  MISSING  %s is not executable\n' "$lint"; exit 1; }

# Body of one shell function, so an assertion about it cannot be satisfied from elsewhere in the file.
# grep plus sed rather than a dynamic awk regex: awk implementations disagree on how an interpolated
# pattern is escaped, and the container's awk silently matched nothing where the host's matched.
fnbody() {
    local start end
    # `grep -m1` rather than `grep | head -1`: under `pipefail`, head closing the pipe early kills
    # grep with SIGPIPE and the pipeline returns 141, which reads as "function not found".
    start=$(grep -m1 -nE "^$1\(\)" "$lint" | cut -d: -f1)
    [ -n "$start" ] || return 0
    end=$(tail -n "+$((start + 1))" "$lint" | grep -m1 -n '^}' | cut -d: -f1)
    [ -n "$end" ] || return 0
    sed -n "${start},$((start + end))p" "$lint"
}

# Assert a pattern against one function's body. The body is captured first and matched second: piping
# it into `grep -q` lets grep exit on the first hit and kills the producing `sed` with SIGPIPE, which
# under `pipefail` turns an early match into a reported miss.
in_fn() {
    local fn=$1 pat=$2 msg=$3 mode=${4:-E} body
    body=$(fnbody "$fn")
    if [ "$mode" = F ]; then grep -qF -- "$pat" <<<"$body"; else grep -qE -- "$pat" <<<"$body"; fi \
        || { printf '  MISSING  %s\n' "$msg"; fail=1; }
}
has_fn() { grep -qE "^$1\(\)" "$lint" || { printf '  MISSING  bin/doc-lint.sh has no %s function\n' "$1"; fail=1; return 1; }; }

# --list-caps prints both, with the caps this plan sets
caps=$("$lint" --list-caps 2>/dev/null || true)
grep -qE '^handoff +150$' <<<"$caps" || { printf '  MISSING  --list-caps does not print "handoff 150"\n'; fail=1; }
grep -qE '^report +120$'  <<<"$caps" || { printf '  MISSING  --list-caps does not print "report 120"\n'; fail=1; }

# cap_for_type — the caps themselves, not just the listing loop, which is a separate literal list
if has_fn cap_for_type; then
  in_fn cap_for_type '(^|\||[[:space:]])handoff\)[[:space:]]*echo[[:space:]]*150' 'cap_for_type gives handoff no 150 cap'
  in_fn cap_for_type '(^|\||[[:space:]])report\)[[:space:]]*echo[[:space:]]*120'  'cap_for_type gives report no 120 cap'
fi

# is_known_type — the function that decides whether the 400-line default silently applies
if has_fn is_known_type; then
  for t in handoff report; do
    in_fn is_known_type "(^|\||\(|[[:space:]])${t}[[:space:]]*(\||\)|\\\\|$)" \
      "is_known_type does not list ${t}, so it keeps the 400-line default"
  done
fi

# is_document_folder — decides whether a file with no frontmatter in the folder is linted at all
if has_fn is_document_folder; then
  for d in handoffs reports; do
    in_fn is_document_folder "*/${d}" \
      "is_document_folder does not cover ${d}/, so a file there without frontmatter is skipped" F
  done
fi

# singularize_type — folder name folded onto the type name, right-hand side included
if has_fn singularize_type; then
  for pair in handoffs:handoff reports:report; do
    folder=${pair%%:*}; want=${pair##*:}
    in_fn singularize_type "^[[:space:]]*${folder}\)[[:space:]]+echo[[:space:]]+${want}([[:space:]]|;|$)" \
      "singularize_type does not fold ${folder} onto ${want}"
  done
fi

# neither type may be a record: both state what is still true, not what happened. A deleted function
# is a failure here, never a skip.
if has_fn is_record_type; then
  record_body=$(fnbody is_record_type)
  grep -qE '(\||\()[[:space:]]*(handoff|report)[[:space:]]*(\||\)|\\)' <<<"$record_body" && {
    printf '  WRONG  bin/doc-lint.sh treats handoff or report as a record; both are contracts\n'; fail=1; }
fi

# and the end-to-end read: a real file of each type takes its own cap and loses the unknown-type note
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
for pair in handoff:150 report:120; do
  t=${pair%%:*}; want=${pair##*:}
  f="$tmp/probe-$t.md"
  {
    printf -- '---\ntype: %s\nproject: probe\nstatus: open\ntags: [%s]\n---\n\n# Probe\n\n## Goal\n\n' "$t" "$t"
    printf 'This sentence exists only to force a finding so that the header prints, and it runs past the thirty word ceiling the standard sets for a specification on purpose, which is the whole point of it.\n'
  } > "$f"
  out=$("$lint" "$f" 2>&1 || true)
  grep -q 'unknown type' <<<"$out" && { printf '  WRONG  a type: %s file still reports "unknown type"\n' "$t"; fail=1; }
  grep -qE "cap ${want}\]" <<<"$out" || { printf '  WRONG  a type: %s file is not graded at cap %s (header: %s)\n' "$t" "$want" "$(head -1 <<<"$out")"; fail=1; }
done

[ "$fail" -eq 0 ] && printf '  OK  doc-lint registers handoff and report as contract types, with caps 150 and 120\n'
exit "$fail"
