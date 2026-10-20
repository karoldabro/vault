---
name: agent-evals
description: Load when you measure or gate an LLM agent your product runs for its users. Covers trace error analysis, binary judges calibrated by TPR and TNR, Wilson intervals, power, pass^k, and triage of drafts the operator will not send.
---

# Agent evals

## When to use

- You choose metrics for an agent, for example a support drafter whose drafts an operator sends or rewrites.
- A judge score gates a release, a prompt change or a learned rule.
- The offline score and the production send rate disagree.
- Learned changes and their promotion gate live in `skills/agent-self-improvement/SKILL.md`.

## Rules

- **Code traces before you choose any metric.** A rubric written before reading outputs measures qualities nobody complained about. https://hamel.dev/blog/posts/evals-faq/
- **Let the domain expert who acts on the output own pass and fail.** A judge tuned to the engineer's taste does not predict what the operator sends. https://hamel.dev/blog/posts/llm-judge/
- **Label each failure mode pass or fail with a written critique.** A 1–5 score hides uncertainty, and its cut line is arbitrary. https://hamel.dev/blog/posts/field-guide/
- **Assert in code what code can check, then add LLM checks.** Length, links, leftover placeholders and forbidden phrases need no judge. https://hamel.dev/blog/posts/evals-faq/
- **Report the judge's TPR and TNR on a held-out test split.** At a 5% failure rate, an always-pass judge reaches 95% raw agreement and catches nothing. https://hamel.dev/blog/posts/llm-judge/
- **Report Cohen's kappa for agreement.** Correlation read 0.8–0.9 where kappa read 0.3–0.5 on the same labels. https://eugeneyan.com/writing/llm-evaluators/
- **Correct a judged rate before you report it as true.** Use θ = (p_obs + TNR − 1) / (TPR + TNR − 1) with a bootstrap interval. The formula fails when TPR + TNR is near 1. https://pypi.org/project/judgy/
- **Use a judge from another model family, or validate a same-family judge first.** Judges recognise and favour their own outputs. https://arxiv.org/abs/2404.13076
- **Give the judge the human's sent reply as a reference answer when one exists.** Without it the judge grades against its own ideal. https://arxiv.org/abs/2306.05685
- **Control length and swap positions in every comparison.** Judges preferred a longer answer over 90% of the time. One judge favoured the first position 70% of the time. https://eugeneyan.com/writing/llm-evaluators/
- **Pin dated model ids and re-validate the judge after any prompt or model change.** A floating alias changes the judge with no commit. https://hamel.dev/blog/posts/evals-faq/
- **Print n and a 95% Wilson interval beside every rate.** Worked example: 37 passes in 71 cases gives 40.7–63.3%, which overlaps 45 in 71 at 51.8–73.6%. https://www.anthropic.com/research/statistical-approach-to-model-evals
- **Compare candidates paired on the same cases, and cluster errors by chat or customer.** Pairing removes case difficulty from the difference; cases from one chat are not independent. https://www.anthropic.com/research/statistical-approach-to-model-evals
- **Run a power analysis before you trust a margin.** Worked example: with 71 unpaired cases per arm, a test detects only about a 23-point gap at 80% power. https://www.anthropic.com/research/statistical-approach-to-model-evals
- **Keep a capability set and a regression set, each with should-act and should-not-act cases.** A set of only should-act cases trains the agent to draft for everything. https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- **Measure pass^k on customer-facing paths.** A case passes only when all k runs pass, which exposes drafts that are good once. https://arxiv.org/abs/2406.12045
- **Measure drafts in production by send class.** Classes: sent as-is, trivially edited, rewritten, not used, not seen; acceptance is bimodal. https://arxiv.org/pdf/2509.08493

## Steps

