---
type: research
project: vault
slug: document-writing
status: living
date_researched: 2026-08-21
tags: [research, documentation, plain-language, specification, minimalism]
---

# Document writing — how to write a file someone will act on

The evidence base for `commands/_shared/document-standard.md` and `bin/doc-lint.sh`
([[ADR-023-document-writing-standard]]).

**Scope boundary.** [[decision-communication]] covers agent→human **messages**. This covers agent→disk
**documents**. The rules differ: a message is read once by someone present in the conversation, a
document is read later by someone who is not.

**Maturity:** `measured` (controlled study) · `doctrine` (institutionally enforced, never
controlled-tested) · `vendor` (unverified product claim). Most named playbooks below are doctrine.

## §1 Findings — the load-bearing set

| id | finding | maturity | source |
|----|---------|----------|--------|
| D-01 | An SRS "should address the software product, **not the process** of producing" it: cost, schedule, method, QA, V&V and acceptance procedures "should not be included". | doctrine | IEEE 830-1998 §4.8 |
| D-02 | "The same requirement should not appear in more than one place." Named failure: "a requirement may be altered in only one of the places where it appears. The SRS then becomes inconsistent." | doctrine | IEEE 830-1998 §4.3.7 |
| D-03 | Clone detection over **28 industrial specs, 8,667 pages**: average duplication **13.6%** (1 word in 7), max **71.6%**. Reading tax averaged **3,578 extra words ≈ 16 min/document**; one spec's blow-up implied **>13 person-days** of extra inspection. Cloned passages were observed **already diverged** in the field. | measured | Juergens et al., ICSE 2010, arXiv:1711.05472 |
| D-04 | A requirement must be **Necessary** — "currently applicable and has **not been made obsolete** by the passage of time". Staleness is a conformance failure of the statement, not a cosmetic issue. | doctrine | ISO/IEC/IEEE 29148:2011 §5.2.5 |
| D-05 | Rationale and assumptions are **attributes, not body text**: design/how information "should be documented and communicated in some other form of documentation, such as the requirements attributes… (e.g., rationale)". Assumptions **shall** be documented in an attribute or an accompanying document. | doctrine | ISO/IEC/IEEE 29148:2011 §5.2.5 NOTE, §5.2.7 |
| D-06 | Rejected options belong to a **different document type**: "Changes considered but not included" and "Alternatives considered… trade-off analysis… rationale for the decisions reached" live in the OpsCon, not the specification. | doctrine | ISO/IEC/IEEE 29148:2011 A.2.4.4, A.2.8.3 |
| D-07 | Delete what you cannot check: "If a method cannot be devised to determine whether the software meets a particular requirement, then that requirement should be **removed or revised**." | doctrine | IEEE 830-1998 §4.3.6 |
| D-08 | Named ambiguity classes banned outright: superlatives, subjective language, vague pronouns (`it`, `this`), open-ended terms (`provide support`, `but not limited to`), loopholes (`if possible`, `as appropriate`), undated references. | doctrine | ISO/IEC/IEEE 29148:2011 §5.2.7 |
| D-09 | An ADR is **one decision per file, one to two pages**; a reversed decision keeps its file marked superseded and the replacement is a **new file**. Community practice hardens this to immutability: not editing accepted ADRs "is what makes the collection trustworthy". | doctrine | Nygard 2011; adr.github.io |
| D-10 | A changelog and a commit log are different artefacts with different readers: "Using commit log diffs as changelogs is a bad idea: they're full of noise." Version control owns the diff; the document owns the present. | doctrine | keepachangelog.com 1.1.0 |
| D-11 | **Counter-finding.** ISO/IEC/IEEE 29148 §9.2.1(b) *prescribes* a revision notice listing changed subclauses and all prior versions. Regulated documents do carry in-document history — but in **front matter**, never interleaved with the normative body (the example SRS outline, Figure 8, contains no revision, decision-log or authorship section in the body). | doctrine | ISO/IEC/IEEE 29148:2011 §9.2.1 b), §8.4.2 Fig. 8 |
| D-12 | **Minimalism, measured.** Minimal Manual learners needed **40% less learning time** (p<.01) and completed **2.7×** as many subtasks (p<.01). Replication: **58% more subtasks** (p<.05) and **93% more per unit time** (p<.05). Perceived course cost fell from a 200 hr median to **80 hr** (p<.05). | measured | Carroll, Smith-Kerker, Ford & Mazur-Rimetz, *HCI* 3(2), 1987 |
| D-13 | **The limit on that result.** Minimalism has four legs — brevity, real tasks, **error recognition and recovery**, guided exploration. Error-recovery content was *kept*, not cut. Brevity that removes recovery material is not minimalism. | doctrine | Carroll, *The Nurnberg Funnel*, MIT Press 1990 |
| D-14 | Mode mixing is the root defect: explanatory material inside reference "is bad for the reference, interrupted and obscured by digressions. But it's bad for the explanation too, because it's not allowed to develop appropriately." Any piece is "one, and only one" of tutorial, how-to, reference, explanation. | doctrine | Procida, diataxis.fr |
| D-15 | Reference is **for work, not study** — "what a user needs in order to help apply knowledge and skill, **while they are working**". Anything read to acquire understanding belongs in another file, reached by a link. | doctrine | diataxis.fr/reference-explanation/ |
| D-16 | Users read "at most **28% of the words — 20% is more likely**" on an average page; scanning follows an F-shape (n=232, re-confirmed 11 years later). **74% of viewing time** falls in the top two screenfuls; **>65%** in the top 40% of the page. | measured | Nielsen/NN/g 2006, 2008; NN/g "Scrolling and Attention" |
| D-17 | **The buried-requirement failure, measured.** Of **543 participants**, **74% skipped the privacy policy entirely**; those who opened the terms spent **51 seconds** on a document needing **15–17 minutes**. | measured | Obar & Oeldorf-Hirsch, *Information, Communication & Society* 23(1), 2020 |
| D-18 | **Why a long document is never actually checked.** Conforming inspection runs at **0.5–1.5 logical pages/hour** (a page ≈ 300 non-commentary words) and finds up to **88% of major defects** in one pass. A 1,000-line / ~10,000-word document is ~33 logical pages: **22–66 hours** of conforming review. | measured | Gilb & Graham, *Software Inspection*, 1993 |
| D-19 | Practitioner ceiling: a design doc must be "short enough to actually be read by busy people", **~10–20 pages at most**; beyond that "it might make sense to split up the problem into more manageable sub problems". | doctrine | Ubl, "Design Docs at Google" |
| D-20 | A section is capped by what a heading can honestly say: "Long sections are impossible to summarize meaningfully in a heading." One topic per section, topic sentence first. | doctrine | Federal Plain Language Guidelines 2011 §II.d, §III.c.4 |
| D-21 | Every chunk carries a descriptive **label**, and the **relevance principle** limits each chunk to a single topic, purpose or idea. If a chunk resists a truthful label, it is two chunks. | doctrine | Horn, Information Mapping |
| D-22 | **Front-load the critical item**, explicitly overriding logical or chronological order: the most critical items "should be listed as close as possible to the beginning… in order to increase the likelihood of completing the task before interruptions may occur". | doctrine (research-derived) | Degani & Wiener, NASA CR-177549, 1990, App. A item 10 |
| D-23 | Checklist content rule: only the **killer items** — "the steps that are most dangerous to skip and sometimes overlooked nonetheless". Length is managed by **partition**, not compression: "A long checklist should be subdivided to smaller task-checklists." | doctrine | Gawande 2009; Degani & Wiener 1990 App. A item 7 |
| D-24 | **Counter-finding — safety repetition is mandatory.** "Critical checklist items… that might be reset prior to takeoff due to new information **should be duplicated** between task-checklists." Where omission is catastrophic, the same normative item is deliberately repeated. | doctrine (research-derived) | Degani & Wiener, NASA CR-177549, 1990, App. A item 11 |
| D-25 | **Counter-rule on cross-references.** "Minimize cross-references… Most users consider them a bother, and just skip over them. If a cross-reference refers to brief material, just repeat that material and get rid of the cross-reference." | doctrine | Federal Plain Language Guidelines 2011 §III.d.6 |
| D-26 | Numeric writing limits: **≤20 words per sentence in procedures, ≤25 in descriptive text, ≤6 sentences per paragraph, one instruction per sentence**; ~900 approved words each with one meaning and one part of speech. GOV.UK: under 20 words. Cutts: 15–20 average across the document. | doctrine | ASD-STE100 Issue 9; GDS; Cutts, *Oxford Guide to Plain English* |
| D-27 | **The one measured sentence-level result, and it is not length.** With 184 participants, **center-embedding inhibited recall more than any other feature** — more than jargon, and more than passive voice, which "did not substantially change understanding". The fix is splitting an embedded definition into its own sentence. Holds **for lawyers too**. | measured | Martínez, Mollica & Gibson, *Cognition* 224:105070, 2022 |
| D-28 | Characters as subjects, actions as verbs; kill nominalizations — with Williams' own carve-out: a nominalization referring back to the previous sentence carries cohesion and should stay. | doctrine | Williams & Bizup, *Style*, Lessons 3–4 |
| D-29 | Outdated documentation is prevalent and framed as actively harmful: across **>3,000 GitHub projects**, "most projects contain at least one outdated code element reference at some point in their history", "misleading users and developers alike". | measured (prevalence) | Wen et al., *EMSE* 2023, arXiv:2212.01479 |
| D-30 | The stronger claim — "incorrect documentation is **worse than missing** documentation" — is an assertion, not a measurement. | doctrine | writethedocs.org |

