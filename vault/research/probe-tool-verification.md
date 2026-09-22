---
type: research
project: vault
slug: probe-tool-verification
status: living
date_researched: 2026-09-21
tags: [research, probes, tools]
---

# Probe tool claims: what each turned out to be

Twelve claims about analysis tools were unverified when the probe catalog was written. Each was checked against the tool's own source, documentation or a run in a scratch environment. A registry row in `probes/registry.tsv` names a tool only when its verdict here is `verified` or `partly` and a parser test consumes real output. A `refuted` or `unverifiable` verdict keeps the tool out of the registry until a session re-checks it.

Verdict values: `verified`, `partly`, `refuted`, `unverifiable`. Each section holds `verdict:`, `url:`, `date:` and `quote:` lines at column 0. `run:` names how the claim was checked.

The evidence for a tool that was run (Semgrep, ast-grep, lizard, typos, `claude plugin validate`) is the run, and its `url:` is the project page, which no session re-opened. The Atlas and tbls sources were opened twice, once by an agent and once by the main session. The other pages were read by an agent only. A future session that relies on a quote re-opens its URL first.

## Claims

### Atlas migrate lint
verdict: refuted
url: https://atlasgo.io/versioned/lint
date: 2026-09-21
quote: Starting with v0.38, the atlas migrate lint command is available only to Atlas Pro users.
run: page fetched twice (an agent and the main session). Needs `atlas login` and a dev database. `{{ json . }}` is not documented on the page.