1. Export traces: input, retrieved context, tool calls, output, and what the human did with it. Stratify by issue type.
2. Open-code at least 50 traces with the domain expert, one sentence each for the first upstream failure. Use no categories yet.
3. Keep reading until new traces add no new failure mode. Aim for 100 per cycle.
4. Axial-code the notes into a failure list with a count per mode. A model may draft the grouping after a human coded 30–50 traces.
5. Write one evaluator per failure mode: a code check where possible, else a binary LLM judge with a critique.
6. Split the expert's labels: 10–20% train for judge examples, 40–45% dev, 40–45% test. Hold 30–50 passes and 30–50 fails in dev and in test.
7. Iterate the judge prompt on dev only. Freeze it, then run test once and record TPR, TNR and kappa.
8. Report a pass-all rate and a rate per check, each with n, a Wilson interval and the judge-corrected value.
9. Before a comparison, fix the smallest gain worth shipping, compute the cases needed, and run both arms on the same cases.
10. Turn every production failure into a regression case. Repeat steps 1–4 every 2–4 weeks and after any model change.

Low-acceptance triage, when the operator sends few drafts:

1. Freeze the evidence: one row per draft with message, context, examples, draft, sent reply and the time between them.
2. Classify each draft by send class. If most are `not seen`, fix latency or the screen before quality.
3. Open-code 50 drafts beside the sent replies with the operator, then count them into the taxonomy below.
4. Fix the largest category first, using its fix and measure from the table.
5. Compute the current judge's TPR and TNR on the same labels. A low TNR means the offline rate reflects judge bias.
6. Re-baseline with the validated judge on a paired replay. That number is the new starting point.

| category | fix | measure |
|---|---|---|
| wrong facts | grounding check, abstain when unsupported | recall@k on those cases |
| missing knowledge | write the knowledge entry, high-traffic gaps first | share of sent replies whose key fact is in the knowledge base |
| tone | better examples and learned edit preferences, fewer persona rules | binary tone check validated against the operator |
| too long | length cap in code from the sent-reply length distribution | draft length against sent length |
| wrong action | tools for live state | tool-call correctness per case |
| should not draft | route or escalate with a reason before drafting | TPR and TNR of that decision |
| context failure | key facts at the start or end, distractors removed | per-case pass on long threads |

## Checks

- `grep -rnE "(judge|sendable|quality)_score'\s*=>" config/` finds no graded judge-score cut line that gates work. Retrieval thresholds such as `min_score` are out of scope.
- `grep -rniE "tpr|tnr|kappa" app/` hits the judge calibration code, and its output prints both rates and n.
- `grep -rnE "_model'\s*=>" config/` shows a dated snapshot id for every judge and author model.
- A unit test asserts the Wilson interval for 37 passes in 71 cases is 40.7–63.3%.
- A test fails when the eval set holds no should-not-act case.
- The replay command accepts a runs-per-case option and prints the all-runs-pass rate.
- A dated failure list with counts per mode is newer than `git log -1 --format=%cs -- <prompt path>`.
- The draft or outcome table has a send-class column, written for every draft.

## Laravel

- Detect the client first: `composer show | grep -E "prism-php/prism|laravel/ai"`. Never assume either.
- Find existing fakes: `grep -rnE "Prism::fake|PrismFake|Agent::fake" tests/`. Unit-test the statistics and the harness with fakes.
- Run live evals only from an artisan command, for example `php artisan agent:replay --cases=100 --runs=3`. Keep live model calls out of PHPUnit.
- Store expert labels in a table: trace id, failure mode, pass boolean, critique, labeller, split.
- Store each run in a table: prompt version, author and judge model ids, n, passes, interval bounds, TPR, TNR, kappa.
- Schedule the trace export and the regression run in `routes/console.php`. Check what the repo uses with `grep -n "Schedule::" routes/console.php`.

## Sources

- LLM Evals FAQ: https://hamel.dev/blog/posts/evals-faq/
- Creating an LLM-as-a-Judge: https://hamel.dev/blog/posts/llm-judge/
- A field guide to rapidly improving AI products: https://hamel.dev/blog/posts/field-guide/
- Evaluating LLM-evaluators: https://eugeneyan.com/writing/llm-evaluators/
- judgy: https://pypi.org/project/judgy/
- Self-preference bias in LLM evaluators: https://arxiv.org/abs/2404.13076
- Judging LLM-as-a-Judge: https://arxiv.org/abs/2306.05685
- A statistical approach to model evaluations: https://www.anthropic.com/research/statistical-approach-to-model-evals
- Demystifying evals for AI agents: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- τ-bench: https://arxiv.org/abs/2406.12045
- Reply-suggestion acceptance study: https://arxiv.org/pdf/2509.08493
