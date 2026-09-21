# Shared module — the architecture spec

Binding on the PROPOSE step of `/v-team` and on `bin/gate.sh arch`. A plan `plans/<slug>.md` has a
sibling `plans/<slug>.arch.md` that states the structure to build. `bin/gate.sh arch` checks it before
any work item is written. Worked examples: `tests/fixtures/arch/code-complete.arch.md` and
`tests/fixtures/arch/harness-complete.arch.md`.

The sections a spec needs depend on the kind of project, so they are data. A **profile** is two files
named `<name>.tsv` and `<name>.md`. The session loads only the profile its repo names.

## Profiles

`arch_profile: <name>|none` in the repo's `VAULT.md`. The gate looks for `arch-profiles/<name>.tsv` in
the repo first and then in the framework, so a repo adds a project type by adding two files there and
changes no framework code. The name matches `^[a-z][a-z0-9-]*$`. The first `arch_profile:` line wins and
a trailing ` # comment` is removed. Absent key or absent file means `none`. A value that names no profile
file, an empty value and a quoted value are invalid.

A repo with a profile refuses a plan that names no spec. A repo with `none` still validates a spec that
is named. Shipped profiles: `code` (data model, interfaces, layers) and `harness` (file tree, load
order, size budgets, config points).

`<name>.md` is the starting text of a spec. `<name>.tsv` lists the sections in order, one per line, tab
separated, `#` for comments:

`section` `kind` `columns` `rules`

- `kind`: `table`, `table,na` (the section may hold only `n/a: <reason>`), `fence:mermaid` (one mermaid
  block), or `fence:any` (one non-empty fenced block).
- `columns`: space-separated `name:validator`. An underscore in a name stands for a space, and a `?`
  after the name makes the column optional. Columns are read by header name, so order does not matter.
- `rules`: space-separated names from the rule library below.

Validators: `any`, `nonempty`, `ident` (`^[A-Za-z_][A-Za-z0-9_]*$`), `enum(a|b|c)` (an empty last
alternative allows an empty cell), `int(min-max)`.

## Rule library

A rule reads columns by name, so a profile uses it only in a section that has them.

- `pk-per-table` (`table`, `key`): each table has at least one `PK` row; two are accepted.
- `fk-index` (`references`, `index`, `key`): a row with `references` (`table.column`, existence not
  checked) has an `index` that is neither empty nor `-`, and a row with `key` `FK` names `references`.
- `params-typed` (`params`): `-` (trimmed) or comma-separated `name: type`, split at bracket depth 0
  over `<>`, `[]` and `()`. The name matches the identifier pattern and the first colon separates it from
  a non-empty type. An `=` at depth 0, an empty param, a trailing comma or unbalanced brackets is a
  defect. The arrows `->` and `=>` are neither brackets nor defaults. A union writes `\|`.
- `reuse-decision` (`decision`, `existing symbol`, `reason`): `reuse` and `extend` name a symbol, and
  `new` states in `reason` what was searched.
- `path-exists-unless-new` (`path`, `new`): a `new: no` path is relative to `--repo`, has no `..`, and
  exists (`-e`).

A section whose profile line lists `table,na` holds either a table or `n/a: <reason>` with a non-empty
reason, never both.

## Call and output

`bin/gate.sh arch <file> [--repo <root>]`. `<file>` is a spec or a plan. `all` accepts `--repo` and
passes it on. `--repo` defaults to the working directory. Success prints `arch: ok <spec path>` to
stdout. Each defect prints `REFUSED arch <spec path>: <problem> [<row>]` to stderr. `<row>` is the first
cell of the row, except rows with `interface` and `method` columns (`interface.method`) and rows with
`table` and `column` columns (`table.column`).

## Order of checks

1. `--repo` is not a directory, `<file>` is unreadable, or an existing `VAULT.md` is unreadable: exit 2.
2. Work on a copy with CR removed.
3. `type:` is not `arch-spec` or `plan`: refuse and stop. The first `type:` key wins, trailing space is
   ignored, quotes are not stripped.
4. Read `arch_profile`. A value that names no profile file: refuse and stop.
5. A plan resolves through `arch_spec`, relative to the plan's folder. Empty or absent: refuse when the
   repo has a profile, else exit 0 with no output. A named file that does not exist: refuse and stop.
6. Spec frontmatter is closed by a second `---`. `profile` names a profile file and equals the repo's
   profile when the repo has one. `plan` is non-empty and there is no `status` key. The text holds no
   `{{` and no `path/to/`, which are the placeholders of a profile's starting text.
7. Structure: fenced blocks (lines starting with three backticks, at column 0) are removed after the
   fence checks. An unclosed fence is a defect, and so is a `## ` heading that appears twice.
8. Each section of the profile is checked, in the profile's order. Extra sections are allowed. A row
   with a different cell count than its header is a defect. Sections are not cross-checked against each
   other, and the spec's `plan:` value is not compared to the plan's slug. Steps 6 to 8 print every
   defect, then exit 1.

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
| value outside a list | `<column>` must be `<a>`, `<b>` or `<c>` | row |
| number outside a range | `<column>` must be an integer from `<min>` to `<max>` | row |
