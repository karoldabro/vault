---
type: session
project: vault
date: 2026-08-21
topic: A writing standard for the files commands write
files_touched: [commands/_shared/document-standard.md, bin/doc-lint.sh, lib/doc-lint-patterns.tsv, commands/v-reconcile.md, templates/plan.md, templates/trail.md, ~/.claude/settings.json, ~/.claude/CLAUDE.md]
decisions: [ADR-023-document-writing-standard]
tags: [session]
---

# A writing standard for the files commands write

## Goal

Stop Claude producing documents the operator cannot read across several projects at once, and make
the rule enforceable rather than aspirational.

## Did

- Wrote `commands/_shared/document-standard.md` — the disk-side sibling of `communication.md`, bound
  in 14 command and step files.
- Moved the critique trail out of the plan into `plans/<slug>.trail.md`; rewrote `templates/plan.md`
  and added `templates/trail.md`.
- Wrote `bin/doc-lint.sh` + `lib/doc-lint-patterns.tsv`, wired to a `PostToolUse` hook at
  `~/.claude/hooks/doc-lint-hook.sh`.
- Wrote `commands/v-reconcile.md` for documents that already exist.
- Added six output rules to `~/.claude/CLAUDE.md` and the document half to `output-styles/director.md`.
- Wrote `vault/research/document-writing.md` and [[ADR-023-document-writing-standard]].

## Learned

- **Nothing in the framework reads a plan's critique trail back.** Every reference under `commands/`
  is a writer; `plans/` is not in the default context-load list; `v-capture.md` contains no
  occurrence of `plan` or `trail`. The sidecar split therefore costs nothing on the read path.
- **The framework's own templates caused the bloat** it was being blamed for: `templates/plan.md`
  mandated a critique trail, `per-round metrics` and a draft section; `templates/integration-guide.md`
  mandated a changelog table.
- **`output-styles/director.md` was installed and active in 0 of 18 projects.** Outside `/v-*`
  commands there was no brevity contract at all.
- **Filing rules alone do not fix bad writing.** Four of the five defect passages the operator
  supplied obey every content rule and remain unusable. The missing axis is register: conclusion
  before evidence, say it rather than allude, name the actor, headings in words the reader has.
- **Compressing a document by rewriting loses constraints.** The operator's own hand-shortened plan
  dropped 288 named things — every source path, plus "the VP8X payload is ten bytes, not seven" and
  "IPTC must not be attempted". Shortening has to be a delete pass with a verification step.
- **Human and agent evidence converge on repeating a critical rule.** Aviation checklists mandate
  duplicating a safety-critical item across procedures; instruction adherence decays ~5.6% in odds
  per generated unit, so a constraint is re-issued at the point of use. Both cut against a naive
  one-rule-one-place reading.
- **"Bloated instruction files get ignored" does not survive its only factorial test** — no
  detectable effect of file size, position or architecture across 1,650 sessions.

## Behaviors & rules

- A file a command writes is contract, record or message → exactly one class; carrying two is the
  defect; edge: an ADR is contract but keeps its rejected options, which are its current truth.
- A plan converges → the plan holds current state and the trail holds how it got there; edge: the
  plan is rewritten each round, never appended to.
- A document is shortened → every constraint, prohibition and exact path in the long version is
  present in the short one or named as a deliberate cut; verified by `doc-lint --compare`.
- A markdown document is written under a vault document folder → the `PostToolUse` hook lints it and
  feeds findings back; edge: instruction files, non-documents and record-class files are skipped.
- A repo's subject matter collides with a check → the exemption is declared in `.doc-lint` with its
  reason; edge: never switch the whole linter off to silence one check.

## Next

- F7: agent envelopes do not yet carry the standard, so a spawned agent writing a file is ungoverned.
- F14: the binding path documented in `user-facing-communication.md` and ADR-018 names `~/.claude/...`,
  which no file uses.
- Run `tests/run.sh tests/unit` — needs Docker; 25 linter behaviours and 17 file assertions were
  verified directly instead.
- Operator: activate the output style via `/config` → Output style → *director*. The dedicated
  `/output-style` command was removed in Claude Code v2.1.91; the feature itself still exists.

## Refs

[[../decisions/ADR-023-document-writing-standard]] · [[../indications/document-writing-standard]] ·
[[../research/document-writing]] · [[../plans/2026-08-21-1015-output-brevity-standard]] ·
[[../decisions/ADR-018-decision-communication-contract]]
