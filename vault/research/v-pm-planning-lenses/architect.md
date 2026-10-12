# Architect lens for PLAN-CRITIC (research)
Verified = fetched this session. [UNVERIFIED] = from memory, no source reached.

## 1. Architect responsibilities, plan question, evidence
Format: R. responsibility (source) | Q: question | EVIDENCE: what confirms a defect
1. Decide what is architecturally significant ("important stuff", hard-to-change decisions) - https://martinfowler.com/architecture/ ; https://adr.github.io/
   Q: Does the plan separate the few hard-to-reverse decisions (data model, boundaries, protocols, persisted formats) from reversible detail?
   EVIDENCE: plan has no such list; a one-way decision (schema, public file format, command name) sits unflagged in a task step; file:line of the persisted artifact it changes.
2. Elicit quality attributes and rank them (ATAM utility tree, scenarios) - https://www.sei.cmu.edu/library/architecture-tradeoff-analysis-method-collection/
   Q: Does the plan name the 1-3 quality attributes that drive it (e.g. latency, auditability, determinism) and say which wins on conflict?
   EVIDENCE: plan missing a goals/non-goals or "optimise for" line; two plan steps that pull opposite ways (speed vs. safety) with no stated priority.
3. Make trade-offs explicit; record alternatives considered - https://www.industrialempathy.com/posts/design-docs-at-google/ (doc is "the place to write down the trade-offs"; alternatives section is among the most important)
   Q: For each significant choice, does the plan list at least one rejected alternative and why?
   EVIDENCE: missing "alternatives" section; a choice where an obvious option (existing library, existing module) is never mentioned.
4. State goals AND non-goals, context and scope - same Google source; arc42 s1,s3 https://docs.arc42.org/home/
   Q: Are scope boundaries and non-goals written so a reviewer can tell what is out?
   EVIDENCE: plan lacks non-goals; task list touches a component not in the stated scope (cite plan line + file).
5. Define boundaries, responsibilities and interfaces (building blocks, containers/components) - https://c4model.com/ (system, container, component, code); arc42 s5 https://docs.arc42.org/home/
   Q: Does each new unit have one stated responsibility, an owner, and a named interface (inputs, outputs, errors)? Do dependencies point one way?
   EVIDENCE: two units in the plan own the same state/decision; circular import visible in import graph / manifest; interface missing from plan.
6. Cover runtime behaviour, failure and recovery (runtime view, reliability pillar) - https://docs.arc42.org/home/ ; https://docs.aws.amazon.com/wellarchitected/latest/framework/the-pillars-of-the-framework.html
   Q: For each external call or multi-step flow, does the plan say what happens on failure, retry, partial completion, concurrent run?
   EVIDENCE: a step that writes then calls out with no rollback/idempotence note; existing code path at file:line that already shows the failure mode.
7. Address cross-cutting concerns by name (security, privacy, observability, config, errors) - Google design-docs source; arc42 s8 https://docs.arc42.org/home/ ; AWS pillars (operational excellence, security, reliability, performance, cost, sustainability)
   Q: Does the plan state which cross-cutting concerns apply, and the single mechanism used (not a new ad hoc one per component)?
   EVIDENCE: two different error/config mechanisms in the plan; existing shared mechanism at file:line that plan bypasses. (Owning specifics goes to other critics, see 6.)
8. Surface constraints and fit them (technical, organisational, conventions) - arc42 s2 https://docs.arc42.org/home/
   Q: Are binding constraints (runtime, licence, deployment target, team skill, existing contracts) listed and does every design choice satisfy them?
   EVIDENCE: dependency manifest (package.json, pyproject, plugin manifest) conflicting with the plan; ADR that forbids the approach; runtime version.
9. Record decisions as ADRs with context, decision, consequences (+ and -) - https://adr.github.io/ ; https://www.martinfowler.com/bliki/ArchitectureDecisionRecord.html (supersede, don't edit)
   Q: Does the plan reverse or contradict an existing ADR, or make a significant decision that needs a new one, and say which?
   EVIDENCE: path of the conflicting ADR in the decisions folder; plan has a significant decision with no ADR task.
10. Identify risks, sensitivity and trade-off points; track technical debt - SEI ATAM outputs https://www.sei.cmu.edu/library/architecture-tradeoff-analysis-method-collection/ ; arc42 s11 https://docs.arc42.org/home/
   Q: Does the plan list its top risks and the debt it knowingly takes, each with a trigger to revisit?
   EVIDENCE: plan has no risk list; a stated shortcut with no owner/trigger; spike absent for the riskiest unknown.
11. Validate the architecture continuously; keep decisions checkable (fitness-style checks; "Continually Analyze the Architecture" in Richards/Ford) - https://oreilly.com/library/view/fundamentals-of-software/9781492043447 (TOC confirmed; body text not read)
   Q: Does the plan say how each architectural claim is verified after the build (test, lint rule, schema check, grep-able invariant)?
   EVIDENCE: claim like "keeps modules independent" with no verification step; no test/gate task mapping to a stated quality attribute.
12. Address concerns for each stakeholder; keep rationale ("why" before "how") - ISO 42010 concerns/stakeholders https://www.iso-architecture.org/42010/define/concerns.html [fetch failed; from memory] ; Richards/Ford "why is more important than how" [UNVERIFIED wording]
   Q: Does the plan name who consumes the result (user, operator, downstream agent, other repo) and what each needs from it?
   EVIDENCE: consumer absent from plan; output format a named consumer cannot parse (cite the consumer file:line).

