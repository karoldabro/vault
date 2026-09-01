---
type: record
project: vault
slug: 2026-09-01-1000-vcr-delivery-and-coverage.trail
plan: 2026-09-01-1000-vcr-delivery-and-coverage.md
tags: [trail, v-cr]
---

# Review trail — vcr-delivery-and-coverage

Process record for `2026-09-01-1000-vcr-delivery-and-coverage.md`. Findings, the reversed diagnosis,
and the options that were rejected.

## The diagnosis reversed mid-review

The draft blamed scope per agent: a 523-file diff handed whole to five critics. The forge contradicted
it. `karoldabro/api.givore.com#190` carries 9 inline comments and **zero** issue comments; the summary
comment id recorded in the session (`4881350226`) returns 404; all 9 review wrappers have empty bodies.

The summary is the only carrier of the verdict, the coverage line, the severity counts, the test-posture
line and the over-cap note (`commands/v-cr/steps/03-review.md:58-66`). Its absence means the operator
received 9 bare inline comments and nothing framing them — which is the reported symptom, reachable
without any review-scope defect.

Two posts are missing against the session's claim of 10 inline plus a summary; the tenth is fingerprint
`a6476f225b9f16bb` on the `revoke_notification_write_permissions` migration. The operator confirms the
summary never reached them, so deletion is excluded. `--unpost` is excluded too: it deletes by marker
and the 9 fingerprinted comments survive.

## Why commit efcd7e8 did not fix this

`efcd7e8` (2026-06-19) made the panel spawn mandatory and required a coverage line and a test-posture
line. Both later runs postdate it and neither shows the effect. The commit instrumented the ephemeral
surfaces — the posted comment body and the step's terminal output — and left the durable record
(`05-capture.md`) and the write boundary (`04-post.md`) uninstrumented. A post that never lands takes
the whole instrument with it.

## Evidence base and its limits

Three run records exist. They do not support the scope conclusion the draft drew.

| run | scope | outcome | why it does not settle the question |
|---|---|---|---|
| digitally-core PR #3237 | 21 files, +2,179 | 6 findings incl. a cross-tenant IDOR | Within the guard threshold, so it tests nothing about large diffs |
| api.givore.com PR #190 | 523 files, 50,817 lines | 9 delivered; 3 MAJOR posted, 6 low-severity dropped at the cap | The cap dropped only low-severity items, so it hid no MAJOR |
| givore_app release/1.12.0 | 442 files, ~49.5k lines | 0 MAJOR, 6 MINOR | It is a `/v-team` run, so `03-review.md` §3.4 was never in its path, and it deduped against ~60 findings from five prior night-shift passes — a residual yield, not a first-pass yield |

No run records how many files entered model context, so no evidence distinguishes reading few files from
commenting on few files. That gap is why work items 1–6 come before any redesign.

## Withdrawn claims

**"§2.4 loads all indications wholesale into every critic."** Wrong. The step reads "decisions (ADRs),
indications, the feature dossier for the touched area" — retrieval-scoped language. Two PR #190
comments cite project decisions (`config/ads.php:16` cites ADR-232; `config/resources.php:14` cites
deny-by-default authz), so vault rules did reach the critics. The real defect is narrower: §2.4 names
`indications` with no retrieval rule, so each run invents its own subsetting and records none of it.

**"Branch type is controlled for."** It is not. Both low-yield runs review release aggregations of
already-reviewed code; the high-yield run reviews a fresh feature branch with an empty suppression set.
Branch type predicts the entire yield difference with no coverage defect required.

## Rejected options

**Give each fleet agent only its unit's slice of the diff.** Rejected. PR #3237's highest-severity
finding joined `RouteServiceProvider.php:127`, the `Import` model's **absent** global customer scope,
the `customer_safe_tables` config, and three new controller methods. The absent scope is a negative fact
about unchanged code and appears in no diff. Diff-only agents cannot reach it. Fleet agents keep full
base-repo read access.

**`VCR_MAX_UNITS` as the fleet knob.** Rejected. `VCR_MAX_TOKENS` (~200k) already exists at
`commands/v-cr/steps/03-review.md:36`. Two caps with no precedence rule is the defect §3.2 already has.
At 12 units the fleet covers 18.9% of PR #190's changed lines with 24 agents; full coverage needs ~128.

**`category:` in every indication's frontmatter.** Rejected. 415 body files against 7 `_index.md` files,
and the index already carries a `scope` column. Surface filtering alone cuts the givore index from 223
rows / 16,813 words to 112 rows / ~8,700 words without touching a single body file. Per-lens categories
become worthwhile only once a fleet makes per-agent rule loading the binding cost.

**A `/v-cr`-owned partition step file.** Rejected as premature, and misplaced if built.
`commands/v-team/steps/04-execute-loop.md:51` has the same unbounded-scope problem and its own
>15-file trigger, so partition logic belongs in `commands/_shared/` alongside `critic-panel.md`.

**`/v-cr` opening pull requests against the framework repo.** Rejected on the threat model.
`indications/` is a privileged channel with two consumers: `02-gather.md:43` feeds it to critics as
unfenced rules, and `sandbox.md:33-35` accepts it as a source of `install:`/`test:` commands.
`lib/cr-sandbox.sh:116` ranks an indication **above** every other recipe source, and
`cr_is_envelope_key` strips network, capability, mount and env keys but not `install` or `test`. A
merged poisoned rule in `karoldabro/vault` would steer every `/v-cr`, `/v-work` and `/v-team` run in
every repo. `/v-cr` writes a local proposal file; the operator opens the PR from a separate session.

**Restricting learning to locally-authored comments.** Rejected as the wrong variable. An operator
pasting a forge comment into a local prompt reintroduces the identical string with identical
privileges. Provenance stamping plus the recipe deny-list is required either way, and with it, forge
comments from write-holders are as safe as local ones.

## Open at close

- Why the PR #190 summary post failed is unknown. A run that hit an execution limit mid-post is the
  leading candidate — claude-mem observation 22377 records exactly that failure on another project's
  `/v-cr` cron. The read-back makes the next occurrence loud rather than silent.
- Whether `/v-cr` under-reads large diffs is unmeasured. The re-run named in the plan's Sequencing
  section is the test.
