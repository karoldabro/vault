# delivery-planner: grounding for the session-split critic

Status tags: [F] fetched and read this run. [K] known, URL not fetched (fetch failed or not attempted). [FW] framework-local evidence, no URL.

## 1. Review questions (10-12)
1. Does each session deliver one observable, verifiable behavior change that cuts through all layers it needs (vertical), not one layer? Horizontal splits fail "independent" and "valuable". [F] https://www.humanizingwork.com/the-humanizing-work-guide-to-splitting-user-stories/
2. Does session 1 build the thinnest end-to-end path that exercises the architecture (walking skeleton) before breadth is added? [K] https://alistair.cockburn.us/walking-skeleton/ (fetch 404; definition: tiny implementation of the system that performs one small end-to-end function and links the main components)
3. Is the riskiest unknown in the earliest session, so it surfaces while time remains? "Push the scariest scopes uphill early"; routine work later. [F] https://basecamp.com/shapeup/3.4-chapter-12
4. Is the first session a tracer bullet (real, kept code on the real path) or a throwaway prototype, and is it labelled? Tracer = try and see how close it lands; prototype = value is the lesson, not the code. [F] https://pragprog.com/tips/
5. Is each session small enough for one context window? Performance degrades as context fills; "too big for one pass" is a named failure. [F] https://code.claude.com/docs/en/best-practices ; one feature per session, whole-task attempts ran out of context mid-feature: [F] https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
6. Is the session short in agent-task terms? Success is ~100% on tasks under 4 human-minutes and <10% over ~4 human-hours (March 2025 data; the 50% horizon doubles about every 7 months, so thresholds drift upward). [F] https://metr.org/blog/2025-03-19-measuring-ai-ability-to-complete-long-tasks/
7. Does every session end with a command that returns pass/fail (test, build exit code, script diff)? "If you can't verify it, don't ship it." [F] https://code.claude.com/docs/en/best-practices
8. Are dependencies explicit, acyclic, and does each session state what it hands the next (files, interfaces, flags, a progress note)? Sessions have no memory; a progress file plus git log carries state. [F] https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
9. Does main stay releasable after every session (mergeable clean state: no half-finished work, descriptive commit)? [F] https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents ; trunk stays green, integrate at least daily: [F] https://trunkbaseddevelopment.com/
10. Are breaking changes sequenced as expand, migrate, contract, with each phase releasable and the old path intact until contract? [F] https://martinfowler.com/bliki/ParallelChange.html
11. Is unfinished user-visible work hidden behind a release toggle with a removal session planned, and does each session name its rollback (revert commit, flag off, old path still live)? Toggles carry cost; plan removal at creation. [F] https://martinfowler.com/articles/feature-toggles.html
12. Is the session count proportional to the task (appetite first, scope flexes), and could the plan be one session? "If you could describe the diff in one sentence, skip the plan." [F] https://basecamp.com/shapeup/1.2-chapter-03 ; https://code.claude.com/docs/en/best-practices
Optional 13 (INVEST per session: independent, valuable, small, testable). [F] https://agilealliance.org/glossary/invest/

