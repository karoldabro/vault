# future-scope critic: grounding

Source status: [P] = primary page returned by search; [S] = secondary/vendor summary. Figures from [S] are directional only.

## 1. Plan-review questions
1. Which decisions in this plan are one-way doors (public API shape, persisted schema, IDs, event names, data location)? Does each have a stated owner and rationale? Two-way doors need no scrutiny. https://fs.blog/2018/04/reversible-irreversible-decisions/ [S quoting Bezos 2015 letter]
2. What is the earliest point at which deferring this decision removes an option, and does the plan decide before that point and not earlier? https://blog.codinghorror.com/the-last-responsible-moment/ [S on Poppendieck]
3. Where will the next likely change land (a second provider, a second output format, a second tenant), and does it land as an added module or as an edit to existing code? https://blog.cleancoder.com/uncle-bob/2014/05/12/TheOpenClosedPrinciple.html [P]
4. What automated check (test, lint, CI rule) will fail if the property the plan relies on (latency budget, dependency direction, schema compatibility) regresses? https://www.thoughtworks.com/en-us/insights/books/building-evolutionaryarchitectures-second-edition [P, fitness functions]
5. Does every persisted record carry a schema/format version, and how is an old record read after the format changes (expand, migrate, contract)? https://www.martinfowler.com/bliki/ParallelChange.html [P]
6. Does every write have a retention rule, a deletion path and a named owner? https://advisera.com/eugdpracademy/gdpr/data-protection-by-design-and-by-default/ [S, GDPR Art. 25]
7. Can a retried or duplicated request repeat a side effect (charge, send, create)? Where is the idempotency key? https://docs.stripe.com/api/idempotent_requests [P]
8. When this fails at 3 a.m., which log line, metric or trace tells the operator what happened? Do the four golden signals (latency, traffic, errors, saturation) exist for the new path? https://sre.google/sre-book/monitoring-distributed-systems/ [not fetched this session; golden signals confirmed via https://clickhouse.com/resources/engineering/golden-signals S]
9. Does the plan log structured fields with a correlation/trace id, and reuse the repo's existing logger and telemetry API instead of a new one? https://opentelemetry.io/pt/docs/concepts/instrumentation/libraries/index.md [P]
10. Are values that differ per environment or change without a release (URLs, limits, thresholds, credentials) read from config, not literals? https://12factor.net/config (factor III; page not fetched, heading confirmed via search of https://12factor.net/)
11. Which user-facing events must be recorded now because they cannot be reconstructed later (activation, conversion, failure)? https://thoughtbot.com/playbook/measuring/instrumentation [S]
12. For each cheap seam the plan adds, which named, scheduled second consumer exists? A seam without one is speculative. https://www.martinfowler.com/bliki/Yagni.html [P]

## 2. Commonly dropped from MVP, expensive to retrofit (ranked)
Rank = irreversibility first, then breadth of code touched.
1. Data retention/deletion + personal-data inventory. Retrofit cost: data already spread across stores, backups, logs and analytics; no record of where personal data went. GDPR Art. 25(2) and Recital 39 require limiting storage period by default and apply to existing systems. https://advisera.com/eugdpracademy/gdpr/data-protection-by-design-and-by-default/ [S]; https://www.activemind.legal/legislation/gdpr/article-25/ [S]
2. Schema/format versioning and migration path. Retrofit cost: unversioned records cannot be told apart, so the first format change needs a guess or a full rewrite. The usual failure is skipping the contract step, leaving two parallel columns. https://www.martinfowler.com/bliki/ParallelChange.html [P]; https://cdn.jsdelivr.net/npm/codingbuddy-rules@5.6.3/.ai-rules/skills/database-migration/expand-contract-patterns.md [S]
3. Idempotency keys on side-effecting writes. Retrofit cost: adding a key changes the client contract and needs stored request state; duplicates already happened cannot be undone. https://brandur.org/idempotency-keys [P]; https://docs.stripe.com/api/idempotent_requests [P]
4. Audit trail (who, what, when) for state changes and security events. Retrofit cost: history before the change does not exist and cannot be recreated. https://wiki.owasp.org/index.php/Logging_issues [P, archived]
5. Product analytics events. Retrofit cost: events not collected have no history; vendor backfill only works where raw capture already ran. https://thoughtbot.com/playbook/measuring/instrumentation [S]; https://www.trackingplan.com/changelog/custom-events-backfilling [S]
6. Structured logging with correlation id. Retrofit cost: every call site changes; one guide notes retrofit after an incident is painful and incomplete. https://www.designgurus.io/answers/detail/structured-logging-done-right-best-practices-and-interview-guide [S]; 12factor logs as event stream: https://12factor.net/logs [P]
7. Metrics/tracing on the golden signals, via a vendor-neutral API. Retrofit cost: proprietary SDK instrumentation must be rewritten to switch vendors. https://oneuptime.com/blog/post/2026-02-06-opentelemetry-vendor-neutral-instrumentation/view [S]; https://opentelemetry.io/pt/docs/concepts/instrumentation/libraries/index.md [P]
8. i18n-ready strings (keys, no concatenation, locale-aware dates). Retrofit cost: hundreds of hardcoded strings, layouts sized for one language; vendor estimate 1-2 weeks greenfield vs 4-8 weeks retrofit. https://simplelocalize.io/blog/posts/why-retrofitting-i18n-is-expensive/ [S, vendor estimates]
9. Accessibility. Retrofit cost: markup and interaction patterns change in every component; direction ("retrofit costs more") is consistent, multipliers are unsourced. https://lists.w3.org/Archives/Public/w3c-wai-eo/2003OctDec/0047.html [S, mailing list]. For small static sites the retrofit cost can be minimal (same thread).
10. Config over literals and feature flags. Retrofit cost: moderate; a flag for a risky release is cheap now, but release toggles must be removed after rollout. https://www.infoq.com/news/2016/02/featuretoggles/ [S on Hodgson/Fowler toggle categories]
11. Error reporting, tests, docs. Retrofit cost grows with code volume; Fowler's design-stamina argument says skipping them pays off only briefly. https://martinfowler.com/bliki/DesignStaminaHypothesis.html [P URL; content known via secondary https://www.sandordargo.com/blog/2018/03/06/design-stamina-hipothesis]
12. Rate limiting and backup/restore: not researched with a cited retrofit-cost source. Treat as UNVERIFIED; ask only when the plan exposes a public endpoint or holds data that cannot be rebuilt.

