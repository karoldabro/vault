---
type: plan
project: vault
slug: output-brevity-standard
status: executed
process_record: 2026-08-21-1015-output-brevity-standard.trail.md
tags: [plan, team, communication, documentation]
---

# output-brevity-standard — plan

## Task

Give Claude a written standard for the **files it writes**, install it globally and in the vault
framework, and enforce it mechanically. Today only terminal prose is governed.

## The gap

`commands/_shared/communication.md` governs prose the user reads. It explicitly excludes "vault
document contents". So no rule reaches plans, briefs, specs, session notes or agent artifacts — the
files that actually cost the operator his day.

Two of the framework's own files cause the bloat:

| file | what it mandates | result |
|---|---|---|
| `templates/plan.md` | `## Critique trail`, `per-round metrics`, `### Round 0 — draft` | process record inside the contract document |
| `output-styles/director.md` | installed at `~/.claude/output-styles/`, **activated in 0 of 18 projects** | no brevity contract outside `/v-*` commands |

Measured: `~/vault/givore/plans/2026-08-18-1230-media-seo-cross-platform.md` is 1,529 lines. 470 are a
revision log, ~110 a critique trail, and the plan itself starts at line 488. Across all vaults, 54 of
60 plans fail the new check, and the framework's own `templates/plan.md` fails it 6 times.

## Model — three document classes

Every file has exactly one job. Mixing two in one file is the defect.

| class | examples | rule |
|---|---|---|
| **Contract** | plan, spec, brief, runbook, ADR, indication, guide | current truth only — someone acts on it |
| **Record** | session capture, critique trail, research log | chronology is the payload; references contracts, never restates them |
| **Message** | terminal output | already governed by `communication.md` |

## Binding decisions

### Where the process record goes

The critique trail, `per-round metrics`, rejected options and revision history move **out of the plan**
into a sidecar `plans/<slug>.trail.md`. The plan links it in one frontmatter key. Nothing is deleted:
round-2 critics, the minority-flag audit and `/v-capture` all still read it.

### The standard itself

New shared module `commands/_shared/document-standard.md`, capped at 110 lines, bound at the top of
every step file that writes a document. Same pattern as `communication.md` (ADR-018).

### Enforcement

`bin/doc-lint.sh` runs on a document **after** it is written, via a `PostToolUse` hook, and hands the
findings back to the model that wrote it. `--changed` scopes it to what this working tree touched, so
a first run does not bury the operator in findings on documents nobody will rewrite.
Prose rules alone already failed: `communication.md` has shipped since ADR-018 and plans still reach
1,500 lines.

Precision is a shipping requirement, not a nicety — a linter that fires on legitimate work gets
switched off. Across the framework's own 50 contract documents it now reports 2 findings, both real.
A repo whose subject matter collides with a rule declares the exemption in a repo-root `.doc-lint`
file, one code per line with its reason, so the exemption is reviewable instead of invisible.

## The rules

Defined once, in `commands/_shared/document-standard.md`. Two axes, and the second is what this plan
was missing when it was drafted: **which file content belongs in**, and **how a sentence is
written**.

Four of the five defect passages in the brief obey every filing rule and are still unusable, so
filing rules alone would have let them through unchanged. The standard therefore leads with the
before-and-after pairs and puts the rules beneath them.

**Exception, deliberate:** a decision record keeps its `## Context`, its rejected options and its
`## Consequences`. Those are its current truth and the only place "why did we decide this" survives
the session; a literal reading of the no-process rule deletes them.

**Not every rule has a check.** The register rules are judgement — no regex separates a good heading
from a bad one — and they are the ones that decide whether a document can be used. Do not read a
clean `doc-lint` run as "this document is good".

## Work items