## §2 Contradictions — reconciled, not hidden

**One rule one place, versus repeat it where it is needed.** D-02/D-03 forbid duplication and mandate
cross-references; D-25 says cross-references get skipped and brief material should be repeated; D-24
*requires* duplication of a safety-critical item across checklists. **Resolution adopted:** single-source
the authoritative definition, and allow a short restatement at the point of use when the material is
brief, omission is catastrophic, and the copy is recognisable as a copy. Uncontrolled prose
duplication is what D-03 measured going wrong. This is why `doc-lint`'s `DUP1` tolerates two
occurrences and why a deliberate safety repetition is exempted in `.doc-lint` rather than argued with.

**Revision history: banned or required?** D-09/D-10 give history to version control; D-11 has a
standard prescribing a revision notice. **Resolution:** history may live in **front matter as
metadata**; it must never be interleaved with the body. `doc-lint` checks the body only, starting
after the frontmatter fence, for exactly this reason.

**Brevity versus completeness.** D-12 measured large gains from removing material; D-13 is the limit —
error recognition and recovery content was kept. **Resolution:** the edit pass never cuts a failure
mode, a rollback path, an open blocker or an unverified assumption.

**Nominalization advice disagrees with itself.** D-28's blanket version conflicts with its own
cohesion carve-out, and the measured evidence (D-27) indicts center-embedding and jargon while
finding passive voice largely harmless — cutting against a large slice of conventional plain-language
advice. **Resolution:** name center-embedding explicitly; treat the nominalization rule as strong
guidance, not a checkable rule.

