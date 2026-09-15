---
type: trail
project: vault
plan: 2026-06-18-1518-setup-auto-install
date: 2026-06-18
personas: [generic: software-architect, security, skeptic]
rounds: 1 propose + 1 diff-review
convergence: clean
tags: [trail, record, team, install]
---

# setup-auto-install — process record

How `vault/plans/2026-06-18-1518-setup-auto-install.md` was reached. That plan carries the current
truth; this file carries the findings, the corrections and the options that lost.

## Decisions & trade-offs

| decision | alternative rejected | why it lost |
|---|---|---|
| Auto-install is the default on Ubuntu, gated by consent | Keep today's hint path as default, add an opt-in `--auto` flag | The explicit ask was a smooth one-command experience. Both the architecture and skeptic lenses wanted the opt-in; the reversal was accepted instead with consent prompt, printed URLs, degrade-on-non-apt and `vault/decisions/ADR-005-installer-auto-exec.md` |
| Keep ollama + `nomic-embed-text` as the embedding backend | Use the memory plugin's own bundled providers | The vault stack already runs against ollama + nomic and works. Server bootstrap stays an advisory note, not an auto-run |
| Drop Morph MCP entirely | Install it only when `$MORPH_API_KEY` is set, never prompting | It needs a paid key, so most runs skip it anyway. Dropping it removes the whole secret surface from `setup.sh` rather than hardening it |
| Full rewrite of `setup.sh` into an installer | Ship only the minimal name and doc fix | Counter to the explicit ask. The minimal fixes it wanted — the wrong plugin id, README against bats — were folded into the rewrite |
| Accept that dry-run and real execution are separate branches | Force one code path through both arms | The install COMMAND strings are identical across `run` and `run_shell`; only prechecks and verify differ, so divergence is bounded |

## Corrections to the draft commands

| tool | draft command | corrected to |
|---|---|---|
| serena | `uv tool install serena-agent@latest --prerelease=allow` | `uv tool install -p 3.13 serena-agent` — the draft form is not the current upstream command |
| morph MCP | `@razorback16/morph-mcp` | `@morphllm/morphmcp` — then dropped entirely at the gate |
| bun | host `bun.sh` | host `bun.com`, so the URL is `bun.com/install`, and the installer needs `unzip` |

## Findings & dispositions

### Round 1 — design

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| architect | arch-1 | MAJOR | confirmed | e2e can't reuse run.sh (no net/sudo, :ro) | applied (own e2e runner) |
| architect | arch-2 | MAJOR | confirmed | silent contract inversion of --full | applied (consent + ADR + README) |
| architect | arch-3 | MAJOR | confirmed | run() must not swallow local scaffold writes | applied (run scope = privileged only) |
| architect | arch-4 | MAJOR | confirmed | set -e aborts before doctor on first fail | applied (continue-on-error + doctor exit) |
| architect | arch-5/6/7/8 | MINOR/NIT | confirmed | PATH probe, lib extraction, e2e opt-in, flag matrix | applied |
| security | sec-1 | MAJOR | confirmed | key in argv via `-e KEY=val` | applied (pass by ref + redact) |
| security | sec-2 | MAJOR | confirmed | curl\|sh no integrity/consent | applied (print URL + consent; two-step where feasible) |
| security | sec-3 | MAJOR | confirmed | untrusted marketplaces auto-added | applied (print source + README note) |
| security | sec-4 | MAJOR | confirmed | secret files under default umask | applied (umask 077 / 0600) |
| security | sec-5 | MAJOR | advisory | dry-run/doctor may echo key | applied (redact + test) |
| security | sec-6/7/8 | MINOR/NIT | confirmed/advisory | sudo scope, path validation, --yes audit | applied / deferred (sec-7) |
| skeptic | skep-2 | BLOCKER | confirmed | partial failure leaves wedged state | applied (artifact-level guards + continue-on-error) |
| skeptic | skep-5 | BLOCKER | confirmed | ollama needs running daemon; e2e flaky | applied (explicit `ollama serve` + readiness; deterministic e2e) |
| skeptic | skep-1/3/7 | MAJOR | confirmed | safety reversal, claude CLI assumed, marketplace re-add | applied |
| skeptic | skep-4 | MAJOR | advisory | live-config mutation race / restart | applied (doctor fresh invocation + restart note) |
| skeptic | skep-6 | MAJOR | confirmed | alpine suite never covers execute path | applied (dry-run transcript = primary tested surface) |
| skeptic | skep-8 | MAJOR | advisory | is full rewrite necessary | rejected (explicit user ask) — minimal fixes folded in |
| skeptic | skep-9/10 | MINOR | confirmed | secret prompt under --yes, shell-rc PATH | applied |

