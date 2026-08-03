---
type: research
project: vault
slug: decision-communication
status: living   # update as evidence changes; cite from ADRs/plans when changing the contract
date_researched: 2026-08-03
tags: [research, communication, ux, decision-support, plain-language]
---

# Decision communication — how to write to a human decision-maker

The evidence base for `commands/_shared/communication.md` and `output-styles/director.md`
([[ADR-018-decision-communication-contract]]). Compiled 2026-08-03 by a three-agent sweep (~30
searches, primary sources fetched where possible).

**Scope boundary.** [[llm-collaboration-patterns]] covers **agent↔agent** structure — panels,
critics, orchestration. This doc covers **agent↔human** output. They do not overlap; the older
catalog has no finding on how an agent should write to its user.

## §0 How to read

- **Maturity:** `measured` (controlled study / meta-analysis) · `doctrine` (institutionally
  enforced, never controlled-tested) · `vendor` (published product guidance).
- IDs are stable — cite as `[[decision-communication]] R-04`.
- **The honesty rule for this doc:** most named playbooks in §2 are *doctrine*. Do not cite them as
  if they were measured.

---

## §1 Findings — the load-bearing set

| id | finding | maturity | source |
|----|---------|----------|--------|
| R-01 | "Army writing will be concise, organized, and to the point. Two essential requirements include **putting the main point at the beginning (bottom line up front)** and **using the active voice**." Sentences ~15 words average; paragraphs ≤10 lines; one-page memos, detail in enclosures. | doctrine | US Army AR 25-50 ¶1-36b, ¶1-37b |
| R-02 | Against the same control copy: **concise +58%** usability · **scannable layout +47%** · **objective language +27%** · **all three +124%**. **79% of users always scan; 16% read word-by-word.** | measured | Morkes & Nielsen, NN/g 1997 |
| R-03 | **Redundancy effect** — presenting information the reader already holds is *actively harmful*, not neutral: they must process it merely to discover it is redundant. Direction is **negative**. | measured | Chandler & Sweller 1991; Sweller et al. 2019 |
| R-04 | **Expertise reversal** — high-assistance instruction helps novices (**d = +0.505**) and *hurts* experts (**d = −0.428**), N = 5,924. **Boundary:** established for *well-structured procedural* material; Nievelstein et al. 2013 found **no reversal in ill-structured domains**, where worked examples helped both groups. Framework and architecture design is ill-structured. | measured | Tetzlaff et al. 2025, *Learning and Instruction* 98; Nievelstein et al. 2013 |
| R-05 | **Seductive details / coherence principle** — interesting but non-load-bearing material costs **g = −0.33** on learning. Decorative metaphor is measurably harmful. | measured | Sundararajan & Adesope 2020; Rey 2012 |
| R-06 | **Jargon disrupts processing fluency even when definitions are supplied.** The fluency hit lands before the definition arrives. N = 650. | measured | Shulman, Dixon, Bullock & Colón Amill 2020, *JLSP* 39 |
| R-07 | Workplace jargon → lower processing fluency → lower self-efficacy → **less information seeking and less information sharing**. The reader disengages **silently** rather than objecting. Not urgency-conditioned. | measured | Bullock & Bisbey 2025, *IJBC* |
| R-08 | **Satisficing** — a difficult question does not yield "I don't know". It yields a **cue-driven answer**: the respondent scans the wording for something easy to select and defensible. A badly framed question manufactures a fake decision rather than failing loudly. | measured | Krosnick 1991; Tourangeau, Rips & Rasinski 2000 |
| R-09 | **Verbiage in the question stem or its introduction degrades measurement quality.** Long preambles produce worse answers. | measured | Krosnick & Presser 2010 |
| R-10 | Choice overload has **no reliable main effect** (d ≈ 0.02 across 50 experiments) — but four moderators reliably produce it: choice-set complexity, task difficulty, **preference uncertainty**, and decision goal. N = 7,202. **Option count is the wrong lever; comparability on shared attributes is the right one.** Stating a recommendation removes preference uncertainty from the reader. | measured | Chernev, Böckenholt & Goodman 2015; Scheibehenne et al. 2010 |
| R-11 | AI explanations increased the chance a human **accepted** the recommendation **regardless of its correctness** — complementary performance did *not* improve. Explanations help only when they let the human **independently verify**. | measured | Bansal et al., CHI 2021; Fok & Weld 2024 |
| R-12 | Plain language: **+19.8pp** correct responses vs standard language (adults, RCT); legalese cuts recall to 35.3% vs 42.4% for plain register, and the driver is **syntax (center-embedding), not vocabulary**. **It works on experts too** — 105 practising lawyers comprehended and preferred plain English. **Two limits:** simplification removes only the extraneous share (absolute comprehension can stay low), and stripping jargon can cost perceived expertise — so simplify **syntax, not precision**. | measured | *J Clin Epi* 2023; Martínez, Mollica & Gibson 2022 *Cognition* / 2023 *PNAS*; Masson & Waldron 1994; *Public Relations Review* 2025 |
| R-13 | Working memory holds **~4 chunks** (range 3–5), not 7 — Miller framed 7±2 rhetorically. **Naming/labelling an option makes it cost one slot instead of many.** | measured | Cowan 2001, *BBS* 24 |
| R-14 | Sentence ceiling **25 words**; at a **14-word average readers understand >90%**, at 43 words **<10%**. "The more educated a person is, and the more specialist their knowledge, **the greater their preference for plain English**." Users read ~25% of a page. | measured + doctrine | GOV.UK / Government Digital Service |
| R-15 | Guideline **G16 — convey the consequences of user actions**; **G10 — scope services when in doubt** (narrowing the action is the third option beside "ask" and "guess"); **G8/G9** — cheap dismissal and correction reduce how much must be asked up front. Validated with 49 practitioners against 20 products. | measured | Amershi et al., CHI 2019 (Microsoft HAX) |
| R-16 | Verbosity is a **trained artifact**: reward models inherit length bias from preference data, so optimizing against them largely optimizes for length; SOTA models **fail to follow explicit length instructions**. Numeric, per-artifact limits work where "be concise" does not. **Two counter-weights:** Claude Code 2.0 itself softened its hard 4-line rule to a soft norm, and there is an accuracy **floor** below which terseness collapses correctness. → cap prose, never reasoning. | measured + vendor | Dubois et al. 2024 (LC-AlpacaEval); Yuan et al., EMNLP 2025 (LIFT); AALC arXiv 2506.20160 |
| R-17 | **Progressive disclosure** — "present the verdict first in one short paragraph, with reasoning, sources, and detail behind disclosure controls." AI answers and long-running agents need layering more than settings screens do. | doctrine | Nielsen (NN/g), 1995 / 2026 |
| R-18 | **Bloated instruction files get ignored** — "important rules get lost in the noise". Prune test: *would removing this line cause a mistake?* If not, cut it. Also: spurious clarifying questions are treated as a **doc defect**, not a model defect. | vendor | Anthropic, Claude Code best practices |
| R-20 | Role framing helps **alignment-dependent** tasks (MT-Bench: extraction +0.65, STEM +0.60) and **hurts pretraining-dependent** ones (MMLU 68.0% vs 71.6% baseline). "Telling a model it's an expert does not impart expertise." → "employee reporting to a director" is legitimate for **voice**; framing it as an engineering upgrade is unsupported and likely harmful. | measured | PRISM arXiv 2603.18507; Wharton arXiv 2512.05858 |

