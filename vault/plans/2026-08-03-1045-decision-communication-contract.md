---
type: plan
project: vault
slug: decision-communication-contract
status: executed
personas: [ad-hoc: framework-architect, quality, skeptic, exec-communication]
rounds: 2
convergence: capped-at-round-cap   # 0 open blockers; plan rounds 2, diff-review rounds 1
tags: [plan, team, communication, ux]
---

# decision-communication-contract — team plan

Make every v-* command write to the user like a competent employee writes to a decision-maker:
answer first, short, no jargon, options with consequences.

**v2** — two critique rounds, 4 critics, 45 findings, 44 applied. Round 1: all four returned
REQUEST_CHANGES; the load-bearing finding was that v0 would have *added* a presentation layer on top
of the existing output mandate, so total text would have grown. Round 2: three critics moved to
APPROVE_WITH_NITS; the skeptic held REQUEST_CHANGES and caught three real regressions v1 had
introduced (blast radius dropped from the gate, warning suppression, forge-comment rule deleted).

## Task

Fix how v-* commands communicate with the user — plans, questions and explanations must be short,
plain, and decision-ready, grounded in established professional-communication playbooks rather than
invented style rules.

Keywords: communication, questions, plans, verbosity, decision-support, style-contract

## User decisions taken at the clarify gate (§3a.0a)

1. **Decision presentation** — recommendation first, then the alternatives with consequences.
2. **Reach** — v-* commands **and** a global Claude Code output style, so ordinary sessions in other
   projects are covered too.

## Assumptions (stated defaults, correctable at the gate)

- One shared contract file, referenced by each command — not duplicated per command. Precedent:
  `commands/_shared/critic-panel.md`; policy: [[ADR-004-generic-packs-specifics-in-indications]].
- The contract governs **user-facing prose**, including the free-text `issue`/`recommendation` fields
  of critic findings that reach the user, **and** a separate clause for outward-facing text (forge
  comments), whose reader is not this user. It does **not** touch machine-read schemas, vault document
  formats, or commit messages.
- Numeric caps apply to **user-facing prose only** — never to reasoning, tool output, or evidence.
- Depth on request is never penalized, with one counter-condition (R-04 boundary).

## Research (§3a.0b)

Three parallel sweeps, ~30 searches, primary sources. **The full evidence tables (R-01..R-20, the
eight reconciled contradictions, and all citations) live in the research doc created by step 11** —
this plan cites by id only. *(Round-2 finding skeptic-14/comms-9: v1 marked this "applied" while
still carrying both tables. Now actually done.)*

**The findings that drive a design decision here:**

- **R-01** answer first (US Army AR 25-50) · **R-02** concise +58% / scannable +47% / both +124%, 79%
  of readers scan (NN/g) · **R-03** explaining what the reader knows is *negative*-value ·
  **R-04** over-explaining an expert costs d=−0.428 — **but no reversal in ill-structured domains, and
  framework design is ill-structured**, so strip narration, keep worked reasoning on novel decisions ·
  **R-05** decorative detail costs g=−0.33 (kills "weird metaphors") · **R-06** defining jargon does
  not undo jargon · **R-07** jargon → silent disengagement, not complaints · **R-08** a hard question
  yields a confidently-wrong answer, not "I don't know" · **R-10** comparability beats option count ·
  **R-11** more explanation buys agreement, not accuracy — optimize for verifiability ·
  **R-12** plain syntax +19.8pp and works on experts, but simplify *syntax, not precision* ·
  **R-13** ~4 chunks of working memory · **R-14** 25-word sentence ceiling, ~15 average ·
  **R-15** every option carries its consequence · **R-16** verbosity is a trained artifact; numeric
  caps work, but there is an accuracy floor — cap prose, never reasoning · **R-17** verdict first,
  detail behind disclosure · **R-18** bloated instruction files get ignored · **R-20** role framing
  helps *voice*, hurts *accuracy* — "employee reporting to a director" is a style claim, not a
  competence claim.

