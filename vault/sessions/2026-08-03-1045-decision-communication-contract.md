---
type: session
project: vault
date: 2026-08-03
topic: decision-communication-contract
files_touched: [commands/_shared/communication.md, output-styles/director.md, install.sh, commands/v-work/steps/03-propose.md, commands/v-team/steps/03-propose-loop.md, commands/v-work/steps/05-commit-capture.md, tests/unit/communication-contract.bats, tests/unit/propose-golden.bats, vault/research/decision-communication.md]
decisions: [ADR-018]
tags: [session, communication, ux, commands]
---

# decision-communication-contract

## Goal

Fix how every v-* command writes to the user — short, plain, decision-ready — grounded in
established professional-communication playbooks rather than invented style rules.

## Did

- Ran a **three-agent research sweep** (~30 searches, primary sources fetched) across corporate/military
  doctrine, the academic evidence, and AI-vendor guidance → [[../research/decision-communication]].
- Clarify gate: asked two questions with consequences. User chose **recommendation-first-then-alternatives**
  (over a bare recommendation or an undecided menu) and **v-* commands + a global output style**
  (over commands only).
- Two plan-critique rounds, 4 ad-hoc critics (framework-architect, quality, skeptic, exec-communication):
  **45 findings, 44 applied** → [[../plans/2026-08-03-1045-decision-communication-contract]].
- Implemented 17 workstreams; one EXECUTE diff-review round: **19 findings, 17 applied**.
- Created `commands/_shared/communication.md` (120 lines, 12 sections), bound by installed path in
  12 dispatchers + all 15 `## Required output` step files + 4 more user-facing step files (31 total).
- Rewrote both `## Required output` blocks as a **two-layer split**; deleted `v-ask.md`'s duplicate
  brevity rule; kept and annotated `/v-cr`'s forge-comment rule.
- Created `output-styles/director.md`; refactored `install.sh` to `link_tree`/`prune_stale` and
  linked a second tree into `~/.claude/output-styles/`.
- Wrote [[../decisions/ADR-018-decision-communication-contract]], [[../indications/user-facing-communication]],
  and 27 new tests. Suite 181 → **218 unit + 50 integration**, all green.

## Learned

- **The framework's own output templates were the cause.** `## Required output` blocks mandated
  always-on fields like `Serena rules: [... or "not available"]` — the user's "it mentions things that
  are working" was our spec, not model drift.
- **A Claude Code output style reaches the main conversation only — never spawned subagents.** So a
  global style alone would have left the critic panel, the single largest text generator, untouched.
  `03-propose-loop.md` §(e).7 is the compensating control.
- **`/output-style` was removed in Claude Code v2.1.91** (deprecated v2.1.73). Activation is `/config`
  → Output style, or the `outputStyle` setting. Caught by a critic *after* I had told the user to run
  the dead command.
- **Expertise reversal does not hold in ill-structured domains** (Nievelstein 2013 vs Tetzlaff 2025).
  Framework design is ill-structured, so "strip explanation for the expert" needed a counter-condition
  — worked reasoning is retained on novel decisions.
- **Defining jargon does not repair it** (Shulman 2020) and its cost shows up as *silent disengagement*,
  not complaints (Bullock & Bisbey 2025). The user stops pushing back rather than objecting.
- **A hard question yields a confidently wrong answer, not "I don't know"** (Krosnick). A badly framed
  question manufactures a fake decision — worse than not asking.
- **`prune_stale` must take the source prefix as a parameter.** The pre-existing "unrelated symlink"
  test used a target that *exists*, so it would still pass if the prefix guard were dropped — a
  dangling foreign symlink was needed to actually cover it.
- **Three of my own tests were vacuous** and only mutation testing found them: a loop over an empty
  fixture section passes green; an unanchored substring grep for `Impact:` is satisfied by the prose
  "the `Impact` line"; and the panel-vocabulary test asserted the banned words were *present*
  (inverted polarity) — deleting the whole translation rule left the suite green.
- **BLUF, Minto, the Amazon 6-pager, DACI, ADR and Completed Staff Work have zero controlled evidence.**
  Widely adopted, institutionally enforced, never tested. Only NN/g, GOV.UK's readability research and
  the cognitive-load/jargon/decision literature carry measured numbers.

## Behaviors & rules

- A command produces user-facing prose → it binds `~/.claude/commands/_shared/communication.md` by
  installed absolute path; edge: a repo-relative path cannot resolve from another project's cwd.
- An approval gate is presented → the `Impact` line (files · migrations · coupled projects) is present;
  edge: when the 15-line cap binds, options and assumptions are cut before impact, never the reverse.
- A field has nothing to report → it is omitted entirely; edge: a skip, fallback, unavailable tool,
  stated safe default, minority flag or open blocker is an exception and is always emitted, however brief.
- A question is considered → it is asked only if the answer changes what gets built AND cannot be
  settled from vault/code/research; edge: if each option's consequence cannot be named, the choice is
  not understood well enough to ask about.
- A critic panel surfaces findings → framework vocabulary (`BLOCKER`, `advisory`, `persona`,
  `convergence`, `grounding`) is translated to plain words; edge: the schema itself is machine-read
  and unaffected.
- Text is posted outside the conversation (forge comment, customer reply) → its own command file owns
  its conventions; edge: it must not be deleted as a duplicate of the shared contract.
- An installer links a tree → prune keys off the source prefix passed as a parameter; edge: a user's
  own dangling symlink in the same target dir survives.

## Next

- **Behaviour is unguarded.** All 27 new tests are file contracts; the golden fixture is a drift
  detector, not proof output is short. A Stop-hook length linter is the deterministic fix — deliberately
  out of scope.
- The `director` output style is **opt-in and off**. User must run `/config` → Output style → director.
- `commands/_shared/communication.md` and `output-styles/director.md` are deliberate duplicates (a
  style cannot read repo files). Parity is guarded by one probe per section — watch for drift.
- Not applied (cosmetic): the binding blockquote sits above the H1 in dispatchers, below it in step files.
- Merge `feat/decision-communication-contract` → main when ready.

## Refs

[[../decisions/ADR-018-decision-communication-contract]] · [[../research/decision-communication]] ·
[[../indications/user-facing-communication]] · [[../plans/2026-08-03-1045-decision-communication-contract]] ·
[[../research/llm-collaboration-patterns]] · [[../decisions/ADR-012-propose-clarify-research-gates]] ·
[[../decisions/ADR-017-evidence-based-panel-hardening]] · [[../decisions/ADR-004-generic-packs-specifics-in-indications]] ·
[[2026-07-03-1205-propose-clarify-research-gates]] · [[2026-07-10-1740-llm-collaboration-patterns]]
