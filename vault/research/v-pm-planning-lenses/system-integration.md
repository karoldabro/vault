# system-integration plan-critic: grounding research

Lens: the seams between independently deployed systems. Every claim cites a fetched source.

## 1. Plan-review questions (12)

1. Does every field/event a consumer reads have a named producer in the plan's contract table, and does every produced field have a consumer?
   - Source for "contract = what consumers actually use": https://docs.pact.io/
2. For each entity, which single system is the source of truth, and do any two systems write it?
   - Dual ownership causes lost updates: https://learn.microsoft.com/en-us/azure/architecture/patterns/saga (lost updates, dirty reads under no cross-service isolation)
3. Is each seam sync or async, and why? What does the caller do when the callee is slow or down (timeout, retry, degrade, queue)?
   - Fallacies: network is not dependable, latency is not zero: https://en.wikipedia.org/wiki/Fallacies_of_distributed_computing
4. Is any change breaking (remove/rename field, new required field, type change, new default, tighter validation)? If yes, is there an expand -> migrate -> contract sequence?
   - https://martinfowler.com/bliki/ParallelChange.html
   - Breaking-change list: https://google.aip.dev/180
5. Which client versions exist in the wild, and can each be force-updated? What minimum-version mechanism exists, and what does an old client do against the new server?
   - Old apps may not understand new responses; without a force-update policy old endpoints cannot be retired: https://careers.lendable.com/blog/articles/a-better-forced-update-approach (practitioner source, not a standard)
6. Does the plan state the rollout order across independently deployed units (server first, additive; clients later; contract step last)?
   - https://martinfowler.com/bliki/ParallelChange.html ; https://google.aip.dev/180 (old clients must keep working with newer servers within a major version)
7. Is every retried or redelivered operation idempotent? Where is the idempotency key generated, stored, and expired?
   - Stripe: client-generated key, server stores first result, mismatched params error: https://docs.stripe.com/api/idempotent_requests
   - Consumer-side dedupe with atomic marker + uniqueness constraint: https://learn.microsoft.com/en-us/azure/architecture/patterns/idempotent-consumer
8. Is "write DB and publish event/call other system" atomic? If not, what repairs the gap (outbox + idempotent consumers, reconciliation job)?
   - https://microservices.io/patterns/data/transactional-outbox.html (relay may publish twice, so consumers must be idempotent)
9. What is the consistency model across the seam (read-your-writes, eventual, stale cache) and what does the user see in the window? What is the compensation if step N of a multi-system flow fails?
   - Saga: local transactions + compensating transactions; pivot transaction; later steps must be retryable/idempotent: https://learn.microsoft.com/en-us/azure/architecture/patterns/saga
10. Does the plan assume event/webhook ordering or exactly-once delivery? It must not.
   - Stripe does not guarantee order; do not rely on `created` for ordering: https://docs.stripe.com/webhooks (section on event ordering)
   - Exactly-once across systems is impractical; use at-least-once + idempotent consumer: https://learn.microsoft.com/en-us/azure/architecture/patterns/idempotent-consumer
   - Ordering needs sequence/version data so stale messages are rejected: same page, "Account for message ordering"
11. For inbound webhooks/third-party callbacks: signature verified on raw body, 2xx returned before heavy work, retry window known, replay/manual resend safe?
   - https://docs.stripe.com/webhooks (verify signature, return 2xx quickly, automatic retries up to 3 days with exponential backoff)
