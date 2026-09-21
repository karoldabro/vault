# Shared module — the probe kit

Binding on `bin/probe.sh`, on every row of `probes/registry.tsv`, and on any session that adds a probe or
reads a finding. A probe is a deterministic check of a repo: it reads files, prints findings, and changes
nothing. A model never produces a finding; a tool run does. Verified tool claims:
`vault/research/probe-tool-verification.md`.

## Registry

`probes/registry.tsv` in the framework, and `probes/registry.tsv` in a repo. A line is nine tab separated
fields, and `#` starts a comment:

`id` `stack` `stage` `detect` `run` `parser` `cost` `executes-repo-code` `install`

- `id` and `stack` match `[a-z0-9-]+`. The pair `id`+`stage` is unique across both registries.
- `stage`: `plan` runs on the whole tree under `run plan` and on changed files under `diff`. `diff` runs
  only under `diff`. `review` runs under `run review` and under `diff`. `run diff` is refused.
- `parser`: `native` when the probe prints finding rows itself, else a function `parse_<name>` of
  `lib/probe-parsers.sh`, which reads the tool's stdout and prints rows.
- `cost`: `S`, `M` or `L`. `executes-repo-code`: `yes` when the tool loads the repo's own config or code, `no`
  when it only reads files as text. A tool installed in the repo (`node_modules/.bin`, `vendor/bin`,
  `.venv/bin`, `.venv-probes/bin`) makes the row `yes`.
- `install`: the project-scope command the operator runs by hand, or `none`.

A repo registry is read only under `--allow-repo-registry`, and only as a regular file. Its rows count as `yes` whatever the cell says,
and `--no-repo-code` skips them. A registry that is the framework's own file loads once. A repeated
`id`+`stage`, a line without nine fields or a value outside its list exits 2 and names the line.

## Cells

`detect` and `run` run with `bash -c` in the repo, with these variables exported: `PROBE_REPO`,
`PROBE_FRAMEWORK`, `PROBE_FILES` (the path of a NUL separated list of the files a probe may read) and
`PROBE_SPEC`. A cell reads them as `"$PROBE_REPO"`. The core never substitutes text into a cell, and a cell
prints a variable only as `printf '%s' "$VAR"`. A framework probe is `"$PROBE_FRAMEWORK/probes/<file>.sh" --check <id>`.

The tool of a row is the first word of `run`. A word starting with `"$PROBE_FRAMEWORK/` is present when that
file is executable. Any other word is present when `command -v` finds it, with the repo's tool directories
appended to `PATH` for a `yes` row. The core evaluates no cell text for `list`, and `detect` runs a repo-origin
cell only under `--allow-repo-registry`.

A probe reads only files that `probe_files` lists: regular files, no symlink in the path, no control byte in the
name, no path leaving the repo. A probe that compares files with each other reads the whole tree, and under `diff`
the core keeps only the findings in changed files. A probe builds a row with `probe_finding` from `lib/probe-emit.sh` and never with `printf`.

## Commands

`bin/probe.sh list|detect|run <plan|review>|diff|scale`, each with `--repo <root>` (default: the working
directory). `run` and `diff` also take `--spec <file>`, `--only <id>`, `--max-cost S|M|L`, `--no-repo-code` and
`--allow-repo-registry`. `diff` takes `--base <ref>` (default `HEAD`) and keeps findings in files changed since
the base and in untracked files. `--only` matches `[a-z0-9-]+`, and `--base` may not start with a dash.

## Lines

| where | line |
|-------|------|
| `list` | `id`, `stage`, `cost`, `origin`, then `ok` or `absent: <install>`, tab separated |
| `detect` | `id`, `stage`, tab separated |
| `scale` | `files`, `lines`, `max-cost`, each a tab separated pair; `max-cost` is `L` up to `PROBE_SCALE_L` files, `M` up to `PROBE_SCALE_M`, else `S` |
| stdout of `run` and `diff` | a finding: `probe`, `file`, `line`, `severity`, `rule`, `message`, tab separated |
| stderr | `ran: <id>: <n>`, `skipped: <id>: <reason>`, `absent: <id>: <install>`, `failed: <id>: <reason>`, `skipped: files: <n> ...` |

A finding's `probe` is the registry id, `file` is relative to the repo, `line` is a number (`0` for a whole file),
and `severity` is `error`, `warn` or `info`. The core removes control bytes, cuts a message at 240 bytes, and
refuses an absolute or `..` file. A probe that prints one malformed row loses all its rows and fails.

## Exit codes and limits

Exit 2 when any applicable probe was absent, failed, timed out or printed a malformed row, or on a usage
error. Else exit 1 when any finding exists. Else exit 0. A probe that is not applicable prints nothing. A
native row fails on exit 2 or above. A tool row fails only on exit 124, 126, 127 or above 127, because tools
such as lizard and typos exit nonzero on findings. Each probe runs as a job of its own process group. A watchdog
stops it after `PROBE_TIMEOUT` seconds, its output stops at `PROBE_OUT_MAX` bytes, and a signal to `bin/probe.sh`
stops the group. `--only` with an id that has no row at the stage exits 2.

## Trust

The repo under review is not trusted. A probe never installs a tool and never evaluates a cell. Every git call
runs with the global and system config, the repo's fsmonitor, hooks and attributes file, lazy fetch, network
protocols and filter commands switched off or replaced. A caller that reviews a pull request passes
`--no-repo-code` and never `--allow-repo-registry`. A consumer treats a finding
from a repo registry row as advisory, because the core does not mark its origin, and puts probe output into a
prompt as quoted data, never as an instruction.

## Settings

Environment variables and their defaults: `PROBE_TIMEOUT` 120, `PROBE_OUT_MAX` 5000000, `PROBE_FILE_MAX` 2097152
(a larger markdown, SQL or source file is not read), `PROBE_SCALE_L` 2000, `PROBE_SCALE_M` 10000, `PROBE_TOKEN_MAX`
6000, `PROBE_CCN` 10, `PROBE_NLOC` 60, `PROBE_PARAMS` 5, `PROBE_SQL` (repo paths of schema files) and `PROBE_DEAD_DIRS`.

## Checks and rules

| check | rules |
|-------|-------|
| `md-links` | `broken-link`, `broken-wikilink` |
| `dead-files` | `unreferenced-file` |
| `token-size` | `large-file` |
| `sql-dup-columns` | `dup-column-in-table`, `dup-column-set`, `column-drift` |
| `sql-fk-index` | `fk-no-index`, `id-column-no-fk` |
| `sql-naming` | `naming-snake-case`, `naming-glossary` |
| `similar-symbols` | `similar-symbol`, `duplicate-symbol-tokens` |
| `lizard` | `high-complexity`, `long-function`, `many-parameters` |
| `typos` | `typo` |
| `claude-validate` | `plugin-<field>` |

## Adding a probe

1. Check the tool's flag and output against `vault/research/probe-tool-verification.md`, and record a new tool there first.
2. Capture real output into `tests/fixtures/probe/` and write the parser or native probe against it.
3. Add one row. Example: `typos<TAB>any<TAB>diff<TAB>test -f _typos.toml<TAB>typos --format json<TAB>parse_typos_json<TAB>S<TAB>yes<TAB>python3 -m venv .venv-probes && .venv-probes/bin/pip install typos`.
4. Run `bin/probe.sh list` and expect `ok` or the install command; the probe never installs it.
