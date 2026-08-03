---
type: decision
id: ADR-018
project: vault
status: accepted
date: 2026-08-03
tags: [decision, communication, ux, commands, output-style]
---

# ADR-018 — A shared contract for how commands write to the user

## Context

3,179 lines of command instructions governed *what* the framework does and **nothing** governed how it
writes to the person running it. The only brevity rules in the tree were `v-ask.md`'s "Lead with the
answer" and `/v-cr`'s rule for forge comments — neither reaching plans, questions, or approval gates.

The user reported the consequence directly: questions that are impossible to answer, jargon only an
agent understands, references to plans and files he has not read, explanations of explanations,
status about things that are working, decorative metaphors, and volume that drains him across
multiple projects. He asked for the established playbooks rather than invented style rules.

A three-agent research sweep produced [[decision-communication]] — corporate/military doctrine (BLUF,
Minto, Amazon memos, SBAR, Completed Staff Work, plain-language standards), the academic evidence
(cognitive load, jargon, question design, choice architecture, human-AI decision support), and vendor
guidance. A four-critic panel over two rounds filed 45 findings; 44 changed the plan.

Two facts shaped the design more than any other. **The framework's own output templates were the
mechanical cause** — `## Required output` blocks mandating always-on fields like `Serena rules:
[... or "not available"]`. And **an output style cannot reach spawned subagents**, so a global setting
alone would leave the panel — the largest text generator — untouched.

## Decision

1. **One shared module, `commands/_shared/communication.md`**, bound at the top of all 12 `v-*.md`
   dispatchers and all 15 step files owning a `## Required output` block, via the resolvable installed
   path `~/.claude/commands/_shared/communication.md`. Precedent: `_shared/critic-panel.md`.
   Scope: **user-facing prose only** — never machine-read schemas, vault documents, commit messages,
   or reasoning. Capped at 120 lines, because a bloated instruction file gets ignored (R-18).

2. **Two-layer output.** The `## Required output` blocks in `v-work/steps/03-propose.md` and
   `v-team/steps/03-propose-loop.md` were **rewritten as a net deletion**, not extended. Layer 1 to
   the user (≤15 lines): `Recommendation · Impact · Options · Assumed · Open · Ask`. Layer 2 to the
   plan artifact: research, Serena memories, critic findings, implementation steps, test plan, vault
   writes, index updates. The user is told the artifact exists; never required to open it to decide.

3. **`Impact` is mandatory at every approval gate.** Approving authorizes a blast radius; a summary
   that omits which files, migrations and coupled projects change converts the gate into a rubber
   stamp. It is the last thing cut, never the first.

4. **Omit-when-empty, scoped to green states only.** No "skipped", "not available", "0 findings". But
   a skipped gate, a tool that fell back, `research: unavailable`, a stated safe default, a minority
   flag, an open blocker, and `CONVERGENCE: capped` are **exceptions** and always surface. The rule
   was written to kill green status lines; it must not take the amber ones with them.

5. **An ask gate before the question-shape rules.** Ask only when the answer changes what gets built
   *and* you cannot settle it yourself. If you cannot name each option's consequence, you do not
   understand the choice well enough to ask. Then: 2–4 options, each with what the user gains and
   gives up, recommendation first, stem ≤2 sentences, no jargon.

6. **The synthesizer caps what reaches the user** (`03-propose-loop.md` §(e).7), and the contract
   rides in the critic envelope for the free-text `issue`/`recommendation` fields (§(c)). This is the
   **only** mechanism covering subagent-authored text. Panel vocabulary (`BLOCKER`, `advisory`,
   `persona`, `convergence`, `grounding`) is translated to plain words, never transcribed.

7. **An opt-in global output style**, `output-styles/director.md`, linked by the installer into
   `~/.claude/output-styles/`. It restates the rules **self-containedly** — a style is injected into
   the system prompt and cannot read repo files, so a pointer would be a no-op. Activation is
   `/config` → Output style → *director* (`/output-style` was removed in Claude Code v2.1.91).

8. **`/v-cr`'s forge-comment brevity rule is kept**, explicitly marked non-superseded. Those comments
   are read by teammates on a forge — a different audience with a different reader model. The contract
   defers to it in an "outward-facing text" section rather than absorbing it.

9. **The installer was refactored** to `link_tree` / `prune_stale` helpers rather than a third
   copy-paste. `prune_stale` takes the source prefix as a **parameter**, never inferred — dropping
   that guard would delete a user's own dangling symlinks. Characterisation tests for the two
   previously-uncovered branches were added *before* the refactor.

## Consequences

**Positive.** All twelve of the user's stated complaints are covered, each by a named contract section
and a test. Total output shrinks rather than gains a summary layer. The rules are cited to primary
sources, so they can be argued with. The global style extends the fix to sessions that never run a
v-* command. The installer refactor removes three duplicated symlink blocks and closes two untested
branches.

**Negative / accepted.** **Behaviour is not guarded.** All 27 new tests are file contracts — they
prove the rules exist, not that the framework obeys them. The golden fixture
(`tests/fixtures/propose-output.txt`) is a **drift detector** for the output template, not a
behavioural test: neither test image ships a `claude` CLI and the repo mounts read-only. A Stop-hook
length linter is the only deterministic fix and is deliberately out of scope.

The output style **does not reach subagents** — decision 6 is the compensating control, and if a new
command spawns agents without routing through a capped synthesizer, its output is ungoverned.

The contract hard-codes **one reader**: a technical director who wants decisions over derivations and
asks when he wants depth. This is explicit, not universal. Expertise reversal (R-04) does **not** hold
in ill-structured domains, so the depth rules retain worked reasoning for novel design decisions —
stripping it there would make recommendations uncheckable.

Prose governing prose decays. Mitigated three ways (guard tests on the artifact, the style's
mid-conversation re-injection, the 120-line cap); solved by none.

## Refs

[[decision-communication]] (evidence base) · [[user-facing-communication]] (working rule) ·
[[llm-collaboration-patterns]] (agent↔agent sibling) · [[ADR-004-generic-packs-specifics-in-indications]] ·
[[ADR-012-propose-clarify-research-gates]] · [[ADR-017-evidence-based-panel-hardening]] ·
[[2026-08-03-1045-decision-communication-contract]] (plan)
