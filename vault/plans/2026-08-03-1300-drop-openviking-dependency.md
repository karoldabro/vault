---
type: plan
project: vault
date: 2026-08-03-1300
topic: drop-openviking-dependency
status: proposed
rounds: 1
convergence: no-new-blocking-findings (2 of 3 reviewers reported; correctness never returned)
tags: [plan, meta, dependencies, memory-stack, removal]
---

# Drop OpenViking as a vault-framework dependency

## Problem

The vault framework hard-wires OpenViking (OV) as the **first, mandatory** context layer in every
lifecycle command, and `setup.sh --with-ov` installs a four-part stack to make it work. The stack is
expensive to install and, measurably, almost never read from.

## Evidence (measured 2026-08-03, all 27 Claude Code projects, trailing 60 days)

| Signal | Count |
|---|---|
| `memory_store` (write into OV) | 194 |
| `memory_health` (health probes) | 139 |
| **`memory_recall` (read back out)** | **17** |
| `ov find` CLI searches | 79 |
| Logged OV failures (`Connection closed`, `ov: command not found`, "OV unavailable") | 38 |

Reads are ~4% of OV traffic; failures are ~40% of successful reads. The framework pays a four-part
install (ollama + `nomic-embed-text` model, pipx `openviking`, JSON `ov.conf` + plugin client config,
a systemd `--user` unit on :1933, plus two `~/.claude/settings.json` env keys) for a layer that is
written to constantly and read from almost never.

Corroborating prior evidence: `plans/2026-07-04-1030-v-family-usage-audit-retiering.md` already found
OV was the source of the "extraction returned 0 memories" noise in **77% of sessions** (16,382 errors,
no `vlm` configured). That fix was left open and never landed.

Replacement is already in place everywhere: **claude-mem** (progressive-disclosure project history)
plus **grep over the vault markdown**, which every command already documents as its OV fallback.

## Decision

Remove OpenViking entirely from the framework. No deprecation stubs, no compatibility shims
(per `indications/` house rule: clean removals). Ship a standalone remover + written instructions so
an existing install can be taken off a machine.

## Front gates

**Clarify (§3a.0a) — asked and answered:**
- Machine-level removal scope → **remove everything, including indexed data** (explicit user consent
  for the destructive `~/.openviking` delete).
- Global `~/.claude/CLAUDE.md` (outside this repo) → **update it too**.

**Research (§3a.0b) — skipped.** This is removal of an internal dependency with a documented
in-house replacement path already written into every command. No novel design choice to ground.

## Assumptions

1. `ollama` + `nomic-embed-text` exist in `setup.sh` **only** to serve OV embeddings. Dropping OV
   drops them from the installer. Ollama is **not** uninstalled from the machine — the user may use
   it elsewhere. The `nomic-embed-text` model (~275 MB) is named in the removal doc as an optional
   extra cleanup, not deleted automatically.
2. `/v-sync` and `/v-backfill` exist **only** to feed OV. With OV gone they have no function and are
   deleted, not stubbed.
3. `/v-link` (coupled groups) survives — coupled groups still steer cross-repo context loading; only
   its OV line goes.
4. `pipx_install` in `lib/installers.sh` stays — Graphify still uses it.
5. claude-mem becomes cost-hierarchy layer 1; grep over the vault is its documented fallback.
   **Caveat (skeptic-4, confirmed):** claude-mem is installed only by `--full` / `--with-claude-mem`
   (`setup.sh:58,84,402`), so a `--minimal` install has no layer 1. Every rewritten command therefore
   states the grep-over-the-vault fallback explicitly rather than assuming claude-mem is present.
   Making claude-mem a default install is **out of scope here** and recorded as an open point.

## Impact scope

