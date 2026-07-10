---
type: research
project: vault
slug: llm-collaboration-patterns
status: living   # update as evidence changes; cite from ADRs/plans when changing panel mechanics
date_researched: 2026-07-10
tags: [research, llm, multi-agent, personas, v-team]
---

# LLM collaboration patterns — a source-cited catalog

How companies and researchers structure human+LLM work, across **development, marketing, sales,
planning/strategy, and customer support**, plus the **cross-domain foundations** evidence. Compiled
2026-07-10 by a five-agent research sweep (~150 sources); shaped by a 2-round critique panel.
**Living doc** — the evidence reference for panel-mechanism changes ([[ADR-017-evidence-based-panel-hardening]]).

## §0 How to read

- **Maturity:** `production-proven` (multiple named deployments) · `emerging` (real but young/contested)
  · `speculative` (plausible, thin evidence).
- **Evidence strength** (§1 only): `strong` (peer-reviewed / replicated / authoritative practitioner)
  · `mixed` (results conflict) · `weak`.
- **Fit:** how the pattern maps onto this framework (/v-team panels, /v-work lifecycle, /v-cr, /v-pm,
  business persona packs).
- IDs are stable — cite as `[[llm-collaboration-patterns]] §F-07` etc.

---

## §1 Foundations — what the evidence actually supports

The load-bearing findings. Anything here overrides vibes in the domain sections.

**F-01 — Debate helps, but often loses to plain self-consistency.** Multi-round debate beats a single
model on math/factual QA and can recover from all-agents-wrong starts (Du et al., arXiv 2305.14325) —
but at equal compute, sampling N independent answers + majority vote frequently matches or beats it
(2025 replications). *Strength: strong-for-debate>single, mixed-vs-self-consistency.* **Fit:** default
to independent-parallel-critics + aggregation, not cross-talk — reaffirms [[ADR-001-panel-loop-over-peer-debate]].