## §3 What the caps rest on

`bin/doc-lint.sh` caps a plan at 300 lines. D-18 is the load-bearing number: conforming inspection
runs at 0.5–1.5 logical pages/hour, so a 1,000-line document is 22–66 hours of review nobody will
spend — which is why it gets skimmed and why a buried requirement survives. D-19 gives the same
answer from practice (10–20 pages). D-16 and D-17 say what happens instead: attention decays sharply
with depth, and readers skip. The caps are a smell test grounded in review cost, not a style
preference.

## §4 When the reader is an agent

A plan is handed to an implementing agent as often as to a person, and that reader has its own
measured failure modes. Two of them converge with §1 from a completely separate corpus.

| id | finding | maturity | source |
|----|---------|----------|--------|
| A-01 | **A buried constraint scores worse than a missing one.** Mid-document position costs up to **22.9 points**; a fact placed mid-context can score below not supplying it at all. | measured | lost-in-the-middle / long-context position studies |
| A-02 | **Topically adjacent noise hurts more than random filler.** One irrelevant sentence cost **22.6 points** on an otherwise-solved task; semantically related but unused prose distracts more than incoherent text. A superseded approach left beside the current one is the worst case of this. | measured | Shi et al., distractor studies; Chroma context-rot |
| A-03 | "Ignore anything not relevant" recovers only **15–28%** of the lost accuracy. The guard is deletion, not an instruction. | measured | distractor-mitigation results |
| A-04 | Instruction adherence decays with turn depth (**~5.6% in odds per generated unit**) regardless of file structure — so a critical constraint is **re-issued at the point of use**, not assumed to still bind from the top of the file. Independent convergence with D-24. | measured | 1,650-session factorial study |
| A-05 | **Structure helps settled facts and hurts judgement.** Key/value and table form aids transfer of decided facts; forcing reasoning-dependent content into hard structure cost up to **63 points**. Markdown ornamentation adds **22–37% tokens** with no reliable accuracy benefit. | measured | structured-output comparisons |
| A-06 | Models **misreport their own compliance**, including word counts they did not produce. Length rules need an external check, not a self-check. This is why `bin/doc-lint.sh` exists rather than an instruction to be brief. | measured | LIFEBench / LIFT |
| A-07 | **Counter-finding — "shorter instruction file = better adherence" is doctrine, not evidence.** The only factorial experiment (1,650 sessions) found **no detectable effect** of instruction-file size, position or architecture, with Bayes factors favouring the null. The measured drivers were turn-depth decay (A-04) and instruction *count*, not file length. | measured (null) | 1,650-session factorial study |
| A-08 | **Brevity is not free in every direction.** A plain "be brief" cost up to **20% of hallucination resistance** — brevity over the justification of a factual claim removes the room needed to refute a false premise. Brevity over reasoning scaffolding measured as *improving* accuracy. No clean operational test separates the two cases. | measured, both directions | Giskard/Phare; CCoT; TALE |

