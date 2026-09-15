# Reviewer packs for /v-team

`/v-team` reviews a plan and a diff with a panel of reviewers. A **pack** decides who sits on that
panel. Packs live in `../personas/`.

## The packs

| Pack | File | Use it for |
|---|---|---|
| `api-laravel` | `../personas/api-laravel.md` | A PHP or Laravel backend |
| `nuxt` | `../personas/nuxt.md` | A Nuxt or Vue frontend |
| `flutter` | `../personas/flutter.md` | A Flutter app |
| `marketing` | `../personas/marketing.md` | Campaigns, positioning, copy |
| `sales` | `../personas/sales.md` | Outreach, proposals, pipeline |
| `seo` | `../personas/seo.md` | Search and content work |
| `support` | `../personas/support.md` | Customer replies and help content |
| `business` | `../personas/business.md` | Strategy and operating decisions |
| `startup-eval` | `../personas/startup-eval.md` | Judging an idea or a venture |

## Reviewers several packs share

They live once, in `../personas/_shared/`, and each pack pulls in the ones it needs.

| Reviewer | What it argues about |
|---|---|
| `correctness`, `quality`, `performance`, `security` | The usual four, on any code change |
| `consumer` | Whoever has to use the thing afterwards |
| `skeptic` | The claim you have not proved yet |
| `_shared/testing/` | Tests an AI wrote: weak assertions, fakes, flakiness, missed edges |
| `_shared/business/` | Numbers used as evidence |

## How a repo picks its pack

Set one key in the repo's `VAULT.md`:

```
project_type: api-laravel
```

Or name the pack directly, which also accepts a list:

```
personas:
  use: [sales, marketing]
```

With a list, the first entry leads. **Do not mix a code pack with a business pack in one list.** They
count and cap their reviewers differently, so the panel would be half-selected by each set of rules.
A repo that does both runs a separate session per kind of work.

With neither key, `/v-team` looks for `composer.json`, `nuxt.config.ts` or `pubspec.yaml` and picks
the matching code pack. The business packs have no such marker, so you must ask for them by name. If
nothing matches, `/v-team` warns once and reviews with a general panel instead of stopping.

Two more keys: `personas.add` seats a reviewer you wrote yourself, and `personas.skip` drops one by
name.

`../personas/_resolution.md` holds the full selection rules: how many reviewers get seated, which are
always in, and how a shared reviewer behaves when two packs both want it.