**Evidence honesty.** BLUF, Minto, the Amazon 6-pager, DACI, ADR and Completed Staff Work have **zero
controlled evidence** — doctrine, widely adopted, never tested. The measured numbers come only from
NN/g, GOV.UK's cited readability research, and the cognitive-load / jargon / decision literature. The
contract must not present doctrine as validated science.

## Converged plan (v2)

| # | File | Action | Driver |
|---|------|--------|--------|
| 1 | `commands/_shared/communication.md` | **CREATE** — ≤120 lines. **12 sections**: Posture (incl. cold-context line: name the project and the thing changing in sentence 1) · Answer first · **Assume the user has read nothing** · What to leave out (incl. no meta-explanation openers; fixed output templates are their own contract — do not reword them) · **Report exceptions, not normality** · Words & sentences (incl. **banned framework vocabulary + plain replacements**) · Asking a question · Presenting a decision (incl. **the ≤15-line cap** and **the cut order: cut options before consequences, assumptions before the ask; never an option without its consequence**) · Verdict first, detail on request · When to go deep · Evidence note · **Outward-facing text clause** (forge comments — different reader). | comms-1/4/5/7/8/10, quality-12, skeptic-12 |
| 2 | 12 × `commands/v-*.md` **+ the 15 files matching heading prefix `## Required output`** | **UPDATE** — binding line with the resolvable installed path `~/.claude/commands/_shared/communication.md`. Set defined by **prefix** match (one heading is suffixed: `v-pm/steps/02-load-context.md`). | arch-5, arch-12, quality-4, skeptic-9 |
| 2b | `commands/v-ask.md:55` | **DELETE** outright — the contract replaces it. **`v-cr/steps/03-review.md:47` is KEPT** — it governs comments posted to the forge, read by teammates, not by this user. It is not a duplicate. | quality-2, **skeptic-12** |
| 3 | `v-work/steps/03-propose.md` §3a.0a | **UPDATE** — an **ask-only-if gate first** (ask only when the answer changes what gets built AND you cannot settle it from vault/code/research; if you cannot name each option's consequence, you don't understand it well enough to ask), then the shape rules. | comms-6 |
| 4 | `v-work/steps/03-propose.md:158-176` and `v-team/steps/03-propose-loop.md:153-165` | **REWRITE — net deletion in what the USER READS** (13 printed fields → 6); the instruction file itself grows (+43 lines). **To the user:** recommendation · **Impact (blast radius: N files · migrations · coupled projects)** · options+consequences · assumptions · **open trade-offs / escalations** · what would change this · the ask. **To the artifact:** Research, Serena rules, Lite critic, Implementation steps, Test plan, Vault writes, Index updates. **Omit rule scoped to GREEN states only** — always emit a skip, a fallback, an unavailable tool, or an open blocker. | skeptic-1, comms-2, quality-1, **skeptic-10, skeptic-11, skeptic-13** |
| 5 | `commands/v-team.md` Step 4, `commands/v-work.md` approval gate | **UPDATE** — same two-layer shape; what reaches the user is **≤15 lines**. | comms-3 |
| 6 | `v-team/steps/03-propose-loop.md` §(c) + §(e) | **UPDATE** — §(e) caps what the synthesizer surfaces (confirmed blockers only, one plain-language line each; full trail to the artifact); §(c) puts the contract in the critic envelope for free-text fields. **The §(e) edit must preserve the ADR-017 tokens** (`minority flag`, `sycophancy`, `critic-owned`) that `tests/unit/v-team.bats` pins. Only mechanism covering subagent text — the output style cannot reach subagents. | skeptic-2, arch-8, **skeptic-15** |
| 7 | `output-styles/director.md` | **CREATE** — self-contained. Frontmatter `name` · `description` · `keep-coding-instructions: true`. | arch-7, quality-6 |
| 8a | `install.sh` | **REFACTOR** — extract `link_tree <src_dir> <target_dir>` and `prune_stale <src_dir> <src_prefix> <target_dir>` from the three copy-pasted blocks. **Prefix passed as a parameter, not inferred.** | quality-3, arch-1, arch-11 |
| 8b | `install.sh` | **UPDATE** — call the helpers for `output-styles/` → `~/.claude/output-styles/`, own `mkdir -p`, own prune pass. Print the correct activation line: `/config` → Output style → *director* (**`/output-style` was removed in v2.1.91**). | arch-1, arch-2, **arch-4** |
| 8c | `tests/unit/install.bats` | **UPDATE — characterisation tests FIRST, then refactor.** (i) fix the `Skipped: N` count for the new tree; (ii) a **dangling** symlink pointing outside `commands/` survives; (iii) a symlink at a valid name pointing at a *wrong* source is re-pointed (the `ln -sfn` branch has zero coverage today). | arch-3, **arch-11, quality-10** |
| 9 | `tests/unit/research-clarify.bats` (rewrite), `tests/unit/v-team.bats` (re-run) | **UPDATE** — the first pins the old output tokens; the second pins §(e)'s ADR-017 tokens. | quality-1, skeptic-15 |
| 10 | `vault-guide.md` §11, `INSTALL.md`, `commands/README.md` | **UPDATE** — `vault-guide.md:356` goes factually wrong once 8b lands. | arch-6 |
| 11 | `vault/research/decision-communication.md` | **CREATE** — the source-cited evidence catalog. R-01..R-20 + contradictions + citations in full. | comms-3/9, skeptic-14 |
| 12 | `vault/decisions/ADR-018-decision-communication-contract.md` | **CREATE** — Nygard format; the two user decisions + eight reconciled contradictions. | — |
| 13 | `vault/indications/user-facing-communication.md` + `_index.md` | **CREATE/UPDATE** — working rule for future framework authors. | — |
| 14 | `vault/research/llm-collaboration-patterns.md` | **UPDATE** — one line + Refs: that doc is agent↔agent, this one agent↔human. | — |
| 15 | `tests/unit/communication-contract.bats` | **CREATE** — the file-contract guards. | — |
| 16 | `tests/unit/propose-golden.bats` + `tests/fixtures/propose-output.txt` | **CREATE** — asserts the output *template* matches a committed expected shape + field set + line count. Carries a `Re-recording:` header naming how to regenerate it. **Honest label: a drift detector for the output block, not a behavioral test** — neither test image ships a `claude` CLI and the repo mounts read-only, so a real dry-run cannot run in CI. | skeptic-4, **arch-10, quality-8, quality-9** |
| 17 | `vault/_moc.md`, `_feature-index.md`, `decisions/_inventory.md` | **UPDATE** — index rows. | — |