## 2. Mechanical checks (script-checkable on the plan's session table)
Each check = rule, severity, source for the underlying principle.
- C1 Missing acceptance command: session has no field `accept:` holding a runnable command, or the command is prose ("works correctly", "looks good"). BLOCK. Source: https://code.claude.com/docs/en/best-practices (check returns pass/fail Claude can read).
- C2 Command not runnable as written: acceptance command references a path/script no session or repo creates. BLOCK. Same source.
- C3 Depends cycle: build graph from `depends:`; any cycle or self-edge. BLOCK. Source: https://www.humanizingwork.com/the-humanizing-work-guide-to-splitting-user-stories/ (independence); cycle detection is plain topological sort, no source needed.
- C4 Orphan consumption: session lists an input (file, table, flag, API, fixture) that no earlier session lists under `produces:` and that does not exist in the repo at plan time. BLOCK. Source: handoff artifacts must exist for a fresh session: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- C5 Dangling dependency: `depends:` names a session id not in the plan. BLOCK. (no source needed)
- C6 Size: estimated files touched > 15 WARN, > 25 BLOCK (thresholds are framework calibration [FW]: ~9 files landed cleanly, ~49 dropped work; no public source gives a file count). Context rationale: https://code.claude.com/docs/en/best-practices
- C7 Layer-only session: title/goal matches layer words only ("add migrations", "add models", "create API layer", "write tests", "add types", "UI scaffolding") and acceptance cannot be exercised from outside that layer. WARN. Source: https://www.humanizingwork.com/the-humanizing-work-guide-to-splitting-user-stories/
- C8 Test-last split: a "tests" session separate from the code it tests. WARN; tests belong in the same slice. Source: https://github.com/github/spec-kit/blob/main/spec-driven.md (tests written and failing before implementation).
- C9 Risk ordering: the session tagged `risk: high` (or containing the external integration / migration / unknown) has index > 1 while a low-risk session precedes it. WARN. Source: https://basecamp.com/shapeup/3.4-chapter-12
- C10 Contract without migrate: a session removes/renames a schema column, API field, or exported symbol and no earlier session adds the replacement and moves callers. BLOCK. Source: https://martinfowler.com/bliki/ParallelChange.html
- C11 Expand and contract in one session for a shared interface/DB (single deploy cannot roll back). WARN. Same source.
- C12 No rollback field: session touching a migration, flag, config, or external service lacks `rollback:`. WARN/BLOCK for data. Source: https://martinfowler.com/bliki/ParallelChange.html
- C13 Flag without removal: plan adds a toggle but no later session removes it. WARN. Source: https://martinfowler.com/articles/feature-toggles.html
- C14 Main-breaking order: session N changes a signature or removes a symbol that session N+k still uses (k>0). BLOCK. Source: https://trunkbaseddevelopment.com/
- C15 Over-split: session count > ceil(total est. files / 9) + 1, or any session < 2 files with no own risk and a hard dependency on its neighbour. WARN. Rationale in section 4.
- C16 Under-split (inverse): one session with > 1 independent acceptance commands covering unrelated behaviors. WARN.
- C17 Handoff gap: session has `depends:` but its prompt block lacks a "previous session produced" line. WARN. Source: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- C18 Parallel collision: two sessions marked parallel list overlapping files. BLOCK. Source: worktrees isolate parallel sessions but do not merge for you: https://code.claude.com/docs/en/best-practices ; spec-kit `[P]` marks only independent tasks: https://github.com/github/spec-kit/blob/main/spec-driven.md

## 3. Self-contained session prompt (checklist the critic verifies per session)
Why: a fresh session has no memory of earlier ones. [F] https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
Best-practice spec wording: self-contained specs "name the files and interfaces involved, state what is out of scope, and end with an end-to-end verification step". [F] https://code.claude.com/docs/en/best-practices
Required fields, in order:
- Goal: one sentence, observable outcome. (scope the task: file, scenario, test preference) https://code.claude.com/docs/en/best-practices
- Read first: exact repo paths (and line ranges where known), not "look around"; unscoped exploration fills context. https://code.claude.com/docs/en/best-practices
- Pattern to follow: path of an existing example file. https://code.claude.com/docs/en/best-practices
- Constraints: libraries allowed, conventions, safety rules, flag name, compatibility promise.
- Inputs from previous session: artifact paths, interface names, flag state, commit/progress-note reference; the next session starts by reading progress notes and git log and running a basic app check. https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Out of scope: explicit list (stops neighbour-session work leaking in). https://code.claude.com/docs/en/best-practices
- Acceptance command(s) with expected result; ask for evidence (output), not assertion. https://code.claude.com/docs/en/best-practices
- Exit state: committed, main releasable, progress note updated, rollback stated. https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Run/test commands the agent cannot guess (init script style). https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Test tip: tests written and confirmed failing before implementation (spec-driven). https://github.com/github/spec-kit/blob/main/spec-driven.md
- Do not paste the whole plan: a prompt carries only this session's slice plus the handoff; extra text dilutes (CLAUDE.md-style rule: "would removing this cause a mistake?"). https://code.claude.com/docs/en/best-practices
- Fresh-context reviewer for the diff against the plan, told to flag only correctness/requirement gaps (else over-engineering). https://code.claude.com/docs/en/best-practices
Hand-off artifact format hint: machine-editable JSON status list resists accidental rewrites better than Markdown; agents may flip only `passes`. https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents

## 4. Scale awareness
One session when:
- The diff is describable in one sentence: skip the plan. https://code.claude.com/docs/en/best-practices
- Scope is clear, small, one acceptance command, <= ~9 files [FW] (no public file-count source), one layer-crossing slice, no migration with live data.
- No unknown to de-risk first, no breaking interface change needing expand/contract.
- Planning is for uncertainty, multi-file change, or unfamiliar code; otherwise it "adds overhead". https://code.claude.com/docs/en/best-practices
Split when: unknowns exist (spike/tracer first), data or interface migration, files exceed one context, acceptance commands are independent, or risk needs its own rollback point.
Appetite first: a time budget shapes the design, scope flexes; too-big ideas get narrowed then cut to a fitting piece. https://basecamp.com/shapeup/1.2-chapter-03
Cost of over-splitting:
- Each extra session repays a fixed handoff cost: re-reading, re-orienting, progress note; fresh sessions begin cold. https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Fakes: tiny sessions drift into horizontal "task disguised as story" slices that deliver no value alone. https://www.humanizingwork.com/the-humanizing-work-guide-to-splitting-user-stories/
- Interface drift between sessions that each assume the other's shape (mitigate: contracts first, spec-kit). https://github.com/github/spec-kit/blob/main/spec-driven.md
- Process overhead is real: in a 2025 RCT experienced devs on familiar repos were 19% slower with AI tools while believing they were faster; budget review and test time, base estimates on measured data. https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/ (small sample, early-2025 tools, METR marks it dated)
- Spec-kit itself caps ceremony: simplicity gate, max 3 projects, extra complexity needs written justification. https://github.com/github/spec-kit/blob/main/spec-driven.md
- Toggles added "to be safe" create carrying cost and combinatorial states. https://martinfowler.com/articles/feature-toggles.html
Proportional ladder (critic suggestion, derived, not sourced): trivial = 1 session no plan; small = 1 session plus acceptance command; medium = 2-4 vertical sessions; large = skeleton session plus slices, reviewed split.
Splitting techniques to propose when a session is too big: workflow steps, operations, business-rule variations, data variations, simple/complex, defer performance, spike last. https://www.humanizingwork.com/the-humanizing-work-guide-to-splitting-user-stories/ ; SPIDR (spikes, paths, interfaces, data, rules): https://www.mountaingoatsoftware.com/blog/five-simple-but-powerful-ways-to-split-user-stories
Meta-pattern: find the core complexity, list its sources of variation, reduce each to one complete slice for the first session. https://www.humanizingwork.com/the-humanizing-work-guide-to-splitting-user-stories/

## 5. Other grounding
- Progress per scope on a hill: uphill = unknowns, downhill = execution; a stuck dot signals blocker. Use as session status vocabulary. https://basecamp.com/shapeup/3.4-chapter-12
- Branch by abstraction for long changes inside trunk, no long-lived branch. https://trunkbaseddevelopment.com/
- Release toggles decouple deploy from release; keep static config in source control. https://martinfowler.com/articles/feature-toggles.html
- Compaction/clear: after two failed corrections, new session with a better prompt beats a long cluttered one; use `/clear` between unrelated tasks. https://code.claude.com/docs/en/best-practices
