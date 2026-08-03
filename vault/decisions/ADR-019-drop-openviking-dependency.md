---
type: decision
id: ADR-019
project: vault
date: 2026-08-03
status: accepted
tags: [decision, adr, dependencies, memory-stack, install]
---

# ADR-019 — Drop OpenViking as a framework dependency

## Status
accepted (2026-08-03)

## Context

OpenViking (OV) was the framework's declared first context layer: `tool-playbook.md` ranked it above
everything else, every lifecycle command opened by querying it, and `setup.sh --with-ov` installed a
four-part stack to make it work (ollama + `nomic-embed-text`, a pipx `openviking` package, a JSON
`ov.conf` plus a separate plugin client config, a systemd `--user` unit on :1933, and two
`OPENVIKING_*` keys in `~/.claude/settings.json`). Two whole commands — `/v-sync` and `/v-backfill` —
existed only to feed it.

Sessions repeatedly reported it as unused and awkward to install. Measured across all 27 Claude Code
projects, trailing 60 days:

| Signal | Count |
|---|---|
| `memory_store` (writes in) | 194 |
| `memory_health` (probes) | 139 |
| **`memory_recall` (reads out)** | **17** |
| `ov find` CLI searches | 79 |
| Logged failures (`Connection closed`, `ov: command not found`, "unavailable") | 38 |

Reads were ~4% of traffic. Failures were ~40% of successful reads. It was, in practice, a write-only
store behind the framework's most expensive install step.

This is not new evidence. `plans/2026-07-04-1030-v-family-usage-audit-retiering.md` already traced the
"extraction returned 0 memories" noise in **77% of sessions** (16,382 errors) to OV having no `vlm`
configured, and left the fix open. Embedding-only recall then ran for six more weeks without anyone
restoring extraction — which is itself the finding.

A replacement was already in place and already documented as OV's fallback in every command:
**claude-mem** for project history, and grep over the vault markdown, which needs nothing installed.

## Decision

Remove OpenViking from the framework entirely. No deprecation stubs, no compatibility shims.

1. **Cost hierarchy** — claude-mem becomes layer 1; grep over `~/vault/` is its standing substitute
   and is named explicitly wherever claude-mem is assumed, because claude-mem installs only with
   `--full` / `--with-claude-mem`.
2. **`tool-playbook.md` §1 is deleted and §§2–7 keep their numbers.** Eleven files across `commands/`
   and `vault/` cite those sections by number; renumbering would silently break every one. A
   numbering gap is the cheaper defect.
3. **`/v-sync` and `/v-backfill` are deleted**, not stubbed — they had no purpose beyond OV ingest.
   `commands/attic/v-resume.md` goes with them (it was retired *because* of OV's auto-recall hook).
4. **Installer** — `--with-ov`, the OpenViking step, the ollama step and all OV/ollama doctor rows are
   gone. Ollama and `nomic-embed-text` are no longer installed by the framework but are **not**
   uninstalled from any machine; the removal doc names `ollama rm nomic-embed-text` as optional.
5. **`bin/remove-openviking.sh` + `docs/removing-openviking.md`** ship as the permanent exit path for
   installs predating this change, and are written **before** the framework stops installing OV.
   `bin/vault-uninstall.sh` no longer touches OV and points at the new script instead.

## Consequences

- The install loses its heaviest, most failure-prone step. `setup.sh --full --dry-run` no longer names
  openviking, ollama or nomic-embed-text at all — asserted by a test.
- Semantic recall over the vault is lost where claude-mem is absent. Grep is lexical, not semantic.
  Accepted: 17 reads in 60 days is not a capability anyone was exercising.
- The removal script is now the only supported way to unwire an old install, so it is covered by
  safety tests rather than treated as a one-off: refuses to run with `HOME` empty or `/` (otherwise
  `"${HOME}/.openviking"` expands to `/.openviking`), honours `--dry-run` as a pure read, is
  skip-on-absent for systemd/jq/pipx, and is idempotent.
- A shared `consent_gate` + `safe_rm_under_home` now live in `lib/installers.sh`, used by both removal
  scripts instead of duplicated. `consent_gate` must be called directly, never in a command
  substitution — a subshell discards the exports (caught by the test suite during implementation).

### Two pre-existing bugs fixed in passing

- `bin/vault-uninstall.sh` uninstalled claude-mem as `claude-mem@claude-mem`, an id that never
  existed, so **claude-mem was never actually removed**. Corrected to `claude-mem@thedotmack`.
- `setup.sh`'s manual hints printed the same unqualified `claude plugin install claude-mem`. Corrected
  to the qualified id. Both are the exact trap `indications/verify-plugin-marketplace-qualifier` was
  written about.
- `bin/vault-uninstall.sh --help` printed shell code, because `usage()` was a `sed` line range over
  the file header. Replaced with a heredoc.

## Alternatives considered

- **Fix OV's extraction instead** (configure a `vlm`, local or hosted). Rejected: it addresses recall
  quality, not the 4% read rate or the four-part install. The audit left this open for a month and
  nothing regressed.
- **Keep OV optional and unwired.** Rejected: "optional" is what it already was on paper, while every
  command still opened by querying it and the installer still shipped it.
- **Deprecate `/v-sync` and `/v-backfill` with stubs.** Rejected per the repo's clean-removal rule and
  the explicit instruction not to preserve backwards compatibility.

## Refs

- [[../plans/2026-08-03-1300-drop-openviking-dependency]] — plan + full review trail (24 findings)
- [[../plans/2026-07-04-1030-v-family-usage-audit-retiering]] — the earlier audit that first flagged it
- [[ADR-005-installer-auto-exec]] — installer consent model this reuses
- `docs/removing-openviking.md` — the removal instructions