## Test plan

Harness: bats-core in the alpine container (`make test` → `tests/unit` + `tests/integration`; e2e is
excluded by design and needs `VAULT_E2E=1` + root + network). Everything below is `kind: unit` so it
runs on the default PR-blocking path. Level: **file-contract greps**, plus one template-drift golden
file. No test here proves behavior — that limit is stated, not papered over.

## Proposed test backlog

| id | source | kind | target | intent | priority |
|----|--------|------|--------|--------|----------|
| c-t1 | plan | unit | contract has all 11 sections **and** the fixed-template clause | can't be silently gutted | must |
| c-t2 | plan, comms-t4 | unit | numeric caps present, **scoped to user-facing prose**, incl. the literal ≤15-line cap | R-16 floor; comms-7 | must |
| c-t3 | arch-t5 | unit | the set matching prefix `## Required output` is exactly **15** files, and each carries the literal `~/.claude/commands/_shared/communication.md` | arch-5/arch-12 — a suffixed heading or new step file can't fall out | must |
| c-t4 | plan | unit | §3a.0a carries the ask-only-if gate + shape rules | R-08 | must |
| c-t5 | skeptic-t1, skeptic-t4 | unit | both blocks drop `Implementation steps`/`Test plan`/`Converged plan: [numbered steps]` from the terminal **and** the user block still carries `Impact` | skeptic-1 + **skeptic-10: no signing off on an unstated blast radius** | must |
| c-t6 | comms-t1 | unit | contract forbids bare file/ADR/wikilink/section-id references in user-facing text | complaint 3 | must |
| c-t7 | comms-t2, skeptic-t5 | unit | omit rule scoped to green states; `research: unavailable`, the `(f2)` skip note, `CONVERGENCE: capped`, and `Open trade-offs / escalations` **survive** | complaint 6 — **without killing the amber warnings too** | must |
| c-t8 | skeptic-t2 | unit | §(e) caps synthesized findings surfaced to the user; ADR-017 tokens preserved | skeptic-2, skeptic-15 | must |
| c-t9 | quality-6 | unit | style contains the caps verbatim **and** `! grep '_shared/communication.md\|commands/v-'` | a pointer-only style is a no-op | must |
| c-t10 | arch-t1 | unit | installer links output-styles idempotently, creates the dir, prunes a dangling style link | arch-1/2 | must |
| c-t10b | arch-t4, quality-t4 | unit | a **dangling** symlink outside `commands/` survives; a wrong-source symlink is re-pointed with `Linked: 1` | **arch-11 + quality-10 — the uncovered branches, added before the 8a refactor** | must |
| c-t11 | quality-t1 | unit | `! grep -rn "Lead with the answer\|Keep it tight" commands/ --exclude-dir=attic **--exclude=communication.md**`; `03-review.md`'s forge-comment rule **exempt** | quality-2 + **quality-7** (the contract must be allowed its own phrasing) + **skeptic-12** | must |
| c-t12 | quality-t2 | unit | `link_tree()` defined once, called twice | no third copy-paste | should |
| c-t13 | arch-t3 | unit | style frontmatter has all three keys | arch-7 | should |
| c-t14 | skeptic-t3 | unit | depth-on-request names the ill-structured/novel counter-condition | skeptic-3 | should |
| c-t15 | comms-t3 | unit | contract forbids meta-explanation openers | complaint 5 | should |
| c-t16a | plan | unit | contract ≤120 lines | R-18 (split per quality-13) | should |
| c-t16b | plan | unit | contract carries the evidence-honesty note | don't overstate doctrine | should |
| c-t17 | quality-t5 | unit | golden fixture lives under `tests/unit/` and carries a `Re-recording:` header | arch-10/quality-8/9 — must run on the default path | should |
| c-t18 | comms-t5 | unit | no user-facing template contains `BLOCKER`/`MAJOR`/`advisory`/`persona`/`convergence`/`grounding` | **comms-8 — the newly-capped synthesizer path still leaks framework jargon** | should |
| c-t19 | skeptic-t6 | unit | a brevity rule still governs forge-posted comments | skeptic-12 | should |
| c-t20 | plan | unit | ADR-018 registered in `_inventory.md`; no broken wikilinks in new files | ADR-hygiene invariant | should |

