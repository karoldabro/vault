---
type: plan
project: vault
slug: decision-communication-contract
status: executed
process_record: 2026-08-03-1045-decision-communication-contract.trail.md
tags: [plan, team, communication, ux]
---

# decision-communication-contract — team plan

Make every v-* command write to the user like a competent employee writes to a decision-maker:
answer first, short, no jargon, options with consequences.

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
eight reconciled contradictions, and all citations) live in `vault/research/decision-communication.md`,
created by step 11** — this plan cites by id only.

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

## Plan

The rules these steps produce are owned by `commands/_shared/communication.md`; that file is the
authority on their wording. This table records what was built, where, and why.

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
| c-t1 | plan | unit | contract has all 12 named sections **and** the fixed-template clause; `tests/unit/communication-contract.bats` pins the `## ` heading count at 13 | can't be silently gutted | must |
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
- **Binding blockquote placement is inconsistent, and stays that way.** It sits above the H1 in the
  `commands/v-*.md` dispatchers and below it in the step files. The text is byte-identical in both
  places and nothing reads its position, so this is an accepted deferral, not an open item.

## Refs

- [[decision-communication]] · [[llm-collaboration-patterns]] · [[ADR-004-generic-packs-specifics-in-indications]] ·
  [[ADR-012-propose-clarify-research-gates]] · [[ADR-017-evidence-based-panel-hardening]]
- New: [[ADR-018-decision-communication-contract]]
- Process record: `vault/plans/2026-08-03-1045-decision-communication-contract.trail.md` — findings, dispositions, rejected options.