12. How do the systems authenticate to each other, and do consumers tolerate additive provider changes (tolerant reader)? Is a third-party's model translated at one boundary (anti-corruption layer) rather than leaked into the domain?
   - https://martinfowler.com/bliki/TolerantReader.html
   - https://learn.microsoft.com/en-us/azure/architecture/patterns/anti-corruption-layer (translation layer; correlation IDs; validate input at the boundary)
   - Zalando: clients MUST accept compatible extensions (#108), enums open-ended (#112): https://opensource.zalando.com/restful-api-guidelines/
   - Auth threat analysis belongs to security-architect; this lens checks only that the plan names the mechanism and the failure mode (expired token, rotated secret).

## 2. Grounding: checks that confirm a defect at plan time

Mechanical (table diff or text search over the plan; no judgement needed)
- M1 Orphan consumer: a field in the consumer column with no row in the producer column of the contract table. Confirms question 1.
- M2 Orphan producer: a produced field with no consumer. Severity small unless it carries PII (hand to security-architect).
- M3 Dual writer: the same entity or column appears in the "writes" list of two systems. Confirms question 2 (lost updates: https://learn.microsoft.com/en-us/azure/architecture/patterns/saga).
- M4 Breaking change without sequence: plan diff contains remove/rename/retype/new-required/changed-default (list: https://google.aip.dev/180) and has no expand/migrate/contract steps or version marker. Confirms question 4.
- M5 Retry without key: plan says "retry", "redeliver", "at-least-once", "webhook" and a POST/side-effect endpoint, but no idempotency key or dedupe store named (https://docs.stripe.com/api/idempotent_requests).
- M6 Ordering assumption: plan text says "in order", "then update", "latest event wins" for events/webhooks with no sequence/version field (https://docs.stripe.com/webhooks).
- M7 Write-then-publish: two side effects (DB + broker/HTTP) in one step with no outbox, no reconciliation named (https://microservices.io/patterns/data/transactional-outbox.html).
- M8 Missing timeout: every cross-system call in the plan has a stated timeout and a stated failure behavior; absence is a defect (fallacy 1-2: https://en.wikipedia.org/wiki/Fallacies_of_distributed_computing).
- M9 Enum added to a response consumed by shipped clients with no "unknown value" handling stated (https://google.aip.dev/180 enum values; https://opensource.zalando.com/restful-api-guidelines/ #112).
- M10 Deploy-order check: for each changed seam, list producer and consumer deploy units and their release channels; flag any seam where the plan deploys the consumer first or both "together" while one unit is an app-store build.

Judgement (needs reading the plan and, often, the code)
- J1 Is the claimed "single source of truth" real (does a cache or copy get written back)?
- J2 Is the chosen consistency window acceptable to the user-visible flow?
- J3 Is an operation "naturally idempotent" (upsert by business key, absolute set, PUT) or does it need a key? Prefer natural idempotency: https://learn.microsoft.com/en-us/azure/architecture/patterns/idempotent-consumer
- J4 Is a compensating action actually possible (is there a pivot/irreversible step before it)? https://learn.microsoft.com/en-us/azure/architecture/patterns/saga
- J5 Can the mobile client be force-updated, and how many installs sit on old versions? Needs release-channel facts, not in the plan; ask or mark unverified.
- J6 Is a "compatible extension" really compatible (semantic changes count: https://google.aip.dev/180, "changing observable semantics").

Confirming a defect = quote the two plan lines that contradict (or the missing line) and name the seam. Do not assert a defect from a pattern name alone.

## 3. Severity examples

Ship-stopper (data loss, corruption, or an unrecoverable client at release)
- Server drops/renames a field that a shipped mobile build reads, and the app cannot be force-updated (M4 + J5).
- Two systems write the same entity with no ownership rule (M3).
- Payment/charge/notification endpoint retried by client or webhook with no idempotency key (M5; double charge example: https://learn.microsoft.com/en-us/azure/architecture/patterns/idempotent-consumer).
- A multi-system flow with an irreversible step before a step that can fail, and no compensation (J4: https://learn.microsoft.com/en-us/azure/architecture/patterns/saga).
- Consumer deployed before the producer that supplies a required field it reads (M1/M10).

Worth fixing (plan will work on the happy path, fails under ordinary faults)
- DB write plus event publish with no outbox or reconciliation (M7).
- Webhook handler does heavy work before returning 2xx; no signature verification step stated (https://docs.stripe.com/webhooks).
- No timeout/retry-limit/backoff policy on a cross-service call (M8).
- Event handler assumes order (M6).
- New enum value in a response with no client "unknown" handling (M9).
- No deprecation signal or usage monitoring before removing an endpoint (https://opensource.zalando.com/restful-api-guidelines/ #188-#189).

Small
- Orphan producer field (M2); inconsistent naming across systems; missing correlation ID in logs (https://learn.microsoft.com/en-us/azure/architecture/patterns/anti-corruption-layer); unstated idempotency-key retention window where operations are rare.

## 4. Scale awareness (2 small repos, one developer, deployed together)

Do not demand
- Schema registry, Pact Broker, or `can-i-deploy`: the broker is required for `can-i-deploy` (https://docs.pact.io/pact_broker/can_i_deploy); two repos deployed together can share one typed contract file or one integration test.
- Message bus, outbox relay, saga orchestrator, canonical data model: the canonical model pays off only as application count grows (EIP states 6 apps -> 30 vs 12 translators: https://www.enterpriseintegrationpatterns.com/patterns/messaging/CanonicalDataModel.html). Saga is for several services with separate databases (https://learn.microsoft.com/en-us/azure/architecture/patterns/saga).
- Semantic versioning of events, `Sunset` headers, partner consent (Zalando rules #185-#189 target external consumers: https://opensource.zalando.com/restful-api-guidelines/).
- Stripe-style date-pinned versions per account (https://stripe.com/blog/api-versioning): overkill without third-party API consumers.

Still demand, at any scale
- Idempotency key on retried side-effect calls and unique constraint or upsert on webhook/event handlers (cheap: https://learn.microsoft.com/en-us/azure/architecture/patterns/idempotent-consumer).
- A contract table with producer and consumer per field (a markdown table is enough).
- One owner per entity.
- Expand/contract whenever any consumer deploys separately from the producer: an installed mobile app or a third-party service counts as separate even if the developer owns it (J5).
- Timeouts and a defined failure behavior on third-party calls.
- Webhook signature verification and fast 2xx for third-party providers (https://docs.stripe.com/webhooks).

Test: ask "can the consumer be on a different version than the producer at any moment?" If no (atomic deploy, server-rendered admin), drop the compatibility demands. If yes (installed app, provider webhook), keep them.

## 5. Decorrelation (what this lens does NOT own)

- Internal structure of one system (layers, modules, class design, DB schema normalization inside one service): architect. This lens reads only the externally visible surface: payloads, events, endpoints, ownership, and sequencing across systems.
- Reuse of existing helpers/patterns inside one repo: codebase-fit. This lens only asks whether a seam already has a contract/version mechanism in the repo, and defers how to code it.
- Threat model (authz design, injection, secrets, PII exposure, abuse): security-architect. This lens asks only that a service-to-service auth mechanism is named and its failure handled; it does not grade the mechanism. Webhook signature verification is flagged here as a missing step, but its cryptographic adequacy is security-architect's.
- Performance/capacity sizing, observability stack choice, UX copy for error states: other lenses. This lens flags missing timeout and missing correlation ID only.
- Overlap rule: if a finding needs a view inside one system to be true, hand it over; if it needs two systems' plan lines to be true, keep it.

## Could not verify
- AWS Builders' Library "Timeouts, retries and backoff with jitter" (redirected, not fetched): retry amplification across layers is not cited; Microsoft/Stripe pages cover idempotency but not jitter.
- Pact docs front page does not mention Broker/can-i-deploy; the claim is sourced from the can_i_deploy page.
- Zalando rules were read from a truncated page (first 100k of 367k chars); rule numbers are as listed there, detail text of #229-#231 and #153 not read.
- Mobile-compat source is a single practitioner blog via search summary, not a standard; install-share thresholds for dropping old versions have no source.
- Microsoft API-design best-practices page was fetched but not mined; not cited.