## Open trade-offs / deferrals

- **Prose fixing prose.** Mitigated three ways — bats guards (which pin the *artifact*, not the
  behavior), the output style's mid-conversation re-injection (main conversation only, **not**
  subagents), and the 120-line cap. A Stop-hook length linter would be the deterministic fix;
  deliberately out of scope. **Behavior is not guarded by any test in this plan.** Stated plainly.
- **Reader model.** The contract hard-codes one reader: a technical director who wants decisions, not
  derivations, and who asks when he wants depth. Explicit, not universal. The forge-comment clause is
  the one place a second reader is acknowledged.
- **Scope growth.** v0 13 steps → v2 17, including an installer refactor and three existing test files.
  All growth is confirmed-finding-driven; the architect's scope check would drop nothing further.
- **Round-2 findings were applied but not re-critiqued** — the round cap is 2 and it was reached.
  15 findings (6 MAJOR) went in without a third review pass.

## Critique trail

### Round 0 — draft
13 steps · 9 contract sections · installer "reuses the existing loop" · critic output exempted ·
all tests file-contract greps.

### Round 1 — 30 findings (21 MAJOR / 8 MINOR / 1 NIT), 28 confirmed. All four: REQUEST_CHANGES.

Applied 29, noted-no-change 1, rejected 0. Clusters: output-block retargeting (skeptic-1 + comms-2 +
quality-1) · subagent coverage (arch-8 + skeptic-2 + quality-4 + skeptic-9) · installer reality
(arch-1 + arch-2 + quality-3) · path form (arch-5). Headline findings:

