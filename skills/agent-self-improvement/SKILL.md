---
name: agent-self-improvement
description: Load when an LLM agent your product runs changes itself from feedback: rules learned from operator edits, an example store or prompt optimization. Covers learning from sent text, the promotion gate, online confirmation, rollback and poisoning control.
---

# Agent self-improvement

## When to use

- The agent learns rules, preferences or examples from what a human did with its output.
- A job promotes a new prompt, rule set or example set without a person approving each change.
- You consider GEPA, MIPROv2 or another prompt optimizer.
- Building and calibrating the metric itself lives in `skills/agent-evals/SKILL.md`. Never start here without that metric.

## Rules

- **Learn from the text the operator sent, never from approve clicks.** The edit between draft and sent reply carries the preference; a click carries none. https://arxiv.org/abs/2404.15269
- **Store each inferred preference with the context it came from, and retrieve it by similar context.** A preference applied everywhere rewrites replies it never fitted. https://arxiv.org/abs/2404.15269
- **Learn only from replies with a good outcome and from the best senders.** A support assistant raised novices most by spreading top performers' practice. https://www.nber.org/papers/w31161
- **Give every reflection or self-critique step an external signal.** Intrinsic self-correction degraded reasoning in Huang et al. https://arxiv.org/html/2310.01798
- **Treat self-refinement gains without feedback as unproven.** Self-Refine's gain vanished once the first prompt stated the requirement. https://arxiv.org/abs/2303.17651
- **Gate every promotion on a metric calibrated against the human who acts on the output.** An uncalibrated judge makes the learner optimize the judge's taste. https://hamel.dev/blog/posts/llm-judge/
- **Split cases into train, validation and a held-out test that no selection step ever reads.** Repeated selection on one set overfits that set. https://dspy.ai/current/api/optimizers/MIPROv2/
- **Set the promotion margin and case count from a power analysis, and compare paired on the same cases.** A 3-point margin on 20–40 cases sits inside the noise. https://www.anthropic.com/research/statistical-approach-to-model-evals
- **Confirm each promotion online on the real send rate, in stages, with automatic demotion.** One reranker gained 13% recall offline and about 3% in a production backtest. https://fin.ai/research/how-we-built-a-world-class-reranker-for-fin
- **Make every learned rule and release revertible on its own in one step.** A bad rule must leave without reverting the good ones. https://www.intercom.com/blog/announcing-evals-and-releases
- **Never auto-append model output to the example store or any trusted memory.** A poisoned entry reaches every later answer. https://genai.owasp.org/resource/agentic-ai-threats-and-mitigations/
- **Admit an example only with provenance: human-sent, source chat, sender, outcome and date.** Without provenance you cannot find or remove a poisoned entry. https://genai.owasp.org/resource/agentic-ai-threats-and-mitigations/
- **Require each learned rule to cite several distinct customers.** A rule from one chat turns one customer's quirk or one attacker's text into policy. https://arxiv.org/abs/2404.15269
- **Run a prompt optimizer only with a trusted metric and a held-out set.** GEPA and MIPROv2 overfit whatever the judge rewards, so they amplify judge bias. https://github.com/gepa-ai/gepa
- **Monitor the online metric for drift and novelty after promotion.** Re-run error analysis after an incident, a model change or a metric drop. https://decagon.ai/blog/evaluation-engine-ai-agents

## Steps

1. Confirm a calibrated metric exists with TPR, TNR and n on a test split. If not, stop and build it with `skills/agent-evals/SKILL.md`.
2. Record the send class and the sent text for every draft. Diff draft against sent text per draft.
3. Infer one preference per meaningful edit. Store it with its context, the source chat and the customer.
4. Promote a preference to a candidate rule only when it cites the configured minimum of distinct customers.
5. Admit examples only from human-sent replies with a good outcome. Record provenance on each row.
6. Split cases by chat into train, validation and test. Assign a chat to one split for life.
7. Fix the smallest gain worth shipping, alpha and power. Compute the case count before the run.
8. Run candidate and current version paired on the validation cases. Promote only when the paired interval's lower bound beats the A/A noise.
9. Run the held-out test once for the promoted candidate. Never use its result to choose between candidates.
10. Release to a share of traffic. Compare the send rate with its interval against the period before.
11. Demote automatically when the online send rate drops below the threshold. Record the reason on the rule.
12. Watch the online rate weekly. Re-run error analysis after drift, an incident or a model change.

Prompt optimizers: pass GEPA or MIPROv2 a `trainset` and a `valset`, keep a third test set outside the optimizer, and validate the metric first. Expect GEPA to need 100–500 metric calls per run.

## Checks

- `grep -rnE "approv" app/` on the learning path shows no learning job reading an approval flag as its label.
- A test runs the learner with a faked model and asserts no model output lands in the example or memory table.
- A test asserts the train, validation and test sets share no chat id, and that selection code never reads the test set.
- A test rejects a learned rule citing fewer distinct customers than the configured minimum.
- The promotion config states the margin and case count, and a decision record states the effect size, alpha and power behind them.
- A scheduled command compares the send rate before and after each promotion and demotes on a drop. A test covers the demotion.
- `grep -rniE "gepa|mipro|dspy|optimi[sz]e" app/ config/` hits only code that also reads a held-out set.
- Each learned rule row has a status, a version, a promoted date and a demoted date.

## Laravel

- Detect the client first: `composer show | grep -E "prism-php/prism|laravel/ai"`. Never assume either.
- Find existing fakes: `grep -rnE "Prism::fake|PrismFake|Agent::fake" tests/`. Fake the learner in every test.
- Store learned rules in a table with status, version and timestamps. Link cited customers through a pivot table, so a query can count them.
- Store examples with provenance columns: source chat, sender, outcome, sent at. Reject inserts without them in a FormRequest or the model.
- Give promotion, demotion and replay their own artisan commands, so an operator can run and revert each one.
- Schedule the learner and the online check in `routes/console.php`. Check what exists with `grep -n "Schedule::" routes/console.php`.
- Extend user erasure to the example store, learned rules and replay cases that hold that user's text.

## Sources

- PRELUDE and CIPHER, learning from user edits: https://arxiv.org/abs/2404.15269
- Generative AI at Work: https://www.nber.org/papers/w31161
- Large language models cannot self-correct reasoning yet: https://arxiv.org/html/2310.01798
- Self-Refine: https://arxiv.org/abs/2303.17651
- Creating an LLM-as-a-Judge: https://hamel.dev/blog/posts/llm-judge/
- DSPy MIPROv2: https://dspy.ai/current/api/optimizers/MIPROv2/
- GEPA: https://github.com/gepa-ai/gepa
- A statistical approach to model evaluations: https://www.anthropic.com/research/statistical-approach-to-model-evals
- Fin reranker: https://fin.ai/research/how-we-built-a-world-class-reranker-for-fin
- Intercom Evals and Releases: https://www.intercom.com/blog/announcing-evals-and-releases
- OWASP Agentic AI Threats and Mitigations: https://genai.owasp.org/resource/agentic-ai-threats-and-mitigations/
- Decagon evaluation engine: https://decagon.ai/blog/evaluation-engine-ai-agents
