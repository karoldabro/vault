---
type: index
project: vault
tags: [index, indications]
---

# vault — Indications (working rules, patterns, standards)

| Slug | Rule | Applies-to |
|------|------|------------|
| [[shared-vs-stack-persona-factoring]] | Generic critics live once in `_shared/`; stack packs compose via `use_shared` + overlays | `personas/**` |
| [[testing-persona-group]] | Testing critics = group in `_shared/testing/`; one AI-failure cluster + one real analyzer per lens; selected on test-touching changes | `personas/_shared/testing/**`, `personas/_resolution.md` |
| [[critique-loop-stop-conditions]] | Loops stop on round cap or no-new-confirmed-blockers, never on approval alone | `commands/v-team/steps/**` |
| [[confirmed-vs-advisory-findings]] | A finding blocks only when tool-confirmed; unbacked = advisory | `personas/**`, `commands/v-team/steps/**` |
| [[packs-detect-not-assume]] | Packs detect the project's stack/state approach; never hardcode a library | `personas/<stack>.md` |
| [[installer-dry-run-seam]] | Installer side-effects go through a dry-run-able `run()` seam; offline tests assert the transcript, e2e proves the real install | `setup.sh`, `lib/installers.sh`, `tests/**` |
| [[per-user-installer-no-sudo]] | Installer runs as the user, escalates internally for apt only; refuse `sudo` invocation (`$SUDO_USER` set), accept interactive sudo | `setup.sh`, `lib/installers.sh`, `bin/*.sh` |
| [[openviking-three-part-install]] | OpenViking = server (pipx) + JSON `ov.conf` + plugin client `config.json` + `settings.json` env; miss any and the MCP shows "Connection closed" | `setup.sh`, `lib/installers.sh`, `~/.openviking/**`, `~/.claude/settings.json` |
| [[pin-pipx-python]] | Pin pipx tools with `--python` to a `>=3.10` interpreter; never inherit the host default (old `python3` → "No matching distribution found") | `setup.sh`, `lib/installers.sh` |
| [[light-command-siblings]] | Light command variants are single-file, no approval gate; `/v-ask` hard read-only, `/v-do` guarded by scope; escalate up the `/v-ask`→`/v-do`→`/v-work`→`/v-team` ladder | `commands/v-ask.md`, `commands/v-do.md` |
| [[automated-cr-safety]] | PR-review automation: untrusted-input + verdict-from-grounding-gate, secret redaction, host-scoped creds, non-bypassable first-post gate, stable fingerprint, never-commit | `commands/v-cr/**`, `lib/forge-detect.sh`, `lib/cr-helpers.sh` |
| [[sandboxed-cr-safety]] | Executing untrusted PR code: framework-owned isolation envelope (never from repo), no-egress-at-execution, runtime output is untrusted, guarded throwaway-clone cleanup, attribution-aware test gate | `commands/v-cr/sandbox.md`, `lib/cr-sandbox.sh`, `commands/v-cr/**` |