---

## §2 The named playbooks (all doctrine — adopted for structure, not evidence)

- **BLUF** (US Army AR 25-50; Air Force *Tongue and Quill* expands it to Bottom line · Impact · Next
  steps · Details). Conclusion precedes justification.
- **Minto Pyramid Principle** (Barbara Minto, McKinsey). Three laws: a parent idea **summarizes** the
  ideas below it; grouped ideas are the **same kind** at the same level (MECE); groups are **logically
  ordered**. Every statement raises exactly one question, answered by the level below. SCQA opening.
  Practical cap of 3 supporting points (max ~5).
- **Amazon 6-pager / PR-FAQ** (Bezos 2004 PowerPoint ban; 2017 shareholder letter). Hard 6-page cap;
  prose only; silent reading first; **anonymous authorship**; no weasel words; **"don't disguise
  assumptions and hypotheses as facts."**
- **SBAR** (US Navy → Kaiser Permanente ~2002; Joint Commission, WHO, AHRQ). Situation · Background ·
  **Assessment** (the slot juniors omit) · **Recommendation**, time-bounded. It exists to *license a
  low-authority sender to make an assertive recommendation upward*. Evidence: moderate quality —
  structured-communication adherence rose 4.0%→79.0% (psychiatry) and 43.6%→91.0% (long-term care).
  **Do not cite the circulated "85% improvement" figure — it traces to no primary study.**
- **Completed Staff Work** (Col. Archer J. Lerch, US Army, 1942). "…in such form that **all that
  remains** to be done… is to indicate his approval or disapproval." Work out the details yourself;
  present **one action**; advise what he ought to do rather than asking what to do; **"do not worry
  your chief with long explanations and memoranda."** Final test: *would you sign it and stake your
  reputation on it?*
