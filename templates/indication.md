---
type: indication
project: {{project}}
slug: {{slug}}
scope: repo
probe:                 # optional: id of a row in probes/registry.tsv that checks this rule
probe_count:           # optional: written by /v-rule, `<n> of <files> files at <sha>` measured when the rule was accepted
source:                # optional: `pr-comment` when the rule came from a review comment
tags: [indication]
---

# {{slug}}

## Rule
<!-- The convention, stated imperatively. What to always / never do. One rule per doc. -->

## Rationale
<!-- Why this rule exists. What breaks or costs when it's violated. -->

## Examples
<!-- Do: concrete code / path that follows the rule.
     Don't: the anti-pattern it replaces. -->

## Applies-to
<!-- Paths, layers, or file globs this rule governs (e.g. app/Http/**, *.test.ts, queue jobs). -->
