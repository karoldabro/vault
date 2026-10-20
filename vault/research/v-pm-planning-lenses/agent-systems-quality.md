---
type: research
project: vault
slug: agent-systems-quality
status: snapshot
date_researched: 2026-10-20
tags: [research, agents]
---

# Research: quality, evaluation, knowledge and self-improvement for product agents

Scope: a design-review persona for product agents inside an API. Worked case: the Givore support reply drafter in `~/workspace/recycling-api` (`app/Services/Support/`, `config/support.php`). Facts carry a source URL. Lines marked "Inference" are my reasoning, not a source claim.

Codebase facts used below (read 2026-10-20, read-only):
- `config/support.php:144` sets `judge_model` = `claude-opus-5-5`. `config/ai.php:55` sets `default_chat_model` (the drafter) = `claude-opus-5-5`. The guidance writer (`config/support.php:155`) is the same model. Author, judge and learner are one model.
- `config/support.php` sets `sendable_score` = 4 and `low_score` = 3. The judge emits a graded score, then a threshold turns it into sendable/not.
- `app/Services/Support/ReplayRunner.php:25` `calibrate()` measures A/A noise (live vs live). Nothing in `app/Services/Support/` computes judge agreement with human labels (no grep hit for `kappa`, `tpr`, `human_label`).
- `app/Services/Support/PairedReplayStatistics.php` runs a paired bootstrap over cases (10,000 resamples, 10% lower quantile). `replay_cases` = 40, `min_replay_cases` = 20, `min_margin` = 3 points.
- `app/Services/Support/SupportOutcomeEvaluator.php:204` compares draft to sent text with PHP `similar_text`.
- `app/Services/Support/SupportLearningSets.php:17` splits outcomes by chat with crc32: the writer learns on one half, the replay judges on the other.

## Open questions / contradictions