**What A-07 means for this framework.** The 120-line cap on `document-standard.md` is a judgement
call, not a measured requirement, and the same is true of the cap on `communication.md`. Keep them —
a short contract is cheap and the null result is one study — but do not cite "bloated instruction
files get ignored" as though it were established.

**What A-08 means.** It is the reason every rule here caps *prose* and none caps reasoning, and the
reason the edit pass has a floor. Cutting narrative is close to free; cutting the support under a
factual claim is not.

## §5 Evidence honesty

**Do not cite these — no primary source exists:**

- The "8 words = 100% comprehension … 43 words = <10%" scale attributed to an American Press
  Institute study. It propagates only through secondary plain-language literature.
- Any Information Mapping percentage-improvement figure. Only a 1969 technical report is reachable.
- ASD-STE100 comprehension or translation-cost improvement percentages.
- "Docs go stale within 30–90 days", "68% of enterprise content unrevised in 6 months",
  "documentation debt costs 47% of development effort" — vendor copy, no traceable study.
- Gawande's 5–9 item and 60–90 second rules: a trade book reporting a Boeing practitioner interview.
  A design heuristic, not a measurement.

**The gap that matters most:** no study compares reader outcomes under stale-content versus
no-content conditions. D-29 measures prevalence, not error rates. The rule that a document carries
current truth only is well-motivated doctrine for a human reader, and should not be presented as
validated science. For an agent reader it is on firmer ground: A-02 measures topically adjacent
unused prose as actively costly, and a superseded approach sitting beside the current one is exactly
that.

**Also unadjudicated:** whether a hand-off should be compressed at all. One vendor compresses
sub-agent work to 1,000–2,000 tokens; another argues that compression is precisely why multi-agent
systems fail, because the receiver acts on assumptions never surfaced. Both are doctrine from teams
shipping opposite architectures, and no measured study settles it. The sidecar split sidesteps the
question rather than answering it: nothing is compressed away, it is moved and referenced.

## Refs

[[ADR-023-document-writing-standard]] · [[document-writing-standard]] · [[decision-communication]] ·
[[ADR-018-decision-communication-contract]]
