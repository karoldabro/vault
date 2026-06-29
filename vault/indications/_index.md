---
type: index
project: vault
tags: [index, indications]
---

# vault — Indications (working rules, patterns, standards)

| Slug | Rule | Applies-to |
|------|------|------------|
| [[docs-readme-landing-page]] | README is a landing page (what-it-is + one-line install + attach + commands + links); deep detail lives in linked pages; humanize prose but keep reference tables/code dense | `README.md`, `INSTALL.md`, `vault-guide.md`, `tool-playbook.md` |
| [[shared-vs-stack-persona-factoring]] | Generic critics live once in `_shared/`; stack packs compose via `use_shared` + overlays | `personas/**` |
| [[testing-persona-group]] | Testing critics = group in `_shared/testing/`; one AI-failure cluster + one real analyzer per lens; selected on test-touching changes | `personas/_shared/testing/**`, `personas/_resolution.md` |
| [[tools-suggestions-not-rules]] | Tool guidance is suggestion not gate — Claude auto-selects; cost hierarchy is a default; only safety notes (Morph markers) stay firm | `tool-playbook.md`, `commands/**`, `VAULT.md` `tools` |
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
| [[verify-plugin-marketplace-qualifier]] | Plugin install id is `<plugin>@<marketplace-name>` from `marketplace.json` `name` — never the repo owner/path; verify before wiring | `lib/installers.sh`, `setup.sh`, `tests/unit/setup-autoinstall.bats` |
| [[cr-panel-spawn-and-visibility]] | Panel must really spawn one Agent per critic (inlined = non-conformant, prove via `Spawned:`); summary must surface coverage + test posture + comment brevity | `commands/_shared/critic-panel.md`, `commands/v-cr/steps/03-review.md` |
| [[capture-behaviors-test-shaped]] | Capture business logic as test-shaped `## Behaviors & rules` (precondition → expected [; edge]); durable in feature, deltas in session; omit when none; established not aspirational | `templates/session.md`, `templates/feature.md`, `commands/v-capture.md` |
| [[generators-emit-critics-confirm]] | Test-design generators emit pre-impl (no analyzer, never on the panel); critics confirm post-impl (bound analyzer, own the vote); all dossier confirmation in EXECUTE | `personas/_shared/testing/design/**`, `commands/v-team/steps/{03,04}-*.md` |
