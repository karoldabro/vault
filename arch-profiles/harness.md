---
type: arch-spec
profile: harness
plan: {{plan-slug}}
tags: [arch-spec]
---

# {{plan-slug}} — architecture spec

<!-- Contract: commands/_shared/architecture-spec.md. `bin/gate.sh arch` refuses a spec that breaks it.
     For work whose product is instructions, commands, configuration or documents. Save this file
     beside the plan as plans/{{plan-slug}}.arch.md. Replace every row; delete none of the sections.
     Change: the plan slug and every file, interface, load and reuse row. Delete this comment: the gate
     refuses a spec that still holds a double brace or a `path/to/` value. -->

## File tree

```text
path/to/existing-file.ext       existing, what changes
path/to/new-file.ext            new
```

## Files

<!-- One row per file this work touches. `new: no` names a path that exists under the repo root.
     `loaded` is `always` (read every session), `on-demand` (read when a trigger fires) or
     `never-by-agent` (tests, fixtures, generated output). -->

| path | new | purpose | loaded |
|------|-----|---------|--------|
| path/to/existing-file.ext | no | one sentence: the single thing this file is for | on-demand |
| path/to/new-file.ext | yes | one sentence: the single thing this file is for | on-demand |

## Data flow

<!-- How control and data move between the files above. Every arrow names what crosses it. -->

```mermaid
flowchart LR
    A["command step (a)"] -->|"template: path"| B["template file"]
    B -->|"draft: text"| C["output file"]
```

## Interfaces

<!-- The surface another file or agent calls: a command, a script subcommand, a function. -->

| interface | method | params | returns | throws | layer |
|-----------|--------|--------|---------|--------|-------|
| script.sh | subcommand | file: path, flag: string | exit code | - | cli |

## Load order

| trigger | loads | tokens-max |
|---------|-------|------------|
| step (a) starts | path/to/new-file.ext | 1500 |

## Reuse map

<!-- `reuse` and `extend` name an existing symbol or file by path. `new` states in `reason` what was
     searched before deciding nothing exists. -->

| need | existing symbol | decision | reason |
|------|-----------------|----------|--------|
| parse a table | path/to/script.sh function_name | reuse | already handles the format |

## Size budgets

| path | max lines |
|------|-----------|
| path/to/new-file.ext | 150 |

## Config points

<!-- Every value a repo can change without editing the files above. `n/a: <reason>` when none. -->

| key | file | default |
|-----|------|---------|
| setting_name | VAULT.md | none |