- **skeptic-1 / comms-2 / quality-1** — v0 targeted anchors that don't control user-facing output
  (`§3a.4`, `§(g)` — the latter emits none at all). Net effect would have been **+4 blocks on an
  unchanged 16-line mandate**. → step 4 retargeted to real line ranges as a net deletion.
- **comms-1 / comms-2** — two of the user's stated complaints were **not covered at all**: "assumes I
  know what it saved to the files" and "mentions things that are working". → two new contract sections.
- **arch-4** — `/output-style` was **removed in Claude Code v2.1.91**; the installer would have printed
  a dead command. (This also corrected what I had told the user at the clarify gate.)
- **skeptic-3** — R-04's expertise-reversal caveat was dropped; the effect does **not** hold in
  ill-structured domains, and framework design is one. → R-04 bounded, c-t14 added.
- **skeptic-4** — "bats guards mitigate prose decay" was circular. → downgraded; golden file added.
- **skeptic-6/7/8, R-12/R-16/R-19** — four research rows over-read their sources or laundered the
  researcher's own synthesis into vendor attribution. → corrected or moved.
- **quality-2** — two brevity rules already existed; the contract would have been a third source of
  truth. → delete outright (no stubs).

### Round 2 — 15 findings (6 MAJOR / 7 MINOR / 2 NIT), 13 confirmed.
Verdicts: architect **APPROVE_WITH_NITS** · quality **APPROVE_WITH_NITS** · exec-communication
**APPROVE_WITH_NITS** · skeptic **REQUEST_CHANGES**. All 15 applied.

All three non-skeptic critics independently verified every round-1 finding as **genuinely resolved in
the text, not merely acknowledged in the trail** — including a re-check of the corrected research rows
against the raw source notes, which found no new over-read.

| persona | id | sev | issue | disposition |
|---------|----|-----|-------|-------------|
| skeptic | skeptic-10 | MAJOR | **`Impact` (blast radius) fell into neither layer** — the user would authorize a 17-file change from a summary that never says which files move | **applied** → step 4 user layer, c-t5 |
| skeptic | skeptic-11 | MAJOR | The omit-when-empty rule was unconditional and would have **suppressed the four amber warnings** (`research: unavailable`, `(f2)` skip, `CONVERGENCE: capped`, safe-default flags) whose whole purpose is gate visibility | **applied** → omit scoped to green states, c-t7 |
| skeptic | skeptic-12 | MAJOR | Deleting `03-review.md:47` removes the only brevity rule on **forge comments read by teammates**, under a contract scoped to a reader who isn't them | **applied** → rule kept, outward-facing clause added, c-t11 exempt, c-t19 |
| skeptic | skeptic-13 | MINOR | `Open trade-offs / escalations` unassigned by the split — the minority-flag surface | **applied** → user layer |
| skeptic | skeptic-14 | MINOR | comms-3 marked "applied" while the plan grew 149→214 lines; the tables never moved | **applied** → tables actually moved to step 11 in v2 |
| skeptic | skeptic-15 | NIT | §(e) rewrite endangers `tests/unit/v-team.bats`'s ADR-017 tokens | **applied** → steps 6 + 9 |
| architect | arch-10 | MAJOR | The golden file is **unrunnable as specced** — no `claude` CLI in either image, repo mounted read-only, `kind: e2e` excluded from `make test` | **applied** → step 16 redefined + honestly relabelled |
| architect | arch-11 | MAJOR | `install.bats`'s "unrelated symlink" test uses a target that **exists**, so a `prune_stale` that drops the prefix guard still passes | **applied** → step 8c, c-t10b |
| architect | arch-12 | MINOR | One of the 15 `## Required output` headings is suffixed; an exact-match enumeration silently drops it | **applied** → prefix match, count asserted |
| architect | arch-13 | NIT | All retargeted anchors verified correct | **noted** |
| quality | quality-7 | MAJOR | c-t11's negative grep has no exception for the contract file — it would **forbid the contract from stating its own rule** | **applied** → `--exclude` |
| quality | quality-8 | MAJOR | `tests/golden/` is a directory no Makefile target walks | **applied** → `tests/unit/` |
| quality | quality-9 | MAJOR | A committed recording with nothing that regenerates it is circular one file removed | **applied** → re-record header + honest relabel |
| quality | quality-10 | MAJOR | The `ln -sfn` re-link branch has **zero coverage**; an extraction that inverts it goes green | **applied** → characterisation test before refactor |
| quality | quality-11/12/13 | MINOR/NIT | c-t10 bundles an unwritable assertion; scope note untested; c-t16 merges two properties | **applied** |
| comms | comms-7 | MINOR | The ≤15-line cap — the number that most limits what he reads — lived in one step file with no must-test | **applied** → contract + c-t2 |
| comms | comms-8 | MINOR | The newly-capped synthesizer path still hands him `BLOCKER`/`persona`/`convergence`/`grounding` — complaint 2 leaking through | **applied** → banned-vocab list, c-t18 |
| comms | comms-9 | MINOR | (= skeptic-14) | **applied** |
| comms | comms-10 | NIT | Nothing says what to cut when the 15-line cap binds; the easiest thing to drop is the consequence he asked for | **applied** → cut order |