- **RAPID** (Bain, HBR 2006) and **DACI** (Intuit/Atlassian) — decision-role assignment; exactly one
  decider. **ADR** (Nygard 2011) — one or two pages; Context · Decision ("We will…") · **Consequences,
  including the negative ones**.
- **Doumont, *Trees, Maps and Theorems*** — zeroth law: have a purpose. Then: adapt to your audience ·
  **maximize signal-to-noise** · **use effective redundancy** (restate one message across *different*
  channels). Every unit carries exactly one message, stated as a full sentence with a verb.
- **Plain language standards** — Plain Writing Act 2010 (PL 111-274, which AR 25-50 cites directly);
  Federal Plain Language Guidelines (one idea per sentence; paragraphs 3–8 sentences, ≤150 words);
  **ISO 24495-1:2023** — plain language means the audience can **find, understand and use** the
  information; principles are *Relevant · Findable · Understandable · Usable* (commonly mis-cited —
  use ISO's wording).

---

## §3 Contradictions — reconciled, not hidden

| tension | resolution adopted in the contract |
|---------|-----------------------------------|
| **Completed Staff Work:** bring ONE action, never a menu — **vs** — **ADR / decision memos:** show alternatives and all consequences | **User decision (2026-08-03):** recommendation first, then alternatives with consequences. The recommendation is signable alone; the options table sits below it as progressive disclosure. Both traditions honored. |
| **Amazon:** bans bullets, tables and diagrams in the body — **vs** — **NN/g:** +47% usability from scannable layout alone; ISO 24495-1 mandates findability | Split by **reader mode**. Amazon assumes 25 minutes of captive silent reading by people paid to read it; this user scans a terminal and consumes ~25% of it. Adopt scannable. Adopt Amazon's *precise-writing* rules (no weasel words, don't disguise assumptions as facts); **reject its no-bullets rule, with reason.** |
| **BLUF:** the answer is sentence one — **vs** — **Minto SCQA:** situation → complication → question → *then* answer | SCQA permitted only as a **three-sentence runway**, and only when the answer is unevaluable without it. Default is BLUF. |
| **Doumont:** "use effective redundancy" — **vs** — plain-language and Amazon: "remove redundancy" | Terminological, and the contract states both so they cannot collide. Doumont means restating **one message across different channels** (heading + sentence + table). The others mean duplicated **words**. |
| Sentence length: AR 25-50 **avg 15** · OPM **15–20** · GOV.UK **ceiling 25** | Three different quantities in three units. Adopt **ceiling 25, aim ~15**, and label which is which. |
| **Jargon always hurts** — **vs** — no significant effect under high urgency (B = 0.11, COVID topic) | Urgency framing **dropped**. It was asserted rather than argued: this user's approval gates are high-motivation moments, exactly where the source says the penalty vanishes. The rule instead rests on **R-07** — jargon's cost is silent disengagement, which is not urgency-conditioned. |
| **Ask vs act:** OpenAI — "be extremely biased for action", "do not ask clarifying questions" — **vs** — Anthropic — ships `AskUserQuestion`, recommends an interview phase, treats Claude-initiated stops as healthy oversight | **Synthesis of this research, not vendor doctrine:** ask at **spec time** (before work), not at **execution time** (mid-work). Anthropic's interview→SPEC→fresh-session flow and OpenAI's "1–3 questions before generating the plan" agree on that shape even where their slogans clash. |
| **Prose instructions decay** — **vs** — the contract is prose | Accepted and scoped. Guard tests pin the **artifact, not the behavior**; the output style re-injects mid-conversation but reaches the **main conversation only, never subagents**; the 120-line cap answers R-18. Subagent text is capped separately at `03-propose-loop.md` §(e).7. A Stop-hook length linter remains the only deterministic fix — out of scope. |

---

## §4 Evidence honesty

