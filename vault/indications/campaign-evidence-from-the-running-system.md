---
type: indication
project: vault
slug: campaign-evidence-from-the-running-system
scope: repo
tags: [indication, campaign, qa, evidence]
---

# campaign-evidence-from-the-running-system

## Rule
A campaign verdict rests on the running system, and a campaign starts only against a stack the
operator named as disposable. Four obligations:

1. **A verdict cites a run.** A request, a click or a query demonstrates the defect, and the same
   demonstration reversing proves the fix. Reading code forms a hypothesis and closes no case.
2. **Every case carries an injection**, designed before the case runs: a contrary condition that must
   produce a different outcome. Same outcome under the injected condition means the case
   discriminates nothing, and its verdict is `BLOCKED` rather than `PASS`.
3. **The agent that wrote a fix hands its retest to another agent.** An agent grading its own work
   skews positive, so generation and evaluation are separate spawns.
4. **The operator names the disposable stack in words.** A stack the session inferred from a config
   file is not one anyone agreed to lose.

## Contrasting pair

| passes | fails |
|--------|-------|
| `results/QA-14.md` ends `VERDICT: FAIL`, quoting the 500 the endpoint returned and the request that produced it; the injected condition returned 200, so the case discriminates. | `results/QA-14.md` ends `VERDICT: PASS` because the handler "looks correct" and the test asserts `count > 0`; the injected condition returns the same `count > 0`. |
| Step 1 stops with "name the stack you are willing to lose" and waits. | Step 1 finds `docker-compose.yml` and a local `.env`, decides that is the stack, and starts. |

## Rationale
Two campaigns on different stacks produced these rules independently — one Laravel with Playwright,
one Flutter on a phone over adb. In one of them six of seventy-three filings were disproved by
checking them against shipped code, several written by the orchestrator itself.

The disposable-stack obligation exists because `/v-team` was documented as high-stakes only and
reached 78% of runs: an entry condition that excludes almost nothing excludes nothing.

## Applies-to
`commands/v-loop.md`, `commands/v-loop/campaign-rules.md`, `templates/campaign/**`,
`prompts/on-device-e2e-campaign.md`, `checks/v-loop-SC-*.sh`

## Refs
- [[../decisions/ADR-027-autonomous-test-fix-loop]] — the decision this rule carries.
- [[rules-the-model-can-check]] — why obligation 4 is worded as a recognition test.
