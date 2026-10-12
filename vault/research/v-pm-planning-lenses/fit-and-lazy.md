# Plan-critic grounding: codebase-fit and lazy-dev
Sources fetched 2026-10-12 unless marked (unverified). Evidence rule for both: a finding without a concrete check is advisory only.

## Source index (claims below cite these)
- S1 Google eng practices, reviewer "what to look for": https://google.github.io/eng-practices/review/reviewer/looking-for.html
- S2 Software Engineering at Google ch.9 (consistency, code search): https://abseil.io/resources/swe-book/html/ch09.html
- S3 McKinley, Choose Boring Technology: https://boringtechnology.club/
- S4 Fowler, Yagni: https://martinfowler.com/bliki/Yagni.html
- S5 Beck four rules (Fowler): https://martinfowler.com/bliki/BeckDesignRules.html
- S6 Metz, The Wrong Abstraction: https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction
- S7 Dodds, AHA: https://kentcdodds.com/blog/aha-programming
- S8 Fowler, MonolithFirst: https://martinfowler.com/bliki/MonolithFirst.html
- S9 Fowler, SacrificialArchitecture: https://martinfowler.com/bliki/SacrificialArchitecture.html
- S10 Spotify Golden Path: https://engineering.atspotify.com/2020/08/how-we-use-golden-paths-to-solve-fragmentation-in-our-software-ecosystem
- S11 Cox, Our Software Dependency Problem: https://research.swtch.com/deps
- S12 Spolsky, In Defense of NIH: https://www.joelonsoftware.com/2001/10/14/in-defense-of-not-invented-here-syndrome/
- S13 Spolsky, Things You Should Never Do I: https://www.joelonsoftware.com/2000/04/06/things-you-should-never-do-part-i/
- S14 Bezos 2015 shareholder letter (Type 1/2): https://www.sec.gov/Archives/edgar/data/1018724/000119312516530910/d168744dex991.htm
- S15 OpenSSF Scorecard checks: https://scorecard.dev/
- S16 Atwood, best code is no code: https://blog.codinghorror.com/the-best-code-is-no-code-at-all/
- S17 ADR definition: https://adr.github.io/
- S18 Rule of three (secondary, attributed to Don Roberts via Fowler's Refactoring): https://en.wikipedia.org/wiki/Rule_of_three_(computer_programming)

## A. codebase-fit persona
### Questions (Q) and grounding (G)
1. Q: Does the repo already contain a module/function doing this, and does the plan name it? S2: code search prevents duplicate code; authors look for existing utilities first. G: `grep -rn` for the verb/noun; cite file:line of the existing implementation.
2. Q: Does the plan add "yet another alternative" to an existing mechanism? S2: new code should solve a real problem, not provide another alternative. G: show the existing mechanism (file:line) and what it fails to do; absent that, reject.
3. Q: Does the change belong in this codebase, this layer and this module? S1: reviewers ask whether the change belongs here or in a library, and whether it integrates with the rest of the system. G: directory layout/import graph shows the layer that owns the concern.
4. Q: Is the second-way-of-doing-X risk present (second HTTP client, queue, config loader, logger, test runner)? S10: fragmentation makes "rumour-driven development"; a supported default path reduces duplicated effort. G: dependency manifest (package.json, pyproject, go.mod) already lists a library for X; grep imports.
5. Q: Does it honour recorded decisions? S17: an ADR captures a decision and rationale. G: grep the ADR dir for the topic; cite ADR id and the line the plan contradicts. A plan that overturns an ADR must say so and supersede it.
6. Q: Does it follow naming, file layout and error/logging conventions? S2: consistency aids comprehension and tooling (refactors by pattern). G: three sibling files show the convention; quote one.
7. Q: Are the tests written in the existing framework/fixture style, run by the existing command? S2 (consistency). G: test dir listing, CI config.
8. Q: Does the plan reuse existing data models, schemas, config keys, env vars instead of parallel ones? S5 rule 3 (no duplication of logic). G: grep config/schema for same concept under another name.
9. Q: Does it touch only the seams that need touching (no unrelated refactor)? S1: solve today's problem. G: file list in plan vs. files the requirement needs.
10. Q: Does it add a dependency or tool the repo's ecosystem already covers? S3: the first question is how to solve it without adding anything new. G: lockfile/manifest search.
11. Q: Is the migration/rollout path consistent with how the repo ships (scripts, hooks, release flow)? S2. G: existing release/migration scripts cited.
12. Q: Would a reader of the new code find the same pattern in neighbouring code? S5 rule 2 (reveals intention). G: side-by-side with the nearest analogue.

### Grounding grades
- Hard (blocks): existing implementation at file:line; manifest entry; ADR text contradicted; sibling files all using a different convention.
- Advisory: "feels inconsistent", no citation.

### When "follow the existing pattern" is wrong
- The pattern is the defect being fixed: the plan states so and names the migration scope; accept a new pattern only with a stated replacement of the old one. S3: if it replaces something, commit to retiring the old tool. Fowler's incremental-replacement logic applies, not a rewrite (S13).
- The existing pattern is a known accident (copy-paste lineage, one author) and not a decision: check git blame/ADR; no ADR and mixed usage means there is no "established" pattern. Cite counts: N files use A, M use B.
- Consistency vs. function: S2 states consistency "sometimes clashes with functionality"; reviewers should prefer simplicity/comprehension, not personal preference, and accept the author's choice when options are equal.
- Golden path is a default, not a ban: S10 says engineers may leave the path and lose support; the cost is what the plan must price.
- Legacy layer being retired: do not extend it (ADR or deprecation note is the evidence).

### Scale
- Tiny repo (single module, few files): conventions are implicit; check only sibling files and manifest; do not demand ADRs or layer diagrams. No ADR dir means skip Q5.
- Large system: layer boundaries, ownership and ADRs are authoritative; S2 shows consistency enforced by tooling and specialist reviewers; require code-search evidence across the whole repo, and check coupled repos/contracts.
- Heuristic: strictness scales with number of consumers of the touched surface (public API, shared lib > private script).

## B. lazy-dev persona
### Questions and grounding
1. Q: Can a config change or an existing feature do this? S3: "how would we solve the problem at hand without adding anything new?" G: framework/tool doc URL showing the setting; run it to confirm.
2. Q: Is there a package/SaaS covering the need? S16: every line adds bugs, upkeep and reading cost. G: name package, URL, version, licence, last release date, weekly downloads/stars, open-issue trend (see "Package evidence card").
3. Q: Does the plan build for a capability not in the stated requirement (presumptive feature)? S4: costs of build, delay, carry, repair. G: quote requirement lines; list plan items with no matching requirement.
4. Q: Is there a single implementation behind an interface/factory/plugin system? S5 rule 4 (fewest elements); S1 (more generic than needed). G: count implementers; one means delete the abstraction.
5. Q: Is an abstraction extracted from fewer than three real uses? S18 rule of three; S7 AHA; S6 duplication is cheaper than the wrong abstraction. G: list the call sites; <3 means inline.
6. Q: Does the plan add a new service/process/queue/datastore? S8: start monolith; microservice boundaries are hard to place early. S3: each new tech costs operation forever. G: show the existing process/DB that can host it (a table, a cron, a script).
7. Q: Does the plan spend more than a few "innovation tokens"? S3: a young company has about three. G: count novel techs in the plan not already in the repo.
8. Q: Is there a simpler first slice that meets the stated need? S9: build for now, expect to replace; "design for ~10X growth" (attributed to Jeff Dean). G: smaller plan, listed steps removed, and the need each removed step served.
9. Q: Is scale/perf/HA hardening specified without a measured need? S9; S4. G: current load numbers vs. plan's target; absence of numbers means advisory.
10. Q: Is custom infrastructure (own auth, scheduler, config system, templating) proposed? S12 inverse: outsource what is not core. G: name the commodity replacement.
11. Q: Does the plan keep optionality cheaply instead of building it? S14 (two-way doors move fast); S4 (yagni viable if code is easy to change). G: show the refactor needed later is small.
12. Q: Could deleting a step leave the stated acceptance criteria met? S5 rule 4. G: map each plan step to a criterion; unmapped steps are candidates.

### Package evidence card (required for a hard "use X" finding)
- Name, URL, exact version, licence (compatible with repo), last release date, release cadence, maintainers count, downloads/stars, open issues/CVEs (OSV), transitive dep count, size vs. need. S11 lists these questions: design, tests, bugs, maintenance, usage, security, licence, transitives. S15 automates part: Maintained, Vulnerabilities, License, Pinned-Dependencies, Dependency-Update-Tool, Signed-Releases checks.
- Framework-feature variant: doc URL for the exact version in the repo's lockfile.
- SaaS variant: pricing page, data-residency/ToS fit, export path (exit cost).
- Missing any field means the finding is advisory.

### When "just use a package" is wrong
- Core domain: S12 "If it's a core business function — do it yourself, no matter what." Own the differentiator.
- Abandoned or single-maintainer package, no release in a long period, open security issues. S11, S15 (Maintained, Vulnerabilities).
- Supply chain: S11 cites left-pad, event-stream, and unpatched Struts (Equifax). Transitive tree larger than the need.
- Licence incompatible or absent. S11, S15 (License).
- Package larger than the need: for a few lines, S11 suggests copying small pieces, or wrapping the dependency behind your own interface.
- Plan replaces a working in-repo module with a package: rewrite risk, S13.
- Package adds a second way of doing X already covered (conflicts with codebase-fit Q4/Q10).
- SaaS lock-in with no exit path; cost grows with usage.
- Lazy-dev must not trade the simple plan for a heavier one: S3 counts a new tool as an innovation token.

### Scale
- Tiny project/script: bias to stdlib, one file, no abstraction; a dependency for under ~30 lines fails S11 cost tests. S9: early, flexibility over HA. S5 rule 4 applies strongly.
- Large system: build-vs-buy gets formal (security review, vendor risk, ownership); abstractions pay off at many callers; S18 threshold of three is a floor, not a mandate; shared-library extraction is justified by counted consumers. S8 caveat: splitting later works only if the monolith was modular.

## C. Tension with a future-scope critic
- Sort each item by door type: S14 Type 2 (reversible) decide fast and defer; Type 1 (hard to reverse) deliberate now. Data formats, public APIs, schema/IDs, security boundaries, published contracts are typical one-way doors; internal helpers, libraries, folder layout are two-way.
- Defer if cost of adding later is about equal to cost now: S4 says to imagine the later refactor; often it is small. YAGNI holds only if the code is easy to change (S4); keep tests and refactorability intact (S4: Yagni does not justify neglecting code health).
- Do now if cheap and adds no complexity: S4 "when there's no added complexity" YAGNI does not apply; low-cost steps that ease later change are worth taking (lookup tables example).
- Do now if expensive later: migration of persisted data, public contract changes, retrofitting auth/audit/idempotency, naming of identifiers that leak to users. Evidence: the later-change cost estimate (files, consumers, data volume).
- MVP-dropped concerns: record them as a named deferral with trigger condition (metric/date), not as silence. S9 suggests designing for replaceability: good module boundaries (S9), monolith kept modular (S8).
- Resolution rule for the review: lazy-dev wins on capability, future-scope wins only on one-way doors or items with a quantified retrofit cost. Both must cite evidence; a bare "we might need" or bare "YAGNI" is advisory.
- S4 adds a bias warning: YAGNI failures are rarer than successes but more memorable (availability bias); apply to both critics.

## Not verified
- Fowler's Refactoring text for Rule of Three: only secondary sources (S18), including the Don Roberts attribution.
- Jeff Dean "10X/100X" quote is as reported by S9, not checked at origin.
- Scorecard "Maintained" thresholds not retrieved (S15 lists checks only); "~30 lines" copy-vs-depend cutoff above is my heuristic, not sourced.
- No InnerSource/reuse empirical study, no formal build-vs-buy framework (e.g. Wardley) fetched; none cited. Brooks "second-system effect" not fetched.
- S2 and S10 summaries come from a small-model fetch; wording of quotes is paraphrased except where quoted.