_Metrics — round 2: findings 15 · confirmed 13, advisory 2 · **new confirmed BLOCKERs: 0** ·
findings-delta vs round 1: 30 → 15 (−50%) · applied 15, rejected 0 · persona overlap: 1 cluster
(skeptic-14 = comms-9) · **sycophancy flag: none** — no previously-confirmed finding was dropped or
relabelled; three critics actively re-verified round-1 resolutions rather than assenting ·
convergence: **round cap reached with 0 open blockers**._

**Coverage of the user's stated complaints (exec-communication critic, round 2): 12 of 12 covered.**
The two that were NOT COVERED in v0 each now have a named contract section and a `must` test.


### EXECUTE diff-review — round 1 (against the real code)

Same four critics, review posture, run on the staged diff (47 files, +1545/−103) with analyzers first
(`bash -n install.sh`, `make test`, live installer runs on a throwaway HOME, and **seeded mutation
testing**). Verdicts: architect **APPROVE_WITH_NITS** · quality **REQUEST_CHANGES** · skeptic
**REQUEST_CHANGES** · exec-communication **REQUEST_CHANGES**. 19 findings, 17 applied.

All four independently confirmed every prior recommendation had landed **in the code**, not just in
the plan. The highest-value findings were about *this change's own tests* — three of mine were
vacuous and would never have failed:

| id | sev | issue | disposition |
|----|-----|-------|-------------|
| quality-14 | BLOCKER | Suite was red — the contract was 121 lines against its own ≤120 cap | **applied** — compressed to exactly 120 with every rule intact |
| quality-15 | MAJOR | Three golden tests loop over a fixture section; emptying it made the loop body never run and the test pass green | **applied** — `golden_section` now fails loudly on an empty result |
| quality-16 | MAJOR | The ALLOWED-field check was an unanchored substring match, so deleting `Recommendation:`, `Impact:`, `Open:` or `Ask:` went undetected (4 of 6 fields unprotected) | **applied** — anchored to `^ *field:`; all six deletions now fail |
| skeptic-16 | MAJOR | The panel-vocabulary test asserted the banned words were **present** — inverted polarity. Deleting the entire translation rule left it green | **applied** — inverted to assert absence from the layer-1 block, plus a separate positive check that the rule still exists |
| skeptic-17 | MAJOR | The artifact-field-leak guard ran only against v-work, but `Converged plan` / `Proposed test backlog` only ever existed in v-team's block | **applied** — loop now covers both files |
| comms-1 | MAJOR | `05-commit-capture.md` §5.6 — the last thing the user reads each session — was never bound and still mandated `Tests: [all passing]` / `Review: [PASS]`, exactly what the contract bans | **applied** — bound + rewritten; green lines omitted, failures/skips/warnings always printed |
| arch-14 | MINOR | The output-styles prune sat inside `if [ -d STYLES_DIR ]`, so dropping the tree would leave symlinks dangling forever | **applied** — prune made unconditional, symmetric with the commands tree |
| arch-16 | NIT | Activation banner gated on the source file, not the link, so a REFUSED run still advertised the style | **applied** — gated on the installed symlink |
| comms-2 | MINOR | "cuts green, never amber" — a 27-word sentence opening with an undefined traffic-light metaphor, in the section banning metaphors | **applied** — "cuts good news, never warnings" everywhere |
| comms-3 | MINOR | "blast radius" prescribed as the definition of a user-facing field, in a contract banning metaphors | **applied** — "what this touches" |
| comms-4 | MINOR | Section heading said "Assume **he** has read nothing" | **applied** — "the user" |
| comms-5 | MINOR | "Progressive disclosure" is a UX term of art used as a heading in the file that bans jargon | **applied** — "Verdict first, detail on request" |
| comms-6 | NIT | The 15-line cap didn't say whether table chrome counts | **applied** — header/separator rows excluded |
| skeptic-18 | MINOR | Style said "about 15 lines", contract said "capped at 15 lines" — the duplicates had already drifted | **applied** — aligned, plus a new cross-file parity test (one probe per contract section) |
| skeptic-19 | MINOR | A capped run with several minority flags cannot satisfy both the 15-line cap and the always-surface list; no rule said which wins | **applied** — impact + warnings are never cut; the cap yields |
| skeptic-20 | MINOR | Plan said "11 sections" then listed 12, and labelled step 4 "net deletion" when the file grew 43 lines | **applied** — count fixed; label now says the deletion is in what the *user reads* (13 fields → 6) |
| skeptic-21 / quality-18 | NIT | The style dropped the verdict-first disclosure rule and buried the outward-facing clause under an unrelated heading | **applied** — both restored, parity test extended to 12 probes |
| quality-17 | MINOR | `grep -qi '15'` was subsumed by `grep -qi '15 lines'`, so the ~15-word average rule was unguarded | **applied** — pinned to the actual rule |
| quality-19 | MINOR | The fixture's `ALWAYS-EMITTED` section was never read by any test — tokens were duplicated as literals | **applied** — driven from the fixture |
| quality-20 | NIT | Binding blockquote sits above the H1 in dispatchers, below it in step files | **not applied** — cosmetic, byte-identical everywhere, no functional impact |
| quality-21 | NIT | Staged index was behind the working tree during review | **applied** — re-staged and re-run before commit |

**Mutation testing (the strongest evidence in this session).** Every previously-surviving mutant was
re-run after the fixes and is now killed: emptying the fixture's ALLOWED section · deleting `Impact:`
from the layer-1 template · changing the 15-word average to 40 · deleting the style's outward-facing
clause · re-adding a `Convergence:` field to the v-team user layer. Earlier rounds also killed:
removing a contract section, reintroducing a duplicate brevity rule, making the style delegate,
dropping the installer's prefix guard, and breaking `ln -sfn`.

_Metrics — diff review round 1: findings 19 (1 BLOCKER, 8 MAJOR, 7 MINOR, 3 NIT) · confirmed 19,
advisory 0 · applied 17, not-applied 1 (cosmetic), superseded 1 · **new confirmed BLOCKERs after
fixes: 0** · tests 215 → 218 unit + 50 integration, all green · **sycophancy flag: none** — three of
four critics held REQUEST_CHANGES against work they had already approved at plan stage, and the
majority of findings targeted the author's own tests rather than the design._

**Stop condition:** no new confirmed BLOCKER/MAJOR remained after the fixes; `team_max_review_rounds`
not exhausted (1 of 2 used).

## Refs

[[decision-communication]] · [[llm-collaboration-patterns]] · [[ADR-004-generic-packs-specifics-in-indications]] ·
[[ADR-012-propose-clarify-research-gates]] · [[ADR-017-evidence-based-panel-hardening]]