## 2. Agent-harness additions (prompts, commands, orchestration)
- Start with the simplest workable pattern; add agent autonomy only when it measurably helps - https://www.anthropic.com/engineering/building-effective-agents
  Q: Does the plan justify an agent/loop over a fixed workflow or single call? EVIDENCE: plan chooses open-ended agent loop for a path with fixed steps (cite the steps).
- Tool/interface design (agent-computer interface) is architecture: same source.
  Q: Are tool/command contracts (inputs, outputs, errors) specified and tested? EVIDENCE: command file lacking output schema; prompt that parses free text.
- Stopping conditions and sandboxed testing: same source.
  Q: Does every loop have a max iteration / budget / exit evidence? EVIDENCE: loop step with no bound.
- Measure and iterate: same source. Q: Is there an eval or check per agent stage? EVIDENCE: stage with no exit evidence.
- Treat prompt, command, and subagent boundaries as components: one responsibility each, explicit hand-off artifact (same C4/arc42 building-block logic as R5).

## 3. Evidence rule
- CONFIRMED defect needs one of: file:line in repo; named missing plan section (quote the heading list); dependency manifest line; ADR path; external source URL.
- No evidence -> mark ADVISORY. Google's rule of thumb: a doc without trade-offs/alternatives reads as an implementation manual (https://www.industrialempathy.com/posts/design-docs-at-google/).

## 4. Scale awareness (do NOT demand)
- Effort must match risk: "Architecture efforts should be commensurate with the risk of failure"; "When you are unconcerned about security risks, spend no time on security design"; wasted design time is itself a risk - Fairbanks, https://www.methodsandtools.com/archive/agilearchi.html . Risk-driven model: identify and prioritise risks, apply techniques, evaluate risk reduction (same URL).
- Do not demand a design doc when the solution is unambiguous; small changes get a 1-3 page mini doc - https://www.industrialempathy.com/posts/design-docs-at-google/
- Do not demand speculative generality: costs of build, delay, carry, repair - https://www.martinfowler.com/bliki/Yagni.html . Fowler: "when in doubt err on the side of simplicity"; build generic structures only as needed - https://martinfowler.com/articles/designDead.html
- Counterweight: YAGNI fails where code is hard to change; "easier to refactor over-design than no design"; broad starting architecture has a role (same two Fowler URLs). So demand early thought only on hard-to-reverse decisions (R1).
- Do not demand: full arc42/C4 sets, ATAM workshop, utility tree, ADR for every choice, microservice boundaries for a single repo, multi-stakeholder views when one consumer exists. arc42 itself says Architecture Decisions = those "costly, risky, or disputed" (https://docs.arc42.org/home/). C4 is notation/tooling independent, a menu not a quota (https://c4model.com/).
- Agent work: prefer fixed workflow over multi-agent orchestration unless it "demonstrably improves outcomes" (https://www.anthropic.com/engineering/building-effective-agents).
- Red Hat: ADRs are for larger decisions, not a changelog (via search result https://www.redhat.com/architect/architecture-decision-records; page not opened).

## 5. Severity guidance (plan level; critic judgement, anchored to the sources above)
- SHIP-STOPPER: plan contradicts an accepted ADR or hard constraint (manifest/runtime) with evidence; one-way decision (persisted schema, public contract) made with no alternative and a named consumer would break; two units own the same state; unbounded agent loop; no failure behaviour for a step that mutates shared state; plan cannot satisfy its own top quality attribute.
- WORTH-FIXING: no stated quality-attribute priority where steps conflict; missing non-goals causing scope creep in the task list; cross-cutting mechanism duplicated; verification of an architectural claim absent; significant decision lacking ADR task; unowned stated risk.
- SMALL: naming of internal units, diagram absent for a 1-repo change, ADR wording, missing alternatives for a reversible choice, preference between equal options.
- Escalate severity by reversibility and blast radius (Fowler "hard to change": https://martinfowler.com/architecture/); lower it when risk is low (Fairbanks URL above).

## 6. Decorrelation (architect owns structure and trade-offs; defers the rest)
- Owns: boundaries/responsibilities, interfaces, quality-attribute trade-offs, constraints/ADR conflicts, one-way decisions, failure/runtime behaviour at design level, verification of architectural claims.
- codebase-fit: reuse of existing modules, repo patterns, naming. Architect only cites ADRs/constraints, not "repo already does X this way".
- lazy-dev: buy-vs-build, simplest path, library choice. Architect only asks for alternatives and trade-offs, not which wins on effort.
- future-scope: extensibility, deferred logs/analytics/MVP-dropped items. Architect checks only the hard-to-reverse seams (R1), never "will it scale to X".
- system-integration: cross-system data flow, contracts between repos. Architect owns the internal interface; hands off cross-repo flows.
- security-architect: threat model, authz, secrets. Architect checks only that the concern is named and uses one mechanism (R7).
- delivery-planner: session slicing, rollout, ordering. Architect flags ordering only when it breaks a dependency direction.
- Rule: report once under the owning lens; if a finding fits two, the architect keeps it only if the evidence is a boundary, ADR, constraint, or trade-off.

## 7. Not verified
- Uber, Stripe design-review practice: not reached.
- Richards/Ford full "Expectations of an Architect" list and "everything is a trade-off" wording: only TOC items 1-3 confirmed via search; free chapter PDF fetch not read.
- ISO 42010 definitions: fetch failed (connection refused); R12 is from memory.
- Fairbanks exact phrase "architecture proportional to risk": not found; closest verified quote is "commensurate with the risk of failure".
- Nygard ADR original post: not opened; section list via secondary summary (gds-way) in search result.
- AWS Well-Architected: pillars list verified; per-pillar trade-off text not read.