Only these carry measured numbers: **NN/g** (+58/+47/+27/+124%, 79% scan) · **GOV.UK's cited
readability research** (>90% at 14 words, <10% at 43) · the **cognitive-load** literature (redundancy,
expertise reversal d = ±0.4–0.5, seductive details g = −0.33) · the **jargon** experiments (N = 650,
plus the workplace replication) · the **decision** literature (Chernev N = 7,202; Bansal CHI'21) ·
the **plain-language RCTs** (+19.8pp) · **SBAR** reviews (moderate quality) · **length-bias** work.

**BLUF, the Minto Pyramid Principle, the Amazon 6-pager, DACI, ADR and Completed Staff Work have
zero controlled evidence.** They are doctrine — widely adopted, institutionally enforced, never
tested. That is not an argument against using them. It is an argument against citing them as science.

Two further caveats worth carrying: the choice-overload headline ("fewer options are better", the jam
study) **failed meta-analytic replication as a main effect** — cite Chernev's moderators, not
Iyengar's result. And better decision support is not the same as happier users: the cognitive-forcing
interventions that most improved decisions were the ones participants **liked least**.

---

## §5 Sources

**Cognitive load / attention:** Sweller, van Merriënboer & Paas (2019) *Educational Psychology Review*
31 · Kalyuga et al. (2003) *Educational Psychologist* 38(1) · Tetzlaff, Simonsmeier, Peters & Brod
(2025) *Learning and Instruction* 98 · Nievelstein et al. (2013) *Contemporary Educational Psychology*
· Sundararajan & Adesope (2020) *Educational Psychology Review* 32 · Rey (2012) *Educational Research
Review* 7(3) · Cowan (2001) *BBS* 24(1) · Eppler & Mengis (2004) *The Information Society* 20(5).

**Plain language / readability:** plainlanguage.gov → digital.gov Federal Plain Language Guidelines ·
Plain Writing Act 2010 (PL 111-274) · ISO 24495-1:2023 · GOV.UK content design + insidegovuk
"why 25 words is our limit" · Morkes & Nielsen (1997) NN/g "How Users Read on the Web" +
"Inverted Pyramid" · Martínez, Mollica & Gibson (2022) *Cognition* 224 + (2023) *PNAS* 120(23) ·
Masson & Waldron (1994) *Applied Cognitive Psychology* 8(1) · *J Clin Epi* (2023) plain-language RCTs.

**Jargon:** Bullock, Colón Amill, Shulman & Dixon (2019) *Public Understanding of Science* 28(7) ·
Shulman, Dixon, Bullock & Colón Amill (2020) *JLSP* 39(5–6) · Bullock & Bisbey (2025) *IJBC* ·
Bullock, Shulman & Huskey (2020) *PLOS ONE* 15(10) · *Public Relations Review* (2025).

**Questions / decisions:** Tourangeau, Rips & Rasinski (2000) *The Psychology of Survey Response* ·
Krosnick (1991) *Applied Cognitive Psychology* 5(3) · Krosnick & Presser (2010) *Handbook of Survey
Research* · Chernev, Böckenholt & Goodman (2015) *JCP* 25(2) · Scheibehenne, Greifeneder & Todd (2010)
*JCR* 37(3) · Keeney & Raiffa (1976) · Hammond, Keeney & Raiffa (1998) HBR "Even Swaps" ·
Spetzler, Winter & Meyer (2016) *Decision Quality*.

**Human–AI:** Amershi et al. (2019) CHI, Guidelines for Human-AI Interaction (microsoft.com/haxtoolkit)
· Bansal et al. (2021) CHI · Buçinca, Malaya & Gajos (2021) *PACM HCI* 5(CSCW1) · Fok & Weld (2024)
*AI Magazine* 45(3) · Vaccaro, Almaatouq & Malone (2024) *Nature Human Behaviour* 8.

**Verbosity / role framing:** Dubois et al. (2024) arXiv 2404.04475 · Yuan et al. (EMNLP 2025) arXiv
2406.17744 · AALC arXiv 2506.20160 · arXiv 2512.17920 · PRISM arXiv 2603.18507 · Wharton arXiv
2512.05858.

**Doctrine sources:** AR 25-50 (armypubs.army.mil) · AFH 33-337 *The Tongue and Quill* · Minto,
*The Minto Pyramid Principle* · Bezos 2017 Letter to Shareholders + Bryar & Carr *Working Backwards* ·
Müller et al. (2018) *BMJ Open* (SBAR review) · Rogers & Blenko (2006) HBR "Who Has the D?" ·
Atlassian DACI · Nygard (2011) "Documenting Architecture Decisions" · Doumont (2002) *IEEE TPC* 45(4) ·
govleaders.org "Completed Staff Work" (Lerch, 1942).

**Vendor guidance:** Anthropic — Claude Code best practices, output styles, tools reference,
"Measuring AI agent autonomy in practice", "Building effective human-agent teams", "Writing effective
tools for agents" · OpenAI — GPT-5 / GPT-5.1 prompting guides.

## Refs

[[ADR-018-decision-communication-contract]] · [[llm-collaboration-patterns]] ·
[[user-facing-communication]] · [[2026-08-03-1045-decision-communication-contract]] (plan)