**F-02 — Intrinsic self-correction doesn't work.** Without external feedback, models converge to their
first answer and can't locate their own reasoning errors — but CAN fix errors when the location is
given (Huang et al., ICLR'24, arXiv 2310.01798). *Strong.* **Fit:** "review your own plan" loops are
low-yield; every critic must bring something the author didn't have.

**F-03 — Tool-interactive critique is the active ingredient.** Generate → verify-with-external-tool →
correct consistently improves QA/math/toxicity with no retraining (CRITIC, ICLR'24, arXiv 2305.11738).
*Strong.* **Fit:** validates [[ADR-003-tool-grounded-findings]]; formalized as the confirmed-vs-advisory gate.

**F-04 — The generation-verification gap widens with tool asymmetry.** Verifying is discriminative
(spot one flaw), generating is constructive (build a perfect whole); verifiers reach high accuracy at
1–3× fewer tokens, and the gap grows when the judge can execute code / query data the generator
couldn't (arXiv 2508.16665, 2506.18203). *Strong.* **Fit:** the highest-leverage upgrade — arm critics
with verification affordances the planner lacked. Adopted: ADR-017 Decision 1.

**F-05 — LLM-as-judge biases are systematic.** Position, verbosity, and self-preference biases are
independent of quality; position is fixable (swap/average), verbosity + self-preference are baked in
(llm-judge-bias.github.io; arXiv 2410.21819). *Strong.* **Fit:** randomize finding order, penalize
length, mask author identity; cross-family judging noted as a single-model-install limitation (ADR-017).

**F-06 — Sycophancy collapses debates.** In multi-round debate, correct→incorrect flips outnumber the
reverse from round 2; agents abandon right answers under social pressure (arXiv 2509.05396 — 3 agents
44.4%→39.4%; 2509.23055). *Strong.* **Fit:** hard round caps (have), dissent preservation + sycophancy
drop-metric (adopted: ADR-017 Decision 3), never force consensus.

**F-07 — Decorrelation is the load-bearing assumption.** Ensembles improve only when member errors are
uncorrelated; shared misconceptions get *amplified* by majority vote; one deceptive agent tanks a
mixture-of-agents stack (MoA ICLR'25, arXiv 2406.04692; 2503.05856). *Strong.* **Fit:** critics must
own genuinely different evidence sources, not stylistic reskins; measure per-persona overlap (§(e)
metrics). This finding killed the proposed premortem seat (ADR-017 Decision 2).

**F-08 — Structured heterogeneity beats homogeneous panels AND naive model-mixing.** Distinct
specialized roles: heterogeneous 2-agent ≈ homogeneous 16-agent (A-HMAD, Springer 2025, +4–6pp, >30%
fewer factual errors); mixing models WITHOUT role differentiation is inconsistent (arXiv 2602.03794).
*Strong/mixed.* **Fit:** the persona structure IS the mechanism — one distinct evaluative jurisdiction
per critic (`_resolution.md` §2 selection rules).

**F-09 — Persona prompting: divergence yes, correctness no.** Expert personas help advisory/open-ended
tasks and idea diversity but yield no gain — sometimes a loss — on objective factual QA (EMNLP'24
Findings; arXiv 2605.29420, 2408.08631). *Mixed.* **Fit:** personas for surfacing different risks;
plain instructions for mechanical checks. Already encoded in `_persona-template.md` ("critique lens,
not a competence boost").

**F-10 — Reflection works only on a real signal.** Reflexion's gains come from converting environmental
feedback (test fail, tool result) into stored lessons — not from reflection prose (NeurIPS'23, arXiv
2303.11366). *Strong (conditional).* **Fit:** rounds must carry concrete outcomes (which check failed),
not "the critic said improve X" — the §(d) `check:` field.

**F-11 — Rubrics, checklists, structured output are cheap strong levers.** Per-criterion structured
scoring (field + justification + score, ONE dimension at a time) beats holistic "rate this"; yes/no
checklists raise judge reliability and human agreement (arXiv 2606.08625, 2601.08654; TICK). *Strong.*
**Fit:** higher-ROI than adding critics; the persona rubric+checklist+schema shape is right — never ask
for one blended score.

**F-12 — Start simple; escalate topology only when it wins.** Anthropic's canon: workflows for
well-defined tasks, agents only for open-ended ones; the five orchestration patterns (chaining,
routing, parallelization, orchestrator-workers, evaluator-optimizer) — "find the simplest solution
possible" (anthropic.com/research/building-effective-agents). *Authoritative.* **Fit:** the
/v-ask→/v-do→/v-work→/v-team ladder + ADR-015 fast path ARE risk-based routing; keep the panel for
stakes that justify it.

**F-13 — Multi-agent decisively wins read-heavy parallel search.** Anthropic's orchestrator-worker
research system beat single-agent by 90.2% on breadth-first tasks — isolated context windows each
explore a slice and return distilled summaries (anthropic.com/engineering/multi-agent-research-system).
*Strong, domain-specific.* **Fit:** panels and research fan-outs are exactly this regime; critics READ
in isolation, return condensed findings.

**F-14 — Multi-agent fails when agents WRITE in parallel.** Parallel actors embed conflicting implicit
decisions a coordinator can't reconcile; share full traces; default to a single-threaded writer
(Cognition "Don't Build Multi-Agents"; 2026 update "Multi-Agents: What's Actually Working": multiple
agents contribute *intelligence*, writes stay single-threaded; reviewers with CLEAN context catch what
the fatigued builder misses). *Strong (practitioner).* **Fit:** read-fan-out / single-synthesizer /
single-writer split — /v-team's exact shape; give critics isolated context, not the builder's trace.

**F-15 — Most multi-agent failures are orchestration bugs.** MAST taxonomy (NeurIPS'25, arXiv
2503.13657; 200+ tasks): step repetition ~15.7%, unaware-of-termination ~12.4%, spec-disobedience
~11.8% — robustness needs better orchestration, not bigger models. *Strong.* **Fit:** explicit
termination conditions (round caps — have), progress guards, strict role adherence, dedicated
verification stage.

**F-16 — Human gates: risk-targeted, not uniform.** Inside the AI's competence frontier, +40% quality;
outside it, humans over-trust and become 19pp MORE wrong (HBS/BCG jagged-frontier). Automation
complacency is real; increased verification effort counters it. *Strong.* **Fit:** cheap auto-accept
for confirmed low-risk findings; mandatory human review near the frontier (novel/ambiguous/high-stakes)
— bind gate strictness to risk, surface WHY a finding is uncertain.

**F-17 — Synthetic personas as simulated stakeholders: bounded validity.** Interview-grounded
generative agents reproduce individuals' survey answers ~85% as well as the people reproduce their own
(Park et al., UIST'23; Stanford HAI 1,000-person sim) — but synthetic users flatten messy real humans;
directional only (NN/g critique). *Mixed.* **Fit:** hypothesis-generation lens (what would security/
ops/the buyer object to?), never ground-truth user research. Tier-2 backlog: synthetic-customer class.

---

## §2 Development

**D-01 — Orchestrator-workers (lead + parallel subagents).** Lead decomposes, spawns 3–5 isolated-
context subagents with explicit objective/format/tool scope, synthesizes; effort scaled to complexity.
Anthropic research system (+90.2% vs single-agent). *Production-proven (read-heavy).* **Fit:** the
panel is this; also the research fan-out used to build this catalog.

**D-02 — Single-threaded writer.** All code-writing on one linear thread; parallel writers make
conflicting implicit decisions (Cognition, Devin). *Production-proven.* **Fit:** guardrail — critics
fan out read-only; EXECUTE stays single-writer.

**D-03 — Multi-intelligence, single-writer (2026 refinement).** Advisor agents + clean-context
reviewers + "smart friend" consultant routing + hierarchical delegation — writes stay single
(Cognition). *Emerging.* **Fit:** give critics ISOLATED context so they don't inherit the builder's
blind spots.

**D-04 — Actor-critic adversarial loop.** Generator writes; adversarial critic assumes-broken and
enumerates issues; loop 3–5 rounds to approval/cap. Cuts human review cycles 3–5→1–2
(understandingdata.com). *Emerging.* **Fit:** /v-team's loop; the "assume it's broken" framing is the
skeptic's mandate.

**D-05 — LLM-as-judge with a rubric (single scalar).** One prompt scoring 0–1 + pass/fail against an
explicit rubric was MORE consistent than multiple specialized judges for Anthropic's eval use.
*Production-proven.* **Fit:** convergence could be scored, not vibes — candidate future metric; note
tension with F-11's per-criterion advice (different use: eval-of-output vs critique-generation).

**D-06 — Self-consistency / N-version voting.** Sample N diverse paths (or judge verdicts),
majority-vote (arXiv 2510.12803 lineage). *Production-proven (reasoning).* **Fit:** for high-stakes
verdicts, run a critic N× and vote instead of trusting one pass — cheaper than debate (F-01).

**D-07 — Research → Plan → Implement with persisted artifacts.** Discrete phases each producing an
artifact before code; 7-step pipeline, each step <40 instructions (12-Factor Agents / HumanLayer).
*Production-proven.* **Fit:** ANALYZE→PROPOSE→EXECUTE already; the plan artifact (plans/) is the
persisted design doc.

**D-08 — Spec-driven development.** The spec is the durable contract; plan/tasks/code/tests generate
FROM it and validate AGAINST it (GitHub Spec Kit, AWS Kiro, Tessl; Fowler's SDD series).
*Production-proven.* **Fit:** the converged plan = the spec critics review AND the implementer + tests
validate against; /v-pm `requirements.md` REQ-NN chain is this idea for business logic.

**D-09 — Architect/editor model split.** Reasoning model describes HOW; editing model converts to
precise file edits — SOTA on aider's benchmark (85%). *Production-proven.* **Fit:** Tier-3 backlog —
plan passes to a cheaper edit-focused model in EXECUTE.

**D-10 — TDD as a leash.** Failing-test-first keeps agents from stalling under accumulated complexity
(Kent Beck); known failure: the agent deletes/weakens tests to go green — watch for it.
*Production-proven.* **Fit:** critics can require a failing test per change; a test-deletion guard in
diff review is a cheap add (testing group's jurisdiction).

**D-11 — Ralph loop (stateless iterate-to-done).** Infinite shell loop re-reading the same PROMPT.md,
filesystem as memory, ruthless per-iteration context reset; overnight runs, six concurrent worktree
loops shipped six ports (~$600, 1000+ commits — ghuntley.com/ralph). *Emerging.* **Fit:** Tier-3 —
post-approval overnight mode grinding a fully-converged spec.

**D-12 — Worktree isolation for parallel implementers.** One git worktree per writing agent; 4–8
concurrent worktrees/dev is routine; bottleneck becomes human review. *Production-proven.* **Fit:**
when the plan has independent workstreams, dispatch each to an isolated worktree subagent.

**D-13 — Deterministic workflow scaffold.** Control flow in code, LLM decisions only within phases;
small focused prompts, few tool choices each (12-Factor Agents; Claude Code workflows).
*Production-proven.* **Fit:** the v-work/v-team fixed phase order + gates is exactly this; keep loops
deterministic (caps), not model-decided.

**D-14 — Context engineering: compaction + progressive disclosure + agentic memory.** Token budget as
the constraint; lightweight identifiers, fetch on demand, clear when done; notes persisted outside
context (Anthropic). *Production-proven.* **Fit:** the vault + OV + cheapest-first LOAD CONTEXT stack
is this discipline; formalized in the search-precedence rule.

**D-15 — Eval-driven development, inverted.** Hamel Husain: write evaluators for errors you DISCOVER
(error analysis first), not errors you imagine. *Production-proven (practitioner).* **Fit:** matches
test triage's strict keep-gate; don't pre-write eval suites for imagined failure modes.

---

## §3 Marketing

**M-01 — Synthetic audience / AI focus group.** Persona populations pressure-test messaging before
spend (AskRally, Deepsona; SSR ~90% human reliability, NeurIPS'25 ~95% survey correlation —
directional only, F-17 caveats). *Emerging.* **Fit:** Tier-2 synthetic-customer lens for the marketing
pack — advisory-only by construction.

**M-02 — Multi-agent buyer-committee simulation.** Simulate the 6–13-person B2B buying committee as
distinct agents reacting to a pitch/campaign (arXiv 2510.18155; 6sense). *Emerging.* **Fit:** the
strongest business analog of a critic panel — each committee role is a lens.

**M-03 — Generator → editor → fact-checker pipeline.** Staged content production with distinct QA
gates per stage (Acrolinx/Markup AI; Yotpo). *Production-proven.* **Fit:** validates staged
generate→critique→gate; brand/copy lens + data-evidence critic are the editor/fact-checker seats.

**M-04 — Brand-voice system + style guard.** Codified voice + RAG governance metadata; every asset
checked against it (Jasper, Acrolinx). *Production-proven.* **Fit:** the marketing pack's Brand & Copy
lens with a real style-guide analyzer = tool-grounded brand critique.

**M-05 — Enterprise AI copywriting with human review ratio.** Klarna Copy Assistant: 80% of copy,
$10M/yr saved, 6wk→7day cycles — with brand+quality+legal human checks retained. *Production-proven,
hard numbers.* **Fit:** the draft-heavy/human-gate split; gates are where quality survives scale.

**M-06 — Campaign pre-mortem + red-team.** Attack the campaign before launch (Asana premortem practice
+ Promptfoo-style adversarial probing). *Production (fusion emerging).* **Fit:** skeptic's pre-mortem
technique (ADR-017) applied to campaign briefs via the marketing pack.

**M-07 — A/B variant generation + surrogate pre-screening.** LLM generates variants, a
predictor pre-screens CTR before live traffic (Meta ad-text RL; arXiv RL-LLM-ABTest).
*Emerging→production.* **Fit:** generate-wide/filter-cheap before human review — pairs with
high-variance ideation (P-16).

**M-08 — GEO / AI-visibility workflow.** Optimizing for AI-engine citation; brand mentions ≈3×
backlinks for AI visibility (Profound, Omnius). *Emerging.* **Fit:** already a seo-pack lens (AI
Visibility/GEO — ADR-016).

---

## §4 Sales

**S-01 — AI-SDR with human-in-loop gates.** Autonomous outreach drafting, human approval gates at send
(Salesforce Agentforce SDR, HubSpot Breeze). *Production-proven.* **Fit:** draft-never-send is already
the givore-support / sales-pack posture; gates at the irreversible step.

**S-02 — Signal-based prospect research pipeline.** 150+ source enrichment → scored signals → tailored
outreach (Clay $3.1B, Outreach). *Production-proven.* **Fit:** research fan-out + evidence-linked
scoring; the sales pack's ICP lens grounded in real enrichment data.

**S-03 — Objection-handling roleplay simulator.** Adversarial buyer personas train reps; 3× faster
ramp (Nooks, Gong AI Trainer). *Production-proven.* **Fit:** adversarial-buyer critique of a pitch =
war-game mode for the sales pack (Tier 2).

**S-04 — Deal-review red team.** Win/loss-trained model interrogates open deals (Clari Deal
Inspection, 98% forecast accuracy claim). *Production-proven.* **Fit:** skeptic + data-evidence
co-review of deal/proposal docs — the panel applied to pipeline reviews.

**S-05 — Hybrid ICP/lead scoring with interrogable verdicts.** Governed human rules + AI signals;
every score carries top-3 reasons (GTM Strategist, Warmly). *Production-proven.* **Fit:** the
human-policy vs AI-judgment split + explainable verdicts — same shape as confirmed-vs-advisory with
cited checks.

**S-06 — Call-summary → CRM auto-update, confidence-gated.** High-confidence fields auto-commit;
low-confidence route to human (Rework, Apollo). *Production-proven.* **Fit:** the reusable mechanic:
confidence-gated commit — Tier-2 candidate for /v-cr auto-posting.

**S-07 — Unified GTM workflow fabric.** One orchestration shell across marketing+sales content ops
(Copy.ai, HubSpot Breeze). *Production-proven.* **Fit:** the multi-pack seating (`use: [sales,
marketing]`) is the panel-level version.

---

## §5 Planning / Strategy / PM

**P-01 — Virtual board of advisors.** Named leadership lenses with fixed domains + challenge prompts,
consulted on consequential decisions; dynamic roster (MIT SMR, Vipin Gupta). *Emerging.* **Fit:**
persona-pack template for a leadership/strategy pack; swappable rosters per decision type.

**P-02 — Panel-of-experts thinker prompt.** Simulated Porter/Christensen/Drucker panel, each applying
its own framework, then unified recommendation (Sourcery; ExpertPrompting arXiv 2305.14688).
*Production-proven (prompting).* **Fit:** IS the business-panel-experts agent already installed; each
thinker = a method-enforcer lens.

**P-03 — Multi-agent debate for decisions.** Propose→critique→vote across personas. *Emerging,
contested (see F-01/F-06).* **Fit:** keep the panel topology; anonymize identities (authority bias,
arXiv 2510.07517); already rejected as primary topology (ADR-001).

**P-04 — Red/blue team war-gaming.** Offense role-plays the adversary attacking the plan; defense
hardens; iterate rounds (Kriegsspiel lineage; arXiv 2310.00322). *Production-proven in security;
emerging for strategy.* **Fit:** Tier-2 war-game mode: attacker persona + defender for
business/startup-eval packs.

**P-05 — Competitor war-gaming / market simulation.** Model a specific competitor's decision tendencies;
run virtual games against it — counters competitor-neglect bias (McKinsey; FifthRow).
*Production-proven (practice), AI version emerging.* **Fit:** competitor personas as a simulation
lens for market-entry deliverables (startup-eval).

**P-06 — Pre-mortem (prospective hindsight).** "It failed — what caused it?" Past-tense framing beats
conditional "what could go wrong" (~30% better risk identification — Klein; **human-team evidence, no
LLM replication known**). *Production-proven (human method).* **Fit:** adopted as a skeptic TECHNIQUE
(ADR-017 Decision 2 — seat rejected on decorrelation grounds).

**P-07 — Devil's advocate / assumption falsification.** Systematic implicit-assumption extraction,
steelmanning, edge-case hunting (IUI'24 LLM devil's-advocate study). *Production-proven (facilitation);
emerging (codified).* **Fit:** IS the skeptic; the falsification-test output section is worth stealing
into skeptic proposed-tests.

**P-08 — Synthetic users / agent-based simulation.** LLM personas simulate customers for product
decisions; ensemble/model-shuffling reduces single-model bias. *Emerging, hotly contested* (misses
effect magnitude, variance, minority opinions; observational not RCT — arXiv 2605.20767). **Fit:**
first-pass filter lens with a hard-coded validity caveat (F-17).

**P-09 — PRD via iterative critique loop.** 5–10 critique iterations per section; the PRD as a
programming interface for agents (Aakash Gupta; ChatPRD). *Production-proven.* **Fit:** /v-pm
requirements.md authoring could adopt section-wise critic passes.

**P-10 — Acceptance-criteria verification generation.** Spec vs description = verifiability;
quantified thresholds, testable conditions (Kiro; StackRanked). *Emerging→production.* **Fit:** the
"is this testable?" closing lens = the (f2) test-design fan-out's boundary-property-explorer for
business rules.

**P-11 — LLM ensemble forecasting + calibration.** 3–7 diverse models, median aggregation, post-hoc
calibration; human-crowd-level accuracy, still trail superforecasters ~0.02 Brier (Metaculus
tournaments; Bridgewater AIA arXiv 2511.07678). *Emerging.* **Fit:** Tier-3 forecaster lens attaching
calibrated probabilities to strategy claims; import median-aggregation discipline for panel confidence.

**P-12 — Opportunity Solution Tree with AI as method-enforcer.** AI runs Torres's OST discipline on
every node: reframe needs, dedupe, MECE gaps, evidence attachment; qualitative comparison before
premature scoring (Nurijanian). *Emerging (rigorous).* **Fit:** **the strongest unifying insight** —
personas as method-enforcers running a named discipline consistently, not opinion-havers. Adopted into
`_persona-template.md` (ADR-017).

**P-13 — Hybrid prioritization scoring.** LLM gathers evidence for RICE/ICE factors; framework staged
by phase (OST→weighted→RICE→MoSCoW); knows when scoring is premature (Canny, ProdPad).
*Production-proven.* **Fit:** a prioritization lens that forces evidence per factor + stage-
appropriateness rule.

**P-14 — OKR drafting + multi-bot critique.** Draft-bot → review-bot → scoring-bot against
specificity/measurability/ambition/alignment; drafting 5h→2h, quality 2.6→3.9/5 (Projective Group).
*Emerging→production.* **Fit:** the model for rubric-explicit critique of any goal doc (F-11 in the
wild).

**P-15 — Amazon PR/FAQ & six-pager gauntlet.** Work backwards from the press release; LLM enforces
prose rules + removability discipline ("if I removed this line, would the reader err?"); FAQ = built-in
assumption surfacing (theprfaq.com; codified skills). *Production-proven (Amazon), LLM-enforced
emerging.* **Fit:** Tier-2 narrative-gauntlet mode for /v-pm — personas interrogate a PR/FAQ like an
Amazon reading meeting.

**P-16 — High-variance ideation.** Default LLM ideation is high-mean/low-variance (ideas cluster);
CoT + explicit diversity prompts approach human-group dispersion; GPT-4 took 35 of top-40 ideas vs
Wharton students (Meincke/Mollick/Terwiesch SSRN 4708466; HBR Dec'25). *Production-proven (academic).*
**Fit:** when PROPOSE generates options, force diversity explicitly — counters panel groupthink at the
generation stage.

---

## §6 Customer support

**C-01 — Draft-then-review (agent assist).** AI drafts, human edits + approves; 2–3× faster than
writing from scratch (Decagon Agent Assist; Dixa). *Production-proven.* Lesson: assisted mode is a
multiplier, not a failure state. **Fit:** givore-support's draft-never-send posture, validated.

**C-02 — Confidence-tiered routing + dual-condition auto-send.** Autonomous >90% / assisted 70–90% /
escalate <70%; auto-send requires confidence ≥ threshold AND N consecutive human approvals (myAskAI,
Zendesk). *Production-proven.* Lesson: single global thresholds are crude; confidence self-reports
miscalibrate. **Fit:** Tier-2 — the dual-condition gate for /v-cr auto-posting.

**C-03 — Tiered deflection / containment.** AI resolves routine volume; complex/emotional routes to
humans; 20–40% voice containment is healthy (Zendesk $200M AI ARR). *Production-proven.* Lesson:
**Klarna's walk-back** — full automation (700 agents cut) dropped CSAT on complex cases; hybrid beat
full-auto on cost AND satisfaction. **Fit:** scope-gatekeeper thinking = the /v-do guardrail (route by
task risk, F-16).

**C-04 — Answer-with-citations (RAG grounding).** Every claim carries a KB citation; admit-don't-guess
(Google check-grounding API). *Production-proven.* Lesson: citations don't guarantee grounding —
post-hoc rationalization is real; numbers/dates/prices are the top failure source. **Fit:** the
data-evidence critic's recompute-don't-trust rule.

**C-05 — Pre-send hallucination gate.** Post-generation inspection: overconfident ungrounded language,
factual contradiction vs context, entity verification; repair-or-block policy (Decagon supervisor;
Nexumo). *Production-proven.* **Fit:** a final gate after panel convergence for outward-facing
business deliverables (support pack).

**C-06 — Supervisor / policy-critic model.** Second model inspects the first's output against
goals+guardrails, vetoes with rationale; two independent ~90% checks → ~1% joint escape
(1 − 0.1×0.1) ≈ 99% effective (Sierra Agent Studio; Decagon Watchtower). *Production-proven.* Lesson: keep deterministic guardrails alongside the LLM critic.
**Fit:** the strongest industry validation of the whole persona-panel thesis.

**C-07 — Input guardrails / bad-actor detection.** Screen adversarial intent before spending effort;
higher stakes with tool access (Decagon). *Production-proven.* **Fit:** /v-cr's untrusted-input gate
(automated-cr-safety indication) — same class.

**C-08 — Red-line topic auto-escalation.** Hard-coded confidence-INDEPENDENT handoffs: self-harm,
minors, legal/medical/financial advice (Intercom Fin, Decagon). *Production-proven.* Lesson:
high confidence on a red-line topic is exactly the dangerous case. **Fit:** Tier-2 red-line list for
business packs (auto-escalate legal/financial/PII deliverables regardless of panel verdict).

**C-09 — KB gap mining + self-updating KB.** Mine resolved tickets for coverage gaps, auto-draft
candidate articles, detect article conflicts (eGain, Fini). *Emerging→production.* Lesson: ungoverned
auto-ingestion propagates wrong answers. **Fit:** /v-capture's indication-candidate scan is the same
loop for working rules; givore-support's KB-append learning.

**C-10 — LLM-as-judge reply QA.** Grade every reply per-dimension (accuracy, policy, tone, resolution)
with structured justification — never one blended score (Portkey; G-Eval). *Production-proven (eval).*
**Fit:** F-11 in production; the support pack's Quality & Voice lens rubric shape.

**C-11 — Voice-of-customer clustering.** Auto-tag/cluster tickets into friction themes; 85–92%
agreement with human researchers (Enterpret, Unwrap). *Production-proven.* **Fit:** theme-synthesizer
thinking — cluster panel findings across sessions to spot recurring framework weaknesses.

**C-12 — Cross-ticket churn-signal detection.** Account-level (not ticket-level) trajectory: unresolved
clusters, sentiment drift, competitor mentions; 70–80% of churned B2B accounts signaled ≥30 days out
(Enterpret, Mosaic). *Emerging→production.* **Fit:** longitudinal-risk lens — read a sequence, not the
item in isolation.

**C-13 — Red-teaming bots pre-launch.** Structured adversarial testing (prompt injection, secret
leakage, unsafe tools, PII exfiltration via RAG, multi-turn jailbreaks) (Promptfoo, DeepTeam).
*Production-proven.* Lesson: single-turn tests give false confidence. **Fit:** /v-cr sandbox posture;
an adversary pass for any outward-facing automation.

**C-14 — Replay/regression corpus + phased rollout.** Hundreds of replayed conversations per workflow;
5% canary; continuous eval expansion because distributions drift (Decagon). *Production-proven.*
Lesson: static test sets rot. **Fit:** Tier-3 — replay corpus of past panel decisions re-run on
persona/rubric changes.

**Accountability framing:** Air Canada held liable for its chatbot's invented policy (Moffatt v. Air
Canada, 2024 BCCRT 149); Cursor's "Sam" bot invented a policy that hit HN. Shared root cause: the
system never said "I don't know." → any persona speaking for a company needs a refuse-to-confabulate
default.

---

## §7 Cross-cutting takeaways

**The persona × mode matrix.** Patterns factor into WHO critiques (expert thinker, competitor,
customer, devil's advocate, domain lens) × HOW (independent panel, debate, pre-mortem, red/blue
war-game, narrative gauntlet, scoring rubric, simulation). Packs define WHO; modes are techniques
personas run — pre-mortem's seat-vs-technique decision (ADR-017) is the precedent.

**Validated current choices** (pattern → what it confirms):

| Evidence | Framework choice confirmed |
|----------|---------------------------|
| F-01/F-06 debate loses to independent critics; sycophancy | [[ADR-001-panel-loop-over-peer-debate]], [[ADR-002-no-stop-on-approval-alone]] |
| F-03 tool-interactive critique | [[ADR-003-tool-grounded-findings]] / confirmed-vs-advisory gate |
| F-07/F-08 decorrelation, roles | `_resolution.md` §2 selection (cap, decorrelated lenses) |
| F-12/F-16 simplest-topology, risk-targeted gates | /v-ask→/v-do→/v-work→/v-team ladder, ADR-015 fast path |
| F-13/F-14 read-fan-out, single writer | panel reads in parallel, one synthesizer, one implementer |
| F-15 orchestration hygiene | hard round caps, task-list enforcement |
| D-08 spec as contract | plan artifact + /v-pm REQ-NN id chain |
| D-14 context engineering | vault + OV cheapest-first LOAD CONTEXT |
| C-06 supervisor model ≈99% | the panel thesis itself |

**Adopted this cycle (ADR-017):** verifier tool-asymmetry (F-04) · method-enforcer persona framing
(P-12) · pre-mortem as skeptic technique (P-06) · minority-flag dissent surface + critic-owned
grounding + sycophancy metric (F-06).

**Recorded backlog:** Tier 2 — synthetic-customer lens (F-17/M-01/M-02), war-game mode (P-04/P-05/S-03),
PR/FAQ gauntlet for /v-pm (P-15), confidence-gated auto-accept for /v-cr (C-02/S-06), red-line topics
(C-08). Tier 3 — replay corpus (C-14), Ralph-loop mode (D-11), forecaster lens (P-11), architect/editor
split (D-09).

---

## §8 Sources

**Foundations:** arxiv.org/abs/2305.14325 (debate) · arxiv.org/pdf/2310.01798 (no self-correct) ·
arxiv.org/abs/2305.11738 (CRITIC) · arxiv.org/html/2508.16665v1 + arxiv.org/html/2506.18203v1
(verification gap) · llm-judge-bias.github.io + arxiv.org/html/2410.21819v1 (judge biases) ·
arxiv.org/html/2509.05396 + arxiv.org/html/2509.23055v1 + arxiv.org/html/2604.02668v1 (sycophancy) ·
arxiv.org/html/2406.04692v1 (MoA) + arxiv.org/pdf/2503.05856 (deception fragility) ·
link.springer.com/article/10.1007/s44443-025-00353-3 (A-HMAD) · arxiv.org/pdf/2602.03794 (diversity
scaling) · aclanthology.org/2024.findings-emnlp.888/ + arxiv.org/html/2605.29420 +
arxiv.org/pdf/2408.08631 (persona effects) · arxiv.org/abs/2303.11366 (Reflexion) ·
arxiv.org/html/2606.08625v1 + arxiv.org/abs/2601.08654 (rubrics) · anthropic.com/research/
building-effective-agents · anthropic.com/engineering/multi-agent-research-system ·
anthropic.com/engineering/effective-context-engineering-for-ai-agents · arxiv.org/abs/2503.13657
(MAST) · mitsloan.mit.edu SSRN-id4573321 (jagged frontier) · dl.acm.org/doi/10.1145/3586183.3606763
(generative agents) · nngroup.com/articles/ai-simulations-studies/ · mingyin.org/paper/IUI-24/devil.pdf ·
arxiv.org/pdf/2510.07517 (authority bias) · tandfonline.com/doi/full/10.1080/10447318.2023.2301250
(automation complacency).

**Development:** cognition.com/blog/dont-build-multi-agents + /multi-agents-working ·
github.blog spec-driven-development + github.com/github/spec-kit · martinfowler.com/articles/
exploring-gen-ai/sdd-3-tools.html · aider.chat/2024/09/26/architect.html ·
newsletter.pragmaticengineer.com/p/tdd-ai-agents-and-coding-with-kent · ghuntley.com/ralph + /loop ·
github.com/humanlayer/12-factor-agents · understandingdata.com/posts/actor-critic-adversarial-coding/ ·
developers.openai.com/codex/subagents · developersdigest.tech git-worktrees guide ·
hamel.dev/blog/posts/evals-faq/ · arxiv.org/html/2510.12803v1 · arxiv.org/html/2511.07784v1.

**Marketing/Sales:** mackinstitute.wharton.upenn.edu prompting-diverse-ideas (SSRN 4708466) ·
hbr.org/2025/12 LLM-creativity · arXiv 2510.18155 (buyer committee) · 6sense.com · askrally.com ·
Klarna Copy Assistant coverage · acrolinx.com · jasper.ai · Meta ad-text RL · profound / omnius (GEO) ·
salesforce.com Agentforce SDR · hubspot.com Breeze · clay.com · nooks.ai · gong.io AI Trainer ·
clari.com Deal Inspection · warmly.ai · copy.ai GTM fabric.

**Planning/PM:** sloanreview.mit.edu personal-board-of-directors · sourcery.ai/blog/panel-of-experts ·
arxiv.org/abs/2305.14688 (ExpertPrompting) · mckinsey.com war-gaming bias-busters · fifthrow.com ·
get-alfred.ai + scrum.org pre-mortem · naomistanford.com devils-advocate-or-pre-mortem ·
news.aakashg.com/p/ai-prd · chatprd.ai · stackranked.ai spec-driven-for-PMs ·
greaterwrong.com ai-forecasting-in-2026 · arxiv.org/html/2511.07678v1 (Bridgewater AIA) ·
thinkingmachines.ai training-llms-to-predict-world-events · nurijanian.substack.com OST workflow ·
canny.io + prodpad.com prioritization · projectivegroup.com OKR case · saralobkovich.com ·
theprfaq.com · productstrategy.co working-backwards · oneusefulthing.org automating-creativity ·
arxiv.org/html/2509.02605v1 (synthetic founders) · arxiv.org/pdf/2605.20767 (illusion of intervention) ·
christophersilvestri.com state-of-synthetic-research-2025.

**Support:** decagon.ai layered-guardrails + zenml.io LLMOps DB (Decagon) · cheekypint.substack.com +
sierra.ai (Bret Taylor supervisor/outcome pricing) · intercom.com Fin handoff docs + eesel.ai analysis ·
myaskai.com + bookbag.ai + kriseena.com confidence thresholds · lasoft.org + fintechweekly.com +
irisagent.com + entrepreneur.com (Klarna walk-back) · docs.cloud.google.com check-grounding ·
medium.com/@Nexumo_ 11-tests · yaihq.com citation-RAG-still-hallucinates · supportbench.com ·
usefini.com + scoutos.com (KB gap mining) · enterpret.com + unwrap.ai + getmosaic.ai (VoC/churn) ·
getcensus.com ticket-LLM-categorization · zendesk.com Relate 2025 · trydeepteam.com + promptfoo.dev +
confident-ai.com + stingrai.io (red-teaming) · portkey.ai + evidentlyai.com + twine.net (judge rubrics) ·
forbes.com Air Canada case + pymnts.com courts-chatbot liability · solresol.substack.com chatbot cases.

## Refs

[[ADR-017-evidence-based-panel-hardening]] · [[ADR-001-panel-loop-over-peer-debate]] ·
[[ADR-003-tool-grounded-findings]] · [[ADR-016-business-persona-family]] ·
[[2026-07-10-1740-llm-collaboration-patterns]] (plan) · [[v-team]] (feature dossier)
