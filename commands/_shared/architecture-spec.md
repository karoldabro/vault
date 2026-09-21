# Shared module — the architecture spec

Binding on the PROPOSE step of `/v-team` and on `bin/gate.sh arch`. A plan `plans/<slug>.md` has a
sibling `plans/<slug>.arch.md` that states the structure to build. `bin/gate.sh arch` checks it before
any work item is written. Worked examples: `tests/fixtures/arch/code-complete.arch.md` and
`tests/fixtures/arch/harness-complete.arch.md`.

## Call and output

`bin/gate.sh arch <file> [--repo <root>]`. `<file>` is a spec or a plan. `all` accepts `--repo` and
passes it on. `--repo` defaults to the working directory. Success prints `arch: ok <spec path>` to
stdout. Each defect prints `REFUSED arch <spec path>: <problem> [<row>]` to stderr. `<row>` is the first
cell of the row, except Interfaces rows (`interface.method`) and Data model column rows
(`table.column`).

## Order of checks

1. `--repo` is not a directory, `<file>` is unreadable, or an existing `VAULT.md` is unreadable: exit 2.
2. Work on a copy with CR removed.
3. `type:` is not `arch-spec` or `plan`: refuse and stop. The first `type:` key wins, trailing space is
   ignored, quotes are not stripped.
4. `arch_profile` in the repo's `VAULT.md` is read (see Profile source). An invalid value: refuse, stop.
5. A plan resolves through `arch_spec`, relative to the plan's folder. Empty or absent: refuse when the
   repo has a profile, else exit 0 with no output. A named file that does not exist: refuse, stop.
6. Spec frontmatter is closed by a second `---`; `profile` is `code` or `harness`; `plan` is non-empty;
   no `status` key. When the
   repo has a profile, the spec's `profile` equals it. The text holds no `{{` and no `path/to/`, which
   are the placeholders of the two templates.
7. Structure: fenced blocks (lines starting with three backticks, at column 0) are removed after the
   Data flow mermaid check; an unclosed fence is a defect; a `## ` heading that appears twice is a
   defect.
8. Each required section of the spec's profile is checked. Extra sections are allowed. Steps 6 to 8
   print every defect, then exit 1.

## Profile source

`arch_profile: code|harness|none` in the repo's `VAULT.md`. The first `arch_profile:` line wins; a
trailing ` # comment` is removed. Absent key or absent file means `none`. Empty, quoted or any other
value is invalid. A repo with a profile refuses a plan that names no spec. A repo with `none` still
validates a spec that is named.

## Sections

| profile | section | form |
|---------|---------|------|
| code | Data model | table `table column type null key index references`, or only `n/a: <reason>` |
| code | Data flow | one ```` ```mermaid ```` block |
| code | Interfaces | table `interface method params returns throws layer` |
| code | Layers & placement | table `logic layer file` |
| code | Reuse map | table `need existing symbol decision reason` |
| code | Size budgets | table `path max lines`, optional `max method lines` |
| harness | File tree | one fenced block, not empty |
| harness | Files | table `path new purpose loaded` |
| harness | Data flow, Interfaces, Reuse map, Size budgets | as in the code profile |
| harness | Load order | table `trigger loads tokens-max` |
| harness | Config points | table `key file default`, or only `n/a: <reason>` |

One table per section, read by header name, so column order does not matter. A row with a different
cell count than its header is a defect. Sections are not cross-checked against each other, and the
spec's `plan:` value is not compared to the plan's slug.

## Rules per section

- Data model: names match `^[A-Za-z_][A-Za-z0-9_]*$`. `key` is `PK`, `FK`, `UQ` or empty. `null` is
  `yes` or `no`. Each table has at least one `PK` row; two are accepted. A row with `references`
  (`table.column`, existence not checked) has an `index` that is neither empty nor `-`. A row with `key`
  `FK` names `references`. `n/a` beside a table is a defect; an empty reason is a defect.
- Interfaces: `params` is `-` (trimmed) or comma-separated `name: type`, split at bracket depth 0 over
  `<>`, `[]` and `()`. The name matches the identifier pattern, the first colon separates it from a
  non-empty type, and an `=` at depth 0, an empty param, a trailing comma or unbalanced brackets is a
  defect. The arrows `->` and `=>` are neither brackets nor defaults. A union writes `\|`.
- Reuse map: `decision` is exactly `reuse`, `extend` or `new`. `reuse` and `extend` name a symbol. `new`
  states in `reason` what was searched.
- Files: `new` is `yes` or `no`; `loaded` is `always`, `on-demand` or `never-by-agent`. A `new: no` path
  is relative to `--repo`, has no `..`, and exists (`-e`).
- Size budgets: each number is an integer from 1 to 100000.

## Messages

The table lists the defects a session most often meets and fixes their wording. Every other defect
prints one sentence that names the defect, with the row when there is one.

| defect | `<problem>` text | `<row>` |
|--------|------------------|---------|
| unedited template | spec still holds a template placeholder | |
| wrong type | frontmatter needs type: arch-spec | |
| invalid profile value | arch_profile has an invalid value | value |
| plan without spec | plan names no arch_spec while repo declares arch_profile `<p>` | |
| spec file missing | arch_spec names a file that does not exist | path |
| profile clash | profile differs from repo profile, or is missing or invalid | |
| missing section | missing section `<heading>` | |
| missing column | section `<heading>` lacks column `<name>` | |
| table without key | table has no primary key | table |
| untyped param | param `<name>` has no type | interface.method |
| foreign key without index | foreign key has no index | table.column |
| new reuse row without reason | new reuse row has no reason | need |
| absent path | path does not exist | path |