| measure | round 1 |
|---|---|
| confirmed blockers raised | 2, both applied |
| confirmed MAJORs | 12, all applied |
| advisory findings | 4 |
| persona overlap | high — safety reversal (arch-2 ≈ skep-1) and coverage (arch-3 ≈ skep-6), clustered |
| round 2 | skipped; every confirmed BLOCKER/MAJOR applied and no open blockers, per `commands/v-team/steps/03-propose-loop.md` §f |

### Round 2 — diff review of the implemented code

| persona | id | severity | grounding | issue | disposition |
|---------|----|----------|-----------|-------|-------------|
| skeptic | skep-r7 | MAJOR | confirmed | stale `setup.sh --with-morph` in vault-guide.md (now a broken instruction) | applied (fixed guide; serena cmd too) |
| skeptic | skep-r2 | MAJOR | confirmed | `ensure_ollama_running` returns 0 even if daemon never came up | applied (returns 1 on poll exhaustion; install_ollama records fail, skips pull) |
| skeptic | skep-r4 | MAJOR | confirmed | e2e doctor assertion `*graphify*` tautological (matches ✓ or ✗) | applied (assert `✓] graphify` glyph) |
| architect | arch-r2 | MAJOR | confirmed | consent precedence `(read&&[y])\|\|[Y]` fragile | applied (braces group the test) |
| skeptic/architect | skep-r1/arch-r3 | MAJOR | confirmed | e2e covers only uv+graphify; ollama/claude paths not e2e-proven | applied (coverage note in run.sh; dry-run covers construction) |
| architect | arch-r6/skep-r3 | MINOR | confirmed | background `ollama serve` not disowned / no failure surface | applied (disown + warn + return 1) |
| architect | arch-r8 | NIT | confirmed | bun apt_install unzip without apt guard on non-apt host | applied (guard apt_available+sudo_available) |
| architect | arch-r5 | MINOR | confirmed | obsidian detection `\|\|`/`&&` precedence (pre-existing) | applied (braces) |
| skeptic | skep-r5 | MINOR | confirmed | unit doctor test weak (no row asserted) | applied (assert ✓uv / ✗ollama rows) |
| security | sec-r1/r2 | MINOR | confirmed | run_shell unredacted; redaction only covers KEY=val suffixes | applied note (guardrail comment); latent, no secret ships once Morph is dropped |
| architect | arch-r1 | MAJOR | advisory | dry-run vs real are separate branches | accepted; command strings identical across arms |
| architect | arch-r4 | MINOR | advisory | empty-array `${arr[@]}` under set -u on bash≤4.3 | deferred; target is Ubuntu bash 5.2, patterns use empty-safe `[*]` |
| skeptic | skep-r6 | MINOR | advisory | real `claude` marketplace idempotency unverified (no claude in e2e) | deferred; documented coverage gap, stub-tested |

| measure | round 2 |
|---|---|
| confirmed MAJORs | 5, all applied |
| MINOR/NIT applied | 5 |
| advisory deferred | 3 |
| security verdict | APPROVE_WITH_NITS — no live secret surface |
| tests after fixes | 34 unit + 35 integration + 4 e2e green |

## Rejected / deferred

- **Morph MCP installation.** The construction that was designed and then dropped: probe
  `MORPH_API_KEY`, never prompt for the paid API key under `--yes`, pass the key by reference and never as a literal in a
  logged string, then
  `claude mcp add filesystem-with-morph --scope user -e MORPH_API_KEY -- npx --prefer-offline -y @morphllm/morphmcp`,
  guarded by `claude mcp list | grep -q`. Killed at the gate: a paid key for a tool most runs skip is
  not worth a live secret surface in `setup.sh`. `tests/unit/setup-autoinstall.bats:320` now asserts
  `--with-morph` is an unknown flag.
- **Two Morph-only test rows.** Both drop with the tool they cover:

| id | source | kind | target | intent | priority |
|----|--------|------|--------|--------|----------|
| sec-t1 | security review | unit | Morph dry-run transcript has no raw key | secret never echoed | must |
| skep-t7 | skeptic review | unit | Morph with `MORPH_API_KEY` set vs unset under --yes | both secret branches, no TTY prompt | should |

- **Opt-in `--auto` flag.** Replaced by consent-gated auto-install as the default.
- **Minimal name-and-doc fix instead of the rewrite.** Rejected; its fixes were folded in.