**~40 files in this repo + 1 outside it.** Two new files, five deletions. (Rebuilt from a repo-wide
search after skeptic-5 showed the first draft's list was written partly from memory.)

### New

| File | Purpose |
|---|---|
| `bin/remove-openviking.sh` | Standalone, layered, consent-gated OV remover (service → configs → settings env → plugin → package → data). Reuses the shared consent gate rather than duplicating it. Reports each part as "already absent" when it isn't there. |
| `docs/removing-openviking.md` | Written removal instructions: what the four install parts were, what the script does, and how to preview it with `--dry-run`. Points at the script for the command list instead of restating it (quality-6, anti-drift). Names `ollama rm nomic-embed-text` as an optional extra. |

### Deleted

| File | Reason |
|---|---|
| `commands/v-sync.md` | OV-only command |
| `commands/v-backfill.md` | OV-only command |
| `commands/attic/v-resume.md` | Already retired; OV-only |
| `vault/indications/openviking-three-part-install.md` | Rule describes a dependency that no longer exists |

### `bin/remove-openviking.sh` — safety contract (from the correctness review)

1. **Delete-target validation before any `rm -rf`** (correctness-1, BLOCKER): `$HOME` must be
   non-empty and not `/`; the target must be an existing directory *under* `$HOME`. Otherwise abort.
   `HOME=` with `set -u` does **not** catch this — `"${HOME}/.openviking"` expands to `/.openviking`.
2. **Explicit `exit 0` at the end** (correctness-5): a script built from `[ "$flag" -eq 1 ] && step`
   lines exits non-zero under `set -e` whenever the last flag is off, so a clean run reports failure.
3. **The settings.json step branches on `VAULT_SETUP_DRY_RUN` by hand** (correctness-4): `run()`
   cannot intercept a shell redirection or `mv`, so a `--dry-run` would still rewrite the file.
   Mirror `clean_settings_env` (`bin/vault-uninstall.sh:121-124`).
4. **Every layer is skip-on-absent and non-fatal** (correctness-8): no user systemd, no `jq`, no
   `pipx` → warn and continue. Each part reports "already absent" rather than assuming it exists
   (skeptic-7: this machine has **no** `OPENVIKING_*` keys in `settings.json` today). A second run
   exits 0.
5. **Shared consent gate** (quality-1): the flag parsing + consent/dry-run preamble is extracted into
   `lib/installers.sh` and used by both this script and `bin/vault-uninstall.sh`, not copied.
6. **`usage()` is a `cat <<'EOF'` heredoc** (quality-5 / correctness-3), not a `sed` line range over
   the file header — the existing range already leaks shell code into `--help`.

### Modified — installer + scripts

| File | Change |
|---|---|
| `setup.sh` | Drop `--with-ov`, Step 4 (OpenViking), the ollama step, OV lines from `--full`, the closing OV note (which is also factually wrong: it claims there is no `ov` command) |
| `lib/installers.sh` | Delete `check_ollama`, `ensure_ollama_running`, `ensure_zstd`, `install_ollama`, `check_openviking_server`, `ov_enable_service`, `install_openviking_server`, `install_openviking_plugin`, `ov_set_env_key`; drop the 6 OV/ollama `_doctor_row`s. Keep `pipx_install` (Graphify) |
| `bin/vault-uninstall.sh` | Remove `remove_ov_service`, `remove_ov_configs`, `clean_settings_env`, the OV plugin line, the OV pipx line; **`purge_vault_data` keeps deleting `${VAULT_HOME}/_global` and loses only the `~/.openviking` argument** (skeptic-3 — they share one `rm -rf` at line 155); fix both messages naming that folder; `usage()` → heredoc; **fix the claude-mem uninstall id `claude-mem@claude-mem` → `claude-mem@thedotmack`** (correctness-6, pre-existing bug: claude-mem is currently never removed); point users at `remove-openviking.sh` |
| `bin/vault-capture.sh` | Drop the OV push comment |
| ~~`install.sh`~~ | **Dropped** — verified to contain zero OpenViking references (quality-7, skeptic-5) |

### Modified — commands (OV layer → claude-mem + grep)

`commands/v-work/steps/02-load-context.md` (§2.1 rewritten), `03-propose.md`, `05-commit-capture.md`,
`commands/v-work.md`, `commands/v-team.md`, `commands/v-do.md`, `commands/v-ask.md`,
`commands/v-capture.md`, `commands/v-guide.md`, `commands/v-link.md`, `commands/v-cr.md`,
`commands/v-cr/steps/02-gather.md`, `commands/v-cr/steps/05-capture.md`, `commands/v-pm.md`,
`commands/v-pm/steps/01-intake.md`, `02-load-context.md`, `05-capture.md`, `06-reconcile.md`,
`commands/README.md`, `commands/attic/README.md`, plus two the first draft missed (skeptic-6):
`commands/_shared/communication.md:8` (names `v-sync`/`v-backfill` as fixed-template commands) and
`commands/v-pm/steps/04-seed-workspace.md:44`.

### Modified — docs

`tool-playbook.md` — **delete §1 and renumber nothing** (quality-2, confirmed): §§3, 5, 6 and 7 are
cited by section number from `templates/VAULT.md:43`, `VAULT.md:41`, `commands/v-work/steps/04-execute.md:34`,
`commands/v-work/steps/03-propose.md:85,133`, `commands/v-work/steps/02-load-context.md:73,81`,
`commands/v-pm.md:60`, `vault/indications/propose-front-gates.md:36`, `vault/features/lifecycle-hooks.md:22`
and two ADRs. A numbering gap is harmless; renumbering silently breaks eleven cross-references.
Also rebuild the cost hierarchy and the health/fallback table.

`vault-guide.md` (memory-stack table, dedupe steps, tool table, cost hierarchy, command rows),
`README.md`, `INSTALL.md`, `_moc.md`, `CLAUDE.md`, `templates/project-moc.md`,
`prompts/consolidate-into-indications.md`, `vault/_moc.md`, `vault/indications/_index.md`,
`vault/features/v-pm.md`, and two indications that teach their rule with an OpenViking example
(quality-4): `vault/indications/verify-plugin-marketplace-qualifier.md:24` and
`vault/indications/pin-pipx-python.md:28` — re-cut onto `graphifyy` / `claude-mem@thedotmack`.
Comment-only: `tests/e2e/run.sh:11`.

### Modified — tests (explicit case list, per correctness-2)

| File | Cases |
|---|---|
| `tests/unit/install.bats` | line 17 — **drops `v-sync` and `v-backfill`** from the expected-symlink loop (skeptic-2, BLOCKER: this alone fails the suite) |
| `tests/unit/v-pm.bats` | lines 36, 58, 59, 122 — assert `memory_store` / `memory_health` / `memory_recall\|OpenViking` are present in the very step files being rewritten (skeptic-1 + quality-3, BLOCKER); flip to the replacement wording |
| `tests/integration/setup.bats` | delete 59, 75, 84, 92, 102; **re-parameterise 114 to `--with-graphify`** rather than delete it — it is the only test proving `--minimal` overrides a tool flag (correctness-7) |
| `tests/integration/vault-uninstall.bats` | delete/rewrite 54, 62, 68, 94, 101, 116; keep a case proving `--purge-data` still deletes `_global` |
| `tests/unit/setup-autoinstall.bats` | delete 138 + 151 (`ensure_zstd`, named for ollama not OV — quality-8) and the OV cases at 42, 62, 130, 163, 179, 196, 206, 214, 241; drop the ollama doctor-row assertion (~250) and the ollama mention in the sudo-scope case (118) |
| **new** `tests/integration/remove-openviking.bats` | covers the new remover (see Test plan) |

### Outside this repo

`~/.claude/CLAUDE.md` — the cross-project memory-stack and search-precedence sections name OV as
layer 1. Rewritten to claude-mem → graph → grep.

### Machine actions (user-approved, destructive)

Run `bin/remove-openviking.sh --all --yes` on this machine: stop + disable + delete the systemd unit,
delete `~/.openviking` **including indexed data**, uninstall the Claude plugin,
`pipx uninstall openviking`. The `OPENVIKING_*` settings keys are **already absent** on this machine
(skeptic-7) — the script will report them as such. Ollama and its model are left installed.

## Implementation order (dependency-ordered)

1. Write `bin/remove-openviking.sh` + `docs/removing-openviking.md` — the exit path must exist before
   the framework stops installing OV.
2. Strip the installer layer: `lib/installers.sh` (extract the shared consent gate first) →
   `setup.sh` → `bin/vault-uninstall.sh`.
3. Update tests to match (2) and confirm `make test` is green.
4. Rewrite the command layer (context-load, capture, and dispatcher tool lines).
5. Delete the OV-only commands and re-run the install symlink test.
6. Update docs + vault indications/MOC.
7. Update `~/.claude/CLAUDE.md`.
8. Execute the machine removal.
9. Write ADR + capture.

## Test plan

`make test` (bats in Docker) is the gate — never on the host. Plus:
- `bash -n` on every changed shell file (shellcheck is not installed here).

New `tests/integration/remove-openviking.bats`:

| id | Case | Guards |
|---|---|---|
| t1 | `--dry-run` against a seeded fake `HOME` (ov.conf, `data/index.bin`, systemd unit, both settings keys) | prints a plan, exits 0, every seeded file byte-identical |
| t2 | `--all --yes` run **twice** with no `jq`, no `systemctl`, no `pipx` on PATH | both runs exit 0; second is a no-op |
| t3 | `--all --yes` with `HOME=""` and with `HOME=/` | refuses and deletes nothing (guards the `/.openviking` expansion) |
| t4 | `./setup.sh --dry-run --full` | exits 0 and names no openviking / ollama / nomic-embed-text |
| t5 | repo-wide grep guard | no `openviking` / `ollama` / `memory_recall` / `memory_store` / `ov find` outside the allowlist |
| t6 | `bin/vault-uninstall.sh --purge-data` | still deletes `${VAULT_HOME}/_global` after the OV argument is removed from the same `rm` |

**Allowlist for t5:** `bin/remove-openviking.sh`, `docs/removing-openviking.md`, `vault/plans/`,
`vault/sessions/`, `vault/decisions/`, and the test file itself — history is not rewritten.

## Risk

- **Sole risk of substance:** removing the only exit path for existing installs. Mitigated by
  ordering step 1 first and keeping the remover in the repo permanently.
- Deleting `~/.openviking/data` is irreversible — but the source markdown it indexed lives in the
  vault repos and is untouched.

## Critique trail

**Round 1** — three reviewers (skeptic, quality, correctness), all read-only, all findings
independently re-verified by the synthesizer against the repo before acceptance. All three returned
`REQUEST_CHANGES`. **24 findings, 24 confirmed, 0 advisory, 0 rejected — every one applied.**

Delivery note: all three initially idled without reporting and had to be prompted a second time via
direct message. Findings arrived intact; the spawn-and-collect path is unreliable in this session.

| id | Sev | Applied as |
|---|---|---|
| correctness-1 | BLOCKER | Delete-target validation before `rm -rf` (empty `HOME` → `/.openviking`) |
| skeptic-1 / quality-3 | BLOCKER | `tests/unit/v-pm.bats` added — 4 assertions require the OV wording in files being rewritten |
| skeptic-2 | BLOCKER | `tests/unit/install.bats:17` added — asserts `v-sync`/`v-backfill` symlinks |
| quality-1 | MAJOR | Shared consent gate extracted to `lib/installers.sh`; not duplicated |
| quality-2 | MAJOR | Renumbering `tool-playbook.md` abandoned — 11 cross-references cite the section numbers |
| skeptic-3 | MAJOR | `purge_vault_data` keeps deleting `_global`; only the OV argument goes |
| skeptic-4 | MAJOR | claude-mem is not installed by `--minimal`; the grep fallback is stated explicitly everywhere |
| correctness-2 | MAJOR | Vague test rows replaced with the explicit 25-case list |
| correctness-3 / quality-5 | MAJOR | `usage()` → heredoc; the `sed` range already leaks shell code into `--help` |
| correctness-4 | MAJOR | settings.json step branches on the dry-run flag by hand; `run()` can't intercept `mv` |
| correctness-5 | MAJOR | Explicit `exit 0` — `[ flag ] && step` as the last line fails under `set -e` |
| quality-4 | MINOR | Two surviving indications re-cut off their OpenViking examples |
| quality-6 | MINOR | Removal doc points at `--dry-run` instead of restating commands |
| quality-7 / skeptic-5 | MINOR | `install.sh` row dropped — verified to contain no OV references |
| quality-8 | MINOR | `ensure_zstd` cases named explicitly (ollama, not OV) |
| skeptic-6 | MINOR | Six missed files added; grep gate allowlist widened to history |
| skeptic-7 | MINOR | `OPENVIKING_*` settings keys are already absent here; script reports per-part state |
| correctness-6 | MINOR | Pre-existing bug fixed: claude-mem uninstalled under a wrong id, so it never was |
| correctness-7 | MINOR | `--minimal beats --with-ov` re-parameterised to `--with-graphify`, not deleted |
| correctness-8 | MINOR | Skip-on-absent contract for systemd / jq / pipx; idempotent |
| skeptic-8 | NIT | `nomic-embed-text` named as optional extra cleanup in the doc |

Verified-clean by correctness, no finding: `setup.sh --full --dry-run` exits 0 today and can only
improve; `tests/e2e/` has no OV assertions; `bash -n` passes on all 11 shell files.

**Stopped after round 1** — every confirmed finding was applied, so a second round has nothing
unresolved to react to.

## Diff review (post-implementation)

One reviewer over the shipped commit `b32b93c`. **8 findings, all confirmed, all applied.** It
verified clean the things most likely to be wrong — `safe_rm_under_home` against glob-metachar and
trailing-slash `HOME`, `set -euo pipefail` interactions, the `CONSENT_MODE` contract in both callers,
and a full 33-function census of `lib/installers.sh` for orphans (none new).

| id | Sev | Applied as |
|---|---|---|
| dr-1 | MAJOR | `bin/vault-uninstall.sh` `purge_vault_data` still did a raw `rm -rf "${VAULT_HOME}/_global"` — with an empty `HOME` that resolves to `/vault/_global`, the very bug the new guard was written for, left live in the sibling script. Now refuses empty/`/`/relative `VAULT_HOME`; two regression tests added. |
| dr-2 | MINOR | `_moc.md` still linked the deleted `commands/v-resume` |
| dr-3 | MINOR | `vault-guide.md` cited capture as §5.5 after it became §5.4; closed the 5.6 gap too |
| dr-4 | MINOR | The "no jq" test left jq on `PATH` at `/usr/bin/jq` (alpine ships it), so the warn branch never ran — now shadowed with a non-executable stub |
| dr-5 | NIT | `setup.sh` in-body `# Step N` markers were skewed one off the header list |
| dr-7 | NIT | The grep guard exempted `lib/installers.sh` — the file OV was removed from — and its companion assertion passed on any word containing "remov" |
| dr-8 | NIT | `remove_plugin` claimed success even when the uninstall failed |

**dr-6 rejected on evidence.** It proposed closing the §2.2 gap in `02-load-context.md`, asserting
nothing cites those numbers. Applying it broke `tests/unit/test-hooks-tools-rename.bats:87`, which
greps for `2.3c`; `04-execute.md:77` and `03-propose.md:95` cite §2.3a and §2.3b as well. Reverted —
the gap stays and is now documented in the file, consistent with the `tool-playbook.md` §1 policy.

Final: **277 tests pass.**
