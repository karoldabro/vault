---
type: report
project: vault
slug: doclint-exempts-a-code-that-does-not-exist
date: 2026-09-15
status: open
severity: minor
found_by: 2026-09-15-0933-doc-corpus campaign, case DOC-01
found_in: repairing vault/decisions/ADR-017-evidence-based-panel-hardening.md
files: [.doc-lint, lib/doc-lint-patterns.tsv]
tags: [report]
---

# doclint-exempts-a-code-that-does-not-exist — report

## What is wrong

The repo's `.doc-lint` grants an exemption to `PROC3b`, and `bin/doc-lint.sh` emits no such code, so
the exemption never applies to anything.

## Files

| file (exact path) | what is wrong in it |
|-------------------|---------------------|
| `.doc-lint` | line 5 names `PROC3b`; the code the pattern table defines is `PROC3` |
| `lib/doc-lint-patterns.tsv` | defines `PROC1` through `PROC7`; `PROC3b` appears nowhere in it |

## Consequence

An ADR that records how many findings a panel run produced is flagged, although this repo decided in
writing that such a count is evidence for the decision and should stay. The author either deletes the
count or writes an exemption that already exists in intent. This is latent: no ADR has yet been
flagged under `PROC3`, so nothing has been lost.

## Cause

unknown: `git log -S 'PROC3b' -- .doc-lint` was not run, and the pattern table carries no history of a
code being renamed. The shape suggests the exemption was written against an intended sub-code that the
pattern table never gained.

## How to see it

```
grep -n 'PROC3b' .doc-lint            # line 5 — the exemption
grep -c 'PROC3b' lib/doc-lint-patterns.tsv   # 0 — nothing emits it
awk -F'\t' '{print $1}' lib/doc-lint-patterns.tsv | grep -E '^PROC' | sort -u
```

The third command prints `PROC1 PROC2 PROC3 PROC4 PROC5 PROC6 PROC7`.

## Repair

Decide which is true, then make the file say it:

- the exemption is wanted — change `.doc-lint` line 5 to name `PROC3`, and check no other document
  relies on `PROC3` firing;
- the exemption is not wanted — delete line 5.

`/v-do` covers either. It touches `.doc-lint` alone, and `./bin/doc-lint.sh --changed` proves it.

## Not now because

It changes how the linter grades every document in the repo, and a campaign is running against that
linter right now. Changing the verifier mid-run invalidates every verdict already recorded in
`vault/campaigns/2026-09-15-0933-doc-corpus/ledger.jsonl`.

## Closes when

`grep -c 'PROC3b' .doc-lint` returns 0.