## 3. Discipline against over-engineering
Counter-argument (YAGNI wins): a presumptive feature carries build, delay, carry and repair costs, and Fowler cites Kohavi et al.: about two thirds of ideas do not improve their target metric. https://www.martinfowler.com/bliki/Yagni.html [P]
YAGNI does not apply to making code easier to change; it applies to building the speculative feature itself (same page).
Reversibility: spend deliberation only on one-way doors; Bezos warns that treating two-way doors as one-way produces slowness and less experimentation. https://fs.blog/2018/04/reversible-irreversible-decisions/ [S]
Timing: decide at the last responsible moment, the point where waiting removes an option; deciding earlier risks throwaway work, deciding later happens by default. https://blog.codinghorror.com/the-last-responsible-moment/ [S]

Decision rule (synthesis from the sources above, the critic's own wording):
- Demand it now only if ALL hold:
  a. Irreversible or lossy to defer: the data, history or public contract it protects cannot be created later (retention rule, version field, audit row, event emission, idempotency key, public identifier).
  b. Cost now is a field, a log line, a function call or an interface with one real implementation: under roughly one hour of work, no new service, no new dependency.
  c. A named, plausible consumer exists within the product horizon (a legal duty, an operator need, a roadmap item), not "someone might".
- Defer if the change is a two-way door: abstraction layers, plugin systems, multi-provider adapters, generic frameworks, dashboards, alert tuning, translations themselves (only the externalisation is cheap), caching, sharding.
- Cheap seam: a column, an emitted event, a log field, a config value, an interface with one implementation at an existing module boundary. Speculative generality: a second implementation, a configuration option nobody sets, a hook with no caller.
- Seam test: delete the seam; if the later retrofit is a local edit, it was not needed now; if it touches stored data or external callers, it was.
- Output format for a finding: concern, one-way/two-way, cost now, cost later, consumer. Findings that cannot fill all five fields get dropped.

## 4. Grounding: evidence that confirms a finding
Confirmed (cite the artifact):
- Plan writes records (table, file, topic, vault doc) and no retention/deletion line exists: quote the plan's write step and grep the plan for retention/ttl/delete.
- Plan changes a persisted format, ID scheme or public API and names no version field or migration/rollback: quote both the change and the missing step.
- Repo already has a logger, metrics client, analytics client, flag or config loader the plan bypasses: path from `grep -rn` over the repo (e.g. `src/lib/logger.*`), plus the plan line that adds a parallel one.
- Plan adds a side-effecting call (payment, email, webhook, external write) that can be retried, with no dedupe key.
- Fitness function absent: plan states a non-functional target (latency, size, dependency rule) with no check that enforces it.
- External source: the specific claim, a URL from this file, and its status ([P] or [S]).
Not confirmed (drop): "might need i18n someday", "should be pluggable", "add metrics" with no consumer, any figure from [S] used as proof of a multiplier (IBM 1x/6.5x/15x/100x and "10-100x" accessibility numbers are unverified).

## 5. Scale awareness: do NOT demand
- Prototype/throwaway (lifetime under about a month, no real users, no personal data): demand nothing beyond not destroying existing data; mark all items "defer".
- Small internal tool or single-maintainer repo: no tracing, no metrics backend, no feature-flag system, no i18n, no rate limiting, no analytics events; stdout structured log lines suffice (12factor logs: https://12factor.net/logs).
- No personal data: skip retention and erasure design.
- No external callers: skip API versioning and idempotency keys unless a retry loop exists.
- Never demand: plugin architecture, microservice split, new infrastructure, an abstraction with one implementation and no second consumer, a vendor observability platform, 100% coverage targets.
- Evolutionary architecture accepts incremental change guarded by fitness functions as an alternative to up-front prediction. https://www.thoughtworks.com/en-us/insights/books/building-evolutionaryarchitectures-second-edition [P]
- Rule of proportion: the number of findings the critic raises scales with the one-way doors in the plan; zero findings is a valid result.