| id | action | constraint | verification | status |
|---|---|---|---|---|
| F1 | Write `commands/_shared/document-standard.md` | ≤110 lines | `doc-lint` passes on itself | DONE |
| F2 | Rewrite `templates/plan.md` as contract-only | drops the critique trail, `Round 0`, `rounds`/`convergence` | `tests/unit/v-team.bats` asserts their absence | DONE |
| F3 | Add `templates/trail.md` (record sidecar) | holds everything F2 removed | linted as record class | DONE |
| F4 | Patch `v-team/steps/03-propose-loop.md` §(a), §(e).6, §(g), Layer 2 | trail writes to the sidecar | no dangling section reference | DONE |
| F5 | Patch `v-team/steps/04-execute-loop.md` §5.3 + Required output | stops printing rounds/convergence | golden fixture updated in the same commit | DONE |
| F6 | Bind `document-standard.md` in 14 named command and step files | same pattern as `communication.md`, one line below it | the paths are pinned in the test | DONE |
| F7 | Carry the standard in every agent envelope that writes a file | subagents inherit neither the output style nor `CLAUDE.md` | envelope grep test | TODO |
| F8 | Write `bin/doc-lint.sh` | precision-first; record-class files exempt from history checks | 19 behaviours pass | DONE |
| F8b | Add `--compare <before> <after>` | reports constraints present before and absent after | catches the 288 dropped paths | DONE |
| F9 | Add `tests/unit/document-standard.bats` | contract shape + binding coverage | 25 behaviours verified outside Docker | DONE |
| F10 | Move patterns to `lib/doc-lint-patterns.tsv` | a rule change is a data edit, not a script edit | every check maps to a numbered rule | DONE |
| F11 | Update `tests/unit/v-team.bats` + `test-design-fanout.bats` + the golden fixture | stop requiring the removed sections | 17 assertions verified | DONE |
| F12 | `commands/v-team.md` stages the sidecar too | the record is committed with the plan | — | DONE |
| F13 | Align `templates/_features/planning-session.md` with the generic sidecar | one vocabulary, two entry points | section names match `templates/trail.md` | DONE |
| F14 | Fix the documented binding path in `vault/indications/user-facing-communication.md` and `ADR-018` | both name `~/.claude/...`; every real binding uses `$VAULT_FRAMEWORK_PATH` | matches the files | TODO |
| F15 | Wire `doc-lint` to a `PostToolUse` hook | non-blocking; caps its own output at ~12 lines | a markdown write triggers it, exit 2 feeds the model | DONE |
| F16 | Write `commands/v-reconcile.md` | applies the standard to documents that already exist; approval gate per file | `--compare` blocks a lossy rewrite | DONE |
| G3 | Register the hook in `~/.claude/settings.json` | settings backed up first | valid JSON, smoke-tested both ways | DONE |
| G4 | Ship the hook as `scripts/doc-lint-hook.sh` **inside the repo** | resolves the framework from its own path; symlinked into `~/.claude/hooks/` like `commands/` and `output-styles/` | works through the symlink | DONE |
| G5 | Add `PostToolUse` to `hooks/hooks.json` | a plugin install gets the hook with no settings edit | `${CLAUDE_PLUGIN_ROOT}` form matches the existing `SessionStart` entry | DONE |
| G1 | Add an output-rules section to `~/.claude/CLAUDE.md` | six rules inline + pointer; file is 86 lines | — | DONE |
| G2 | Extend `output-styles/director.md` with the document half | written, **not activated** — the user reviews first | `/output-style director` when approved | DONE |
| V1 | Write ADR-023 + the indication + both indexes | one decision, one place | both lint clean | DONE |
| V2 | Write `vault/research/document-writing.md` | 30 findings, with the unciteable figures named | record class, lint clean | DONE |

## Open

- **F7 and F14 are not done.** Agent envelopes do not yet carry the standard, so a spawned agent that
  writes a file is still ungoverned. The binding path documented in
  `vault/indications/user-facing-communication.md` and `ADR-018` names `~/.claude/...`, which no file
  actually uses.
- **Needs the operator:** activate the output style via `/config` → Output style → *director*, after
  reading `output-styles/director.md`. The dedicated `/output-style` command was removed in Claude
  Code v2.1.91; the feature still exists. It is installed and active in none of 18 projects.
- **The suite has not run.** `tests/run.sh` needs Docker; the 25 linter behaviours and 17 file
  assertions were verified directly instead. Run `tests/run.sh tests/unit` before merging.
- Caps: plan 300 · feature 200 · guide 600 · ADR 120 · indication 80. Grounded in review cost —
  conforming inspection runs at 0.5–1.5 logical pages/hour, so a 1,000-line document is 22–66 hours
  of review nobody spends. Evidence in `vault/research/document-writing.md`.
- Migrating the 54 existing over-cap plans is out of scope here — `/v-reconcile` handles them on
  demand, one approval gate per file.
- The global `~/.claude/CLAUDE.md` copy cannot be reached by any test in this repo, so it will drift.
  Six rules plus a pointer limits how far.

## Refs

`decisions/ADR-018-decision-communication-contract.md` · `indications/user-facing-communication.md` ·
`research/decision-communication.md`
