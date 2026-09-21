---
type: arch-spec
profile: harness
plan: fixture
tags: [arch-spec]
---

# Gate arch check — architecture spec

Worked example of the harness profile. `commands/_shared/architecture-spec.md` owns the rules.

## File tree

```text
bin/gate.sh                       existing, gains the arch subcommand
bin/doc-lint.sh                   existing, gains the arch-spec type
checks/arch-SC-9.sh               new
```

## Files

| path | new | purpose | loaded |
|------|-----|---------|--------|
| bin/gate.sh | no | refuses a session that skipped a required step | on-demand |
| bin/doc-lint.sh | no | checks that a document is well formed | on-demand |
| checks/arch-SC-9.sh | yes | decides one success criterion | on-demand |

## Data flow

```mermaid
flowchart LR
    A["v-team step (g)"] -->|"spec: path, repo: path"| B["gate.sh arch"]
    B -->|"exit code, refusal text"| A
```

## Interfaces

| interface | method | params | returns | throws | layer |
|-----------|--------|--------|---------|--------|-------|
| gate.sh | arch | spec: path, repo: path | exit code | - | cli |

## Load order

| trigger | loads | tokens-max |
|---------|-------|------------|
| PROPOSE finalise | bin/gate.sh | 0 |

## Reuse map

| need | existing symbol | decision | reason |
|------|-----------------|----------|--------|
| table parsing | bin/gate.sh table_rows | reuse | already splits cells |

## Size budgets

| path | max lines |
|------|-----------|
| bin/gate.sh | 900 |

## Config points

| key | file | default |
|-----|------|---------|
| arch_profile | VAULT.md | none |
