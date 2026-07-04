#!/usr/bin/env bash
# vault-capture — deterministic mechanics behind /v-capture.
#
# /v-capture used to carry all of this as in-prompt bash/regex instructions (~900 words re-loaded on
# every /v-work and /v-team run). This script owns the mechanical parts; the command markdown keeps
# only judgment (metadata extraction, candidate approval, feature CREATE/UPDATE/SKIP, OV push).
#
# Subcommands:
#   dedupe       --vault PATH --keywords "kw1 kw2 ..."       overlap % vs last 10 sessions
#   scan-adr     --file PATH                                  decision-shaped candidate lines
#   scan-ind     --file PATH --vault PATH                     rule-shaped candidates, deduped vs index
#   refs         --file PATH --vault PATH                     resolved Refs list (wikilinks/ADR/features)
#   next-adr     --vault PATH                                 next free ADR number (3-digit)
#   index-moc    --vault PATH --session FILENAME --goal TEXT  idempotent MOC prepend, keep last 5
#
# All output is plain text for the calling model to read. Non-zero exit only on usage/IO errors —
# "no candidates found" is a successful empty result, never a failure.

set -euo pipefail

usage() { grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

die() { echo "vault-capture: $*" >&2; exit 1; }

need_file() { [[ -f "$1" ]] || die "file not found: $1"; }
need_dir()  { [[ -d "$1" ]] || die "vault dir not found: $1"; }

cmd="${1:-}"; [[ -n "$cmd" ]] || usage 1
shift

VAULT="" FILE="" KEYWORDS="" SESSION="" GOAL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)    VAULT="$2"; shift 2 ;;
    --file)     FILE="$2"; shift 2 ;;
    --keywords) KEYWORDS="$2"; shift 2 ;;
    --session)  SESSION="$2"; shift 2 ;;
    --goal)     GOAL="$2"; shift 2 ;;
    -h|--help)  usage 0 ;;
    *) die "unknown flag: $1" ;;
  esac
done

case "$cmd" in

  # ── Step 2: dedupe vs last 10 sessions ────────────────────────────────────────
  dedupe)
    need_dir "$VAULT"; [[ -n "$KEYWORDS" ]] || die "dedupe needs --keywords"
    mapfile -t recent < <(ls -t "$VAULT"/sessions/*.md 2>/dev/null | head -10)
    ((${#recent[@]})) || { echo "no recent sessions — write fresh"; exit 0; }
    read -ra kws <<<"$KEYWORDS"
    for f in "${recent[@]}"; do
      hits=0
      for kw in "${kws[@]}"; do grep -qi -- "$kw" "$f" && hits=$((hits+1)); done
      echo "$(( hits * 100 / ${#kws[@]} ))% $f"
    done | sort -rn
    echo "---"
    echo "rule: >60% on any file → offer append (or continues: frontmatter); else write fresh"
    ;;

  # ── Step 4: ADR candidate scan ────────────────────────────────────────────────
  scan-adr)
    need_file "$FILE"
    grep -niE "we decided|decided to|chose .* over|going with|agreed to|settled on|picked .* because|rejected .* in favor of" \
      "$FILE" | cut -c1-200 || echo "no ADR candidates"
    ;;

  # ── Step 4b: indication candidate scan, deduped vs indications/_index.md ─────
  scan-ind)
    need_file "$FILE"; need_dir "$VAULT"
    idx="$VAULT/indications/_index.md"
    matches=$(grep -niE "convention:|pattern:|rule:|standard|always [a-z]+|never [a-z]+|we use .* for|prefer .* over|the .* way is|should (always|never)|test .* with|mock .* not" \
      "$FILE" | cut -c1-200 || true)
    [[ -n "$matches" ]] || { echo "no indication candidates"; exit 0; }
    if [[ -f "$idx" ]]; then
      while IFS= read -r line; do
        # crude but effective dedupe: any 4+ char word of the candidate already in the index row set
        key=$(echo "$line" | grep -oE '[a-z]{5,}' | head -3 | paste -sd'|' -)
        if [[ -n "$key" ]] && grep -qiE "$key" "$idx"; then
          echo "DUP  $line"
        else
          echo "NEW  $line"
        fi
      done <<<"$matches"
    else
      sed 's/^/NEW  /' <<<"$matches"
    fi
    ;;

  # ── Step 5: cross-link Refs ───────────────────────────────────────────────────
  refs)
    need_file "$FILE"; need_dir "$VAULT"
    {
      grep -oE '\[\[[^]]+\]\]' "$FILE" || true
      # ADR-NNN → resolve against inventory
      for n in $(grep -oE 'ADR-[0-9]+' "$FILE" | sort -u); do
        hit=$(ls "$VAULT"/decisions/${n}-*.md 2>/dev/null | head -1)
        [[ -n "$hit" ]] && echo "[[../decisions/$(basename "${hit%.md}")]]" || echo "UNRESOLVED $n"
      done
      grep -oE 'features/[0-9]+-[a-z0-9-]+' "$FILE" | sort -u | sed 's|^|[[../|; s|$|]]|' || true
    } | sort -u
    ;;

  # ── Step 4 helper: next free ADR number ──────────────────────────────────────
  next-adr)
    need_dir "$VAULT"
    inv="$VAULT/decisions/_inventory.md"
    last=$( { [[ -f "$inv" ]] && grep -oE 'ADR-[0-9]+' "$inv"; ls "$VAULT"/decisions/ADR-*.md 2>/dev/null | grep -oE 'ADR-[0-9]+'; } \
      | grep -oE '[0-9]+' | sort -n | tail -1)
    printf 'ADR-%03d\n' "$(( 10#${last:-0} + 1 ))"   # 10# guards octal misread of e.g. "014"
    ;;

  # ── Step 6: idempotent MOC prepend, keep last 5 ───────────────────────────────
  index-moc)
    need_dir "$VAULT"; [[ -n "$SESSION" && -n "$GOAL" ]] || die "index-moc needs --session and --goal"
    moc="$VAULT/_moc.md"; need_file "$moc"
    entry="- [[sessions/${SESSION%.md}]] — $GOAL"
    if grep -qF "[[sessions/${SESSION%.md}]]" "$moc"; then
      echo "already indexed — no-op"; exit 0
    fi
    grep -n "Sessions (recent)" "$moc" >/dev/null || { echo "no 'Sessions (recent)' block — add manually"; exit 0; }
    awk -v entry="$entry" '
      /Sessions \(recent\)/ { print; print entry; inblock=1; count=0; next }
      inblock && /^- \[\[sessions\// { count++; if (count >= 5) next }
      inblock && !/^- / && NF { inblock=0 }
      { print }
    ' "$moc" > "$moc.tmp" && mv "$moc.tmp" "$moc"
    echo "indexed: $entry (block trimmed to 5)"
    ;;

  *) die "unknown subcommand: $cmd (see --help)" ;;
esac
