---
type: indication
project: vault
slug: checks-answer-the-same-everywhere
scope: repo
tags: [indication, gates, shell]
---

# checks-answer-the-same-everywhere

## Rule

A check script gives the same answer on every shell, every `awk`, and every file size, or it is not a
check. Run each one on the host **and** inside `./tests/run.sh` before trusting either result, and
prefer the construct that cannot vary.

Four constructs vary. Use the right-hand column.

| never | always | because |
|-------|--------|---------|
| `grep -nE "$p" f \| head -1` | `grep -m1 -nE "$p" f` | `head` closes the pipe, `grep` takes SIGPIPE, and under `set -o pipefail` the pipeline returns 141 |
| `producer \| grep -q "$p"` | `body=$(producer); grep -q "$p" <<<"$body"` | `grep -q` exits on the first hit and kills the producer the same way |
| `awk -v p="$pat" '$0 ~ p'` | `grep -m1 -n` for the line, `sed -n 'a,bp'` for the slice | `awk` implementations disagree on how an interpolated pattern is escaped |
| `grep -qF "--open"` | `grep -qF -- "--open"` | a pattern beginning with `-` is parsed as an option |

## Rationale

The first two make the answer depend on **where the match is and how big the file is**. A match near
the end of a section passes and a match near the start fails, because the producer had already
finished writing in one case and not the other. That is not a flaky check; it is a check that reports
a clean file as broken and, in the mirrored case, a broken file as clean.

The third makes the answer depend on the machine. `checks/handoff-SC-3.sh` passed on the host and
failed in the container while both read the identical file, because the host runs gawk and the test
image does not.

All four fail in the direction that costs most: they produce a **confident wrong verdict** rather
than an error. `vault/indications/unreadable-is-not-no.md` states the principle — a check separates
"the answer is no" from "I could not read the question". These are the four shell constructs that
break it silently.

## Examples

Do — `checks/handoff-SC-3.sh`:

```bash
section() {
    local f="$root/$1" start end
    start=$(grep -m1 -nE "$2" "$f" | cut -d: -f1)
    [ -n "$start" ] || return 0
    end=$(tail -n "+$((start + 1))" "$f" | grep -m1 -nE "$3" | cut -d: -f1)
    if [ -n "$end" ]; then sed -n "${start},$((start + end - 1))p" "$f"
    else sed -n "${start},\$p" "$f"; fi
}
in_section() {
    local file=$1 start=$2 end=$3 pat=$4 msg=$5 body
    body=$(section "$file" "$start" "$end")
    grep -qE "$pat" <<<"$body" || { printf '  MISSING  %s: %s\n' "$file" "$msg"; fail=1; }
}
```

Don't — the same helper before the repair, which reported nine present lines as missing:

```bash
section() { awk -v s="$2" -v e="$3" '$0 ~ s {f=1} f && $0 ~ e {f=0} f' "$root/$1"; }
in_section() { section "$1" "$2" "$3" | grep -qE "$4" || fail=1; }
```

## Applies-to

`checks/*.sh`, `bin/*.sh`, `lib/*.sh`, `scripts/*-hook.sh`, and any `run` assertion in `tests/**/*.bats`.