1. **Binary vs graded scoring.** Husain/Shankar say use pass/fail per failure mode, never 1-5 ([evals FAQ](https://hamel.dev/blog/posts/evals-faq/)). Anthropic's agent-eval guide says "build in partial credit" for multi-step tasks ([Anthropic](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)). Eugene Yan says binary for objective criteria, pairwise for subjective ones like tone ([eugeneyan.com](https://eugeneyan.com/writing/llm-evaluators/)). Resolution for a reply drafter (Inference): one binary "would Carlos send this as-is or with a trivial edit" label, plus one binary check per failure category. The current 1-5 score thresholded at 4 is the pattern the FAQ warns against.
2. **Same model as author and judge.** The FAQ says it is "usually fine if judge agreement with humans is high" ([evals FAQ](https://hamel.dev/blog/posts/evals-faq/)). Zheng et al. and Panickssery et al. measure self-enhancement bias: GPT-4 favored itself by about 10% win rate, Claude-v1 by about 25% ([Zheng 2023](https://arxiv.org/abs/2306.05685), [Panickssery 2024](https://arxiv.org/abs/2404.13076), numbers via [eugeneyan.com](https://eugeneyan.com/writing/llm-evaluators/)). Both agree on one point: without measured human agreement, a same-model judge is unvalidated. Givore has no human-agreement measurement, so the question is open until it does.
3. **Self-refinement without external feedback.** Self-Refine reports about 20% absolute gains with no external feedback ([Madaan 2023](https://arxiv.org/abs/2303.17651)). Huang et al. show intrinsic self-correction degrades reasoning, and that Self-Refine's constrained-generation gain vanished once the first prompt stated the requirement (81.8 standard vs 75.1 after self-correction) ([Huang 2023](https://arxiv.org/html/2310.01798)). Huang also notes models judge "inappropriate" style better than their own reasoning errors. Open: whether a critique pass helps tone in Spanish support replies. Only a paired replay with a human-validated judge can answer it.
4. **How many cases are enough.** Anthropic: start with 20-50 tasks from real failures, since early effects are large ([Anthropic](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)). Husain: at least 100 traces per error-analysis round, and about 100 labels per failure mode to validate a judge; below 60 the interval is too wide ([critique shadowing](https://hamel.dev/blog/posts/llm-judge/)). Both hold: 20-50 finds big failures; 100+ is needed to measure a judge or detect a small gain.
5. **Small-set statistics for Givore (computed, Wilson 95%).** 37/71 sendable (52%) has an interval of 40.7%-63.3%. 45/71 (63%) has 51.8%-73.6%. The intervals overlap. 0/18 production sends has an interval of 0%-17.6%. An unpaired comparison at n=71 per arm detects only about a 23-point difference at 80% power. A paired design (same cases, both arms) shrinks this, as Anthropic's error-bars paper shows ([Anthropic stats](https://www.anthropic.com/research/statistical-approach-to-model-evals)). Open: the promotion gate uses `replay_cases` = 40 and `min_margin` = 3 points. A 3-point margin on 20-40 cases sits well inside judge noise unless the paired correlation is very high. The A/A calibration measures drafter noise but not judge bias.
6. **Offline gains shrink online.** Fin's reranker gained +13% Recall@10 offline, about +3% recall in a production backtest, and a significant but undisclosed resolution gain online ([Fin reranker](https://fin.ai/research/how-we-built-a-world-class-reranker-for-fin)). The replay judge says 52%; Carlos sent 0 of 18. Open: which signal the replay judge actually predicts. Until it is calibrated against Carlos's sends, the replay rate is not evidence of sendability.
7. **Resolution-rate definitions disagree across vendors.** Intercom counts silence after an answer as an assumed resolution, and counts conversations where a teammate later joined ([Intercom community](https://community.intercom.com/fin-ai-agent-59/q-a-fin-ai-resolution-rate-vs-fin-ai-resolution-filtered-team-currently-assigned-9255), [Fin feedback research](https://fin.ai/research/was-that-helpful-understanding-user-feedback-in-customer-support-ai-agents)). Zendesk counts no human escalation ([Zendesk help](https://support.zendesk.com/hc/en-us/articles/6970583409690)). Published rates range from 20% to 80%. None of them measures draft acceptance by an operator. No vendor publishes a draft-send-rate benchmark.
8. **Few-shot selection: similarity vs diversity.** Liu et al. find nearest-neighbour examples beat random ones ([Liu 2021](https://arxiv.org/abs/2101.06804)). Levy et al. find a diverse set beats a set of near-duplicates when no single example covers the case ([Levy 2023](https://aclanthology.org/2023.acl-long.78)). Anthropic advises "diverse, canonical examples" ([context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)). Open for Givore: whether top-k similar replies from one operator collapse to one template.
9. **Redaction and example usefulness.** No study measures how name redaction changes few-shot usefulness. Practitioner guides disagree between typed placeholders (`[NAME]`) and consistent pseudonyms (`PERSON_001`) ([Redakto preprint](https://arxiv.org/pdf/2608.18260), [MLflow](https://mlflow.org/articles/pii-redaction-llm)). Open: test it with a paired replay (redacted vs placeholder-normalized examples).
10. **Personas.** Zheng et al. (2023) find personas in system prompts do not improve factual accuracy, and effects are unpredictable ([Zheng persona study](https://arxiv.org/abs/2311.10054)). That study measured factual QA, not tone. No primary source measures persona prompts vs examples for voice adherence in support replies.
11. **Klarna.** Klarna claimed its assistant did the work of 700 agents, then its CEO said cost focus produced "lower quality" and rehired humans in 2025 ([tech.co](https://tech.co/news/klarna-reverses-ai-overhaul)). The reports are secondary coverage of one Bloomberg interview. No metric definition was published.

## Patterns

Each item: rule. When it applies. Failure it prevents. Source.

### Evaluation

- **P1. Do error analysis before building metrics.** Read 20-50 traces per significant change, write free-text notes (open coding), then group notes into a counted failure taxonomy (axial coding). Applies before any judge, rubric or optimizer exists. Prevents measuring generic qualities that do not match real failures. [evals FAQ](https://hamel.dev/blog/posts/evals-faq/)
- **P2. Stop at saturation, not at a count.** Keep reading traces until new ones reveal no new failure mode; aim for at least 100 per cycle, every 2-4 weeks. Applies to each review cycle. Prevents a taxonomy that misses rare but costly failures. [evals FAQ](https://hamel.dev/blog/posts/evals-faq/)
- **P3. Note the first upstream failure per trace.** Applies to multi-step pipelines (retrieve → draft → judge). Prevents blaming the drafter for a retrieval miss. [evals FAQ](https://hamel.dev/blog/posts/evals-faq/what-parts-of-evals-can-be-automated-with-llms.html)
- **P4. One domain expert owns the quality bar.** A "benevolent dictator" (for Givore: Carlos) defines pass/fail. Applies to any subjective quality. Prevents a judge aligned to the engineer's taste instead of the sender's. [critique shadowing](https://hamel.dev/blog/posts/llm-judge/)
- **P5. Expect criteria drift; re-grade after criteria change.** Users invent and reinterpret criteria while grading. Applies whenever a rubric is written. Prevents a rubric frozen before anyone read outputs. [Shankar 2024](https://arxiv.org/html/2404.12272)
- **P6. Use binary pass/fail with a written critique.** Applies to every human label and every judge output. Prevents unreliable Likert midpoints and inconsistent adjacent scores. [field guide](https://hamel.dev/blog/posts/field-guide/)
- **P7. One evaluator per failure mode; code checks before LLM checks.** Length, forbidden phrases, links, placeholders left in text: assert in code. Tone, factual grounding: LLM judge. Applies after the taxonomy exists. Prevents one vague "quality" judge that hides which failure moved. [evals FAQ](https://hamel.dev/blog/posts/evals-faq/)
- **P8. Report a pass-all rate plus per-check rates.** Applies to dashboards and promotion gates. Prevents an average that rises while one critical check gets worse. [evals FAQ](https://hamel.dev/blog/posts/evals-faq/)
- **P9. Separate capability evals from regression evals.** Capability sets start with low pass rates. Regression sets stay near 100% and run on every change. Applies to CI. Prevents a saturated eval that shows no signal for improvement. [Anthropic agent evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- **P10. Test both "should act" and "should not act".** Include cases where the right output is no draft, an escalation, or a question back. Prevents one-sided optimization that drafts for everything. [Anthropic agent evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- **P11. Feed production failures back into the eval set.** Every flagged live conversation becomes a replay case. Applies after launch. Prevents a golden set that goes stale. [Intercom Evals and Releases](https://www.intercom.com/blog/announcing-evals-and-releases), [evals FAQ](https://hamel.dev/blog/posts/evals-faq/)
- **P12. Stratify samples by issue type and segment.** Applies to replay and judge-validation sets. Prevents a set dominated by the most common, easiest category. [Decagon](https://decagon.ai/blog/evaluation-engine-ai-agents)
- **P13. Report a confidence interval with every rate. Compare arms paired.** Use SEM or Wilson intervals. Compare candidates on the same cases with a paired test. Cluster standard errors when cases share a chat or customer. Applies to every replay comparison. Prevents promoting noise. [Anthropic stats](https://www.anthropic.com/research/statistical-approach-to-model-evals)
- **P14. Run a power analysis before trusting a small set.** Decide the smallest gain worth shipping, then compute the cases needed. Applies to promotion gates. Prevents a 40-case gate that cannot detect a 3-point gain. [Anthropic stats](https://www.anthropic.com/research/statistical-approach-to-model-evals)
- **P15. Measure reliability with pass^k on customer-facing paths.** Run each case k times; a case passes only if all k pass. Applies to drafters with sampling noise. Prevents shipping a drafter that is good once and bad on rerun. [tau-bench](https://arxiv.org/abs/2406.12045), [Anthropic agent evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- **P16. Gate offline, then confirm online.** Only variants passing offline thresholds reach a gradual A/B; online metrics decide. Applies to every prompt, model or retrieval change. Prevents offline wins that do not move the real metric. [Decagon](https://decagon.ai/blog/evaluation-engine-ai-agents), [Fin reranker](https://fin.ai/research/how-we-built-a-world-class-reranker-for-fin)

### LLM-as-judge

- **P17. Calibrate the judge against expert labels with a train/dev/test split.** 10-20% train (few-shot examples for the judge), 40-45% dev, 40-45% test; 30-50 pass and 30-50 fail in dev and test. Freeze the prompt before the single test run. Applies before any judge score drives a decision. Prevents an unvalidated judge. [critique shadowing](https://hamel.dev/blog/posts/llm-judge/)
- **P18. Report TPR and TNR, not raw agreement.** With a 5% failure rate, an always-pass judge gets 95% agreement and catches nothing. Applies to judge validation. [critique shadowing](https://hamel.dev/blog/posts/llm-judge/)
- **P19. Correct the observed pass rate for judge error.** θ = (p_obs + TNR − 1) / (TPR + TNR − 1), with a bootstrap interval. Applies when reporting a judged rate as the true rate. Breaks down when TPR + TNR is near 1. [judgy](https://pypi.org/project/judgy/)
- **P20. Prefer Cohen's kappa over correlation for agreement.** UMBRELA reported kappa 0.3-0.5 where tau/rho were 0.8-0.9. Applies to human-human and judge-human agreement. [eugeneyan.com](https://eugeneyan.com/writing/llm-evaluators/)
- **P21. Use a reference answer when one exists.** The operator's sent reply is a reference; grade "does the draft say what the sent reply says, with no wrong facts". Applies to replay of real chats. Prevents the judge inventing its own ideal. [Zheng 2023](https://arxiv.org/abs/2306.05685)
- **P22. Control for length.** Judges preferred the longer response more than 90% of the time when the extra text added nothing. Add a length check or regress length out. Applies to any pairwise or rated comparison. [eugeneyan.com](https://eugeneyan.com/writing/llm-evaluators/), [LC AlpacaEval](https://arxiv.org/abs/2404.04475)
- **P23. Swap positions in pairwise judging.** Claude-v1 favored the first position 70% of the time. Applies to A/B judge prompts. [eugeneyan.com](https://eugeneyan.com/writing/llm-evaluators/)
- **P24. Use a judge from a different model family, or a panel.** A panel of three smaller models correlated better with humans than GPT-4 alone at one-seventh the cost. Applies when author and judge share a model. [eugeneyan.com](https://eugeneyan.com/writing/llm-evaluators/) (PoLL, Verga 2024)
- **P25. Give the judge only the context it needs and pin a dated model.** Re-validate after any prompt or model change. [evals FAQ](https://hamel.dev/blog/posts/evals-faq/), [judgy guide](https://skills.sh/hamelsmu/evals-skills/validate-evaluator)
- **P26. Watch the negative class.** Fin's second-judge check found negative-feedback F1 fell to about 0.77 while positive held. Applies to any judge where failures are rarer. [Fin feedback research](https://fin.ai/research/was-that-helpful-understanding-user-feedback-in-customer-support-ai-agents)

### Knowledge and retrieval

- **P27. If the knowledge base fits, skip RAG.** Under about 200k tokens, put the whole KB in the prompt with prompt caching. Applies to small support KBs. Prevents retrieval misses entirely. [Anthropic contextual retrieval](https://www.anthropic.com/news/contextual-retrieval) — but see P31: more context also costs accuracy. Test both.
- **P28. Use hybrid BM25 + embeddings with contextual chunks and a reranker.** Contextual embeddings cut top-20 retrieval failures 35%; adding contextual BM25, 49%; adding reranking, 67%. Retrieve about 150, rerank to 20. Applies when the KB exceeds the context budget. [Anthropic contextual retrieval](https://www.anthropic.com/news/contextual-retrieval)
- **P29. Evaluate retrieval separately with Recall@k on question-document pairs.** Generate questions from chunks, check the source chunk is returned. Debug retrieval before generation. [evals FAQ](https://hamel.dev/blog/posts/evals-faq/), [Jason Liu](https://jxnl.co/writing/2024/02/28/levels-of-complexity-rag-applications/)
- **P30. Segment queries by topic and capability.** A topic gap means missing content; a capability gap means the system cannot do that kind of question. Fixes differ. [Jason Liu](https://jxnl.co/writing/2024/02/28/levels-of-complexity-rag-applications/)
- **P31. Send only relevant context; remove near-miss distractors.** Every model scored higher on focused (~300 token) than full (~113k token) input; one distractor already hurt. Applies to KB snippets, examples and rulebooks. [Chroma context rot](https://www.trychroma.com/research/context-rot)
- **P32. Retrieval as a tool for structured or changing facts.** Give the agent tools for account state, post status and policies; keep stable guidance pre-loaded (hybrid). Applies when answers depend on live data. Trade-off: latency. [Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), [Fin agentic RAG](https://fin.ai/research/structured-agentic-rag-for-e-commerce)
- **P33. Abstain or escalate when context is insufficient.** Strong models give wrong answers instead of abstaining when context is insufficient. A sufficiency check before answering raised the share of correct answers among those given by 2-10%. Applies to every grounded answer. [Sufficient Context](https://arxiv.org/abs/2411.06037)
- **P34. Make escalation an explicit, measured decision with a reason.** Fin predicts escalate / offer escalation / continue plus one of 8 reasons and the cited guideline. The A/B raised resolution (p < 0.01). Applies to "should-not-draft" cases. [Fin escalation](https://fin.ai/research/to-escalate-or-not-to-escalate-that-is-the-question)
- **P35. Fix the content behind high-traffic gaps first.** Approved content fixes raised Fin resolution by 1.23 points on average and up to 10. One customer reached 76% of conversations with 8 approvals. Applies to "missing knowledge" failures. [Fin causal RAG](https://fin.ai/research/a-causal-inference-approach-to-measuring-the-impact-of-improved-rag-content)
- **P36. Hand the agent its handover triggers.** Gorgias hands over on low confidence, a listed topic, no relevant content, an angry customer, or a request for a human. [Gorgias docs](https://docs.gorgias.com/en-US/ai-agent-101-497772)

### Prompting and few-shot

- **P37. Write the system prompt at the "right altitude".** Not a brittle if-else rulebook, not vague. Use examples for behavior, not a "laundry list of edge cases". [Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- **P38. Keep the instruction count low.** At 500 simultaneous instructions the best models reached about 68%; models favor earlier instructions; some models decay linearly or exponentially with count. Applies to persona/rulebook prompts. [IFScale](https://arxiv.org/abs/2507.11538)
- **P39. Put key information at the start or end.** Accuracy drops for information in the middle of long inputs. [Lost in the Middle](https://arxiv.org/abs/2307.03172)
- **P40. Retrieve examples by similarity, then enforce diversity.** Similar examples beat random ones; a set of near-duplicates loses to a covering set. [Liu 2021](https://arxiv.org/abs/2101.06804), [Levy 2023](https://aclanthology.org/2023.acl-long.78)
- **P41. Learn from top performers, not all replies.** The support assistant in Brynjolfsson et al. spread high performers' practices; novices gained 34%, experts little. Applies to choosing which operator replies become examples. [NBER w31161](https://www.nber.org/papers/w31161)
- **P42. Filter examples by outcome.** Use replies whose conversation resolved (no repeat contact, positive reply), not every sent reply. Givore already excludes examples without an outcome (`app/Services/Support/ReplyExampleRetriever.php:20`). [Fin feedback research](https://fin.ai/research/was-that-helpful-understanding-user-feedback-in-customer-support-ai-agents) (Inference on application)

### Self-improvement

- **P43. Learn from what the human sent, via edits.** Infer a preference from each edit. Store it with its context. Retrieve preferences from similar past contexts. Edit distance is the cost to minimize. [PRELUDE/CIPHER](https://arxiv.org/abs/2404.15269)
- **P44. Reflection needs an external signal.** Self-correction helps with code execution, tools or a trained verifier; without one it can degrade. GEPA works because it reflects on scored traces. [Huang 2023](https://arxiv.org/html/2310.01798), [GEPA](https://arxiv.org/abs/2507.19457)
- **P45. Prompt optimizers need a trusted metric and a held-out set.** GEPA takes `trainset` and `valset` and 100-500 metric calls; MIPROv2 scores minibatches of 35 and re-checks on the full valset. Applies before any automatic prompt search. The optimizer will overfit whatever the judge rewards. [GEPA repo](https://github.com/gepa-ai/gepa), [MIPROv2](https://dspy.ai/current/api/optimizers/MIPROv2/)
- **P46. Release changes behind a staged rollout with one-step rollback.** Bundle content, procedures and guidance into a Release; run evals; ramp or A/B; pause and roll back. [Intercom Evals and Releases](https://www.intercom.com/blog/announcing-evals-and-releases)
- **P47. Monitor drift and novelty effects after promotion.** Watch the online metric for noise, novelty and drift; re-run error analysis after incidents or metric drift. [Decagon](https://decagon.ai/blog/evaluation-engine-ai-agents), [evals FAQ](https://hamel.dev/blog/posts/evals-faq/)
- **P48. Track product-level outcomes alongside judged quality.** Use send rate, edit distance, customer reply, repeat contact. [evals FAQ](https://hamel.dev/blog/posts/evals-faq/), [pronix agent-assist](https://pronix.ai/resources/guides/agent-assist-software)

### Customer-support drafting specifically

- **P49. The send-rate metric is "sent unchanged or with a trivial edit".** Acceptance is bimodal: in one 2,760-draft study, 69% went out verbatim and the median edit was 0 characters. Medium-length drafts were accepted most; long ones rarely. Measure verbatim-send rate, and edit distance on edited sends. [scambaiting study](https://arxiv.org/pdf/2509.08493)
- **P50. Acceptance rate needs a downstream quality pair.** Acceptance alone can be inflated by lazy acceptance; pair it with post-send outcomes. [larridin](https://larridin.com/developer-productivity-hub/ai-suggestion-acceptance-rate-benchmark?hs_amp=true) (secondary)
- **P51. Simulations from real conversations, judged per criterion, fail on any failed criterion.** Intercom builds Evals from inbox conversations; one failed criterion fails the simulation. [Intercom Evals and Releases](https://www.intercom.com/blog/announcing-evals-and-releases)

## Anti-patterns

Each item: symptom. Consequence. Source.

- **A1. Rubric written before reading outputs.** The judge scores qualities nobody complained about. Real failures go unmeasured. [Shankar 2024](https://arxiv.org/html/2404.12272), [evals FAQ](https://hamel.dev/blog/posts/evals-faq/)
- **A2. 1-5 score with a threshold.** Midpoints hide uncertainty; a shift from 3 to 4 looks like progress. The pass line is arbitrary. Givore: `sendable_score` = 4 in `config/support.php`. [evals FAQ](https://hamel.dev/blog/posts/evals-faq/)
- **A3. Judge never compared to the human who sends.** A 52% "sendable" replay rate coexists with 0/18 real sends. The metric optimizes the judge's taste. [critique shadowing](https://hamel.dev/blog/posts/llm-judge/)
- **A4. Author, judge and learner on one model.** Self-preference inflates scores; the learner writes guidance the judge already likes. Givore: all three are `claude-opus-5-5`. [Panickssery 2024](https://arxiv.org/abs/2404.13076)
- **A5. Generic metrics (helpfulness, ROUGE, BERTScore) as quality gates.** They do not track the failures users see. Use them only to find traces to read. [evals FAQ](https://hamel.dev/blog/posts/evals-faq/)
- **A6. Raw agreement as judge quality.** An always-pass judge looks 95% accurate at a 5% failure rate. [critique shadowing](https://hamel.dev/blog/posts/llm-judge/)
- **A7. Promotion on a small margin without power.** A 3-point gain on 20-40 cases is mostly noise. The learner churns guidance and "overfits the replay set". [Anthropic stats](https://www.anthropic.com/research/statistical-approach-to-model-evals)
- **A8. Reusing the same replay cases every week for selection.** Repeated selection on one set overfits it even if each comparison is held out from the writer. (Inference, standard model-selection risk; the GEPA/MIPROv2 train/val split is the mitigation.) [MIPROv2](https://dspy.ai/current/api/optimizers/MIPROv2/)
- **A9. Long rulebook prompt that grows with every incident.** Instruction-following decays with count, earlier rules win, middle content is lost. [IFScale](https://arxiv.org/abs/2507.11538), [Lost in the Middle](https://arxiv.org/abs/2307.03172), [Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- **A10. Stuffing every snippet "just in case".** Near-miss snippets act as distractors; one is enough to lower accuracy. [Chroma context rot](https://www.trychroma.com/research/context-rot)
- **A11. Drafting when the KB has no answer.** Strong models answer wrongly instead of abstaining. The operator has to delete the draft. [Sufficient Context](https://arxiv.org/abs/2411.06037)
- **A12. Self-critique loop with no external signal.** Cost doubles; quality flat or worse; gains seen in papers came from a weaker first prompt. [Huang 2023](https://arxiv.org/html/2310.01798)
- **A13. Persona text as the main lever for voice.** Persona effects are unpredictable; examples carry voice better. [Zheng persona study](https://arxiv.org/abs/2311.10054), [Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- **A14. Few-shot examples all from one template.** Similar examples cluster; the drafter copies one shape regardless of the question. [Levy 2023](https://aclanthology.org/2023.acl-long.78)
- **A15. Counting silence as success.** Assumed resolutions include customers who gave up. [Fin feedback research](https://fin.ai/research/was-that-helpful-understanding-user-feedback-in-customer-support-ai-agents)
- **A16. Cost-first automation.** Klarna rehired humans after "lower quality" support. [tech.co](https://tech.co/news/klarna-reverses-ai-overhaul)
- **A17. Outsourcing open coding to an LLM.** LLM clusters merge issues that need different fixes. LLMs may do first-pass axial coding after a human codes 30-50 traces. [evals FAQ automation](https://hamel.dev/blog/posts/evals-faq/what-parts-of-evals-can-be-automated-with-llms.html)
- **A18. Character-level similarity as the only acceptance signal.** `similar_text` rewards shared boilerplate and penalizes a reordered but equal reply. (Inference.) Pair it with a binary "sent as-is / trivially edited / rewritten / not used" class. [scambaiting study](https://arxiv.org/pdf/2509.08493)

## Review checklist candidates

Each: yes/no question. Source. Mechanical verification in a Laravel codebase.

1. **Has a human read and coded at least 50 recent traces since the last prompt change?** [evals FAQ](https://hamel.dev/blog/posts/evals-faq/). Verify: a dated failure-taxonomy file exists in the vault (`grep -rl "open coding\|failure taxonomy" ~/vault/givore/`) with counts per category and a date after the last commit touching the prompt (`git log -1 --format=%cs -- app/Services/Support/Strategies`).
2. **Does the judge output pass/fail per failure mode, not a 1-5 score?** [evals FAQ](https://hamel.dev/blog/posts/evals-faq/). Verify: `grep -n "sendable_score\|low_score" config/support.php` returns nothing; the judge DTO has boolean fields.
3. **Has the judge been measured against the sender's labels, with TPR and TNR on a held-out test split of at least 30 pass and 30 fail?** [critique shadowing](https://hamel.dev/blog/posts/llm-judge/). Verify: `grep -rn -i "tpr\|tnr\|true_positive" app/Services/Support` hits a calibration command; an artisan command prints both rates; a test asserts the split sizes.
4. **Is the judge a different model family from the drafter, or validated despite sharing one?** [Panickssery 2024](https://arxiv.org/abs/2404.13076). Verify: `php artisan tinker --execute="echo config('support.learning.judge_model'), ' ', config('ai.default_chat_model');"` prints different families, or item 3 is satisfied.
5. **Are judge model IDs pinned to dated snapshots?** [judgy guide](https://skills.sh/hamelsmu/evals-skills/validate-evaluator). Verify: `grep -n "_model" config/support.php config/ai.php` shows no floating alias.
6. **Does every reported rate carry a confidence interval and n?** [Anthropic stats](https://www.anthropic.com/research/statistical-approach-to-model-evals). Verify: run `dcart support:drafts:replay ...` and check its output contains n and an interval; a unit test pins the interval for a fixed input.
7. **Was the promotion margin chosen by a power analysis for the case count?** [Anthropic stats](https://www.anthropic.com/research/statistical-approach-to-model-evals). Verify: an ADR in `~/vault/givore/decisions/` states effect size, alpha, power and resulting n; `config/support.php` `replay_cases` ≥ that n.
8. **Is the replay set refreshed with new production cases and a final untouched test set kept?** [evals FAQ](https://hamel.dev/blog/posts/evals-faq/). Verify: `SupportLearningSets` (or a sibling) defines a third split never used by the weekly gate; a test asserts disjointness from writer and replay sets.
9. **Does the eval set include should-not-draft cases (escalate, ask back, ignore)?** [Anthropic agent evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents). Verify: count replay cases by expected action; a test fails if any class is empty.
10. **Is reliability measured with repeated runs (pass^k)?** [tau-bench](https://arxiv.org/abs/2406.12045). Verify: the replay command accepts a runs-per-case option and reports all-runs-pass rate.
11. **Is the production metric "sent as-is or trivially edited", logged per draft?** [scambaiting study](https://arxiv.org/pdf/2509.08493). Verify: `message_drafts` (or outcome table) has a send class column; `grep -n "similar_text" app/Services/Support/SupportOutcomeEvaluator.php` is paired with a class enum.
12. **Is retrieval evaluated on its own with Recall@k?** [Jason Liu](https://jxnl.co/writing/2024/02/28/levels-of-complexity-rag-applications/). Verify: a test or command computes recall@k on labelled question → KB-entry pairs; `grep -rn -i "recall" app/Services/Support tests/` hits.
13. **Does the KB fit in context, and if so is it loaded whole with caching instead of retrieved?** [Anthropic contextual retrieval](https://www.anthropic.com/news/contextual-retrieval). Verify: count KB tokens; if under 200k, check the prompt builder sends the whole KB with a cache-control breakpoint.
14. **Does the drafter return "no draft / escalate" when no KB entry supports the answer?** [Sufficient Context](https://arxiv.org/abs/2411.06037). Verify: a feature test with an empty KB retrieval asserts no draft or an escalation reason.
15. **Does every factual claim in a draft trace to a retrieved snippet or a tool result?** [Sufficient Context](https://arxiv.org/abs/2411.06037). Verify: a grounding check (code or validated judge) runs in the pipeline; a test feeds a draft with an unsupported claim and expects a fail.
16. **Is the system prompt under a fixed instruction budget?** [IFScale](https://arxiv.org/abs/2507.11538). Verify: a test counts rule lines in the persona/guidance (`guidance_max_chars` = 1500 exists in `config/support.php`); add a count of the persona file too.
17. **Are few-shot examples deduplicated for diversity and filtered by good outcome?** [Levy 2023](https://aclanthology.org/2023.acl-long.78). Verify: `ReplyExampleRetriever` applies an outcome filter (it does, line 20) and a max-similarity-between-examples cutoff; a test asserts two near-identical examples are not both returned.
18. **Do redacted examples keep consistent typed placeholders?** [MLflow](https://mlflow.org/articles/pii-redaction-llm). Verify: a `ReplyRedactor` test asserts the same name maps to the same placeholder within one example.
19. **Does any self-critique step use an external signal?** [Huang 2023](https://arxiv.org/html/2310.01798). Verify: a critique pass reads a tool result, KB check or code assertion; otherwise remove it and compare on paired replay.
20. **Does the learner learn from edits and sends, and is each learned rule traced to several customers?** [PRELUDE](https://arxiv.org/abs/2404.15269). Verify: `min_cited_customers` = 3 in `config/support.php`; a test rejects a rule citing fewer.
21. **Is a promoted change confirmed online (send rate) after a fixed period, with rollback?** [Decagon](https://decagon.ai/blog/evaluation-engine-ai-agents), [Intercom](https://www.intercom.com/blog/announcing-evals-and-releases). Verify: a scheduled command compares send rate before/after promotion and demotes on a drop; `grep -n "learn" routes/console.php`.
22. **Are judge length and position biases controlled?** [LC AlpacaEval](https://arxiv.org/abs/2404.04475). Verify: replay output reports mean draft length vs sent reply length; a pairwise judge runs both orders.

## Low-acceptance triage method

Goal: find why Carlos sends 0 of 18 drafts and the replay judge says 52%. Each step names its output.

1. **Freeze the evidence.** Export every draft from the last 60 days with: customer message, retrieved KB snippets, retrieved examples, draft, Carlos's sent reply, time between draft and send. Output: one row per draft. (Use `ReplayInputsExport` / `support:drafts:replay` exports.)
2. **Classify each draft by what Carlos did.** Classes: sent as-is, sent with trivial edit, heavily rewritten, not used. Add "Carlos did not see it" when the draft arrived after he replied. Output: counts per class. If most are "not seen", the problem is latency or UI, not quality. Source: [scambaiting study](https://arxiv.org/pdf/2509.08493).
3. **Open-code 50 drafts with Carlos, side by side with his reply.** One sentence per draft: the first thing wrong. Do not use categories yet. Source: [evals FAQ](https://hamel.dev/blog/posts/evals-faq/).
4. **Axial-code into the fixed taxonomy below, plus any new category that appears.** Count each. Output: a Pareto table.
5. **Apply the fix that matches each category, largest count first.**
   - **Wrong facts** (draft states something false about Givore). Fix: grounding check plus abstain (P33); find whether the KB is wrong, stale or not retrieved. Measure: recall@k on those cases.
   - **Missing knowledge** (Carlos used a fact the KB lacks). Fix: write the KB entry; prioritise high-traffic gaps (P35). Measure: share of cases where the sent reply's key fact is in the KB.
   - **Wrong tone / voice** (facts right, does not sound like Carlos). Fix: better examples, not more persona rules: similarity plus diversity, top-outcome replies only (P40-P42); learned edit preferences (P43). Measure: binary tone check validated against Carlos.
   - **Too long / too much** (Carlos cut it down). Fix: hard length cap in code tied to the sent-reply length distribution; one question per reply. Measure: draft length vs sent length.
   - **Wrong action** (should have checked account, post status, or done something). Fix: give the drafter tools for live state (P32); add the action to the expected output. Measure: tool-call correctness per case.
   - **Should not draft** (spam, abuse, no reply needed, needs Carlos's judgment, legal). Fix: explicit route/escalate decision with a reason before drafting (P34). Measure: TPR/TNR of that classifier on labelled cases.
   - **Context failure** (draft ignores earlier messages or the customer card). Fix: put the latest message and key facts at the start or end; cut distractors (P31, P39).
6. **Validate the judge on the same 50+ labels.** Compute TPR/TNR of the current judge against Carlos's labels. If TNR is low (it passes drafts Carlos would not send), the 52% replay rate is judge bias, not drafter quality. Rebuild the judge as binary per category, few-shot from Carlos's critiques, ideally another model family (P17-P24).
7. **Re-baseline with the validated judge on a paired replay.** Report pass-all rate and per-category rates with intervals. This is the new starting number.
8. **Fix the top category, rerun the paired replay, then check online send rate.** Only promote when the paired lower bound beats the A/A noise. Confirm with real sends over the next period (P13, P16).
9. **Add every newly fixed failure as a regression case.** (P9, P11.)
10. **Repeat steps 3-9 every 2-4 weeks or after any model change.**

## Skill topic candidates

Each a reusable how-to an engineer would load on demand.

1. **Error analysis on agent traces** — export, open coding, axial coding, saturation, Pareto table. Base: [evals FAQ](https://hamel.dev/blog/posts/evals-faq/), [ai-evals-course/evals-skills](https://github.com/ai-evals-course/evals-skills).
2. **Building and validating a binary LLM judge** — critique shadowing, splits, TPR/TNR, bias correction, re-validation triggers. Base: [critique shadowing](https://hamel.dev/blog/posts/llm-judge/), [judgy](https://pypi.org/project/judgy/).
3. **Small-sample eval statistics** — Wilson interval, paired bootstrap, McNemar, clustered SE, power analysis, A/A noise. Base: [Anthropic stats](https://www.anthropic.com/research/statistical-approach-to-model-evals).
4. **Retrieval evaluation and repair** — synthetic question-chunk pairs, recall@k, contextual chunks, hybrid BM25 + pgvector in PostgreSQL, reranking. Base: [Anthropic contextual retrieval](https://www.anthropic.com/news/contextual-retrieval).
5. **Abstention and escalation design** — sufficiency check, reason codes, "should not draft" eval cases. Base: [Sufficient Context](https://arxiv.org/abs/2411.06037), [Fin escalation](https://fin.ai/research/to-escalate-or-not-to-escalate-that-is-the-question).
6. **Few-shot example store** — outcome filtering, similarity plus diversity selection, redaction with consistent placeholders, retention. Base: [Liu 2021](https://arxiv.org/abs/2101.06804), [Levy 2023](https://aclanthology.org/2023.acl-long.78).
7. **Learning from operator edits** — send classes, edit diffs, preference extraction, retrieval of learned preferences. Base: [PRELUDE](https://arxiv.org/abs/2404.15269).
8. **Prompt optimization with a held-out gate** — when to use GEPA/MIPROv2, train/val/test, metric trust, overfitting checks. Base: [GEPA repo](https://github.com/gepa-ai/gepa).
9. **Prompt slimming** — moving rules into examples, code checks or tools; instruction budget; placement. Base: [Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), [IFScale](https://arxiv.org/abs/2507.11538).
10. **Offline-to-online release** — replay gate, staged rollout, online send-rate check, rollback. Base: [Intercom Evals and Releases](https://www.intercom.com/blog/announcing-evals-and-releases).
11. **Building a trace review screen** — one screen with message, context, draft, sent reply, hotkeys for pass/fail and critique. Base: [field guide](https://hamel.dev/blog/posts/field-guide/).

### Reference repos and tutorials

- **Copy:** [ai-evals-course/evals-skills](https://github.com/ai-evals-course/evals-skills) (successor of hamelsmu/evals-skills): error analysis, judge writing, judge validation, RAG eval, review UI.
- **Copy:** [judgy](https://pypi.org/project/judgy/): judge-error correction with bootstrap intervals. Small; the formula is portable to PHP.
- **Copy:** [Anthropic contextual retrieval cookbook](https://www.anthropic.com/news/contextual-retrieval): chunk-context prompt and evaluation harness.
- **Study:** [sierra-research/tau2-bench](https://github.com/sierra-research/tau2-bench): policy + tools + simulated user + DB-state grading; includes Spanish (τ-i18n). Copy the task format, not the harness.
- **Use with care:** [gepa-ai/gepa](https://github.com/gepa-ai/gepa) and DSPy MIPROv2: real gains in papers, but they amplify whatever the metric rewards. With an unvalidated judge they optimize judge bias. "Up to 35x fewer rollouts" and "beats Opus at 90x lower cost" are best-case claims.
- **Hype risk:** OPRO ("up to 50%") and TextGrad (51% → 55% on GPQA) report best-case reasoning benchmarks, not support-reply quality. [OPRO](https://arxiv.org/abs/2309.03409), [TextGrad](https://arxiv.org/abs/2406.07496).
- **Hype risk:** vendor resolution-rate claims (Zendesk "up to 80%", Intercom averages from 51% to 76%) use incompatible definitions and are not draft-send rates. Third-party blogs (eesel.ai, metageeks, clonedesk) are competitor content.
- **Hype risk:** generic RAG metric libraries used as quality gates (faithfulness/relevance scores out of the box) without calibration fall under A5. Use them to find traces, not to gate.

## Sources

| Title | URL | Takeaway |
|---|---|---|
| LLM Evals FAQ (Husain, Shankar) | https://hamel.dev/blog/posts/evals-faq/ | Error analysis first; binary checks; 100+ traces; judge splits; TPR/TNR; CI with deterministic checks. |
| What parts of evals can be automated | https://hamel.dev/blog/posts/evals-faq/what-parts-of-evals-can-be-automated-with-llms.html | Humans do open coding and ground truth; LLMs may do first-pass clustering. |
| Creating a LLM-as-a-Judge (critique shadowing) | https://hamel.dev/blog/posts/llm-judge/ | One expert, pass/fail plus critique, iterate judge to agreement; raw agreement misleads. |
| A field guide to rapidly improving AI products | https://hamel.dev/blog/posts/field-guide/ | Data viewer, experts edit prompts, binary evals, criteria emerge from judging. |
| Who Validates the Validators? (Shankar 2024) | https://arxiv.org/html/2404.12272 | Criteria drift; criteria cannot be fixed before grading outputs. |
| Judging LLM-as-a-Judge (Zheng 2023) | https://arxiv.org/abs/2306.05685 | Position, verbosity, self-enhancement biases; ~80% agreement with humans. |
| Self-preference bias (Panickssery 2024) | https://arxiv.org/abs/2404.13076 | Judges recognise and favour their own outputs. |
| Evaluating LLM-evaluators (Eugene Yan) | https://eugeneyan.com/writing/llm-evaluators/ | Kappa over correlation; bias magnitudes; panels; binary outputs. |
| Length-Controlled AlpacaEval | https://arxiv.org/abs/2404.04475 | Regressing out length raised correlation with humans from 0.94 to 0.98. |
| judgy | https://pypi.org/project/judgy/ | Corrects judged pass rate using TPR/TNR; bootstrap CI. |
| A statistical approach to model evaluations (Anthropic) | https://www.anthropic.com/research/statistical-approach-to-model-evals | SEM, clustered SE, paired differences, power analysis. |
| Demystifying evals for AI agents (Anthropic) | https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents | Capability vs regression evals; pass^k; balanced sets; start with 20-50 real failures. |
| τ-bench | https://arxiv.org/abs/2406.12045 | Policy + tools + simulated user; pass^8 < 25% in retail. |
| tau2-bench repo | https://github.com/sierra-research/tau2-bench | Current harness; Spanish tasks; judges do not affect task reward. |
| LLMs cannot self-correct reasoning yet (Huang 2023) | https://arxiv.org/html/2310.01798 | Intrinsic self-correction degrades; oracle labels inflated prior gains. |
| Self-Refine | https://arxiv.org/abs/2303.17651 | ~20% gains claimed without external feedback; contested by Huang. |
| GEPA paper | https://arxiv.org/abs/2507.19457 | Reflective prompt evolution beats GRPO and MIPROv2 on its tasks. |
| GEPA repo | https://github.com/gepa-ai/gepa | trainset/valset, 100-500 metric calls, textual feedback as signal. |
| DSPy MIPROv2 | https://dspy.ai/current/api/optimizers/MIPROv2/ | Joint instruction + demo search scored on a valset. |
| OPRO | https://arxiv.org/abs/2309.03409 | LLM-as-optimizer; best-case gains on reasoning benchmarks. |
| TextGrad | https://arxiv.org/abs/2406.07496 | Textual gradients; modest QA gain. |
| PRELUDE / CIPHER | https://arxiv.org/abs/2404.15269 | Learn latent preferences from user edits; retrieve by context; minimise edit distance. |
| Contextual Retrieval (Anthropic) | https://www.anthropic.com/news/contextual-retrieval | Contextual BM25 + embeddings + rerank cut retrieval failures 67%; KB < 200k tokens: skip RAG. |
| Effective context engineering (Anthropic) | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents | Right-altitude prompts; diverse canonical examples; just-in-time retrieval. |
| Context Rot (Chroma) | https://www.trychroma.com/research/context-rot | Focused input beats full input on every model; distractors hurt. |
| Lost in the Middle | https://arxiv.org/abs/2307.03172 | Middle-of-context information is used worst. |
| How Many Instructions Can LLMs Follow at Once? (IFScale) | https://arxiv.org/abs/2507.11538 | Accuracy falls with instruction count; early instructions win. |
| Sufficient Context | https://arxiv.org/abs/2411.06037 | Models answer wrongly instead of abstaining; sufficiency-guided abstention helps. |
| Levels of complexity: RAG (Jason Liu) | https://jxnl.co/writing/2024/02/28/levels-of-complexity-rag-applications/ | Retrieval metrics first; synthetic questions; topic vs capability segments. |
| What makes good in-context examples (Liu 2021) | https://arxiv.org/abs/2101.06804 | Similar examples beat random. |
| Diverse Demonstrations (Levy 2023) | https://aclanthology.org/2023.acl-long.78 | Diverse covering sets beat near-duplicate similar ones. |
| Persona prompts (Zheng et al. 2023) | https://arxiv.org/abs/2311.10054 | Personas do not improve factual accuracy; effects unpredictable. |
| Generative AI at Work (NBER) | https://www.nber.org/papers/w31161 | Support assistant raised productivity 14%, novices 34%; spread top performers' practice. |
| Intercom: Evals and Releases | https://www.intercom.com/blog/announcing-evals-and-releases | Simulations from real chats; any failed criterion fails; Releases with A/B and rollback. |
| Fin: escalation model | https://fin.ai/research/to-escalate-or-not-to-escalate-that-is-the-question | 3-way escalate decision with reason and cited guideline; resolution up. |
| Fin: user feedback | https://fin.ai/research/was-that-helpful-understanding-user-feedback-in-customer-support-ai-agents | Assumed vs confirmed resolutions; negative class least reliable. |
| Fin: reranker | https://fin.ai/research/how-we-built-a-world-class-reranker-for-fin | Offline gains shrink in backtest; online A/B decides. |
| Fin: causal impact of RAG content | https://fin.ai/research/a-causal-inference-approach-to-measuring-the-impact-of-improved-rag-content | Content fixes on high-traffic gaps lift resolution. |
| Fin: structured agentic RAG | https://fin.ai/research/structured-agentic-rag-for-e-commerce | Tools with hard filters beat single-shot vector RAG for structured data. |
| Decagon: evaluation engine | https://decagon.ai/blog/evaluation-engine-ai-agents | Offline judge + human audit gate; gradual online A/B on CSAT and resolution. |
| Gorgias AI Agent docs | https://docs.gorgias.com/en-US/ai-agent-101-497772 | Explicit handover triggers; automation rate, CSAT. |
| Zendesk: About AI agents | https://support.zendesk.com/hc/en-us/articles/6970583409690 | Automated resolution = no human escalation. |
| Front help center (AI compose) | https://help.front.com/en/articles/2003 | Drafts from current thread; tone presets; no learning from past replies documented. |
| Klarna reversal (tech.co) | https://tech.co/news/klarna-reverses-ai-overhaul | Cost-first AI support led to "lower quality"; humans rehired. |
| Scambaiting reply-suggestion study | https://arxiv.org/pdf/2509.08493 | 2,760 drafts: 69% verbatim, median edit 0; long drafts rarely accepted. |
| Agent assist metrics (pronix) | https://pronix.ai/resources/guides/agent-assist-software | Track acceptance plus edit distance; handle time alone misleads. Secondary. |
| PII redaction for LLMs (MLflow) | https://mlflow.org/articles/pii-redaction-llm | Typed vs consistent placeholders; test utility on your data. Secondary. |
| ai-evals-course/evals-skills | https://github.com/ai-evals-course/evals-skills | Ready skills for error analysis, judge validation, RAG eval. |