### DCM Dart Code Metrics
verdict: partly
url: https://dcm.dev/pricing
date: 2026-09-21
quote: Free: up to 50k analyzed LOC, 100 lint rules, 1 seat (agent's reading of the pricing page).
run: `dcm analyze` and `dcm check-code-duplication` accept `--reporter json` (https://dcm.dev/docs/cli/analysis/analyze/). The licence is commercial. The OSS fork `dart_code_linter` has `analyze --reporter json` and no duplication check.

### PHPArkitect
verdict: verified
url: https://raw.githubusercontent.com/phparkitect/arkitect/main/src/CLI/Command/Check.php
date: 2026-09-22
quote: Output format: text (default), json, gitlab
run: `phparkitect/phparkitect` 1.3.0.0 installed and run for real in a scratch project (session S9). The config file must `return static function (Config $config): void { ... $config->add($classSet, ...$rules); }` — `Config::for()` does not exist. Rule construction is `Rule::allClasses()->that(...)->should(new NotDependsOnTheseNamespaces([...]))->because(...)`; the namespace-list expressions take an `array`, not a `string`. `check --format=json` on one deliberate violation (a `App\Domain` class depending on `App\Infra`) printed `{"totalViolations": 1, "details": {"<FQCN>": [{"error": "...", "line": N}]}}` — keyed by fully-qualified class name, with **no file path field at all**. `probes/rules/fixtures/phparkitect` (`tests/fixtures/probe/phparkitect.json`) holds the captured payload; `parse_phparkitect_json` derives the file path from the FQCN under the Laravel `App\` → `app/` PSR-4 convention, since this row is Laravel-only.

### tbls lint JSON output
verdict: refuted
url: https://raw.githubusercontent.com/k1LoW/tbls/main/cmd/lint.go
date: 2026-09-21
quote: lintCmd.Flags().StringVarP(&dsn, "dsn", "", "", "data source name")
run: `tbls lint` registers only `--dsn`, `--config` and `--when`. Output is text and exit 1 on violations. JSON exists only in `tbls out`. A datasource may be `json://<file>`, which lets it lint without a database.

### PHPMD empty catch rule
verdict: partly
url: https://raw.githubusercontent.com/phpmd/phpmd/master/CHANGELOG
date: 2026-09-21
quote: EmptyCatchBlock rule added in 2.7.0 (agent's reading of the changelog).
run: the rule is `EmptyCatchBlock` in the `design` ruleset, not `cleancode`. `phpmd <path> json <ruleset>` is valid; exit 2 means violations. Report formats `json`, `sarif`, `checkstyle`, `github` and `gitlab` exist.

### Semgrep Dart and Vue support
verdict: partly
url: https://semgrep.dev/docs/supported-languages
date: 2026-09-21
quote: Failure: Vue support has been removed in 1.93.0
run: semgrep 1.177.0 in a scratch venv. A `languages: [dart]` rule matched an empty catch. A `.vue` file scanned to a failure line and no findings. `semgrep --test` with `# ruleid:` and `# ok:` annotations passed offline.

### ast-grep Dart and Vue support
verdict: refuted
url: https://ast-grep.github.io/reference/languages.html
date: 2026-09-21
quote: error: invalid value 'vue' for '--lang <LANG>': vue is not supported!
run: ast-grep 0.45.3 via pnpm in a scratch project. The TypeScript pattern matched. The Dart pattern parsed with an ERROR node and found nothing. The binary is `ast-grep`; `/usr/bin/sg` on this machine is the shadow-utils group tool.

### lizard JSON output
verdict: partly
url: https://pypi.org/project/lizard/
date: 2026-09-21
quote: error: unrecognized arguments: --json
run: lizard 1.24.0 in a scratch venv. `--json` does not exist, so that claim is refuted. `--csv`, `-X` (xml) and `-H` (html) exist, and a threshold breach exits 1. The registry row uses `--csv`.

### PMD CPD flags
verdict: partly
url: https://pmd.github.io/pmd/pmd_userdocs_cpd.html
date: 2026-09-21
quote: --minimum-tokens is required and --language defaults to Java (agent's reading of the page).
run: PMD 7 syntax is `pmd cpd --minimum-tokens N --language X --format F --dir PATH`. Formats are text, xml, xmlold, csv, csv_with_linecount_per_file, vs and markdown, with no json. Exit 4 means duplicates and `--no-fail-on-violation` changes it. It needs a JRE. No captured output yet. Session S9 (`vault/plans/2026-09-22-0900-stack-packs.md`) is a Laravel/Nuxt/Flutter/Python stack-pack session. It does not add this row. Cross-language duplicate detection is a different job from a stack pack and stays open for a future session.

### typos on PyPI
verdict: verified
url: https://pypi.org/project/typos/
date: 2026-09-21
quote: Source Code Spelling Correction
run: typos 1.50.2 in a scratch venv. `typos --format json --config _typos.toml <file>` printed one JSON object per line with `path`, `line_num`, `typo` and `corrections`. An `extend-words` entry `client = "customer"` produced a glossary finding. Exit 2 on findings.

### Qlty offline claim
verdict: partly
url: https://docs.qlty.sh/cli/commands/install
date: 2026-09-21
quote: plugin installations require an Internet connection
run: the CLI is free under the Business Source License, and `qlty check --sarif` exists. It needs network on first run for each plugin set. The language page lists PHP, Python and TypeScript, and not Dart or Vue.

### claude plugin validate
verdict: verified
url: https://code.claude.com/docs/en/plugins-reference
date: 2026-09-21
quote: Validate a plugin or marketplace manifest, or the skills, agents, and commands in a directory
run: `claude plugin validate --help` on version 2.1.278. `--json` prints a report with `manifest` and `contents[]` entries, each holding `errors` and `warnings`. Exit 0 on success and 1 on an invalid manifest, tested on this repo and on a broken manifest. `--strict` treats warnings as errors.

### PHPStan JSON output
verdict: verified
url: https://phpstan.org/user-guide/output-format
date: 2026-09-22
quote: json — minified JSON without whitespace.
run: PHPStan 2.x, `--error-format=json --no-progress`, run for real inside `recycling-api`'s own `server` docker image (session S9; the host's PHP 8.3.11 is too old for that repo's `composer.lock`, which needs PHP >=8.4.1). Real output is `{"totals": {"errors": N, "file_errors": N}, "files": {"<path>": {"errors": N, "messages": [{"message": "...", "line": N, "ignorable": bool, "identifier": "..."}]}}, "errors": [...]}`. There is no severity/level field on a message — only `ignorable`. `tests/fixtures/probe/phpstan.json` holds the captured payload (path normalized to repo-relative).

### ruff --output-format json
verdict: verified
url: https://docs.astral.sh/ruff/settings/
date: 2026-09-22
quote: --output-format json produces machine-readable output.
run: ruff 0.16.8 installed in a scratch `.venv-probes` (session S9, same convention as the `typos` row) and run against a file with an unused import and an unused local variable. Real output is a JSON array of `{"filename": <absolute path>, "location": {"row": N, "column": N}, "code": "...", "message": "...", "severity": "error", ...}`. `tests/fixtures/probe/ruff.json` holds the captured payload (path normalized to repo-relative).

### dart analyze --format=machine (Flutter/Dart)
verdict: partly
url: https://github.com/flutter/flutter/issues/95090
date: 2026-09-22
quote: --format=machine parameter (pipe-delimited: SEVERITY|TYPE|ERROR_CODE|FILE_PATH|LINE|COLUMN|LENGTH|ERROR_MESSAGE)
run: `flutter analyze` on Flutter 3.44.4 has **no `--format` flag at all** — refuted for that command specifically (`Could not find an option named "--format"`, exit 64). The underlying `dart analyze --format=machine` (Dart SDK bundled with Flutter) does carry it and was run for real, in a scratch `flutter create` project (session S9) with an unused local variable and a stray `print`. Real output: `WARNING|STATIC_WARNING|UNUSED_LOCAL_VARIABLE|lib/main.dart|126|7|11|...` and `INFO|LINT|AVOID_PRINT|lib/main.dart|125|3|5|...`, one line per finding, pipe-delimited, matching the documented column order. `probes/registry.tsv` runs `dart analyze`, never `flutter analyze --format=machine`. `tests/fixtures/probe/dart-analyze.txt` holds the captured payload.

### vue-tsc --noEmit diagnostic text (Nuxt)
verdict: refuted (original claim), verified (actual format)
url: https://github.com/nuxt/cli/blob/main/packages/nuxi/src/commands/typecheck.ts
date: 2026-09-22
quote: (no JSON or machine-readable mode documented for vue-tsc or nuxi typecheck)
run: the original draft assumed TypeScript's colon-dash pretty form, `path:line:col - error TSxxxx: message` — that is the TTY-only "pretty" form. Piped (as `bin/probe.sh` always runs a tool), TypeScript defaults to non-pretty. vue-tsc 3.3.11 (pinned to `typescript@5.6`; `typescript@7.0.2` breaks vue-tsc's internal `require.resolve('./lib/tsc')` — a real, current incompatibility, noted for the install command) was run for real, in a scratch project, against `const x: number = "not a number";`. Real, piped output: `bad.ts(1,7): error TS2322: Type 'string' is not assignable to type 'number'.` — the parenthesized form, one line per diagnostic, no JSON. `tests/fixtures/probe/vue-tsc.txt` holds the captured payload.

## Refs
- `probes/registry.tsv`: every tool row names a tool that has a section here.
- `vault/plans/2026-09-21-1130-probe-kit-core.md`: decision D-9 requires this file.
- `vault/plans/2026-09-22-0900-stack-packs.md`: session S9, adds the PHPStan, PHPArkitect, ruff, dart analyze and vue-tsc rows above.
